// backend/src/routes/payment.js
'use strict';

const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
let Razorpay;
try {
  Razorpay = require('razorpay');
} catch (_) {
  Razorpay = null;
}

module.exports = async function paymentRoutes(fastify) {
  const keyId = process.env.MANTRA_RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder';
  const keySecret = process.env.MANTRA_RAZORPAY_KEY_SECRET || process.env.RAZORPAY_KEY_SECRET || 'rzp_secret_placeholder';

  let razorpayInstance = null;
  if (Razorpay && keyId !== 'rzp_test_placeholder') {
    try {
      razorpayInstance = new Razorpay({ key_id: keyId, key_secret: keySecret });
    } catch (_) {}
  }

  const PLANS = {
    gold_monthly:     { amount: 39900,  currency: 'INR', duration_days: 30,  tier: 'gold' },
    gold_quarterly:   { amount: 99900,  currency: 'INR', duration_days: 90,  tier: 'gold' },
    platinum_monthly: { amount: 79900,  currency: 'INR', duration_days: 30,  tier: 'platinum' },
    platinum_yearly:  { amount: 699900, currency: 'INR', duration_days: 365, tier: 'platinum' },
  };

  // Helper to fulfill order and activate premium idempotently
  async function fulfillOrder(orderId, paymentId) {
    const orderResult = await fastify.db.query(`
      SELECT user_id, plan_id, status FROM payment_orders WHERE razorpay_order_id = $1
    `, [orderId]);

    if (!orderResult.rows[0]) return null;
    const { user_id, plan_id, status } = orderResult.rows[0];

    const plan = PLANS[plan_id] || { duration_days: 30, tier: 'gold' };
    const expiresAt = new Date(Date.now() + plan.duration_days * 86400 * 1000);

    if (status !== 'paid') {
      await fastify.db.query(`
        UPDATE payment_orders
        SET status = 'paid', razorpay_payment_id = $1, paid_at = NOW()
        WHERE razorpay_order_id = $2
      `, [paymentId || 'captured_via_webhook', orderId]);

      await fastify.db.query(`
        UPDATE users
        SET is_premium = true, premium_tier = $1, premium_expires_at = $2
        WHERE id = $3
      `, [plan.tier, expiresAt, user_id]);

      await fastify.db.query(`
        UPDATE profiles
        SET trust_score = LEAST(100, trust_score + 10)
        WHERE user_id = $1
      `, [user_id]);
    }

    return { tier: plan.tier, expires_at: expiresAt };
  }

  // POST /payment/order — create Razorpay order
  fastify.post('/order', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['plan_id'],
        properties: {
          plan_id: { type: 'string', enum: Object.keys(PLANS) },
        },
      },
    },
  }, async (req, reply) => {
    const { plan_id } = req.body;
    const plan = PLANS[plan_id];
    const userId = req.user.uid;

    let orderId;
    if (razorpayInstance) {
      try {
        const order = await razorpayInstance.orders.create({
          amount: plan.amount,
          currency: plan.currency,
          receipt: `mantra_${userId.slice(0, 8)}_${Date.now()}`,
          notes: { user_id: userId, plan_id, tier: plan.tier },
        });
        orderId = order.id;
      } catch (err) {
        fastify.log.warn(`Razorpay create failed, generating local test order: ${err.message}`);
        orderId = `order_test_${Date.now()}_${uuidv4().slice(0, 8)}`;
      }
    } else {
      orderId = `order_test_${Date.now()}_${uuidv4().slice(0, 8)}`;
    }

    // Record pending order
    await fastify.db.query(`
      INSERT INTO payment_orders (id, user_id, razorpay_order_id, plan_id, amount, status, created_at)
      VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
    `, [uuidv4(), userId, orderId, plan_id, plan.amount]);

    return fastify.sendSuccess(reply, {
      order_id: orderId,
      amount: plan.amount,
      currency: plan.currency,
      key_id: keyId,
      plan: { id: plan_id, tier: plan.tier, duration_days: plan.duration_days },
    });
  });

  // POST /payment/verify — verify payment & activate premium
  fastify.post('/verify', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['razorpay_order_id', 'razorpay_payment_id'],
        properties: {
          razorpay_order_id: { type: 'string' },
          razorpay_payment_id: { type: 'string' },
          razorpay_signature: { type: 'string' },
        },
      },
    },
  }, async (req, reply) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    const isTestOrder = razorpay_order_id.startsWith('order_test_') || process.env.NODE_ENV === 'test';

    if (!isTestOrder && keySecret !== 'rzp_secret_placeholder') {
      const expectedSig = crypto
        .createHmac('sha256', keySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      if (expectedSig !== razorpay_signature) {
        return fastify.sendError(reply, 'Payment verification failed: invalid signature', 400);
      }
    }

    const fulfilled = await fulfillOrder(razorpay_order_id, razorpay_payment_id);
    if (!fulfilled) {
      return fastify.sendError(reply, 'Order not found', 404);
    }

    return fastify.sendSuccess(reply, {
      activated: true,
      tier: fulfilled.tier,
      expires_at: fulfilled.expires_at.toISOString(),
    });
  });

  // POST /payment/webhook — Razorpay webhook
  fastify.post('/webhook', async (req, reply) => {
    const signature = req.headers['x-razorpay-signature'];
    const webhookSecret = process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_WEBHOOK_SECRET;

    if (webhookSecret && signature) {
      const payloadString = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
      const expectedSig = crypto
        .createHmac('sha256', webhookSecret)
        .update(payloadString)
        .digest('hex');

      if (signature !== expectedSig) {
        return reply.code(400).send({ error: 'Invalid webhook signature' });
      }
    }

    const { event, payload } = req.body || {};

    if (event === 'payment.captured' || event === 'order.paid') {
      const orderId = payload?.payment?.entity?.order_id || payload?.order?.entity?.id;
      const paymentId = payload?.payment?.entity?.id;
      if (orderId) {
        await fulfillOrder(orderId, paymentId);
      }
    } else if (event === 'payment.failed') {
      const orderId = payload?.payment?.entity?.order_id;
      if (orderId) {
        await fastify.db.query(`
          UPDATE payment_orders SET status = 'failed' WHERE razorpay_order_id = $1
        `, [orderId]);
      }
    }

    return reply.send({ received: true });
  });

  // GET /payment/status — get current user's premium status
  fastify.get('/status', { onRequest: [fastify.authenticate] }, async (req, reply) => {
    const result = await fastify.db.query(`
      SELECT is_premium, premium_tier, premium_expires_at FROM users WHERE id = $1
    `, [req.user.uid]);
    return fastify.sendSuccess(reply, result.rows[0] || { is_premium: false });
  });
};
