-- backend/database/schema.sql
-- Mantra Reconciled & Canonical PostgreSQL Schema
-- Run: psql $DATABASE_URL -f schema.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── ENUMS ────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE account_status AS ENUM ('active', 'suspended', 'banned', 'shadow_banned', 'deleted');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE gender_type AS ENUM ('man', 'woman', 'nonbinary', 'prefer_not_say');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE connection_status AS ENUM ('pending', 'connected', 'disconnected', 'blocked', 'flagged');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE report_reason AS ENUM ('inappropriate', 'fake', 'harassment', 'explicit', 'scam', 'other');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE report_status AS ENUM ('pending', 'reviewing', 'resolved', 'dismissed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE premium_tier AS ENUM ('gold', 'platinum');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE room_type AS ENUM ('interest', 'city', 'career', 'emotion', 'activity', 'women_only', 'language');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE message_type AS ENUM ('text', 'voice', 'gif', 'system');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE moderation_status AS ENUM ('approved', 'flagged', 'removed', 'pending');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE kyc_level AS ENUM ('unverified', 'phone', 'id_verified', 'face_verified', 'fully_verified');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ─── USERS ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_hash          VARCHAR(64) UNIQUE NOT NULL,
  email_hash          VARCHAR(64),
  firebase_uid        VARCHAR(128) UNIQUE,
  verification_level  SMALLINT DEFAULT 1 CHECK (verification_level BETWEEN 1 AND 5),
  kyc_level           kyc_level DEFAULT 'phone',
  account_status      account_status DEFAULT 'active',
  gender              gender_type,
  age                 SMALLINT CHECK (age >= 18 AND age <= 100),
  city                VARCHAR(100),
  is_premium          BOOLEAN DEFAULT FALSE,
  premium_tier        premium_tier,
  premium_expires_at  TIMESTAMPTZ,
  is_onboarded        BOOLEAN DEFAULT FALSE,
  onboarding_step     SMALLINT DEFAULT 0,
  is_admin            BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  last_active         TIMESTAMPTZ DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ,
  device_fingerprints JSONB DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_hash);
CREATE INDEX IF NOT EXISTS idx_users_firebase ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(account_status) WHERE account_status = 'active';
CREATE INDEX IF NOT EXISTS idx_users_last_active ON users(last_active DESC);
CREATE INDEX IF NOT EXISTS idx_users_gender_age ON users(gender, age) WHERE account_status = 'active';

-- ─── PROFILES ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  user_id                 UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name            VARCHAR(30) NOT NULL,
  bio_prompt_responses    JSONB DEFAULT '[]',
  personality_tags        TEXT[] DEFAULT '{}',
  personality_vector      FLOAT[] DEFAULT '{}',
  voice_intro_url         VARCHAR(500),
  voice_transcript        TEXT,
  voice_sentiment_score   FLOAT CHECK (voice_sentiment_score BETWEEN -1 AND 1),
  photo_urls              TEXT[] DEFAULT '{}',
  photos_blurred          BOOLEAN DEFAULT TRUE,
  intent                  VARCHAR(50),
  trust_score             DECIMAL(5,2) DEFAULT 50.00 CHECK (trust_score BETWEEN 0 AND 100),
  creep_score             DECIMAL(5,2) DEFAULT 0.00 CHECK (creep_score BETWEEN 0 AND 100),
  profile_completeness    SMALLINT DEFAULT 0 CHECK (profile_completeness BETWEEN 0 AND 100),
  is_searchable           BOOLEAN DEFAULT TRUE,
  women_only_mode         BOOLEAN DEFAULT FALSE,
  ghost_mode              BOOLEAN DEFAULT FALSE,
  language_prefs          TEXT[] DEFAULT '{hindi_english}',
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_trust ON profiles(trust_score DESC) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_searchable ON profiles(is_searchable, women_only_mode, ghost_mode);
CREATE INDEX IF NOT EXISTS idx_profiles_tags ON profiles USING GIN(personality_tags);

