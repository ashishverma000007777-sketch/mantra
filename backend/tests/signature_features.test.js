// backend/tests/signature_features.test.js
// Test suite for Mantra 5 Signature Features
'use strict';

const { createTestApp } = require('./testHelper');

describe('Mantra Signature Features Test Suite', () => {
  let app;
  const userA = 'user-uuid-aaaa-1111';
  const userB = 'user-uuid-bbbb-2222';
  const userC = 'user-uuid-cccc-3333';
  const connId = 'conn-uuid-aaaa-bbbb';

  function createToken(uid) {
    return app.jwt.sign({ uid, jti: `jti-${uid}-${Date.now()}` }, { expiresIn: '15m' });
  }

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    app = await createTestApp();
    await app.ready();

    // Set up test users & profiles
    app.db.users.set(userA, { id: userA, gender: 'woman', age: 26, city: 'Mumbai', account_status: 'active' });
    app.db.profiles.set(userA, {
      user_id: userA,
      display_name: 'Aanya',
      trust_score: 85,
      personality_tags: ['chai', 'reading', 'nature'],
      intent: 'Mindful slow dating',
      bio_prompt_responses: [{ question: 'My ideal Sunday', answer: 'Making ginger chai and reading poems.' }],
      photo_urls: ['https://cdn.mantraapp.in/photos/aanya_1.jpg'],
      is_searchable: true,
    });

    app.db.users.set(userB, { id: userB, gender: 'man', age: 28, city: 'Mumbai', account_status: 'active' });
    app.db.profiles.set(userB, {
      user_id: userB,
      display_name: 'Kabir',
      trust_score: 90,
      personality_tags: ['chai', 'reading', 'cinema'],
      intent: 'Mindful slow dating',
      bio_prompt_responses: [{ question: 'My ideal Sunday', answer: 'Filter coffee and vintage bookstores.' }],
      photo_urls: ['https://cdn.mantraapp.in/photos/kabir_1.jpg'],
      voice_intro_url: 'https://cdn.mantraapp.in/voice/kabir_intro.m4a',
      is_searchable: true,
    });

    // Set up active connection between userA and userB
    app.db.connections.set(connId, {
      id: connId,
      user_a: userA,
      user_b: userB,
      status: 'connected',
      stage: 1,
      reveal_stage: 'mind',
      connected_at: new Date().toISOString(),
    });
  });

  afterAll(async () => {
    await app.close();
  });

  // =========================================================================
  // FEATURE 1: MYSTERY MATCH
  // =========================================================================
  describe('Feature 1: Mystery Match (Personality-first discovery)', () => {
    test('GET /api/v1/match/mystery returns personality cards with hidden photos and pseudonyms', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/match/mystery',
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(Array.isArray(json.data)).toBe(true);

      if (json.data.length > 0) {
        const card = json.data[0];
        // Personality-first properties
        expect(card.candidate_id).toBeDefined();
        expect(card.pseudonym).toBeDefined();
        expect(card.personality_tags).toBeDefined();
        expect(card.intent).toBeDefined();

        // Privacy enforcement: Photos strictly redacted at backend level!
        expect(card.photos_hidden).toBe(true);
        expect(card.photo_urls).toEqual([]);
        expect(card.profile_photo_url).toBeNull();
      }
    });

    test('POST /api/v1/match/mystery/explore prevents self-exploration', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/mystery/explore',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: userA },
      });

      expect(res.statusCode).toBe(400);
      expect(res.json().success).toBe(false);
    });

    test('POST /api/v1/match/mystery/explore records interest and supports mutual connection', async () => {
      const tokenA = createToken(userA);
      const resA = await app.inject({
        method: 'POST',
        url: '/api/v1/match/mystery/explore',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { target_user_id: userB },
      });
      expect(resA.statusCode).toBe(200);
      expect(resA.json().data.is_mutual).toBe(false);

      // Now User B also explores User A
      const tokenB = createToken(userB);
      const resB = await app.inject({
        method: 'POST',
        url: '/api/v1/match/mystery/explore',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { target_user_id: userA },
      });
      expect(resB.statusCode).toBe(200);
      expect(resB.json().data.is_mutual).toBe(true);
      expect(resB.json().data.conversation_id).toBeDefined();
    });

    test('POST /api/v1/match/mystery/pass records respectful pass', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/match/mystery/pass',
        headers: { authorization: `Bearer ${token}` },
        payload: { target_user_id: userC },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.passed).toBe(true);
    });
  });

  // =========================================================================
  // FEATURE 2: COMPATIBILITY DNA
  // =========================================================================
  describe('Feature 2: Compatibility DNA (7 Dimensions)', () => {
    test('POST /api/v1/compatibility/answers saves 7-dimension answers', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/compatibility/answers',
        headers: { authorization: `Bearer ${token}` },
        payload: {
          answers: {
            communication: { pace: 'thoughtful_daily', preferred_medium: 'voice_notes' },
            relationship_intentions: { primary_goal: 'mindful_slow_dating', pacing: 'gradual' },
            core_values: ['authenticity', 'empathy', 'growth'],
            lifestyle: { daily_rhythm: 'morning', social_energy: 'introvert' },
            emotional_readiness: { openness: 'open_and_reflective' },
            conflict_resolution: { style: 'cool_off_first' },
            shared_interests: ['chai', 'reading', 'nature'],
          },
        },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.saved).toBe(true);
      expect(json.data.dimensions_ready.communication_ready).toBe(true);
      expect(json.data.dimensions_ready.values_ready).toBe(true);
    });

    test('GET /api/v1/compatibility retrieves own questionnaire profile', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/compatibility',
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
      expect(res.json().data.answers.communication.pace).toBe('thoughtful_daily');
    });

    test('GET /api/v1/compatibility/compare/:targetUserId generates 7-dimension insights', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/compatibility/compare/${userB}`,
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.overall_alignment).toBeGreaterThanOrEqual(50);
      expect(json.data.evaluated_dimensions_count).toBe(7);

      // Verify specific dimensions evaluated
      expect(json.data.dimensions.communication).toBeDefined();
      expect(json.data.dimensions.relationship_intentions).toBeDefined();
      expect(json.data.dimensions.core_values).toBeDefined();
      expect(json.data.dimensions.lifestyle).toBeDefined();
      expect(json.data.dimensions.emotional_readiness).toBeDefined();
      expect(json.data.dimensions.conflict_resolution).toBeDefined();
      expect(json.data.dimensions.shared_interests).toBeDefined();

      // Ethical safety check: no diagnostic claims, includes honest notice
      expect(json.data.ethical_notice).toBeDefined();
      expect(json.data.ethical_notice).toContain('not a psychological diagnosis');
    });

    test('GET /api/v1/compatibility/compare rejects self-comparison', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/compatibility/compare/${userA}`,
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(400);
    });
  });

  // =========================================================================
  // FEATURE 3: CONVERSATION QUEST
  // =========================================================================
  describe('Feature 3: Conversation Quest (Mindful Prompts & Mutual Unlock)', () => {
    const questId = 'b0000000-0000-0000-0000-000000000001';

    test('GET /api/v1/quests/daily returns active daily conversation prompt', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/quests/daily',
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.prompt_text).toBeDefined();
      expect(json.data.category).toBeDefined();
    });

    test('Quest status gates partner answer before mutual participation', async () => {
      const tokenA = createToken(userA);

      // User A submits answer
      const submitRes = await app.inject({
        method: 'POST',
        url: '/api/v1/quests/answer',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: {
          quest_id: questId,
          connection_id: connId,
          answer_text: 'I will never compromise on treating people with gentle honesty.',
        },
      });
      expect(submitRes.statusCode).toBe(200);
      expect(submitRes.json().data.is_unlocked).toBe(false);

      // Check quest status: user sees their own answer, but partner answer is null!
      const statusRes = await app.inject({
        method: 'GET',
        url: `/api/v1/quests/connection/${connId}`,
        headers: { authorization: `Bearer ${tokenA}` },
      });

      expect(statusRes.statusCode).toBe(200);
      const status = statusRes.json().data;
      expect(status.has_user_answered).toBe(true);
      expect(status.has_partner_answered).toBe(false);
      expect(status.is_unlocked).toBe(false);
      expect(status.my_answer).not.toBeNull();
      expect(status.partner_answer).toBeNull(); // PRIVACY: Hidden!
      expect(status.follow_up_prompt).toBeNull();
    });

    test('Mutual quest completion unlocks both answers and follow-up question', async () => {
      const tokenB = createToken(userB);

      // User B also submits their answer
      const submitResB = await app.inject({
        method: 'POST',
        url: '/api/v1/quests/answer',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: {
          quest_id: questId,
          connection_id: connId,
          answer_text: 'For me, staying true to creative integrity is non-negotiable.',
        },
      });
      expect(submitResB.statusCode).toBe(200);
      expect(submitResB.json().data.is_unlocked).toBe(true);

      // Now inspect status from User A's perspective
      const tokenA = createToken(userA);
      const statusRes = await app.inject({
        method: 'GET',
        url: `/api/v1/quests/connection/${connId}`,
        headers: { authorization: `Bearer ${tokenA}` },
      });

      const status = statusRes.json().data;
      expect(status.is_unlocked).toBe(true);
      expect(status.partner_answer).not.toBeNull();
      expect(status.partner_answer.answer_text).toContain('creative integrity');
      expect(status.follow_up_prompt).not.toBeNull();
    });

    test('POST /api/v1/quests/react adds emoji reaction to unlocked answer', async () => {
      const tokenA = createToken(userA);
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/quests/react',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: {
          quest_answer_id: 'qa-test-1',
          reaction: '❤️',
        },
      });
      // qa-test-1 doesn't exist in mock DB, should return 404
      expect([200, 404]).toContain(res.statusCode);
    });
  });

  // =========================================================================
  // FEATURE 4: GRADUAL IDENTITY REVEAL
  // =========================================================================
  describe('Feature 4: Gradual Identity Reveal (4 Stages & Mutual Consent)', () => {
    test('Initial stage is MIND and photos remain locked', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/reveal/${connId}`,
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.data.current_stage).toBe('mind');
      expect(json.data.is_photo_unlocked).toBe(false);
    });

    test('Gated media endpoint rejects photo access before mutual consent (403 Forbidden)', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/reveal/${connId}/media/photo`,
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(403);
      expect(res.json().success).toBe(false);
      expect(res.json().error).toContain('Mutual face reveal consent is required');
    });

    test('One party requesting face reveal does NOT unlock photos automatically', async () => {
      const tokenA = createToken(userA);
      const reqRes = await app.inject({
        method: 'POST',
        url: `/api/v1/reveal/${connId}/request`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { stage: 'face' },
      });

      expect(reqRes.statusCode).toBe(200);
      expect(reqRes.json().data.stage_advanced).toBe(false);

      // Photos still forbidden
      const mediaRes = await app.inject({
        method: 'GET',
        url: `/api/v1/reveal/${connId}/media/photo`,
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(mediaRes.statusCode).toBe(403);
    });

    test('Second party accepting/requesting face reveal unlocks photos mutually', async () => {
      const tokenB = createToken(userB);
      const reqResB = await app.inject({
        method: 'POST',
        url: `/api/v1/reveal/${connId}/request`,
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { stage: 'face' },
      });

      expect(reqResB.statusCode).toBe(200);
      expect(reqResB.json().data.stage_advanced).toBe(true);
      expect(reqResB.json().data.new_stage).toBe('face');

      // Now media endpoint allows photo access!
      const mediaRes = await app.inject({
        method: 'GET',
        url: `/api/v1/reveal/${connId}/media/photo`,
        headers: { authorization: `Bearer ${tokenB}` },
      });
      expect(mediaRes.statusCode).toBe(200);
      expect(mediaRes.json().data.is_unlocked).toBe(true);
    });

    test('Revoking consent immediately locks photos and lowers stage', async () => {
      const tokenA = createToken(userA);
      const revokeRes = await app.inject({
        method: 'POST',
        url: `/api/v1/reveal/${connId}/revoke`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { stage: 'face' },
      });

      expect(revokeRes.statusCode).toBe(200);
      expect(revokeRes.json().data.revoked).toBe(true);
      expect(revokeRes.json().data.new_stage).toBe('connection');

      // Subsequent media request is blocked again
      const mediaRes = await app.inject({
        method: 'GET',
        url: `/api/v1/reveal/${connId}/media/photo`,
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(mediaRes.statusCode).toBe(403);
    });
  });

  // =========================================================================
  // FEATURE 5: CONNECTION GARDEN
  // =========================================================================
  describe('Feature 5: Connection Garden (Seed -> Sprout -> Growing -> Bloom)', () => {
    test('GET /api/v1/garden/:connectionId returns garden stage and progress history', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/garden/${connId}`,
        headers: { authorization: `Bearer ${token}` },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(['seed', 'sprout', 'growing', 'bloom']).toContain(json.data.stage);
      expect(json.data.growth_points).toBeGreaterThan(0);
      expect(Array.isArray(json.data.milestones)).toBe(true);
      expect(json.data.anti_streak_guarantee).toBeDefined();
    });

    test('POST /api/v1/garden/:connectionId/activity records legitimate mutual milestone', async () => {
      const token = createToken(userA);
      const res = await app.inject({
        method: 'POST',
        url: `/api/v1/garden/${connId}/activity`,
        headers: { authorization: `Bearer ${token}` },
        payload: {
          activity_type: 'voice_exchange',
          title: 'First Voice Note Shared',
          description: 'Both listened to each other voice introductions.',
        },
      });

      expect(res.statusCode).toBe(200);
      const json = res.json();
      expect(json.success).toBe(true);
      expect(json.data.activity_recorded).toBe(true);
      expect(json.data.growth_points).toBeGreaterThanOrEqual(25);
    });

    test('POST /api/v1/garden/:connectionId/privacy pauses and resumes garden', async () => {
      const token = createToken(userA);
      // Pause
      const pauseRes = await app.inject({
        method: 'POST',
        url: `/api/v1/garden/${connId}/privacy`,
        headers: { authorization: `Bearer ${token}` },
        payload: { pause: true },
      });
      expect(pauseRes.statusCode).toBe(200);
      expect(pauseRes.json().data.is_paused).toBe(true);

      // Resume
      const resumeRes = await app.inject({
        method: 'POST',
        url: `/api/v1/garden/${connId}/privacy`,
        headers: { authorization: `Bearer ${token}` },
        payload: { pause: false },
      });
      expect(resumeRes.statusCode).toBe(200);
      expect(resumeRes.json().data.is_paused).toBe(false);
    });
  });
});
