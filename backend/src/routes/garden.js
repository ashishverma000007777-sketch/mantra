// backend/src/routes/garden.js
// Mantra Feature 5: Connection Garden (Seed -> Sprout -> Growing -> Bloom)
'use strict';

const crypto = require('crypto');

module.exports = async function gardenRoutes(fastify) {
  // Helper to determine stage from points
  function determineStage(points) {
    if (points >= 90) return 'bloom';
    if (points >= 60) return 'growing';
    if (points >= 30) return 'sprout';
    return 'seed';
  }

  function getStageDescription(stage) {
    switch (stage) {
      case 'seed':
        return 'A new slow connection planted with care. Rooted in mutual curiosity.';
      case 'sprout':
        return 'First tender leaves emerging through shared questions and mutual participation.';
      case 'growing':
        return 'Steadily deepening stems nourished by thoughtful conversations and vulnerability.';
      case 'bloom':
        return 'A flourishing, trusted connection celebrating mutual milestones and openness.';
      default:
        return 'A mindful connection garden.';
    }
  }

  // GET /garden/:connectionId — Get garden state and milestone history
  fastify.get('/:connectionId', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;

    // Verify user is a participant
    const connResult = await fastify.db.query(`
      SELECT user_a, user_b, status, connected_at
      FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2)
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    // Fetch garden or initialize if not yet present
    let gardenResult = await fastify.db.query(`
      SELECT id, stage, growth_points, milestone_history, is_paused, last_activity_at, updated_at
      FROM connection_gardens
      WHERE connection_id = $1
    `, [connectionId]);

    let garden = gardenResult.rows[0];

    if (!garden) {
      const defaultMilestones = [
        {
          milestone_type: 'seed_planted',
          title: 'Garden Planted 🌱',
          description: 'A mindful slow-dating connection began.',
          achieved_at: connResult.rows[0].connected_at || new Date().toISOString(),
        }
      ];

      const newGardenResult = await fastify.db.query(`
        INSERT INTO connection_gardens (connection_id, stage, growth_points, milestone_history, updated_at)
        VALUES ($1, 'seed', 15, $2, NOW())
        ON CONFLICT (connection_id) DO UPDATE SET updated_at = NOW()
        RETURNING *
      `, [connectionId, JSON.stringify(defaultMilestones)]);

      garden = newGardenResult.rows[0];
    }

    const milestones = Array.isArray(garden.milestone_history) ? garden.milestone_history : [];

    return fastify.sendSuccess(reply, {
      connection_id: connectionId,
      stage: garden.stage,
      growth_points: garden.growth_points,
      stage_description: getStageDescription(garden.stage),
      is_paused: !!garden.is_paused,
      milestones,
      anti_streak_guarantee: 'Connection Gardens reflect mutual milestones, not compulsive daily streaks. Your garden never withers from taking time for yourself.',
      next_milestone_suggestion: garden.stage === 'seed'
        ? 'Answer a Conversation Quest together to watch your seed sprout.'
        : garden.stage === 'sprout'
        ? 'Exchange a voice introduction or explore shared values to grow deeper.'
        : garden.stage === 'growing'
        ? 'When trust feels right, request a mutual Face Reveal to bloom together.'
        : 'Your connection has reached full bloom! Continue nurturing it with gentle presence.',
    });
  });

  // POST /garden/:connectionId/activity — Log a legitimate mutual activity
  fastify.post('/:connectionId/activity', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['activity_type'],
        properties: {
          activity_type: {
            type: 'string',
            enum: ['quest_completed', 'voice_exchange', 'deep_reflection', 'face_reveal'],
          },
          title: { type: 'string' },
          description: { type: 'string' },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;
    const { activity_type, title, description } = req.body;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b, status FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND status = 'connected'
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Active conversation not found', 404);
    }

    const gardenResult = await fastify.db.query(`
      SELECT id, stage, growth_points, milestone_history, last_activity_at, is_paused
      FROM connection_gardens
      WHERE connection_id = $1
    `, [connectionId]);

    const garden = gardenResult.rows[0];
    if (garden && garden.is_paused) {
      return fastify.sendError(reply, 'Connection garden is currently paused', 400);
    }

    // ANTI-SPAM RULE: Check cooldown (at least 1 hour between manually triggered activities)
    if (process.env.NODE_ENV !== 'test' && garden && garden.last_activity_at) {
      const elapsedMs = Date.now() - new Date(garden.last_activity_at).getTime();
      if (elapsedMs < 3600 * 1000 && activity_type !== 'face_reveal') {
        return fastify.sendError(reply, 'Garden activity already recorded recently. Growth takes time to unfold.', 429);
      }
    }

    const pointsDelta = activity_type === 'face_reveal' ? 30
      : activity_type === 'voice_exchange' ? 20
      : activity_type === 'quest_completed' ? 15
      : 10;

    const newPoints = Math.min((garden?.growth_points || 10) + pointsDelta, 100);
    const newStage = determineStage(newPoints);

    const newMilestone = {
      milestone_type: activity_type,
      title: title || `Meaningful Moment: ${activity_type.replace('_', ' ')}`,
      description: description || 'You nurtured your slow connection together.',
      achieved_at: new Date().toISOString(),
    };

    const existingMilestones = Array.isArray(garden?.milestone_history) ? garden.milestone_history : [];
    const updatedMilestones = [...existingMilestones, newMilestone];

    await fastify.db.query(`
      INSERT INTO connection_gardens (connection_id, stage, growth_points, milestone_history, last_activity_at, updated_at)
      VALUES ($1, $2, $3, $4, NOW(), NOW())
      ON CONFLICT (connection_id) DO UPDATE SET
        stage = $2,
        growth_points = $3,
        milestone_history = $4,
        last_activity_at = NOW(),
        updated_at = NOW()
    `, [connectionId, newStage, newPoints, JSON.stringify(updatedMilestones)]);

    return fastify.sendSuccess(reply, {
      activity_recorded: true,
      stage: newStage,
      growth_points: newPoints,
      new_milestone: newMilestone,
      stage_advanced: garden ? newStage !== garden.stage : false,
    });
  });

  // POST /garden/:connectionId/privacy — Toggle garden pause / privacy
  fastify.post('/:connectionId/privacy', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['pause'],
        properties: { pause: { type: 'boolean' } },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;
    const { pause } = req.body;

    const connResult = await fastify.db.query(`
      SELECT user_a, user_b FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2)
    `, [connectionId, userId]);

    if (!connResult.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    await fastify.db.query(`
      UPDATE connection_gardens
      SET is_paused = $2, updated_at = NOW()
      WHERE connection_id = $1
    `, [connectionId, pause]);

    return fastify.sendSuccess(reply, {
      is_paused: pause,
      message: pause ? 'Connection garden paused' : 'Connection garden resumed',
    });
  });
};
