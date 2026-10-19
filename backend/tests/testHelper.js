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

    // Signature Features Mock Storage
    this.mysteryDiscoveries = new Map();
    this.compatibilityProfiles = new Map();
    this.conversationQuests = new Map([
      ['b0000000-0000-0000-0000-000000000001', {
        id: 'b0000000-0000-0000-0000-000000000001',
        category: 'values',
        prompt_text: 'What is one personal principle you will never compromise on?',
        follow_up_prompt: 'How has holding this boundary helped you grow?',
        is_active: true,
      }],
      ['b0000000-0000-0000-0000-000000000002', {
        id: 'b0000000-0000-0000-0000-000000000002',
        category: 'memories',
        prompt_text: 'What is a small, quiet memory from childhood?',
        follow_up_prompt: 'Who was with you during that moment?',
        is_active: true,
      }],
    ]);
    this.questAnswers = new Map();
    this.questReactions = new Map();
    this.revealRequests = new Map();
    this.connectionGardens = new Map();
  }

  async query(sql, params = []) {
    const s = sql.toLowerCase();

    // Health
    if (s.trim() === 'select 1' || (s.includes('select 1') && !s.includes('from'))) {
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

    // ─── 1. Mystery Match Mock Handlers ──────────────────
    if (s.includes('from mystery_discoveries')) {
      if (s.includes('target_user_id = $2') && s.includes("action = 'explore'")) {
        const key = `${params[0]}:${params[1]}`;
        const item = this.mysteryDiscoveries.get(key);
        if (item && item.action === 'explore') {
          return { rows: [{ id: 'md-mutual' }], rowCount: 1 };
        }
        return { rows: [], rowCount: 0 };
      }
      return { rows: [], rowCount: 0 };
    }

    if (s.includes('insert into mystery_discoveries')) {
      const key = `${params[0]}:${params[1]}`;
      this.mysteryDiscoveries.set(key, {
        user_id: params[0],
        target_user_id: params[1],
        action: s.includes("'pass'") ? 'pass' : (params[2] || 'explore'),
      });
      return { rows: [{ id: 'md-1' }], rowCount: 1 };
    }

    // ─── 2. Compatibility DNA Mock Handlers ──────────────
    if (s.includes('from compatibility_profiles') && s.includes('user_id = $1 or user_id = $2')) {
      const p1 = this.compatibilityProfiles.get(params[0]) || {
        user_id: params[0],
        answers: {
          communication: { pace: 'thoughtful_daily', preferred_medium: 'voice_notes' },
          relationship_intentions: { primary_goal: 'mindful_slow_dating', pacing: 'gradual' },
          core_values: ['authenticity', 'empathy', 'growth'],
          lifestyle: { daily_rhythm: 'morning', social_energy: 'introvert' },
          emotional_readiness: { openness: 'open_and_reflective' },
          conflict_resolution: { style: 'cool_off_first' },
          shared_interests: ['chai', 'reading', 'cinema'],
        },
      };
      const p2 = this.compatibilityProfiles.get(params[1]) || {
        user_id: params[1],
        answers: {
          communication: { pace: 'thoughtful_daily', preferred_medium: 'voice_notes' },
          relationship_intentions: { primary_goal: 'mindful_slow_dating', pacing: 'gradual' },
          core_values: ['authenticity', 'empathy', 'kindness'],
          lifestyle: { daily_rhythm: 'morning', social_energy: 'ambivert' },
          emotional_readiness: { openness: 'open_and_reflective' },
          conflict_resolution: { style: 'cool_off_first' },
          shared_interests: ['chai', 'reading', 'nature'],
        },
      };
      return { rows: [p1, p2], rowCount: 2 };
    }

    if (s.includes('from compatibility_profiles') && s.includes('user_id = $1') && !s.includes('or user_id = $2')) {
      const p = this.compatibilityProfiles.get(params[0]);
      return { rows: p ? [p] : [], rowCount: p ? 1 : 0 };
    }

    if (s.includes('insert into compatibility_profiles')) {
      const entry = {
        user_id: params[0],
        answers: typeof params[1] === 'string' ? JSON.parse(params[1]) : params[1],
        dimensions: typeof params[2] === 'string' ? JSON.parse(params[2]) : params[2],
        updated_at: new Date().toISOString(),
      };
      this.compatibilityProfiles.set(params[0], entry);
      return { rows: [entry], rowCount: 1 };
    }

    // ─── 3. Conversation Quest Mock Handlers ─────────────
    if (s.includes('from conversation_quests')) {
      return {
        rows: Array.from(this.conversationQuests.values()),
        rowCount: this.conversationQuests.size,
      };
    }

    if (s.includes('from quest_answers') && s.includes('quest_id = $1') && s.includes('connection_id = $2') && s.includes('user_id = $3')) {
      const key = `${params[0]}:${params[1]}:${params[2]}`;
      const ans = this.questAnswers.get(key);
      return { rows: ans ? [ans] : [], rowCount: ans ? 1 : 0 };
    }

    if (s.includes('from quest_answers a') && s.includes('connection_id = $1')) {
      const answers = Array.from(this.questAnswers.values()).filter(a => a.connection_id === params[0]);
      return { rows: answers, rowCount: answers.length };
    }

    if (s.includes('from quest_answers') && s.includes('connections c on c.id = a.connection_id') && s.includes('a.id = $1')) {
      const ans = Array.from(this.questAnswers.values()).find(a => a.id === params[0]);
      if (ans) {
        return { rows: [{ connection_id: ans.connection_id, user_a: params[1], user_b: 'other' }], rowCount: 1 };
      }
      return { rows: [], rowCount: 0 };
    }

    if (s.includes('insert into quest_answers')) {
      const key = `${params[1]}:${params[2]}:${params[3]}`;
      const entry = {
        id: params[0],
        quest_id: params[1],
        connection_id: params[2],
        user_id: params[3],
        answer_text: params[4],
        created_at: new Date().toISOString(),
        reactions: [],
      };
      this.questAnswers.set(key, entry);
      return { rows: [entry], rowCount: 1 };
    }

    if (s.includes('insert into quest_reactions')) {
      this.questReactions.set(params[0], {
        id: params[0],
        quest_answer_id: params[1],
        user_id: params[2],
        reaction: params[3],
      });
      return { rows: [{ id: params[0] }], rowCount: 1 };
    }

    // ─── 4. Gradual Identity Reveal Mock Handlers ────────
    if (s.includes('from reveal_requests') && s.includes('connection_id = $1') && s.includes('requester_id = $2') && s.includes('stage = $3')) {
      const key = `${params[0]}:${params[1]}:${params[2]}`;
      const req = this.revealRequests.get(key);
      return { rows: req ? [req] : [], rowCount: req ? 1 : 0 };
    }

    if (s.includes('from reveal_requests') && s.includes('connection_id = $1') && s.includes('stage = $2')) {
      const reqs = Array.from(this.revealRequests.values()).filter(r => r.connection_id === params[0] && r.stage === params[1]);
      return { rows: reqs, rowCount: reqs.length };
    }

    if (s.includes('from reveal_requests') && s.includes('connection_id = $1')) {
      const reqs = Array.from(this.revealRequests.values()).filter(r => r.connection_id === params[0]);
      return { rows: reqs, rowCount: reqs.length };
    }

    if (s.includes('insert into reveal_requests')) {
      const key = `${params[1]}:${params[2]}:${params[3]}`;
      const entry = {
        id: params[0],
        connection_id: params[1],
        requester_id: params[2],
        stage: params[3],
        status: s.includes("'accepted'") ? 'accepted' : (params[4] || 'pending'),
        updated_at: new Date().toISOString(),
      };
      this.revealRequests.set(key, entry);
      return { rows: [entry], rowCount: 1 };
    }

    if (s.includes('update reveal_requests set status =')) {
      for (const req of this.revealRequests.values()) {
        if (req.connection_id === params[0]) {
          const targetStage = params.length >= 3 ? params[2] : params[1];
          const targetUser = params.length >= 3 ? params[1] : null;
          if (req.stage === targetStage && (!targetUser || req.requester_id === targetUser)) {
            req.status = s.includes("'accepted'") ? 'accepted' : s.includes("'declined'") ? 'declined' : 'revoked';
          }
        }
      }
      return { rows: [], rowCount: 1 };
    }

    if (s.includes('update connections') && s.includes('reveal_stage = $2')) {
      const conn = this.connections.get(params[0]);
      if (conn) {
        conn.reveal_stage = params[1];
        if (params[1] === 'face') conn.photo_revealed_at = new Date().toISOString();
        if (params[2] === 'face') conn.photo_revealed_at = null;
      }
      return { rows: [], rowCount: 1 };
    }

    // ─── 5. Connection Garden Mock Handlers ──────────────
    if (s.includes('from connection_gardens') && s.includes('connection_id = $1')) {
      const g = this.connectionGardens.get(params[0]);
      return { rows: g ? [g] : [], rowCount: g ? 1 : 0 };
    }

    if (s.includes('insert into connection_gardens')) {
      const isInitialSeed = params.length === 2;
      const entry = {
        connection_id: params[0],
        stage: isInitialSeed ? 'seed' : params[1],
        growth_points: isInitialSeed ? 15 : params[2],
        milestone_history: isInitialSeed
          ? (typeof params[1] === 'string' ? JSON.parse(params[1]) : params[1])
          : (typeof params[3] === 'string' ? JSON.parse(params[3]) : params[3]),
        is_paused: false,
        last_activity_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      this.connectionGardens.set(params[0], entry);
      return { rows: [entry], rowCount: 1 };
    }

    if (s.includes('update connection_gardens')) {
      const g = this.connectionGardens.get(params[0]) || {
        connection_id: params[0],
        stage: 'seed',
        growth_points: 15,
        milestone_history: [],
      };
      if (s.includes('is_paused = $2')) {
        g.is_paused = params[1];
      } else {
        if (s.includes('growth_points = growth_points + 25')) {
          g.growth_points = (g.growth_points || 15) + 25;
          if (params[1] === 'face') g.stage = 'bloom';
        } else if (s.includes('growth_points = growth_points + 15')) {
          g.growth_points = (g.growth_points || 15) + 15;
          if (g.stage === 'seed') g.stage = 'sprout';
        } else {
          if (params[1]) g.stage = params[1];
          if (params[2]) g.growth_points = params[2];
          if (params[3]) g.milestone_history = typeof params[3] === 'string' ? JSON.parse(params[3]) : params[3];
        }
        g.last_activity_at = new Date().toISOString();
      }
      this.connectionGardens.set(params[0], g);
      return { rows: [g], rowCount: 1 };
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
