-- backend/database/migrations/002_signature_features.sql
-- Mantra Signature Features: Mystery Match, Compatibility DNA, Conversation Quest, Gradual Reveal, Connection Garden

-- 1. Mystery Discoveries (Tracking personality-first discovery candidate views & actions)
CREATE TABLE IF NOT EXISTS mystery_discoveries (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action            VARCHAR(20) DEFAULT 'pending', -- 'explore', 'pass', 'pending'
  action_at         TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_mystery_discovery UNIQUE (user_id, target_user_id)
);
CREATE INDEX IF NOT EXISTS idx_mystery_user ON mystery_discoveries(user_id, created_at DESC);

-- 2. Compatibility Profiles (7-dimension persistent questionnaire & calculated dimensions)
CREATE TABLE IF NOT EXISTS compatibility_profiles (
  user_id           UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  answers           JSONB NOT NULL DEFAULT '{}',
  dimensions        JSONB NOT NULL DEFAULT '{}',
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_compatibility_user ON compatibility_profiles(user_id);

-- 3. Conversation Quests (Daily prompts, mutual submission, follow-up, reactions)
CREATE TABLE IF NOT EXISTS conversation_quests (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category          VARCHAR(30) NOT NULL, -- values, memories, relationships, aspirations, humour, everyday_life
  prompt_text       TEXT NOT NULL,
  follow_up_prompt  TEXT,
  is_active         BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quest_answers (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quest_id          UUID NOT NULL REFERENCES conversation_quests(id) ON DELETE CASCADE,
  connection_id     UUID REFERENCES connections(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  answer_text       TEXT NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_quest_user_connection UNIQUE (quest_id, connection_id, user_id)
);

CREATE TABLE IF NOT EXISTS quest_reactions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quest_answer_id   UUID NOT NULL REFERENCES quest_answers(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reaction          VARCHAR(20) NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_quest_reaction UNIQUE (quest_answer_id, user_id)
);

-- 4. Reveal Requests (Gradual Identity Reveal: Mind -> Voice -> Connection -> Face)
CREATE TABLE IF NOT EXISTS reveal_requests (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  connection_id     UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
  requester_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stage             VARCHAR(20) NOT NULL CHECK (stage IN ('voice', 'connection', 'face')),
  status            VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'revoked')),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_reveal_request UNIQUE (connection_id, requester_id, stage)
);
CREATE INDEX IF NOT EXISTS idx_reveal_conn ON reveal_requests(connection_id, stage, status);

-- Add reveal_stage to connections if not exists
DO $$ BEGIN
  ALTER TABLE connections ADD COLUMN reveal_stage VARCHAR(20) DEFAULT 'mind' CHECK (reveal_stage IN ('mind', 'voice', 'connection', 'face'));
EXCEPTION WHEN duplicate_column THEN null; END $$;

-- 5. Connection Gardens (Mindful relationship growth: seed -> sprout -> growing -> bloom)
CREATE TABLE IF NOT EXISTS connection_gardens (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  connection_id     UUID UNIQUE NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
  stage             VARCHAR(20) NOT NULL DEFAULT 'seed' CHECK (stage IN ('seed', 'sprout', 'growing', 'bloom')),
  growth_points     INTEGER DEFAULT 10,
  milestone_history JSONB DEFAULT '[]',
  is_paused         BOOLEAN DEFAULT FALSE,
  last_activity_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gardens_conn ON connection_gardens(connection_id);

-- Seed Conversation Quests across 6 categories
INSERT INTO conversation_quests (id, category, prompt_text, follow_up_prompt) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'values', 'What is one personal principle you will never compromise on, even when it is difficult?', 'How has holding this boundary helped you grow?'),
  ('b0000000-0000-0000-0000-000000000002', 'memories', 'What is a small, quiet memory from childhood that still brings you a sense of calm?', 'Who was with you during that moment?'),
  ('b0000000-0000-0000-0000-000000000003', 'relationships', 'When life feels overwhelming, what does genuine emotional support look like for you?', 'How can a partner best hold space for you then?'),
  ('b0000000-0000-0000-0000-000000000004', 'aspirations', 'If you could dedicate the next year entirely to one passion project, what would it be?', 'What first sparked your fascination with it?'),
  ('b0000000-0000-0000-0000-000000000005', 'humour', 'What is something undeniably silly or quirky that never fails to make you smile?', 'Has anyone ever caught you laughing about it alone?'),
  ('b0000000-0000-0000-0000-000000000006', 'everyday_life', 'What is your cherished slow Sunday morning ritual that grounds your upcoming week?', 'Is it tea, reading, morning walks, or stillness?')
ON CONFLICT (id) DO NOTHING;
