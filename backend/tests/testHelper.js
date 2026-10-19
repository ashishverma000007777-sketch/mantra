// backend/tests/testHelper.js
'use strict';

const { buildApp } = require('../src/index');

class MockDatabase {
  constructor() {
    this.users = new Map();
    this.profiles = new Map();
    this.connections = new Map();
    this.sparks = new Map();
    this.blocks = new Map();
    this.reports = new Map();
    this.rooms = new Map([
      ['a0000000-0000-0000-0000-000000000001', {
        id: 'a0000000-0000-0000-0000-000000000001',
        name: 'Bollywood Unpopular Opinions',
        description: 'Hot takes welcome. Fights expected.',
        emoji: '🎬',
        room_type: 'interest',
        color: '#C4654A',
        city: null,
        tags: ['bollywood'],
        member_count: 1247,
        post_count: 50,
        is_active: true,
        is_featured: true,
        women_only: false,
      }],
      ['a0000000-0000-0000-0000-000000000002', {
        id: 'a0000000-0000-0000-0000-000000000002',
        name: 'Desi Women Talk',
        description: 'A safe space for women.',
        emoji: '🌸',
        room_type: 'women_only',
        color: '#7A9E7E',
        city: null,
        tags: ['women'],
        member_count: 892,
        post_count: 30,
        is_active: true,
        is_featured: false,
        women_only: true,
      }],
    ]);
    this.roomMembers = new Map();
    this.roomPosts = new Map();
    this.messages = new Map();
    this.trustedContacts = new Map();
    this.paymentOrders = new Map();
  }

