// backend/tests/api.test.js
'use strict';

const { createTestApp } = require('./testHelper');

describe('Mantra Fastify API Integration Test Suite', () => {
  let app;
  let testUserId = 'test-user-uuid-1234';

  function createToken(uid = testUserId, jti = `jti-${Date.now()}-${Math.random()}`) {
    return app.jwt.sign({ uid, jti }, { expiresIn: '15m' });
  }

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('1. System & Health Endpoints', () => {
    test('GET /health returns 200 ok', async () => {
      const res = await app.inject({ method: 'GET', url: '/health' });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.status).toBe('ok');
      expect(json.service).toBe('mantra-backend');
    });

    test('GET / returns API info', async () => {
      const res = await app.inject({ method: 'GET', url: '/' });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.name).toBe('Mantra Dating API');
    });
  });

  describe('2. Authentication & Session Lifecycle', () => {
    test('POST /api/v1/auth/register fails without authorization header', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/register',
        payload: {},
      });
      expect(res.statusCode).toBe(401);
    });

    test('POST /api/v1/auth/register succeeds with test token', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/register',
        headers: { authorization: 'Bearer test_token_user999' },
        payload: { fcm_token: 'test_fcm_token_12345' },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.access_token).toBeDefined();
      expect(json.data.refresh_token).toBeDefined();
      expect(json.data.user.id).toBeDefined();
    });

    test('GET /api/v1/auth/me returns current user profile info', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.id).toBe(testUserId);
    });

    test('POST /api/v1/auth/refresh rotates refresh token', async () => {
      const refreshToken = app.jwt.sign({ uid: testUserId, type: 'refresh', jti: 'ref-1' });
      await app.redis.setEx(`refresh:${testUserId}`, 3600, refreshToken);

      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/refresh',
        payload: { refresh_token: refreshToken },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.access_token).toBeDefined();
      expect(json.data.refresh_token).toBeDefined();
    });

    test('POST /api/v1/auth/fcm-token registers device push token', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/fcm-token',
        headers: { authorization: `Bearer ${token}` },
        payload: { fcm_token: 'valid_fcm_token_xyz_67890' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.registered).toBe(true);
    });

    test('POST /api/v1/auth/logout invalidates session and revokes JTI', async () => {
      const logoutJti = 'logout-jti-unique';
      const token = createToken(testUserId, logoutJti);

      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/logout',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.logged_out).toBe(true);

      // Verify that this token is now rejected due to blacklist
      const retryRes = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(retryRes.statusCode).toBe(401);
    });
  });

  describe('3. Profile Management', () => {
    test('GET /api/v1/profile returns user profile', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/profile',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.prompt_responses).toBeDefined();
    });

    test('POST /api/v1/profile updates profile and calculates completeness', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/profile',
        headers: { authorization: `Bearer ${token}` },
        payload: {
          display_name: 'Priya Sharma',
          gender: 'woman',
          age: 26,
          city: 'Mumbai',
          intent: 'meaningful_dating',
          personality_tags: ['chai', 'indie_music', 'film_aficionado'],
          bio_prompt_responses: [
            { question: 'A slow Sunday to me is', answer: 'Filter coffee and a classic book.' },
          ],
        },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.updated).toBe(true);
    });

    test('PATCH /api/v1/profile/settings updates privacy preferences', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'PATCH',
        url: '/api/v1/profile/settings',
        headers: { authorization: `Bearer ${token}` },
        payload: { photos_blurred: false, women_only_mode: true },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.updated).toBe(true);
    });
  });

  describe('4. Daily Sparks & Matching Engine', () => {
    test('GET /api/v1/match/sparks returns Daily 7 candidates', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/match/sparks',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(Array.isArray(json.data)).toBe(true);
      if (json.data.length > 0) {
        expect(json.data[0].compatibility_score).toBeGreaterThan(0);
        expect(json.data[0].trust_score).toBeDefined();
      }
    });

    test('POST /api/v1/match/connect prevents self-connection', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/connect',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: testUserId },
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error).toContain('Cannot connect with yourself');
    });

    test('POST /api/v1/match/connect connects with a target candidate', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/connect',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: 'target-candidate-uuid-9999' },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.is_mutual).toBeDefined();
    });

    test('POST /api/v1/match/save bookmarks spark', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/save',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: 'target-candidate-uuid-9999' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.saved).toBe(true);
    });

    test('POST /api/v1/match/pass passes spark', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/pass',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: 'target-candidate-uuid-9999' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.passed).toBe(true);
    });
  });

  describe('5. Chat & Messaging Workflows', () => {
    const connId = 'conn-uuid-1111';

    test('GET /api/v1/chat/conversations lists conversations', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/chat/conversations',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
    });

    test('POST /api/v1/chat/:connectionId/messages sends a message', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: `/api/v1/chat/${connId}/messages`,
        headers: { authorization: `Bearer ${token}` },
        payload: { content: 'Hi there! Loved your bio prompt.', message_type: 'text' },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.message_id).toBeDefined();
    });

    test('POST /api/v1/chat/:connectionId/reveal authorizes photo reveal', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: `/api/v1/chat/${connId}/reveal`,
        headers: { authorization: `Bearer ${token}` },
        payload: { type: 'photo' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.revealed).toBe(true);
      expect(res.json().data.type).toBe('photo');
    });
  });

  describe('6. Community Rooms', () => {
    test('GET /api/v1/rooms returns room list with emoji and color fields', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/rooms',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(Array.isArray(json.data)).toBe(true);
      expect(json.data[0].emoji).toBeDefined();
      expect(json.data[0].color).toBeDefined();
    });

    test('POST /api/v1/rooms/join joins room', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/rooms/join',
        headers: { authorization: `Bearer ${token}` },
        payload: { room_id: 'a0000000-0000-0000-0000-000000000001' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.joined).toBe(true);
    });
  });

  describe('7. Safety, Moderation & Emergency SOS', () => {
    test('POST /api/v1/safety/report submits user report', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/safety/report',
        headers: { authorization: `Bearer ${token}` },
        payload: { reported_user_id: 'bad-actor-uuid', reason: 'harassment', note: 'Offensive language' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
    });

    test('POST /api/v1/safety/block blocks a user', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/safety/block',
        headers: { authorization: `Bearer ${token}` },
        payload: { blocked_user_id: 'bad-actor-uuid', reason: 'Unwanted contact' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.blocked).toBe(true);
    });

    test('POST /api/v1/safety/trusted-contacts adds emergency contact', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/safety/trusted-contacts',
        headers: { authorization: `Bearer ${token}` },
        payload: { name: 'Pooja Sister', phone: '+919876543210' },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.added).toBe(true);
    });

    test('POST /api/v1/safety/sos triggers emergency alert with GPS coordinates', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/safety/sos',
        headers: { authorization: `Bearer ${token}` },
        payload: { latitude: 19.0760, longitude: 72.8777 },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.contacts_alerted).toBeGreaterThanOrEqual(0);
    });
  });

  describe('8. Premium Memberships & Razorpay Lifecycle', () => {
    let orderId;

    test('POST /api/v1/payment/order creates Razorpay order', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/payment/order',
        headers: { authorization: `Bearer ${token}` },
        payload: { plan_id: 'gold_monthly' },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.order_id).toBeDefined();
      orderId = json.data.order_id;
    });

    test('POST /api/v1/payment/verify activates premium', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/payment/verify',
        headers: { authorization: `Bearer ${token}` },
        payload: {
          razorpay_order_id: orderId,
          razorpay_payment_id: 'pay_test_123456',
          razorpay_signature: 'test_signature',
        },
      });
      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.activated).toBe(true);
      expect(json.data.tier).toBe('gold');
    });

    test('GET /api/v1/payment/status returns membership tier', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/payment/status',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
    });
  });

  describe('9. Admin Operations & Role Guards', () => {
    test('GET /api/v1/admin/dashboard forbidden for regular users', async () => {
      const token = createToken();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/admin/dashboard',
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(403);
    });
  });
});
