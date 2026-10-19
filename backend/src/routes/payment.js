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
  async function fulfillOrder(orderId, paymentId, expectedUserId = null) {
    const orderResult = await fastify.db.query(`
      SELECT user_id, plan_id, amount, status FROM payment_orders WHERE razorpay_order_id = $1
    `, [orderId]);

    if (!orderResult.rows[0]) {
      return { notFound: true };
    }
    const { user_id, plan_id, status } = orderResult.rows[0];

    // Ownership verification guard
    if (expectedUserId && user_id !== expectedUserId) {
      return { forbidden: true };
    }

    const plan = PLANS[plan_id] || { duration_days: 30, tier: 'gold' };

    // Idempotency: If already fulfilled, return current state without double-extending or duplicate trust score
    if (status === 'paid') {
      const userRes = await fastify.db.query(`
        SELECT premium_tier, premium_expires_at FROM users WHERE id = $1
      `, [user_id]);
      const current = userRes.rows[0] || {};
      return {
        tier: current.premium_tier || plan.tier,
        expires_at: current.premium_expires_at ? new Date(current.premium_expires_at) : new Date(),
        already_fulfilled: true,
      };
    }

    // Atomic conditional update to prevent race conditions
    const updateOrder = await fastify.db.query(`
      UPDATE payment_orders
      SET status = 'paid', razorpay_payment_id = $1, paid_at = NOW()
      WHERE razorpay_order_id = $2 AND status != 'paid'
      RETURNING id
    `, [paymentId || 'captured_via_webhook', orderId]);

    if (updateOrder.rowCount === 0) {
      const userRes = await fastify.db.query(`
        SELECT premium_tier, premium_expires_at FROM users WHERE id = $1
      `, [user_id]);
      const current = userRes.rows[0] || {};
      return {
        tier: current.premium_tier || plan.tier,
        expires_at: current.premium_expires_at ? new Date(current.premium_expires_at) : new Date(),
        already_fulfilled: true,
      };
    }

    const expiresAt = new Date(Date.now() + plan.duration_days * 86400 * 1000);

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
        if (process.env.NODE_ENV === 'production') {
          fastify.log.error(`Razorpay order creation failed in production: ${err.message}`);
          return fastify.sendError(reply, 'Unable to create payment order at this time', 502);
        }
        fastify.log.warn(`Razorpay create failed, generating local test order: ${err.message}`);
        orderId = `order_test_${Date.now()}_${uuidv4().slice(0, 8)}`;
      }
    } else {
      if (process.env.NODE_ENV === 'production') {
        return fastify.sendError(reply, 'Payment gateway is not configured', 500);
      }
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
        required: ['razorpay_order_id', 'razorpay_payment_id', 'razorpay_signature'],
        properties: {
          razorpay_order_id: { type: 'string' },
          razorpay_payment_id: { type: 'string' },
          razorpay_signature: { type: 'string' },
        },
      },
    },
  }, async (req, reply) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const userId = req.user.uid;

    // Check order exists and belongs to this user before anything else
    const orderCheck = await fastify.db.query(`
      SELECT user_id, amount, status FROM payment_orders WHERE razorpay_order_id = $1
    `, [razorpay_order_id]);

    if (!orderCheck.rows[0]) {
      return fastify.sendError(reply, 'Order not found', 404);
    }

    if (orderCheck.rows[0].user_id !== userId) {
      return fastify.sendError(reply, 'Payment verification forbidden: order does not belong to authenticated user', 403);
    }

    if (orderCheck.rows[0].status === 'failed') {
      return fastify.sendError(reply, 'Order has already been marked failed', 400);
    }

    // Signature verification:
    // In production, fabricated order bypass is strictly prohibited.
    const isTestEnv = process.env.NODE_ENV === 'test';

    if (!isTestEnv) {
      if (!keySecret || keySecret === 'rzp_secret_placeholder') {
        fastify.log.error('Razorpay secret not configured in non-test environment');
        return fastify.sendError(reply, 'Payment gateway configuration error', 500);
      }

      const expectedSig = crypto
        .createHmac('sha256', keySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      const sigBuf = Buffer.from(razorpay_signature);
      const expBuf = Buffer.from(expectedSig);
      if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
        return fastify.sendError(reply, 'Payment verification failed: invalid signature', 400);
      }
    } else {
      // In explicit test mode (NODE_ENV === 'test'), allow controlled test signature fixture OR valid HMAC
      const expectedSig = crypto
        .createHmac('sha256', keySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      const isTestFixture = razorpay_signature === 'test_signature';
      const isValidHmac = razorpay_signature === expectedSig;

      if (!isTestFixture && !isValidHmac) {
        return fastify.sendError(reply, 'Payment verification failed: invalid signature', 400);
      }
    }

    const fulfilled = await fulfillOrder(razorpay_order_id, razorpay_payment_id, userId);
    if (!fulfilled || fulfilled.notFound) {
      return fastify.sendError(reply, 'Order not found', 404);
    }
    if (fulfilled.forbidden) {
      return fastify.sendError(reply, 'Payment verification forbidden: order does not belong to authenticated user', 403);
    }

    return fastify.sendSuccess(reply, {
      activated: true,
      tier: fulfilled.tier,
      expires_at: fulfilled.expires_at.toISOString(),
    });
  });

  // POST /payment/webhook — Razorpay webhook
  fastify.post('/webhook', async (req, reply) => {
    const webhookSecret = process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!webhookSecret) {
      fastify.log.error('Razorpay webhook secret is not configured');
      return reply.code(500).send({ error: 'Webhook secret is not configured' });
    }

    const signature = req.headers['x-razorpay-signature'];
    if (!signature) {
      return reply.code(400).send({ error: 'Missing webhook signature' });
    }

    // Verify against the exact raw request payload
    const rawPayload = typeof req.rawBody === 'string'
      ? req.rawBody
      : (typeof req.body === 'string' ? req.body : JSON.stringify(req.body));

    const expectedSig = crypto
      .createHmac('sha256', webhookSecret)
      .update(rawPayload)
      .digest('hex');

    const sigBuf = Buffer.from(signature);
    const expBuf = Buffer.from(expectedSig);
    if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
      return reply.code(400).send({ error: 'Invalid webhook signature' });
    }

    const { event, payload } = req.body || {};

    if (event === 'payment.captured' || event === 'order.paid') {
      const orderId = payload?.payment?.entity?.order_id || payload?.order?.entity?.id;
      const paymentId = payload?.payment?.entity?.id;
      const capturedAmount = payload?.payment?.entity?.amount;

      if (orderId) {
        // Validate amount against the server order if present
        if (capturedAmount !== undefined) {
          const orderCheck = await fastify.db.query(`
            SELECT amount FROM payment_orders WHERE razorpay_order_id = $1
          `, [orderId]);
          if (orderCheck.rows[0] && orderCheck.rows[0].amount !== capturedAmount) {
            fastify.log.error(`Payment amount mismatch for order ${orderId}: expected ${orderCheck.rows[0].amount}, got ${capturedAmount}`);
            return reply.code(400).send({ error: 'Payment amount mismatch' });
          }
        }

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