  async query(sql, params = []) {
    const s = sql.toLowerCase();

    // Health
    if (s.includes('select 1')) {
      return { rows: [{ '?column?': 1 }], rowCount: 1 };
    }

    // Users / Auth
    if (s.includes('insert into users')) {
      const id = params[0];
      const phone_hash = params[1];
      const firebase_uid = params[2];
      const user = {
        id,
        phone_hash,
        firebase_uid,
        verification_level: 1,
        account_status: 'active',
        is_onboarded: false,
        is_admin: false,
        is_premium: false,
        created_at: new Date().toISOString(),
        last_active: new Date().toISOString(),
      };
      this.users.set(id, user);
      return { rows: [user], rowCount: 1 };
    }

    if (s.includes('from users') && s.includes('where u.id = $1')) {
      const u = this.users.get(params[0]) || {
        id: params[0],
        verification_level: 1,
        account_status: 'active',
        is_onboarded: true,
        is_admin: false,
        is_premium: false,
        gender: 'woman',
        age: 26,
        city: 'Mumbai',
      };
      const p = this.profiles.get(params[0]) || {
        display_name: 'TestUser',
        trust_score: '75.00',
        photos_blurred: true,
      };
      return { rows: [{ ...u, ...p }], rowCount: 1 };
    }

    if (s.includes('select is_admin from users')) {
      const u = this.users.get(params[0]);
      return { rows: [{ is_admin: u ? !!u.is_admin : false }], rowCount: 1 };
    }

    if (s.includes('select gender from users')) {
      const u = this.users.get(params[0]);
      return { rows: [{ gender: u?.gender || 'woman' }], rowCount: 1 };
    }

    // Profiles
    if (s.includes('select user_id from profiles where user_id = $1')) {
      const p = this.profiles.get(params[0]);
      return { rows: p ? [{ user_id: p.user_id }] : [], rowCount: p ? 1 : 0 };
    }

    if (s.includes('insert into profiles')) {
      const profile = {
        user_id: params[0],
        display_name: params[1],
        intent: params[2],
        personality_tags: params[3],
        bio_prompt_responses: params[4],
        language_prefs: params[5],
        trust_score: 50,
        photos_blurred: true,
        is_searchable: true,
      };
      this.profiles.set(params[0], profile);
      return { rows: [profile], rowCount: 1 };
    }

    if (s.includes('update profiles set display_name=$1')) {
      const p = this.profiles.get(params[5]) || {};
      Object.assign(p, {
        display_name: params[0],
        intent: params[1],
        personality_tags: params[2],
        bio_prompt_responses: params[3],
        language_prefs: params[4],
      });
      this.profiles.set(params[5], p);
      return { rows: [p], rowCount: 1 };
    }

    if (s.includes('from profiles p') && s.includes('where p.user_id = $1')) {
      const p = this.profiles.get(params[0]) || {
        user_id: params[0],
        display_name: 'TestProfile',
        personality_tags: ['chai', 'reading'],
        trust_score: '80.00',
        photos_blurred: true,
        photo_urls: [],
        bio_prompt_responses: [{ question: 'Sunday', answer: 'Tea' }],
      };
      const u = this.users.get(params[0]) || { gender: 'woman', age: 25, city: 'Mumbai', is_premium: false };
      return { rows: [{ ...p, prompt_responses: p.bio_prompt_responses, ...u }], rowCount: 1 };
    }

    // Sparks / Matching
    if (s.includes('from sparks_delivered')) {
      return { rows: [], rowCount: 0 };
    }

    if (s.includes('from blocks')) {
      return { rows: [], rowCount: 0 };
    }

    if (s.includes('from profiles p join users u')) {
      return {
        rows: [
          {
            user_id: '99999999-9999-9999-9999-999999999991',
            display_name: 'Candidate A',
            trust_score: '85.00',
            personality_tags: ['books', 'chai'],
            photo_urls: ['https://example.com/p1.jpg'],
            bio_prompt_responses: [],
            age: 26,
            city: 'Mumbai',
            gender: 'man',
            verification_level: 3,
            is_verified: true,
          },
        ],
        rowCount: 1,
      };
    }

    if (s.includes('insert into sparks_delivered')) {
      return { rows: [{ id: 'spark-1' }], rowCount: 1 };
    }

    if (s.includes('insert into connections')) {
      const id = params[0];
      const conn = { id, user_a: params[1], user_b: params[2], status: 'connected', stage: 1 };
      this.connections.set(id, conn);
      return { rows: [{ id }], rowCount: 1 };
    }

    // Chat / Messages
    if (s.includes('from connections c')) {
      return {
        rows: Array.from(this.connections.values()).map(c => ({
          ...c,
          other_user_id: 'other-user',
          display_name: 'Mira',
          photos_blurred: true,
          last_message: 'Hello!',
          unread_count: 0,
        })),
        rowCount: this.connections.size,
      };
    }

    if (s.includes('from connections') && s.includes('id = $1')) {
      const conn = this.connections.get(params[0]) || {
        id: params[0],
        user_a: params[1],
        user_b: 'other-user-uuid',
        stage: 1,
        status: 'connected',
      };
      return { rows: [conn], rowCount: 1 };
    }

    if (s.includes('insert into messages')) {
      const msg = {
        id: params[0],
        connection_id: params[1],
        sender_id: params[2],
        content: params[3],
        message_type: params[4],
        moderation_status: params[5],
        created_at: new Date().toISOString(),
      };
      this.messages.set(params[0], msg);
      return { rows: [msg], rowCount: 1 };
    }

    if (s.includes('from messages m')) {
      return { rows: Array.from(this.messages.values()), rowCount: this.messages.size };
    }

    // Community Rooms
    if (s.includes('from rooms r')) {
      if (params[0] && this.rooms.has(params[0])) {
        return { rows: [{ ...this.rooms.get(params[0]), is_member: true }], rowCount: 1 };
      }
      return { rows: Array.from(this.rooms.values()).map(r => ({ ...r, is_member: false })), rowCount: this.rooms.size };
    }

    if (s.includes('select room_type from rooms')) {
      const r = this.rooms.get(params[0]);
      return { rows: r ? [{ room_type: r.room_type }] : [], rowCount: r ? 1 : 0 };
    }

    if (s.includes('insert into room_members')) {
      return { rows: [{ user_id: params[0] }], rowCount: 1 };
    }

    if (s.includes('insert into room_posts')) {
      return { rows: [{ id: params[0] }], rowCount: 1 };
    }

    // Safety
    if (s.includes('insert into reports')) {
      return { rows: [{ id: params[0] }], rowCount: 1 };
    }

    if (s.includes('insert into blocks')) {
      return { rows: [], rowCount: 1 };
    }

    if (s.includes('from trusted_contacts')) {
      if (s.includes('count(*)')) {
        return { rows: [{ count: 1 }], rowCount: 1 };
      }
      return { rows: [{ id: 'tc-1', name: 'Papa', phone: '+919876543210' }], rowCount: 1 };
    }

    if (s.includes('insert into trusted_contacts')) {
      return { rows: [{ id: params[0] }], rowCount: 1 };
    }

    if (s.includes('insert into sos_events')) {
      return { rows: [{ id: params[0] }], rowCount: 1 };
    }

    // Payments
    if (s.includes('insert into payment_orders')) {
      this.paymentOrders.set(params[2], {
        id: params[0],
        user_id: params[1],
        razorpay_order_id: params[2],
        plan_id: params[3],
        amount: params[4],
        status: 'pending',
      });
      return { rows: [], rowCount: 1 };
    }

    if (s.includes('from payment_orders')) {
      const o = this.paymentOrders.get(params[0]);
      if (o) {
        return { rows: [o], rowCount: 1 };
      }
      return { rows: [], rowCount: 0 };
    }

    if (s.includes('update payment_orders')) {
      for (const [orderId, order] of this.paymentOrders.entries()) {
        if (params.includes(orderId)) {
          order.status = s.includes("'failed'") ? 'failed' : 'paid';
          break;
        }
      }
      return { rows: [{ id: 'order-1' }], rowCount: 1 };
    }

    // Fallback
    return { rows: [], rowCount: 0 };
  }

  async end() {}
}

class MockRedis {
  constructor() {
    this.store = new Map();
  }

  async get(k) { return this.store.get(k) || null; }
  async set(k, v) { this.store.set(k, String(v)); return 'OK'; }
  async setEx(k, ttl, v) { this.store.set(k, String(v)); return 'OK'; }
  async del(k) { this.store.delete(k); return 1; }
  async lPush(k, v) { return 1; }
  async publish(ch, msg) { return 1; }
  async connect() {}
  async quit() {}
}

async function createTestApp() {
  const db = new MockDatabase();
  const redis = new MockRedis();
  return buildApp({
    db,
    redis,
    enableRateLimit: false,
    logger: false,
    jwtSecret: 'test-jwt-secret-for-mantra-testing-only-12345',
  });
}

module.exports = { createTestApp, MockDatabase, MockRedis };
