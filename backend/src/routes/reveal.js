// backend/src/routes/reveal.js
// Mantra Feature 4: Gradual Identity Reveal (Mind -> Voice -> Connection -> Face)
'use strict';

const crypto = require('crypto');

module.exports = async function revealRoutes(fastify) {
  const STAGE_ORDER = ['mind', 'voice', 'connection', 'face'];

  // Helper to check mutual consent
  async function checkMutualConsent(connectionId, stage) {
    const res = await fastify.db.query(`
      SELECT requester_id, status FROM reveal_requests
      WHERE connection_id = $1 AND stage = $2
    `, [connectionId, stage]);

    // Check if both users consented
    const acceptedRequests = res.rows.filter(r => r.status === 'accepted');
    return acceptedRequests.length >= 2;
  }

  // GET /reveal/:connectionId — Get current reveal stage and consent statuses
  fastify.get('/:connectionId', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;

    // Verify participant
    const connResult = await fastify.db.query(`
      SELECT id, user_a, user_b, status, reveal_stage, photo_revealed_at, name_revealed_at
      FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2)
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    const conn = connResult.rows[0];
    const partnerId = conn.user_a === userId ? conn.user_b : conn.user_a;

    // Fetch all requests for this connection
    const requestsResult = await fastify.db.query(`
      SELECT requester_id, stage, status, updated_at
      FROM reveal_requests
      WHERE connection_id = $1
    `, [connectionId]);

    const requests = requestsResult.rows;

    const myConsent = {
      voice: requests.some(r => r.requester_id === userId && r.stage === 'voice' && r.status === 'accepted'),
      connection: requests.some(r => r.requester_id === userId && r.stage === 'connection' && r.status === 'accepted'),
      face: requests.some(r => r.requester_id === userId && r.stage === 'face' && r.status === 'accepted'),
    };

    const partnerConsent = {
      voice: requests.some(r => r.requester_id === partnerId && r.stage === 'voice' && r.status === 'accepted'),
      connection: requests.some(r => r.requester_id === partnerId && r.stage === 'connection' && r.status === 'accepted'),
      face: requests.some(r => r.requester_id === partnerId && r.stage === 'face' && r.status === 'accepted'),
    };

    const pendingFromPartner = requests
      .filter(r => r.requester_id === partnerId && r.status === 'pending')
      .map(r => r.stage);

    const pendingFromMe = requests
      .filter(r => r.requester_id === userId && r.status === 'pending')
      .map(r => r.stage);

    const isFaceUnlocked = myConsent.face && partnerConsent.face;
    const isVoiceUnlocked = myConsent.voice && partnerConsent.voice;

    return fastify.sendSuccess(reply, {
      connection_id: connectionId,
      current_stage: conn.reveal_stage || 'mind',
      stages: STAGE_ORDER,
      my_consent: myConsent,
      partner_consent: partnerConsent,
      pending_requests_from_partner: pendingFromPartner,
      pending_requests_from_me: pendingFromMe,
      is_voice_unlocked: isVoiceUnlocked,
      is_photo_unlocked: isFaceUnlocked,
      explanation: isFaceUnlocked
        ? 'Mutual face reveal consented by both parties. Photos are now unblurred.'
        : 'Photos remain gently blurred until both participants provide explicit mutual consent.',
    });
  });

  // POST /reveal/:connectionId/request — Request advancement to a stage
  fastify.post('/:connectionId/request', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['stage'],
        properties: {
          stage: { type: 'string', enum: ['voice', 'connection', 'face'] },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;
    const { stage } = req.body;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b, status, reveal_stage
      FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND status = 'connected'
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Active conversation not found', 404);
    }

    const partnerId = connResult.rows[0].user_a === userId ? connResult.rows[0].user_b : connResult.rows[0].user_a;

    // Check if partner already requested or accepted this stage
    const partnerRequest = await fastify.db.query(`
      SELECT id, status FROM reveal_requests
      WHERE connection_id = $1 AND requester_id = $2 AND stage = $3
    `, [connectionId, partnerId, stage]);

    const partnerConsented = partnerRequest.rows.some(r => r.status === 'accepted' || r.status === 'pending');

    if (partnerConsented) {
      // Both now consent!
      await fastify.db.query(`
        INSERT INTO reveal_requests (id, connection_id, requester_id, stage, status, updated_at)
        VALUES ($1, $2, $3, $4, 'accepted', NOW())
        ON CONFLICT (connection_id, requester_id, stage)
        DO UPDATE SET status = 'accepted', updated_at = NOW()
      `, [crypto.randomUUID(), connectionId, userId, stage]);

      await fastify.db.query(`
        UPDATE reveal_requests SET status = 'accepted', updated_at = NOW()
        WHERE connection_id = $1 AND requester_id = $2 AND stage = $3
      `, [connectionId, partnerId, stage]);

      // Advance connection reveal_stage
      await fastify.db.query(`
        UPDATE connections
        SET reveal_stage = $2,
            photo_revealed_at = CASE WHEN $2 = 'face' THEN NOW() ELSE photo_revealed_at END,
            stage_updated_at = NOW()
        WHERE id = $1
      `, [connectionId, stage]);

      // Award Connection Garden milestone
      await fastify.db.query(`
        UPDATE connection_gardens
        SET growth_points = growth_points + 25,
            stage = CASE WHEN stage = 'growing' AND $2 = 'face' THEN 'bloom'
                         WHEN stage = 'sprout' THEN 'growing'
                         ELSE stage END,
            milestone_history = milestone_history || $3::jsonb,
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE connection_id = $1
      `, [
        connectionId,
        stage,
        JSON.stringify([{
          milestone_type: `${stage}_reveal_consented`,
          title: `Mutual ${stage.charAt(0).toUpperCase() + stage.slice(1)} Reveal Consented`,
          description: `Both participants mutually consented to unlock the ${stage} stage!`,
          achieved_at: new Date().toISOString(),
        }])
      ]);

      return fastify.sendSuccess(reply, {
        stage_advanced: true,
        new_stage: stage,
        is_unlocked: true,
        message: `Mutual consent established! ${stage.toUpperCase()} is now unlocked for both of you.`,
      });
    } else {
      // User requests stage, awaits partner consent
      await fastify.db.query(`
        INSERT INTO reveal_requests (id, connection_id, requester_id, stage, status, updated_at)
        VALUES ($1, $2, $3, $4, 'accepted', NOW())
        ON CONFLICT (connection_id, requester_id, stage)
        DO UPDATE SET status = 'accepted', updated_at = NOW()
      `, [crypto.randomUUID(), connectionId, userId, stage]);

      // Inform partner via Redis
      if (fastify.redis && fastify.redis.publish) {
        await fastify.redis.publish('notifications', JSON.stringify({
          type: 'reveal_requested',
          target_user_id: partnerId,
          data: { connection_id: connectionId, stage },
        }));
      }

      return fastify.sendSuccess(reply, {
        stage_advanced: false,
        stage_requested: stage,
        message: `You consented to ${stage} reveal. Photos & details will unlock when your partner also consents.`,
      });
    }
  });

  // POST /reveal/:connectionId/respond — Accept or decline partner's request
  fastify.post('/:connectionId/respond', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['stage', 'accept'],
        properties: {
          stage: { type: 'string', enum: ['voice', 'connection', 'face'] },
          accept: { type: 'boolean' },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;
    const { stage, accept } = req.body;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND status = 'connected'
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    if (!accept) {
      await fastify.db.query(`
        INSERT INTO reveal_requests (id, connection_id, requester_id, stage, status, updated_at)
        VALUES ($1, $2, $3, $4, 'declined', NOW())
        ON CONFLICT (connection_id, requester_id, stage)
        DO UPDATE SET status = 'declined', updated_at = NOW()
      `, [crypto.randomUUID(), connectionId, userId, stage]);

      return fastify.sendSuccess(reply, {
        stage_advanced: false,
        status: 'declined',
        message: 'Request declined respectfully. No changes were made.',
      });
    }

    // Accept: both now consented!
    await fastify.db.query(`
      INSERT INTO reveal_requests (id, connection_id, requester_id, stage, status, updated_at)
      VALUES ($1, $2, $3, $4, 'accepted', NOW())
      ON CONFLICT (connection_id, requester_id, stage)
      DO UPDATE SET status = 'accepted', updated_at = NOW()
    `, [crypto.randomUUID(), connectionId, userId, stage]);

    await fastify.db.query(`
      UPDATE connections
      SET reveal_stage = $2,
          photo_revealed_at = CASE WHEN $2 = 'face' THEN NOW() ELSE photo_revealed_at END
      WHERE id = $1
    `, [connectionId, stage]);

    return fastify.sendSuccess(reply, {
      stage_advanced: true,
      new_stage: stage,
      message: `Mutual consent confirmed! ${stage.toUpperCase()} is now unlocked.`,
    });
  });

  // POST /reveal/:connectionId/revoke — Instantly revoke consent and re-lock
  fastify.post('/:connectionId/revoke', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['stage'],
        properties: {
          stage: { type: 'string', enum: ['voice', 'connection', 'face'] },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;
    const { stage } = req.body;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b, reveal_stage FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2)
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    // Set user's request status to revoked
    await fastify.db.query(`
      UPDATE reveal_requests
      SET status = 'revoked', updated_at = NOW()
      WHERE connection_id = $1 AND requester_id = $2 AND stage = $3
    `, [connectionId, userId, stage]);

    // Revert reveal_stage to prior safe stage
    const newStage = stage === 'face' ? 'connection' : stage === 'connection' ? 'voice' : 'mind';

    await fastify.db.query(`
      UPDATE connections
      SET reveal_stage = $2,
          photo_revealed_at = CASE WHEN $3 = 'face' THEN NULL ELSE photo_revealed_at END
      WHERE id = $1
    `, [connectionId, newStage, stage]);

    return fastify.sendSuccess(reply, {
      revoked: true,
      new_stage: newStage,
      message: `${stage.toUpperCase()} reveal consent revoked. Content is immediately secured and locked.`,
    });
  });

  // GET /reveal/:connectionId/media/:mediaType — Gated media access with backend authorization
  fastify.get('/:connectionId/media/:mediaType', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId, mediaType } = req.params;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b, status, reveal_stage FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND status = 'connected'
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found or disconnected', 404);
    }

    const conn = connResult.rows[0];
    const partnerId = conn.user_a === userId ? conn.user_b : conn.user_a;

    // Check media type gating
    if (mediaType === 'photo') {
      const isMutualFace = await checkMutualConsent(connectionId, 'face');
      if (!isMutualFace || conn.reveal_stage !== 'face') {
        return fastify.sendError(reply, 'Mutual face reveal consent is required to access photos', 403);
      }

      const partnerProfile = await fastify.db.query(`
        SELECT photo_urls FROM profiles WHERE user_id = $1
      `, [partnerId]);

      return fastify.sendSuccess(reply, {
        is_unlocked: true,
        photo_urls: partnerProfile.rows[0]?.photo_urls || [],
      });
    }

    if (mediaType === 'voice') {
      const isMutualVoice = await checkMutualConsent(connectionId, 'voice');
      if (!isMutualVoice || conn.reveal_stage === 'mind') {
        return fastify.sendError(reply, 'Mutual voice reveal consent is required to access voice audio', 403);
      }

      const partnerProfile = await fastify.db.query(`
        SELECT voice_intro_url FROM profiles WHERE user_id = $1
      `, [partnerId]);

      return fastify.sendSuccess(reply, {
        is_unlocked: true,
        voice_intro_url: partnerProfile.rows[0]?.voice_intro_url || null,
      });
    }

    return fastify.sendError(reply, 'Invalid media type requested', 400);
  });
};
