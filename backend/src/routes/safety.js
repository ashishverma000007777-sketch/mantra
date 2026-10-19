// backend/src/routes/safety.js
'use strict';

const crypto = require('crypto');

module.exports = async function safetyRoutes(fastify) {
  // POST /safety/report — Report a user
  fastify.post('/report', {
    onRequest: [fastify.authenticate],
    config: { rateLimit: { max: 10, timeWindow: '1 day' } },
    schema: {
      body: {
        type: 'object',
        required: ['reported_user_id', 'reason'],
        properties: {
          reported_user_id: { type: 'string' },
          reason: { type: 'string', enum: ['inappropriate', 'fake', 'harassment', 'explicit', 'scam', 'other'] },
          note: { type: 'string', maxLength: 500 },
        },
      },
    },
  }, async (req, reply) => {
    const { reported_user_id, reason, note } = req.body;
    const reporter_id = req.user.uid;

    if (reported_user_id === reporter_id) {
      return fastify.sendError(reply, 'Cannot report yourself', 400);
    }

    await fastify.db.query(`
      INSERT INTO reports (id, reporter_id, reported_user_id, reason, note, status, created_at)
      VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
    `, [crypto.randomUUID(), reporter_id, reported_user_id, reason, note]);

    // Decrement trust score on reported user
    await fastify.db.query(`
      UPDATE profiles SET trust_score = GREATEST(0, trust_score - 5), creep_score = LEAST(100, creep_score + 10)
      WHERE user_id = $1
    `, [reported_user_id]);

    // Queue for moderation
    if (fastify.redis && fastify.redis.lPush) {
      await fastify.redis.lPush('moderation_queue', JSON.stringify({
        type: 'report',
        reporter_id,
        reported_user_id,
        reason,
        note,
        timestamp: new Date().toISOString(),
      }));
    }

    return fastify.sendSuccess(reply, {
      message: 'Report received. Our safety team will review within 4 hours.',
    });
  });

  // POST /safety/block — Block a user
  fastify.post('/block', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['blocked_user_id'],
        properties: {
          blocked_user_id: { type: 'string' },
          reason: { type: 'string' },
        },
      },
    },
  }, async (req, reply) => {
    const { blocked_user_id, reason } = req.body;
    const blocker_id = req.user.uid;

    if (blocked_user_id === blocker_id) {
      return fastify.sendError(reply, 'Cannot block yourself', 400);
    }

    await fastify.db.query(`
      INSERT INTO blocks (blocker_id, blocked_id, reason, created_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (blocker_id, blocked_id) DO NOTHING
    `, [blocker_id, blocked_user_id, reason || null]);

    // Disconnect active connection if any
    const [a, b] = [blocker_id, blocked_user_id].sort();
    await fastify.db.query(`
      UPDATE connections SET status = 'blocked'
      WHERE user_a = $1 AND user_b = $2
    `, [a, b]);

    // Clear spark caches
    if (fastify.redis && fastify.redis.del) {
      const todayStr = new Date().toISOString().slice(0, 10);
      await fastify.redis.del(`sparks:${blocker_id}:${todayStr}`);
    }

    return fastify.sendSuccess(reply, { blocked: true });
  });

  // GET /safety/blocks — List blocked users
  fastify.get('/blocks', { onRequest: [fastify.authenticate] }, async (req, reply) => {
    const result = await fastify.db.query(`
      SELECT b.blocked_id, b.reason, b.created_at,
             p.display_name, p.photo_urls
      FROM blocks b
      LEFT JOIN profiles p ON p.user_id = b.blocked_id
      WHERE b.blocker_id = $1
      ORDER BY b.created_at DESC
    `, [req.user.uid]);

    return fastify.sendSuccess(reply, result.rows);
  });

  // DELETE /safety/block/:userId — Unblock a user
  fastify.delete('/block/:userId', { onRequest: [fastify.authenticate] }, async (req, reply) => {
    const { userId } = req.params;
    await fastify.db.query(`
      DELETE FROM blocks WHERE blocker_id = $1 AND blocked_id = $2
    `, [req.user.uid, userId]);

    return fastify.sendSuccess(reply, { unblocked: true });
  });

  // POST /safety/sos — Emergency SOS alert
  fastify.post('/sos', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const { latitude, longitude, conversation_id } = req.body || {};
    const userId = req.user.uid;

    // Get trusted contacts
    const contactsResult = await fastify.db.query(`
      SELECT name, phone FROM trusted_contacts WHERE user_id = $1
    `, [userId]);

    const contacts = contactsResult.rows;

    // Get user display name
    const userResult = await fastify.db.query(`
      SELECT display_name FROM profiles WHERE user_id = $1
    `, [userId]);

    const senderName = userResult.rows[0]?.display_name || 'Your contact';
    const mapsLink = latitude && longitude
      ? `https://maps.google.com/?q=${latitude},${longitude}`
      : 'Location unavailable';

    // Queue SMS to all registered trusted contacts
    if (fastify.redis && fastify.redis.lPush) {
      for (const contact of contacts) {
        await fastify.redis.lPush('sms_queue', JSON.stringify({
          to: contact.phone,
          message: `⚠️ MANTRA SAFETY ALERT: ${senderName} has activated emergency SOS mode. Location: ${mapsLink}. Please check on them immediately.`,
        }));
      }
    }

    // Flag conversation if specified
    if (conversation_id) {
      await fastify.db.query(`
        UPDATE connections SET status = 'flagged' WHERE id = $1
      `, [conversation_id]);
    }

    // Record SOS event
    await fastify.db.query(`
      INSERT INTO sos_events (id, user_id, latitude, longitude, contacts_alerted, conversation_id, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
    `, [crypto.randomUUID(), userId, latitude || null, longitude || null, contacts.length, conversation_id || null]);

    return fastify.sendSuccess(reply, {
      contacts_alerted: contacts.length,
      message: `${contacts.length} trusted contact(s) have been alerted.`,
    });
  });

  // GET /safety/trusted-contacts — List user's trusted contacts
  fastify.get('/trusted-contacts', { onRequest: [fastify.authenticate] }, async (req, reply) => {
    const result = await fastify.db.query(`
      SELECT id, name, phone, created_at
      FROM trusted_contacts
      WHERE user_id = $1
      ORDER BY created_at ASC
    `, [req.user.uid]);

    return fastify.sendSuccess(reply, result.rows);
  });

  // POST /safety/trusted-contacts — Add a trusted contact (max 3)
  fastify.post('/trusted-contacts', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['name', 'phone'],
        properties: {
          name: { type: 'string', minLength: 2, maxLength: 50 },
          phone: { type: 'string', minLength: 10, maxLength: 20 },
        },
      },
    },
  }, async (req, reply) => {
    const { name, phone } = req.body;
    const userId = req.user.uid;

    const countResult = await fastify.db.query(`
      SELECT COUNT(*) as count FROM trusted_contacts WHERE user_id = $1
    `, [userId]);

    if (parseInt(countResult.rows[0].count) >= 3) {
      return fastify.sendError(reply, 'Maximum 3 trusted contacts allowed', 400);
    }

    const contactId = crypto.randomUUID();
    await fastify.db.query(`
      INSERT INTO trusted_contacts (id, user_id, name, phone, created_at)
      VALUES ($1, $2, $3, $4, NOW())
    `, [contactId, userId, name, phone]);

    // Fetch user name for intro SMS
    const userResult = await fastify.db.query(`
      SELECT display_name FROM profiles WHERE user_id = $1
    `, [userId]);
    const senderName = userResult.rows[0]?.display_name || 'A Mantra user';

    if (fastify.redis && fastify.redis.lPush) {
      await fastify.redis.lPush('sms_queue', JSON.stringify({
        to: phone,
        message: `Hi ${name}, ${senderName} added you as a trusted safety contact on Mantra dating app. You will receive an emergency alert if they need help.`,
      }));
    }

    return fastify.sendSuccess(reply, { id: contactId, added: true });
  });

  // DELETE /safety/trusted-contacts/:id — Delete a trusted contact
  fastify.delete('/trusted-contacts/:id', { onRequest: [fastify.authenticate] }, async (req, reply) => {
    const { id } = req.params;
    await fastify.db.query(`
      DELETE FROM trusted_contacts WHERE id = $1 AND user_id = $2
    `, [id, req.user.uid]);

    return fastify.sendSuccess(reply, { deleted: true });
  });
};
