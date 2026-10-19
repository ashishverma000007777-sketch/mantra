// backend/src/routes/auth.js
'use strict';

const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
let admin;
try {
  admin = require('firebase-admin');
} catch (_) {
  admin = null;
}

module.exports = async function authRoutes(fastify) {
  // Helper to hash phone deterministically
  function hashPhone(identifier) {
    const secret =
      process.env.MANTRA_PHONE_HASH_SECRET ||
      process.env.PHONE_HASH_SECRET ||
      process.env.JWT_SECRET ||
      'mantra-deterministic-phone-secret-key';
    return crypto.createHmac('sha256', secret).update(String(identifier).trim()).digest('hex');
  }

  // POST /auth/register — called after Firebase phone auth
  fastify.post('/register', {
    schema: {
      body: {
        type: 'object',
        properties: {
          fcm_token: { type: 'string' },
        },
      },
    },
  }, async (req, reply) => {
    const firebaseToken = req.headers.authorization?.replace('Bearer ', '');
    if (!firebaseToken) {
      return fastify.sendError(reply, 'No token provided', 401);
    }

    let decoded;
    if (process.env.NODE_ENV === 'test' && firebaseToken.startsWith('test_token_')) {
      const uid = firebaseToken.replace('test_token_', '');
      decoded = { uid, phone_number: `+9199999${uid.slice(0, 5).padStart(5, '0')}` };
    } else {
      try {
        if (!admin || !admin.apps || admin.apps.length === 0) {
          // If Firebase Admin isn't initialized with credentials, provide test fallback in dev
          if (process.env.NODE_ENV !== 'production' && firebaseToken.startsWith('mock_')) {
            decoded = { uid: firebaseToken, phone_number: '+919876543210' };
          } else {
            return fastify.sendError(reply, 'Firebase Auth service not initialized', 503);
          }
        } else {
          decoded = await admin.auth().verifyIdToken(firebaseToken);
        }
      } catch (err) {
        return fastify.sendError(reply, 'Invalid Firebase token', 401);
      }
    }

    const phoneHash = hashPhone(decoded.phone_number || decoded.uid);
    const firebaseUid = decoded.uid;

    // Deterministic upsert user
    const result = await fastify.db.query(`
      INSERT INTO users (id, phone_hash, firebase_uid, verification_level, account_status, created_at, last_active, is_onboarded)
      VALUES ($1, $2, $3, 1, 'active', NOW(), NOW(), false)
      ON CONFLICT (phone_hash) DO UPDATE SET
        last_active = NOW(),
        firebase_uid = COALESCE(users.firebase_uid, EXCLUDED.firebase_uid)
      RETURNING id, is_onboarded, verification_level, account_status
    `, [uuidv4(), phoneHash, firebaseUid]);

    const user = result.rows[0];

    if (user.account_status === 'banned') {
      return fastify.sendError(reply, 'This account has been suspended', 403);
    }

    const accessJti = uuidv4();
    const refreshJti = uuidv4();

    const accessToken = fastify.jwt.sign(
      { uid: user.id, jti: accessJti },
      { expiresIn: '15m' }
    );
    const refreshToken = fastify.jwt.sign(
      { uid: user.id, type: 'refresh', jti: refreshJti },
      { expiresIn: '7d' }
    );

    // Store refresh token in Redis
    if (fastify.redis && fastify.redis.setEx) {
      await fastify.redis.setEx(`refresh:${user.id}`, 7 * 24 * 3600, refreshToken);
      if (req.body?.fcm_token) {
        await fastify.redis.set(`fcm:${user.id}`, req.body.fcm_token);
      }
    }

    return fastify.sendSuccess(reply, {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        is_onboarded: user.is_onboarded,
        verification_level: user.verification_level,
      },
    });
  });

  // POST /auth/refresh — Refresh access token with rotation
  fastify.post('/refresh', async (req, reply) => {
    const { refresh_token } = req.body || {};
    if (!refresh_token) return fastify.sendError(reply, 'No refresh token provided', 400);

    let decoded;
    try {
      decoded = fastify.jwt.verify(refresh_token);
    } catch {
      return fastify.sendError(reply, 'Invalid or expired refresh token', 401);
    }

    if (decoded.type !== 'refresh') {
      return fastify.sendError(reply, 'Invalid token type', 401);
    }

    if (fastify.redis && fastify.redis.get) {
      const stored = await fastify.redis.get(`refresh:${decoded.uid}`);
      if (stored !== refresh_token) {
        return fastify.sendError(reply, 'Token reuse detected or revoked', 401);
      }
    }

    // Issue rotated access and refresh tokens
    const newAccessJti = uuidv4();
    const newRefreshJti = uuidv4();

    const newAccessToken = fastify.jwt.sign(
      { uid: decoded.uid, jti: newAccessJti },
      { expiresIn: '15m' }
    );
    const newRefreshToken = fastify.jwt.sign(
      { uid: decoded.uid, type: 'refresh', jti: newRefreshJti },
      { expiresIn: '7d' }
    );

    if (fastify.redis && fastify.redis.setEx) {
      await fastify.redis.setEx(`refresh:${decoded.uid}`, 7 * 24 * 3600, newRefreshToken);
    }

    return fastify.sendSuccess(reply, {
      access_token: newAccessToken,
      refresh_token: newRefreshToken,
    });
  });

  // GET /auth/me — Current authenticated user details
  fastify.get('/me', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const result = await fastify.db.query(`
      SELECT u.id, u.verification_level, u.kyc_level, u.account_status, u.gender, u.age,
             u.city, u.created_at, u.last_active, u.is_premium, u.premium_tier,
             u.is_onboarded, u.onboarding_step, u.is_admin,
             p.display_name, p.trust_score, p.photos_blurred
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.id
      WHERE u.id = $1
    `, [req.user.uid]);

    if (!result.rows[0]) {
      return fastify.sendError(reply, 'User not found', 404);
    }

    return fastify.sendSuccess(reply, result.rows[0]);
  });

  // POST /auth/fcm-token — Register device token for push notifications
  fastify.post('/fcm-token', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['fcm_token'],
        properties: {
          fcm_token: { type: 'string', minLength: 10 },
        },
      },
    },
  }, async (req, reply) => {
    const { fcm_token } = req.body;
    if (fastify.redis && fastify.redis.set) {
      await fastify.redis.set(`fcm:${req.user.uid}`, fcm_token);
    }
    return fastify.sendSuccess(reply, { registered: true });
  });

  // POST /auth/logout — Revoke tokens
  fastify.post('/logout', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const jti = req.user.jti;

    if (fastify.redis) {
      if (jti && fastify.redis.setEx) {
        // Blacklist access token for remaining lifetime (15 mins)
        await fastify.redis.setEx(`blacklist:${jti}`, 900, 'revoked');
      }
      if (fastify.redis.del) {
        await fastify.redis.del(`refresh:${userId}`);
      }
    }

    return fastify.sendSuccess(reply, { logged_out: true });
  });
};