-- ─── TRUST SCORE EVENTS ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trust_score_events (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score_delta   DECIMAL(5,2) NOT NULL,
  reason        VARCHAR(100) NOT NULL,
  triggered_by  VARCHAR(50) DEFAULT 'system',
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trust_events_user ON trust_score_events(user_id, created_at DESC);

-- ─── CONNECTIONS ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS connections (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_a              UUID NOT NULL REFERENCES users(id),
  user_b              UUID NOT NULL REFERENCES users(id),
  status              connection_status DEFAULT 'connected',
  stage               SMALLINT DEFAULT 1 CHECK (stage BETWEEN 1 AND 5),
  initiated_by        UUID REFERENCES users(id),
  connected_at        TIMESTAMPTZ DEFAULT NOW(),
  last_message_at     TIMESTAMPTZ,
  name_revealed_at    TIMESTAMPTZ,
  photo_revealed_at   TIMESTAMPTZ,
  voice_call_at       TIMESTAMPTZ,
  stage_updated_at    TIMESTAMPTZ DEFAULT NOW(),
  message_count       INTEGER DEFAULT 0,
  is_disappearing     BOOLEAN DEFAULT FALSE,
  disappear_hours     SMALLINT DEFAULT 24,
  ai_suggestion       TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT no_self_connection CHECK (user_a != user_b),
  CONSTRAINT ordered_pair CHECK (user_a < user_b),
  CONSTRAINT unique_connection UNIQUE (user_a, user_b)
);

CREATE INDEX IF NOT EXISTS idx_connections_user_a ON connections(user_a, status, stage);
CREATE INDEX IF NOT EXISTS idx_connections_user_b ON connections(user_b, status, stage);
CREATE INDEX IF NOT EXISTS idx_connections_recent ON connections(last_message_at DESC) WHERE status = 'connected';
CREATE INDEX IF NOT EXISTS idx_connections_stage ON connections(stage) WHERE status = 'connected';

-- ─── SPARKS DELIVERED ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sparks_delivered (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action            VARCHAR(20) DEFAULT 'pending',
  action_at         TIMESTAMPTZ,
  score_at_delivery DECIMAL(5,2),
  rank_position     SMALLINT,
  delivered_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_spark UNIQUE (user_id, target_user_id)
);

CREATE INDEX IF NOT EXISTS idx_sparks_user ON sparks_delivered(user_id, delivered_at DESC);
CREATE INDEX IF NOT EXISTS idx_sparks_action ON sparks_delivered(user_id, action);

-- ─── BLOCKS ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS blocks (
  blocker_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason        VARCHAR(100),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON blocks(blocked_id);

-- ─── REPORTS ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reports (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id       UUID NOT NULL REFERENCES users(id),
  reported_user_id  UUID NOT NULL REFERENCES users(id),
  reason            report_reason NOT NULL,
  note              TEXT,
  evidence_urls     TEXT[] DEFAULT '{}',
  status            report_status DEFAULT 'pending',
  assigned_to       VARCHAR(100),
  resolver_note     TEXT,
  resolved_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_reports_reported ON reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);

-- ─── ROOMS ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS rooms (
  id                         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                       VARCHAR(100) NOT NULL,
  description                TEXT,
  emoji                      VARCHAR(10) DEFAULT '💬',
  room_type                  room_type NOT NULL,
  tags                       TEXT[] DEFAULT '{}',
  color                      VARCHAR(9) DEFAULT '#7A9E7E',
  city                       VARCHAR(100),
  language                   VARCHAR(30) DEFAULT 'hindi_english',
  cover_image_url            VARCHAR(500),
  member_count               INTEGER DEFAULT 0,
  post_count                 INTEGER DEFAULT 0,
  is_active                  BOOLEAN DEFAULT TRUE,
  is_featured                BOOLEAN DEFAULT FALSE,
  requires_verification      SMALLINT DEFAULT 1,
  women_only                 BOOLEAN DEFAULT FALSE,
  is_premium                 BOOLEAN DEFAULT FALSE,
  created_by                 UUID REFERENCES users(id),
  last_activity_at           TIMESTAMPTZ DEFAULT NOW(),
  created_at                 TIMESTAMPTZ DEFAULT NOW(),
  updated_at                 TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_type ON rooms(room_type) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_rooms_featured ON rooms(is_featured, member_count DESC);
CREATE INDEX IF NOT EXISTS idx_rooms_city ON rooms(city) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_rooms_women ON rooms(women_only) WHERE is_active = TRUE;

-- ─── ROOM MEMBERS ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS room_members (
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  room_id       UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  role          VARCHAR(20) DEFAULT 'member',
  post_count    INTEGER DEFAULT 0,
  last_active   TIMESTAMPTZ DEFAULT NOW(),
  joined_at     TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, room_id)
);

CREATE INDEX IF NOT EXISTS idx_room_members_user ON room_members(user_id);
CREATE INDEX IF NOT EXISTS idx_room_members_room ON room_members(room_id, last_active DESC);

-- ─── ROOM POSTS ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS room_posts (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id             UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  author_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content             TEXT NOT NULL,
  post_type           VARCHAR(20) DEFAULT 'text',
  media_url           VARCHAR(500),
  media_urls          TEXT[] DEFAULT '{}',
  is_anonymous        BOOLEAN DEFAULT FALSE,
  reaction_counts     JSONB DEFAULT '{"❤️":0,"🔥":0,"💭":0,"😂":0}',
  poll_options        JSONB DEFAULT '[]',
  like_count          INTEGER DEFAULT 0,
  comment_count       INTEGER DEFAULT 0,
  reply_count         INTEGER DEFAULT 0,
  is_pinned           BOOLEAN DEFAULT FALSE,
  moderation_status   moderation_status DEFAULT 'approved',
  ai_toxicity_score   FLOAT DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_room_time ON room_posts(room_id, created_at DESC) WHERE moderation_status = 'approved';
CREATE INDEX IF NOT EXISTS idx_posts_author ON room_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_search ON room_posts USING GIN(to_tsvector('english', content));

-- ─── MESSAGES ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS messages (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  connection_id       UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
  sender_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content             TEXT NOT NULL,
  message_type        message_type DEFAULT 'text',
  moderation_status   moderation_status DEFAULT 'approved',
  is_read             BOOLEAN DEFAULT FALSE,
  reaction            VARCHAR(10),
  reply_to_id         UUID REFERENCES messages(id),
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_messages_connection ON messages(connection_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);

-- ─── TRUSTED CONTACTS ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trusted_contacts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trusted_contacts_user ON trusted_contacts(user_id);

-- ─── SOS EVENTS ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sos_events (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id),
  latitude          DECIMAL(10, 7),
  longitude         DECIMAL(10, 7),
  contacts_alerted  SMALLINT DEFAULT 0,
  conversation_id   UUID REFERENCES connections(id),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sos_user ON sos_events(user_id, created_at DESC);

-- ─── PAYMENT ORDERS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS payment_orders (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES users(id),
  razorpay_order_id     VARCHAR(100) UNIQUE NOT NULL,
  razorpay_payment_id   VARCHAR(100),
  plan_id               VARCHAR(50) NOT NULL,
  amount                INTEGER NOT NULL,
  status                VARCHAR(20) DEFAULT 'pending',
  paid_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON payment_orders(user_id, created_at DESC);

-- ─── SUBSCRIPTIONS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS subscriptions (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES users(id),
  tier                  premium_tier NOT NULL,
  billing_period        VARCHAR(10) DEFAULT 'monthly',
  amount_paise          INTEGER NOT NULL,
  razorpay_order_id     VARCHAR(100),
  razorpay_payment_id   VARCHAR(100),
  razorpay_sub_id       VARCHAR(100),
  status                VARCHAR(20) DEFAULT 'active',
  started_at            TIMESTAMPTZ DEFAULT NOW(),
  expires_at            TIMESTAMPTZ NOT NULL,
  cancelled_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subs_user ON subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_subs_expiry ON subscriptions(expires_at) WHERE status = 'active';

-- ─── MOOD CHECK-INS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mood_checkins (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id),
  mood        VARCHAR(10) NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mood_user_recent ON mood_checkins(user_id, created_at DESC);

-- ─── MODERATION LOG ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS moderation_log (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type   VARCHAR(20) NOT NULL,
  entity_id     UUID NOT NULL,
  user_id       UUID NOT NULL REFERENCES users(id),
  action        VARCHAR(20) NOT NULL,
  score         FLOAT,
  categories    TEXT[] DEFAULT '{}',
  moderated_by  VARCHAR(20) DEFAULT 'ai',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mod_log_user ON moderation_log(user_id);
CREATE INDEX IF NOT EXISTS idx_mod_log_entity ON moderation_log(entity_type, entity_id);

-- ─── DATABASE FUNCTIONS & TRIGGERS ────────────────────────────────────

CREATE OR REPLACE FUNCTION update_connection_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE connections
  SET message_count = message_count + 1, last_message_at = NOW()
  WHERE id = NEW.connection_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_message_stats ON messages;
CREATE TRIGGER trg_message_stats
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_connection_stats();

-- Soft delete users (DPDP compliance)
CREATE OR REPLACE FUNCTION soft_delete_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET
    account_status = 'deleted',
    phone_hash = 'DELETED_' || p_user_id,
    email_hash = NULL,
    firebase_uid = NULL,
    deleted_at = NOW()
  WHERE id = p_user_id;

  UPDATE profiles SET
    display_name = 'Deleted User',
    bio_prompt_responses = '[]',
    voice_intro_url = NULL,
    photo_urls = '{}',
    is_searchable = FALSE
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ─── SEED DATA ────────────────────────────────────────────────────────

INSERT INTO rooms (id, name, description, emoji, room_type, color, city, member_count, is_featured, women_only, tags) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Bollywood Unpopular Opinions', 'Hot takes welcome. Fights expected.', '🎬', 'interest', '#C4654A', NULL, 1247, TRUE, FALSE, '{bollywood,movies,popculture}'),
  ('a0000000-0000-0000-0000-000000000002', 'Desi Women Talk', 'A safe space. Vent, share, support.', '🌸', 'women_only', '#7A9E7E', NULL, 892, FALSE, TRUE, '{women,safe,support}'),
  ('a0000000-0000-0000-0000-000000000003', 'First-gen Professionals', 'Corporate struggles and wins.', '💼', 'career', '#5B8DB8', NULL, 2103, TRUE, FALSE, '{career,corporate,growth}'),
  ('a0000000-0000-0000-0000-000000000004', 'Reading Circle: Slow Sundays', 'Books that made us pause and think.', '📚', 'activity', '#D4884A', NULL, 318, TRUE, FALSE, '{books,reading,calm}'),
  ('a0000000-0000-0000-0000-000000000005', 'Startup Founders India', 'Building in public and learning.', '🚀', 'career', '#4CAF79', 'Bengaluru', 1678, FALSE, FALSE, '{startup,tech,founder}'),
  ('a0000000-0000-0000-0000-000000000006', 'Gentle Vent Space', 'Be kind. Listen first.', '🌧️', 'emotion', '#8B6BB1', NULL, 445, FALSE, FALSE, '{vent,feelings,empathy}'),
  ('a0000000-0000-0000-0000-000000000007', 'Hinglish Chai Gang', 'Bhai/Behen log ek saath.', '☕', 'language', '#E8A030', NULL, 3201, TRUE, FALSE, '{chai,hindi,hinglish}'),
  ('a0000000-0000-0000-0000-000000000008', 'Pune Night Owls', 'For those alive after midnight.', '🌙', 'city', '#5B8DB8', 'Pune', 543, FALSE, FALSE, '{pune,night,local}')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  room_type = EXCLUDED.room_type,
  emoji = EXCLUDED.emoji,
  color = EXCLUDED.color,
  tags = EXCLUDED.tags;
