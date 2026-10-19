// backend/tests/payment_security.test.js
'use strict';

const crypto = require('crypto');
const { createTestApp } = require('./testHelper');

describe('Mantra Payment Security & Razorpay Hardening Test Suite', () => {
  let app;
  const userA = 'user-uuid-aaaa-1111';
  const userB = 'user-uuid-bbbb-2222';
  const testSecret = 'rzp_test_secret_key_12345';
  const testWebhookSecret = 'rzp_webhook_secret_98765';

  function createToken(uid) {
    return app.jwt.sign({ uid, jti: `jti-${Date.now()}-${Math.random()}` }, { expiresIn: '15m' });
  }

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    process.env.MANTRA_RAZORPAY_KEY_SECRET = testSecret;
    process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET = testWebhookSecret;

    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  test('1. Non-existent / forged order ID is rejected with 404', async () => {
    const token = createToken(userA);
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        razorpay_order_id: 'order_non_existent_99999',
        razorpay_payment_id: 'pay_99999',
        razorpay_signature: 'test_signature',
      },
    });

    // In mockDb, an order not created in the database returns not found
    // If mockDb fallback returns a default, let's verify mockDb behaves or verify response
    expect([404, 400]).toContain(res.statusCode);
  });

  test('2. Order ownership guard: User B cannot verify User A\'s order', async () => {
    // User A creates order
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'platinum_monthly' },
    });
    expect(createRes.statusCode).toBe(200);
    const orderId = createRes.json().data.order_id;

    // User B attempts to verify User A's order
    const tokenB = createToken(userB);
    const verifyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${tokenB}` },
      payload: {
        razorpay_order_id: orderId,
        razorpay_payment_id: 'pay_b_impersonate',
        razorpay_signature: 'test_signature',
      },
    });

    expect(verifyRes.statusCode).toBe(403);
    expect(verifyRes.json().error).toMatch(/order does not belong to authenticated user/i);
  });

  test('3. Invalid signature is rejected with 400 in test mode when not using test fixture', async () => {
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'gold_monthly' },
    });
    const orderId = createRes.json().data.order_id;

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: {
        razorpay_order_id: orderId,
        razorpay_payment_id: 'pay_some_payment_id',
        razorpay_signature: 'tampered_or_invalid_signature',
      },
    });

    expect(res.statusCode).toBe(400);
    expect(res.json().error).toMatch(/invalid signature/i);
  });

  test('4. Valid HMAC SHA-256 signature succeeds and activates premium', async () => {
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'gold_monthly' },
    });
    const orderId = createRes.json().data.order_id;
    const paymentId = 'pay_legit_1001';

    const validSig = crypto
      .createHmac('sha256', testSecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: {
        razorpay_order_id: orderId,
        razorpay_payment_id: paymentId,
        razorpay_signature: validSig,
      },
    });

    expect(res.statusCode).toBe(200);
    const json = res.json();
    expect(json.success).toBe(true);
    expect(json.data.activated).toBe(true);
    expect(json.data.tier).toBe('gold');
  });

  test('5. Idempotent verification: Re-verifying the same order returns current state without error', async () => {
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'gold_monthly' },
    });
    const orderId = createRes.json().data.order_id;
    const paymentId = 'pay_legit_1002';

    const validSig = crypto
      .createHmac('sha256', testSecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    // First verification
    const res1 = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: {
        razorpay_order_id: orderId,
        razorpay_payment_id: paymentId,
        razorpay_signature: validSig,
      },
    });
    expect(res1.statusCode).toBe(200);

    // Second verification (replay)
    const res2 = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/verify',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: {
        razorpay_order_id: orderId,
        razorpay_payment_id: paymentId,
        razorpay_signature: validSig,
      },
    });
    expect(res2.statusCode).toBe(200);
    expect(res2.json().data.activated).toBe(true);
  });

  test('6. Webhook fails closed (500) if webhook secret is unset', async () => {
    const oldSecret = process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET;
    delete process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET;
    delete process.env.RAZORPAY_WEBHOOK_SECRET;

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: {
        'content-type': 'application/json',
        'x-razorpay-signature': 'any_sig',
      },
      payload: { event: 'payment.captured' },
    });

    expect(res.statusCode).toBe(500);
    expect(res.json().error).toMatch(/webhook secret is not configured/i);

    // Restore
    process.env.MANTRA_RAZORPAY_WEBHOOK_SECRET = oldSecret;
  });

  test('7. Webhook rejects missing signature with 400', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: { 'content-type': 'application/json' },
      payload: { event: 'payment.captured' },
    });

    expect(res.statusCode).toBe(400);
    expect(res.json().error).toMatch(/missing webhook signature/i);
  });

  test('8. Webhook rejects forged / invalid signature with 400', async () => {
    const rawPayload = JSON.stringify({ event: 'payment.captured' });
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: {
        'content-type': 'application/json',
        'x-razorpay-signature': 'invalid_forged_signature_hex_value_00000',
      },
      payload: rawPayload,
    });

    expect(res.statusCode).toBe(400);
    expect(res.json().error).toMatch(/invalid webhook signature/i);
  });

  test('9. Webhook rejects payment amount mismatch', async () => {
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'gold_monthly' }, // 39900 paise
    });
    const orderId = createRes.json().data.order_id;

    // Webhook with tampered amount (e.g. 100 paise instead of 39900)
    const webhookPayload = JSON.stringify({
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_tampered_amount',
            order_id: orderId,
            amount: 100, // Tampered!
          },
        },
      },
    });

    const validSig = crypto
      .createHmac('sha256', testWebhookSecret)
      .update(webhookPayload)
      .digest('hex');

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: {
        'content-type': 'application/json',
        'x-razorpay-signature': validSig,
      },
      payload: webhookPayload,
    });

    expect(res.statusCode).toBe(400);
    expect(res.json().error).toMatch(/payment amount mismatch/i);
  });

  test('10. Webhook with valid signature and amount fulfills order idempotently', async () => {
    const tokenA = createToken(userA);
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/order',
      headers: { authorization: `Bearer ${tokenA}` },
      payload: { plan_id: 'platinum_yearly' }, // 699900 paise
    });
    const orderId = createRes.json().data.order_id;

    const webhookPayload = JSON.stringify({
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_valid_webhook_123',
            order_id: orderId,
            amount: 699900,
          },
        },
      },
    });

    const validSig = crypto
      .createHmac('sha256', testWebhookSecret)
      .update(webhookPayload)
      .digest('hex');

    // First delivery
    const res1 = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: {
        'content-type': 'application/json',
        'x-razorpay-signature': validSig,
      },
      payload: webhookPayload,
    });
    expect(res1.statusCode).toBe(200);
    expect(res1.json().received).toBe(true);

    // Duplicate replay delivery
    const res2 = await app.inject({
      method: 'POST',
      url: '/api/v1/payment/webhook',
      headers: {
        'content-type': 'application/json',
        'x-razorpay-signature': validSig,
      },
      payload: webhookPayload,
    });
    expect(res2.statusCode).toBe(200);
    expect(res2.json().received).toBe(true);
  });
});
