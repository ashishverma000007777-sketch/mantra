// backend/src/index.js
// Mantra Backend — Node.js + Fastify + PostgreSQL + Redis + Firebase

'use strict';

const Fastify = require('fastify');
const cors = require('@fastify/cors');
const helmet = require('@fastify/helmet');
const rateLimit = require('@fastify/rate-limit');
const jwt = require('@fastify/jwt');
const multipart = require('@fastify/multipart');
const { createClient } = require('redis');
const { Pool } = require('pg');

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const matchRoutes = require('./routes/match');
const chatRoutes = require('./routes/chat');
const communityRoutes = require('./routes/community');
const safetyRoutes = require('./routes/safety');
const paymentRoutes = require('./routes/payment');
const adminRoutes = require('./routes/admin');

async function buildApp(options = {}) {
  const app = Fastify({
    logger: options.logger !== undefined
      ? options.logger
      : {
          level: process.env.LOG_LEVEL || 'info',
          transport: process.env.NODE_ENV === 'development'
            ? { target: 'pino-pretty' }
            : undefined,
        },
    trustProxy: true,
  });

  const db = options.db || new Pool({
    connectionString:
      process.env.MANTRA_DATABASE_URL ||
      process.env.DATABASE_URL ||
      'postgresql://postgres:postgres@localhost:5432/mantra_db',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 3000,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: true } : false,
  });

  const redisUrl = process.env.MANTRA_REDIS_URL || process.env.REDIS_URL || 'redis://localhost:6379';
  const redis = options.redis || createClient({
    url: redisUrl,
    socket: { reconnectStrategy: (retries) => Math.min(retries * 100, 3000) },
  });

  // ─── Plugins ──────────────────────────────────────────────
  await app.register(helmet, {
    contentSecurityPolicy: false,
  });

  await app.register(cors, {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true,
  });

  if (options.enableRateLimit !== false) {
    try {
      await app.register(rateLimit, {
        global: true,
        max: 150,
        timeWindow: '1 minute',
        keyGenerator: (req) => req.ip,
        errorResponseBuilder: () => ({
          statusCode: 429,
          error: 'Too Many Requests',
          message: 'Slow down. Try again in a moment.',
        }),
      });
    } catch (_) {}
  }

  const jwtSecret =
    options.jwtSecret ||
    process.env.MANTRA_JWT_SECRET ||
    process.env.JWT_SECRET ||
    'mantra-super-secret-jwt-key-2026';

  await app.register(jwt, {
    secret: jwtSecret,
    sign: { expiresIn: '15m' },
  });

  await app.register(multipart, {
    limits: {
      fileSize: 50 * 1024 * 1024, // 50MB
      files: 6,
    },
  });

  // ─── Decorators ───────────────────────────────────────────
  app.decorate('db', db);
  app.decorate('redis', redis);

  // Auth middleware
  app.decorate('authenticate', async function (req, reply) {
    try {
      await req.jwtVerify();
      // Check token blacklist if redis available
      if (redis && redis.get) {
        try {
          const blacklisted = await redis.get(`blacklist:${req.user.jti}`);
          if (blacklisted) {
            return reply.code(401).send({ error: 'Token revoked' });
          }
        } catch (_) {}
      }
    } catch (err) {
      reply.code(401).send({ error: 'Unauthorized' });
    }
  });

  // Response helpers
  app.decorate('sendSuccess', function (reply, data, meta = {}) {
    return reply.send({ success: true, data, meta });
  });

  app.decorate('sendError', function (reply, message, statusCode = 400) {
    return reply.code(statusCode).send({ success: false, error: message });
  });

  // ─── Routes ───────────────────────────────────────────────
  const prefix = '/api/v1';

  app.register(authRoutes, { prefix: `${prefix}/auth` });
  app.register(profileRoutes, { prefix: `${prefix}/profile` });
  app.register(matchRoutes, { prefix: `${prefix}/match` });
  app.register(chatRoutes, { prefix: `${prefix}/chat` });
  app.register(communityRoutes, { prefix: `${prefix}/rooms` });
  app.register(safetyRoutes, { prefix: `${prefix}/safety` });
  app.register(paymentRoutes, { prefix: `${prefix}/payment` });
  app.register(adminRoutes, { prefix: `${prefix}/admin` });

  // Root & Health check
  app.get('/health', async () => ({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'mantra-backend',
    version: '1.0.0',
  }));

  app.get('/', async () => ({
    name: 'Mantra Dating API',
    status: 'active',
    documentation: '/docs',
  }));

  // ─── Error Handlers ───────────────────────────────────────
  app.setErrorHandler((error, req, reply) => {
    req.log.error(error);

    if (error.validation) {
      return reply.code(422).send({
        success: false,
        error: 'Validation failed',
        details: error.validation,
      });
    }

    if (error.statusCode === 429) {
      return reply.code(429).send({
        success: false,
        error: 'Rate limit exceeded',
      });
    }

    return reply.code(error.statusCode || 500).send({
      success: false,
      error: process.env.NODE_ENV === 'production'
        ? 'Internal server error'
        : error.message,
    });
  });

  app.setNotFoundHandler((req, reply) => {
    reply.code(404).send({ success: false, error: 'Route not found' });
  });

  return app;
}

// ─── Startup ──────────────────────────────────────────────
async function start() {
  try {
    const app = await buildApp();

    try {
      if (app.redis.connect) await app.redis.connect();
      app.log.info('Redis client connected');
    } catch (rErr) {
      app.log.warn(`Redis not available (${rErr.message}) - continuing with degraded caching`);
    }

    try {
      await app.db.query('SELECT 1');
      app.log.info('PostgreSQL connected');
    } catch (dbErr) {
      app.log.warn(`PostgreSQL connection check failed (${dbErr.message})`);
    }

    const port = parseInt(process.env.MANTRA_PORT || process.env.PORT || '3000');
    const host = process.env.HOST || '0.0.0.0';

    await app.listen({ port, host });
    app.log.info(`Mantra API running on http://${host}:${port}`);

    // Graceful shutdown
    const shutdown = async () => {
      app.log.info('Gracefully shutting down Mantra backend...');
      await app.close();
      if (app.redis && app.redis.quit) await app.redis.quit().catch(() => {});
      if (app.db && app.db.end) await app.db.end().catch(() => {});
      process.exit(0);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
  } catch (err) {
    console.error('Failed to start Mantra API:', err);
    process.exit(1);
  }
}

if (require.main === module) {
  start();
}

module.exports = { buildApp, start };
