// backend/src/routes/quests.js
// Mantra Feature 3: Conversation Quest (Mindful Prompts & Mutual Unlock)
'use strict';

const crypto = require('crypto');

module.exports = async function questRoutes(fastify) {
  // GET /quests/daily — Get current daily prompt
  fastify.get('/daily', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    // Select an active prompt (deterministic based on day of year to provide same daily theme)
    const questsResult = await fastify.db.query(`
      SELECT id, category, prompt_text, follow_up_prompt
      FROM conversation_quests
      WHERE is_active = true
      ORDER BY id ASC
    `);

    const quests = questsResult.rows;
    if (quests.length === 0) {
      return fastify.sendSuccess(reply, {
        id: 'default-quest',
        category: 'values',
        prompt_text: 'What is one personal principle you will never compromise on?',
        follow_up_prompt: 'How has holding this boundary helped you grow?',
      });
    }

    const dayOfYear = Math.floor((new Date() - new Date(new Date().getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
    const selectedQuest = quests[dayOfYear % quests.length];

    return fastify.sendSuccess(reply, selectedQuest);
  });

  // GET /quests/connection/:connectionId — Get quest status for a specific conversation
  fastify.get('/connection/:connectionId', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { connectionId } = req.params;

    // Verify user is a participant
    const connCheck = await fastify.db.query(`
      SELECT user_a, user_b, status FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2)
    `, [connectionId, userId]);

    if (!connCheck.rows[0]) {
      return fastify.sendError(reply, 'Conversation not found', 404);
    }

    const conn = connCheck.rows[0];
    const partnerId = conn.user_a === userId ? conn.user_b : conn.user_a;

    // Fetch daily quest
    const questsResult = await fastify.db.query(`
      SELECT id, category, prompt_text, follow_up_prompt
      FROM conversation_quests
      WHERE is_active = true
      ORDER BY id ASC
    `);
    const dayOfYear = Math.floor((new Date() - new Date(new Date().getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
    const currentQuest = questsResult.rows[dayOfYear % (questsResult.rows.length || 1)] || {
      id: 'b0000000-0000-0000-0000-000000000001',
      category: 'values',
      prompt_text: 'What is one personal principle you will never compromise on, even when it is difficult?',
      follow_up_prompt: 'How has holding this boundary helped you grow?',
    };

    // Fetch existing answers for this quest in this connection
    const answersResult = await fastify.db.query(`
      SELECT a.id, a.user_id, a.answer_text, a.created_at,
             (SELECT json_agg(json_build_object('user_id', r.user_id, 'reaction', r.reaction)) 
              FROM quest_reactions r WHERE r.quest_answer_id = a.id) as reactions
      FROM quest_answers a
      WHERE a.connection_id = $1 AND a.quest_id = $2
    `, [connectionId, currentQuest.id]);

    const myAnswer = answersResult.rows.find(r => r.user_id === userId);
    const partnerAnswer = answersResult.rows.find(r => r.user_id === partnerId);

    const isMutualUnlocked = !!(myAnswer && partnerAnswer);

    return fastify.sendSuccess(reply, {
      quest: currentQuest,
      has_user_answered: !!myAnswer,
      has_partner_answered: !!partnerAnswer,
      is_unlocked: isMutualUnlocked,
      my_answer: myAnswer ? {
        id: myAnswer.id,
        answer_text: myAnswer.answer_text,
        created_at: myAnswer.created_at,
        reactions: myAnswer.reactions || [],
      } : null,
      // PRIVACY ENFORCEMENT: Partner answer is strictly null until mutual submission!
      partner_answer: isMutualUnlocked ? {
        id: partnerAnswer.id,
        answer_text: partnerAnswer.answer_text,
        created_at: partnerAnswer.created_at,
        reactions: partnerAnswer.reactions || [],
      } : null,
      follow_up_prompt: isMutualUnlocked ? currentQuest.follow_up_prompt : null,
      optional_notice: 'Conversation Quests are a mindful invitation to connect. Participation is entirely optional.',
    });
  });

  // POST /quests/answer — Submit an answer to a quest
  fastify.post('/answer', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['quest_id', 'connection_id', 'answer_text'],
        properties: {
          quest_id: { type: 'string' },
          connection_id: { type: 'string' },
          answer_text: { type: 'string', minLength: 2, maxLength: 2000 },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { quest_id, connection_id, answer_text } = req.body;

    // Verify user is a participant
    const connCheck = await fastify.db.query(`
      SELECT user_a, user_b, status FROM connections
      WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND status = 'connected'
    `, [connection_id, userId]);

    if (!connCheck.rows[0]) {
      return fastify.sendError(reply, 'Active conversation not found', 404);
    }

    const partnerId = connCheck.rows[0].user_a === userId ? connCheck.rows[0].user_b : connCheck.rows[0].user_a;

    // Insert or update answer
    const answerId = crypto.randomUUID();
    await fastify.db.query(`
      INSERT INTO quest_answers (id, quest_id, connection_id, user_id, answer_text, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
      ON CONFLICT (quest_id, connection_id, user_id)
      DO UPDATE SET answer_text = EXCLUDED.answer_text, created_at = NOW()
    `, [answerId, quest_id, connection_id, userId, answer_text]);

    // Check if partner has already answered (mutual unlock triggered!)
    const partnerCheck = await fastify.db.query(`
      SELECT id, answer_text FROM quest_answers
      WHERE quest_id = $1 AND connection_id = $2 AND user_id = $3
    `, [quest_id, connection_id, partnerId]);

    const isMutual = partnerCheck.rows.length > 0;

    if (isMutual) {
      // Award connection garden progress (+15 points, advance seed -> sprout)
      await fastify.db.query(`
        UPDATE connection_gardens
        SET growth_points = growth_points + 15,
            stage = CASE WHEN stage = 'seed' THEN 'sprout' ELSE stage END,
            milestone_history = milestone_history || $2::jsonb,
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE connection_id = $1
      `, [
        connection_id,
        JSON.stringify([{
          milestone_type: 'quest_completed',
          title: 'Conversation Quest Unlocked',
          description: 'Both shared thoughtful answers to the daily prompt!',
          achieved_at: new Date().toISOString(),
        }])
      ]);

      // Publish notification
      if (fastify.redis && fastify.redis.publish) {
        await fastify.redis.publish('notifications', JSON.stringify({
          type: 'quest_unlocked',
          target_user_id: partnerId,
          data: { connection_id, quest_id },
        }));
      }
    }

    return fastify.sendSuccess(reply, {
      submitted: true,
      is_unlocked: isMutual,
      message: isMutual
        ? 'Mutual participation complete! Partner answer and follow-up question are now unlocked.'
        : 'Your thoughtful response is recorded. It will be unlocked once your partner also shares.',
    });
  });

  // POST /quests/react — React to an unlocked answer
  fastify.post('/react', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['quest_answer_id', 'reaction'],
        properties: {
          quest_answer_id: { type: 'string' },
          reaction: { type: 'string', minLength: 1, maxLength: 20 },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { quest_answer_id, reaction } = req.body;

    const answerCheck = await fastify.db.query(`
      SELECT a.connection_id, c.user_a, c.user_b
      FROM quest_answers a
      JOIN connections c ON c.id = a.connection_id
      WHERE a.id = $1 AND (c.user_a = $2 OR c.user_b = $2)
    `, [quest_answer_id, userId]);

    if (!answerCheck.rows[0]) {
      return fastify.sendError(reply, 'Answer not found or inaccessible', 404);
    }

    await fastify.db.query(`
      INSERT INTO quest_reactions (id, quest_answer_id, user_id, reaction, created_at)
      VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (quest_answer_id, user_id)
      DO UPDATE SET reaction = EXCLUDED.reaction, created_at = NOW()
    `, [crypto.randomUUID(), quest_answer_id, userId, reaction]);

    return fastify.sendSuccess(reply, { reacted: true, reaction });
  });
};
