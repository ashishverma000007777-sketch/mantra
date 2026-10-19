// backend/src/routes/match.js
'use strict';

const crypto = require('crypto');

module.exports = async function matchRoutes(fastify) {
  // GET /match/sparks — Daily 7
  fastify.get('/sparks', {
    onRequest: [fastify.authenticate],
    config: {
      rateLimit: { max: 20, timeWindow: '1 hour' },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;

    // Check cache
    const todayStr = new Date().toISOString().slice(0, 10);
    const cacheKey = `sparks:${userId}:${todayStr}`;
    if (fastify.redis && fastify.redis.get) {
      const cached = await fastify.redis.get(cacheKey);
      if (cached) {
        return fastify.sendSuccess(reply, JSON.parse(cached));
      }
    }

    // Get user's profile for matching
    const userProfile = await fastify.db.query(`
      SELECT p.*, u.gender, u.age, u.city, u.is_premium
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      WHERE p.user_id = $1
    `, [userId]);

    if (!userProfile.rows[0]) {
      return fastify.sendError(reply, 'Profile not found. Please complete profile setup.', 404);
    }

    const me = userProfile.rows[0];

    // Get already-seen profiles from past 30 days
    const seenResult = await fastify.db.query(`
      SELECT target_user_id FROM sparks_delivered
      WHERE user_id = $1 AND delivered_at > NOW() - INTERVAL '30 days'
    `, [userId]);

    const seenIds = seenResult.rows.map(r => r.target_user_id);
    const excludeIds = [...seenIds, userId];

    // Get blocked users
    const blockedResult = await fastify.db.query(`
      SELECT blocked_id as id FROM blocks WHERE blocker_id = $1
      UNION
      SELECT blocker_id as id FROM blocks WHERE blocked_id = $1
    `, [userId]);

    const blockedIds = blockedResult.rows.map(r => r.id);
    const allExcludeIds = [...new Set([...excludeIds, ...blockedIds])];

    // Gender filter (preference-based)
    const genderFilter = me.gender === 'woman' ? 'man' : 'woman';
    const minAge = Math.max(18, (me.age || 25) - 5);
    const maxAge = Math.min(100, (me.age || 25) + 7);

    // Fetch candidates (top 50 by trust score + last active)
    const candidatesResult = await fastify.db.query(`
      SELECT 
        p.user_id, p.display_name, p.trust_score, p.personality_tags,
        p.voice_intro_url, p.photos_blurred, p.photo_urls,
        p.bio_prompt_responses as prompt_responses,
        u.age, u.city, u.gender, u.verification_level,
        CASE WHEN u.verification_level >= 3 THEN true ELSE false END as is_verified
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      WHERE 
        u.id != ALL($1::uuid[])
        AND (u.gender = $2 OR u.gender IS NULL)
        AND (u.age BETWEEN $3 AND $4 OR u.age IS NULL)
        AND p.is_searchable = true
        AND u.account_status = 'active'
        AND u.last_active > NOW() - INTERVAL '30 days'
        AND ($5 = 'woman' AND p.trust_score >= 50 OR $5 != 'woman')
      ORDER BY p.trust_score DESC, u.last_active DESC
      LIMIT 50
    `, [allExcludeIds, genderFilter, minAge, maxAge, me.gender || 'man']);

    const candidates = candidatesResult.rows;

    // Score each candidate
    const myTags = new Set(me.personality_tags || []);
    const scored = candidates.map(c => {
      const theirTags = new Set(c.personality_tags || []);
      const tagOverlap = [...myTags].filter(t => theirTags.has(t)).length;
      const tagScore = tagOverlap / Math.max(myTags.size + theirTags.size, 1);

      const trustScore = (parseFloat(c.trust_score) || 50) / 100;
      const cityBonus = c.city && me.city && c.city.toLowerCase() === me.city.toLowerCase() ? 0.1 : 0;
      const verifiedBonus = c.is_verified ? 0.05 : 0;

      const total = (tagScore * 0.4) + (trustScore * 0.35) + cityBonus + verifiedBonus;
      const compatibilityPct = Math.round(Math.min(total * 100 + 30, 99));

      return { ...c, compatibility_score: compatibilityPct, _score: total };
    });

    // Sort and take top 7
    scored.sort((a, b) => b._score - a._score);
    const top7 = scored.slice(0, 7).map(({ _score, photo_urls, ...rest }) => ({
      ...rest,
      profile_photo_url: photo_urls?.[0] || null,
      interests: rest.personality_tags || [],
      shared_interests: [...myTags].filter(t => new Set(rest.personality_tags || []).has(t)),
      shared_rooms_count: 0,
      voice_duration_seconds: 32,
    }));

    // Cache for 24h
    if (fastify.redis && fastify.redis.setEx) {
      await fastify.redis.setEx(cacheKey, 86400, JSON.stringify(top7));
    }

    // Log delivered sparks
    if (top7.length > 0) {
      for (let i = 0; i < top7.length; i++) {
        await fastify.db.query(`
          INSERT INTO sparks_delivered (user_id, target_user_id, delivered_at, rank_position)
          VALUES ($1, $2, NOW(), $3)
          ON CONFLICT (user_id, target_user_id) DO NOTHING
        `, [userId, top7[i].user_id, i + 1]);
      }
    }

    return fastify.sendSuccess(reply, top7, { count: top7.length });
  });

  // POST /match/connect — Express interest
  fastify.post('/connect', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['target_user_id'],
        properties: { target_user_id: { type: 'string' } },
      },
    },
  }, async (req, reply) => {
    const { target_user_id } = req.body;
    const userId = req.user.uid;

    if (target_user_id === userId) {
      return fastify.sendError(reply, 'Cannot connect with yourself', 400);
    }

    // Update spark action
    await fastify.db.query(`
      INSERT INTO sparks_delivered (user_id, target_user_id, action, action_at)
      VALUES ($1, $2, 'connect', NOW())
      ON CONFLICT (user_id, target_user_id) DO UPDATE SET action = 'connect', action_at = NOW()
    `, [userId, target_user_id]);

    // Check if target user previously clicked connect on me
    const mutualResult = await fastify.db.query(`
      SELECT id FROM sparks_delivered
      WHERE user_id = $1 AND target_user_id = $2 AND action = 'connect'
    `, [target_user_id, userId]);

    let conversationId = null;
    let isMutual = false;

    if (mutualResult.rows.length > 0) {
      isMutual = true;

      // Ordered pair for unique constraint
      const [a, b] = [userId, target_user_id].sort();
      const connResult = await fastify.db.query(`
        INSERT INTO connections (id, user_a, user_b, status, stage, initiated_by, connected_at)
        VALUES ($1, $2, $3, 'connected', 1, $4, NOW())
        ON CONFLICT (user_a, user_b) DO UPDATE SET status = 'connected', connected_at = NOW()
        RETURNING id
      `, [crypto.randomUUID(), a, b, userId]);

      conversationId = connResult.rows[0].id;

      // Notify target user via redis pubsub
      if (fastify.redis && fastify.redis.publish) {
        await fastify.redis.publish('notifications', JSON.stringify({
          type: 'mutual_connect',
          target_user_id,
          data: { from_user_id: userId, conversation_id: conversationId },
        }));
      }
    }

    return fastify.sendSuccess(reply, { is_mutual: isMutual, conversation_id: conversationId });
  });

  // POST /match/pass — Pass on profile
  fastify.post('/pass', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['target_user_id'],
        properties: { target_user_id: { type: 'string' } },
      },
    },
  }, async (req, reply) => {
    const { target_user_id } = req.body;
    await fastify.db.query(`
      INSERT INTO sparks_delivered (user_id, target_user_id, action, action_at)
      VALUES ($1, $2, 'pass', NOW())
      ON CONFLICT (user_id, target_user_id) DO UPDATE SET action = 'pass', action_at = NOW()
    `, [req.user.uid, target_user_id]);

    return fastify.sendSuccess(reply, { passed: true });
  });

  // POST /match/save — Bookmark spark
  fastify.post('/save', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['target_user_id'],
        properties: { target_user_id: { type: 'string' } },
      },
    },
  }, async (req, reply) => {
    const { target_user_id } = req.body;
    await fastify.db.query(`
      INSERT INTO sparks_delivered (user_id, target_user_id, action, action_at)
      VALUES ($1, $2, 'save', NOW())
      ON CONFLICT (user_id, target_user_id) DO UPDATE SET action = 'save', action_at = NOW()
    `, [req.user.uid, target_user_id]);

    return fastify.sendSuccess(reply, { saved: true });
  });

  // ─── FEATURE 1: MYSTERY MATCH ───────────────────────────────────────

  // GET /match/mystery — Personality-first discovery cards (Photos & Real Names Hidden)
  fastify.get('/mystery', {
    onRequest: [fastify.authenticate],
    config: {
      rateLimit: { max: 30, timeWindow: '1 hour' },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;

    // Get user's profile
    const userProfile = await fastify.db.query(`
      SELECT p.*, u.gender, u.age, u.city, u.is_premium
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      WHERE p.user_id = $1
    `, [userId]);

    if (!userProfile.rows[0]) {
      return fastify.sendError(reply, 'Profile not found. Please complete profile setup.', 404);
    }

    const me = userProfile.rows[0];

    // Exclude users already seen in mystery discovery in past 14 days
    const seenResult = await fastify.db.query(`
      SELECT target_user_id FROM mystery_discoveries
      WHERE user_id = $1 AND created_at > NOW() - INTERVAL '14 days'
    `, [userId]);

    const seenIds = seenResult.rows.map(r => r.target_user_id);
    const excludeIds = [...seenIds, userId];

    // Exclude blocked users
    const blockedResult = await fastify.db.query(`
      SELECT blocked_id as id FROM blocks WHERE blocker_id = $1
      UNION
      SELECT blocker_id as id FROM blocks WHERE blocked_id = $1
    `, [userId]);

    const blockedIds = blockedResult.rows.map(r => r.id);
    const allExcludeIds = [...new Set([...excludeIds, ...blockedIds])];

    const genderFilter = me.gender === 'woman' ? 'man' : 'woman';
    const minAge = Math.max(18, (me.age || 25) - 6);
    const maxAge = Math.min(100, (me.age || 25) + 8);

    // Fetch candidate profiles (backend-enforced privacy: photos NEVER returned)
    const candidatesResult = await fastify.db.query(`
      SELECT 
        p.user_id, p.trust_score, p.personality_tags,
        p.intent, p.bio_prompt_responses as prompt_responses,
        p.voice_intro_url IS NOT NULL as has_voice_intro,
        u.age, u.city, u.gender, u.verification_level
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      WHERE 
        u.id != ALL($1::uuid[])
        AND (u.gender = $2 OR u.gender IS NULL)
        AND (u.age BETWEEN $3 AND $4 OR u.age IS NULL)
        AND p.is_searchable = true
        AND u.account_status = 'active'
        AND u.last_active > NOW() - INTERVAL '30 days'
        AND ($5 = 'woman' AND p.trust_score >= 50 OR $5 != 'woman')
      ORDER BY p.trust_score DESC, u.last_active DESC
      LIMIT 20
    `, [allExcludeIds, genderFilter, minAge, maxAge, me.gender || 'man']);

    const candidates = candidatesResult.rows;
    if (candidates.length === 0) {
      return fastify.sendSuccess(reply, [], { count: 0, message: 'No suitable mystery matches found at this time' });
    }

    // Archetype pseudonyms to protect identity while conveying personality
    const archetypes = [
      'Mindful Reader', 'Thoughtful Stargazer', 'Quiet Philosopher',
      'Curious Wanderer', 'Gentle Explorer', 'Artistic Dreamer',
      'Chai & Conversations', 'Deep Thinker', 'Compassionate Soul'
    ];

    const myTags = new Set(me.personality_tags || []);

    const mysteryCards = candidates.map((c, idx) => {
      const theirTags = new Set(c.personality_tags || []);
      const sharedInterests = [...myTags].filter(t => theirTags.has(t));
      const archetype = archetypes[idx % archetypes.length];

      return {
        candidate_id: c.user_id,
        pseudonym: archetype,
        age: c.age || 25,
        city: c.city || 'Somewhere nearby',
        intent: c.intent || 'Meaningful slow dating',
        personality_tags: c.personality_tags || [],
        shared_interests: sharedInterests,
        prompt_responses: Array.isArray(c.prompt_responses) ? c.prompt_responses : [],
        trust_score: parseFloat(c.trust_score) || 50.0,
        has_voice_intro: !!c.has_voice_intro,
        // PRIVACY ENFORCEMENT: Never return photo URLs or real names in Mystery Match
        photos_hidden: true,
        photo_urls: [],
        profile_photo_url: null,
      };
    });

    return fastify.sendSuccess(reply, mysteryCards, { count: mysteryCards.length });
  });

  // POST /match/mystery/explore — "Explore Their Mind" action
  fastify.post('/mystery/explore', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['target_user_id'],
        properties: { target_user_id: { type: 'string' } },
      },
    },
  }, async (req, reply) => {
    const { target_user_id } = req.body;
    const userId = req.user.uid;

    if (target_user_id === userId) {
      return fastify.sendError(reply, 'Cannot explore yourself', 400);
    }

    // Check block list
    const blockCheck = await fastify.db.query(`
      SELECT 1 FROM blocks 
      WHERE (blocker_id = $1 AND blocked_id = $2) OR (blocker_id = $2 AND blocked_id = $1)
    `, [userId, target_user_id]);

    if (blockCheck.rows.length > 0) {
      return fastify.sendError(reply, 'User is unavailable', 403);
    }

    // Record explore action
    await fastify.db.query(`
      INSERT INTO mystery_discoveries (user_id, target_user_id, action, action_at)
      VALUES ($1, $2, 'explore', NOW())
      ON CONFLICT (user_id, target_user_id) DO UPDATE SET action = 'explore', action_at = NOW()
    `, [userId, target_user_id]);

    // Check if target previously explored me
    const mutualCheck = await fastify.db.query(`
      SELECT id FROM mystery_discoveries
      WHERE user_id = $1 AND target_user_id = $2 AND action = 'explore'
    `, [target_user_id, userId]);

    let conversationId = null;
    let isMutual = false;

    if (mutualCheck.rows.length > 0) {
      isMutual = true;
      const [a, b] = [userId, target_user_id].sort();
      const connResult = await fastify.db.query(`
        INSERT INTO connections (id, user_a, user_b, status, stage, reveal_stage, initiated_by, connected_at)
        VALUES ($1, $2, $3, 'connected', 1, 'mind', $4, NOW())
        ON CONFLICT (user_a, user_b) DO UPDATE SET status = 'connected', connected_at = NOW()
        RETURNING id
      `, [crypto.randomUUID(), a, b, userId]);

      conversationId = connResult.rows[0].id;

      // Seed connection garden
      await fastify.db.query(`
        INSERT INTO connection_gardens (connection_id, stage, growth_points, milestone_history, updated_at)
        VALUES ($1, 'seed', 10, $2, NOW())
        ON CONFLICT (connection_id) DO NOTHING
      `, [
        conversationId,
        JSON.stringify([
          {
            milestone_type: 'seed_planted',
            title: 'Mystery Match Seed Planted',
            description: 'You both discovered each other through personality first!',
            achieved_at: new Date().toISOString(),
          }
        ])
      ]);

      if (fastify.redis && fastify.redis.publish) {
        await fastify.redis.publish('notifications', JSON.stringify({
          type: 'mystery_mutual_match',
          target_user_id,
          data: { from_user_id: userId, conversation_id: conversationId },
        }));
      }
    }

    return fastify.sendSuccess(reply, {
      is_mutual: isMutual,
      conversation_id: conversationId,
      message: isMutual
        ? 'Mutual mystery match! Your slow journey begins.'
        : 'You chose to explore their mind. If feelings align, you will connect.'
    });
  });

  // POST /match/mystery/pass — "Not My Vibe" action
  fastify.post('/mystery/pass', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['target_user_id'],
        properties: { target_user_id: { type: 'string' } },
      },
    },
  }, async (req, reply) => {
    const { target_user_id } = req.body;
    const userId = req.user.uid;

    if (target_user_id === userId) {
      return fastify.sendError(reply, 'Invalid target user', 400);
    }

    await fastify.db.query(`
      INSERT INTO mystery_discoveries (user_id, target_user_id, action, action_at)
      VALUES ($1, $2, 'pass', NOW())
      ON CONFLICT (user_id, target_user_id) DO UPDATE SET action = 'pass', action_at = NOW()
    `, [userId, target_user_id]);

    return fastify.sendSuccess(reply, { passed: true, message: 'Passed respectfully' });
  });
};
