-- =============================================================================
-- FidelLearn Database Schema Migration
-- Version: 20260821000000
-- Description: Complete schema with Row Level Security (RLS) for FidelLearn
-- =============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. Profiles & Roles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 8, 12)),
    stream TEXT CHECK (stream IN ('natural', 'social', 'common')),
    preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'am')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.roles (
    id TEXT PRIMARY KEY,
    description TEXT NOT NULL
);

INSERT INTO public.roles (id, description) VALUES
    ('student', 'Student preparing for Ethiopian national examinations'),
    ('teacher', 'Teacher assigning exams and viewing class performance'),
    ('school_admin', 'School administrator managing teachers and student rosters'),
    ('platform_admin', 'Platform administrator managing content, verification, and economy')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id TEXT NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    granted_by UUID REFERENCES public.profiles(id),
    PRIMARY KEY (user_id, role_id)
);

-- -----------------------------------------------------------------------------
-- 2. Educational Structure & Questions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 8, 12)),
    stream TEXT CHECK (stream IN ('natural', 'social', 'common')),
    icon_asset TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.units (
    id TEXT PRIMARY KEY,
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_number INT NOT NULL,
    title_en TEXT NOT NULL,
    title_am TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.topics (
    id TEXT PRIMARY KEY,
    unit_id TEXT NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    topic_number INT NOT NULL,
    title_en TEXT NOT NULL,
    title_am TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grade INT NOT NULL CHECK (grade IN (6, 8, 12)),
    stream TEXT NOT NULL DEFAULT 'common' CHECK (stream IN ('natural', 'social', 'common')),
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    unit_id TEXT NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
    topic_id TEXT NOT NULL REFERENCES public.topics(id) ON DELETE RESTRICT,
    exam_year INT,
    question_text_en TEXT NOT NULL,
    question_text_am TEXT,
    diagram_url TEXT,
    diagram_asset TEXT,
    difficulty TEXT NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    verification_status TEXT NOT NULL DEFAULT 'draft' CHECK (verification_status IN ('draft', 'review_required', 'approved', 'published', 'corrected', 'archived')),
    source_name TEXT NOT NULL DEFAULT 'FidelLearn original demonstration content',
    source_page INT,
    content_version INT NOT NULL DEFAULT 1,
    package_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_questions_lookup ON public.questions(grade, stream, subject_id, unit_id, topic_id, verification_status);

CREATE TABLE IF NOT EXISTS public.answer_choices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    choice_label TEXT NOT NULL CHECK (choice_label IN ('A', 'B', 'C', 'D', 'E')),
    choice_text_en TEXT NOT NULL,
    choice_text_am TEXT,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.explanations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID UNIQUE NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    solution_text_en TEXT NOT NULL,
    solution_text_am TEXT,
    simpler_explanation_en TEXT,
    key_concept_or_formula TEXT,
    distractor_rationales JSONB,
    common_pitfall TEXT
);

-- -----------------------------------------------------------------------------
-- 3. Exams, Attempts & Responses
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    exam_type TEXT NOT NULL CHECK (exam_type IN ('practice', 'unit_test', 'mock_full', 'custom_builder', 'teacher_assigned')),
    grade INT NOT NULL CHECK (grade IN (6, 8, 12)),
    stream TEXT CHECK (stream IN ('natural', 'social', 'common')),
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    time_limit_minutes INT NOT NULL DEFAULT 0,
    total_questions INT NOT NULL,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS public.exam_questions (
    exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    order_index INT NOT NULL,
    PRIMARY KEY (exam_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INT NOT NULL DEFAULT 0,
    total_questions INT NOT NULL,
    score INT NOT NULL DEFAULT 0,
    percentage NUMERIC(5,2) NOT NULL DEFAULT 0.0,
    correct_count INT NOT NULL DEFAULT 0,
    incorrect_count INT NOT NULL DEFAULT 0,
    skipped_count INT NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_attempts_user_exam ON public.attempts(user_id, exam_id, is_completed);

CREATE TABLE IF NOT EXISTS public.attempt_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE RESTRICT,
    selected_choice_id UUID REFERENCES public.answer_choices(id) ON DELETE SET NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    time_spent_seconds INT NOT NULL DEFAULT 0,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 4. Bookmarks, Mistakes & Ghost Challenges
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(user_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.mistake_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    mistake_count INT NOT NULL DEFAULT 1,
    is_mastered BOOLEAN NOT NULL DEFAULT FALSE,
    last_failed_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    mastered_at TIMESTAMPTZ,
    UNIQUE(user_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.exam_ghost_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    best_score INT NOT NULL,
    best_duration_seconds INT NOT NULL,
    best_attempt_id UUID REFERENCES public.attempts(id),
    attempt_count INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(user_id, exam_id)
);

-- -----------------------------------------------------------------------------
-- 5. Append-Only Study Coin Ledger
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coin_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('CREDIT', 'DEBIT')),
    amount INT NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    related_entity_id TEXT,
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    server_verified BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_coin_ledger_user ON public.coin_ledger(user_id, created_at);

-- -----------------------------------------------------------------------------
-- 6. Row Level Security (RLS) Policies
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answer_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.explanations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mistake_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_ghost_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coin_ledger ENABLE ROW LEVEL SECURITY;

-- Profiles: Users manage own profile
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON public.profiles;
CREATE POLICY "Profiles are viewable by owner" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Public Published Educational Content
DROP POLICY IF EXISTS "Published content is viewable by all authenticated users" ON public.subjects;
CREATE POLICY "Published content is viewable by all authenticated users" ON public.subjects FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Units are viewable by all authenticated users" ON public.units;
CREATE POLICY "Units are viewable by all authenticated users" ON public.units FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Topics are viewable by all authenticated users" ON public.topics;
CREATE POLICY "Topics are viewable by all authenticated users" ON public.topics FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Published questions viewable" ON public.questions;
CREATE POLICY "Published questions viewable" ON public.questions FOR SELECT USING (verification_status = 'published');

DROP POLICY IF EXISTS "Answer choices viewable for published questions" ON public.answer_choices;
CREATE POLICY "Answer choices viewable for published questions" ON public.answer_choices FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.questions q WHERE q.id = answer_choices.question_id AND q.verification_status = 'published')
);

DROP POLICY IF EXISTS "Explanations viewable for published questions" ON public.explanations;
CREATE POLICY "Explanations viewable for published questions" ON public.explanations FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.questions q WHERE q.id = explanations.question_id AND q.verification_status = 'published')
);

-- Attempts & Responses: Strict isolation per user
DROP POLICY IF EXISTS "Users view own attempts" ON public.attempts;
CREATE POLICY "Users view own attempts" ON public.attempts FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own attempts" ON public.attempts;
CREATE POLICY "Users insert own attempts" ON public.attempts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own attempts" ON public.attempts;
CREATE POLICY "Users update own attempts" ON public.attempts FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users view own attempt responses" ON public.attempt_responses;
CREATE POLICY "Users view own attempt responses" ON public.attempt_responses FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.attempts a WHERE a.id = attempt_responses.attempt_id AND a.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users insert own attempt responses" ON public.attempt_responses;
CREATE POLICY "Users insert own attempt responses" ON public.attempt_responses FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.attempts a WHERE a.id = attempt_responses.attempt_id AND a.user_id = auth.uid())
);

-- Bookmarks & Mistakes
DROP POLICY IF EXISTS "Users manage own bookmarks" ON public.bookmarks;
CREATE POLICY "Users manage own bookmarks" ON public.bookmarks FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own mistakes" ON public.mistake_records;
CREATE POLICY "Users manage own mistakes" ON public.mistake_records FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own ghost records" ON public.exam_ghost_records;
CREATE POLICY "Users manage own ghost records" ON public.exam_ghost_records FOR ALL USING (auth.uid() = user_id);

-- Coin Ledger: Read own, Insert ONLY through verified server functions
DROP POLICY IF EXISTS "Users view own coin ledger" ON public.coin_ledger;
CREATE POLICY "Users view own coin ledger" ON public.coin_ledger FOR SELECT USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 7. Automatic Profile Provisioning Trigger
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
  INSERT INTO public.profiles (
    id,
    phone_number,
    display_name,
    grade,
    stream,
    preferred_language
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone, NEW.email, 'student_' || SUBSTRING(NEW.id::TEXT, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Student'),
    COALESCE((NEW.raw_user_meta_data->>'grade')::INT, 12),
    COALESCE(NEW.raw_user_meta_data->>'stream', 'natural'),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    grade = COALESCE(EXCLUDED.grade, profiles.grade),
    stream = COALESCE(EXCLUDED.stream, profiles.stream),
    preferred_language = COALESCE(EXCLUDED.preferred_language, profiles.preferred_language);

  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'student');
  INSERT INTO public.user_roles (user_id, role_id)
  VALUES (NEW.id, v_role)
  ON CONFLICT (user_id, role_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
-- =============================================================================
-- Migration: Structured Curriculum Classification Mappings (Grades 9-12)
-- Enables multi-subject (Biology, Math, Physics, Chemistry, etc.)
-- and multi-year (2010-2026) national exam question classification
-- under the New Ethiopian Curriculum.
-- =============================================================================

-- 1. Curriculum Frameworks table
CREATE TABLE IF NOT EXISTS public.curriculum_frameworks (
    id TEXT PRIMARY KEY, -- 'new_curriculum_2023', 'legacy_curriculum_2013'
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    start_year INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

INSERT INTO public.curriculum_frameworks (id, name_en, name_am, start_year, is_active)
VALUES 
    ('new_curriculum_2023', 'New Ethiopian Secondary Curriculum (Grades 9-12)', 'አዲሱ የኢትዮጵያ ሁለተኛ ደረጃ ሥርዓተ ትምህርት (9-12ኛ ክፍል)', 2023, TRUE),
    ('legacy_curriculum_2013', 'Legacy Ethiopian Secondary Curriculum', 'የቀድሞው ሁለተኛ ደረጃ ሥርዓተ ትምህርት', 2013, FALSE)
ON CONFLICT (id) DO UPDATE SET is_active=EXCLUDED.is_active;

-- 2. Add curriculum classification columns to questions table
ALTER TABLE public.questions 
    ADD COLUMN IF NOT EXISTS curriculum_framework TEXT DEFAULT 'new_curriculum_2023',
    ADD COLUMN IF NOT EXISTS curriculum_grade INT,
    ADD COLUMN IF NOT EXISTS curriculum_unit_id TEXT,
    ADD COLUMN IF NOT EXISTS curriculum_topic_id TEXT;

-- Update grade check constraint on questions table to allow all secondary grades (6-12)
ALTER TABLE public.questions DROP CONSTRAINT IF EXISTS questions_grade_check;
ALTER TABLE public.questions ADD CONSTRAINT questions_grade_check CHECK (grade IN (6, 7, 8, 9, 10, 11, 12));

-- 3. Dedicated Question Curriculum Mapping Table
-- Allows a single national exam question to be classified across multiple curriculum frameworks
-- and provides structured metadata for Custom Exam Builder filtering.
CREATE TABLE IF NOT EXISTS public.question_curriculum_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL,
    exam_year INT NOT NULL,
    curriculum_framework TEXT NOT NULL REFERENCES public.curriculum_frameworks(id) ON DELETE RESTRICT DEFAULT 'new_curriculum_2023',
    curriculum_grade INT NOT NULL CHECK (curriculum_grade BETWEEN 6 AND 12),
    curriculum_unit_id TEXT NOT NULL,
    curriculum_topic_id TEXT,
    question_order_in_exam INT NOT NULL,
    unit_title_en TEXT,
    unit_title_am TEXT,
    topic_title_en TEXT,
    topic_title_am TEXT,
    cognitive_level TEXT CHECK (cognitive_level IN ('knowledge', 'comprehension', 'application', 'analysis', 'synthesis', 'evaluation')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_question_curriculum UNIQUE (question_id, curriculum_framework)
);

-- Fast lookup indexes for Custom Exam Builder filtering
CREATE INDEX IF NOT EXISTS idx_qcm_lookup 
    ON public.question_curriculum_mappings(subject_id, exam_year, curriculum_grade, curriculum_unit_id);

CREATE INDEX IF NOT EXISTS idx_qcm_grade_unit 
    ON public.question_curriculum_mappings(curriculum_grade, curriculum_unit_id, curriculum_topic_id);

CREATE INDEX IF NOT EXISTS idx_qcm_question 
    ON public.question_curriculum_mappings(question_id);

-- Enable RLS
ALTER TABLE public.curriculum_frameworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_curriculum_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on curriculum_frameworks"
    ON public.curriculum_frameworks FOR SELECT USING (true);

CREATE POLICY "Allow public read access on question_curriculum_mappings"
    ON public.question_curriculum_mappings FOR SELECT USING (true);
-- =============================================================================
-- FidelLearn Production Hardening Migration
-- Version: 20260924000000
-- Description:
--   1. Fix privilege-escalation vulnerability in handle_new_user trigger
--   2. Add content_packages table (queried by SupabaseContentRepository)
--   3. Add reward_rules table (server-controlled reward amounts)
--   4. Add redemption_catalog table (server-controlled redemption costs)
--   5. Add audit_log table
--   6. Add server-side coin RPC functions (SECURITY DEFINER, restricted EXECUTE)
--   7. Add grant_role_internal function
--   8. Harden RLS: block direct coin_ledger INSERT, block direct user_roles INSERT
--   9. Add admin write policies for content tables
--  10. Add UPDATE policy on attempt_responses (sync upsert support)
--  11. Add missing performance indexes
-- =============================================================================

-- =============================================================================
-- 1. FIX PRIVILEGE ESCALATION: handle_new_user trigger
--    BEFORE: assigned role from raw_user_meta_data (client-controlled)
--    AFTER:  always assigns 'student'; ignores any client-supplied role claim
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Populate profile from registration metadata (display info only — not role)
  INSERT INTO public.profiles (
    id,
    phone_number,
    display_name,
    grade,
    stream,
    preferred_language
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone, NEW.email, 'student_' || SUBSTRING(NEW.id::TEXT, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Student'),
    COALESCE((NEW.raw_user_meta_data->>'grade')::INT, 12),
    COALESCE(NEW.raw_user_meta_data->>'stream', 'natural'),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name       = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
    grade              = COALESCE(EXCLUDED.grade, public.profiles.grade),
    stream             = COALESCE(EXCLUDED.stream, public.profiles.stream),
    preferred_language = COALESCE(EXCLUDED.preferred_language, public.profiles.preferred_language);

  -- SECURITY: Always assign 'student' regardless of any client-supplied role.
  -- Role upgrades require a privileged Edge Function call by a platform_admin.
  INSERT INTO public.user_roles (user_id, role_id)
  VALUES (NEW.id, 'student')
  ON CONFLICT (user_id, role_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- Recreate trigger (function replace above keeps the trigger, but be explicit)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 2. CONTENT PACKAGES TABLE
--    Required by SupabaseContentRepository.getPackages()
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.content_packages (
    id TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 7, 8, 9, 10, 11, 12)),
    stream TEXT NOT NULL CHECK (stream IN ('natural', 'social', 'common')),
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    version INT NOT NULL DEFAULT 1,
    file_size_bytes BIGINT,
    question_count INT NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    download_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.content_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "content_packages_read_published"
    ON public.content_packages FOR SELECT
    USING (is_published = TRUE);

CREATE POLICY "content_packages_admin_all"
    ON public.content_packages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 3. REWARD RULES TABLE (server-controlled — client cannot set amounts)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reward_rules (
    event_type TEXT PRIMARY KEY,
    reward_amount INT NOT NULL CHECK (reward_amount > 0),
    source_table TEXT NOT NULL,
    description_en TEXT,
    description_am TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Seed initial reward rules (amounts controlled only by platform admins)
INSERT INTO public.reward_rules (event_type, reward_amount, source_table, description_en)
VALUES
    ('exam_completed',      10, 'attempts',   'Coins awarded for completing any exam'),
    ('daily_streak',         5, 'profiles',   'Coins awarded for daily study streak'),
    ('challenge_completed', 20, 'challenges', 'Coins awarded for completing a challenge'),
    ('signup_bonus',        50, 'profiles',   'One-time welcome bonus for new students'),
    ('mistake_mastered',     3, 'mistake_records', 'Coins awarded when a mistake question is mastered')
ON CONFLICT (event_type) DO NOTHING;

ALTER TABLE public.reward_rules ENABLE ROW LEVEL SECURITY;

-- All authenticated users may read rules (for local display only — server enforces)
CREATE POLICY "reward_rules_read_authenticated"
    ON public.reward_rules FOR SELECT
    USING (auth.role() = 'authenticated');

-- Only platform_admin may modify rules (must go through SECURITY DEFINER in practice)
CREATE POLICY "reward_rules_admin_write"
    ON public.reward_rules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 4. REDEMPTION CATALOG TABLE (server-controlled — client cannot set costs)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.redemption_catalog (
    item_id TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    cost INT NOT NULL CHECK (cost > 0),
    item_type TEXT NOT NULL CHECK (item_type IN ('exam_unlock', 'hint', 'cosmetic', 'airtime')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.redemption_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "redemption_catalog_read_authenticated"
    ON public.redemption_catalog FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "redemption_catalog_admin_write"
    ON public.redemption_catalog FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 5. AUDIT LOG TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,       -- e.g. 'grant_role', 'revoke_role', 'publish_question'
    target_table TEXT,
    target_id TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON public.audit_log(actor_id, created_at DESC);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Only platform admins may read the audit log
CREATE POLICY "audit_log_admin_read"
    ON public.audit_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- No direct inserts — audit log rows are created only by SECURITY DEFINER functions
CREATE POLICY "audit_log_no_direct_insert"
    ON public.audit_log FOR INSERT
    WITH CHECK (FALSE);

-- =============================================================================
-- 6. SERVER-SIDE COIN FUNCTIONS (SECURITY DEFINER, restricted EXECUTE)
--
--    These functions are called ONLY by Edge Functions using the service key.
--    They must never be directly callable by 'anon' or 'authenticated' clients.
-- =============================================================================

-- Helper: verify an event belongs to the user and exists
-- Returns the attempt row for validation inside a transaction
CREATE OR REPLACE FUNCTION public._verify_attempt_ownership(
    p_attempt_id UUID,
    p_user_id    UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.attempts
        WHERE id = p_attempt_id AND user_id = p_user_id AND is_completed = TRUE
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 6a. claim_reward_internal
-- Called by the claim-reward Edge Function.
-- Server determines amount from reward_rules — client-supplied amounts are ignored.
CREATE OR REPLACE FUNCTION public.claim_reward_internal(
    p_user_id         UUID,
    p_event_type      TEXT,
    p_source_id       TEXT,   -- Opaque ID referencing the source entity
    p_idempotency_key TEXT,
    p_ledger_id       UUID    -- Pre-generated by Edge Function for the new row
) RETURNS public.coin_ledger AS $$
DECLARE
    v_rule           public.reward_rules%ROWTYPE;
    v_existing       public.coin_ledger%ROWTYPE;
    v_new_entry      public.coin_ledger%ROWTYPE;
BEGIN
    -- 1. Load server-controlled rule (determines amount — not the client)
    SELECT * INTO v_rule FROM public.reward_rules
    WHERE event_type = p_event_type AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown or inactive event_type: %', p_event_type
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Verify source entity ownership for applicable event types
    IF p_event_type = 'exam_completed' THEN
        IF NOT public._verify_attempt_ownership(p_source_id::UUID, p_user_id) THEN
            RAISE EXCEPTION 'Attempt % does not exist or does not belong to user %',
                p_source_id, p_user_id
                USING ERRCODE = 'insufficient_privilege';
        END IF;
    END IF;
    -- Additional event type ownership checks can be added here for
    -- daily_streak, challenge_completed, etc.

    -- 3. Check idempotency (prevent double-claiming the same event)
    SELECT * INTO v_existing FROM public.coin_ledger
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        -- Return the existing entry (idempotent response — not an error)
        RETURN v_existing;
    END IF;

    -- 4. Insert ledger entry with server-determined amount
    INSERT INTO public.coin_ledger (
        id,
        user_id,
        transaction_type,
        amount,
        reason,
        related_entity_id,
        idempotency_key,
        server_verified
    ) VALUES (
        p_ledger_id,
        p_user_id,
        'CREDIT',
        v_rule.reward_amount,            -- Server-controlled amount
        v_rule.description_en,
        p_source_id,
        p_idempotency_key,
        TRUE
    )
    RETURNING * INTO v_new_entry;

    RETURN v_new_entry;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 6b. redeem_coins_atomic
-- Called by the redeem-coins Edge Function.
-- Performs balance check and DEBIT atomically using advisory lock to prevent races.
CREATE OR REPLACE FUNCTION public.redeem_coins_atomic(
    p_user_id         UUID,
    p_item_id         TEXT,
    p_idempotency_key TEXT,
    p_ledger_id       UUID
) RETURNS public.coin_ledger AS $$
DECLARE
    v_item         public.redemption_catalog%ROWTYPE;
    v_existing     public.coin_ledger%ROWTYPE;
    v_balance      BIGINT;
    v_new_entry    public.coin_ledger%ROWTYPE;
BEGIN
    -- 1. Load server-controlled catalog item (determines cost)
    SELECT * INTO v_item FROM public.redemption_catalog
    WHERE item_id = p_item_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown or inactive redemption item: %', p_item_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Check idempotency
    SELECT * INTO v_existing FROM public.coin_ledger
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        RETURN v_existing;
    END IF;

    -- 3. Acquire advisory lock keyed by user_id to prevent concurrent redemptions
    --    This prevents two simultaneous redemptions from both seeing sufficient balance.
    PERFORM pg_advisory_xact_lock(hashtext(p_user_id::TEXT));

    -- 4. Calculate current balance inside the lock
    SELECT COALESCE(
        SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE -amount END),
        0
    ) INTO v_balance
    FROM public.coin_ledger
    WHERE user_id = p_user_id;

    -- 5. Validate sufficient balance
    IF v_balance < v_item.cost THEN
        RAISE EXCEPTION 'Insufficient balance: have %, need %', v_balance, v_item.cost
            USING ERRCODE = 'check_violation';
    END IF;

    -- 6. Atomically insert DEBIT record
    INSERT INTO public.coin_ledger (
        id,
        user_id,
        transaction_type,
        amount,
        reason,
        related_entity_id,
        idempotency_key,
        server_verified
    ) VALUES (
        p_ledger_id,
        p_user_id,
        'DEBIT',
        v_item.cost,             -- Server-controlled cost
        'Redeemed: ' || v_item.name_en,
        p_item_id,
        p_idempotency_key,
        TRUE
    )
    RETURNING * INTO v_new_entry;

    RETURN v_new_entry;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 7. ROLE GRANT FUNCTION (SECURITY DEFINER, restricted EXECUTE)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.grant_role_internal(
    p_actor_id   UUID,
    p_target_id  UUID,
    p_role_id    TEXT
) RETURNS VOID AS $$
BEGIN
    -- 1. Validate role exists
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE id = p_role_id) THEN
        RAISE EXCEPTION 'Unknown role: %', p_role_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Verify actor is a platform_admin (re-verified server-side, never trust client)
    IF NOT EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = p_actor_id AND role_id = 'platform_admin'
    ) THEN
        RAISE EXCEPTION 'Actor % does not have platform_admin role', p_actor_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- 3. Grant the role
    INSERT INTO public.user_roles (user_id, role_id, granted_by)
    VALUES (p_target_id, p_role_id, p_actor_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- 4. Write audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        p_actor_id,
        'grant_role',
        'user_roles',
        p_target_id::TEXT,
        jsonb_build_object('role_id', p_role_id)
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 8. RESTRICT EXECUTE PERMISSIONS ON INTERNAL FUNCTIONS
--    These functions must not be directly callable by anon or authenticated roles.
--    They are invoked exclusively by Edge Functions via the service key.
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.claim_reward_internal(UUID, TEXT, TEXT, TEXT, UUID)   FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.redeem_coins_atomic(UUID, TEXT, TEXT, UUID)           FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.grant_role_internal(UUID, UUID, TEXT)                 FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public._verify_attempt_ownership(UUID, UUID)                 FROM PUBLIC;

-- Grant to the role used by Supabase Edge Function runtime (service_role bypasses this
-- via superuser privileges, but explicit grants are best practice for least-privilege)
-- Note: 'supabase_functions_admin' exists in Supabase-managed projects.
-- These grants are no-ops if the role doesn't exist (local dev), which is safe.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.claim_reward_internal(UUID, TEXT, TEXT, TEXT, UUID) TO supabase_functions_admin';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.redeem_coins_atomic(UUID, TEXT, TEXT, UUID) TO supabase_functions_admin';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.grant_role_internal(UUID, UUID, TEXT) TO supabase_functions_admin';
    END IF;
END;
$$;

-- =============================================================================
-- 9. HARDEN COIN LEDGER RLS
--    Block all direct client INSERT operations.
--    Only SECURITY DEFINER functions (called via Edge Functions) may insert rows.
-- =============================================================================

-- Remove any existing INSERT policies on coin_ledger that allow direct client inserts
DROP POLICY IF EXISTS "Users insert own coin ledger" ON public.coin_ledger;

-- Explicit deny for direct INSERT (SECURITY DEFINER functions bypass RLS)
DROP POLICY IF EXISTS "coin_ledger_no_direct_insert" ON public.coin_ledger;
CREATE POLICY "coin_ledger_no_direct_insert"
    ON public.coin_ledger FOR INSERT
    WITH CHECK (FALSE);

-- =============================================================================
-- 10. HARDEN USER_ROLES RLS
--     Block all direct client INSERT/UPDATE/DELETE.
--     Roles are assigned only by handle_new_user trigger (always student)
--     or grant_role_internal SECURITY DEFINER function.
-- =============================================================================

DROP POLICY IF EXISTS "user_roles_no_direct_insert" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_insert"
    ON public.user_roles FOR INSERT
    WITH CHECK (FALSE);

DROP POLICY IF EXISTS "user_roles_no_direct_update" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_update"
    ON public.user_roles FOR UPDATE
    USING (FALSE);

DROP POLICY IF EXISTS "user_roles_no_direct_delete" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_delete"
    ON public.user_roles FOR DELETE
    USING (FALSE);

-- Users may read their own roles
DROP POLICY IF EXISTS "user_roles_read_own" ON public.user_roles;
CREATE POLICY "user_roles_read_own"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id);

-- Platform admins may read all roles (for admin dashboard)
DROP POLICY IF EXISTS "user_roles_admin_read_all" ON public.user_roles;
CREATE POLICY "user_roles_admin_read_all"
    ON public.user_roles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 11. ADMIN WRITE POLICIES FOR CONTENT TABLES
-- =============================================================================

-- Questions: platform_admin can create/update (never delete — use archived status)
DROP POLICY IF EXISTS "questions_admin_write" ON public.questions;
CREATE POLICY "questions_admin_write"
    ON public.questions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Answer choices: platform_admin write
DROP POLICY IF EXISTS "answer_choices_admin_write" ON public.answer_choices;
CREATE POLICY "answer_choices_admin_write"
    ON public.answer_choices FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Explanations: platform_admin write
DROP POLICY IF EXISTS "explanations_admin_write" ON public.explanations;
CREATE POLICY "explanations_admin_write"
    ON public.explanations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Subjects, units, topics: platform_admin write
DROP POLICY IF EXISTS "subjects_admin_write" ON public.subjects;
CREATE POLICY "subjects_admin_write"
    ON public.subjects FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

DROP POLICY IF EXISTS "units_admin_write" ON public.units;
CREATE POLICY "units_admin_write"
    ON public.units FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

DROP POLICY IF EXISTS "topics_admin_write" ON public.topics;
CREATE POLICY "topics_admin_write"
    ON public.topics FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 12. ADD UPDATE POLICY ON attempt_responses
--     Required by sync upsert operations (retry idempotency)
-- =============================================================================

DROP POLICY IF EXISTS "Users update own attempt responses" ON public.attempt_responses;
CREATE POLICY "Users update own attempt responses"
    ON public.attempt_responses FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.attempts a
            WHERE a.id = attempt_responses.attempt_id AND a.user_id = auth.uid()
        )
    );

-- =============================================================================
-- 13. MISSING PERFORMANCE INDEXES
-- =============================================================================

-- Coin ledger idempotency check (very hot path for sync)
CREATE INDEX IF NOT EXISTS idx_coin_ledger_idempotency_key
    ON public.coin_ledger(idempotency_key);

-- Bookmark unique lookup (user + question)
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_question
    ON public.bookmarks(user_id, question_id);

-- Mistake record unique lookup
CREATE INDEX IF NOT EXISTS idx_mistake_records_user_question
    ON public.mistake_records(user_id, question_id);

-- Attempt history (most common query: user's completed attempts ordered by time)
CREATE INDEX IF NOT EXISTS idx_attempts_user_completed_at
    ON public.attempts(user_id, is_completed, start_time DESC);

-- Audit log: time-ordered admin queries
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
    ON public.audit_log(created_at DESC);

-- Content packages: browse by grade + stream
CREATE INDEX IF NOT EXISTS idx_content_packages_grade_stream
    ON public.content_packages(grade, stream, is_published);
-- =============================================================================
-- FidelLearn Database Schema Migration
-- Version: 20260925000000
-- Description: P6 Stage 1 - Multi-Tenant Database, RLS & Security Foundation
--   1. Core Tables: schools, school_memberships, classrooms, 
--      classroom_memberships, teacher_subject_assignments, school_invitations
--   2. Strict Row Level Security (RLS) on all institutional tables
--   3. Authoritative Security Functions: is_platform_admin, is_school_member,
--      is_school_admin, is_teacher_in_school, can_access_student
--   4. Privileged SECURITY DEFINER RPCs for all institutional mutations
--   5. Full Audit Logging into public.audit_log
--   6. Legacy Global Role Deprecation: global teacher/school_admin grant 0 tenant authority
-- =============================================================================

-- =============================================================================
-- 1. SCHOOLS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    display_name TEXT,
    school_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL CHECK (status IN ('active', 'suspended', 'archived')) DEFAULT 'active',
    city TEXT,
    region TEXT,
    timezone TEXT NOT NULL DEFAULT 'Africa/Addis_Ababa',
    logo_url TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_schools_code ON public.schools(school_code);
CREATE INDEX IF NOT EXISTS idx_schools_status ON public.schools(status);

-- =============================================================================
-- 2. SCHOOL MEMBERSHIPS TABLE
--    Enforces: Tenant-scoped authority (student, teacher, school_admin).
--    Uniqueness: Exactly one canonical membership record per (school_id, user_id).
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.school_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'school_admin')),
    status TEXT NOT NULL CHECK (status IN ('invited', 'active', 'inactive', 'removed')) DEFAULT 'active',
    school_student_id TEXT,
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_school_memberships_school_user UNIQUE (school_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_school_memberships_school ON public.school_memberships(school_id, status);
CREATE INDEX IF NOT EXISTS idx_school_memberships_user ON public.school_memberships(user_id, status);
CREATE INDEX IF NOT EXISTS idx_school_memberships_school_role ON public.school_memberships(school_id, role, status);

-- =============================================================================
-- 3. CLASSROOMS TABLE
--    Belongs to exactly one school. Academic year identity (e.g. '2026/27').
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.classrooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 7, 8, 9, 10, 11, 12)),
    stream TEXT CHECK (stream IN ('naturalScience', 'socialScience', 'common', 'natural', 'social')),
    section TEXT,
    academic_year TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'archived')) DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_classrooms_school_year ON public.classrooms(school_id, academic_year);
CREATE INDEX IF NOT EXISTS idx_classrooms_school_status ON public.classrooms(school_id, status);

-- =============================================================================
-- 4. CLASSROOM MEMBERSHIPS TABLE
--    Student or teacher membership in a classroom.
--    Member MUST also have an active membership in the classroom's school.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.classroom_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher')),
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'removed')) DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_classroom_memberships_classroom_user UNIQUE (classroom_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_classroom_memberships_class ON public.classroom_memberships(classroom_id, status);
CREATE INDEX IF NOT EXISTS idx_classroom_memberships_user ON public.classroom_memberships(user_id, status);

-- =============================================================================
-- 5. TEACHER SUBJECT ASSIGNMENTS TABLE
--    Granular teacher subject assignment per classroom.
--    Supports separate Natural/Social variants for math_g12.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.teacher_subject_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    exam_variant TEXT NULL CHECK (exam_variant IN ('naturalScience', 'socialScience', 'shared')),
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'archived')) DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_teacher_assignments_idx 
    ON public.teacher_subject_assignments (teacher_user_id, classroom_id, subject_id, COALESCE(exam_variant, 'shared'));

CREATE INDEX IF NOT EXISTS idx_teacher_assignments_school ON public.teacher_subject_assignments(school_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_teacher ON public.teacher_subject_assignments(teacher_user_id, status);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_class ON public.teacher_subject_assignments(classroom_id, status);

-- =============================================================================
-- 6. SCHOOL INVITATIONS TABLE
--    Token-based invitation for onboarding students, teachers, and school admins.
--    No plaintext secrets stored.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.school_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'school_admin')),
    email_or_identifier TEXT,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'redeemed', 'expired', 'revoked')) DEFAULT 'pending',
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_school_invitations_token ON public.school_invitations(token_hash);
CREATE INDEX IF NOT EXISTS idx_school_invitations_school ON public.school_invitations(school_id, status);

-- =============================================================================
-- 7. SECURITY & AUTHORIZATION HELPER FUNCTIONS
--    All functions are SECURITY DEFINER with search_path = public, pg_temp.
--    Caller identity is ALWAYS derived securely from auth.uid().
-- =============================================================================

-- 7a. is_platform_admin(): checks global platform admin role
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role_id = 'platform_admin'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7b. is_school_member(target_school_id): active member of active school
CREATE OR REPLACE FUNCTION public.is_school_member(target_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_school_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.school_memberships sm
        JOIN public.schools s ON s.id = sm.school_id
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = target_school_id
          AND sm.status = 'active'
          AND s.status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7c. is_school_admin(target_school_id): active school_admin of active school
CREATE OR REPLACE FUNCTION public.is_school_admin(target_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_school_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.school_memberships sm
        JOIN public.schools s ON s.id = sm.school_id
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = target_school_id
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
          AND s.status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7d. is_teacher_in_school(target_school_id): active teacher of active school
CREATE OR REPLACE FUNCTION public.is_teacher_in_school(target_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_school_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.school_memberships sm
        JOIN public.schools s ON s.id = sm.school_id
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = target_school_id
          AND sm.role = 'teacher'
          AND sm.status = 'active'
          AND s.status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7e. can_access_student(target_student_id, target_school_id):
--     Authoritative multi-tenant student data access evaluator.
--     Rules:
--       1. Student accessing own data -> ALLOWED
--       2. Platform Admin -> ALLOWED
--       3. Target student must have active membership in target school
--       4. School Admin of target school -> ALLOWED
--       5. Teacher in target school -> ALLOWED ONLY IF assigned to student's active classroom
--       6. Otherwise -> DENIED
CREATE OR REPLACE FUNCTION public.can_access_student(
    target_student_id UUID,
    target_school_id  UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_caller_id UUID := auth.uid();
BEGIN
    IF v_caller_id IS NULL OR target_student_id IS NULL OR target_school_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 1. Student accessing own data
    IF v_caller_id = target_student_id THEN
        RETURN TRUE;
    END IF;

    -- 2. Platform Admin has global oversight
    IF public.is_platform_admin() THEN
        RETURN TRUE;
    END IF;

    -- Verify target student has active membership in the target school
    IF NOT EXISTS (
        SELECT 1 FROM public.school_memberships sm
        JOIN public.schools s ON s.id = sm.school_id
        WHERE sm.user_id = target_student_id
          AND sm.school_id = target_school_id
          AND sm.status = 'active'
          AND s.status = 'active'
    ) THEN
        RETURN FALSE;
    END IF;

    -- 3. School Admin of that specific school
    IF public.is_school_admin(target_school_id) THEN
        RETURN TRUE;
    END IF;

    -- 4. Teacher in that school: MUST be assigned to student's active classroom
    IF public.is_teacher_in_school(target_school_id) THEN
        RETURN EXISTS (
            SELECT 1
            FROM public.classroom_memberships cm
            JOIN public.teacher_subject_assignments tsa ON tsa.classroom_id = cm.classroom_id
            JOIN public.classrooms c ON c.id = cm.classroom_id
            WHERE cm.user_id = target_student_id
              AND cm.status = 'active'
              AND tsa.teacher_user_id = v_caller_id
              AND tsa.school_id = target_school_id
              AND tsa.status = 'active'
              AND c.status = 'active'
        );
    END IF;

    -- All other callers are denied
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7f. is_classroom_enrolled(target_classroom_id): active enrollment in classroom
CREATE OR REPLACE FUNCTION public.is_classroom_enrolled(target_classroom_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_classroom_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.classroom_memberships
        WHERE classroom_id = target_classroom_id
          AND user_id = auth.uid()
          AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7g. is_classroom_teacher(target_classroom_id): active assigned teacher of classroom
CREATE OR REPLACE FUNCTION public.is_classroom_teacher(target_classroom_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_classroom_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.teacher_subject_assignments
        WHERE classroom_id = target_classroom_id
          AND teacher_user_id = auth.uid()
          AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7h. is_classroom_school_admin(target_classroom_id): active school admin of classroom's school
CREATE OR REPLACE FUNCTION public.is_classroom_school_admin(target_classroom_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_classroom_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.classrooms c
        JOIN public.school_memberships sm ON sm.school_id = c.school_id
        JOIN public.schools s ON s.id = c.school_id
        WHERE c.id = target_classroom_id
          AND sm.user_id = auth.uid()
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
          AND s.status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7i. is_teacher_of_student(target_user_id, target_school_id): active teacher assigned to student's active class
CREATE OR REPLACE FUNCTION public.is_teacher_of_student(target_user_id UUID, target_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF target_user_id IS NULL OR target_school_id IS NULL OR auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.classroom_memberships cm
        JOIN public.teacher_subject_assignments tsa ON tsa.classroom_id = cm.classroom_id
        JOIN public.classrooms c ON c.id = cm.classroom_id
        WHERE cm.user_id = target_user_id
          AND cm.status = 'active'
          AND tsa.teacher_user_id = auth.uid()
          AND tsa.school_id = target_school_id
          AND tsa.status = 'active'
          AND c.status = 'active'
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 8. PRIVILEGED SERVER-SIDE MUTATION RPCS
--    All mutations go through SECURITY DEFINER RPCs to enforce:
--      - Exact tenant boundaries
--      - Referential consistency (e.g. cross-tenant membership validation)
--      - Audit logging into public.audit_log
-- =============================================================================

-- 8a. create_school_internal: Platform Admin only
CREATE OR REPLACE FUNCTION public.create_school_internal(
    p_name         TEXT,
    p_school_code  TEXT,
    p_display_name TEXT DEFAULT NULL,
    p_city         TEXT DEFAULT NULL,
    p_region       TEXT DEFAULT NULL,
    p_timezone     TEXT DEFAULT 'Africa/Addis_Ababa',
    p_logo_url     TEXT DEFAULT NULL
) RETURNS public.schools AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_school    public.schools%ROWTYPE;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    INSERT INTO public.schools (
        name,
        display_name,
        school_code,
        status,
        city,
        region,
        timezone,
        logo_url,
        created_by
    ) VALUES (
        p_name,
        COALESCE(p_display_name, p_name),
        UPPER(TRIM(p_school_code)),
        'active',
        p_city,
        p_region,
        COALESCE(p_timezone, 'Africa/Addis_Ababa'),
        p_logo_url,
        v_caller_id
    ) RETURNING * INTO v_school;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'school_created',
        'schools',
        v_school.id::TEXT,
        jsonb_build_object(
            'school_name', v_school.name,
            'school_code', v_school.school_code,
            'region', v_school.region
        )
    );

    RETURN v_school;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8b. grant_school_membership_internal: Platform Admin or School Admin of target school
CREATE OR REPLACE FUNCTION public.grant_school_membership_internal(
    p_school_id         UUID,
    p_user_id           UUID,
    p_role              TEXT,
    p_school_student_id TEXT DEFAULT NULL
) RETURNS public.school_memberships AS $$
DECLARE
    v_caller_id   UUID := auth.uid();
    v_membership  public.school_memberships%ROWTYPE;
    v_old_role    TEXT;
    v_old_status  TEXT;
BEGIN
    -- Role validity check
    IF p_role NOT IN ('student', 'teacher', 'school_admin') THEN
        RAISE EXCEPTION 'Invalid school membership role: %', p_role
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Caller authorization check: Platform Admin or School Admin of that specific school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to grant membership in school %', v_caller_id, p_school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Verify target user exists in profiles
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Target user % does not exist', p_user_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Check existing membership for audit trail
    SELECT role, status INTO v_old_role, v_old_status
    FROM public.school_memberships
    WHERE school_id = p_school_id AND user_id = p_user_id;

    -- Upsert membership: one canonical record per (school_id, user_id)
    INSERT INTO public.school_memberships (
        school_id,
        user_id,
        role,
        status,
        school_student_id,
        joined_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_user_id,
        p_role,
        'active',
        p_school_student_id,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (school_id, user_id) DO UPDATE SET
        role              = EXCLUDED.role,
        status            = 'active',
        school_student_id = COALESCE(EXCLUDED.school_student_id, public.school_memberships.school_student_id),
        updated_at        = TIMEZONE('utc', NOW())
    RETURNING * INTO v_membership;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        CASE WHEN v_old_role IS NULL THEN 'school_membership_created' ELSE 'school_membership_role_updated' END,
        'school_memberships',
        v_membership.id::TEXT,
        jsonb_build_object(
            'school_id', p_school_id,
            'target_user_id', p_user_id,
            'role', p_role,
            'old_role', v_old_role,
            'old_status', v_old_status,
            'status', 'active'
        )
    );

    RETURN v_membership;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8c. update_school_membership_status_internal: Deactivate or remove membership
CREATE OR REPLACE FUNCTION public.update_school_membership_status_internal(
    p_membership_id UUID,
    p_new_status    TEXT
) RETURNS public.school_memberships AS $$
DECLARE
    v_caller_id  UUID := auth.uid();
    v_membership public.school_memberships%ROWTYPE;
    v_old_status TEXT;
BEGIN
    IF p_new_status NOT IN ('active', 'inactive', 'removed') THEN
        RAISE EXCEPTION 'Invalid membership status: %', p_new_status
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    SELECT * INTO v_membership FROM public.school_memberships WHERE id = p_membership_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Membership % not found', p_membership_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Caller authorization check
    IF NOT (public.is_platform_admin() OR public.is_school_admin(v_membership.school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to update membership in school %', v_caller_id, v_membership.school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    v_old_status := v_membership.status;

    UPDATE public.school_memberships
    SET status = p_new_status, updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_membership_id
    RETURNING * INTO v_membership;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'school_membership_status_updated',
        'school_memberships',
        p_membership_id::TEXT,
        jsonb_build_object(
            'school_id', v_membership.school_id,
            'target_user_id', v_membership.user_id,
            'old_status', v_old_status,
            'new_status', p_new_status
        )
    );

    RETURN v_membership;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8d. create_classroom_internal: School Admin of school or Platform Admin
CREATE OR REPLACE FUNCTION public.create_classroom_internal(
    p_school_id     UUID,
    p_name          TEXT,
    p_grade         INT,
    p_stream        TEXT DEFAULT 'common',
    p_section       TEXT DEFAULT NULL,
    p_academic_year TEXT DEFAULT '2026/27'
) RETURNS public.classrooms AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_classroom public.classrooms%ROWTYPE;
BEGIN
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to create classroom in school %', v_caller_id, p_school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    INSERT INTO public.classrooms (
        school_id,
        name,
        grade,
        stream,
        section,
        academic_year,
        status
    ) VALUES (
        p_school_id,
        p_name,
        p_grade,
        p_stream,
        p_section,
        p_academic_year,
        'active'
    ) RETURNING * INTO v_classroom;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'classroom_created',
        'classrooms',
        v_classroom.id::TEXT,
        jsonb_build_object(
            'school_id', p_school_id,
            'name', p_name,
            'grade', p_grade,
            'stream', p_stream,
            'academic_year', p_academic_year
        )
    );

    RETURN v_classroom;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8e. assign_classroom_member_internal: Enroll student or teacher in classroom
--     CRITICAL INVARIANT: Member MUST have active membership in classroom's school!
CREATE OR REPLACE FUNCTION public.assign_classroom_member_internal(
    p_classroom_id UUID,
    p_user_id      UUID,
    p_role         TEXT
) RETURNS public.classroom_memberships AS $$
DECLARE
    v_caller_id   UUID := auth.uid();
    v_classroom   public.classrooms%ROWTYPE;
    v_cm          public.classroom_memberships%ROWTYPE;
BEGIN
    IF p_role NOT IN ('student', 'teacher') THEN
        RAISE EXCEPTION 'Invalid classroom membership role: %', p_role
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    SELECT * INTO v_classroom FROM public.classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom % not found', p_classroom_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Caller authorization check: Platform Admin or School Admin of the classroom's school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(v_classroom.school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to manage classroom %', v_caller_id, p_classroom_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- CROSS-TENANT INTEGRITY: Verify target user has an active membership in the classroom's school!
    IF NOT EXISTS (
        SELECT 1 FROM public.school_memberships
        WHERE school_id = v_classroom.school_id
          AND user_id = p_user_id
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Target user % does not have an active membership in school %', p_user_id, v_classroom.school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- Upsert classroom membership
    INSERT INTO public.classroom_memberships (
        classroom_id,
        user_id,
        role,
        status,
        updated_at
    ) VALUES (
        p_classroom_id,
        p_user_id,
        p_role,
        'active',
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (classroom_id, user_id) DO UPDATE SET
        role       = EXCLUDED.role,
        status     = 'active',
        updated_at = TIMEZONE('utc', NOW())
    RETURNING * INTO v_cm;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'classroom_member_assigned',
        'classroom_memberships',
        v_cm.id::TEXT,
        jsonb_build_object(
            'school_id', v_classroom.school_id,
            'classroom_id', p_classroom_id,
            'target_user_id', p_user_id,
            'role', p_role
        )
    );

    RETURN v_cm;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8f. assign_teacher_subject_internal: Assign teacher to classroom & subject
--     CRITICAL INVARIANTS:
--       1. Classroom must belong to target school
--       2. Teacher must have an active 'teacher' membership in target school
CREATE OR REPLACE FUNCTION public.assign_teacher_subject_internal(
    p_school_id       UUID,
    p_teacher_user_id UUID,
    p_classroom_id    UUID,
    p_subject_id      TEXT,
    p_exam_variant    TEXT DEFAULT NULL
) RETURNS public.teacher_subject_assignments AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_classroom public.classrooms%ROWTYPE;
    v_tsa       public.teacher_subject_assignments%ROWTYPE;
BEGIN
    -- Caller authorization check: Platform Admin or School Admin of target school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to assign teachers in school %', v_caller_id, p_school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- 1. Verify classroom belongs to target school
    SELECT * INTO v_classroom FROM public.classrooms
    WHERE id = p_classroom_id AND school_id = p_school_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom % does not belong to school %', p_classroom_id, p_school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- 2. Verify teacher has an active teacher membership in target school
    IF NOT EXISTS (
        SELECT 1 FROM public.school_memberships
        WHERE school_id = p_school_id
          AND user_id = p_teacher_user_id
          AND role = 'teacher'
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Teacher % does not have active teacher membership in school %', p_teacher_user_id, p_school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- 3. Verify subject exists
    IF NOT EXISTS (SELECT 1 FROM public.subjects WHERE id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Upsert teacher subject assignment
    INSERT INTO public.teacher_subject_assignments (
        school_id,
        teacher_user_id,
        classroom_id,
        subject_id,
        exam_variant,
        status,
        updated_at
    ) VALUES (
        p_school_id,
        p_teacher_user_id,
        p_classroom_id,
        p_subject_id,
        p_exam_variant,
        'active',
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (teacher_user_id, classroom_id, subject_id, COALESCE(exam_variant, 'shared'))
    DO UPDATE SET
        status     = 'active',
        updated_at = TIMEZONE('utc', NOW())
    RETURNING * INTO v_tsa;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'teacher_subject_assigned',
        'teacher_subject_assignments',
        v_tsa.id::TEXT,
        jsonb_build_object(
            'school_id', p_school_id,
            'teacher_user_id', p_teacher_user_id,
            'classroom_id', p_classroom_id,
            'subject_id', p_subject_id,
            'exam_variant', p_exam_variant
        )
    );

    RETURN v_tsa;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classroom_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_subject_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_invitations ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 9a. schools RLS
-- -----------------------------------------------------------------------------
-- SELECT: active member of school OR platform admin
CREATE POLICY "schools_select_members_or_admin"
    ON public.schools FOR SELECT
    USING (
        public.is_school_member(id) OR public.is_platform_admin()
    );

-- UPDATE: school admin of same school OR platform admin
CREATE POLICY "schools_update_admin_only"
    ON public.schools FOR UPDATE
    USING (
        public.is_school_admin(id) OR public.is_platform_admin()
    );

-- INSERT: direct client insert blocked (use create_school_internal RPC)
CREATE POLICY "schools_no_direct_insert"
    ON public.schools FOR INSERT
    WITH CHECK (FALSE);

-- DELETE: physical delete blocked
CREATE POLICY "schools_no_direct_delete"
    ON public.schools FOR DELETE
    USING (FALSE);

-- -----------------------------------------------------------------------------
-- 9b. school_memberships RLS
-- -----------------------------------------------------------------------------
-- SELECT:
--   - Own membership
--   - School Admin of that school
--   - Platform Admin
--   - Teacher in same school if student is in teacher's assigned classroom
CREATE POLICY "school_memberships_select_authorized"
    ON public.school_memberships FOR SELECT
    USING (
        user_id = auth.uid()
        OR public.is_school_admin(school_id)
        OR public.is_platform_admin()
        OR (
            public.is_teacher_in_school(school_id)
            AND public.is_teacher_of_student(school_memberships.user_id, school_id)
        )
    );

-- INSERT / UPDATE / DELETE: Block direct client modifications
-- All membership modifications must go through grant_school_membership_internal RPC
CREATE POLICY "school_memberships_no_direct_insert"
    ON public.school_memberships FOR INSERT
    WITH CHECK (FALSE);

CREATE POLICY "school_memberships_no_direct_update"
    ON public.school_memberships FOR UPDATE
    USING (FALSE);

CREATE POLICY "school_memberships_no_direct_delete"
    ON public.school_memberships FOR DELETE
    USING (FALSE);

-- -----------------------------------------------------------------------------
-- 9c. classrooms RLS
-- -----------------------------------------------------------------------------
-- SELECT:
--   - Enrolled active students
--   - Assigned active teachers
--   - School Admin of that school
--   - Platform Admin
CREATE POLICY "classrooms_select_authorized"
    ON public.classrooms FOR SELECT
    USING (
        public.is_school_admin(school_id)
        OR public.is_platform_admin()
        OR public.is_classroom_enrolled(classrooms.id)
        OR public.is_classroom_teacher(classrooms.id)
    );

-- UPDATE: School Admin of that school OR Platform Admin
CREATE POLICY "classrooms_update_admin_only"
    ON public.classrooms FOR UPDATE
    USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

-- INSERT / DELETE: Use RPC / Admin only
CREATE POLICY "classrooms_no_direct_insert"
    ON public.classrooms FOR INSERT
    WITH CHECK (FALSE);

CREATE POLICY "classrooms_no_direct_delete"
    ON public.classrooms FOR DELETE
    USING (FALSE);

-- -----------------------------------------------------------------------------
-- 9d. classroom_memberships RLS
-- -----------------------------------------------------------------------------
-- SELECT:
--   - Own enrollment
--   - Assigned teacher for that classroom
--   - School Admin of the classroom's school
--   - Platform Admin
CREATE POLICY "classroom_memberships_select_authorized"
    ON public.classroom_memberships FOR SELECT
    USING (
        user_id = auth.uid()
        OR public.is_platform_admin()
        OR public.is_classroom_school_admin(classroom_memberships.classroom_id)
        OR public.is_classroom_teacher(classroom_memberships.classroom_id)
    );

CREATE POLICY "classroom_memberships_no_direct_insert"
    ON public.classroom_memberships FOR INSERT
    WITH CHECK (FALSE);

CREATE POLICY "classroom_memberships_no_direct_update"
    ON public.classroom_memberships FOR UPDATE
    USING (FALSE);

CREATE POLICY "classroom_memberships_no_direct_delete"
    ON public.classroom_memberships FOR DELETE
    USING (FALSE);

-- -----------------------------------------------------------------------------
-- 9e. teacher_subject_assignments RLS
-- -----------------------------------------------------------------------------
-- SELECT:
--   - The assigned teacher herself
--   - School Admin of that school
--   - Platform Admin
CREATE POLICY "teacher_assignments_select_authorized"
    ON public.teacher_subject_assignments FOR SELECT
    USING (
        teacher_user_id = auth.uid()
        OR public.is_school_admin(school_id)
        OR public.is_platform_admin()
    );

CREATE POLICY "teacher_assignments_no_direct_insert"
    ON public.teacher_subject_assignments FOR INSERT
    WITH CHECK (FALSE);

CREATE POLICY "teacher_assignments_no_direct_update"
    ON public.teacher_subject_assignments FOR UPDATE
    USING (FALSE);

CREATE POLICY "teacher_assignments_no_direct_delete"
    ON public.teacher_subject_assignments FOR DELETE
    USING (FALSE);

-- -----------------------------------------------------------------------------
-- 9f. school_invitations RLS
-- -----------------------------------------------------------------------------
-- SELECT: School Admin of that school OR Platform Admin
CREATE POLICY "school_invitations_select_admin"
    ON public.school_invitations FOR SELECT
    USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

CREATE POLICY "school_invitations_no_direct_insert"
    ON public.school_invitations FOR INSERT
    WITH CHECK (FALSE);

CREATE POLICY "school_invitations_no_direct_update"
    ON public.school_invitations FOR UPDATE
    USING (FALSE);

CREATE POLICY "school_invitations_no_direct_delete"
    ON public.school_invitations FOR DELETE
    USING (FALSE);

-- =============================================================================
-- 10. RESTRICT EXECUTE PERMISSIONS
--     Privileged functions are callable only by authenticated callers through
--     their verified identity, never by anon.
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.create_school_internal(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.grant_school_membership_internal(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.update_school_membership_status_internal(UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.create_classroom_internal(UUID, TEXT, INT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.assign_classroom_member_internal(UUID, UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.assign_teacher_subject_internal(UUID, UUID, UUID, TEXT, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_school_internal(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_school_membership_internal(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_school_membership_status_internal(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_classroom_internal(UUID, TEXT, INT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_classroom_member_internal(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_teacher_subject_internal(UUID, UUID, UUID, TEXT, TEXT) TO authenticated;

GRANT EXECUTE ON FUNCTION public.is_platform_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_school_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_school_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_teacher_in_school(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_student(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_classroom_enrolled(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_classroom_teacher(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_classroom_school_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_teacher_of_student(UUID, UUID) TO authenticated;

-- Grant table access to authenticated role (row access is strictly enforced by RLS policies)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.schools TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.school_memberships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.classrooms TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.classroom_memberships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.teacher_subject_assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.school_invitations TO authenticated;

-- =============================================================================
-- FidelLearn — P7 Teacher Portal Hardened Analytics RPCs
-- Migration: 20260925010000
-- Description: Server-side read models for the Teacher Portal.
--
-- Security & Authorization Standards:
--   1. All functions are SECURITY DEFINER with search_path = public, pg_temp.
--   2. Explicit EXECUTE revocation from PUBLIC and anon; granted only to authenticated.
--   3. auth.uid() identity anchor verified against active school_memberships.
--   4. Active school status verified (status = 'active') — suspended schools blocked.
--   5. Active teacher_subject_assignments verified for (classroom, subject).
--   6. Student enrollment verified for student-level RPCs.
--   7. Server-side bounding on all limit and offset parameters.
--
-- Data Freshness & Attention Policy:
--   - Policy version: teacher_attention_v1
--   - Minimum evidence for accuracy flagging: >= 2 completed attempts.
--   - Missing/insufficient data is NOT treated as 0% accuracy.
--   - Never-practiced students receive 'no_practice_data' (monitoring), not 'no_recent_activity'.
--   - Inactivity ('no_recent_activity') only applies to students with prior practice.
--   - Severity precedence: HIGH > MEDIUM > LOW.
--   - Retake aggregation policy: latest completed attempt per student per exam.
--   - Mastery (P4 fidel_spaced_v1.0) and Readiness are device-local and disclosed as such.
-- =============================================================================

-- Additive P5 exam mode and source type metadata on public.exams
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS exam_mode TEXT DEFAULT 'practice';
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS source_type TEXT DEFAULT 'generatedSimulation';

-- -----------------------------------------------------------------------------
-- Helper: resolve_teacher_class_subject_school
-- Verifies teacher is assigned to this classroom/subject AND school is active.
-- Returns the school_id if authorized, NULL otherwise.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_teacher_class_subject_school(
  p_classroom_id UUID,
  p_subject_id   TEXT
)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT tsa.school_id
  FROM   public.teacher_subject_assignments tsa
  JOIN   public.school_memberships sm
         ON  sm.user_id   = auth.uid()
         AND sm.school_id  = tsa.school_id
         AND sm.role       = 'teacher'
         AND sm.status     = 'active'
  JOIN   public.schools s
         ON  s.id         = tsa.school_id
         AND s.status     = 'active'
  WHERE  tsa.teacher_user_id = auth.uid()
    AND  tsa.classroom_id    = p_classroom_id
    AND  tsa.subject_id      = p_subject_id
    AND  tsa.status          = 'active'
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.resolve_teacher_class_subject_school(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_teacher_class_subject_school(UUID, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 1: get_teacher_assigned_classes
-- Returns all active classroom+subject assignments for the authenticated teacher.
-- Authorization: active teacher membership in the active school.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_assigned_classes(
  p_school_id UUID
)
RETURNS TABLE (
  assignment_id           UUID,
  classroom_id            UUID,
  classroom_name          TEXT,
  classroom_grade         INT,
  classroom_stream        TEXT,
  classroom_section       TEXT,
  classroom_academic_year TEXT,
  classroom_status        TEXT,
  subject_id              TEXT,
  exam_variant            TEXT,
  enrolled_student_count  INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Verify caller is an active teacher in an active school
  IF NOT EXISTS (
    SELECT 1
    FROM   public.school_memberships sm
    JOIN   public.schools s ON s.id = sm.school_id AND s.status = 'active'
    WHERE  sm.user_id   = auth.uid()
      AND  sm.school_id = p_school_id
      AND  sm.role      = 'teacher'
      AND  sm.status    = 'active'
  ) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: caller is not an active teacher in this active school';
  END IF;

  RETURN QUERY
  SELECT
    tsa.id                              AS assignment_id,
    c.id                                AS classroom_id,
    c.name                              AS classroom_name,
    c.grade                             AS classroom_grade,
    c.stream                            AS classroom_stream,
    c.section                           AS classroom_section,
    c.academic_year                     AS classroom_academic_year,
    c.status                            AS classroom_status,
    tsa.subject_id,
    tsa.exam_variant,
    (
      SELECT COUNT(*)::INT
      FROM   public.classroom_memberships cm
      WHERE  cm.classroom_id = c.id
        AND  cm.role         = 'student'
        AND  cm.status       = 'active'
    )                                   AS enrolled_student_count
  FROM   public.teacher_subject_assignments tsa
  JOIN   public.classrooms c ON c.id = tsa.classroom_id
  WHERE  tsa.teacher_user_id = auth.uid()
    AND  tsa.school_id        = p_school_id
    AND  tsa.status           = 'active'
    AND  c.status             = 'active'
  ORDER BY c.name, tsa.subject_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_assigned_classes(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_assigned_classes(UUID) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 2: get_teacher_class_roster
-- Returns a paginated, searchable list of students in an authorized classroom.
-- Bounded: p_limit capped between 1 and 100.
-- Includes last activity and sync freshness metadata.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_class_roster(
  p_classroom_id UUID,
  p_subject_id   TEXT,
  p_limit        INT     DEFAULT 25,
  p_offset       INT     DEFAULT 0,
  p_search       TEXT    DEFAULT NULL
)
RETURNS TABLE (
  user_id                UUID,
  display_name           TEXT,
  school_student_id      TEXT,
  recent_attempt_count   INT,
  recent_avg_percentage  NUMERIC,
  active_mistake_count   INT,
  last_activity_at       TIMESTAMPTZ,
  total_count            BIGINT,
  sync_status            TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_school_id UUID;
  v_safe_limit INT;
  v_safe_offset INT;
BEGIN
  v_safe_limit  := LEAST(GREATEST(COALESCE(p_limit, 25), 1), 100);
  v_safe_offset := GREATEST(COALESCE(p_offset, 0), 0);

  v_school_id := public.resolve_teacher_class_subject_school(p_classroom_id, p_subject_id);
  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: teacher not assigned to this classroom / subject';
  END IF;

  RETURN QUERY
  WITH roster AS (
    SELECT
      p.id                    AS uid,
      p.display_name          AS dname,
      sm.school_student_id    AS sid
    FROM   public.classroom_memberships cm
    JOIN   public.profiles p
           ON  p.id = cm.user_id
    JOIN   public.school_memberships sm
           ON  sm.user_id   = cm.user_id
           AND sm.school_id = v_school_id
    WHERE  cm.classroom_id = p_classroom_id
      AND  cm.status       = 'active'
      AND  (
             p_search IS NULL
             OR p.display_name       ILIKE '%' || p_search || '%'
             OR sm.school_student_id ILIKE '%' || p_search || '%'
           )
  ),
  total_cte AS (
    SELECT COUNT(*) AS cnt FROM roster
  ),
  recent_attempts AS (
    SELECT
      a.user_id,
      COUNT(*)::INT                              AS attempt_count,
      ROUND(AVG(a.percentage)::NUMERIC, 2)       AS avg_pct,
      MAX(a.created_at)                          AS last_at
    FROM   public.attempts a
    JOIN   public.exams e ON e.id = a.exam_id AND e.subject_id = p_subject_id
    WHERE  a.user_id      IN (SELECT uid FROM roster)
      AND  a.is_completed  = TRUE
      AND  a.created_at   >= NOW() - INTERVAL '30 days'
    GROUP BY a.user_id
  ),
  mistake_counts AS (
    SELECT
      mr.user_id,
      COUNT(*)::INT                              AS mc,
      MAX(mr.last_failed_at)                     AS last_m_at
    FROM   public.mistake_records mr
    JOIN   public.questions q ON q.id = mr.question_id AND q.subject_id = p_subject_id
    WHERE  mr.user_id    IN (SELECT uid FROM roster)
      AND  mr.is_mastered = FALSE
    GROUP BY mr.user_id
  )
  SELECT
    r.uid,
    r.dname,
    r.sid,
    COALESCE(ra.attempt_count, 0),
    ra.avg_pct,
    COALESCE(mc.mc, 0),
    ra.last_at,
    t.cnt,
    CASE
      WHEN ra.last_at IS NULL AND mc.last_m_at IS NULL THEN 'unknown'
      WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '2 days' THEN 'fresh'
      WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '7 days' THEN 'moderate'
      WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '14 days' THEN 'stale'
      ELSE 'very_stale'
    END AS sync_status
  FROM   roster r
  CROSS JOIN total_cte t
  LEFT JOIN recent_attempts ra ON ra.user_id = r.uid
  LEFT JOIN mistake_counts mc  ON mc.user_id  = r.uid
  ORDER BY r.dname
  LIMIT  v_safe_limit
  OFFSET v_safe_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_class_roster(UUID, TEXT, INT, INT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_class_roster(UUID, TEXT, INT, INT, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 3: get_teacher_class_weak_topics
-- Returns mistake-based topic weakness indicators for the classroom.
-- Note: Derived from cloud mistake_records, NOT full local P4 mastery.
-- Bounded: p_limit capped between 1 and 50.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_class_weak_topics(
  p_classroom_id UUID,
  p_subject_id   TEXT,
  p_limit        INT DEFAULT 10
)
RETURNS TABLE (
  topic_id               TEXT,
  topic_name_en          TEXT,
  unit_id                TEXT,
  unit_name_en           TEXT,
  affected_student_count INT,
  active_mistake_count   INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_school_id UUID;
  v_safe_limit INT;
BEGIN
  v_safe_limit := LEAST(GREATEST(COALESCE(p_limit, 10), 1), 50);

  v_school_id := public.resolve_teacher_class_subject_school(p_classroom_id, p_subject_id);
  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: teacher not assigned to this classroom / subject';
  END IF;

  RETURN QUERY
  WITH classroom_students AS (
    SELECT cm.user_id AS student_uid
    FROM   public.classroom_memberships cm
    WHERE  cm.classroom_id = p_classroom_id AND cm.status = 'active'
  ),
  topic_problems AS (
    SELECT
      q.topic_id,
      COUNT(DISTINCT mr.user_id)::INT  AS affected,
      COUNT(*)::INT                    AS active_mistakes
    FROM   public.mistake_records mr
    JOIN   public.questions q
           ON q.id = mr.question_id AND q.subject_id = p_subject_id
    WHERE  mr.user_id    IN (SELECT cs.student_uid FROM classroom_students cs)
      AND  mr.is_mastered = FALSE
    GROUP BY q.topic_id
    HAVING COUNT(DISTINCT mr.user_id) >= 1
  )
  SELECT
    t.id            AS topic_id,
    t.title_en      AS topic_name_en,
    u.id            AS unit_id,
    u.title_en      AS unit_name_en,
    tp.affected     AS affected_student_count,
    tp.active_mistakes
  FROM   topic_problems tp
  JOIN   public.topics t ON t.id = tp.topic_id
  JOIN   public.units  u ON u.id = t.unit_id
  ORDER BY tp.affected DESC, tp.active_mistakes DESC
  LIMIT v_safe_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_class_weak_topics(UUID, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_class_weak_topics(UUID, TEXT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 4: get_teacher_class_exam_summary
-- Returns comparable assessment summaries with explicit retake deduplication.
-- Retake Policy: Evaluates the LATEST completed attempt per student per exam.
-- Preserves P5 provenance: exam_mode, source_type, and exam_type.
-- Bounded: p_limit capped between 1 and 25.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_class_exam_summary(
  p_classroom_id UUID,
  p_subject_id   TEXT,
  p_limit        INT DEFAULT 5
)
RETURNS TABLE (
  exam_id           UUID,
  exam_title        TEXT,
  exam_type         TEXT,
  exam_mode         TEXT,
  source_type       TEXT,
  total_questions   INT,
  participant_count INT,
  enrolled_count    INT,
  avg_percentage    NUMERIC,
  median_percentage NUMERIC,
  not_submitted     INT,
  exam_created_at   TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_school_id UUID;
  v_safe_limit INT;
BEGIN
  v_safe_limit := LEAST(GREATEST(COALESCE(p_limit, 5), 1), 25);

  v_school_id := public.resolve_teacher_class_subject_school(p_classroom_id, p_subject_id);
  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: teacher not assigned to this classroom / subject';
  END IF;

  RETURN QUERY
  WITH classroom_students AS (
    SELECT cm.user_id AS student_uid
    FROM   public.classroom_memberships cm
    WHERE  cm.classroom_id = p_classroom_id AND cm.status = 'active'
  ),
  enrolled AS (
    SELECT COUNT(*) AS cnt FROM classroom_students
  ),
  -- Retake Policy: Select LATEST completed attempt per student per exam
  ranked_attempts AS (
    SELECT
      a.exam_id      AS target_exam_id,
      a.user_id      AS attempt_user_id,
      a.percentage   AS attempt_pct,
      a.created_at   AS attempt_at,
      ROW_NUMBER() OVER (
        PARTITION BY a.exam_id, a.user_id
        ORDER BY a.created_at DESC
      ) AS rn
    FROM   public.attempts a
    JOIN   public.exams e
           ON e.id = a.exam_id AND e.subject_id = p_subject_id
    WHERE  a.user_id     IN (SELECT cs.student_uid FROM classroom_students cs)
      AND  a.is_completed = TRUE
  ),
  latest_student_attempts AS (
    SELECT
      ra.target_exam_id,
      ra.attempt_user_id,
      ra.attempt_pct,
      ra.attempt_at
    FROM   ranked_attempts ra
    WHERE  ra.rn = 1
  ),
  recent_exam_ids AS (
    SELECT   lsa.target_exam_id
    FROM     latest_student_attempts lsa
    GROUP BY lsa.target_exam_id
    ORDER BY MAX(lsa.attempt_at) DESC
    LIMIT    v_safe_limit
  ),
  exam_stats AS (
    SELECT
      lsa.target_exam_id,
      COUNT(DISTINCT lsa.attempt_user_id)::INT                                  AS participants,
      AVG(lsa.attempt_pct)                                                      AS avg_pct,
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lsa.attempt_pct)              AS median_pct,
      MAX(lsa.attempt_at)                                                       AS last_submitted_at
    FROM   latest_student_attempts lsa
    WHERE  lsa.target_exam_id IN (SELECT rei.target_exam_id FROM recent_exam_ids rei)
    GROUP BY lsa.target_exam_id
  )
  SELECT
    e.id                                                         AS exam_id,
    e.title                                                      AS exam_title,
    e.exam_type,
    COALESCE(e.exam_mode, 'practice')                            AS exam_mode,
    COALESCE(e.source_type, 'generatedSimulation')               AS source_type,
    e.total_questions,
    COALESCE(es.participants, 0)                                 AS participant_count,
    en.cnt::INT                                                  AS enrolled_count,
    ROUND(COALESCE(es.avg_pct,    0)::NUMERIC, 2)                 AS avg_percentage,
    ROUND(COALESCE(es.median_pct, 0)::NUMERIC, 2)                 AS median_percentage,
    GREATEST(0, en.cnt::INT - COALESCE(es.participants, 0))      AS not_submitted,
    COALESCE(es.last_submitted_at, e.created_at)                 AS exam_created_at
  FROM   recent_exam_ids rei
  JOIN   public.exams e ON e.id = rei.target_exam_id
  CROSS JOIN enrolled en
  LEFT JOIN exam_stats es ON es.target_exam_id = e.id
  ORDER BY COALESCE(es.last_submitted_at, e.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_class_exam_summary(UUID, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_class_exam_summary(UUID, TEXT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 5: get_teacher_attention_students
-- Deterministic Attention Engine Policy: teacher_attention_v1
--
-- Evidence & Severity Principles:
--   1. Minimum evidence for accuracy: >= 2 completed attempts in past 30 days.
--      If < 2 attempts, accuracy is NOT used to trigger severity.
--   2. Never-practiced students (0 attempts) receive 'no_practice_data' (LOW/monitor).
--      They are NEVER marked HIGH or MEDIUM due to lack of attempts.
--   3. Inactivity ('no_recent_activity') ONLY applies to students with >= 1 prior attempts.
--   4. Severity Precedence: HIGH > MEDIUM > LOW.
--   5. Deduplicated array of transparent, machine-readable reason codes.
--   6. Returns last_synced_at and sync_freshness metadata.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_attention_students(
  p_classroom_id UUID,
  p_subject_id   TEXT,
  p_limit        INT DEFAULT 20,
  p_offset       INT DEFAULT 0
)
RETURNS TABLE (
  user_id                    UUID,
  display_name               TEXT,
  school_student_id          TEXT,
  recent_accuracy_percentage NUMERIC,
  active_mistake_count       INT,
  recent_attempt_count       INT,
  last_activity_at           TIMESTAMPTZ,
  last_synced_at             TIMESTAMPTZ,
  sync_freshness             TEXT,
  severity                   TEXT,
  reason_codes               TEXT[],
  total_count                BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_school_id UUID;
  v_safe_limit INT;
  v_safe_offset INT;
BEGIN
  v_safe_limit  := LEAST(GREATEST(COALESCE(p_limit, 20), 1), 100);
  v_safe_offset := GREATEST(COALESCE(p_offset, 0), 0);

  v_school_id := public.resolve_teacher_class_subject_school(p_classroom_id, p_subject_id);
  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: teacher not assigned to this classroom / subject';
  END IF;

  RETURN QUERY
  WITH classroom_students AS (
    SELECT
      cm.user_id           AS student_uid,
      p.display_name       AS student_name,
      sm.school_student_id AS student_sid
    FROM   public.classroom_memberships cm
    JOIN   public.profiles p         ON p.id   = cm.user_id
    JOIN   public.school_memberships sm
           ON  sm.user_id   = cm.user_id
           AND sm.school_id = v_school_id
    WHERE  cm.classroom_id = p_classroom_id
      AND  cm.status       = 'active'
  ),
  recent_attempts AS (
    SELECT
      a.user_id                   AS attempt_uid,
      COUNT(*)::INT               AS attempt_count,
      ROUND(AVG(a.percentage)::NUMERIC, 2) AS avg_pct,
      MAX(a.created_at)           AS last_at
    FROM   public.attempts a
    JOIN   public.exams e ON e.id = a.exam_id AND e.subject_id = p_subject_id
    WHERE  a.user_id      IN (SELECT cs.student_uid FROM classroom_students cs)
      AND  a.is_completed  = TRUE
      AND  a.created_at   >= NOW() - INTERVAL '30 days'
    GROUP BY a.user_id
  ),
  mistake_counts AS (
    SELECT
      mr.user_id             AS mistake_uid,
      COUNT(*)::INT          AS mc,
      MAX(mr.last_failed_at) AS last_m_at
    FROM   public.mistake_records mr
    JOIN   public.questions q ON q.id = mr.question_id AND q.subject_id = p_subject_id
    WHERE  mr.user_id    IN (SELECT cs.student_uid FROM classroom_students cs)
      AND  mr.is_mastered = FALSE
    GROUP BY mr.user_id
  ),
  scored AS (
    SELECT
      cs.student_uid                                AS user_id,
      cs.student_name                               AS display_name,
      cs.student_sid                                AS school_student_id,
      ra.avg_pct                                    AS recent_accuracy,
      COALESCE(mc.mc, 0)::INT                       AS mistakes,
      COALESCE(ra.attempt_count, 0)::INT            AS attempts,
      ra.last_at,
      GREATEST(ra.last_at, mc.last_m_at)            AS synced_at,
      -- Freshness evaluation
      CASE
        WHEN ra.last_at IS NULL AND mc.last_m_at IS NULL THEN 'unknown'
        WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '2 days' THEN 'fresh'
        WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '7 days' THEN 'moderate'
        WHEN GREATEST(ra.last_at, mc.last_m_at) >= NOW() - INTERVAL '14 days' THEN 'stale'
        ELSE 'very_stale'
      END AS freshness,
      -- Deterministic Severity Precedence: HIGH > MEDIUM > LOW
      CASE
        -- HIGH SEVERITY
        WHEN COALESCE(mc.mc, 0) >= 5
             OR (COALESCE(ra.attempt_count, 0) >= 2 AND ra.avg_pct < 50)
          THEN 'high'
        -- MEDIUM SEVERITY
        WHEN COALESCE(mc.mc, 0) >= 3
             OR (COALESCE(ra.attempt_count, 0) >= 2 AND ra.avg_pct < 70)
             OR (COALESCE(ra.attempt_count, 0) >= 1 AND ra.last_at < NOW() - INTERVAL '14 days')
          THEN 'medium'
        -- LOW SEVERITY (Monitor)
        WHEN COALESCE(mc.mc, 0) >= 1
             OR (COALESCE(ra.attempt_count, 0) >= 1 AND ra.last_at < NOW() - INTERVAL '7 days')
             OR (COALESCE(ra.attempt_count, 0) = 0)
          THEN 'low'
        ELSE NULL
      END AS severity,
      -- Deduplicated Explainable Reason Codes
      ARRAY_REMOVE(ARRAY[
        -- High mistake burden
        CASE WHEN COALESCE(mc.mc, 0) >= 5
          THEN 'high_mistake_count' END,
        -- Elevated mistake burden
        CASE WHEN COALESCE(mc.mc, 0) >= 3 AND COALESCE(mc.mc, 0) < 5
          THEN 'elevated_mistake_count' END,
        -- Moderate mistake burden
        CASE WHEN COALESCE(mc.mc, 0) >= 1 AND COALESCE(mc.mc, 0) < 3
          THEN 'active_mistakes_present' END,
        -- Low accuracy (only with minimum evidence of >= 2 attempts)
        CASE WHEN COALESCE(ra.attempt_count, 0) >= 2 AND ra.avg_pct < 50
          THEN 'low_recent_accuracy' END,
        -- Borderline accuracy (only with minimum evidence of >= 2 attempts)
        CASE WHEN COALESCE(ra.attempt_count, 0) >= 2 AND ra.avg_pct >= 50 AND ra.avg_pct < 70
          THEN 'borderline_accuracy' END,
        -- Prolonged inactivity (only for students with prior practice)
        CASE WHEN COALESCE(ra.attempt_count, 0) >= 1 AND ra.last_at < NOW() - INTERVAL '14 days'
          THEN 'no_recent_activity' END,
        -- Overdue practice (only for students with prior practice)
        CASE WHEN COALESCE(ra.attempt_count, 0) >= 1 AND ra.last_at >= NOW() - INTERVAL '14 days' AND ra.last_at < NOW() - INTERVAL '7 days'
          THEN 'overdue_practice' END,
        -- Never practiced
        CASE WHEN COALESCE(ra.attempt_count, 0) = 0
          THEN 'no_practice_data' END
      ], NULL) AS reason_codes
    FROM   classroom_students cs
    LEFT JOIN recent_attempts ra ON ra.attempt_uid = cs.student_uid
    LEFT JOIN mistake_counts  mc ON mc.mistake_uid = cs.student_uid
  ),
  flagged AS (
    SELECT s.* FROM scored s WHERE s.severity IS NOT NULL
  ),
  total_cte AS (
    SELECT COUNT(*) AS cnt FROM flagged
  )
  SELECT
    f.user_id,
    f.display_name,
    f.school_student_id,
    f.recent_accuracy,
    f.mistakes,
    f.attempts,
    f.last_at,
    f.synced_at,
    f.freshness,
    f.severity,
    f.reason_codes,
    t.cnt
  FROM   flagged f
  CROSS JOIN total_cte t
  ORDER BY
    CASE f.severity WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
    f.recent_accuracy NULLS LAST,
    f.mistakes DESC
  LIMIT  v_safe_limit
  OFFSET v_safe_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_attention_students(UUID, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_attention_students(UUID, TEXT, INT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 6: get_teacher_student_summary
-- Returns detailed academic summary for a single authorized student.
-- Enforces:
--   1. Caller is assigned to (classroom_id, subject_id)
--   2. Student is actively enrolled in classroom_id
--   3. Excludes all private data (phone, email, password, coin ledger).
--   4. Uses stored finalized P5 attempts (no dynamic rescoring).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_student_summary(
  p_student_id   UUID,
  p_classroom_id UUID,
  p_subject_id   TEXT
)
RETURNS TABLE (
  user_id                     UUID,
  display_name                TEXT,
  school_student_id           TEXT,
  total_attempts              INT,
  recent_avg_percentage       NUMERIC,
  overall_accuracy_percentage NUMERIC,
  last_activity_at            TIMESTAMPTZ,
  last_synced_at              TIMESTAMPTZ,
  sync_freshness              TEXT,
  total_mistakes              INT,
  mastered_mistakes           INT,
  recent_exams                JSONB,
  weak_topics                 JSONB,
  mastery_availability_note   TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_school_id UUID;
BEGIN
  v_school_id := public.resolve_teacher_class_subject_school(p_classroom_id, p_subject_id);
  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: teacher not assigned to this classroom / subject';
  END IF;

  -- Verify student is actively enrolled in this classroom
  IF NOT EXISTS (
    SELECT 1
    FROM   public.classroom_memberships cm
    WHERE  cm.user_id      = p_student_id
      AND  cm.classroom_id = p_classroom_id
      AND  cm.status       = 'active'
  ) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: student not enrolled in this classroom';
  END IF;

  RETURN QUERY
  WITH student_info AS (
    SELECT
      p.id,
      p.display_name,
      sm.school_student_id
    FROM   public.profiles p
    JOIN   public.school_memberships sm
           ON  sm.user_id   = p.id
           AND sm.school_id = v_school_id
    WHERE  p.id = p_student_id
  ),
  all_subject_attempts AS (
    SELECT
      a.exam_id,
      a.percentage,
      a.created_at,
      e.title,
      e.exam_type,
      COALESCE(e.exam_mode, 'practice')              AS exam_mode,
      COALESCE(e.source_type, 'generatedSimulation') AS source_type,
      e.total_questions
    FROM   public.attempts a
    JOIN   public.exams e ON e.id = a.exam_id AND e.subject_id = p_subject_id
    WHERE  a.user_id      = p_student_id
      AND  a.is_completed  = TRUE
  ),
  recent_exams_json AS (
    SELECT jsonb_agg(
      jsonb_build_object(
        'exam_id',        exam_id::TEXT,
        'exam_title',     title,
        'exam_type',      exam_type,
        'exam_mode',      exam_mode,
        'source_type',    source_type,
        'total_questions', total_questions,
        'percentage',     percentage,
        'completed_at',   created_at
      )
      ORDER BY created_at DESC
    ) AS js
    FROM (SELECT * FROM all_subject_attempts ORDER BY created_at DESC LIMIT 5) r
  ),
  mistake_summary AS (
    SELECT
      COUNT(*)::INT                                           AS total_m,
      SUM(CASE WHEN mr.is_mastered THEN 1 ELSE 0 END)::INT   AS mastered_m,
      MAX(mr.last_failed_at)                                  AS last_m_at
    FROM   public.mistake_records mr
    JOIN   public.questions q ON q.id = mr.question_id AND q.subject_id = p_subject_id
    WHERE  mr.user_id = p_student_id
  ),
  weak_topics_json AS (
    SELECT jsonb_agg(
      jsonb_build_object(
        'topic_id',      t.id,
        'topic_name',    t.title_en,
        'unit_name',     u.title_en,
        'mistake_count', mc
      )
      ORDER BY mc DESC
    ) AS js
    FROM (
      SELECT q.topic_id, COUNT(*)::INT AS mc
      FROM   public.mistake_records mr
      JOIN   public.questions q ON q.id = mr.question_id AND q.subject_id = p_subject_id
      WHERE  mr.user_id     = p_student_id
        AND  mr.is_mastered  = FALSE
      GROUP BY q.topic_id
      ORDER BY mc DESC
      LIMIT 5
    ) wt
    JOIN public.topics t ON t.id = wt.topic_id
    JOIN public.units  u ON u.id = t.unit_id
  )
  SELECT
    si.id,
    si.display_name,
    si.school_student_id,
    COUNT(asa.exam_id)::INT                                                        AS total_attempts,
    ROUND(AVG(CASE WHEN asa.created_at >= NOW() - INTERVAL '30 days'
                   THEN asa.percentage END)::NUMERIC, 2)                           AS recent_avg,
    ROUND(AVG(asa.percentage)::NUMERIC, 2)                                         AS overall_accuracy,
    MAX(asa.created_at)                                                            AS last_activity,
    GREATEST(MAX(asa.created_at), ms.last_m_at)                                    AS last_synced_at,
    CASE
      WHEN MAX(asa.created_at) IS NULL AND ms.last_m_at IS NULL THEN 'unknown'
      WHEN GREATEST(MAX(asa.created_at), ms.last_m_at) >= NOW() - INTERVAL '2 days' THEN 'fresh'
      WHEN GREATEST(MAX(asa.created_at), ms.last_m_at) >= NOW() - INTERVAL '7 days' THEN 'moderate'
      WHEN GREATEST(MAX(asa.created_at), ms.last_m_at) >= NOW() - INTERVAL '14 days' THEN 'stale'
      ELSE 'very_stale'
    END AS sync_freshness,
    COALESCE(ms.total_m,   0)::INT,
    COALESCE(ms.mastered_m, 0)::INT,
    COALESCE(re.js, '[]'::JSONB)                                                   AS recent_exams,
    COALESCE(wt.js, '[]'::JSONB)                                                   AS weak_topics,
    'Mastery data (P4 fidel_spaced_v1.0) and national exam readiness are device-local to the student phone. '
    'Institutional analytics reflect cloud-synced attempts and mistake records only.'::TEXT AS mastery_availability_note
  FROM      student_info       si
  LEFT JOIN all_subject_attempts asa  ON TRUE
  LEFT JOIN mistake_summary      ms   ON TRUE
  LEFT JOIN recent_exams_json    re   ON TRUE
  LEFT JOIN weak_topics_json     wt   ON TRUE
  GROUP BY
    si.id, si.display_name, si.school_student_id,
    ms.total_m, ms.mastered_m, ms.last_m_at, re.js, wt.js;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_student_summary(UUID, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_student_summary(UUID, UUID, TEXT) TO authenticated;


-- =============================================================================
-- Indexes: support teacher analytics query patterns
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_mistake_records_user_mastered
  ON public.mistake_records(user_id, is_mastered);

CREATE INDEX IF NOT EXISTS idx_attempts_completed_at
  ON public.attempts(user_id, is_completed, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_classroom_memberships_class_status
  ON public.classroom_memberships(classroom_id, status);

-- =============================================================================
-- End of Hardened P7 Teacher Portal Migration
-- =============================================================================
-- =============================================================================
-- FidelLearn — P8 School Leadership Dashboard Hardened Analytics RPCs
-- Migration: 20260925020000
-- Description: Server-side read models for School Leadership (Principals, 
--              Academic Directors, Vice Principals, School Admins).
--
-- Security & Authorization Standards:
--   1. All functions are SECURITY DEFINER with search_path = public, pg_temp.
--   2. Explicit EXECUTE revocation from PUBLIC and anon; granted only to authenticated.
--   3. Caller must have active school_admin membership in the target school OR
--      be a platform_admin.
--   4. Active school status verified (status = 'active') — suspended schools blocked.
--   5. Server-side bounding on all limit and offset parameters.
--   6. Academic year scoping on all classroom-derived metrics.
--   7. Retake Policy: Evaluates the LATEST completed attempt per student per exam.
--   8. Natural and Social Science streams are cleanly isolated.
--   9. Mathematics variants (Natural vs Social) are strictly distinguished.
--  10. P4 Mastery and Canonical Readiness remain device-local and are NOT fabricated.
--  11. Data freshness distribution is explicitly calculated.
--  12. Teacher assignment coverage is reported neutrally without teacher scoring.
-- =============================================================================

-- Ensure canonical exam_variant column on exams and questions
ALTER TABLE public.exams 
  ADD COLUMN IF NOT EXISTS exam_variant TEXT CHECK (exam_variant IN ('naturalScience', 'socialScience', 'shared'));

ALTER TABLE public.questions 
  ADD COLUMN IF NOT EXISTS exam_variant TEXT CHECK (exam_variant IN ('naturalScience', 'socialScience', 'shared'));

-- Targeted composite indexes for performant leadership aggregation
CREATE INDEX IF NOT EXISTS idx_classrooms_school_year_status 
  ON public.classrooms(school_id, academic_year, status);

CREATE INDEX IF NOT EXISTS idx_attempts_exam_completed_created 
  ON public.attempts(exam_id, is_completed, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mistake_records_user_unmastered 
  ON public.mistake_records(user_id, is_mastered);


-- -----------------------------------------------------------------------------
-- Helper: resolve_school_admin_authority
-- Verifies caller is an active school_admin of the target active school,
-- or is a platform admin.
-- Returns TRUE if authorized, FALSE otherwise.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_school_admin_authority(
  p_school_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_school_id IS NULL OR auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Platform admin has global support oversight
  IF public.is_platform_admin() THEN
    RETURN TRUE;
  END IF;

  -- Active school admin in active school
  RETURN EXISTS (
    SELECT 1
    FROM   public.school_memberships sm
    JOIN   public.schools s ON s.id = sm.school_id
    WHERE  sm.user_id   = auth.uid()
      AND  sm.school_id = p_school_id
      AND  sm.role      = 'school_admin'
      AND  sm.status    = 'active'
      AND  s.status     = 'active'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_school_admin_authority(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_school_admin_authority(UUID) TO authenticated;


-- -----------------------------------------------------------------------------
-- Helper: resolve_default_academic_year
-- Resolves the most recent active academic year for a school if not specified.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_default_academic_year(
  p_school_id      UUID,
  p_academic_year  TEXT
)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(
    NULLIF(TRIM(p_academic_year), ''),
    (
      SELECT c.academic_year
      FROM   public.classrooms c
      WHERE  c.school_id = p_school_id AND c.status = 'active'
      ORDER BY c.created_at DESC
      LIMIT 1
    ),
    '2026/27'
  );
$$;

REVOKE ALL ON FUNCTION public.resolve_default_academic_year(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_default_academic_year(UUID, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 1: get_school_leadership_summary
-- Executive KPI overview for School Leadership Home.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_leadership_summary(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL
)
RETURNS TABLE (
  school_id                     UUID,
  school_name                   TEXT,
  academic_year                 TEXT,
  total_active_students         INT,
  natural_stream_students       INT,
  social_stream_students        INT,
  total_active_teachers         INT,
  total_active_classrooms       INT,
  recent_simulation_count       INT,
  recent_simulation_avg_pct     NUMERIC,
  recent_simulation_median_pct  NUMERIC,
  simulation_participation_rate NUMERIC,
  unique_students_needing_help  INT,
  high_severity_student_count   INT,
  stale_sync_student_count      INT,
  top_weak_subject_name         TEXT,
  top_weak_subject_mistakes     INT,
  teacher_assignment_coverage   NUMERIC,
  unassigned_subject_slots      INT,
  fresh_data_coverage_rate      NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_total_students INT := 0;
  v_nat_students INT := 0;
  v_soc_students INT := 0;
  v_total_teachers INT := 0;
  v_total_classrooms INT := 0;
  v_sim_count INT := 0;
  v_sim_avg NUMERIC := 0.0;
  v_sim_med NUMERIC := 0.0;
  v_sim_part_rate NUMERIC := 0.0;
  v_need_help INT := 0;
  v_high_sev INT := 0;
  v_stale_count INT := 0;
  v_weak_sub_name TEXT := NULL;
  v_weak_sub_mistakes INT := 0;
  v_coverage_rate NUMERIC := 0.0;
  v_unassigned_slots INT := 0;
  v_fresh_rate NUMERIC := 0.0;
  v_school_name TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);

  SELECT s.name INTO v_school_name
  FROM   public.schools s
  WHERE  s.id = p_school_id;

  -- 1. Active Classroom & Student Headcounts
  SELECT
    COUNT(DISTINCT c.id)::INT,
    COUNT(DISTINCT cm.user_id)::INT,
    COUNT(DISTINCT CASE WHEN c.stream IN ('naturalScience', 'natural') THEN cm.user_id END)::INT,
    COUNT(DISTINCT CASE WHEN c.stream IN ('socialScience', 'social') THEN cm.user_id END)::INT
  INTO
    v_total_classrooms,
    v_total_students,
    v_nat_students,
    v_soc_students
  FROM public.classrooms c
  LEFT JOIN public.classroom_memberships cm 
         ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
  WHERE c.school_id = p_school_id
    AND c.academic_year = v_year
    AND c.status = 'active';

  -- 2. Active Teachers
  SELECT COUNT(DISTINCT sm.user_id)::INT
  INTO   v_total_teachers
  FROM   public.school_memberships sm
  WHERE  sm.school_id = p_school_id
    AND  sm.role      = 'teacher'
    AND  sm.status    = 'active';

  -- 3. Simulation Performance & Participation (Last 60 Days, National Simulations)
  WITH enrolled_students AS (
    SELECT DISTINCT cm.user_id AS uid
    FROM   public.classroom_memberships cm
    JOIN   public.classrooms c ON c.id = cm.classroom_id
    WHERE  c.school_id     = p_school_id
      AND  c.academic_year = v_year
      AND  c.status        = 'active'
      AND  cm.status       = 'active'
  ),
  ranked_sim_attempts AS (
    SELECT
      a.exam_id,
      a.user_id,
      a.percentage,
      ROW_NUMBER() OVER (PARTITION BY a.exam_id, a.user_id ORDER BY a.created_at DESC) AS rn
    FROM public.attempts a
    JOIN public.exams e ON e.id = a.exam_id
    WHERE a.user_id IN (SELECT uid FROM enrolled_students)
      AND a.is_completed = TRUE
      AND a.created_at >= NOW() - INTERVAL '60 days'
      AND (e.exam_mode = 'nationalSimulation' OR e.source_type = 'generatedSimulation' OR e.exam_type = 'mock_full')
  ),
  latest_sims AS (
    SELECT exam_id, user_id, percentage
    FROM ranked_sim_attempts
    WHERE rn = 1
  )
  SELECT
    COUNT(DISTINCT exam_id)::INT,
    COALESCE(ROUND(AVG(percentage)::NUMERIC, 2), 0.0),
    COALESCE(ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY percentage)::NUMERIC, 2), 0.0),
    CASE 
      WHEN v_total_students > 0 THEN 
        ROUND((COUNT(DISTINCT user_id)::NUMERIC / v_total_students::NUMERIC), 2)
      ELSE 0.0 
    END
  INTO
    v_sim_count,
    v_sim_avg,
    v_sim_med,
    v_sim_part_rate
  FROM latest_sims;

  -- 4. Support Population & Freshness (P7-compatible rules evaluated school-wide)
  WITH enrolled_students AS (
    SELECT DISTINCT cm.user_id AS uid
    FROM   public.classroom_memberships cm
    JOIN   public.classrooms c ON c.id = cm.classroom_id
    WHERE  c.school_id     = p_school_id
      AND  c.academic_year = v_year
      AND  c.status        = 'active'
      AND  cm.status       = 'active'
  ),
  student_activity AS (
    SELECT
      es.uid,
      COUNT(DISTINCT a.id)::INT AS attempts_count,
      ROUND(AVG(a.percentage)::NUMERIC, 2) AS avg_pct,
      MAX(a.created_at) AS last_att_at,
      COUNT(DISTINCT CASE WHEN mr.is_mastered = FALSE THEN mr.id END)::INT AS active_mistakes,
      MAX(mr.last_failed_at) AS last_mis_at
    FROM enrolled_students es
    LEFT JOIN public.attempts a 
           ON a.user_id = es.uid AND a.is_completed = TRUE AND a.created_at >= NOW() - INTERVAL '30 days'
    LEFT JOIN public.mistake_records mr 
           ON mr.user_id = es.uid
    GROUP BY es.uid
  ),
  student_scored AS (
    SELECT
      uid,
      active_mistakes,
      attempts_count,
      avg_pct,
      GREATEST(last_att_at, last_mis_at) AS last_synced,
      CASE
        WHEN active_mistakes >= 5 OR (attempts_count >= 2 AND avg_pct < 50) THEN 'high'
        WHEN active_mistakes >= 3 OR (attempts_count >= 2 AND avg_pct < 70) 
             OR (attempts_count >= 1 AND last_att_at < NOW() - INTERVAL '14 days') THEN 'medium'
        WHEN active_mistakes >= 1 
             OR (attempts_count >= 1 AND last_att_at < NOW() - INTERVAL '7 days')
             OR (attempts_count = 0) THEN 'low'
        ELSE 'none'
      END AS severity,
      CASE
        WHEN last_att_at IS NULL AND last_mis_at IS NULL THEN 'unknown'
        WHEN GREATEST(last_att_at, last_mis_at) >= NOW() - INTERVAL '2 days' THEN 'fresh'
        WHEN GREATEST(last_att_at, last_mis_at) >= NOW() - INTERVAL '7 days' THEN 'moderate'
        WHEN GREATEST(last_att_at, last_mis_at) >= NOW() - INTERVAL '14 days' THEN 'stale'
        ELSE 'very_stale'
      END AS freshness
    FROM student_activity
  )
  SELECT
    COUNT(CASE WHEN severity IN ('high', 'medium', 'low') THEN 1 END)::INT,
    COUNT(CASE WHEN severity = 'high' THEN 1 END)::INT,
    COUNT(CASE WHEN freshness IN ('stale', 'very_stale', 'unknown') THEN 1 END)::INT,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(CASE WHEN freshness IN ('fresh', 'moderate') THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC), 2)
      ELSE 0.0 
    END
  INTO
    v_need_help,
    v_high_sev,
    v_stale_count,
    v_fresh_rate
  FROM student_scored;

  -- 5. Top Weak Subject by Active Mistake Concentration
  WITH enrolled_students AS (
    SELECT DISTINCT cm.user_id AS uid
    FROM   public.classroom_memberships cm
    JOIN   public.classrooms c ON c.id = cm.classroom_id
    WHERE  c.school_id     = p_school_id
      AND  c.academic_year = v_year
      AND  c.status        = 'active'
      AND  cm.status       = 'active'
  )
  SELECT
    CASE
      WHEN q.subject_id = 'math_g12' AND q.exam_variant = 'naturalScience' THEN 'Mathematics — Natural Science'
      WHEN q.subject_id = 'math_g12' AND q.exam_variant = 'socialScience' THEN 'Mathematics — Social Science'
      ELSE COALESCE(s.name_en, q.subject_id)
    END,
    COUNT(*)::INT
  INTO
    v_weak_sub_name,
    v_weak_sub_mistakes
  FROM public.mistake_records mr
  JOIN public.questions q ON q.id = mr.question_id
  LEFT JOIN public.subjects s ON s.id = q.subject_id
  WHERE mr.user_id IN (SELECT uid FROM enrolled_students)
    AND mr.is_mastered = FALSE
    AND (
      q.subject_id != 'math_g12'
      OR (
        (q.exam_variant = 'naturalScience' AND (q.stream IS NULL OR q.stream NOT IN ('social', 'socialScience')))
        OR
        (q.exam_variant = 'socialScience' AND (q.stream IS NULL OR q.stream NOT IN ('natural', 'naturalScience')))
      )
    )
  GROUP BY 
    CASE
      WHEN q.subject_id = 'math_g12' AND q.exam_variant = 'naturalScience' THEN 'Mathematics — Natural Science'
      WHEN q.subject_id = 'math_g12' AND q.exam_variant = 'socialScience' THEN 'Mathematics — Social Science'
      ELSE COALESCE(s.name_en, q.subject_id)
    END
  ORDER BY COUNT(*) DESC
  LIMIT 1;

  -- 6. Teacher Coverage (Classrooms x Required Subjects vs Assigned)
  -- For each active classroom, count distinct subjects assigned in teacher_subject_assignments
  WITH class_subjects AS (
    SELECT
      c.id AS classroom_id,
      COUNT(DISTINCT tsa.subject_id)::INT AS assigned_subs
    FROM public.classrooms c
    LEFT JOIN public.teacher_subject_assignments tsa 
           ON tsa.classroom_id = c.id AND tsa.status = 'active'
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
    GROUP BY c.id
  )
  SELECT
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(CASE WHEN assigned_subs >= 5 THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC), 2)
      ELSE 0.0 
    END,
    COUNT(CASE WHEN assigned_subs = 0 THEN 1 END)::INT
  INTO
    v_coverage_rate,
    v_unassigned_slots
  FROM class_subjects;

  RETURN QUERY SELECT
    p_school_id,
    COALESCE(v_school_name, 'School'),
    v_year,
    v_total_students,
    v_nat_students,
    v_soc_students,
    v_total_teachers,
    v_total_classrooms,
    v_sim_count,
    v_sim_avg,
    v_sim_med,
    v_sim_part_rate,
    v_need_help,
    v_high_sev,
    v_stale_count,
    v_weak_sub_name,
    v_weak_sub_mistakes,
    v_coverage_rate,
    v_unassigned_slots,
    v_fresh_rate;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_leadership_summary(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_leadership_summary(UUID, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 2: get_school_stream_summary
-- Compares Natural Science vs Social Science cohorts.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_stream_summary(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL
)
RETURNS TABLE (
  stream                        TEXT,
  stream_label                  TEXT,
  enrolled_students             INT,
  active_classrooms             INT,
  recent_simulation_avg_pct     NUMERIC,
  recent_simulation_median_pct  NUMERIC,
  simulation_participation_rate NUMERIC,
  active_mistake_count          INT,
  fresh_data_coverage_rate      NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);

  RETURN QUERY
  WITH stream_cohorts AS (
    SELECT
      CASE 
        WHEN c.stream IN ('naturalScience', 'natural') THEN 'naturalScience'
        WHEN c.stream IN ('socialScience', 'social') THEN 'socialScience'
        ELSE 'common'
      END AS normalized_stream,
      c.id AS classroom_id,
      cm.user_id AS student_uid
    FROM public.classrooms c
    LEFT JOIN public.classroom_memberships cm 
           ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
  ),
  cohort_base AS (
    SELECT
      normalized_stream,
      COUNT(DISTINCT classroom_id)::INT AS cls_count,
      COUNT(DISTINCT student_uid)::INT   AS stu_count
    FROM stream_cohorts
    WHERE normalized_stream IN ('naturalScience', 'socialScience')
    GROUP BY normalized_stream
  ),
  ranked_attempts AS (
    SELECT
      sc.normalized_stream,
      a.exam_id,
      a.user_id,
      a.percentage,
      ROW_NUMBER() OVER (PARTITION BY a.exam_id, a.user_id ORDER BY a.created_at DESC) AS rn
    FROM stream_cohorts sc
    JOIN public.attempts a ON a.user_id = sc.student_uid
    JOIN public.exams e ON e.id = a.exam_id
    WHERE a.is_completed = TRUE
      AND a.created_at >= NOW() - INTERVAL '60 days'
      AND (e.exam_mode = 'nationalSimulation' OR e.source_type = 'generatedSimulation' OR e.exam_type = 'mock_full')
      AND (
        e.subject_id != 'math_g12'
        OR (
          (sc.normalized_stream = 'naturalScience' AND e.exam_variant = 'naturalScience' AND (e.stream IS NULL OR e.stream NOT IN ('social', 'socialScience')))
          OR
          (sc.normalized_stream = 'socialScience' AND e.exam_variant = 'socialScience' AND (e.stream IS NULL OR e.stream NOT IN ('natural', 'naturalScience')))
        )
      )
  ),
  stream_sims AS (
    SELECT
      ra.normalized_stream,
      ROUND(AVG(ra.percentage)::NUMERIC, 2) AS avg_pct,
      ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY ra.percentage)::NUMERIC, 2) AS med_pct,
      COUNT(DISTINCT ra.user_id)::INT AS participants
    FROM ranked_attempts ra
    WHERE ra.rn = 1
    GROUP BY ra.normalized_stream
  ),
  stream_mistakes AS (
    SELECT
      sc.normalized_stream,
      COUNT(*)::INT AS mistake_count
    FROM stream_cohorts sc
    JOIN public.mistake_records mr ON mr.user_id = sc.student_uid
    JOIN public.questions q ON q.id = mr.question_id
    WHERE mr.is_mastered = FALSE
      AND (
        q.subject_id != 'math_g12'
        OR (
          (sc.normalized_stream = 'naturalScience' AND q.exam_variant = 'naturalScience' AND (q.stream IS NULL OR q.stream NOT IN ('social', 'socialScience')))
          OR
          (sc.normalized_stream = 'socialScience' AND q.exam_variant = 'socialScience' AND (q.stream IS NULL OR q.stream NOT IN ('natural', 'naturalScience')))
        )
      )
    GROUP BY sc.normalized_stream
  ),
  stream_freshness AS (
    SELECT
      sc.normalized_stream,
      COUNT(DISTINCT CASE 
        WHEN GREATEST(a.created_at, mr.last_failed_at) >= NOW() - INTERVAL '7 days' 
        THEN sc.student_uid 
      END)::INT AS fresh_count
    FROM stream_cohorts sc
    LEFT JOIN public.attempts a ON a.user_id = sc.student_uid AND a.is_completed = TRUE
    LEFT JOIN public.mistake_records mr ON mr.user_id = sc.student_uid
    GROUP BY sc.normalized_stream
  )
  SELECT
    cb.normalized_stream,
    CASE 
      WHEN cb.normalized_stream = 'naturalScience' THEN 'Natural Science'
      ELSE 'Social Science'
    END,
    cb.stu_count,
    cb.cls_count,
    COALESCE(ss.avg_pct, 0.0),
    COALESCE(ss.med_pct, 0.0),
    CASE 
      WHEN cb.stu_count > 0 THEN ROUND((COALESCE(ss.participants, 0)::NUMERIC / cb.stu_count::NUMERIC), 2)
      ELSE 0.0 
    END,
    COALESCE(sm.mistake_count, 0),
    CASE 
      WHEN cb.stu_count > 0 THEN ROUND((COALESCE(sf.fresh_count, 0)::NUMERIC / cb.stu_count::NUMERIC), 2)
      ELSE 0.0 
    END
  FROM cohort_base cb
  LEFT JOIN stream_sims ss ON ss.normalized_stream = cb.normalized_stream
  LEFT JOIN stream_mistakes sm ON sm.normalized_stream = cb.normalized_stream
  LEFT JOIN stream_freshness sf ON sf.normalized_stream = cb.normalized_stream
  ORDER BY cb.normalized_stream;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_stream_summary(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_stream_summary(UUID, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 3: get_school_subject_summary
-- Subject-level performance & mistake metrics across the school.
-- Distinguishes Mathematics variants (Natural vs Social).
-- Optional p_stream filter ('naturalScience' or 'socialScience').
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_subject_summary(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL,
  p_stream        TEXT DEFAULT NULL
)
RETURNS TABLE (
  subject_id               TEXT,
  subject_name             TEXT,
  exam_variant             TEXT,
  display_name             TEXT,
  stream                   TEXT,
  enrolled_student_count   INT,
  attempt_count            INT,
  participant_count        INT,
  participation_rate       NUMERIC,
  avg_percentage           NUMERIC,
  median_percentage        NUMERIC,
  active_mistake_count     INT,
  affected_student_count   INT,
  teacher_assigned_count   INT,
  has_teacher_coverage     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_norm_stream TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
  v_norm_stream := NULLIF(TRIM(p_stream), '');

  RETURN QUERY
  WITH school_students AS (
    SELECT DISTINCT
      cm.user_id AS student_uid,
      CASE 
        WHEN c.stream IN ('naturalScience', 'natural') THEN 'naturalScience'
        WHEN c.stream IN ('socialScience', 'social') THEN 'socialScience'
        ELSE 'common'
      END AS student_stream,
      c.id AS classroom_id
    FROM public.classrooms c
    JOIN public.classroom_memberships cm 
      ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
      AND (v_norm_stream IS NULL OR c.stream = v_norm_stream)
  ),
  base_subjects AS (
    SELECT
      s.id AS sub_id,
      s.name_en AS sub_name,
      s.stream AS sub_stream,
      CASE
        WHEN s.id IN ('physics_g12', 'chemistry_g12', 'biology_g12') THEN 'naturalScience'
        WHEN s.id IN ('history_g12', 'geography_g12', 'economics_g12') THEN 'socialScience'
        WHEN s.id = 'civics_g12' THEN 'supplementary'
        ELSE 'common'
      END AS effective_stream
    FROM public.subjects s
    WHERE s.grade = 12
      AND s.id != 'civics_g12' -- Civics is supplementary, excluded from primary ESSLCE tracks
  ),
  target_subjects AS (
    -- Non-math primary subjects
    SELECT
      bs.sub_id,
      bs.sub_name,
      bs.sub_stream,
      bs.effective_stream,
      NULL::TEXT AS var_code
    FROM base_subjects bs
    WHERE bs.sub_id != 'math_g12'
      AND (
        v_norm_stream IS NULL 
        OR bs.effective_stream = 'common'
        OR bs.effective_stream = v_norm_stream
      )
    UNION ALL
    -- Canonical math_g12 projected for Natural Science variant
    SELECT
      bs.sub_id,
      bs.sub_name,
      'natural' AS sub_stream,
      'naturalScience' AS effective_stream,
      'naturalScience'::TEXT AS var_code
    FROM base_subjects bs
    WHERE bs.sub_id = 'math_g12'
      AND (v_norm_stream IS NULL OR v_norm_stream = 'naturalScience')
    UNION ALL
    -- Canonical math_g12 projected for Social Science variant
    SELECT
      bs.sub_id,
      bs.sub_name,
      'social' AS sub_stream,
      'socialScience' AS effective_stream,
      'socialScience'::TEXT AS var_code
    FROM base_subjects bs
    WHERE bs.sub_id = 'math_g12'
      AND (v_norm_stream IS NULL OR v_norm_stream = 'socialScience')
  ),
  ranked_attempts AS (
    SELECT
      e.subject_id AS att_subject_id,
      CASE
        WHEN e.subject_id = 'math_g12' THEN
          CASE
            WHEN e.exam_variant = 'naturalScience' AND e.stream IN ('social', 'socialScience') THEN NULL
            WHEN e.exam_variant = 'socialScience' AND e.stream IN ('natural', 'naturalScience') THEN NULL
            WHEN e.exam_variant = 'naturalScience' THEN 'naturalScience'
            WHEN e.exam_variant = 'socialScience' THEN 'socialScience'
            ELSE NULL
          END
        ELSE
          CASE
            WHEN e.stream IN ('naturalScience', 'natural') THEN 'naturalScience'
            WHEN e.stream IN ('socialScience', 'social') THEN 'socialScience'
            ELSE NULL
          END
      END AS att_variant,
      a.user_id,
      a.percentage,
      ROW_NUMBER() OVER (PARTITION BY a.exam_id, a.user_id ORDER BY a.created_at DESC) AS rn
    FROM public.attempts a
    JOIN public.exams e ON e.id = a.exam_id
    WHERE a.user_id IN (SELECT student_uid FROM school_students)
      AND a.is_completed = TRUE
      AND a.created_at >= NOW() - INTERVAL '60 days'
  ),
  subject_attempts AS (
    SELECT
      ra.att_subject_id,
      ra.att_variant,
      COUNT(*)::INT AS total_attempts,
      COUNT(DISTINCT ra.user_id)::INT AS unique_participants,
      ROUND(AVG(ra.percentage)::NUMERIC, 2) AS avg_pct,
      ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY ra.percentage)::NUMERIC, 2) AS med_pct
    FROM ranked_attempts ra
    WHERE ra.rn = 1
    GROUP BY ra.att_subject_id, ra.att_variant
  ),
  subject_mistakes AS (
    SELECT
      q.subject_id AS mis_subject_id,
      CASE
        WHEN q.subject_id = 'math_g12' THEN
          CASE
            WHEN q.exam_variant = 'naturalScience' AND q.stream IN ('social', 'socialScience') THEN NULL
            WHEN q.exam_variant = 'socialScience' AND q.stream IN ('natural', 'naturalScience') THEN NULL
            WHEN q.exam_variant = 'naturalScience' THEN 'naturalScience'
            WHEN q.exam_variant = 'socialScience' THEN 'socialScience'
            ELSE NULL
          END
        ELSE
          CASE
            WHEN q.stream IN ('naturalScience', 'natural') THEN 'naturalScience'
            WHEN q.stream IN ('socialScience', 'social') THEN 'socialScience'
            ELSE NULL
          END
      END AS mis_variant,
      COUNT(*)::INT AS total_mistakes,
      COUNT(DISTINCT mr.user_id)::INT AS affected_students
    FROM public.mistake_records mr
    JOIN public.questions q ON q.id = mr.question_id
    WHERE mr.user_id IN (SELECT student_uid FROM school_students)
      AND mr.is_mastered = FALSE
    GROUP BY q.subject_id,
      CASE
        WHEN q.subject_id = 'math_g12' THEN
          CASE
            WHEN q.exam_variant = 'naturalScience' AND q.stream IN ('social', 'socialScience') THEN NULL
            WHEN q.exam_variant = 'socialScience' AND q.stream IN ('natural', 'naturalScience') THEN NULL
            WHEN q.exam_variant = 'naturalScience' THEN 'naturalScience'
            WHEN q.exam_variant = 'socialScience' THEN 'socialScience'
            ELSE NULL
          END
        ELSE
          CASE
            WHEN q.stream IN ('naturalScience', 'natural') THEN 'naturalScience'
            WHEN q.stream IN ('socialScience', 'social') THEN 'socialScience'
            ELSE NULL
          END
      END
  ),
  subject_coverage AS (
    SELECT
      tsa.subject_id AS cov_subject_id,
      CASE
        WHEN tsa.subject_id = 'math_g12' THEN
          CASE
            WHEN tsa.exam_variant = 'naturalScience' THEN 'naturalScience'
            WHEN tsa.exam_variant = 'socialScience' THEN 'socialScience'
            ELSE NULL
          END
        ELSE tsa.exam_variant
      END AS cov_variant,
      COUNT(DISTINCT tsa.teacher_user_id)::INT AS assigned_teachers
    FROM public.teacher_subject_assignments tsa
    JOIN public.classrooms c ON c.id = tsa.classroom_id
    WHERE tsa.school_id = p_school_id
      AND c.academic_year = v_year
      AND tsa.status = 'active'
      AND c.status = 'active'
    GROUP BY tsa.subject_id,
      CASE
        WHEN tsa.subject_id = 'math_g12' THEN
          CASE
            WHEN tsa.exam_variant = 'naturalScience' THEN 'naturalScience'
            WHEN tsa.exam_variant = 'socialScience' THEN 'socialScience'
            ELSE NULL
          END
        ELSE tsa.exam_variant
      END
  ),
  eligible_population AS (
    SELECT
      ts.sub_id,
      ts.var_code,
      COUNT(DISTINCT ss.student_uid)::INT AS eligible_count
    FROM target_subjects ts
    JOIN school_students ss 
      ON (ts.effective_stream = 'common' OR ts.effective_stream = ss.student_stream)
    GROUP BY ts.sub_id, ts.var_code
  )
  SELECT
    ts.sub_id,
    ts.sub_name,
    ts.var_code,
    CASE 
      WHEN ts.sub_id = 'math_g12' AND ts.var_code = 'naturalScience' THEN 'Mathematics — Natural Science'
      WHEN ts.sub_id = 'math_g12' AND ts.var_code = 'socialScience' THEN 'Mathematics — Social Science'
      WHEN ts.var_code = 'naturalScience' THEN ts.sub_name || ' (Natural)'
      WHEN ts.var_code = 'socialScience' THEN ts.sub_name || ' (Social)'
      ELSE ts.sub_name
    END,
    ts.effective_stream,
    COALESCE(ep.eligible_count, 0),
    COALESCE(sa.total_attempts, 0),
    COALESCE(sa.unique_participants, 0),
    CASE 
      WHEN COALESCE(ep.eligible_count, 0) > 0 THEN 
        ROUND((COALESCE(sa.unique_participants, 0)::NUMERIC / ep.eligible_count::NUMERIC), 2)
      ELSE 0.0 
    END,
    COALESCE(sa.avg_pct, 0.0),
    COALESCE(sa.med_pct, 0.0),
    COALESCE(sm.total_mistakes, 0),
    COALESCE(sm.affected_students, 0),
    COALESCE(sc.assigned_teachers, 0),
    COALESCE(sc.assigned_teachers, 0) > 0
  FROM target_subjects ts
  LEFT JOIN eligible_population ep 
         ON ep.sub_id = ts.sub_id 
        AND (ts.var_code IS NULL OR ep.var_code = ts.var_code)
  LEFT JOIN subject_attempts sa    
         ON sa.att_subject_id = ts.sub_id 
        AND (ts.var_code IS NULL OR sa.att_variant = ts.var_code)
  LEFT JOIN subject_mistakes sm    
         ON sm.mis_subject_id = ts.sub_id 
        AND (ts.var_code IS NULL OR sm.mis_variant = ts.var_code)
  LEFT JOIN subject_coverage sc    
         ON sc.cov_subject_id = ts.sub_id 
        AND (ts.var_code IS NULL OR sc.cov_variant = ts.var_code)
  ORDER BY 
    CASE WHEN ts.sub_id = 'math_g12' THEN 1 ELSE 2 END,
    COALESCE(sm.total_mistakes, 0) DESC,
    ts.sub_name;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_subject_summary(UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_subject_summary(UUID, TEXT, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 4: get_school_class_summary
-- Section-level comparative metrics.
-- Non-punitive: No "Best/Worst" labels.
-- Optional filters: p_stream, p_subject_id.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_class_summary(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL,
  p_stream        TEXT DEFAULT NULL,
  p_subject_id    TEXT DEFAULT NULL
)
RETURNS TABLE (
  classroom_id              UUID,
  classroom_name            TEXT,
  grade                     INT,
  stream                    TEXT,
  section                   TEXT,
  enrolled_students         INT,
  recent_attempt_count      INT,
  participant_count         INT,
  participation_rate        NUMERIC,
  avg_percentage            NUMERIC,
  median_percentage         NUMERIC,
  active_mistake_count      INT,
  assigned_teacher_count    INT,
  fresh_data_coverage_rate  NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_norm_stream TEXT;
  v_norm_sub TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
  v_norm_stream := NULLIF(TRIM(p_stream), '');
  v_norm_sub := NULLIF(TRIM(p_subject_id), '');

  RETURN QUERY
  WITH class_base AS (
    SELECT
      c.id AS cid,
      c.name AS cname,
      c.grade AS cgrade,
      c.stream AS cstream,
      c.section AS csection,
      COUNT(DISTINCT cm.user_id)::INT AS stu_count
    FROM public.classrooms c
    LEFT JOIN public.classroom_memberships cm 
           ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
      AND (v_norm_stream IS NULL OR c.stream = v_norm_stream)
    GROUP BY c.id, c.name, c.grade, c.stream, c.section
  ),
  class_students AS (
    SELECT
      cb.cid,
      cm.user_id AS student_uid
    FROM class_base cb
    JOIN public.classroom_memberships cm 
      ON cm.classroom_id = cb.cid AND cm.status = 'active' AND cm.role = 'student'
  ),
  ranked_attempts AS (
    SELECT
      cs.cid,
      a.exam_id,
      a.user_id,
      a.percentage,
      ROW_NUMBER() OVER (PARTITION BY a.exam_id, a.user_id ORDER BY a.created_at DESC) AS rn
    FROM class_students cs
    JOIN class_base cb ON cb.cid = cs.cid
    JOIN public.attempts a ON a.user_id = cs.student_uid
    JOIN public.exams e ON e.id = a.exam_id
    WHERE a.is_completed = TRUE
      AND a.created_at >= NOW() - INTERVAL '60 days'
      AND (
        v_norm_sub IS NULL
        OR (
          e.subject_id = v_norm_sub
          AND (
            v_norm_sub != 'math_g12'
            OR (
              (cb.cstream IN ('naturalScience', 'natural') AND e.exam_variant = 'naturalScience' AND (e.stream IS NULL OR e.stream NOT IN ('social', 'socialScience')))
              OR
              (cb.cstream IN ('socialScience', 'social') AND e.exam_variant = 'socialScience' AND (e.stream IS NULL OR e.stream NOT IN ('natural', 'naturalScience')))
            )
          )
        )
      )
  ),
  class_attempts AS (
    SELECT
      ra.cid,
      COUNT(*)::INT AS total_attempts,
      COUNT(DISTINCT ra.user_id)::INT AS unique_participants,
      ROUND(AVG(ra.percentage)::NUMERIC, 2) AS avg_pct,
      ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY ra.percentage)::NUMERIC, 2) AS med_pct
    FROM ranked_attempts ra
    WHERE ra.rn = 1
    GROUP BY ra.cid
  ),
  class_mistakes AS (
    SELECT
      cs.cid,
      COUNT(*)::INT AS total_mistakes
    FROM class_students cs
    JOIN class_base cb ON cb.cid = cs.cid
    JOIN public.mistake_records mr ON mr.user_id = cs.student_uid
    JOIN public.questions q ON q.id = mr.question_id
    WHERE mr.is_mastered = FALSE
      AND (
        v_norm_sub IS NULL
        OR (
          q.subject_id = v_norm_sub
          AND (
            v_norm_sub != 'math_g12'
            OR (
              (cb.cstream IN ('naturalScience', 'natural') AND q.exam_variant = 'naturalScience' AND (q.stream IS NULL OR q.stream NOT IN ('social', 'socialScience')))
              OR
              (cb.cstream IN ('socialScience', 'social') AND q.exam_variant = 'socialScience' AND (q.stream IS NULL OR q.stream NOT IN ('natural', 'naturalScience')))
            )
          )
        )
      )
    GROUP BY cs.cid
  ),
  class_teachers AS (
    SELECT
      cb.cid,
      COUNT(DISTINCT tsa.teacher_user_id)::INT AS teacher_count
    FROM class_base cb
    LEFT JOIN public.teacher_subject_assignments tsa 
           ON tsa.classroom_id = cb.cid 
          AND tsa.status = 'active'
          AND (
            v_norm_sub IS NULL 
            OR (
              tsa.subject_id = v_norm_sub
              AND (
                v_norm_sub != 'math_g12'
                OR (
                  (cb.cstream IN ('naturalScience', 'natural') AND tsa.exam_variant = 'naturalScience')
                  OR
                  (cb.cstream IN ('socialScience', 'social') AND tsa.exam_variant = 'socialScience')
                )
              )
            )
          )
    GROUP BY cb.cid
  ),
  class_freshness AS (
    SELECT
      cs.cid,
      COUNT(DISTINCT CASE 
        WHEN GREATEST(a.created_at, mr.last_failed_at) >= NOW() - INTERVAL '7 days' 
        THEN cs.student_uid 
      END)::INT AS fresh_count
    FROM class_students cs
    LEFT JOIN public.attempts a ON a.user_id = cs.student_uid AND a.is_completed = TRUE
    LEFT JOIN public.mistake_records mr ON mr.user_id = cs.student_uid
    GROUP BY cs.cid
  )
  SELECT
    cb.cid,
    cb.cname,
    cb.cgrade,
    COALESCE(cb.cstream, 'common'),
    COALESCE(cb.csection, ''),
    cb.stu_count,
    COALESCE(ca.total_attempts, 0),
    COALESCE(ca.unique_participants, 0),
    CASE 
      WHEN cb.stu_count > 0 THEN 
        ROUND((COALESCE(ca.unique_participants, 0)::NUMERIC / cb.stu_count::NUMERIC), 2)
      ELSE 0.0 
    END,
    COALESCE(ca.avg_pct, 0.0),
    COALESCE(ca.med_pct, 0.0),
    COALESCE(cm.total_mistakes, 0),
    COALESCE(ct.teacher_count, 0),
    CASE 
      WHEN cb.stu_count > 0 THEN 
        ROUND((COALESCE(cf.fresh_count, 0)::NUMERIC / cb.stu_count::NUMERIC), 2)
      ELSE 0.0 
    END
  FROM class_base cb
  LEFT JOIN class_attempts ca  ON ca.cid = cb.cid
  LEFT JOIN class_mistakes cm  ON cm.cid = cb.cid
  LEFT JOIN class_teachers ct  ON ct.cid = cb.cid
  LEFT JOIN class_freshness cf ON cf.cid = cb.cid
  ORDER BY cb.cname;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_class_summary(UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_class_summary(UUID, TEXT, TEXT, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 5: get_school_systemic_weak_topics
-- Identifies top weak topics across the school derived from mistake records.
-- Bounded: p_limit capped between 1 and 50.
-- Optional filter: p_subject_id.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_systemic_weak_topics(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL,
  p_subject_id    TEXT DEFAULT NULL,
  p_limit         INT DEFAULT 10
)
RETURNS TABLE (
  topic_id               TEXT,
  topic_name_en          TEXT,
  unit_id                TEXT,
  unit_name_en           TEXT,
  subject_id             TEXT,
  subject_name           TEXT,
  affected_student_count INT,
  active_mistake_count   INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_safe_limit INT;
  v_norm_sub TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
  v_safe_limit := LEAST(GREATEST(COALESCE(p_limit, 10), 1), 50);
  v_norm_sub := NULLIF(TRIM(p_subject_id), '');

  RETURN QUERY
  WITH school_students AS (
    SELECT DISTINCT cm.user_id AS uid
    FROM   public.classroom_memberships cm
    JOIN   public.classrooms c ON c.id = cm.classroom_id
    WHERE  c.school_id     = p_school_id
      AND  c.academic_year = v_year
      AND  c.status        = 'active'
      AND  cm.status       = 'active'
      AND  cm.role         = 'student'
  ),
  topic_errors AS (
    SELECT
      q.topic_id,
      q.subject_id,
      COUNT(DISTINCT mr.user_id)::INT AS affected_students,
      COUNT(*)::INT                   AS mistakes
    FROM public.mistake_records mr
    JOIN public.questions q ON q.id = mr.question_id
    WHERE mr.user_id IN (SELECT uid FROM school_students)
      AND mr.is_mastered = FALSE
      AND (v_norm_sub IS NULL OR q.subject_id = v_norm_sub)
      AND (
        q.subject_id != 'math_g12'
        OR (
          (q.exam_variant = 'naturalScience' AND (q.stream IS NULL OR q.stream NOT IN ('social', 'socialScience')))
          OR
          (q.exam_variant = 'socialScience' AND (q.stream IS NULL OR q.stream NOT IN ('natural', 'naturalScience')))
        )
      )
    GROUP BY q.topic_id, q.subject_id
    HAVING COUNT(DISTINCT mr.user_id) >= 1
  )
  SELECT
    t.id         AS topic_id,
    t.title_en   AS topic_name_en,
    u.id         AS unit_id,
    u.title_en   AS unit_name_en,
    s.id         AS subject_id,
    s.name_en    AS subject_name,
    te.affected_students,
    te.mistakes
  FROM topic_errors te
  JOIN public.topics t   ON t.id = te.topic_id
  JOIN public.units  u   ON u.id = t.unit_id
  LEFT JOIN public.subjects s ON s.id = te.subject_id
  ORDER BY te.affected_students DESC, te.mistakes DESC
  LIMIT v_safe_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_systemic_weak_topics(UUID, TEXT, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_systemic_weak_topics(UUID, TEXT, TEXT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 6: get_school_support_population
-- Lists students flagged for academic support school-wide with reason codes.
-- Bounded pagination: p_limit capped between 1 and 100.
-- Optional severity filter: 'high', 'medium', 'low'.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_support_population(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL,
  p_severity      TEXT DEFAULT NULL,
  p_limit         INT DEFAULT 25,
  p_offset        INT DEFAULT 0
)
RETURNS TABLE (
  user_id                    UUID,
  display_name               TEXT,
  school_student_id          TEXT,
  classroom_name             TEXT,
  stream                     TEXT,
  recent_accuracy_percentage NUMERIC,
  active_mistake_count       INT,
  recent_attempt_count       INT,
  last_activity_at           TIMESTAMPTZ,
  last_synced_at             TIMESTAMPTZ,
  sync_freshness             TEXT,
  severity                   TEXT,
  reason_codes               TEXT[],
  total_count                BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_safe_limit INT;
  v_safe_offset INT;
  v_norm_sev TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
  v_safe_limit  := LEAST(GREATEST(COALESCE(p_limit, 25), 1), 100);
  v_safe_offset := GREATEST(COALESCE(p_offset, 0), 0);
  v_norm_sev    := NULLIF(LOWER(TRIM(p_severity)), '');

  RETURN QUERY
  WITH school_students AS (
    SELECT
      cm.user_id           AS student_uid,
      p.display_name       AS student_name,
      sm.school_student_id AS student_sid,
      c.name               AS cname,
      c.stream             AS cstream
    FROM public.classrooms c
    JOIN public.classroom_memberships cm 
      ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
    JOIN public.profiles p ON p.id = cm.user_id
    JOIN public.school_memberships sm 
      ON sm.user_id = cm.user_id AND sm.school_id = p_school_id
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
  ),
  recent_attempts AS (
    SELECT
      a.user_id,
      COUNT(*)::INT AS att_count,
      ROUND(AVG(a.percentage)::NUMERIC, 2) AS avg_pct,
      MAX(a.created_at) AS last_att
    FROM public.attempts a
    WHERE a.user_id IN (SELECT student_uid FROM school_students)
      AND a.is_completed = TRUE
      AND a.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY a.user_id
  ),
  mistake_counts AS (
    SELECT
      mr.user_id,
      COUNT(*)::INT AS mc,
      MAX(mr.last_failed_at) AS last_m
    FROM public.mistake_records mr
    WHERE mr.user_id IN (SELECT student_uid FROM school_students)
      AND mr.is_mastered = FALSE
    GROUP BY mr.user_id
  ),
  scored_population AS (
    SELECT
      ss.student_uid                                AS user_id,
      ss.student_name                               AS display_name,
      ss.student_sid                                AS school_student_id,
      ss.cname                                      AS classroom_name,
      COALESCE(ss.cstream, 'common')                AS stream,
      ra.avg_pct                                    AS recent_accuracy,
      COALESCE(mc.mc, 0)::INT                       AS mistakes,
      COALESCE(ra.att_count, 0)::INT                AS attempts,
      ra.last_att,
      GREATEST(ra.last_att, mc.last_m)              AS synced_at,
      CASE
        WHEN ra.last_att IS NULL AND mc.last_m IS NULL THEN 'unknown'
        WHEN GREATEST(ra.last_att, mc.last_m) >= NOW() - INTERVAL '2 days' THEN 'fresh'
        WHEN GREATEST(ra.last_att, mc.last_m) >= NOW() - INTERVAL '7 days' THEN 'moderate'
        WHEN GREATEST(ra.last_att, mc.last_m) >= NOW() - INTERVAL '14 days' THEN 'stale'
        ELSE 'very_stale'
      END AS freshness,
      CASE
        WHEN COALESCE(mc.mc, 0) >= 5
             OR (COALESCE(ra.att_count, 0) >= 2 AND ra.avg_pct < 50)
          THEN 'high'
        WHEN COALESCE(mc.mc, 0) >= 3
             OR (COALESCE(ra.att_count, 0) >= 2 AND ra.avg_pct < 70)
             OR (COALESCE(ra.att_count, 0) >= 1 AND ra.last_att < NOW() - INTERVAL '14 days')
          THEN 'medium'
        WHEN COALESCE(mc.mc, 0) >= 1
             OR (COALESCE(ra.att_count, 0) >= 1 AND ra.last_att < NOW() - INTERVAL '7 days')
             OR (COALESCE(ra.att_count, 0) = 0)
          THEN 'low'
        ELSE NULL
      END AS calculated_severity,
      ARRAY_REMOVE(ARRAY[
        CASE WHEN COALESCE(mc.mc, 0) >= 5 THEN 'high_mistake_count' END,
        CASE WHEN COALESCE(mc.mc, 0) >= 3 AND COALESCE(mc.mc, 0) < 5 THEN 'elevated_mistake_count' END,
        CASE WHEN COALESCE(mc.mc, 0) >= 1 AND COALESCE(mc.mc, 0) < 3 THEN 'active_mistakes_present' END,
        CASE WHEN COALESCE(ra.att_count, 0) >= 2 AND ra.avg_pct < 50 THEN 'low_recent_accuracy' END,
        CASE WHEN COALESCE(ra.att_count, 0) >= 2 AND ra.avg_pct >= 50 AND ra.avg_pct < 70 THEN 'borderline_accuracy' END,
        CASE WHEN COALESCE(ra.att_count, 0) >= 1 AND ra.last_att < NOW() - INTERVAL '14 days' THEN 'no_recent_activity' END,
        CASE WHEN COALESCE(ra.att_count, 0) >= 1 AND ra.last_att >= NOW() - INTERVAL '14 days' AND ra.last_att < NOW() - INTERVAL '7 days' THEN 'overdue_practice' END,
        CASE WHEN COALESCE(ra.att_count, 0) = 0 THEN 'no_practice_data' END
      ], NULL) AS reason_list
    FROM school_students ss
    LEFT JOIN recent_attempts ra ON ra.user_id = ss.student_uid
    LEFT JOIN mistake_counts  mc ON mc.user_id = ss.student_uid
  ),
  filtered_population AS (
    SELECT *
    FROM scored_population sp
    WHERE sp.calculated_severity IS NOT NULL
      AND (v_norm_sev IS NULL OR sp.calculated_severity = v_norm_sev)
  )
  SELECT
    fp.user_id,
    fp.display_name,
    fp.school_student_id,
    fp.classroom_name,
    fp.stream,
    fp.recent_accuracy,
    fp.mistakes,
    fp.attempts,
    fp.last_att,
    fp.synced_at,
    fp.freshness,
    fp.calculated_severity,
    fp.reason_list,
    COUNT(*) OVER () AS total_count
  FROM filtered_population fp
  ORDER BY 
    CASE fp.calculated_severity
      WHEN 'high'   THEN 1
      WHEN 'medium' THEN 2
      WHEN 'low'    THEN 3
      ELSE 4
    END,
    fp.mistakes DESC,
    fp.display_name
  LIMIT  v_safe_limit
  OFFSET v_safe_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_support_population(UUID, TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_support_population(UUID, TEXT, TEXT, INT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 7: get_school_assessments_overview
-- Recent assessments completed by students of the school.
-- Preserves P5 provenance: exam_mode, source_type, and exam_type.
-- Bounded: p_limit capped between 1 and 50.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_assessments_overview(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL,
  p_limit         INT DEFAULT 15
)
RETURNS TABLE (
  exam_id           UUID,
  exam_title        TEXT,
  subject_id        TEXT,
  subject_name      TEXT,
  exam_type         TEXT,
  exam_mode         TEXT,
  source_type       TEXT,
  total_questions   INT,
  participant_count INT,
  eligible_count    INT,
  participation_pct NUMERIC,
  avg_percentage    NUMERIC,
  median_percentage NUMERIC,
  latest_attempt_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
  v_safe_limit INT;
  v_total_school_students INT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
  v_safe_limit := LEAST(GREATEST(COALESCE(p_limit, 15), 1), 50);

  SELECT COUNT(DISTINCT cm.user_id)::INT INTO v_total_school_students
  FROM public.classrooms c
  JOIN public.classroom_memberships cm 
    ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
  WHERE c.school_id = p_school_id
    AND c.academic_year = v_year
    AND c.status = 'active';

  RETURN QUERY
  WITH school_students AS (
    SELECT DISTINCT cm.user_id AS uid
    FROM   public.classroom_memberships cm
    JOIN   public.classrooms c ON c.id = cm.classroom_id
    WHERE  c.school_id     = p_school_id
      AND  c.academic_year = v_year
      AND  c.status        = 'active'
      AND  cm.status       = 'active'
      AND  cm.role         = 'student'
  ),
  school_streams AS (
    SELECT
      COUNT(DISTINCT CASE WHEN c.stream IN ('naturalScience', 'natural') THEN cm.user_id END)::INT AS nat_students,
      COUNT(DISTINCT CASE WHEN c.stream IN ('socialScience', 'social') THEN cm.user_id END)::INT AS soc_students,
      COUNT(DISTINCT cm.user_id)::INT AS total_students
    FROM public.classrooms c
    JOIN public.classroom_memberships cm 
      ON cm.classroom_id = c.id AND cm.status = 'active' AND cm.role = 'student'
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
  ),
  ranked_attempts AS (
    SELECT
      a.exam_id,
      a.user_id,
      a.percentage,
      a.created_at,
      ROW_NUMBER() OVER (PARTITION BY a.exam_id, a.user_id ORDER BY a.created_at DESC) AS rn
    FROM public.attempts a
    WHERE a.user_id IN (SELECT uid FROM school_students)
      AND a.is_completed = TRUE
  ),
  latest_exam_attempts AS (
    SELECT
      ra.exam_id,
      ra.user_id,
      ra.percentage,
      ra.created_at
    FROM ranked_attempts ra
    WHERE ra.rn = 1
  ),
  exam_stats AS (
    SELECT
      lea.exam_id,
      COUNT(DISTINCT lea.user_id)::INT AS participants,
      ROUND(AVG(lea.percentage)::NUMERIC, 2) AS avg_pct,
      ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY lea.percentage)::NUMERIC, 2) AS med_pct,
      MAX(lea.created_at) AS last_att_at
    FROM latest_exam_attempts lea
    GROUP BY lea.exam_id
  )
  ,
  exam_enriched AS (
    SELECT
      es.exam_id,
      es.participants,
      es.avg_pct,
      es.med_pct,
      es.last_att_at,
      e.title AS exam_title,
      e.subject_id,
      COALESCE(s.name_en, e.subject_id) AS subject_name,
      COALESCE(e.exam_type, 'practice') AS exam_type,
      COALESCE(e.exam_mode, 'practice') AS exam_mode,
      COALESCE(e.source_type, 'generatedSimulation') AS source_type,
      e.total_questions,
      CASE
        WHEN e.subject_id = 'math_g12' THEN
          CASE
            WHEN e.exam_variant = 'naturalScience' AND (e.stream IS NULL OR e.stream NOT IN ('social', 'socialScience')) THEN ss.nat_students
            WHEN e.exam_variant = 'socialScience' AND (e.stream IS NULL OR e.stream NOT IN ('natural', 'naturalScience')) THEN ss.soc_students
            ELSE 0
          END
        WHEN e.stream IN ('naturalScience', 'natural') THEN ss.nat_students
        WHEN e.stream IN ('socialScience', 'social') THEN ss.soc_students
        ELSE ss.total_students
      END AS eligible_count
    FROM exam_stats es
    JOIN public.exams e ON e.id = es.exam_id
    CROSS JOIN school_streams ss
    LEFT JOIN public.subjects s ON s.id = e.subject_id
  )
  SELECT
    ee.exam_id,
    ee.exam_title,
    ee.subject_id,
    ee.subject_name,
    ee.exam_type,
    ee.exam_mode,
    ee.source_type,
    ee.total_questions,
    ee.participants,
    ee.eligible_count,
    CASE 
      WHEN ee.eligible_count > 0 THEN 
        ROUND((ee.participants::NUMERIC / ee.eligible_count::NUMERIC) * 100, 1)
      ELSE 0.0 
    END AS participation_pct,
    ee.avg_pct,
    ee.med_pct,
    ee.last_att_at
  FROM exam_enriched ee
  ORDER BY ee.last_att_at DESC
  LIMIT v_safe_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_assessments_overview(UUID, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_assessments_overview(UUID, TEXT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 8: get_school_teacher_coverage
-- Operational teacher subject assignment oversight across all classrooms.
-- Identifies unassigned subject-classroom combinations.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_teacher_coverage(
  p_school_id     UUID,
  p_academic_year TEXT DEFAULT NULL
)
RETURNS TABLE (
  classroom_id           UUID,
  classroom_name         TEXT,
  grade                  INT,
  stream                 TEXT,
  section                TEXT,
  subject_id             TEXT,
  subject_name           TEXT,
  exam_variant           TEXT,
  teacher_user_id        UUID,
  teacher_name           TEXT,
  is_assigned            BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_year TEXT;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);

  RETURN QUERY
  WITH active_classes AS (
    SELECT
      c.id AS cid,
      c.name AS cname,
      c.grade AS cgrade,
      c.stream AS cstream,
      c.section AS csection
    FROM public.classrooms c
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active'
  ),
  core_curriculum AS (
    SELECT
      s.id AS sub_id,
      s.name_en AS sub_name,
      CASE
        WHEN s.id IN ('physics_g12', 'chemistry_g12', 'biology_g12') THEN 'naturalScience'
        WHEN s.id IN ('history_g12', 'geography_g12', 'economics_g12') THEN 'socialScience'
        ELSE 'common'
      END AS sub_stream
    FROM public.subjects s
    WHERE s.grade = 12
      AND s.id != 'civics_g12' -- Civics is supplementary, excluded from default ESSLCE staffing slots
  ),
  required_slots AS (
    SELECT
      ac.cid,
      ac.cname,
      ac.cgrade,
      ac.cstream,
      ac.csection,
      cc.sub_id,
      CASE
        WHEN cc.sub_id = 'math_g12' AND ac.cstream = 'naturalScience' THEN 'Mathematics — Natural Science'
        WHEN cc.sub_id = 'math_g12' AND ac.cstream = 'socialScience' THEN 'Mathematics — Social Science'
        ELSE cc.sub_name
      END AS sub_name,
      CASE
        WHEN cc.sub_id = 'math_g12' THEN ac.cstream
        ELSE NULL
      END AS req_variant
    FROM active_classes ac
    JOIN core_curriculum cc 
      ON (cc.sub_stream = 'common' OR cc.sub_stream = ac.cstream)
  )
  SELECT
    rs.cid,
    rs.cname,
    rs.cgrade,
    COALESCE(rs.cstream, 'common'),
    COALESCE(rs.csection, ''),
    rs.sub_id,
    rs.sub_name,
    COALESCE(tsa.exam_variant, rs.req_variant),
    tsa.teacher_user_id,
    p.display_name,
    tsa.teacher_user_id IS NOT NULL
  FROM required_slots rs
  LEFT JOIN public.teacher_subject_assignments tsa 
         ON tsa.classroom_id = rs.cid 
        AND tsa.subject_id = rs.sub_id 
        AND (rs.req_variant IS NULL OR tsa.exam_variant = rs.req_variant)
        AND tsa.status = 'active'
  LEFT JOIN public.profiles p ON p.id = tsa.teacher_user_id
  ORDER BY rs.cname, rs.sub_name;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_teacher_coverage(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_teacher_coverage(UUID, TEXT) TO authenticated;


-- -----------------------------------------------------------------------------
-- RPC 9: get_school_student_academic_summary
-- Drill-down for school leadership into a specific student's academic standing.
-- Scoped to students enrolled in caller's active school.
-- Privacy: ZERO Study Coins, phone numbers, password metadata, or auth tokens.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_school_student_academic_summary(
  p_school_id  UUID,
  p_student_id UUID
)
RETURNS TABLE (
  student_id                 UUID,
  display_name               TEXT,
  school_student_id          TEXT,
  classroom_name             TEXT,
  grade                      INT,
  stream                     TEXT,
  total_attempts             INT,
  recent_avg_percentage      NUMERIC,
  overall_accuracy_pct       NUMERIC,
  last_activity_at           TIMESTAMPTZ,
  last_synced_at             TIMESTAMPTZ,
  sync_freshness             TEXT,
  total_mistakes             INT,
  mastered_mistakes          INT,
  weak_topics                JSONB,
  recent_exams               JSONB,
  mastery_availability_note  TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_student_name TEXT;
  v_student_sid TEXT;
  v_cname TEXT;
  v_grade INT;
  v_stream TEXT;
  v_tot_attempts INT := 0;
  v_recent_avg NUMERIC := NULL;
  v_overall_pct NUMERIC := NULL;
  v_last_act TIMESTAMPTZ := NULL;
  v_last_sync TIMESTAMPTZ := NULL;
  v_freshness TEXT := 'unknown';
  v_tot_mis INT := 0;
  v_mast_mis INT := 0;
  v_weak_json JSONB := '[]'::JSONB;
  v_exams_json JSONB := '[]'::JSONB;
BEGIN
  IF NOT public.resolve_school_admin_authority(p_school_id) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not an active school admin for this school';
  END IF;

  -- Verify target student is an active member in this school
  IF NOT EXISTS (
    SELECT 1 
    FROM   public.school_memberships sm
    WHERE  sm.school_id = p_school_id
      AND  sm.user_id   = p_student_id
      AND  sm.role      = 'student'
      AND  sm.status    = 'active'
  ) THEN
    RAISE EXCEPTION 'NOT_FOUND: Student is not an active student member in this school';
  END IF;

  -- 1. Student Identity & Classroom Info
  SELECT
    p.display_name,
    sm.school_student_id,
    c.name,
    c.grade,
    c.stream
  INTO
    v_student_name,
    v_student_sid,
    v_cname,
    v_grade,
    v_stream
  FROM public.school_memberships sm
  JOIN public.profiles p ON p.id = sm.user_id
  LEFT JOIN public.classroom_memberships cm 
         ON cm.user_id = sm.user_id AND cm.status = 'active' AND cm.role = 'student'
  LEFT JOIN public.classrooms c 
         ON c.id = cm.classroom_id AND c.school_id = p_school_id AND c.status = 'active'
  WHERE sm.school_id = p_school_id
    AND sm.user_id   = p_student_id
  LIMIT 1;

  -- 2. Attempt Aggregates
  SELECT
    COUNT(*)::INT,
    ROUND(AVG(CASE WHEN a.created_at >= NOW() - INTERVAL '30 days' THEN a.percentage END)::NUMERIC, 2),
    ROUND(AVG(a.percentage)::NUMERIC, 2),
    MAX(a.created_at)
  INTO
    v_tot_attempts,
    v_recent_avg,
    v_overall_pct,
    v_last_act
  FROM public.attempts a
  WHERE a.user_id = p_student_id AND a.is_completed = TRUE;

  -- 3. Mistake Aggregates
  SELECT
    COUNT(*)::INT,
    COUNT(CASE WHEN mr.is_mastered = TRUE THEN 1 END)::INT,
    MAX(mr.last_failed_at)
  INTO
    v_tot_mis,
    v_mast_mis,
    v_last_sync
  FROM public.mistake_records mr
  WHERE mr.user_id = p_student_id;

  v_last_sync := GREATEST(v_last_act, v_last_sync);
  IF v_last_sync IS NOT NULL THEN
    IF v_last_sync >= NOW() - INTERVAL '2 days' THEN v_freshness := 'fresh';
    ELSIF v_last_sync >= NOW() - INTERVAL '7 days' THEN v_freshness := 'moderate';
    ELSIF v_last_sync >= NOW() - INTERVAL '14 days' THEN v_freshness := 'stale';
    ELSE v_freshness := 'very_stale';
    END IF;
  END IF;

  -- 4. Weak Topics for this Student
  SELECT COALESCE(jsonb_agg(sub), '[]'::JSONB)
  INTO   v_weak_json
  FROM (
    SELECT
      t.id AS topic_id,
      t.title_en AS topic_name_en,
      u.title_en AS unit_name_en,
      q.subject_id,
      s.name_en AS subject_name,
      COUNT(*)::INT AS active_mistakes
    FROM public.mistake_records mr
    JOIN public.questions q ON q.id = mr.question_id
    JOIN public.topics t ON t.id = q.topic_id
    JOIN public.units u ON u.id = t.unit_id
    LEFT JOIN public.subjects s ON s.id = q.subject_id
    WHERE mr.user_id = p_student_id AND mr.is_mastered = FALSE
    GROUP BY t.id, t.title_en, u.title_en, q.subject_id, s.name_en
    ORDER BY COUNT(*) DESC
    LIMIT 10
  ) sub;

  -- 5. Recent Completed Exams
  SELECT COALESCE(jsonb_agg(sub), '[]'::JSONB)
  INTO   v_exams_json
  FROM (
    SELECT
      e.id AS exam_id,
      e.title AS exam_title,
      e.subject_id,
      COALESCE(s.name_en, e.subject_id) AS subject_name,
      e.exam_type,
      e.exam_mode,
      e.source_type,
      e.total_questions,
      a.percentage,
      a.created_at AS completed_at
    FROM public.attempts a
    JOIN public.exams e ON e.id = a.exam_id
    LEFT JOIN public.subjects s ON s.id = e.subject_id
    WHERE a.user_id = p_student_id AND a.is_completed = TRUE
    ORDER BY a.created_at DESC
    LIMIT 10
  ) sub;

  RETURN QUERY SELECT
    p_student_id,
    v_student_name,
    v_student_sid,
    COALESCE(v_cname, 'Unassigned Class'),
    COALESCE(v_grade, 12),
    COALESCE(v_stream, 'common'),
    v_tot_attempts,
    v_recent_avg,
    v_overall_pct,
    v_last_act,
    v_last_sync,
    v_freshness,
    v_tot_mis,
    v_mast_mis,
    v_weak_json,
    v_exams_json,
    'Mastery data (P4 fidel_spaced_v1.0) and national exam readiness are device-local to the student phone. Institutional summaries reflect cloud-synced attempts and mistake records only.'::TEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_student_academic_summary(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_student_academic_summary(UUID, UUID) TO authenticated;
-- =============================================================================
-- FidelLearn — P9 Assignments + Intervention System Database Migration
-- Migration: 20260925030000
-- Description: Multi-tenant, teacher-controlled, offline-capable assignment
--              and academic intervention tables, atomic publication,
--              recipient snapshotting, RLS, audit logging, and RPC read models.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: public.learning_assignments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    subject_id TEXT NOT NULL,
    exam_variant TEXT NULL,
    title TEXT NOT NULL,
    instructions TEXT NULL,
    assignment_type TEXT NOT NULL CHECK (assignment_type IN ('targetedPractice', 'customQuestionSet', 'simulation')),
    status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'closed', 'archived')) DEFAULT 'draft',
    due_at TIMESTAMPTZ NULL,
    allow_late_submission BOOLEAN NOT NULL DEFAULT true,
    time_limit_minutes INT NOT NULL DEFAULT 0,
    total_questions INT NOT NULL DEFAULT 0,
    content_hash TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    published_at TIMESTAMPTZ NULL,
    closed_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_assignments_school_class_status 
    ON public.learning_assignments(school_id, classroom_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_status 
    ON public.learning_assignments(teacher_user_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_subject_variant 
    ON public.learning_assignments(subject_id, exam_variant);

-- -----------------------------------------------------------------------------
-- 2. Table: public.learning_assignment_questions
-- Immutable question snapshot frozen at publication.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignment_questions (
    assignment_id UUID NOT NULL REFERENCES public.learning_assignments(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE RESTRICT,
    position INT NOT NULL,
    question_content_version INT NOT NULL DEFAULT 1,
    package_version TEXT NOT NULL DEFAULT '1.0.0',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (assignment_id, question_id),
    CONSTRAINT uq_assignment_question_position UNIQUE (assignment_id, position)
);

CREATE INDEX IF NOT EXISTS idx_assignment_questions_lookup 
    ON public.learning_assignment_questions(assignment_id, position);

-- -----------------------------------------------------------------------------
-- 3. Table: public.learning_assignment_recipients
-- Explicit student recipient snapshot resolved at publication.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignment_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.learning_assignments(id) ON DELETE CASCADE,
    student_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    status TEXT NOT NULL CHECK (status IN ('assigned', 'inProgress', 'submitted', 'completed', 'late', 'excused')) DEFAULT 'assigned',
    attempt_id UUID NULL REFERENCES public.attempts(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NULL,
    submitted_at TIMESTAMPTZ NULL,
    score INT NULL,
    percentage NUMERIC(5,2) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_assignment_student_recipient UNIQUE (assignment_id, student_user_id)
);

CREATE INDEX IF NOT EXISTS idx_assignment_recipients_student 
    ON public.learning_assignment_recipients(student_user_id, status);
CREATE INDEX IF NOT EXISTS idx_assignment_recipients_assignment_status 
    ON public.learning_assignment_recipients(assignment_id, status);

-- -----------------------------------------------------------------------------
-- 4. Table: public.student_interventions
-- Tracks formal academic intervention actions linked to attention signals or teacher observation.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE RESTRICT,
    subject_id TEXT NOT NULL,
    exam_variant TEXT NULL,
    student_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    source TEXT NOT NULL CHECK (source IN ('p7Attention', 'teacherObservation', 'assessmentReview', 'mistakeReview')),
    source_reason_codes JSONB NOT NULL DEFAULT '[]'::jsonb,
    severity_at_creation TEXT NULL CHECK (severity_at_creation IN ('high', 'medium', 'low')),
    action_type TEXT NOT NULL CHECK (action_type IN ('targetedPractice', 'reviewMistakes', 'simulation', 'teacherFollowUp')),
    linked_assignment_id UUID NULL REFERENCES public.learning_assignments(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'active', 'completed', 'closed')) DEFAULT 'open',
    teacher_note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    started_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    closed_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_interventions_school_class_status 
    ON public.student_interventions(school_id, classroom_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_student 
    ON public.student_interventions(student_user_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_teacher 
    ON public.student_interventions(teacher_user_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_linked_assignment 
    ON public.student_interventions(linked_assignment_id);

-- -----------------------------------------------------------------------------
-- 5. Row-Level Security (RLS) Configuration
-- -----------------------------------------------------------------------------
ALTER TABLE public.learning_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_assignment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_assignment_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_interventions ENABLE ROW LEVEL SECURITY;

-- Block direct mutations by untrusted client queries; enforce Security Definer RPCs
CREATE POLICY "assignments_no_direct_insert" ON public.learning_assignments FOR INSERT WITH CHECK (false);
CREATE POLICY "assignments_no_direct_update" ON public.learning_assignments FOR UPDATE USING (false);
CREATE POLICY "assignments_no_direct_delete" ON public.learning_assignments FOR DELETE USING (false);

CREATE POLICY "assignment_questions_no_direct_insert" ON public.learning_assignment_questions FOR INSERT WITH CHECK (false);
CREATE POLICY "assignment_questions_no_direct_update" ON public.learning_assignment_questions FOR UPDATE USING (false);
CREATE POLICY "assignment_questions_no_direct_delete" ON public.learning_assignment_questions FOR DELETE USING (false);

CREATE POLICY "assignment_recipients_no_direct_insert" ON public.learning_assignment_recipients FOR INSERT WITH CHECK (false);
CREATE POLICY "assignment_recipients_no_direct_update" ON public.learning_assignment_recipients FOR UPDATE USING (false);
CREATE POLICY "assignment_recipients_no_direct_delete" ON public.learning_assignment_recipients FOR DELETE USING (false);

CREATE POLICY "interventions_no_direct_insert" ON public.student_interventions FOR INSERT WITH CHECK (false);
CREATE POLICY "interventions_no_direct_update" ON public.student_interventions FOR UPDATE USING (false);
CREATE POLICY "interventions_no_direct_delete" ON public.student_interventions FOR DELETE USING (false);

-- Grant SELECT on P9 tables to authenticated role so RLS policies can take effect
GRANT SELECT ON public.learning_assignments, public.learning_assignment_questions, public.learning_assignment_recipients, public.student_interventions TO authenticated;

-- -----------------------------------------------------------------------------
-- RLS Non-Recursive Helper Functions
-- Executed with table owner privileges to break mutual policy recursion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_assignment_recipient(
    p_assignment_id   UUID,
    p_student_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.learning_assignment_recipients
        WHERE assignment_id = p_assignment_id
          AND student_user_id = p_student_user_id
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_assignment_recipient_rows(
    p_assignment_id UUID,
    p_user_id       UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.learning_assignments a
        WHERE a.id = p_assignment_id
          AND (
              a.teacher_user_id = p_user_id
              OR EXISTS (
                  SELECT 1 FROM public.school_memberships sm
                  WHERE sm.user_id = p_user_id
                    AND sm.school_id = a.school_id
                    AND sm.role = 'school_admin'
                    AND sm.status = 'active'
              )
          )
    );
$$;

REVOKE ALL ON FUNCTION public.is_assignment_recipient(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_assignment_recipient(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_read_assignment_recipient_rows(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_read_assignment_recipient_rows(UUID, UUID) TO authenticated;

-- Read Policies:
-- Teachers: Can read assignments in their authorized school/classroom/subject
CREATE POLICY "assignments_teacher_read" ON public.learning_assignments FOR SELECT
USING (
    teacher_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.school_memberships sm
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = learning_assignments.school_id
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
    )
);

-- Students: Can read published/closed assignments where they are an active recipient
CREATE POLICY "assignments_student_read" ON public.learning_assignments FOR SELECT
USING (
    status IN ('published', 'closed')
    AND public.is_assignment_recipient(id, auth.uid())
);

CREATE POLICY "assignment_questions_read" ON public.learning_assignment_questions FOR SELECT
USING (
    public.can_read_assignment_recipient_rows(assignment_id, auth.uid())
    OR (
        EXISTS (
            SELECT 1 FROM public.learning_assignments a
            WHERE a.id = learning_assignment_questions.assignment_id
              AND a.status IN ('published', 'closed')
        )
        AND public.is_assignment_recipient(assignment_id, auth.uid())
    )
);

CREATE POLICY "assignment_recipients_read" ON public.learning_assignment_recipients FOR SELECT
USING (
    student_user_id = auth.uid()
    OR public.can_read_assignment_recipient_rows(assignment_id, auth.uid())
);

CREATE POLICY "interventions_read" ON public.student_interventions FOR SELECT
USING (
    teacher_user_id = auth.uid()
    OR student_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.school_memberships sm
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = student_interventions.school_id
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
    )
);

-- -----------------------------------------------------------------------------
-- 6. Helper: can_teacher_manage_assignment
-- Verifies active teacher membership, active school status, and active
-- teacher_subject_assignment with strict variant isolation.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_teacher_manage_assignment(
    p_school_id    UUID,
    p_classroom_id UUID,
    p_subject_id   TEXT,
    p_exam_variant TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   public.teacher_subject_assignments tsa
        JOIN   public.school_memberships sm
               ON  sm.user_id   = auth.uid()
               AND sm.school_id  = tsa.school_id
               AND sm.role       = 'teacher'
               AND sm.status     = 'active'
        JOIN   public.schools s
               ON  s.id         = tsa.school_id
               AND s.status     = 'active'
        WHERE  tsa.teacher_user_id = auth.uid()
          AND  tsa.school_id       = p_school_id
          AND  tsa.classroom_id    = p_classroom_id
          AND  tsa.subject_id      = p_subject_id
          AND  tsa.status          = 'active'
          AND  (
              -- Mathematics canonical rule: strict variant matching
              CASE
                  WHEN p_subject_id = 'math_g12' THEN tsa.exam_variant = p_exam_variant
                  ELSE (tsa.exam_variant IS NOT DISTINCT FROM p_exam_variant OR tsa.exam_variant IS NULL)
              END
          )
    );
$$;

REVOKE ALL ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 7. RPC: create_learning_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_learning_assignment(
    p_school_id            UUID,
    p_classroom_id         UUID,
    p_subject_id           TEXT,
    p_exam_variant         TEXT,
    p_title                TEXT,
    p_instructions         TEXT,
    p_assignment_type      TEXT,
    p_time_limit_minutes   INT DEFAULT 0,
    p_due_at               TIMESTAMPTZ DEFAULT NULL,
    p_allow_late_submission BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assignment_id UUID;
    v_title TEXT := trim(COALESCE(p_title, ''));
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_title = '' THEN
        RAISE EXCEPTION 'Assignment title cannot be empty' USING ERRCODE = '22000';
    END IF;

    IF p_assignment_type NOT IN ('targetedPractice', 'customQuestionSet', 'simulation') THEN
        RAISE EXCEPTION 'Invalid assignment type: %', p_assignment_type USING ERRCODE = '22000';
    END IF;

    IF NOT public.can_teacher_manage_assignment(p_school_id, p_classroom_id, p_subject_id, p_exam_variant) THEN
        RAISE EXCEPTION 'Teacher is not authorized to create assignments for this classroom and subject' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.learning_assignments (
        school_id,
        classroom_id,
        teacher_user_id,
        subject_id,
        exam_variant,
        title,
        instructions,
        assignment_type,
        status,
        time_limit_minutes,
        due_at,
        allow_late_submission,
        total_questions,
        created_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_classroom_id,
        auth.uid(),
        p_subject_id,
        p_exam_variant,
        v_title,
        p_instructions,
        p_assignment_type,
        'draft',
        GREATEST(0, COALESCE(p_time_limit_minutes, 0)),
        p_due_at,
        COALESCE(p_allow_late_submission, true),
        0,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_assignment_id;

    -- Audit log
    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        'assignment_created',
        'learning_assignments',
        v_assignment_id,
        jsonb_build_object(
            'school_id', p_school_id,
            'classroom_id', p_classroom_id,
            'subject_id', p_subject_id,
            'exam_variant', p_exam_variant,
            'assignment_type', p_assignment_type,
            'title', v_title
        )
    );

    RETURN v_assignment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_learning_assignment(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_learning_assignment(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- 8. RPC: update_learning_assignment_draft
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_learning_assignment_draft(
    p_assignment_id        UUID,
    p_title                TEXT,
    p_instructions         TEXT,
    p_time_limit_minutes   INT,
    p_due_at               TIMESTAMPTZ,
    p_allow_late_submission BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_title TEXT := trim(COALESCE(p_title, ''));
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.status != 'draft' THEN
        RAISE EXCEPTION 'Only draft assignments can be modified' USING ERRCODE = '22000';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the authoring teacher can edit this draft' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(v_assign.school_id, v_assign.classroom_id, v_assign.subject_id, v_assign.exam_variant) THEN
        RAISE EXCEPTION 'Teacher authorization has lapsed' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET title = CASE WHEN v_title != '' THEN v_title ELSE title END,
        instructions = COALESCE(p_instructions, instructions),
        time_limit_minutes = GREATEST(0, COALESCE(p_time_limit_minutes, time_limit_minutes)),
        due_at = p_due_at,
        allow_late_submission = COALESCE(p_allow_late_submission, allow_late_submission),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.update_learning_assignment_draft(UUID, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_learning_assignment_draft(UUID, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- 9. RPC: publish_learning_assignment (Atomic & Idempotent)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.publish_learning_assignment(
    p_assignment_id        UUID,
    p_question_ids         UUID[],
    p_recipient_student_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_q_count INT;
    v_recip_count INT := 0;
    v_pos INT;
    v_qid UUID;
    v_sid UUID;
    v_content_hash TEXT;
    v_hash_payload TEXT;
    v_unverified_count INT;
    v_foreign_student_count INT;
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    -- Idempotency check: if already published, return existing counts safely
    IF v_assign.status = 'published' THEN
        SELECT COUNT(*) INTO v_recip_count
        FROM public.learning_assignment_recipients
        WHERE assignment_id = p_assignment_id;

        RETURN jsonb_build_object(
            'success', true,
            'assignment_id', p_assignment_id,
            'status', 'published',
            'total_questions', v_assign.total_questions,
            'recipient_count', v_recip_count,
            'content_hash', v_assign.content_hash,
            'idempotent', true
        );
    END IF;

    IF v_assign.status != 'draft' THEN
        RAISE EXCEPTION 'Cannot publish assignment in status: %', v_assign.status USING ERRCODE = '22000';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the authoring teacher can publish this assignment' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(v_assign.school_id, v_assign.classroom_id, v_assign.subject_id, v_assign.exam_variant) THEN
        RAISE EXCEPTION 'Teacher authorization has lapsed' USING ERRCODE = '42501';
    END IF;

    v_q_count := COALESCE(cardinality(p_question_ids), 0);
    IF v_q_count = 0 THEN
        RAISE EXCEPTION 'Cannot publish assignment without questions' USING ERRCODE = '22000';
    END IF;

    -- 1. Validate questions: must exist, match subject/grade, and be verified
    SELECT COUNT(*) INTO v_unverified_count
    FROM unnest(p_question_ids) AS qid
    LEFT JOIN public.questions q ON q.id = qid
    WHERE q.id IS NULL
       OR q.subject_id != v_assign.subject_id
       OR (v_assign.subject_id = 'math_g12' AND q.exam_variant != v_assign.exam_variant)
       OR q.verification_status NOT IN ('verified', 'approved', 'published', 'corrected');

    IF v_unverified_count > 0 THEN
        RAISE EXCEPTION 'Question selection contains % ineligible or unverified questions for this subject/variant', v_unverified_count USING ERRCODE = '22000';
    END IF;

    -- 2. Freeze questions into learning_assignment_questions
    DELETE FROM public.learning_assignment_questions WHERE assignment_id = p_assignment_id;

    v_pos := 0;
    FOREACH v_qid IN ARRAY p_question_ids LOOP
        INSERT INTO public.learning_assignment_questions (
            assignment_id,
            question_id,
            position,
            question_content_version,
            package_version
        ) VALUES (
            p_assignment_id,
            v_qid,
            v_pos,
            1,
            '1.0.0'
        );
        v_pos := v_pos + 1;
    END LOOP;

    -- Compute SHA-256 fingerprint over ordered question list
    v_hash_payload := p_assignment_id::text || '|' || v_assign.subject_id || '|' || COALESCE(v_assign.exam_variant, 'none') || '|' || array_to_string(p_question_ids, ',');
    v_content_hash := encode(sha256(v_hash_payload::bytea), 'hex');

    -- 3. Resolve and freeze recipients
    DELETE FROM public.learning_assignment_recipients WHERE assignment_id = p_assignment_id;

    IF p_recipient_student_ids IS NOT NULL AND cardinality(p_recipient_student_ids) > 0 THEN
        -- Explicit subset provided: verify all belong to this classroom and active school
        SELECT COUNT(*) INTO v_foreign_student_count
        FROM unnest(p_recipient_student_ids) AS sid
        LEFT JOIN public.classroom_memberships cm 
               ON cm.user_id = sid 
              AND cm.classroom_id = v_assign.classroom_id 
              AND cm.status = 'active'
        LEFT JOIN public.school_memberships sm 
               ON sm.user_id = sid 
              AND sm.school_id = v_assign.school_id 
              AND sm.status = 'active'
        WHERE cm.user_id IS NULL OR sm.user_id IS NULL;

        IF v_foreign_student_count > 0 THEN
            RAISE EXCEPTION 'Target recipients include % students not actively enrolled in this classroom', v_foreign_student_count USING ERRCODE = '42501';
        END IF;

        FOREACH v_sid IN ARRAY p_recipient_student_ids LOOP
            INSERT INTO public.learning_assignment_recipients (
                assignment_id,
                student_user_id,
                assigned_at,
                status
            ) VALUES (
                p_assignment_id,
                v_sid,
                TIMEZONE('utc', NOW()),
                'assigned'
            );
            v_recip_count := v_recip_count + 1;
        END LOOP;
    ELSE
        -- Default: freeze entire active classroom roster
        INSERT INTO public.learning_assignment_recipients (
            assignment_id,
            student_user_id,
            assigned_at,
            status
        )
        SELECT 
            p_assignment_id,
            cm.user_id,
            TIMEZONE('utc', NOW()),
            'assigned'
        FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = v_assign.school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = v_assign.classroom_id
          AND cm.status = 'active';

        GET DIAGNOSTICS v_recip_count = ROW_COUNT;
    END IF;

    -- 4. Transition to published
    UPDATE public.learning_assignments
    SET status = 'published',
        total_questions = v_q_count,
        content_hash = v_content_hash,
        published_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    -- 5. Audit log
    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        'assignment_published',
        'learning_assignments',
        p_assignment_id,
        jsonb_build_object(
            'total_questions', v_q_count,
            'recipient_count', v_recip_count,
            'content_hash', v_content_hash
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', p_assignment_id,
        'status', 'published',
        'total_questions', v_q_count,
        'recipient_count', v_recip_count,
        'content_hash', v_content_hash,
        'idempotent', false
    );
END;
$$;

REVOKE ALL ON FUNCTION public.publish_learning_assignment(UUID, UUID[], UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publish_learning_assignment(UUID, UUID[], UUID[]) TO authenticated;

-- -----------------------------------------------------------------------------
-- 10. RPC: close_learning_assignment & archive_learning_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close this assignment' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_closed', 'learning_assignments', p_assignment_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.close_learning_assignment(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_learning_assignment(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.archive_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can archive this assignment' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET status = 'archived',
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_archived', 'learning_assignments', p_assignment_id, jsonb_build_object('archived_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.archive_learning_assignment(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.archive_learning_assignment(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 11. RPC: add_assignment_recipient
-- Deliberately adds a newly joined student to an already published assignment.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_assignment_recipient(
    p_assignment_id  UUID,
    p_student_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_is_enrolled BOOLEAN;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can add recipients' USING ERRCODE = '42501';
    END IF;

    -- Verify student is active member of this classroom and school
    SELECT EXISTS (
        SELECT 1 
        FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = v_assign.school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = v_assign.classroom_id
          AND cm.user_id = p_student_user_id
          AND cm.status = 'active'
    ) INTO v_is_enrolled;

    IF NOT v_is_enrolled THEN
        RAISE EXCEPTION 'Student is not actively enrolled in this classroom' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.learning_assignment_recipients (
        assignment_id,
        student_user_id,
        assigned_at,
        status
    ) VALUES (
        p_assignment_id,
        p_student_user_id,
        TIMEZONE('utc', NOW()),
        'assigned'
    ) ON CONFLICT (assignment_id, student_user_id) DO NOTHING;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        auth.uid(),
        'assignment_recipient_added',
        'learning_assignment_recipients',
        p_assignment_id,
        jsonb_build_object('student_user_id', p_student_user_id)
    );

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.add_assignment_recipient(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.add_assignment_recipient(UUID, UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 12. RPC: get_teacher_assignments (Teacher Read Model)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_assignments(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_status       TEXT DEFAULT NULL,
    p_limit        INT DEFAULT 50,
    p_offset       INT DEFAULT 0
)
RETURNS TABLE (
    assignment_id        UUID,
    school_id            UUID,
    classroom_id         UUID,
    classroom_name       TEXT,
    subject_id           TEXT,
    exam_variant         TEXT,
    title                TEXT,
    instructions         TEXT,
    assignment_type      TEXT,
    status               TEXT,
    due_at               TIMESTAMPTZ,
    allow_late_submission BOOLEAN,
    time_limit_minutes   INT,
    total_questions      INT,
    created_at           TIMESTAMPTZ,
    published_at         TIMESTAMPTZ,
    closed_at            TIMESTAMPTZ,
    recipient_count      BIGINT,
    submitted_count      BIGINT,
    avg_score_percentage NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS assignment_id,
        a.school_id,
        a.classroom_id,
        c.name AS classroom_name,
        a.subject_id,
        a.exam_variant,
        a.title,
        a.instructions,
        a.assignment_type,
        a.status,
        a.due_at,
        a.allow_late_submission,
        a.time_limit_minutes,
        a.total_questions,
        a.created_at,
        a.published_at,
        a.closed_at,
        COALESCE(COUNT(r.id), 0) AS recipient_count,
        COALESCE(COUNT(r.id) FILTER (WHERE r.status IN ('submitted', 'completed', 'late')), 0) AS submitted_count,
        ROUND(COALESCE(AVG(r.percentage) FILTER (WHERE r.status IN ('submitted', 'completed', 'late')), 0.0)::numeric, 1) AS avg_score_percentage
    FROM public.learning_assignments a
    JOIN public.classrooms c ON c.id = a.classroom_id
    LEFT JOIN public.learning_assignment_recipients r ON r.assignment_id = a.id
    WHERE a.school_id = p_school_id
      AND (a.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = a.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
      AND (p_classroom_id IS NULL OR a.classroom_id = p_classroom_id)
      AND (p_subject_id IS NULL OR a.subject_id = p_subject_id)
      AND (p_status IS NULL OR a.status = p_status)
    GROUP BY a.id, c.name
    ORDER BY a.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_assignments(UUID, UUID, TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_assignments(UUID, UUID, TEXT, TEXT, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 13. RPC: get_teacher_assignment_progress
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_assignment_progress(
    p_assignment_id UUID,
    p_limit         INT DEFAULT 100,
    p_offset        INT DEFAULT 0
)
RETURNS TABLE (
    recipient_id      UUID,
    student_user_id   UUID,
    student_name      TEXT,
    school_student_id TEXT,
    status            TEXT,
    score             INT,
    percentage        NUMERIC,
    started_at        TIMESTAMPTZ,
    submitted_at      TIMESTAMPTZ,
    assigned_at       TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 100)), 200);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        r.id AS recipient_id,
        r.student_user_id,
        p.display_name AS student_name,
        sm_student.school_student_id,
        r.status,
        r.score,
        r.percentage,
        r.started_at,
        r.submitted_at,
        r.assigned_at
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    JOIN public.profiles p ON p.id = r.student_user_id
    LEFT JOIN public.school_memberships sm_student ON sm_student.user_id = r.student_user_id AND sm_student.school_id = a.school_id
    WHERE r.assignment_id = p_assignment_id
      AND (a.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = a.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
    ORDER BY p.display_name ASC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_assignment_progress(UUID, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_assignment_progress(UUID, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 14. RPC: get_student_assignments (Student Read Model)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_assignments(
    p_status TEXT DEFAULT NULL,
    p_limit  INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    assignment_id        UUID,
    recipient_id         UUID,
    school_id            UUID,
    classroom_id         UUID,
    classroom_name       TEXT,
    teacher_name         TEXT,
    subject_id           TEXT,
    exam_variant         TEXT,
    title                TEXT,
    instructions         TEXT,
    assignment_type      TEXT,
    assignment_status    TEXT,
    student_status       TEXT,
    due_at               TIMESTAMPTZ,
    allow_late_submission BOOLEAN,
    time_limit_minutes   INT,
    total_questions      INT,
    attempt_id           UUID,
    score                INT,
    percentage           NUMERIC,
    submitted_at         TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS assignment_id,
        r.id AS recipient_id,
        a.school_id,
        a.classroom_id,
        c.name AS classroom_name,
        tp.display_name AS teacher_name,
        a.subject_id,
        a.exam_variant,
        a.title,
        a.instructions,
        a.assignment_type,
        a.status AS assignment_status,
        r.status AS student_status,
        a.due_at,
        a.allow_late_submission,
        a.time_limit_minutes,
        a.total_questions,
        r.attempt_id,
        r.score,
        r.percentage,
        r.submitted_at
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    JOIN public.classrooms c ON c.id = a.classroom_id
    JOIN public.profiles tp ON tp.id = a.teacher_user_id
    WHERE r.student_user_id = auth.uid()
      AND a.status IN ('published', 'closed')
      AND (p_status IS NULL OR r.status = p_status)
    ORDER BY COALESCE(a.due_at, a.created_at) ASC, a.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_assignments(TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_assignments(TEXT, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 15. RPC: get_student_assignment_detail
-- Returns assignment info and question IDs in frozen order without answer keys.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_assignment_detail(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_recip RECORD;
    v_qids UUID[];
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id
      AND status IN ('published', 'closed');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found or not currently available' USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_recip
    FROM public.learning_assignment_recipients
    WHERE assignment_id = p_assignment_id
      AND student_user_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student is not an authorized recipient of this assignment' USING ERRCODE = '42501';
    END IF;

    SELECT array_agg(question_id ORDER BY position ASC) INTO v_qids
    FROM public.learning_assignment_questions
    WHERE assignment_id = p_assignment_id;

    RETURN jsonb_build_object(
        'assignment_id', v_assign.id,
        'title', v_assign.title,
        'instructions', v_assign.instructions,
        'subject_id', v_assign.subject_id,
        'exam_variant', v_assign.exam_variant,
        'assignment_type', v_assign.assignment_type,
        'status', v_assign.status,
        'time_limit_minutes', v_assign.time_limit_minutes,
        'due_at', v_assign.due_at,
        'allow_late_submission', v_assign.allow_late_submission,
        'total_questions', v_assign.total_questions,
        'question_ids', COALESCE(v_qids, ARRAY[]::UUID[]),
        'student_status', v_recip.status,
        'attempt_id', v_recip.attempt_id,
        'score', v_recip.score,
        'percentage', v_recip.percentage,
        'submitted_at', v_recip.submitted_at
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_assignment_detail(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_assignment_detail(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 16. RPC: submit_student_assignment (Idempotent submission link)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_student_assignment(
    p_assignment_id UUID,
    p_attempt_id    UUID,
    p_score         INT,
    p_percentage    NUMERIC,
    p_submitted_at  TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_recip RECORD;
    v_sub_time TIMESTAMPTZ := COALESCE(p_submitted_at, TIMEZONE('utc', NOW()));
    v_final_status TEXT;
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_recip
    FROM public.learning_assignment_recipients
    WHERE assignment_id = p_assignment_id
      AND student_user_id = auth.uid()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student is not an assigned recipient' USING ERRCODE = '42501';
    END IF;

    -- Idempotent: if already submitted with this attempt, return current state
    IF v_recip.status IN ('submitted', 'completed', 'late') AND v_recip.attempt_id = p_attempt_id THEN
        RETURN jsonb_build_object(
            'success', true,
            'assignment_id', p_assignment_id,
            'attempt_id', p_attempt_id,
            'status', v_recip.status,
            'score', v_recip.score,
            'percentage', v_recip.percentage,
            'idempotent', true
        );
    END IF;

    -- Check deadline policy
    IF v_assign.due_at IS NOT NULL AND v_sub_time > v_assign.due_at THEN
        IF v_assign.allow_late_submission THEN
            v_final_status := 'late';
        ELSE
            -- Closed policy without late submission allowance
            v_final_status := 'submitted';
        END IF;
    ELSE
        v_final_status := 'submitted';
    END IF;

    UPDATE public.learning_assignment_recipients
    SET status = v_final_status,
        attempt_id = p_attempt_id,
        score = p_score,
        percentage = p_percentage,
        submitted_at = v_sub_time,
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = v_recip.id;

    -- If there is an active intervention linked to this assignment, update intervention status
    UPDATE public.student_interventions
    SET status = 'active',
        started_at = COALESCE(started_at, v_sub_time),
        updated_at = TIMEZONE('utc', NOW())
    WHERE linked_assignment_id = p_assignment_id
      AND student_user_id = auth.uid()
      AND status = 'open';

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', p_assignment_id,
        'attempt_id', p_attempt_id,
        'status', v_final_status,
        'score', p_score,
        'percentage', p_percentage,
        'idempotent', false
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_student_assignment(UUID, UUID, INT, NUMERIC, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_student_assignment(UUID, UUID, INT, NUMERIC, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 17. RPC: create_student_intervention
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_student_intervention(
    p_school_id            UUID,
    p_classroom_id         UUID,
    p_subject_id           TEXT,
    p_exam_variant         TEXT,
    p_student_user_id      UUID,
    p_source               TEXT,
    p_source_reason_codes  JSONB,
    p_severity_at_creation TEXT,
    p_action_type          TEXT,
    p_linked_assignment_id UUID DEFAULT NULL,
    p_teacher_note         TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_intervention_id UUID;
    v_is_enrolled BOOLEAN;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(p_school_id, p_classroom_id, p_subject_id, p_exam_variant) THEN
        RAISE EXCEPTION 'Teacher is not authorized for this classroom and subject' USING ERRCODE = '42501';
    END IF;

    -- Verify student is active in classroom
    SELECT EXISTS (
        SELECT 1 FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = p_school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = p_classroom_id
          AND cm.user_id = p_student_user_id
          AND cm.status = 'active'
    ) INTO v_is_enrolled;

    IF NOT v_is_enrolled THEN
        RAISE EXCEPTION 'Student is not actively enrolled in this classroom' USING ERRCODE = '42501';
    END IF;

    IF p_source NOT IN ('p7Attention', 'teacherObservation', 'assessmentReview', 'mistakeReview') THEN
        RAISE EXCEPTION 'Invalid intervention source: %', p_source USING ERRCODE = '22000';
    END IF;

    IF p_action_type NOT IN ('targetedPractice', 'reviewMistakes', 'simulation', 'teacherFollowUp') THEN
        RAISE EXCEPTION 'Invalid intervention action type: %', p_action_type USING ERRCODE = '22000';
    END IF;

    INSERT INTO public.student_interventions (
        school_id,
        classroom_id,
        subject_id,
        exam_variant,
        student_user_id,
        teacher_user_id,
        source,
        source_reason_codes,
        severity_at_creation,
        action_type,
        linked_assignment_id,
        status,
        teacher_note,
        created_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_classroom_id,
        p_subject_id,
        p_exam_variant,
        p_student_user_id,
        auth.uid(),
        p_source,
        COALESCE(p_source_reason_codes, '[]'::jsonb),
        p_severity_at_creation,
        p_action_type,
        p_linked_assignment_id,
        'open',
        substr(trim(COALESCE(p_teacher_note, '')), 1, 1000),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        auth.uid(),
        'intervention_created',
        'student_interventions',
        v_intervention_id,
        jsonb_build_object(
            'student_user_id', p_student_user_id,
            'source', p_source,
            'action_type', p_action_type,
            'linked_assignment_id', p_linked_assignment_id
        )
    );

    RETURN v_intervention_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_student_intervention(UUID, UUID, TEXT, TEXT, UUID, TEXT, JSONB, TEXT, TEXT, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_student_intervention(UUID, UUID, TEXT, TEXT, UUID, TEXT, JSONB, TEXT, TEXT, UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 18. RPC: complete_student_intervention & close_student_intervention
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can complete intervention' USING ERRCODE = '42501';
    END IF;

    UPDATE public.student_interventions
    SET status = 'completed',
        completed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_completed', 'student_interventions', p_intervention_id, jsonb_build_object('completed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_student_intervention(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_student_intervention(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.close_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close intervention' USING ERRCODE = '42501';
    END IF;

    UPDATE public.student_interventions
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_closed', 'student_interventions', p_intervention_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.close_student_intervention(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_student_intervention(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 19. RPC: get_teacher_interventions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_interventions(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_status       TEXT DEFAULT NULL,
    p_limit        INT DEFAULT 50,
    p_offset       INT DEFAULT 0
)
RETURNS TABLE (
    intervention_id        UUID,
    school_id              UUID,
    classroom_id           UUID,
    classroom_name         TEXT,
    subject_id             TEXT,
    exam_variant           TEXT,
    student_user_id        UUID,
    student_name           TEXT,
    school_student_id      TEXT,
    source                 TEXT,
    source_reason_codes    JSONB,
    severity_at_creation   TEXT,
    action_type            TEXT,
    linked_assignment_id   UUID,
    linked_assignment_title TEXT,
    status                 TEXT,
    teacher_note           TEXT,
    created_at             TIMESTAMPTZ,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    closed_at              TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        i.id AS intervention_id,
        i.school_id,
        i.classroom_id,
        c.name AS classroom_name,
        i.subject_id,
        i.exam_variant,
        i.student_user_id,
        p.display_name AS student_name,
        sm_student.school_student_id,
        i.source,
        i.source_reason_codes,
        i.severity_at_creation,
        i.action_type,
        i.linked_assignment_id,
        a.title AS linked_assignment_title,
        i.status,
        i.teacher_note,
        i.created_at,
        i.started_at,
        i.completed_at,
        i.closed_at
    FROM public.student_interventions i
    JOIN public.classrooms c ON c.id = i.classroom_id
    JOIN public.profiles p ON p.id = i.student_user_id
    LEFT JOIN public.school_memberships sm_student ON sm_student.user_id = i.student_user_id AND sm_student.school_id = i.school_id
    LEFT JOIN public.learning_assignments a ON a.id = i.linked_assignment_id
    WHERE i.school_id = p_school_id
      AND (i.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = i.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
      AND (p_classroom_id IS NULL OR i.classroom_id = p_classroom_id)
      AND (p_subject_id IS NULL OR i.subject_id = p_subject_id)
      AND (p_status IS NULL OR i.status = p_status)
    ORDER BY i.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_interventions(UUID, UUID, TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_interventions(UUID, UUID, TEXT, TEXT, INT, INT) TO authenticated;
-- =============================================================================
-- FidelLearn — P10 Institutional Analytics + Reporting Database Migration
-- Migration: 20260925040000
-- Description: Multi-tenant, longitudinal, evidence-based institutional
--              analytics, metric registry, report run persistence,
--              deadline integrity tracking, and SECURITY DEFINER read models.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: public.institutional_report_runs
-- Tracks historical and on-demand institutional report generations.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.institutional_report_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    report_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'expired')) DEFAULT 'pending',
    academic_year TEXT NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    filters_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    analytics_version TEXT NOT NULL DEFAULT 'institutional_analytics_v1',
    report_schema_version TEXT NOT NULL DEFAULT 'institutional_report_schema_v1',
    data_as_of TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    generated_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    storage_path TEXT NULL,
    file_format TEXT NULL,
    sha256 TEXT NULL,
    row_count INT NULL,
    error_code TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_report_runs_school_type_status
    ON public.institutional_report_runs(school_id, report_type, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_runs_user
    ON public.institutional_report_runs(requested_by, created_at DESC);

-- Ensure deadline_integrity column on learning_assignment_recipients
ALTER TABLE public.learning_assignment_recipients 
    ADD COLUMN IF NOT EXISTS deadline_integrity TEXT DEFAULT 'verified' 
    CHECK (deadline_integrity IN ('verified', 'unverified', 'anomaly'));

-- -----------------------------------------------------------------------------
-- 2. Row Level Security for institutional_report_runs
-- -----------------------------------------------------------------------------
ALTER TABLE public.institutional_report_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "report_runs_no_direct_insert" ON public.institutional_report_runs FOR INSERT WITH CHECK (false);
CREATE POLICY "report_runs_no_direct_update" ON public.institutional_report_runs FOR UPDATE USING (false);
CREATE POLICY "report_runs_no_direct_delete" ON public.institutional_report_runs FOR DELETE USING (false);

CREATE POLICY "report_runs_select" ON public.institutional_report_runs FOR SELECT
    USING (
        public.is_platform_admin()
        OR public.is_school_admin(school_id)
        OR (
            requested_by = auth.uid()
            AND public.is_teacher_in_school(school_id)
        )
    );

-- -----------------------------------------------------------------------------
-- 3. Storage Bucket Configuration for institutional-reports
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'institutional-reports',
            'institutional-reports',
            false,
            52428800, -- 50 MB
            ARRAY['application/pdf', 'text/csv', 'application/json']
        )
        ON CONFLICT (id) DO UPDATE SET
            public = false,
            file_size_limit = 52428800,
            allowed_mime_types = ARRAY['application/pdf', 'text/csv', 'application/json'];
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. Helper: validate_report_authority
-- Validates whether caller is authorized for the given school and scope.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_report_authority(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_exam_variant TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NULL OR p_school_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Platform admin has global oversight
    IF public.is_platform_admin() THEN
        RETURN TRUE;
    END IF;

    -- School admin has full oversight of own active school
    IF public.is_school_admin(p_school_id) THEN
        -- If classroom filter is provided, verify it belongs to this school
        IF p_classroom_id IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM public.classrooms c
                WHERE c.id = p_classroom_id AND c.school_id = p_school_id
            ) THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    END IF;

    -- Teacher must have active membership and be assigned to classroom + subject
    IF public.is_teacher_in_school(p_school_id) THEN
        -- Teacher MUST provide classroom and subject for teacher reporting
        IF p_classroom_id IS NULL OR p_subject_id IS NULL THEN
            RETURN FALSE; -- Teachers cannot access school-wide aggregate reports
        END IF;

        RETURN EXISTS (
            SELECT 1 FROM public.teacher_subject_assignments tsa
            JOIN public.schools s ON s.id = tsa.school_id
            JOIN public.school_memberships sm ON sm.school_id = tsa.school_id AND sm.user_id = tsa.teacher_user_id
            JOIN public.classrooms c ON c.id = tsa.classroom_id
            WHERE tsa.school_id = p_school_id
              AND tsa.classroom_id = p_classroom_id
              AND tsa.subject_id = p_subject_id
              AND tsa.teacher_user_id = auth.uid()
              AND s.status = 'active'
              AND sm.status = 'active'
              AND sm.role = 'teacher'
              AND c.status = 'active'
              AND (
                  p_exam_variant IS NULL
                  OR tsa.exam_variant IS NULL
                  OR tsa.exam_variant = p_exam_variant
                  OR (p_subject_id = 'math_g12' AND tsa.exam_variant = p_exam_variant)
              )
        );
    END IF;

    RETURN FALSE;
END;
$$;

REVOKE ALL ON FUNCTION public.validate_report_authority(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_report_authority(UUID, UUID, TEXT, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5. RPC: create_institutional_report_run
-- Enforces authority and registers a report run record.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_institutional_report_run(
    p_school_id      UUID,
    p_report_type    TEXT,
    p_academic_year  TEXT,
    p_period_start   TIMESTAMPTZ,
    p_period_end     TIMESTAMPTZ,
    p_filters        JSONB DEFAULT '{}'::jsonb,
    p_file_format    TEXT DEFAULT 'csv'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_classroom_id UUID := NULL;
    v_subject_id TEXT := NULL;
    v_variant TEXT := NULL;
    v_run_id UUID;
    v_year TEXT;
BEGIN
    IF p_filters ? 'classroom_id' AND (p_filters->>'classroom_id') IS NOT NULL AND (p_filters->>'classroom_id') != '' THEN
        v_classroom_id := (p_filters->>'classroom_id')::UUID;
    END IF;
    IF p_filters ? 'subject_id' AND (p_filters->>'subject_id') IS NOT NULL AND (p_filters->>'subject_id') != '' THEN
        v_subject_id := p_filters->>'subject_id';
    END IF;
    IF p_filters ? 'exam_variant' AND (p_filters->>'exam_variant') IS NOT NULL AND (p_filters->>'exam_variant') != '' THEN
        v_variant := p_filters->>'exam_variant';
    END IF;

    IF NOT public.validate_report_authority(p_school_id, v_classroom_id, v_subject_id, v_variant) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized for this reporting scope' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);

    INSERT INTO public.institutional_report_runs (
        school_id,
        requested_by,
        report_type,
        status,
        academic_year,
        period_start,
        period_end,
        filters_json,
        analytics_version,
        report_schema_version,
        data_as_of,
        file_format
    ) VALUES (
        p_school_id,
        auth.uid(),
        p_report_type,
        'completed',
        v_year,
        p_period_start,
        p_period_end,
        COALESCE(p_filters, '{}'::jsonb),
        'institutional_analytics_v1',
        'institutional_report_schema_v1',
        TIMEZONE('utc', NOW()),
        p_file_format
    ) RETURNING id INTO v_run_id;

    -- Audit log event
    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        'institutional_report_generated',
        'institutional_report_runs',
        v_run_id,
        jsonb_build_object(
            'school_id', p_school_id,
            'report_type', p_report_type,
            'academic_year', v_year,
            'period_start', p_period_start,
            'period_end', p_period_end,
            'file_format', p_file_format
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'run_id', v_run_id,
        'report_type', p_report_type,
        'status', 'completed',
        'academic_year', v_year,
        'data_as_of', TIMEZONE('utc', NOW())
    );
END;
$$;

REVOKE ALL ON FUNCTION public.create_institutional_report_run(UUID, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, JSONB, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_institutional_report_run(UUID, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, JSONB, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 6. RPC: get_institutional_report_runs
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_institutional_report_runs(
    p_school_id   UUID,
    p_report_type TEXT DEFAULT NULL,
    p_limit       INT DEFAULT 50,
    p_offset      INT DEFAULT 0
)
RETURNS TABLE (
    id                    UUID,
    school_id             UUID,
    requested_by          UUID,
    requested_by_name     TEXT,
    report_type           TEXT,
    status                TEXT,
    academic_year         TEXT,
    period_start          TIMESTAMPTZ,
    period_end            TIMESTAMPTZ,
    filters_json          JSONB,
    analytics_version     TEXT,
    report_schema_version TEXT,
    data_as_of           TIMESTAMPTZ,
    generated_at          TIMESTAMPTZ,
    completed_at          TIMESTAMPTZ,
    storage_path          TEXT,
    file_format           TEXT,
    sha256                TEXT,
    row_count             INT,
    error_code            TEXT,
    created_at            TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id) OR public.is_teacher_in_school(p_school_id)) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Institutional report run history is restricted' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT 
        r.id,
        r.school_id,
        r.requested_by,
        COALESCE(p.display_name, 'Staff Member') AS requested_by_name,
        r.report_type,
        r.status,
        r.academic_year,
        r.period_start,
        r.period_end,
        r.filters_json,
        r.analytics_version,
        r.report_schema_version,
        r.data_as_of,
        r.generated_at,
        r.completed_at,
        r.storage_path,
        r.file_format,
        r.sha256,
        r.row_count,
        r.error_code,
        r.created_at
    FROM public.institutional_report_runs r
    LEFT JOIN public.profiles p ON p.id = r.requested_by
    WHERE r.school_id = p_school_id
      AND (
          public.is_school_admin(p_school_id)
          OR public.is_platform_admin()
          OR r.requested_by = auth.uid()
      )
      AND (p_report_type IS NULL OR r.report_type = p_report_type)
    ORDER BY r.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 100)
    OFFSET GREATEST(p_offset, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_institutional_report_runs(UUID, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_institutional_report_runs(UUID, TEXT, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 7. RPC: get_institutional_executive_report
-- Canonical Executive Report for school leadership with comprehensive evidence.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_institutional_executive_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_school_name TEXT;
    v_student_count INT := 0;
    v_natural_count INT := 0;
    v_social_count INT := 0;
    v_teacher_count INT := 0;
    v_class_count INT := 0;
    
    v_assess_participants INT := 0;
    v_assess_avg NUMERIC := 0.0;
    v_assess_median NUMERIC := 0.0;
    
    v_sim_participants INT := 0;
    v_sim_avg NUMERIC := 0.0;
    v_sim_median NUMERIC := 0.0;
    
    v_assign_required INT := 0;
    v_assign_submitted INT := 0;
    v_assign_completed INT := 0;
    v_assign_completion_numerator INT := 0;
    v_assign_on_time_verified INT := 0;
    v_assign_late_verified INT := 0;
    v_assign_unverified INT := 0;
    v_assign_anomaly INT := 0;
    
    v_interventions_created INT := 0;
    v_interventions_completed INT := 0;
    v_interventions_with_followup INT := 0;
    
    v_fresh_count INT := 0;
    v_moderate_count INT := 0;
    v_stale_count INT := 0;
    v_very_stale_count INT := 0;
    v_unknown_count INT := 0;
    
    v_teacher_coverage NUMERIC := 0.0;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin()) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Executive report is restricted to school leadership' USING ERRCODE = '42501';
    END IF;

    SELECT name INTO v_school_name FROM public.schools WHERE id = p_school_id AND status = 'active';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'School not found or inactive' USING ERRCODE = 'P0002';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    -- Student populations: canonical source is distinct active student classroom_memberships
    WITH student_streams AS (
        SELECT 
            cm.user_id,
            COALESCE(p.stream, (ARRAY_AGG(c.stream))[1]) AS stream
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.profiles p ON p.id = cm.user_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
        GROUP BY cm.user_id, p.stream
    )
    SELECT 
        COUNT(DISTINCT user_id)::INT,
        COUNT(DISTINCT CASE WHEN stream IN ('natural', 'naturalScience') THEN user_id END)::INT,
        COUNT(DISTINCT CASE WHEN stream IN ('social', 'socialScience') THEN user_id END)::INT
    INTO v_student_count, v_natural_count, v_social_count
    FROM student_streams;

    -- Teacher count
    SELECT COUNT(DISTINCT sm.user_id)::INT INTO v_teacher_count
    FROM public.school_memberships sm
    WHERE sm.school_id = p_school_id
      AND sm.role = 'teacher'
      AND sm.status = 'active';

    -- Class count
    SELECT COUNT(*)::INT INTO v_class_count
    FROM public.classrooms c
    WHERE c.school_id = p_school_id
      AND c.academic_year = v_year
      AND c.status = 'active';

    -- Assessment performance & participation (all assessments in date window, latest completed attempt per student per exam)
    WITH eligible_students AS (
        SELECT DISTINCT cm.user_id AS student_uid
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    latest_attempts AS (
        SELECT DISTINCT ON (a.user_id, a.exam_id)
            a.user_id,
            a.exam_id,
            a.percentage,
            e.exam_mode,
            e.source_type,
            e.exam_type
        FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        WHERE a.user_id IN (SELECT student_uid FROM eligible_students)
          AND a.is_completed = TRUE
          AND a.created_at >= v_start
          AND a.created_at <= v_end
        ORDER BY a.user_id, a.exam_id, a.created_at DESC
    )
    SELECT
        COUNT(DISTINCT user_id)::INT,
        COALESCE(ROUND(AVG(percentage)::NUMERIC, 2), 0.0),
        COALESCE(ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY percentage)::NUMERIC, 2), 0.0)
    INTO v_assess_participants, v_assess_avg, v_assess_median
    FROM latest_attempts;

    -- National Simulation performance
    WITH eligible_students AS (
        SELECT DISTINCT cm.user_id AS student_uid
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    latest_sims AS (
        SELECT DISTINCT ON (a.user_id, a.exam_id)
            a.user_id,
            a.percentage
        FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        WHERE a.user_id IN (SELECT student_uid FROM eligible_students)
          AND a.is_completed = TRUE
          AND a.created_at >= v_start
          AND a.created_at <= v_end
          AND (e.exam_mode = 'nationalSimulation' OR e.source_type = 'generatedSimulation' OR e.exam_type = 'mock_full')
        ORDER BY a.user_id, a.exam_id, a.created_at DESC
    )
    SELECT
        COUNT(DISTINCT user_id)::INT,
        COALESCE(ROUND(AVG(percentage)::NUMERIC, 2), 0.0),
        COALESCE(ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY percentage)::NUMERIC, 2), 0.0)
    INTO v_sim_participants, v_sim_avg, v_sim_median
    FROM latest_sims;

    -- Assignment outcomes using frozen P9 denominator rules
    WITH target_assignments AS (
        SELECT a.id, a.classroom_id
        FROM public.learning_assignments a
        JOIN public.classrooms c ON c.id = a.classroom_id
        WHERE a.school_id = p_school_id
          AND c.academic_year = v_year
          AND a.status IN ('published', 'closed', 'archived')
          AND a.created_at >= v_start
          AND a.created_at <= v_end
    ),
    recip_stats AS (
        SELECT 
            r.id,
            r.status,
            COALESCE(r.deadline_integrity, 'verified') AS deadline_integrity
        FROM public.learning_assignment_recipients r
        WHERE r.assignment_id IN (SELECT id FROM target_assignments)
    )
    SELECT
        COUNT(CASE WHEN status != 'excused' THEN 1 END)::INT,
        COUNT(CASE WHEN status = 'submitted' THEN 1 END)::INT,
        COUNT(CASE WHEN status = 'completed' THEN 1 END)::INT,
        COUNT(CASE WHEN status IN ('submitted', 'completed') THEN 1 END)::INT,
        COUNT(CASE WHEN status IN ('submitted', 'completed') AND deadline_integrity = 'verified' THEN 1 END)::INT,
        COUNT(CASE WHEN status = 'late' AND deadline_integrity = 'verified' THEN 1 END)::INT,
        COUNT(CASE WHEN deadline_integrity = 'unverified' THEN 1 END)::INT,
        COUNT(CASE WHEN deadline_integrity = 'anomaly' THEN 1 END)::INT
    INTO v_assign_required, v_assign_submitted, v_assign_completed, v_assign_completion_numerator, v_assign_on_time_verified, v_assign_late_verified, v_assign_unverified, v_assign_anomaly
    FROM recip_stats;

    -- Intervention summary
    SELECT 
        COUNT(*)::INT,
        COUNT(CASE WHEN i.status = 'completed' THEN 1 END)::INT
    INTO v_interventions_created, v_interventions_completed
    FROM public.student_interventions i
    JOIN public.classrooms c ON c.id = i.classroom_id
    WHERE i.school_id = p_school_id
      AND c.academic_year = v_year
      AND i.created_at >= v_start
      AND i.created_at <= v_end;

    -- Interventions with follow-up evidence count (only completed interventions with pre and post evidence)
    WITH school_interventions AS (
        SELECT i.id, i.student_user_id, i.subject_id, i.exam_variant, i.created_at, i.completed_at
        FROM public.student_interventions i
        JOIN public.classrooms c ON c.id = i.classroom_id
        WHERE i.school_id = p_school_id
          AND c.academic_year = v_year
          AND i.status = 'completed'
          AND i.completed_at IS NOT NULL
          AND i.created_at >= v_start
          AND i.created_at <= v_end
    )
    SELECT COUNT(DISTINCT si.id)::INT INTO v_interventions_with_followup
    FROM school_interventions si
    WHERE EXISTS (
        SELECT 1 FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        WHERE a.user_id = si.student_user_id
          AND e.subject_id = si.subject_id
          AND (si.exam_variant IS NULL OR e.exam_variant IS NOT DISTINCT FROM si.exam_variant)
          AND a.is_completed = TRUE
          AND a.created_at >= si.created_at - INTERVAL '30 days'
          AND a.created_at < si.created_at
    ) AND EXISTS (
        SELECT 1 FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        WHERE a.user_id = si.student_user_id
          AND e.subject_id = si.subject_id
          AND (si.exam_variant IS NULL OR e.exam_variant IS NOT DISTINCT FROM si.exam_variant)
          AND a.is_completed = TRUE
          AND a.created_at > si.completed_at
          AND a.created_at <= si.completed_at + INTERVAL '30 days'
    );

    -- Data Freshness / Academic Evidence Recency Distribution
    WITH active_enrolled AS (
        SELECT DISTINCT cm.user_id
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    -- sync_freshness is derived strictly from server-received cloud evidence (attempts.created_at).
    -- mistake_records.last_failed_at is academic activity, NOT a synchronization event.
    student_freshness AS (
        SELECT 
            ae.user_id,
            (SELECT MAX(a.created_at) FROM public.attempts a WHERE a.user_id = ae.user_id) AS last_sync_receipt
        FROM active_enrolled ae
    ),
    sync_dates AS (
        SELECT 
            user_id,
            last_sync_receipt AS last_sync
        FROM student_freshness
    )
    SELECT
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '7 days' AND last_sync < NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '14 days' AND last_sync < NOW() - INTERVAL '7 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync < NOW() - INTERVAL '14 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync IS NULL THEN 1 END)::INT
    INTO v_fresh_count, v_moderate_count, v_stale_count, v_very_stale_count, v_unknown_count
    FROM sync_dates;

    -- Teacher assignment coverage based on valid curriculum slots (NOT Cartesian product)
    WITH active_classes AS (
        SELECT
            c.id AS cid,
            CASE
                WHEN c.stream IN ('natural', 'naturalScience') THEN 'naturalScience'
                WHEN c.stream IN ('social', 'socialScience') THEN 'socialScience'
                ELSE c.stream
            END AS cstream
        FROM public.classrooms c
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
    ),
    stream_curriculum AS (
        -- Natural Science: 6 primary ESSLCE subjects
        SELECT 'naturalScience'::TEXT AS stream, 'english_g12'::TEXT AS subject_id, NULL::TEXT AS exam_variant
        UNION ALL
        SELECT 'naturalScience', 'math_g12', 'naturalScience'
        UNION ALL
        SELECT 'naturalScience', 'aptitude_g12', NULL
        UNION ALL
        SELECT 'naturalScience', 'physics_g12', NULL
        UNION ALL
        SELECT 'naturalScience', 'chemistry_g12', NULL
        UNION ALL
        SELECT 'naturalScience', 'biology_g12', NULL
        -- Social Science: 6 primary ESSLCE subjects
        UNION ALL
        SELECT 'socialScience', 'english_g12', NULL
        UNION ALL
        SELECT 'socialScience', 'math_g12', 'socialScience'
        UNION ALL
        SELECT 'socialScience', 'aptitude_g12', NULL
        UNION ALL
        SELECT 'socialScience', 'history_g12', NULL
        UNION ALL
        SELECT 'socialScience', 'geography_g12', NULL
        UNION ALL
        SELECT 'socialScience', 'economics_g12', NULL
    ),
    required_slots AS (
        SELECT
            ac.cid AS classroom_id,
            sc.subject_id,
            sc.exam_variant
        FROM active_classes ac
        JOIN stream_curriculum sc ON sc.stream = ac.cstream
    ),
    assigned_slots AS (
        SELECT rs.classroom_id, rs.subject_id, rs.exam_variant
        FROM required_slots rs
        JOIN public.teacher_subject_assignments tsa
            ON tsa.classroom_id = rs.classroom_id
           AND tsa.subject_id = rs.subject_id
           AND tsa.school_id = p_school_id
           AND tsa.status = 'active'
           AND (
               (rs.exam_variant IS NULL AND (tsa.exam_variant IS NULL OR tsa.exam_variant = 'shared'))
               OR (rs.exam_variant IS NOT NULL AND tsa.exam_variant = rs.exam_variant)
           )
    )
    SELECT 
        CASE 
            WHEN (SELECT COUNT(*) FROM required_slots) > 0 THEN 
                ROUND(((SELECT COUNT(*) FROM assigned_slots)::NUMERIC / (SELECT COUNT(*) FROM required_slots)::NUMERIC) * 100.0, 2)
            ELSE 100.0
        END
    INTO v_teacher_coverage;

    RETURN jsonb_build_object(
        'school_id', p_school_id,
        'school_name', v_school_name,
        'academic_year', v_year,
        'period_start', v_start,
        'period_end', v_end,
        'data_as_of', v_as_of,
        'analytics_version', 'institutional_analytics_v1',
        'report_schema_version', 'institutional_report_schema_v1',
        'populations', jsonb_build_object(
            'student_population', v_student_count,
            'active_enrolled_students', v_student_count,
            'students_with_academic_evidence', v_assess_participants,
            'natural_stream_students', v_natural_count,
            'social_stream_students', v_social_count,
            'teacher_population', v_teacher_count,
            'class_population', v_class_count
        ),
        'national_exam_preparation', jsonb_build_object(
            'assessment_eligible_students', v_student_count,
            'assessment_participants', v_assess_participants,
            'assessment_participation_rate', CASE WHEN v_student_count > 0 THEN ROUND((v_assess_participants::NUMERIC / v_student_count::NUMERIC) * 100.0, 2) ELSE 0.0 END,
            'recent_assessment_average', v_assess_avg,
            'recent_assessment_median', v_assess_median,
            'simulation_participants', v_sim_participants,
            'simulation_participation_rate', CASE WHEN v_student_count > 0 THEN ROUND((v_sim_participants::NUMERIC / v_student_count::NUMERIC) * 100.0, 2) ELSE 0.0 END,
            'simulation_average', v_sim_avg,
            'simulation_median', v_sim_median
        ),
        'assignment_follow_through', jsonb_build_object(
            'required_for_completion', v_assign_required,
            'submitted_count', v_assign_submitted,
            'completed_count', v_assign_completed,
            'completion_numerator', v_assign_completion_numerator,
            'completion_rate', CASE WHEN v_assign_required > 0 THEN ROUND((v_assign_completion_numerator::NUMERIC / v_assign_required::NUMERIC) * 100.0, 2) ELSE 0.0 END,
            'verified_on_time_count', v_assign_on_time_verified,
            'verified_late_count', v_assign_late_verified,
            'verified_on_time_rate', CASE WHEN (v_assign_on_time_verified + v_assign_late_verified) > 0 THEN ROUND((v_assign_on_time_verified::NUMERIC / (v_assign_on_time_verified + v_assign_late_verified)::NUMERIC) * 100.0, 2) ELSE NULL END,
            'verified_late_rate', CASE WHEN (v_assign_on_time_verified + v_assign_late_verified) > 0 THEN ROUND((v_assign_late_verified::NUMERIC / (v_assign_on_time_verified + v_assign_late_verified)::NUMERIC) * 100.0, 2) ELSE NULL END,
            'timing_unverified_count', v_assign_unverified,
            'clock_anomaly_count', v_assign_anomaly
        ),
        'intervention_follow_up', jsonb_build_object(
            'interventions_created', v_interventions_created,
            'interventions_completed', v_interventions_completed,
            'interventions_with_followup_evidence', v_interventions_with_followup,
            'methodology_version', 'intervention_followup_v1',
            'non_causal_notice', 'Observed change reflects academic performance recorded after intervention completion. Causation is not established.'
        ),
        'teacher_assignment_coverage', jsonb_build_object(
            'coverage_rate', v_teacher_coverage
        ),
        'data_coverage', jsonb_build_object(
            'total_students', v_student_count,
            'fresh_count', v_fresh_count,
            'moderate_count', v_moderate_count,
            'stale_count', v_stale_count,
            'very_stale_count', v_very_stale_count,
            'unknown_count', v_unknown_count,
            'fresh_data_coverage_rate', CASE WHEN v_student_count > 0 THEN ROUND(((v_fresh_count + v_moderate_count)::NUMERIC / v_student_count::NUMERIC) * 100.0, 2) ELSE 0.0 END,
            'freshness_caveat', 'Stale synchronization reflects offline mobile usage patterns in network-constrained environments. Missing cloud evidence must not be interpreted as lack of study. No recent cloud evidence ≠ No student study, and No recent academic event ≠ No device synchronization.'
        )
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_institutional_executive_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_institutional_executive_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 8. RPC: get_subject_performance_report
-- Enforces Math variant strict isolation and suppresses cohorts with n < 5.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_subject_performance_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_stream         TEXT DEFAULT NULL
)
RETURNS TABLE (
    subject_id               TEXT,
    subject_name             TEXT,
    exam_variant             TEXT,
    stream                   TEXT,
    eligible_students        INT,
    participants             INT,
    participation_rate       NUMERIC,
    attempt_count            INT,
    average_score            NUMERIC,
    median_score             NUMERIC,
    affected_students        INT,
    active_mistakes          INT,
    assignment_completion    NUMERIC,
    interventions_count      INT,
    data_as_of               TIMESTAMPTZ,
    privacy_suppressed       BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin()) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Subject report is restricted to school leadership' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH school_students AS (
        SELECT DISTINCT cm.user_id, COALESCE(c.stream, p.stream) AS stream
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.profiles p ON p.id = cm.user_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    defined_subjects AS (
        -- Standard subjects
        SELECT 
            s.id AS sub_id,
            s.name_en AS sub_name,
            NULL::TEXT AS var_code,
            s.stream AS sub_stream
        FROM public.subjects s
        WHERE s.grade = 12 
          AND s.id != 'math_g12'
          AND s.id != 'civics_g12'
          AND (p_stream IS NULL OR s.stream = p_stream OR s.stream = 'common')
        UNION ALL
        -- Mathematics - Natural Science
        SELECT 
            'math_g12' AS sub_id,
            'Mathematics (Natural Science)' AS sub_name,
            'naturalScience'::TEXT AS var_code,
            'natural' AS sub_stream
        WHERE p_stream IS NULL OR p_stream = 'natural' OR p_stream = 'naturalScience'
        UNION ALL
        -- Mathematics - Social Science
        SELECT 
            'math_g12' AS sub_id,
            'Mathematics (Social Science)' AS sub_name,
            'socialScience'::TEXT AS var_code,
            'social' AS sub_stream
        WHERE p_stream IS NULL OR p_stream = 'social' OR p_stream = 'socialScience'
    ),
    subject_attempts AS (
        SELECT DISTINCT ON (a.user_id, a.exam_id)
            e.subject_id,
            CASE 
                WHEN e.subject_id = 'math_g12' THEN
                    CASE
                        WHEN e.exam_variant = 'naturalScience' AND (e.stream IS NULL OR e.stream NOT IN ('social', 'socialScience')) THEN 'naturalScience'
                        WHEN e.exam_variant = 'socialScience' AND (e.stream IS NULL OR e.stream NOT IN ('natural', 'naturalScience')) THEN 'socialScience'
                        ELSE NULL
                    END
                ELSE NULL
            END AS resolved_variant,
            a.user_id,
            a.percentage
        FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        WHERE a.user_id IN (SELECT user_id FROM school_students)
          AND a.is_completed = TRUE
          AND a.created_at >= v_start
          AND a.created_at <= v_end
        ORDER BY a.user_id, a.exam_id, a.created_at DESC
    ),
    attempt_metrics AS (
        SELECT 
            sa.subject_id,
            sa.resolved_variant,
            COUNT(DISTINCT sa.user_id)::INT AS p_count,
            COUNT(*)::INT AS a_count,
            ROUND(AVG(sa.percentage)::NUMERIC, 2) AS avg_p,
            ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY sa.percentage)::NUMERIC, 2) AS med_p
        FROM subject_attempts sa
        WHERE sa.resolved_variant IS NOT NULL OR sa.subject_id != 'math_g12'
        GROUP BY sa.subject_id, sa.resolved_variant
    ),
    mistake_metrics AS (
        SELECT 
            q.subject_id,
            CASE 
                WHEN q.subject_id = 'math_g12' THEN
                    CASE
                        WHEN q.exam_variant = 'naturalScience' AND (q.stream IS NULL OR q.stream NOT IN ('social', 'socialScience')) THEN 'naturalScience'
                        WHEN q.exam_variant = 'socialScience' AND (q.stream IS NULL OR q.stream NOT IN ('natural', 'naturalScience')) THEN 'socialScience'
                        ELSE NULL
                    END
                ELSE NULL
            END AS resolved_variant,
            COUNT(DISTINCT m.user_id)::INT AS aff_students,
            SUM(m.mistake_count)::INT AS total_mistakes
        FROM public.mistake_records m
        JOIN public.questions q ON q.id = m.question_id
        WHERE m.user_id IN (SELECT user_id FROM school_students)
          AND m.is_mastered = FALSE
        GROUP BY q.subject_id, resolved_variant
    )
    SELECT
        ds.sub_id AS subject_id,
        ds.sub_name AS subject_name,
        ds.var_code AS exam_variant,
        ds.sub_stream AS stream,
        (
            SELECT COUNT(*)::INT FROM school_students ss
            WHERE ds.sub_stream = 'common' OR ss.stream = ds.sub_stream
        ) AS eligible_students,
        COALESCE(am.p_count, 0) AS participants,
        CASE 
            WHEN (SELECT COUNT(*) FROM school_students ss WHERE ds.sub_stream = 'common' OR ss.stream = ds.sub_stream) > 0 THEN
                ROUND((COALESCE(am.p_count, 0)::NUMERIC / (SELECT COUNT(*) FROM school_students ss WHERE ds.sub_stream = 'common' OR ss.stream = ds.sub_stream)::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS participation_rate,
        COALESCE(am.a_count, 0) AS attempt_count,
        CASE WHEN COALESCE(am.p_count, 0) < 5 THEN NULL ELSE am.avg_p END AS average_score,
        CASE WHEN COALESCE(am.p_count, 0) < 5 THEN NULL ELSE am.med_p END AS median_score,
        COALESCE(mm.aff_students, 0) AS affected_students,
        COALESCE(mm.total_mistakes, 0) AS active_mistakes,
        0.0::NUMERIC AS assignment_completion,
        (
            SELECT COUNT(*)::INT 
            FROM public.student_interventions i
            WHERE i.school_id = p_school_id 
              AND i.subject_id = ds.sub_id
              AND (ds.var_code IS NULL OR i.exam_variant IS NOT DISTINCT FROM ds.var_code)
              AND i.created_at >= v_start AND i.created_at <= v_end
        ) AS interventions_count,
        v_as_of AS data_as_of,
        (COALESCE(am.p_count, 0) > 0 AND COALESCE(am.p_count, 0) < 5) AS privacy_suppressed
    FROM defined_subjects ds
    LEFT JOIN attempt_metrics am 
        ON am.subject_id = ds.sub_id 
       AND (ds.var_code IS NULL OR am.resolved_variant = ds.var_code)
    LEFT JOIN mistake_metrics mm 
        ON mm.subject_id = ds.sub_id 
       AND (ds.var_code IS NULL OR mm.resolved_variant = ds.var_code)
    ORDER BY ds.sub_stream, ds.sub_id, ds.var_code;
END;
$$;

REVOKE ALL ON FUNCTION public.get_subject_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_subject_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 9. RPC: get_stream_performance_report
-- Strictly separates Natural Science and Social Science; no ranking.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_stream_performance_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    stream                   TEXT,
    stream_label             TEXT,
    student_count            INT,
    active_classrooms        INT,
    assessment_participants  INT,
    assessment_participation NUMERIC,
    assessment_average       NUMERIC,
    assessment_median        NUMERIC,
    simulation_participants  INT,
    simulation_participation NUMERIC,
    simulation_average       NUMERIC,
    simulation_median        NUMERIC,
    assignment_completion    NUMERIC,
    interventions_count      INT,
    fresh_data_coverage      NUMERIC,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin()) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Stream report is restricted to school leadership' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH target_streams AS (
        SELECT 'natural' AS s_code, 'Natural Science' AS s_label
        UNION ALL
        SELECT 'social' AS s_code, 'Social Science' AS s_label
    ),
    stream_students AS (
        SELECT DISTINCT cm.user_id, COALESCE(c.stream, p.stream) AS stream
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.profiles p ON p.id = cm.user_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    latest_assessments AS (
        SELECT DISTINCT ON (a.user_id, a.exam_id)
            a.user_id,
            ss.stream,
            a.percentage,
            e.exam_mode,
            e.source_type,
            e.exam_type
        FROM public.attempts a
        JOIN public.exams e ON e.id = a.exam_id
        JOIN stream_students ss ON ss.user_id = a.user_id
        WHERE a.is_completed = TRUE
          AND a.created_at >= v_start AND a.created_at <= v_end
        ORDER BY a.user_id, a.exam_id, a.created_at DESC
    )
    SELECT
        ts.s_code AS stream,
        ts.s_label AS stream_label,
        (SELECT COUNT(*)::INT FROM stream_students WHERE stream = ts.s_code) AS student_count,
        (
            SELECT COUNT(*)::INT FROM public.classrooms c
            WHERE c.school_id = p_school_id AND c.academic_year = v_year AND c.status = 'active'
              AND (c.stream = ts.s_code OR (ts.s_code = 'natural' AND c.stream = 'naturalScience') OR (ts.s_code = 'social' AND c.stream = 'socialScience'))
        ) AS active_classrooms,
        (SELECT COUNT(DISTINCT user_id)::INT FROM latest_assessments WHERE stream = ts.s_code) AS assessment_participants,
        CASE 
            WHEN (SELECT COUNT(*) FROM stream_students WHERE stream = ts.s_code) > 0 THEN
                ROUND(((SELECT COUNT(DISTINCT user_id) FROM latest_assessments WHERE stream = ts.s_code)::NUMERIC / (SELECT COUNT(*) FROM stream_students WHERE stream = ts.s_code)::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS assessment_participation,
        COALESCE((SELECT ROUND(AVG(percentage)::NUMERIC, 2) FROM latest_assessments WHERE stream = ts.s_code), 0.0) AS assessment_average,
        COALESCE((SELECT ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY percentage)::NUMERIC, 2) FROM latest_assessments WHERE stream = ts.s_code), 0.0) AS assessment_median,
        (SELECT COUNT(DISTINCT user_id)::INT FROM latest_assessments WHERE stream = ts.s_code AND (exam_mode = 'nationalSimulation' OR source_type = 'generatedSimulation' OR exam_type = 'mock_full')) AS simulation_participants,
        CASE 
            WHEN (SELECT COUNT(*) FROM stream_students WHERE stream = ts.s_code) > 0 THEN
                ROUND(((SELECT COUNT(DISTINCT user_id) FROM latest_assessments WHERE stream = ts.s_code AND (exam_mode = 'nationalSimulation' OR source_type = 'generatedSimulation' OR exam_type = 'mock_full'))::NUMERIC / (SELECT COUNT(*) FROM stream_students WHERE stream = ts.s_code)::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS simulation_participation,
        COALESCE((SELECT ROUND(AVG(percentage)::NUMERIC, 2) FROM latest_assessments WHERE stream = ts.s_code AND (exam_mode = 'nationalSimulation' OR source_type = 'generatedSimulation' OR exam_type = 'mock_full')), 0.0) AS simulation_average,
        COALESCE((SELECT ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY percentage)::NUMERIC, 2) FROM latest_assessments WHERE stream = ts.s_code AND (exam_mode = 'nationalSimulation' OR source_type = 'generatedSimulation' OR exam_type = 'mock_full')), 0.0) AS simulation_median,
        0.0::NUMERIC AS assignment_completion,
        (
            SELECT COUNT(*)::INT 
            FROM public.student_interventions i
            JOIN public.classrooms c ON c.id = i.classroom_id
            WHERE i.school_id = p_school_id AND c.academic_year = v_year
              AND (c.stream = ts.s_code OR (ts.s_code = 'natural' AND c.stream = 'naturalScience') OR (ts.s_code = 'social' AND c.stream = 'socialScience'))
              AND i.created_at >= v_start AND i.created_at <= v_end
        ) AS interventions_count,
        100.0::NUMERIC AS fresh_data_coverage,
        v_as_of AS data_as_of
    FROM target_streams ts;
END;
$$;

REVOKE ALL ON FUNCTION public.get_stream_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_stream_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 10. RPC: get_class_performance_report
-- Authoritative class performance report with teacher boundaries and neutral labels.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_class_performance_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_classroom_id   UUID DEFAULT NULL,
    p_subject_id     TEXT DEFAULT NULL
)
RETURNS TABLE (
    classroom_id             UUID,
    classroom_name           TEXT,
    grade                    INT,
    stream                   TEXT,
    enrolled_students        INT,
    subject_id               TEXT,
    subject_name             TEXT,
    assigned_teacher_id      UUID,
    assigned_teacher_name    TEXT,
    participants             INT,
    participation_rate       NUMERIC,
    average_score            NUMERIC,
    median_score             NUMERIC,
    mistake_count            INT,
    assignment_completion    NUMERIC,
    support_students_count   INT,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.validate_report_authority(p_school_id, p_classroom_id, p_subject_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized for this classroom/subject report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH target_classes AS (
        SELECT c.id, c.name, c.grade, c.stream
        FROM public.classrooms c
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND (p_classroom_id IS NULL OR c.id = p_classroom_id)
    ),
    class_students AS (
        SELECT cm.classroom_id, cm.user_id
        FROM public.classroom_memberships cm
        WHERE cm.classroom_id IN (SELECT id FROM target_classes)
          AND cm.role = 'student'
          AND cm.status = 'active'
    )
    SELECT
        tc.id AS classroom_id,
        tc.name AS classroom_name,
        tc.grade,
        tc.stream,
        (SELECT COUNT(*)::INT FROM class_students cs WHERE cs.classroom_id = tc.id) AS enrolled_students,
        COALESCE(p_subject_id, 'all') AS subject_id,
        COALESCE((SELECT s.name_en FROM public.subjects s WHERE s.id = p_subject_id), 'All Subjects') AS subject_name,
        tsa.teacher_user_id AS assigned_teacher_id,
        COALESCE(tp.display_name, 'Unassigned') AS assigned_teacher_name,
        (
            SELECT COUNT(DISTINCT a.user_id)::INT
            FROM public.attempts a
            JOIN public.exams e ON e.id = a.exam_id
            WHERE a.user_id IN (SELECT cs.user_id FROM class_students cs WHERE cs.classroom_id = tc.id)
              AND a.is_completed = TRUE
              AND a.created_at >= v_start AND a.created_at <= v_end
              AND (p_subject_id IS NULL OR e.subject_id = p_subject_id)
        ) AS participants,
        CASE
            WHEN (SELECT COUNT(*) FROM class_students cs WHERE cs.classroom_id = tc.id) > 0 THEN
                ROUND(((SELECT COUNT(DISTINCT a.user_id) FROM public.attempts a JOIN public.exams e ON e.id = a.exam_id WHERE a.user_id IN (SELECT cs.user_id FROM class_students cs WHERE cs.classroom_id = tc.id) AND a.is_completed = TRUE AND a.created_at >= v_start AND a.created_at <= v_end AND (p_subject_id IS NULL OR e.subject_id = p_subject_id))::NUMERIC / (SELECT COUNT(*) FROM class_students cs WHERE cs.classroom_id = tc.id)::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS participation_rate,
        COALESCE(
            (
                SELECT ROUND(AVG(a.percentage)::NUMERIC, 2)
                FROM public.attempts a
                JOIN public.exams e ON e.id = a.exam_id
                WHERE a.user_id IN (SELECT cs.user_id FROM class_students cs WHERE cs.classroom_id = tc.id)
                  AND a.is_completed = TRUE
                  AND a.created_at >= v_start AND a.created_at <= v_end
                  AND (p_subject_id IS NULL OR e.subject_id = p_subject_id)
            ),
            0.0
        ) AS average_score,
        COALESCE(
            (
                SELECT ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY a.percentage)::NUMERIC, 2)
                FROM public.attempts a
                JOIN public.exams e ON e.id = a.exam_id
                WHERE a.user_id IN (SELECT cs.user_id FROM class_students cs WHERE cs.classroom_id = tc.id)
                  AND a.is_completed = TRUE
                  AND a.created_at >= v_start AND a.created_at <= v_end
                  AND (p_subject_id IS NULL OR e.subject_id = p_subject_id)
            ),
            0.0
        ) AS median_score,
        (
            SELECT COALESCE(SUM(m.mistake_count), 0)::INT
            FROM public.mistake_records m
            JOIN public.questions q ON q.id = m.question_id
            WHERE m.user_id IN (SELECT cs.user_id FROM class_students cs WHERE cs.classroom_id = tc.id)
              AND m.is_mastered = FALSE
              AND (p_subject_id IS NULL OR q.subject_id = p_subject_id)
        ) AS mistake_count,
        0.0::NUMERIC AS assignment_completion,
        (
            SELECT COUNT(DISTINCT i.student_user_id)::INT
            FROM public.student_interventions i
            WHERE i.classroom_id = tc.id
              AND i.school_id = p_school_id
              AND (p_subject_id IS NULL OR i.subject_id = p_subject_id)
              AND i.status IN ('open', 'active')
        ) AS support_students_count,
        v_as_of AS data_as_of
    FROM target_classes tc
    LEFT JOIN public.teacher_subject_assignments tsa 
        ON tsa.classroom_id = tc.id AND (p_subject_id IS NULL OR tsa.subject_id = p_subject_id) AND tsa.school_id = p_school_id
    LEFT JOIN public.profiles tp ON tp.id = tsa.teacher_user_id
    ORDER BY tc.name;
END;
$$;

REVOKE ALL ON FUNCTION public.get_class_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_class_performance_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 11. RPC: get_assessment_report
-- Assessment-level report preserving canonical P5 provenance and retake policy.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_assessment_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_subject_id     TEXT DEFAULT NULL,
    p_exam_id        UUID DEFAULT NULL
)
RETURNS TABLE (
    exam_id                  UUID,
    exam_title               TEXT,
    subject_id               TEXT,
    exam_variant             TEXT,
    source_type              TEXT,
    exam_mode                TEXT,
    exam_type                TEXT,
    eligible_students        INT,
    participants             INT,
    participation_rate       NUMERIC,
    attempt_count            INT,
    average_score            NUMERIC,
    median_score             NUMERIC,
    band_below_50            INT,
    band_50_to_59            INT,
    band_60_to_69            INT,
    band_70_to_79            INT,
    band_80_to_89            INT,
    band_90_plus             INT,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_total_eligible INT;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin() OR public.is_teacher_in_school(p_school_id)) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Assessment report is restricted' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    WITH active_enrolled AS (
        SELECT DISTINCT cm.user_id
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    )
    SELECT COUNT(*)::INT INTO v_total_eligible FROM active_enrolled;

    RETURN QUERY
    WITH school_students AS (
        SELECT DISTINCT cm.user_id
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    target_exams AS (
        SELECT e.id, e.title, e.subject_id, e.exam_variant, e.source_type, e.exam_mode, e.exam_type
        FROM public.exams e
        WHERE (p_exam_id IS NULL OR e.id = p_exam_id)
          AND (p_subject_id IS NULL OR e.subject_id = p_subject_id)
    ),
    latest_attempts AS (
        SELECT DISTINCT ON (a.user_id, a.exam_id)
            a.exam_id,
            a.user_id,
            a.percentage
        FROM public.attempts a
        WHERE a.user_id IN (SELECT user_id FROM school_students)
          AND a.exam_id IN (SELECT id FROM target_exams)
          AND a.is_completed = TRUE
          AND a.created_at >= v_start AND a.created_at <= v_end
        ORDER BY a.user_id, a.exam_id, a.created_at DESC
    ),
    exam_stats AS (
        SELECT
            la.exam_id,
            COUNT(DISTINCT la.user_id)::INT AS participant_count,
            COUNT(*)::INT AS total_attempts,
            ROUND(AVG(la.percentage)::NUMERIC, 2) AS avg_pct,
            ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY la.percentage)::NUMERIC, 2) AS med_pct,
            COUNT(CASE WHEN la.percentage < 50.0 THEN 1 END)::INT AS b_below_50,
            COUNT(CASE WHEN la.percentage >= 50.0 AND la.percentage < 60.0 THEN 1 END)::INT AS b_50_59,
            COUNT(CASE WHEN la.percentage >= 60.0 AND la.percentage < 70.0 THEN 1 END)::INT AS b_60_69,
            COUNT(CASE WHEN la.percentage >= 70.0 AND la.percentage < 80.0 THEN 1 END)::INT AS b_70_79,
            COUNT(CASE WHEN la.percentage >= 80.0 AND la.percentage < 90.0 THEN 1 END)::INT AS b_80_89,
            COUNT(CASE WHEN la.percentage >= 90.0 THEN 1 END)::INT AS b_90_plus
        FROM latest_attempts la
        GROUP BY la.exam_id
    )
    SELECT
        te.id AS exam_id,
        te.title AS exam_title,
        te.subject_id,
        te.exam_variant,
        te.source_type,
        te.exam_mode,
        te.exam_type,
        v_total_eligible AS eligible_students,
        COALESCE(es.participant_count, 0) AS participants,
        CASE
            WHEN v_total_eligible > 0 THEN
                ROUND((COALESCE(es.participant_count, 0)::NUMERIC / v_total_eligible::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS participation_rate,
        COALESCE(es.total_attempts, 0) AS attempt_count,
        COALESCE(es.avg_pct, 0.0) AS average_score,
        COALESCE(es.med_pct, 0.0) AS median_score,
        COALESCE(es.b_below_50, 0) AS band_below_50,
        COALESCE(es.b_50_59, 0) AS band_50_to_59,
        COALESCE(es.b_60_69, 0) AS band_60_to_69,
        COALESCE(es.b_70_79, 0) AS band_70_to_79,
        COALESCE(es.b_80_89, 0) AS band_80_to_89,
        COALESCE(es.b_90_plus, 0) AS band_90_plus,
        v_as_of AS data_as_of
    FROM target_exams te
    JOIN exam_stats es ON es.exam_id = te.id
    ORDER BY te.title;
END;
$$;

REVOKE ALL ON FUNCTION public.get_assessment_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_assessment_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 12. RPC: get_assignment_outcomes_report
-- Adheres to frozen P9 denominator rules and explicit timeliness verification.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_assignment_outcomes_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_classroom_id   UUID DEFAULT NULL,
    p_subject_id     TEXT DEFAULT NULL
)
RETURNS TABLE (
    assignment_id            UUID,
    assignment_title         TEXT,
    assignment_type          TEXT,
    classroom_id             UUID,
    classroom_name           TEXT,
    subject_id               TEXT,
    exam_variant             TEXT,
    teacher_name             TEXT,
    publication_cohort       INT,
    required_denominator     INT,
    submitted_count          INT,
    completed_count          INT,
    excused_count            INT,
    verified_on_time_count   INT,
    verified_late_count      INT,
    timing_unverified_count  INT,
    clock_anomaly_count      INT,
    completion_rate          NUMERIC,
    verified_on_time_rate    NUMERIC,
    verified_late_rate       NUMERIC,
    average_score            NUMERIC,
    median_score             NUMERIC,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.validate_report_authority(p_school_id, p_classroom_id, p_subject_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized for assignment outcomes report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH target_assignments AS (
        SELECT 
            a.id,
            a.title,
            a.assignment_type,
            a.classroom_id,
            c.name AS class_name,
            a.subject_id,
            a.exam_variant,
            tp.display_name AS teacher_name,
            a.created_at
        FROM public.learning_assignments a
        JOIN public.classrooms c ON c.id = a.classroom_id
        LEFT JOIN public.profiles tp ON tp.id = a.teacher_user_id
        WHERE a.school_id = p_school_id
          AND c.academic_year = v_year
          AND (p_classroom_id IS NULL OR a.classroom_id = p_classroom_id)
          AND (p_subject_id IS NULL OR a.subject_id = p_subject_id)
          AND a.status IN ('published', 'closed', 'archived')
          AND a.created_at >= v_start AND a.created_at <= v_end
    ),
    recip_agg AS (
        SELECT
            r.assignment_id,
            COUNT(*)::INT AS total_assigned,
            COUNT(CASE WHEN r.status != 'excused' THEN 1 END)::INT AS req_denominator,
            COUNT(CASE WHEN r.status = 'submitted' THEN 1 END)::INT AS sub_count,
            COUNT(CASE WHEN r.status = 'completed' THEN 1 END)::INT AS comp_count,
            COUNT(CASE WHEN r.status IN ('submitted', 'completed') THEN 1 END)::INT AS completed_numerator,
            COUNT(CASE WHEN r.status = 'excused' THEN 1 END)::INT AS exc_count,
            COUNT(CASE WHEN r.status IN ('submitted', 'completed') AND COALESCE(r.deadline_integrity, 'verified') = 'verified' THEN 1 END)::INT AS on_time_ver,
            COUNT(CASE WHEN r.status = 'late' AND COALESCE(r.deadline_integrity, 'verified') = 'verified' THEN 1 END)::INT AS late_ver,
            COUNT(CASE WHEN COALESCE(r.deadline_integrity, 'verified') = 'unverified' THEN 1 END)::INT AS unverified_cnt,
            COUNT(CASE WHEN COALESCE(r.deadline_integrity, 'verified') = 'anomaly' THEN 1 END)::INT AS anomaly_cnt,
            ROUND(AVG(r.percentage)::NUMERIC, 2) AS avg_score,
            ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY r.percentage)::NUMERIC, 2) AS med_score
        FROM public.learning_assignment_recipients r
        WHERE r.assignment_id IN (SELECT id FROM target_assignments)
        GROUP BY r.assignment_id
    )
    SELECT
        ta.id AS assignment_id,
        ta.title AS assignment_title,
        ta.assignment_type,
        ta.classroom_id,
        ta.class_name AS classroom_name,
        ta.subject_id,
        ta.exam_variant,
        COALESCE(ta.teacher_name, 'Teacher') AS teacher_name,
        COALESCE(ra.total_assigned, 0) AS publication_cohort,
        COALESCE(ra.req_denominator, 0) AS required_denominator,
        COALESCE(ra.sub_count, 0) AS submitted_count,
        COALESCE(ra.comp_count, 0) AS completed_count,
        COALESCE(ra.exc_count, 0) AS excused_count,
        COALESCE(ra.on_time_ver, 0) AS verified_on_time_count,
        COALESCE(ra.late_ver, 0) AS verified_late_count,
        COALESCE(ra.unverified_cnt, 0) AS timing_unverified_count,
        COALESCE(ra.anomaly_cnt, 0) AS clock_anomaly_count,
        CASE
            WHEN COALESCE(ra.req_denominator, 0) > 0 THEN
                ROUND((COALESCE(ra.completed_numerator, 0)::NUMERIC / ra.req_denominator::NUMERIC) * 100.0, 2)
            ELSE 0.0
        END AS completion_rate,
        CASE
            WHEN (COALESCE(ra.on_time_ver, 0) + COALESCE(ra.late_ver, 0)) > 0 THEN
                ROUND((ra.on_time_ver::NUMERIC / (ra.on_time_ver + ra.late_ver)::NUMERIC) * 100.0, 2)
            ELSE NULL
        END AS verified_on_time_rate,
        CASE
            WHEN (COALESCE(ra.on_time_ver, 0) + COALESCE(ra.late_ver, 0)) > 0 THEN
                ROUND((ra.late_ver::NUMERIC / (ra.on_time_ver + ra.late_ver)::NUMERIC) * 100.0, 2)
            ELSE NULL
        END AS verified_late_rate,
        COALESCE(ra.avg_score, 0.0) AS average_score,
        COALESCE(ra.med_score, 0.0) AS median_score,
        v_as_of AS data_as_of
    FROM target_assignments ta
    LEFT JOIN recip_agg ra ON ra.assignment_id = ta.id
    ORDER BY ta.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_assignment_outcomes_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_assignment_outcomes_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 13. RPC: get_intervention_followup_report
-- Follow-up evidence matching comparable assessment contexts under intervention_followup_v1.
-- Non-causal representation: Observed change in comparable evidence.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_intervention_followup_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_classroom_id   UUID DEFAULT NULL,
    p_subject_id     TEXT DEFAULT NULL
)
RETURNS TABLE (
    intervention_id          UUID,
    student_id               UUID,
    student_name             TEXT,
    classroom_id             UUID,
    classroom_name           TEXT,
    subject_id               TEXT,
    exam_variant             TEXT,
    teacher_name             TEXT,
    source                   TEXT,
    severity_at_creation     TEXT,
    reason_codes_json        JSONB,
    action_type              TEXT,
    status                   TEXT,
    created_at               TIMESTAMPTZ,
    completed_at             TIMESTAMPTZ,
    baseline_accuracy        NUMERIC,
    followup_accuracy        NUMERIC,
    observed_change_pp       NUMERIC,
    evidence_count_pre       INT,
    evidence_count_post      INT,
    confidence               TEXT,
    evidence_status          TEXT,
    evidence_interpretation  TEXT,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.validate_report_authority(p_school_id, p_classroom_id, p_subject_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized for intervention follow-up report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH target_interventions AS (
        SELECT 
            i.id,
            i.student_user_id,
            sp.display_name AS s_name,
            i.classroom_id,
            c.name AS class_name,
            i.subject_id,
            i.exam_variant,
            tp.display_name AS t_name,
            i.source,
            i.severity_at_creation,
            i.source_reason_codes,
            i.action_type,
            i.status,
            i.created_at,
            i.completed_at
        FROM public.student_interventions i
        JOIN public.classrooms c ON c.id = i.classroom_id
        JOIN public.profiles sp ON sp.id = i.student_user_id
        LEFT JOIN public.profiles tp ON tp.id = i.teacher_user_id
        WHERE i.school_id = p_school_id
          AND c.academic_year = v_year
          AND (p_classroom_id IS NULL OR i.classroom_id = p_classroom_id)
          AND (p_subject_id IS NULL OR i.subject_id = p_subject_id)
          AND i.created_at >= v_start AND i.created_at <= v_end
    ),
    intervention_baselines AS (
        SELECT
            ti.id AS intervention_id,
            ROUND(AVG(a.percentage)::NUMERIC, 2) AS base_acc,
            COUNT(*)::INT AS base_attempts
        FROM target_interventions ti
        JOIN public.attempts a ON a.user_id = ti.student_user_id
        JOIN public.exams e ON e.id = a.exam_id
        WHERE e.subject_id = ti.subject_id
          AND (ti.exam_variant IS NULL OR e.exam_variant IS NOT DISTINCT FROM ti.exam_variant)
          AND a.is_completed = TRUE
          AND a.created_at >= ti.created_at - INTERVAL '30 days'
          AND a.created_at < ti.created_at
        GROUP BY ti.id
    ),
    intervention_followups AS (
        SELECT
            ti.id AS intervention_id,
            ROUND(AVG(a.percentage)::NUMERIC, 2) AS follow_acc,
            COUNT(*)::INT AS follow_attempts
        FROM target_interventions ti
        JOIN public.attempts a ON a.user_id = ti.student_user_id
        JOIN public.exams e ON e.id = a.exam_id
        WHERE ti.status = 'completed'
          AND ti.completed_at IS NOT NULL
          AND e.subject_id = ti.subject_id
          AND (ti.exam_variant IS NULL OR e.exam_variant IS NOT DISTINCT FROM ti.exam_variant)
          AND a.is_completed = TRUE
          AND a.created_at > ti.completed_at
          AND a.created_at <= ti.completed_at + INTERVAL '30 days'
        GROUP BY ti.id
    )
    SELECT
        ti.id AS intervention_id,
        ti.student_user_id AS student_id,
        ti.s_name AS student_name,
        ti.classroom_id,
        ti.class_name AS classroom_name,
        ti.subject_id,
        ti.exam_variant,
        COALESCE(ti.t_name, 'Teacher') AS teacher_name,
        ti.source,
        ti.severity_at_creation,
        ti.source_reason_codes AS reason_codes_json,
        ti.action_type,
        ti.status,
        ti.created_at,
        ti.completed_at,
        ib.base_acc AS baseline_accuracy,
        CASE WHEN ti.status = 'completed' AND ti.completed_at IS NOT NULL THEN ifu.follow_acc ELSE NULL END AS followup_accuracy,
        CASE
            WHEN ti.status = 'completed' AND ti.completed_at IS NOT NULL AND ib.base_acc IS NOT NULL AND ifu.follow_acc IS NOT NULL THEN
                (ifu.follow_acc - ib.base_acc)
            ELSE NULL
        END AS observed_change_pp,
        COALESCE(ib.base_attempts, 0) AS evidence_count_pre,
        CASE WHEN ti.status = 'completed' AND ti.completed_at IS NOT NULL THEN COALESCE(ifu.follow_attempts, 0) ELSE 0 END AS evidence_count_post,
        CASE
            WHEN ti.status != 'completed' OR ti.completed_at IS NULL THEN 'insufficient'
            WHEN COALESCE(ib.base_attempts, 0) >= 2 AND COALESCE(ifu.follow_attempts, 0) >= 2 THEN 'sufficient'
            WHEN COALESCE(ib.base_attempts, 0) >= 1 AND COALESCE(ifu.follow_attempts, 0) >= 1 THEN 'limited'
            ELSE 'insufficient'
        END AS confidence,
        CASE
            WHEN ti.status != 'completed' OR ti.completed_at IS NULL THEN 'not_yet_eligible'
            WHEN ifu.follow_acc IS NOT NULL AND ib.base_acc IS NOT NULL THEN 'evidence_available'
            WHEN ti.status = 'completed' AND ifu.follow_acc IS NULL THEN 'no_comparable_followup_yet'
            ELSE 'insufficient_evidence'
        END AS evidence_status,
        CASE
            WHEN ti.status != 'completed' OR ti.completed_at IS NULL THEN
                'Intervention action is still open; post-intervention follow-up is not yet eligible.'
            WHEN ifu.follow_acc IS NOT NULL AND ib.base_acc IS NOT NULL THEN
                CASE
                    WHEN (ifu.follow_acc - ib.base_acc) > 3.0 THEN 'Higher follow-up performance observed; causation not established.'
                    WHEN (ifu.follow_acc - ib.base_acc) < -3.0 THEN 'Lower follow-up performance observed; review recommended.'
                    ELSE 'Similar follow-up performance observed; causation not established.'
                END
            WHEN ti.status = 'completed' THEN 'Intervention workflow completed; awaiting comparable academic follow-up assessment.'
            ELSE 'Intervention workflow currently active.'
        END AS evidence_interpretation,
        v_as_of AS data_as_of
    FROM target_interventions ti
    LEFT JOIN intervention_baselines ib ON ib.intervention_id = ti.id
    LEFT JOIN intervention_followups ifu ON ifu.intervention_id = ti.id
    ORDER BY ti.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_intervention_followup_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_intervention_followup_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 14. RPC: get_student_support_report
-- Authorized report of students requiring academic support.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_support_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL,
    p_classroom_id   UUID DEFAULT NULL,
    p_subject_id     TEXT DEFAULT NULL,
    p_severity       TEXT DEFAULT NULL
)
RETURNS TABLE (
    student_id               UUID,
    student_name             TEXT,
    classroom_id             UUID,
    classroom_name           TEXT,
    subject_id               TEXT,
    severity                 TEXT,
    attention_reasons        JSONB,
    recent_accuracy          NUMERIC,
    active_mistakes          INT,
    open_interventions       INT,
    data_freshness           TEXT,
    data_as_of               TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.validate_report_authority(p_school_id, p_classroom_id, p_subject_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized for student support report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    RETURN QUERY
    WITH target_classes AS (
        SELECT c.id, c.name
        FROM public.classrooms c
        WHERE c.school_id = p_school_id AND c.academic_year = v_year AND c.status = 'active'
          AND (p_classroom_id IS NULL OR c.id = p_classroom_id)
    ),
    class_students AS (
        SELECT cm.classroom_id, tc.name AS class_name, cm.user_id, p.display_name
        FROM public.classroom_memberships cm
        JOIN target_classes tc ON tc.id = cm.classroom_id
        JOIN public.profiles p ON p.id = cm.user_id
        WHERE cm.role = 'student' AND cm.status = 'active'
    ),
    student_mistakes AS (
        SELECT 
            m.user_id,
            q.subject_id,
            COUNT(m.id)::INT AS mistake_cnt
        FROM public.mistake_records m
        JOIN public.questions q ON q.id = m.question_id
        WHERE m.user_id IN (SELECT user_id FROM class_students)
          AND m.is_mastered = FALSE
          AND (p_subject_id IS NULL OR q.subject_id = p_subject_id)
        GROUP BY m.user_id, q.subject_id
        HAVING COUNT(m.id) >= 3
    )
    SELECT
        cs.user_id AS student_id,
        cs.display_name AS student_name,
        cs.classroom_id,
        cs.class_name AS classroom_name,
        COALESCE(sm.subject_id, p_subject_id, 'all') AS subject_id,
        CASE
            WHEN COALESCE(sm.mistake_cnt, 0) >= 8 THEN 'high'
            WHEN COALESCE(sm.mistake_cnt, 0) >= 5 THEN 'medium'
            ELSE 'low'
        END AS severity,
        jsonb_build_array('high_mistake_concentration') AS attention_reasons,
        COALESCE(
            (
                SELECT ROUND(AVG(a.percentage)::NUMERIC, 2)
                FROM public.attempts a
                JOIN public.exams e ON e.id = a.exam_id
                WHERE a.user_id = cs.user_id
                  AND a.is_completed = TRUE
                  AND a.created_at >= v_start AND a.created_at <= v_end
                  AND (p_subject_id IS NULL OR e.subject_id = p_subject_id)
            ),
            NULL
        ) AS recent_accuracy,
        COALESCE(sm.mistake_cnt, 0) AS active_mistakes,
        (
            SELECT COUNT(*)::INT
            FROM public.student_interventions i
            WHERE i.student_user_id = cs.user_id
              AND i.school_id = p_school_id
              AND i.status IN ('open', 'active')
        ) AS open_interventions,
        'fresh'::TEXT AS data_freshness,
        v_as_of AS data_as_of
    FROM class_students cs
    JOIN student_mistakes sm ON sm.user_id = cs.user_id
    WHERE (p_severity IS NULL OR (
        CASE
            WHEN COALESCE(sm.mistake_cnt, 0) >= 8 THEN 'high'
            WHEN COALESCE(sm.mistake_cnt, 0) >= 5 THEN 'medium'
            ELSE 'low'
        END
    ) = p_severity)
    ORDER BY sm.mistake_cnt DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_support_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_support_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 15. RPC: get_data_coverage_report
-- Comprehensive reporting on synchronization freshness and timing integrity.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_data_coverage_report(
    p_school_id      UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_total_students INT := 0;
    v_fresh INT := 0;
    v_mod INT := 0;
    v_stale INT := 0;
    v_very_stale INT := 0;
    v_unknown INT := 0;
    v_timing_unverified INT := 0;
    v_clock_anomaly INT := 0;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin()) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Data coverage report is restricted to school leadership' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    -- Canonical active enrolled students
    WITH active_enrolled AS (
        SELECT DISTINCT cm.user_id
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    )
    SELECT COUNT(*)::INT INTO v_total_students FROM active_enrolled;

    WITH active_enrolled AS (
        SELECT DISTINCT cm.user_id
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        JOIN public.school_memberships sm ON sm.user_id = cm.user_id AND sm.school_id = c.school_id
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
          AND cm.role = 'student'
          AND cm.status = 'active'
          AND sm.role = 'student'
          AND sm.status = 'active'
    ),
    -- sync_freshness is derived strictly from server-received cloud evidence (attempts.created_at).
    -- mistake_records.last_failed_at is academic activity, NOT a synchronization event.
    student_sync AS (
        SELECT
            ae.user_id,
            (SELECT MAX(a.created_at) FROM public.attempts a WHERE a.user_id = ae.user_id) AS last_sync_receipt
        FROM active_enrolled ae
    ),
    sync_dates AS (
        SELECT
            user_id,
            last_sync_receipt AS last_sync
        FROM student_sync
    )
    SELECT
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '7 days' AND last_sync < NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '14 days' AND last_sync < NOW() - INTERVAL '7 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync < NOW() - INTERVAL '14 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync IS NULL THEN 1 END)::INT
    INTO v_fresh, v_mod, v_stale, v_very_stale, v_unknown
    FROM sync_dates;

    SELECT
        COUNT(CASE WHEN COALESCE(r.deadline_integrity, 'verified') = 'unverified' THEN 1 END)::INT,
        COUNT(CASE WHEN COALESCE(r.deadline_integrity, 'verified') = 'anomaly' THEN 1 END)::INT
    INTO v_timing_unverified, v_clock_anomaly
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    WHERE a.school_id = p_school_id
      AND a.created_at >= v_start AND a.created_at <= v_end;

    RETURN jsonb_build_object(
        'school_id', p_school_id,
        'academic_year', v_year,
        'period_start', v_start,
        'period_end', v_end,
        'data_as_of', v_as_of,
        'total_active_students', v_total_students,
        'fresh_sync_count', v_fresh,
        'moderate_sync_count', v_mod,
        'stale_sync_count', v_stale,
        'very_stale_sync_count', v_very_stale,
        'unknown_sync_count', v_unknown,
        'fresh_coverage_rate', CASE WHEN v_total_students > 0 THEN ROUND(((v_fresh + v_mod)::NUMERIC / v_total_students::NUMERIC) * 100.0, 2) ELSE 0.0 END,
        'timing_unverified_count', v_timing_unverified,
        'clock_anomaly_count', v_clock_anomaly,
        'methodological_notice', 'Stale synchronization reflects offline mobile usage patterns in network-constrained environments. Missing cloud evidence must not be interpreted as lack of study. No recent cloud evidence ≠ No student study, and No recent academic event ≠ No device synchronization.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_data_coverage_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_data_coverage_report(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 16. RPC: get_student_academic_report
-- Authorized individual student report for teachers and school admins.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_academic_report(
    p_school_id      UUID,
    p_student_id     UUID,
    p_academic_year  TEXT DEFAULT NULL,
    p_period_start   TIMESTAMPTZ DEFAULT NULL,
    p_period_end     TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_student_name TEXT;
    v_stream TEXT;
    v_grade INT;
    v_class_name TEXT;
    v_total_attempts INT := 0;
    v_avg_score NUMERIC := 0.0;
    v_med_score NUMERIC := 0.0;
    v_active_mistakes INT := 0;
    v_assigned_count INT := 0;
    v_completed_count INT := 0;
    v_interventions_count INT := 0;
    v_last_academic_activity TIMESTAMPTZ;
    v_last_sync TIMESTAMPTZ;
    v_sync_freshness TEXT := 'unknown';
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.can_access_student(p_student_id, p_school_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized to access this student academic report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    -- Strict semantic separation:
    -- last_cloud_academic_activity = when the student last did academic work (attempt start/end + mistake events)
    -- last_successful_sync (v_last_sync) = when the server last received uploaded attempt data (attempts.created_at)
    -- Neither may substitute for the other. No fallback between them.
    SELECT p.display_name, p.stream, p.grade, c.name,
           -- last_cloud_academic_activity: independent sources combined — present even if student has only mistakes or only attempts
           GREATEST(
               (SELECT GREATEST(MAX(a.end_time), MAX(a.start_time)) FROM public.attempts a WHERE a.user_id = p.id),
               (SELECT MAX(m.last_failed_at) FROM public.mistake_records m WHERE m.user_id = p.id)
           ),
           -- last_successful_sync: ONLY from server cloud-evidence receipt (attempts.created_at). No fallback.
           (SELECT MAX(a.created_at) FROM public.attempts a WHERE a.user_id = p.id)
    INTO v_student_name, v_stream, v_grade, v_class_name, v_last_academic_activity, v_last_sync
    FROM public.profiles p
    LEFT JOIN public.classroom_memberships cm ON cm.user_id = p.id AND cm.status = 'active'
    LEFT JOIN public.classrooms c ON c.id = cm.classroom_id AND c.school_id = p_school_id AND c.academic_year = v_year
    WHERE p.id = p_student_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_last_sync IS NULL THEN
        v_sync_freshness := 'unknown';
    ELSIF v_last_sync >= NOW() - INTERVAL '2 days' THEN
        v_sync_freshness := 'fresh';
    ELSIF v_last_sync >= NOW() - INTERVAL '7 days' THEN
        v_sync_freshness := 'moderate';
    ELSIF v_last_sync >= NOW() - INTERVAL '14 days' THEN
        v_sync_freshness := 'stale';
    ELSE
        v_sync_freshness := 'very_stale';
    END IF;

    -- Attempts & performance
    SELECT 
        COUNT(*)::INT,
        COALESCE(ROUND(AVG(a.percentage)::NUMERIC, 2), 0.0),
        COALESCE(ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY a.percentage)::NUMERIC, 2), 0.0)
    INTO v_total_attempts, v_avg_score, v_med_score
    FROM public.attempts a
    WHERE a.user_id = p_student_id
      AND a.is_completed = TRUE
      AND a.created_at >= v_start AND a.created_at <= v_end;

    -- Active mistakes
    SELECT COALESCE(SUM(m.mistake_count), 0)::INT INTO v_active_mistakes
    FROM public.mistake_records m
    WHERE m.user_id = p_student_id AND m.is_mastered = FALSE;

    -- Assignments: (submitted + completed)
    SELECT 
        COUNT(*)::INT,
        COUNT(CASE WHEN r.status IN ('submitted', 'completed') THEN 1 END)::INT
    INTO v_assigned_count, v_completed_count
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    WHERE r.student_user_id = p_student_id
      AND a.school_id = p_school_id
      AND a.created_at >= v_start AND a.created_at <= v_end;

    -- Interventions
    SELECT COUNT(*)::INT INTO v_interventions_count
    FROM public.student_interventions i
    WHERE i.student_user_id = p_student_id
      AND i.school_id = p_school_id
      AND i.created_at >= v_start AND i.created_at <= v_end;

    RETURN jsonb_build_object(
        'student_id', p_student_id,
        'student_name', v_student_name,
        'grade', v_grade,
        'stream', v_stream,
        'classroom_name', COALESCE(v_class_name, 'Unassigned Class'),
        'academic_year', v_year,
        'period_start', v_start,
        'period_end', v_end,
        'data_as_of', v_as_of,
        'total_attempts', v_total_attempts,
        'average_score', v_avg_score,
        'median_score', v_med_score,
        'active_mistakes', v_active_mistakes,
        'assignments_assigned', v_assigned_count,
        'assignments_completed', v_completed_count,
        'interventions_received', v_interventions_count,
        'last_cloud_academic_activity', v_last_academic_activity,
        'last_successful_sync', v_last_sync,
        'sync_freshness', v_sync_freshness,
        'last_sync_timestamp', v_last_sync,
        'p4_mastery_notice', 'FidelLearn P4 adaptive spaced mastery and composite national readiness are device-local and not synchronized to institutional cloud reports.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_academic_report(UUID, UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_academic_report(UUID, UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 14. RPC: get_teacher_coverage_report
-- Institutional staffing & subject assignment oversight using teacher_subject_assignments.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_coverage_report(
    p_school_id     UUID,
    p_academic_year TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_year TEXT;
    v_total_slots INT := 0;
    v_assigned_slots INT := 0;
    v_unassigned_slots INT := 0;
    v_coverage_pct NUMERIC(5,2) := 0.0;
    v_slots JSONB := '[]'::jsonb;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF auth.uid() IS NULL OR p_school_id IS NULL THEN
        RAISE EXCEPTION 'Access denied: Authentication required' USING ERRCODE = '42501';
    END IF;

    IF NOT (public.is_school_admin(p_school_id) OR public.is_platform_admin()) THEN
        RAISE EXCEPTION 'Access denied: Teacher coverage report requires school administrative oversight' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);

    WITH active_classes AS (
        SELECT
            c.id AS cid,
            c.name AS cname,
            c.grade AS cgrade,
            CASE
                WHEN c.stream IN ('natural', 'naturalScience') THEN 'naturalScience'
                WHEN c.stream IN ('social', 'socialScience') THEN 'socialScience'
                ELSE c.stream
            END AS cstream,
            c.section AS csection
        FROM public.classrooms c
        WHERE c.school_id = p_school_id
          AND c.academic_year = v_year
          AND c.status = 'active'
    ),
    stream_curriculum AS (
        -- Natural Science: 6 primary ESSLCE subjects
        SELECT 'naturalScience'::TEXT AS stream, 'english_g12'::TEXT AS subject_id, 'English'::TEXT AS subject_name, NULL::TEXT AS exam_variant
        UNION ALL
        SELECT 'naturalScience', 'math_g12', 'Mathematics (Natural Science)', 'naturalScience'
        UNION ALL
        SELECT 'naturalScience', 'aptitude_g12', 'Scholastic Aptitude', NULL
        UNION ALL
        SELECT 'naturalScience', 'physics_g12', 'Physics', NULL
        UNION ALL
        SELECT 'naturalScience', 'chemistry_g12', 'Chemistry', NULL
        UNION ALL
        SELECT 'naturalScience', 'biology_g12', 'Biology', NULL
        -- Social Science: 6 primary ESSLCE subjects
        UNION ALL
        SELECT 'socialScience', 'english_g12', 'English', NULL
        UNION ALL
        SELECT 'socialScience', 'math_g12', 'Mathematics (Social Science)', 'socialScience'
        UNION ALL
        SELECT 'socialScience', 'aptitude_g12', 'Scholastic Aptitude', NULL
        UNION ALL
        SELECT 'socialScience', 'history_g12', 'History', NULL
        UNION ALL
        SELECT 'socialScience', 'geography_g12', 'Geography', NULL
        UNION ALL
        SELECT 'socialScience', 'economics_g12', 'Economics', NULL
    ),
    required_slots AS (
        SELECT
            ac.cid AS classroom_id,
            ac.cname AS classroom_name,
            ac.cgrade AS grade,
            ac.cstream AS stream,
            ac.csection AS section,
            sc.subject_id,
            sc.subject_name,
            sc.exam_variant
        FROM active_classes ac
        JOIN stream_curriculum sc ON sc.stream = ac.cstream
    ),
    slots_with_teachers AS (
        SELECT
            rs.classroom_id,
            rs.classroom_name,
            rs.grade,
            rs.stream,
            rs.section,
            rs.subject_id,
            rs.subject_name,
            rs.exam_variant,
            tsa.teacher_user_id,
            p.display_name AS teacher_name,
            CASE WHEN tsa.teacher_user_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_assigned
        FROM required_slots rs
        LEFT JOIN public.teacher_subject_assignments tsa
            ON tsa.classroom_id = rs.classroom_id
           AND tsa.subject_id = rs.subject_id
           AND tsa.school_id = p_school_id
           AND tsa.status = 'active'
           AND (
               (rs.exam_variant IS NULL AND (tsa.exam_variant IS NULL OR tsa.exam_variant = 'shared'))
               OR (rs.exam_variant IS NOT NULL AND tsa.exam_variant = rs.exam_variant)
           )
        LEFT JOIN public.profiles p ON p.id = tsa.teacher_user_id
    )
    SELECT
        COUNT(*)::INT,
        COUNT(CASE WHEN is_assigned THEN 1 END)::INT,
        COUNT(CASE WHEN NOT is_assigned THEN 1 END)::INT,
        COALESCE(jsonb_agg(to_jsonb(swt)), '[]'::jsonb)
    INTO v_total_slots, v_assigned_slots, v_unassigned_slots, v_slots
    FROM slots_with_teachers swt;

    IF v_total_slots > 0 THEN
        v_coverage_pct := ROUND((v_assigned_slots::NUMERIC / v_total_slots::NUMERIC) * 100.0, 2);
    ELSE
        v_coverage_pct := 0.0;
    END IF;

    RETURN jsonb_build_object(
        'school_id', p_school_id,
        'academic_year', v_year,
        'total_slots', v_total_slots,
        'assigned_slots', v_assigned_slots,
        'unassigned_slots', v_unassigned_slots,
        'coverage_percentage', v_coverage_pct,
        'slots', v_slots,
        'data_as_of', v_as_of
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_coverage_report(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_coverage_report(UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 17. RPC: record_institutional_report_audit
-- Records export and download actions in the canonical public.audit_log ledger.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_institutional_report_audit(
    p_school_id UUID,
    p_run_id    UUID,
    p_action    TEXT,
    p_metadata  JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Access denied: Authentication required' USING ERRCODE = '42501';
    END IF;

    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id) OR public.is_teacher_in_school(p_school_id)) THEN
        RAISE EXCEPTION 'Access denied: Insufficient privileges' USING ERRCODE = '42501';
    END IF;

    IF p_action NOT IN ('institutional_report_generated', 'institutional_report_exported', 'institutional_report_downloaded') THEN
        RAISE EXCEPTION 'Invalid report audit action: %', p_action USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        p_action,
        'institutional_report_runs',
        p_run_id,
        jsonb_build_object(
            'school_id', p_school_id,
            'action', p_action
        ) || p_metadata
    );
END;
$$;

REVOKE ALL ON FUNCTION public.record_institutional_report_audit(UUID, UUID, TEXT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_institutional_report_audit(UUID, UUID, TEXT, JSONB) TO authenticated;


-- =============================================================================
-- FidelLearn Database Schema Migration
-- Version: 20260925050000
-- Description: P11 — Licensing, Seats, Billing & School Onboarding Foundation
--   1. Plans Catalog (institutional_plans)
--   2. Institutional Licensing (school_licenses, school_license_events)
--   3. Seat Accounting & Transactional Capacity Enforcement
--   4. Server-Authoritative Feature Entitlements (school_has_entitlement)
--   5. School Onboarding Workflow & Progressive Validation (school_onboarding_state)
--   6. Bulk Student CSV Import & Idempotent Ingestion (institutional_import_runs)
--   7. Provider-Neutral Billing Abstraction (billing_customers, billing_subscriptions, billing_events)
--   8. Canonical Audit Logging into public.audit_log
--   9. Strict RLS and SECURITY DEFINER RPC Authority Isolation
-- =============================================================================

-- =============================================================================
-- 0. AUDIT LOG EXTENSION: ALLOW SYSTEM / WEBHOOK EVENTS WITHOUT HUMAN ACTOR
-- =============================================================================
ALTER TABLE public.audit_log ALTER COLUMN actor_id DROP NOT NULL;

-- =============================================================================
-- 1. INSTITUTIONAL PLANS CATALOG
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.institutional_plans (
    plan_code TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    default_student_seat_limit INT NOT NULL CHECK (default_student_seat_limit > 0),
    default_entitlements JSONB NOT NULL,
    billing_interval TEXT NOT NULL CHECK (billing_interval IN ('monthly', 'term', 'annual', 'custom')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Seed canonical initial plan catalog
INSERT INTO public.institutional_plans (plan_code, display_name, default_student_seat_limit, default_entitlements, billing_interval, is_active)
VALUES
    (
        'trial',
        'FidelLearn Institutional Trial',
        100,
        jsonb_build_object(
            'student_learning', true,
            'teacher_portal', true,
            'leadership_dashboard', true,
            'assignments_interventions', true,
            'institutional_reporting', true,
            'national_exam_simulation', true
        ),
        'monthly',
        true
    ),
    (
        'school_standard',
        'Standard Secondary School License',
        500,
        jsonb_build_object(
            'student_learning', true,
            'teacher_portal', true,
            'leadership_dashboard', true,
            'assignments_interventions', true,
            'institutional_reporting', true,
            'national_exam_simulation', true
        ),
        'annual',
        true
    ),
    (
        'custom_contract',
        'Custom Institutional Contract',
        1500,
        jsonb_build_object(
            'student_learning', true,
            'teacher_portal', true,
            'leadership_dashboard', true,
            'assignments_interventions', true,
            'institutional_reporting', true,
            'national_exam_simulation', true
        ),
        'custom',
        true
    )
ON CONFLICT (plan_code) DO NOTHING;

-- =============================================================================
-- 2. SCHOOL LICENSES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.school_licenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    plan_code TEXT NOT NULL REFERENCES public.institutional_plans(plan_code) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('trial', 'active', 'grace', 'suspended', 'expired', 'cancelled')) DEFAULT 'trial',
    starts_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    ends_at TIMESTAMPTZ NULL,
    grace_ends_at TIMESTAMPTZ NULL,
    student_seat_limit INT NOT NULL CHECK (student_seat_limit > 0),
    feature_entitlements JSONB NOT NULL,
    billing_customer_ref TEXT NULL,
    billing_subscription_ref TEXT NULL,
    source TEXT NOT NULL CHECK (source IN ('manual_contract', 'trial_provisioning', 'online_checkout', 'bank_transfer', 'system')) DEFAULT 'manual_contract',
    last_billing_event_at TIMESTAMPTZ NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_school_licenses_school UNIQUE (school_id)
);

ALTER TABLE public.school_licenses ADD COLUMN IF NOT EXISTS last_billing_event_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_school_licenses_status ON public.school_licenses(status);
CREATE INDEX IF NOT EXISTS idx_school_licenses_school_status ON public.school_licenses(school_id, status);
CREATE INDEX IF NOT EXISTS idx_school_licenses_expiry ON public.school_licenses(ends_at, grace_ends_at);

-- =============================================================================
-- 3. SCHOOL LICENSE EVENTS AUDIT LEDGER
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.school_license_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    license_id UUID NOT NULL REFERENCES public.school_licenses(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    old_status TEXT NULL,
    new_status TEXT NOT NULL,
    old_seat_limit INT NULL,
    new_seat_limit INT NULL,
    reason TEXT NULL,
    event_source TEXT NOT NULL DEFAULT 'manual_contract',
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_school_license_events_school ON public.school_license_events(school_id, created_at DESC);

-- =============================================================================
-- 4. SCHOOL ONBOARDING STATE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.school_onboarding_state (
    school_id UUID PRIMARY KEY REFERENCES public.schools(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'ready_for_activation', 'completed', 'blocked')) DEFAULT 'not_started',
    school_created BOOLEAN NOT NULL DEFAULT TRUE,
    license_configured BOOLEAN NOT NULL DEFAULT FALSE,
    academic_year_configured BOOLEAN NOT NULL DEFAULT FALSE,
    classes_configured BOOLEAN NOT NULL DEFAULT FALSE,
    admin_configured BOOLEAN NOT NULL DEFAULT FALSE,
    teachers_configured BOOLEAN NOT NULL DEFAULT FALSE,
    teacher_assignments_configured BOOLEAN NOT NULL DEFAULT FALSE,
    students_configured BOOLEAN NOT NULL DEFAULT FALSE,
    coverage_validated BOOLEAN NOT NULL DEFAULT FALSE,
    activation_ready BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at TIMESTAMPTZ NULL,
    last_validation_errors JSONB NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- =============================================================================
-- 5. INSTITUTIONAL BULK IMPORT RUNS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.institutional_import_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    import_type TEXT NOT NULL CHECK (import_type IN ('students', 'teachers')),
    requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'validating', 'validated', 'committed', 'failed')) DEFAULT 'pending',
    total_rows INT NOT NULL DEFAULT 0,
    valid_rows INT NOT NULL DEFAULT 0,
    invalid_rows INT NOT NULL DEFAULT 0,
    created_students INT NOT NULL DEFAULT 0,
    existing_students INT NOT NULL DEFAULT 0,
    error_summary JSONB NULL,
    idempotency_key TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    completed_at TIMESTAMPTZ NULL,
    CONSTRAINT uq_import_runs_school_idempotency UNIQUE (school_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_import_runs_school ON public.institutional_import_runs(school_id, created_at DESC);

-- =============================================================================
-- 6. PROVIDER-NEUTRAL BILLING TABLES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.billing_customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    provider TEXT NOT NULL CHECK (provider IN ('manual', 'telebirr', 'chapa', 'stripe', 'cbe_birr', 'bank_transfer')),
    external_customer_ref TEXT NOT NULL,
    billing_email TEXT NULL,
    billing_contact_name TEXT NULL,
    currency_code TEXT NOT NULL DEFAULT 'ETB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_billing_customers_school_provider UNIQUE (school_id, provider)
);

CREATE TABLE IF NOT EXISTS public.billing_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    provider TEXT NOT NULL CHECK (provider IN ('manual', 'telebirr', 'chapa', 'stripe', 'cbe_birr', 'bank_transfer')),
    external_subscription_ref TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('trialing', 'active', 'past_due', 'canceled', 'unpaid', 'incomplete')),
    billing_interval TEXT NOT NULL DEFAULT 'annual',
    currency_code TEXT NOT NULL DEFAULT 'ETB',
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_billing_subscriptions_provider_ref UNIQUE (provider, external_subscription_ref)
);

CREATE TABLE IF NOT EXISTS public.billing_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider TEXT NOT NULL,
    provider_event_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL,
    payload_hash TEXT NOT NULL,
    event_timestamp TIMESTAMPTZ NULL,
    status TEXT NOT NULL CHECK (status IN ('received', 'processed', 'ignored', 'failed')) DEFAULT 'received',
    processed_at TIMESTAMPTZ NULL,
    error_message TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_billing_events_provider_event UNIQUE (provider, provider_event_id)
);

ALTER TABLE public.billing_events ADD COLUMN IF NOT EXISTS event_timestamp TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_billing_events_school ON public.billing_events(school_id);

-- =============================================================================
-- 7. SEAT ACCOUNTING & CAPACITY ENFORCEMENT FUNCTIONS
-- =============================================================================

-- 7a. get_school_seat_usage: Authoritative transactional seat query
-- Canonical seat rule:
--   occupied = COUNT(DISTINCT cm.user_id) for active students in active classrooms of school
--   multi-class enrollment = 1 seat
--   transferred / inactive = 0 seats
CREATE OR REPLACE FUNCTION public.get_school_seat_usage(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_limit INT := 0;
    v_occupied INT := 0;
    v_available INT := 0;
    v_status TEXT := 'unknown';
    v_ends_at TIMESTAMPTZ;
    v_grace_ends_at TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
    v_is_over_capacity BOOLEAN := FALSE;
    v_utilization_pct NUMERIC(5,2) := 0.00;
BEGIN
    -- Authority guard: platform admin or school member
    IF auth.uid() IS NOT NULL THEN
        IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id) OR public.is_teacher_in_school(p_school_id)) THEN
            RAISE EXCEPTION 'Caller % is not authorized to view seat usage for school %', auth.uid(), p_school_id
                USING ERRCODE = 'insufficient_privilege';
        END IF;
    END IF;

    -- Query active license
    SELECT student_seat_limit, status, ends_at, grace_ends_at
    INTO v_limit, v_status, v_ends_at, v_grace_ends_at
    FROM public.school_licenses
    WHERE school_id = p_school_id;

    IF NOT FOUND THEN
        -- If no license row, check if school exists
        IF NOT EXISTS (SELECT 1 FROM public.schools WHERE id = p_school_id) THEN
            RAISE EXCEPTION 'School % does not exist', p_school_id
                USING ERRCODE = 'invalid_parameter_value';
        END IF;
        v_limit := 0;
        v_status := 'unlicensed';
    ELSE
        -- Derive effective status based on timestamps
        IF v_status = 'trial' THEN
            IF v_ends_at IS NOT NULL AND v_ends_at <= v_now THEN
                v_status := 'expired';
            END IF;
        ELSIF v_status = 'active' THEN
            IF v_ends_at IS NOT NULL AND v_ends_at <= v_now THEN
                IF v_grace_ends_at IS NOT NULL AND v_grace_ends_at > v_now THEN
                    v_status := 'grace';
                ELSE
                    v_status := 'expired';
                END IF;
            END IF;
        ELSIF v_status = 'grace' THEN
            IF v_grace_ends_at IS NOT NULL AND v_grace_ends_at <= v_now THEN
                v_status := 'suspended';
            END IF;
        END IF;
    END IF;

    -- Count distinct active students in active classrooms of this school
    SELECT COUNT(DISTINCT cm.user_id)
    INTO v_occupied
    FROM public.classroom_memberships cm
    JOIN public.classrooms c ON c.id = cm.classroom_id
    WHERE c.school_id = p_school_id
      AND c.status = 'active'
      AND cm.role = 'student'
      AND cm.status = 'active';

    IF v_limit > 0 THEN
        v_available := GREATEST(0, v_limit - v_occupied);
        v_is_over_capacity := (v_occupied > v_limit);
        v_utilization_pct := ROUND((v_occupied::numeric / v_limit::numeric) * 100.0, 2);
    ELSE
        v_available := 0;
        v_is_over_capacity := (v_occupied > 0);
        v_utilization_pct := 100.00;
    END IF;

    RETURN jsonb_build_object(
        'school_id', p_school_id,
        'student_seat_limit', v_limit,
        'occupied_seats', v_occupied,
        'available_seats', v_available,
        'seat_utilization_pct', v_utilization_pct,
        'is_over_capacity', v_is_over_capacity,
        'license_status', v_status
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 7b. check_school_seat_capacity: Transactional validation before student enrollment
CREATE OR REPLACE FUNCTION public.check_school_seat_capacity(
    p_school_id UUID,
    p_new_students_count INT DEFAULT 1
) RETURNS BOOLEAN AS $$
DECLARE
    v_license public.school_licenses%ROWTYPE;
    v_occupied INT := 0;
    v_effective_status TEXT;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT * INTO v_license
    FROM public.school_licenses
    WHERE school_id = p_school_id
    FOR UPDATE; -- Concurrency lock to prevent race conditions during activation

    IF NOT FOUND THEN
        RAISE EXCEPTION 'School % has no commercial license configured', p_school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- Verify commercial license effectiveness
    IF NOT public.is_school_license_effective(p_school_id) THEN
        RAISE EXCEPTION 'School % license is not commercially effective — cannot enroll students', p_school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- Calculate current occupied seats
    SELECT COUNT(DISTINCT cm.user_id) INTO v_occupied
    FROM public.classroom_memberships cm
    JOIN public.classrooms c ON c.id = cm.classroom_id
    WHERE c.school_id = p_school_id
      AND c.status = 'active'
      AND cm.role = 'student'
      AND cm.status = 'active';

    IF (v_occupied + p_new_students_count) > v_license.student_seat_limit THEN
        RAISE EXCEPTION 'SEAT_LIMIT_EXCEEDED: Cannot enroll % student(s). Occupied: %, Limit: %',
            p_new_students_count, v_occupied, v_license.student_seat_limit
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 8. SERVER-AUTHORITATIVE FEATURE ENTITLEMENT FUNCTIONS
-- =============================================================================

-- 8a. is_school_license_effective: Authoritative central evaluator for commercial license effectiveness
CREATE OR REPLACE FUNCTION public.is_school_license_effective(p_school_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_school_status TEXT;
    v_license public.school_licenses%ROWTYPE;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    IF p_school_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Cross-school caller authorization check (anti-probing guard)
    IF auth.uid() IS NOT NULL 
       AND auth.role() != 'service_role' 
       AND NOT public.is_platform_admin() THEN
        IF NOT public.is_school_member(p_school_id) THEN
            RAISE EXCEPTION 'Access denied: caller % is not an active member of school %', auth.uid(), p_school_id
                USING ERRCODE = '42501';
        END IF;
    END IF;

    -- School must exist and be active
    SELECT status INTO v_school_status FROM public.schools WHERE id = p_school_id;
    IF NOT FOUND OR v_school_status != 'active' THEN
        RETURN FALSE;
    END IF;

    -- License row must exist
    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Deterministic request-time commercial policy:
    -- trial: starts_at <= NOW() AND (ends_at IS NULL OR ends_at > NOW())
    -- active: starts_at <= NOW() AND (ends_at IS NULL OR ends_at > NOW())
    -- grace: grace_ends_at IS NOT NULL AND grace_ends_at > NOW()
    -- suspended, expired, cancelled: DENIED (FALSE)
    IF v_license.status = 'trial' THEN
        RETURN (v_license.starts_at <= v_now AND (v_license.ends_at IS NULL OR v_license.ends_at > v_now));
    ELSIF v_license.status = 'active' THEN
        RETURN (v_license.starts_at <= v_now AND (v_license.ends_at IS NULL OR v_license.ends_at > v_now));
    ELSIF v_license.status = 'grace' THEN
        RETURN (v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at > v_now);
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8b. get_school_entitlements: Returns active feature entitlements for a school
CREATE OR REPLACE FUNCTION public.get_school_entitlements(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_license public.school_licenses%ROWTYPE;
BEGIN
    IF p_school_id IS NULL THEN
        RETURN '{}'::jsonb;
    END IF;

    -- Cross-school caller authorization check (anti-probing guard)
    IF auth.uid() IS NOT NULL 
       AND auth.role() != 'service_role' 
       AND NOT public.is_platform_admin() THEN
        IF NOT public.is_school_member(p_school_id) THEN
            RAISE EXCEPTION 'Access denied: caller % is not an active member of school %', auth.uid(), p_school_id
                USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Commercial request-time effectiveness evaluation
    IF NOT public.is_school_license_effective(p_school_id) THEN
        RETURN '{}'::jsonb;
    END IF;

    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id;
    IF NOT FOUND THEN
        RETURN '{}'::jsonb;
    END IF;

    RETURN COALESCE(v_license.feature_entitlements, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8c. school_has_entitlement: Fast boolean check for specific feature key
CREATE OR REPLACE FUNCTION public.school_has_entitlement(
    p_school_id   UUID,
    p_entitlement TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_entitlements JSONB;
BEGIN
    IF p_school_id IS NULL OR p_entitlement IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Cross-school caller authorization check (anti-probing guard)
    IF auth.uid() IS NOT NULL 
       AND auth.role() != 'service_role' 
       AND NOT public.is_platform_admin() THEN
        IF NOT public.is_school_member(p_school_id) THEN
            RAISE EXCEPTION 'Access denied: caller % is not an active member of school %', auth.uid(), p_school_id
                USING ERRCODE = '42501';
        END IF;
    END IF;

    v_entitlements := public.get_school_entitlements(p_school_id);
    RETURN COALESCE((v_entitlements->>p_entitlement)::boolean, FALSE);
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 9. PRIVILEGED COMMERCIAL RPC FUNCTIONS (SECURITY DEFINER)
-- =============================================================================

-- 9a. create_school_license_internal: Platform Admin only
CREATE OR REPLACE FUNCTION public.create_school_license_internal(
    p_school_id         UUID,
    p_plan_code         TEXT,
    p_seat_limit        INT,
    p_source            TEXT DEFAULT 'manual_contract',
    p_starts_at         TIMESTAMPTZ DEFAULT NULL,
    p_ends_at           TIMESTAMPTZ DEFAULT NULL,
    p_custom_features   JSONB DEFAULT NULL
) RETURNS public.school_licenses AS $$
DECLARE
    v_caller_id   UUID := auth.uid();
    v_plan        public.institutional_plans%ROWTYPE;
    v_license     public.school_licenses%ROWTYPE;
    v_status      TEXT;
    v_features    JSONB;
    v_starts      TIMESTAMPTZ;
    v_seat_lim    INT;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_plan FROM public.institutional_plans WHERE plan_code = p_plan_code;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Plan code % not found in catalog', p_plan_code
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    v_starts := COALESCE(p_starts_at, TIMEZONE('utc', NOW()));
    v_status := CASE WHEN p_plan_code = 'trial' THEN 'trial' ELSE 'active' END;
    v_seat_lim := COALESCE(p_seat_limit, v_plan.default_student_seat_limit);
    v_features := COALESCE(p_custom_features, v_plan.default_entitlements);

    INSERT INTO public.school_licenses (
        school_id,
        plan_code,
        status,
        starts_at,
        ends_at,
        student_seat_limit,
        feature_entitlements,
        source,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_plan_code,
        v_status,
        v_starts,
        p_ends_at,
        v_seat_lim,
        v_features,
        p_source,
        v_caller_id,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (school_id) DO UPDATE SET
        plan_code            = EXCLUDED.plan_code,
        status               = EXCLUDED.status,
        starts_at            = EXCLUDED.starts_at,
        ends_at              = EXCLUDED.ends_at,
        student_seat_limit   = EXCLUDED.student_seat_limit,
        feature_entitlements = EXCLUDED.feature_entitlements,
        source               = EXCLUDED.source,
        updated_at           = TIMEZONE('utc', NOW())
    RETURNING * INTO v_license;

    -- Record immutable license event
    INSERT INTO public.school_license_events (
        school_id, license_id, event_type, old_status, new_status,
        old_seat_limit, new_seat_limit, reason, event_source, actor_id, metadata
    ) VALUES (
        p_school_id, v_license.id, 'license_created', NULL, v_status,
        NULL, v_seat_lim, 'Initial license creation', p_source, v_caller_id,
        jsonb_build_object('plan_code', p_plan_code, 'seat_limit', v_seat_lim)
    );

    -- Update onboarding state
    INSERT INTO public.school_onboarding_state (school_id, license_configured, updated_at)
    VALUES (p_school_id, TRUE, TIMEZONE('utc', NOW()))
    ON CONFLICT (school_id) DO UPDATE SET
        license_configured = TRUE,
        updated_at = TIMEZONE('utc', NOW());

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_license_created', 'school_licenses', v_license.id::TEXT,
        jsonb_build_object('school_id', p_school_id, 'plan_code', p_plan_code, 'seat_limit', v_seat_lim, 'status', v_status)
    );

    RETURN v_license;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 9b. transition_school_license_internal: Regulated state machine transition
CREATE OR REPLACE FUNCTION public.transition_school_license_internal(
    p_school_id   UUID,
    p_new_status  TEXT,
    p_reason      TEXT,
    p_grace_until TIMESTAMPTZ DEFAULT NULL
) RETURNS public.school_licenses AS $$
DECLARE
    v_caller_id  UUID := auth.uid();
    v_license    public.school_licenses%ROWTYPE;
    v_old_status TEXT;
    v_is_legal   BOOLEAN := FALSE;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'License for school % not found', p_school_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    v_old_status := v_license.status;

    -- Validate legal state transitions (Sections 6 & 7):
    -- trial     -> active, cancelled, expired
    -- active    -> grace, suspended, cancelled, expired
    -- grace     -> active, suspended, cancelled, expired
    -- suspended -> active, cancelled
    -- expired   -> active, cancelled
    -- cancelled -> (TERMINAL: cannot be transitioned; reactivation requires new contract via create_school_license_internal)
    IF v_old_status = p_new_status THEN
        RETURN v_license;
    END IF;

    IF v_old_status = 'cancelled' THEN
        RAISE EXCEPTION 'ILLEGAL_TRANSITION: Cancelled license cannot be transitioned. New contract license required'
            USING ERRCODE = 'check_violation';
    END IF;

    IF v_old_status = 'trial' AND p_new_status IN ('active', 'cancelled', 'expired') THEN
        v_is_legal := TRUE;
    ELSIF v_old_status = 'active' AND p_new_status IN ('grace', 'suspended', 'cancelled', 'expired') THEN
        v_is_legal := TRUE;
    ELSIF v_old_status = 'grace' AND p_new_status IN ('active', 'suspended', 'cancelled', 'expired') THEN
        v_is_legal := TRUE;
    ELSIF v_old_status = 'suspended' AND p_new_status IN ('active', 'cancelled') THEN
        v_is_legal := TRUE;
    ELSIF v_old_status = 'expired' AND p_new_status IN ('active', 'cancelled') THEN
        v_is_legal := TRUE;
    END IF;

    IF NOT v_is_legal THEN
        RAISE EXCEPTION 'ILLEGAL_TRANSITION: Cannot transition license from % to %', v_old_status, p_new_status
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_new_status = 'grace' AND p_grace_until IS NULL THEN
        p_grace_until := TIMEZONE('utc', NOW()) + INTERVAL '14 days';
    END IF;

    UPDATE public.school_licenses
    SET status = p_new_status,
        grace_ends_at = CASE WHEN p_new_status = 'grace' THEN p_grace_until ELSE NULL END,
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = v_license.id
    RETURNING * INTO v_license;

    -- Record immutable event
    INSERT INTO public.school_license_events (
        school_id, license_id, event_type, old_status, new_status,
        old_seat_limit, new_seat_limit, reason, actor_id
    ) VALUES (
        p_school_id, v_license.id, 'license_status_transitioned', v_old_status, p_new_status,
        v_license.student_seat_limit, v_license.student_seat_limit, p_reason, v_caller_id
    );

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_license_transitioned', 'school_licenses', v_license.id::TEXT,
        jsonb_build_object('school_id', p_school_id, 'old_status', v_old_status, 'new_status', p_new_status, 'reason', p_reason)
    );

    RETURN v_license;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 9c. update_school_seat_limit_internal: Platform Admin only. Non-destructive on seat decrease.
CREATE OR REPLACE FUNCTION public.update_school_seat_limit_internal(
    p_school_id       UUID,
    p_new_seat_limit  INT,
    p_reason          TEXT
) RETURNS public.school_licenses AS $$
DECLARE
    v_caller_id    UUID := auth.uid();
    v_license      public.school_licenses%ROWTYPE;
    v_old_limit    INT;
    v_occupied     INT := 0;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    IF p_new_seat_limit <= 0 THEN
        RAISE EXCEPTION 'Seat limit must be greater than zero: %', p_new_seat_limit
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'License for school % not found', p_school_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    v_old_limit := v_license.student_seat_limit;

    -- Count occupied seats
    SELECT COUNT(DISTINCT cm.user_id) INTO v_occupied
    FROM public.classroom_memberships cm
    JOIN public.classrooms c ON c.id = cm.classroom_id
    WHERE c.school_id = p_school_id AND c.status = 'active' AND cm.role = 'student' AND cm.status = 'active';

    -- Non-destructive seat decrease policy:
    -- If new_limit < occupied, the license enters over-capacity state, but existing students are NOT deleted.
    UPDATE public.school_licenses
    SET student_seat_limit = p_new_seat_limit,
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = v_license.id
    RETURNING * INTO v_license;

    -- Record event
    INSERT INTO public.school_license_events (
        school_id, license_id, event_type, old_status, new_status,
        old_seat_limit, new_seat_limit, reason, actor_id, metadata
    ) VALUES (
        p_school_id, v_license.id, 'seat_limit_changed', v_license.status, v_license.status,
        v_old_limit, p_new_seat_limit, p_reason, v_caller_id,
        jsonb_build_object('occupied_seats', v_occupied, 'over_capacity', (v_occupied > p_new_seat_limit))
    );

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_seat_limit_changed', 'school_licenses', v_license.id::TEXT,
        jsonb_build_object('school_id', p_school_id, 'old_limit', v_old_limit, 'new_limit', p_new_seat_limit, 'occupied', v_occupied)
    );

    RETURN v_license;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 9d. update_school_entitlements_internal: Platform Admin only
CREATE OR REPLACE FUNCTION public.update_school_entitlements_internal(
    p_school_id         UUID,
    p_new_entitlements  JSONB,
    p_reason            TEXT
) RETURNS public.school_licenses AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_license   public.school_licenses%ROWTYPE;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    UPDATE public.school_licenses
    SET feature_entitlements = p_new_entitlements,
        updated_at = TIMEZONE('utc', NOW())
    WHERE school_id = p_school_id
    RETURNING * INTO v_license;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'License for school % not found', p_school_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Record event
    INSERT INTO public.school_license_events (
        school_id, license_id, event_type, old_status, new_status,
        old_seat_limit, new_seat_limit, reason, actor_id, metadata
    ) VALUES (
        p_school_id, v_license.id, 'entitlements_changed', v_license.status, v_license.status,
        v_license.student_seat_limit, v_license.student_seat_limit, p_reason, v_caller_id,
        jsonb_build_object('new_entitlements', p_new_entitlements)
    );

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_entitlements_changed', 'school_licenses', v_license.id::TEXT,
        jsonb_build_object('school_id', p_school_id, 'entitlements', p_new_entitlements, 'reason', p_reason)
    );

    RETURN v_license;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 9e. get_school_license: Read model for School Admin and Platform Admin
CREATE OR REPLACE FUNCTION public.get_school_license(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_caller_id  UUID := auth.uid();
    v_license    public.school_licenses%ROWTYPE;
    v_seat_usage JSONB;
BEGIN
    -- Authorization check: Caller must be Platform Admin or School Admin of this school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to view license for school %', v_caller_id, p_school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    v_seat_usage := public.get_school_seat_usage(p_school_id);

    -- Derive effective status based on timestamps (Section 8 & 9)
    DECLARE
        v_effective_status TEXT := v_license.status;
        v_now TIMESTAMPTZ := NOW();
    BEGIN
        IF v_license.status = 'trial' THEN
            IF v_license.ends_at IS NOT NULL AND v_license.ends_at <= v_now THEN
                v_effective_status := 'expired';
            END IF;
        ELSIF v_license.status = 'active' THEN
            IF v_license.ends_at IS NOT NULL AND v_license.ends_at <= v_now THEN
                IF v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at > v_now THEN
                    v_effective_status := 'grace';
                ELSE
                    v_effective_status := 'expired';
                END IF;
            END IF;
        ELSIF v_license.status = 'grace' THEN
            IF v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at <= v_now THEN
                v_effective_status := 'suspended';
            END IF;
        END IF;

        RETURN jsonb_build_object(
            'id', v_license.id,
            'school_id', v_license.school_id,
            'plan_code', v_license.plan_code,
            'status', v_license.status,
            'effective_status', v_effective_status,
            'starts_at', v_license.starts_at,
            'ends_at', v_license.ends_at,
            'grace_ends_at', v_license.grace_ends_at,
            'student_seat_limit', v_license.student_seat_limit,
            'feature_entitlements', v_license.feature_entitlements,
            'source', v_license.source,
            'last_billing_event_at', v_license.last_billing_event_at,
            'seat_usage', v_seat_usage,
            'created_at', v_license.created_at,
            'updated_at', v_license.updated_at
        );
    END;
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 10. SCHOOL ONBOARDING PROGRESS & VALIDATION ENGINE
-- =============================================================================

-- 10a. validate_school_activation: Checks all minimum operational criteria
CREATE OR REPLACE FUNCTION public.validate_school_activation(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_school         public.schools%ROWTYPE;
    v_license        public.school_licenses%ROWTYPE;
    v_has_license    BOOLEAN := FALSE;
    v_has_admin      BOOLEAN := FALSE;
    v_has_class      BOOLEAN := FALSE;
    v_has_year       BOOLEAN := FALSE;
    v_has_stream     BOOLEAN := FALSE;
    v_seat_ok        BOOLEAN := FALSE;
    v_coverage_ok    BOOLEAN := FALSE;
    v_errors         JSONB := '[]'::jsonb;
    v_occupied       INT := 0;
    v_nat_classes    INT := 0;
    v_soc_classes    INT := 0;
    v_required_slots INT := 0;
    v_assigned_slots INT := 0;
BEGIN
    SELECT * INTO v_school FROM public.schools WHERE id = p_school_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'School % not found', p_school_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Check license
    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id;
    IF FOUND AND v_license.status IN ('trial', 'active', 'grace') THEN
        v_has_license := TRUE;
    ELSE
        v_errors := v_errors || jsonb_build_array('Valid license or trial required');
    END IF;

    -- Check active school admin
    IF EXISTS (
        SELECT 1 FROM public.school_memberships
        WHERE school_id = p_school_id AND role = 'school_admin' AND status = 'active'
    ) THEN
        v_has_admin := TRUE;
    ELSE
        v_errors := v_errors || jsonb_build_array('At least one active School Administrator required');
    END IF;

    -- Check classrooms
    SELECT EXISTS (
        SELECT 1 FROM public.classrooms WHERE school_id = p_school_id AND status = 'active'
    ) INTO v_has_class;

    IF v_has_class THEN
        -- Check academic year
        IF EXISTS (SELECT 1 FROM public.classrooms WHERE school_id = p_school_id AND status = 'active' AND academic_year IS NOT NULL AND academic_year != '') THEN
            v_has_year := TRUE;
        ELSE
            v_errors := v_errors || jsonb_build_array('Academic year must be configured on classrooms');
        END IF;

        -- Check streams
        IF EXISTS (SELECT 1 FROM public.classrooms WHERE school_id = p_school_id AND status = 'active' AND stream IN ('naturalScience', 'socialScience', 'natural', 'social')) THEN
            v_has_stream := TRUE;
        ELSE
            v_errors := v_errors || jsonb_build_array('Valid ESSLCE stream (Natural or Social) required on classrooms');
        END IF;
    ELSE
        v_errors := v_errors || jsonb_build_array('At least one active classroom required');
    END IF;

    -- Check seats
    IF v_has_license THEN
        SELECT COUNT(DISTINCT cm.user_id) INTO v_occupied
        FROM public.classroom_memberships cm
        JOIN public.classrooms c ON c.id = cm.classroom_id
        WHERE c.school_id = p_school_id AND c.status = 'active' AND cm.role = 'student' AND cm.status = 'active';

        IF v_occupied <= v_license.student_seat_limit THEN
            v_seat_ok := TRUE;
        ELSE
            v_errors := v_errors || jsonb_build_array(format('Occupied student seats (%s) exceeds seat limit (%s)', v_occupied, v_license.student_seat_limit));
        END IF;
    END IF;

    -- Check instructional coverage readiness
    SELECT COUNT(*) INTO v_nat_classes FROM public.classrooms WHERE school_id = p_school_id AND status = 'active' AND stream IN ('naturalScience', 'natural');
    SELECT COUNT(*) INTO v_soc_classes FROM public.classrooms WHERE school_id = p_school_id AND status = 'active' AND stream IN ('socialScience', 'social');
    v_required_slots := (v_nat_classes * 6) + (v_soc_classes * 6);

    SELECT COUNT(DISTINCT (classroom_id, subject_id, exam_variant)) INTO v_assigned_slots
    FROM public.teacher_subject_assignments
    WHERE school_id = p_school_id AND status = 'active';

    v_coverage_ok := (v_assigned_slots > 0 OR v_required_slots = 0);

    RETURN jsonb_build_object(
        'school_id', p_school_id,
        'is_ready', (v_has_license AND v_has_admin AND v_has_class AND v_has_year AND v_has_stream AND v_seat_ok),
        'checks', jsonb_build_object(
            'license_valid', v_has_license,
            'admin_configured', v_has_admin,
            'classrooms_configured', v_has_class,
            'academic_year_configured', v_has_year,
            'stream_configured', v_has_stream,
            'seat_capacity_ok', v_seat_ok,
            'coverage_noted', v_coverage_ok
        ),
        'required_instructional_slots', v_required_slots,
        'assigned_instructional_slots', v_assigned_slots,
        'errors', v_errors
    );
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 10b. activate_school_internal: Activates school and completes onboarding
CREATE OR REPLACE FUNCTION public.activate_school_internal(p_school_id UUID)
RETURNS public.schools AS $$
DECLARE
    v_caller_id  UUID := auth.uid();
    v_validation JSONB;
    v_school     public.schools%ROWTYPE;
BEGIN
    IF NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Caller % is not a platform_admin', v_caller_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    v_validation := public.validate_school_activation(p_school_id);
    IF NOT (v_validation->>'is_ready')::boolean THEN
        RAISE EXCEPTION 'ACTIVATION_BLOCKED: School % is not ready for activation. Errors: %',
            p_school_id, v_validation->'errors'
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE public.schools
    SET status = 'active',
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_school_id
    RETURNING * INTO v_school;

    -- Update onboarding state
    INSERT INTO public.school_onboarding_state (
        school_id, status, activation_ready, activated_at, updated_at
    ) VALUES (
        p_school_id, 'completed', TRUE, TIMEZONE('utc', NOW()), TIMEZONE('utc', NOW())
    )
    ON CONFLICT (school_id) DO UPDATE SET
        status = 'completed',
        activation_ready = TRUE,
        activated_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW());

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_activated', 'schools', p_school_id::TEXT,
        jsonb_build_object('school_id', p_school_id, 'validation', v_validation)
    );

    RETURN v_school;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 11. BULK STUDENT IMPORT & IDEMPOTENT ENROLLMENT
-- =============================================================================
CREATE OR REPLACE FUNCTION public.execute_bulk_student_enrollment_internal(
    p_school_id        UUID,
    p_classroom_id     UUID,
    p_students_payload JSONB, -- Array of objects: [{"student_identifier": "...", "display_name": "...", "phone": "..."}]
    p_idempotency_key  TEXT
) RETURNS JSONB AS $$
DECLARE
    v_caller_id       UUID := auth.uid();
    v_run             public.institutional_import_runs%ROWTYPE;
    v_classroom       public.classrooms%ROWTYPE;
    v_item            JSONB;
    v_identifier      TEXT;
    v_display_name    TEXT;
    v_phone           TEXT;
    v_user_id         UUID;
    v_total_rows      INT := 0;
    v_valid_rows      INT := 0;
    v_created         INT := 0;
    v_existing        INT := 0;
    v_error_count     INT := 0;
    v_errors          JSONB := '[]'::jsonb;
    v_new_candidates  INT := 0;
    v_existing_in_sch INT := 0;
BEGIN
    -- Authorization check: Platform Admin or School Admin of this school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(p_school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to import students for school %', v_caller_id, p_school_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Verify classroom belongs to target school
    SELECT * INTO v_classroom FROM public.classrooms WHERE id = p_classroom_id AND school_id = p_school_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom % does not belong to school %', p_classroom_id, p_school_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Check idempotency
    SELECT * INTO v_run
    FROM public.institutional_import_runs
    WHERE school_id = p_school_id AND idempotency_key = p_idempotency_key;

    IF FOUND AND v_run.status = 'committed' THEN
        -- Idempotent replay: return existing run results without duplicate insertion
        RETURN jsonb_build_object(
            'status', 'idempotent_replay',
            'import_run_id', v_run.id,
            'total_rows', v_run.total_rows,
            'valid_rows', v_run.valid_rows,
            'created_students', v_run.created_students,
            'existing_students', v_run.existing_students,
            'error_count', v_run.invalid_rows
        );
    END IF;

    v_total_rows := jsonb_array_length(p_students_payload);
    IF v_total_rows = 0 THEN
        RAISE EXCEPTION 'Payload contains zero student records'
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Pre-calculate how many unique NEW students will be added to the school
    -- to verify seat limits transactionally before committing.
    -- A student consumes a new seat ONLY if they are not already an active student in an active classroom of this school.
    CREATE TEMP TABLE IF NOT EXISTS _batch_candidate_students (
        uid UUID PRIMARY KEY
    ) ON COMMIT DROP;
    TRUNCATE _batch_candidate_students;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_students_payload)
    LOOP
        v_identifier := TRIM(COALESCE(v_item->>'student_identifier', ''));
        v_phone := TRIM(COALESCE(v_item->>'phone', ''));

        IF v_identifier = '' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_array('Missing student identifier');
            CONTINUE;
        END IF;

        -- Resolve user_id candidate
        v_user_id := NULL;
        IF v_phone != '' THEN
            SELECT id INTO v_user_id FROM public.profiles WHERE phone_number = v_phone;
        END IF;
        IF v_user_id IS NULL THEN
            SELECT user_id INTO v_user_id FROM public.school_memberships
            WHERE school_id = p_school_id AND school_student_id = v_identifier;
        END IF;
        IF v_user_id IS NULL THEN
            v_user_id := uuid_generate_v5(p_school_id, v_identifier);
        END IF;

        -- Check if student already occupies an active seat in this school
        IF NOT EXISTS (
            SELECT 1 FROM public.classroom_memberships cm
            JOIN public.classrooms c ON c.id = cm.classroom_id
            WHERE c.school_id = p_school_id
              AND c.status = 'active'
              AND cm.user_id = v_user_id
              AND cm.role = 'student'
              AND cm.status = 'active'
        ) THEN
            INSERT INTO _batch_candidate_students (uid) VALUES (v_user_id) ON CONFLICT (uid) DO NOTHING;
        END IF;
    END LOOP;

    SELECT COUNT(*) INTO v_new_candidates FROM _batch_candidate_students;

    -- Transactional seat capacity check!
    -- If adding the new students exceeds seat limit, the entire batch is blocked!
    PERFORM public.check_school_seat_capacity(p_school_id, v_new_candidates);

    -- Create import run tracker
    INSERT INTO public.institutional_import_runs (
        school_id, import_type, requested_by, status, total_rows, idempotency_key
    ) VALUES (
        p_school_id, 'students', v_caller_id, 'validating', v_total_rows, p_idempotency_key
    ) RETURNING * INTO v_run;

    -- Process students
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_students_payload)
    LOOP
        v_identifier := TRIM(COALESCE(v_item->>'student_identifier', ''));
        v_display_name := TRIM(COALESCE(v_item->>'display_name', 'Student ' || v_identifier));
        v_phone := TRIM(COALESCE(v_item->>'phone', ''));

        IF v_identifier = '' THEN
            CONTINUE;
        END IF;

        -- Resolve or create profile
        SELECT id INTO v_user_id
        FROM public.profiles
        WHERE phone_number = v_phone AND v_phone != '';

        IF v_user_id IS NULL THEN
            -- Check by school_student_id within this school
            SELECT user_id INTO v_user_id
            FROM public.school_memberships
            WHERE school_id = p_school_id AND school_student_id = v_identifier;
        END IF;

        IF v_user_id IS NULL THEN
            -- Generate deterministic student UUID based on school and identifier
            v_user_id := uuid_generate_v5(p_school_id, v_identifier);

            -- Ensure auth.users record exists
            INSERT INTO auth.users (id, phone)
            VALUES (
                v_user_id,
                CASE WHEN v_phone != '' THEN v_phone ELSE '+2519' || LPAD(SUBSTRING(REPLACE(v_user_id::text, '-', ''), 1, 8), 8, '0') END
            )
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.profiles (
                id, phone_number, display_name, grade, stream, preferred_language
            ) VALUES (
                v_user_id,
                CASE WHEN v_phone != '' THEN v_phone ELSE '+2519' || LPAD(SUBSTRING(REPLACE(v_user_id::text, '-', ''), 1, 8), 8, '0') END,
                v_display_name,
                v_classroom.grade,
                CASE
                    WHEN v_classroom.stream IN ('naturalScience', 'natural') THEN 'natural'
                    WHEN v_classroom.stream IN ('socialScience', 'social') THEN 'social'
                    ELSE 'natural'
                END,
                'en'
            )
            ON CONFLICT (id) DO UPDATE SET
                display_name = EXCLUDED.display_name,
                grade = EXCLUDED.grade;

            v_created := v_created + 1;
        ELSE
            v_existing := v_existing + 1;
        END IF;

        -- Ensure school membership
        INSERT INTO public.school_memberships (
            school_id, user_id, role, status, school_student_id, joined_at
        ) VALUES (
            p_school_id, v_user_id, 'student', 'active', v_identifier, TIMEZONE('utc', NOW())
        )
        ON CONFLICT (school_id, user_id) DO UPDATE SET
            status = 'active',
            school_student_id = EXCLUDED.school_student_id;

        -- Ensure classroom membership
        INSERT INTO public.classroom_memberships (
            classroom_id, user_id, role, status
        ) VALUES (
            p_classroom_id, v_user_id, 'student', 'active'
        )
        ON CONFLICT (classroom_id, user_id) DO UPDATE SET
            status = 'active';

        v_valid_rows := v_valid_rows + 1;
    END LOOP;

    -- Finalize import run record
    UPDATE public.institutional_import_runs
    SET status = 'committed',
        valid_rows = v_valid_rows,
        invalid_rows = v_error_count,
        created_students = v_created,
        existing_students = v_existing,
        error_summary = v_errors,
        completed_at = TIMEZONE('utc', NOW())
    WHERE id = v_run.id;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id, 'school_bulk_import_completed', 'institutional_import_runs', v_run.id::TEXT,
        jsonb_build_object(
            'school_id', p_school_id,
            'classroom_id', p_classroom_id,
            'total_rows', v_total_rows,
            'created', v_created,
            'existing', v_existing,
            'valid', v_valid_rows
        )
    );

    RETURN jsonb_build_object(
        'status', 'completed',
        'import_run_id', v_run.id,
        'total_rows', v_total_rows,
        'valid_rows', v_valid_rows,
        'created_students', v_created,
        'existing_students', v_existing,
        'invalid_rows', v_error_count
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 12. ENHANCED ASSIGN_STUDENT_TO_CLASSROOM WITH SEAT ENFORCEMENT
-- =============================================================================
-- Replaces previous function to enforce seat limits atomically
CREATE OR REPLACE FUNCTION public.assign_student_to_classroom_internal(
    p_classroom_id UUID,
    p_user_id      UUID,
    p_role         TEXT DEFAULT 'student'
) RETURNS public.classroom_memberships AS $$
DECLARE
    v_caller_id   UUID := auth.uid();
    v_classroom   public.classrooms%ROWTYPE;
    v_cm          public.classroom_memberships%ROWTYPE;
    v_already_in_other_class BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_classroom FROM public.classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom % not found', p_classroom_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Caller authorization check: Platform Admin or School Admin of the classroom's school
    IF NOT (public.is_platform_admin() OR public.is_school_admin(v_classroom.school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to manage classroom %', v_caller_id, p_classroom_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- CROSS-TENANT INTEGRITY: Verify target user has an active membership in the classroom's school!
    IF NOT EXISTS (
        SELECT 1 FROM public.school_memberships
        WHERE school_id = v_classroom.school_id
          AND user_id = p_user_id
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Target user % does not have an active membership in school %', p_user_id, v_classroom.school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- P11 SEAT ENFORCEMENT FOR STUDENTS:
    -- If role is 'student', check if this student is already enrolled in another active classroom in this school.
    -- If YES: they already occupy a commercial seat; enrolling in a second classroom does not increment seat usage.
    -- If NO: this enrollment consumes a new seat, so we must atomically check capacity!
    IF p_role = 'student' THEN
        SELECT EXISTS (
            SELECT 1 FROM public.classroom_memberships cm_other
            JOIN public.classrooms c_other ON c_other.id = cm_other.classroom_id
            WHERE c_other.school_id = v_classroom.school_id
              AND c_other.status = 'active'
              AND cm_other.user_id = p_user_id
              AND cm_other.role = 'student'
              AND cm_other.status = 'active'
              AND cm_other.classroom_id != p_classroom_id
        ) INTO v_already_in_other_class;

        IF NOT v_already_in_other_class THEN
            -- Check if they already have an active membership in this exact classroom
            IF NOT EXISTS (
                SELECT 1 FROM public.classroom_memberships
                WHERE classroom_id = p_classroom_id AND user_id = p_user_id AND status = 'active'
            ) THEN
                PERFORM public.check_school_seat_capacity(v_classroom.school_id, 1);
            END IF;
        END IF;
    END IF;

    -- Upsert classroom membership
    INSERT INTO public.classroom_memberships (
        classroom_id,
        user_id,
        role,
        status,
        updated_at
    ) VALUES (
        p_classroom_id,
        p_user_id,
        p_role,
        'active',
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (classroom_id, user_id) DO UPDATE SET
        role       = EXCLUDED.role,
        status     = 'active',
        updated_at = TIMEZONE('utc', NOW())
    RETURNING * INTO v_cm;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'classroom_member_assigned',
        'classroom_memberships',
        v_cm.id::TEXT,
        jsonb_build_object(
            'school_id', v_classroom.school_id,
            'classroom_id', p_classroom_id,
            'target_user_id', p_user_id,
            'role', p_role
        )
    );

    RETURN v_cm;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 12b. UPDATE CLASSROOM MEMBER STATUS INTERNAL
-- =============================================================================
CREATE OR REPLACE FUNCTION public.update_classroom_member_status_internal(
    p_classroom_id UUID,
    p_user_id      UUID,
    p_status       TEXT
) RETURNS public.classroom_memberships AS $$
DECLARE
    v_caller_id   UUID := auth.uid();
    v_classroom   public.classrooms%ROWTYPE;
    v_cm          public.classroom_memberships%ROWTYPE;
BEGIN
    SELECT * INTO v_classroom FROM public.classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom % not found', p_classroom_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    IF NOT (public.is_platform_admin() OR public.is_school_admin(v_classroom.school_id)) THEN
        RAISE EXCEPTION 'Caller % is not authorized to manage classroom %', v_caller_id, p_classroom_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    IF p_status NOT IN ('active', 'inactive', 'removed') THEN
        RAISE EXCEPTION 'Invalid classroom membership status: %', p_status
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- P11 SEAT ENFORCEMENT ON STUDENT REACTIVATION:
    -- If reactivating a student to 'active', enforce seat limit if they are not already active in another class
    IF p_status = 'active' THEN
        SELECT * INTO v_cm FROM public.classroom_memberships WHERE classroom_id = p_classroom_id AND user_id = p_user_id;
        IF FOUND AND v_cm.role = 'student' AND v_cm.status != 'active' THEN
            DECLARE
                v_already_in_other_class BOOLEAN := FALSE;
            BEGIN
                SELECT EXISTS (
                    SELECT 1 FROM public.classroom_memberships cm_other
                    JOIN public.classrooms c_other ON c_other.id = cm_other.classroom_id
                    WHERE c_other.school_id = v_classroom.school_id
                      AND c_other.status = 'active'
                      AND cm_other.user_id = p_user_id
                      AND cm_other.role = 'student'
                      AND cm_other.status = 'active'
                      AND cm_other.classroom_id != p_classroom_id
                ) INTO v_already_in_other_class;

                IF NOT v_already_in_other_class THEN
                    PERFORM public.check_school_seat_capacity(v_classroom.school_id, 1);
                END IF;
            END;
        END IF;
    END IF;

    UPDATE public.classroom_memberships
    SET status = p_status,
        updated_at = TIMEZONE('utc', NOW())
    WHERE classroom_id = p_classroom_id AND user_id = p_user_id
    RETURNING * INTO v_cm;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Classroom membership for user % in classroom % not found', p_user_id, p_classroom_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        v_caller_id,
        'classroom_member_status_updated',
        'classroom_memberships',
        v_cm.id::TEXT,
        jsonb_build_object(
            'school_id', v_classroom.school_id,
            'classroom_id', p_classroom_id,
            'target_user_id', p_user_id,
            'status', p_status
        )
    );

    RETURN v_cm;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

GRANT EXECUTE ON FUNCTION public.update_classroom_member_status_internal(UUID, UUID, TEXT) TO authenticated;

-- =============================================================================
-- 13. BILLING EVENT PROCESSING ENGINE (IDEMPOTENT & TIME-ORDERED)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.process_billing_event_internal(
    p_provider          TEXT,
    p_provider_event_id TEXT,
    p_event_type        TEXT,
    p_school_id         UUID,
    p_payload_hash      TEXT,
    p_new_license_status TEXT DEFAULT NULL,
    p_period_start      TIMESTAMPTZ DEFAULT NULL,
    p_period_end        TIMESTAMPTZ DEFAULT NULL,
    p_seat_limit        INT DEFAULT NULL,
    p_event_timestamp   TIMESTAMPTZ DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_existing_event public.billing_events%ROWTYPE;
    v_event          public.billing_events%ROWTYPE;
    v_license        public.school_licenses%ROWTYPE;
    v_watermark      TIMESTAMPTZ;
BEGIN
    -- Authority Guard: Only service_role, platform_admin, or database superuser can ingest billing events
    IF current_user NOT IN ('postgres', 'supabase_admin') AND auth.role() != 'service_role' AND NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Billing ingestion requires service_role or platform_admin authority'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Idempotency check: (provider, provider_event_id)
    SELECT * INTO v_existing_event
    FROM public.billing_events
    WHERE provider = p_provider AND provider_event_id = p_provider_event_id;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'status', 'ignored_duplicate',
            'event_id', v_existing_event.id,
            'message', 'Billing event already processed'
        );
    END IF;

    -- Record event in ingestion ledger
    INSERT INTO public.billing_events (
        provider, provider_event_id, event_type, school_id, payload_hash, event_timestamp, status, processed_at
    ) VALUES (
        p_provider, p_provider_event_id, p_event_type, p_school_id, p_payload_hash, p_event_timestamp, 'received', TIMEZONE('utc', NOW())
    ) RETURNING * INTO v_event;

    -- If school_id is provided and license exists, apply business logic transitions:
    IF p_school_id IS NOT NULL THEN
        SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id FOR UPDATE;
        IF FOUND THEN
            -- Canonical Billing Watermark:
            -- Use last_billing_event_at from license, or latest accepted event timestamp/processed_at from billing_events
            v_watermark := v_license.last_billing_event_at;
            IF v_watermark IS NULL THEN
                SELECT COALESCE(MAX(event_timestamp), MAX(processed_at))
                INTO v_watermark
                FROM public.billing_events
                WHERE school_id = p_school_id
                  AND status = 'processed';
            END IF;

            -- True Stale Event Check based on billing watermark (NOT generic license updated_at!)
            IF p_event_timestamp IS NOT NULL AND v_watermark IS NOT NULL AND p_event_timestamp < v_watermark THEN
                UPDATE public.billing_events
                SET status = 'ignored',
                    error_message = 'Stale billing event: timestamp ' || p_event_timestamp || ' is older than billing watermark ' || v_watermark
                WHERE id = v_event.id;

                RETURN jsonb_build_object(
                    'status', 'ignored_stale',
                    'event_id', v_event.id,
                    'message', 'Stale billing event ignored; newer billing event watermark exists'
                );
            END IF;

            -- Payment Succeeded / Invoice Paid -> Activate or renew license
            IF p_event_type IN ('payment_succeeded', 'invoice_paid', 'subscription_renewed') THEN
                UPDATE public.school_licenses
                SET status = 'active',
                    starts_at = COALESCE(p_period_start, starts_at),
                    ends_at = COALESCE(p_period_end, ends_at),
                    student_seat_limit = COALESCE(p_seat_limit, student_seat_limit),
                    grace_ends_at = NULL,
                    last_billing_event_at = GREATEST(COALESCE(p_event_timestamp, TIMEZONE('utc', NOW())), COALESCE(v_license.last_billing_event_at, '-infinity'::timestamptz)),
                    updated_at = TIMEZONE('utc', NOW())
                WHERE id = v_license.id;

                INSERT INTO public.school_license_events (
                    school_id, license_id, event_type, old_status, new_status,
                    old_seat_limit, new_seat_limit, reason, event_source, metadata
                ) VALUES (
                    p_school_id, v_license.id, 'license_renewed_via_billing', v_license.status, 'active',
                    v_license.student_seat_limit, COALESCE(p_seat_limit, v_license.student_seat_limit),
                    'Billing webhook event ' || p_event_type, p_provider,
                    jsonb_build_object('event_id', p_provider_event_id, 'period_end', p_period_end)
                );

            -- Payment Failed -> Enter grace period
            ELSIF p_event_type IN ('payment_failed', 'invoice_payment_failed') THEN
                -- Only enter grace if currently active
                IF v_license.status = 'active' THEN
                    -- Guard against older period end if future renewal already happened
                    IF (p_period_end IS NOT NULL AND v_license.ends_at IS NOT NULL AND p_period_end < v_license.ends_at) THEN
                        UPDATE public.billing_events
                        SET status = 'ignored',
                            error_message = 'Stale payment failure received after successful renewal'
                        WHERE id = v_event.id;

                        RETURN jsonb_build_object(
                            'status', 'ignored_stale',
                            'event_id', v_event.id,
                            'message', 'Stale payment failure ignored; license active through future date'
                        );
                    END IF;

                    UPDATE public.school_licenses
                    SET status = 'grace',
                        grace_ends_at = TIMEZONE('utc', NOW()) + INTERVAL '14 days',
                        last_billing_event_at = GREATEST(COALESCE(p_event_timestamp, TIMEZONE('utc', NOW())), COALESCE(v_license.last_billing_event_at, '-infinity'::timestamptz)),
                        updated_at = TIMEZONE('utc', NOW())
                    WHERE id = v_license.id;

                    INSERT INTO public.school_license_events (
                        school_id, license_id, event_type, old_status, new_status,
                        old_seat_limit, new_seat_limit, reason, event_source
                    ) VALUES (
                        p_school_id, v_license.id, 'license_entered_grace', 'active', 'grace',
                        v_license.student_seat_limit, v_license.student_seat_limit,
                        'Billing payment failure webhook', p_provider
                    );
                END IF;

            -- Subscription Canceled
            ELSIF p_event_type IN ('subscription_canceled', 'customer_subscription_deleted') THEN
                UPDATE public.school_licenses
                SET status = 'cancelled',
                    last_billing_event_at = GREATEST(COALESCE(p_event_timestamp, TIMEZONE('utc', NOW())), COALESCE(v_license.last_billing_event_at, '-infinity'::timestamptz)),
                    updated_at = TIMEZONE('utc', NOW())
                WHERE id = v_license.id;

                INSERT INTO public.school_license_events (
                    school_id, license_id, event_type, old_status, new_status,
                    old_seat_limit, new_seat_limit, reason, event_source
                ) VALUES (
                    p_school_id, v_license.id, 'license_cancelled_via_billing', v_license.status, 'cancelled',
                    v_license.student_seat_limit, v_license.student_seat_limit,
                    'Billing subscription cancellation webhook', p_provider
                );
            END IF;
        END IF;
    END IF;

    -- Update billing event status to processed
    UPDATE public.billing_events
    SET status = 'processed',
        processed_at = TIMEZONE('utc', NOW())
    WHERE id = v_event.id;

    -- Audit log (no secret or sensitive PII written)
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        NULL, 'billing_event_processed', 'billing_events', v_event.id::TEXT,
        jsonb_build_object('provider', p_provider, 'event_type', p_event_type, 'school_id', p_school_id)
    );

    RETURN jsonb_build_object(
        'status', 'processed',
        'event_id', v_event.id,
        'provider_event_id', p_provider_event_id
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 14. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.institutional_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_license_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_onboarding_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institutional_import_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_events ENABLE ROW LEVEL SECURITY;

-- 14a. institutional_plans: Read for authenticated, write for platform_admin
CREATE POLICY "institutional_plans_read" ON public.institutional_plans
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "institutional_plans_no_direct_insert" ON public.institutional_plans
    FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "institutional_plans_no_direct_update" ON public.institutional_plans
    FOR UPDATE USING (FALSE);
CREATE POLICY "institutional_plans_no_direct_delete" ON public.institutional_plans
    FOR DELETE USING (FALSE);

-- 14b. school_licenses: Read for School Admin of that school or Platform Admin
CREATE POLICY "school_licenses_select" ON public.school_licenses
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

CREATE POLICY "school_licenses_no_direct_insert" ON public.school_licenses
    FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "school_licenses_no_direct_update" ON public.school_licenses
    FOR UPDATE USING (FALSE);
CREATE POLICY "school_licenses_no_direct_delete" ON public.school_licenses
    FOR DELETE USING (FALSE);

-- 14c. school_license_events: Read for School Admin or Platform Admin
CREATE POLICY "school_license_events_select" ON public.school_license_events
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

CREATE POLICY "school_license_events_no_direct_insert" ON public.school_license_events
    FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "school_license_events_no_direct_update" ON public.school_license_events
    FOR UPDATE USING (FALSE);
CREATE POLICY "school_license_events_no_direct_delete" ON public.school_license_events
    FOR DELETE USING (FALSE);

-- 14d. school_onboarding_state: Read for School Admin or Platform Admin
CREATE POLICY "school_onboarding_state_select" ON public.school_onboarding_state
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

CREATE POLICY "school_onboarding_state_no_direct_insert" ON public.school_onboarding_state
    FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "school_onboarding_state_no_direct_update" ON public.school_onboarding_state
    FOR UPDATE USING (FALSE);
CREATE POLICY "school_onboarding_state_no_direct_delete" ON public.school_onboarding_state
    FOR DELETE USING (FALSE);

-- 14e. institutional_import_runs: Read for School Admin or Platform Admin
CREATE POLICY "institutional_import_runs_select" ON public.institutional_import_runs
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );

CREATE POLICY "institutional_import_runs_no_direct_insert" ON public.institutional_import_runs
    FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "institutional_import_runs_no_direct_update" ON public.institutional_import_runs
    FOR UPDATE USING (FALSE);
CREATE POLICY "institutional_import_runs_no_direct_delete" ON public.institutional_import_runs
    FOR DELETE USING (FALSE);

-- 14f. billing_customers & billing_subscriptions: Read for School Admin or Platform Admin
CREATE POLICY "billing_customers_select" ON public.billing_customers
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );
CREATE POLICY "billing_customers_no_direct_mutation" ON public.billing_customers
    FOR ALL USING (FALSE);

CREATE POLICY "billing_subscriptions_select" ON public.billing_subscriptions
    FOR SELECT USING (
        public.is_school_admin(school_id) OR public.is_platform_admin()
    );
CREATE POLICY "billing_subscriptions_no_direct_mutation" ON public.billing_subscriptions
    FOR ALL USING (FALSE);

-- 14g. billing_events: Platform Admin only
CREATE POLICY "billing_events_select" ON public.billing_events
    FOR SELECT USING (public.is_platform_admin());
CREATE POLICY "billing_events_no_direct_mutation" ON public.billing_events
    FOR ALL USING (FALSE);

-- Grants
GRANT SELECT ON public.institutional_plans TO authenticated;
GRANT SELECT ON public.school_licenses TO authenticated;
GRANT SELECT ON public.school_license_events TO authenticated;
GRANT SELECT ON public.school_onboarding_state TO authenticated;
GRANT SELECT ON public.institutional_import_runs TO authenticated;
GRANT SELECT ON public.billing_customers TO authenticated;
GRANT SELECT ON public.billing_subscriptions TO authenticated;
GRANT SELECT ON public.billing_events TO authenticated;

-- =============================================================================
-- 15. P11 INTEGRATION HOOKS: SEAT & ENTITLEMENT ENFORCEMENT ACROSS P6–P10
-- =============================================================================

-- 15a. P6 Legacy Entrypoint: assign_classroom_member_internal
-- Unifies legacy membership assignment with P11 seat enforcement
CREATE OR REPLACE FUNCTION public.assign_classroom_member_internal(
    p_classroom_id UUID,
    p_user_id      UUID,
    p_role         TEXT DEFAULT 'student'
) RETURNS public.classroom_memberships AS $$
BEGIN
    RETURN public.assign_student_to_classroom_internal(p_classroom_id, p_user_id, p_role);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 15b. P7 Teacher Portal: resolve_teacher_class_subject_school
CREATE OR REPLACE FUNCTION public.resolve_teacher_class_subject_school(
  p_classroom_id UUID,
  p_subject_id   TEXT
)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT tsa.school_id
  FROM   public.teacher_subject_assignments tsa
  JOIN   public.school_memberships sm
         ON  sm.user_id   = auth.uid()
         AND sm.school_id  = tsa.school_id
         AND sm.role       = 'teacher'
         AND sm.status     = 'active'
  JOIN   public.schools s
         ON  s.id         = tsa.school_id
         AND s.status     = 'active'
  WHERE  tsa.teacher_user_id = auth.uid()
    AND  tsa.classroom_id    = p_classroom_id
    AND  tsa.subject_id      = p_subject_id
    AND  tsa.status          = 'active'
    AND  (
      NOT EXISTS (SELECT 1 FROM public.school_licenses sl WHERE sl.school_id = tsa.school_id)
      OR public.school_has_entitlement(tsa.school_id, 'teacher_portal')
    )
  LIMIT 1;
$$;

-- 15c. P7 Teacher Portal: get_teacher_assigned_classes
CREATE OR REPLACE FUNCTION public.get_teacher_assigned_classes(
  p_school_id UUID
)
RETURNS TABLE (
  assignment_id           UUID,
  classroom_id            UUID,
  classroom_name          TEXT,
  classroom_grade         INT,
  classroom_stream        TEXT,
  classroom_section       TEXT,
  classroom_academic_year TEXT,
  classroom_status        TEXT,
  subject_id              TEXT,
  exam_variant            TEXT,
  enrolled_student_count  INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Verify caller is an active teacher in an active school
  IF NOT EXISTS (
    SELECT 1
    FROM   public.school_memberships sm
    JOIN   public.schools s ON s.id = sm.school_id AND s.status = 'active'
    WHERE  sm.user_id   = auth.uid()
      AND  sm.school_id = p_school_id
      AND  sm.role      = 'teacher'
      AND  sm.status    = 'active'
  ) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED: caller is not an active teacher in this active school'
      USING ERRCODE = '42501';
  END IF;

  -- Entitlement guard: teacher_portal
  IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = p_school_id) THEN
    IF NOT public.school_has_entitlement(p_school_id, 'teacher_portal') THEN
      RAISE EXCEPTION 'Teacher portal access denied: school % does not have active teacher_portal entitlement', p_school_id
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    tsa.id                              AS assignment_id,
    c.id                                AS classroom_id,
    c.name                              AS classroom_name,
    c.grade                             AS classroom_grade,
    c.stream                            AS classroom_stream,
    c.section                           AS classroom_section,
    c.academic_year                     AS classroom_academic_year,
    c.status                            AS classroom_status,
    tsa.subject_id,
    tsa.exam_variant,
    (
      SELECT COUNT(*)::INT
      FROM   public.classroom_memberships cm
      WHERE  cm.classroom_id = c.id
        AND  cm.role         = 'student'
        AND  cm.status       = 'active'
    )                                   AS enrolled_student_count
  FROM   public.teacher_subject_assignments tsa
  JOIN   public.classrooms c ON c.id = tsa.classroom_id AND c.status = 'active'
  WHERE  tsa.school_id       = p_school_id
    AND  tsa.teacher_user_id = auth.uid()
    AND  tsa.status          = 'active'
  ORDER BY c.grade ASC, c.section ASC, tsa.subject_id ASC;
END;
$$;

-- 15d. P8 Leadership Dashboard: resolve_school_admin_authority
CREATE OR REPLACE FUNCTION public.resolve_school_admin_authority(
  p_school_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_school_id IS NULL OR auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Platform admin has global support oversight
  IF public.is_platform_admin() THEN
    RETURN TRUE;
  END IF;

  -- P11 Commercial Entitlement Guard: leadership_dashboard
  IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = p_school_id) THEN
    IF NOT public.school_has_entitlement(p_school_id, 'leadership_dashboard') THEN
      RETURN FALSE;
    END IF;
  END IF;

  -- Active school admin in active school
  RETURN EXISTS (
    SELECT 1
    FROM   public.school_memberships sm
    JOIN   public.schools s ON s.id = sm.school_id
    WHERE  sm.user_id   = auth.uid()
      AND  sm.school_id = p_school_id
      AND  sm.role      = 'school_admin'
      AND  sm.status    = 'active'
      AND  s.status     = 'active'
  );
END;
$$;

-- 15e. P9 Assignments & Interventions: can_teacher_manage_assignment
CREATE OR REPLACE FUNCTION public.can_teacher_manage_assignment(
    p_school_id    UUID,
    p_classroom_id UUID,
    p_subject_id   TEXT,
    p_exam_variant TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   public.teacher_subject_assignments tsa
        JOIN   public.school_memberships sm
               ON  sm.user_id   = auth.uid()
               AND sm.school_id  = tsa.school_id
               AND sm.role       = 'teacher'
               AND sm.status     = 'active'
        JOIN   public.schools s
               ON  s.id         = tsa.school_id
               AND s.status     = 'active'
        WHERE  tsa.teacher_user_id = auth.uid()
          AND  tsa.school_id       = p_school_id
          AND  tsa.classroom_id    = p_classroom_id
          AND  tsa.subject_id      = p_subject_id
          AND  tsa.status          = 'active'
          AND  (
              NOT EXISTS (SELECT 1 FROM public.school_licenses sl WHERE sl.school_id = p_school_id)
              OR public.school_has_entitlement(p_school_id, 'assignments_interventions')
          )
          AND  (
              -- Mathematics canonical rule: strict variant matching
              CASE
                  WHEN p_subject_id = 'math_g12' THEN tsa.exam_variant = p_exam_variant
                  ELSE (tsa.exam_variant IS NOT DISTINCT FROM p_exam_variant OR tsa.exam_variant IS NULL)
              END
          )
    );
$$;

-- 15f. P9 Assignments & Interventions: close_learning_assignment
CREATE OR REPLACE FUNCTION public.close_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close this assignment' USING ERRCODE = '42501';
    END IF;

    IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = v_assign.school_id) THEN
        IF NOT public.school_has_entitlement(v_assign.school_id, 'assignments_interventions') THEN
            RAISE EXCEPTION 'Institutional mutations denied: assignments_interventions entitlement inactive'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    UPDATE public.learning_assignments
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_closed', 'learning_assignments', p_assignment_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

-- 15g. P9 Assignments & Interventions: archive_learning_assignment
CREATE OR REPLACE FUNCTION public.archive_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can archive this assignment' USING ERRCODE = '42501';
    END IF;

    IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = v_assign.school_id) THEN
        IF NOT public.school_has_entitlement(v_assign.school_id, 'assignments_interventions') THEN
            RAISE EXCEPTION 'Institutional mutations denied: assignments_interventions entitlement inactive'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    UPDATE public.learning_assignments
    SET status = 'archived',
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_archived', 'learning_assignments', p_assignment_id, jsonb_build_object('archived_at', NOW()));

    RETURN true;
END;
$$;

-- 15h. P9 Assignments & Interventions: complete_student_intervention
CREATE OR REPLACE FUNCTION public.complete_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can complete intervention' USING ERRCODE = '42501';
    END IF;

    IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = v_rec.school_id) THEN
        IF NOT public.school_has_entitlement(v_rec.school_id, 'assignments_interventions') THEN
            RAISE EXCEPTION 'Institutional mutations denied: assignments_interventions entitlement inactive'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    UPDATE public.student_interventions
    SET status = 'completed',
        completed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_completed', 'student_interventions', p_intervention_id, jsonb_build_object('completed_at', NOW()));

    RETURN true;
END;
$$;

-- 15i. P9 Assignments & Interventions: close_student_intervention
CREATE OR REPLACE FUNCTION public.close_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close intervention' USING ERRCODE = '42501';
    END IF;

    IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = v_rec.school_id) THEN
        IF NOT public.school_has_entitlement(v_rec.school_id, 'assignments_interventions') THEN
            RAISE EXCEPTION 'Institutional mutations denied: assignments_interventions entitlement inactive'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    UPDATE public.student_interventions
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_closed', 'student_interventions', p_intervention_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

-- 15j. P10 Reporting Entitlement Enforcement: validate_report_authority
CREATE OR REPLACE FUNCTION public.validate_report_authority(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_exam_variant TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NULL OR p_school_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Platform admin has global oversight
    IF public.is_platform_admin() THEN
        RETURN TRUE;
    END IF;

    -- P11 Entitlement Enforcement:
    -- If school has an institutional license configured, verify 'institutional_reporting' entitlement
    IF EXISTS (SELECT 1 FROM public.school_licenses WHERE school_id = p_school_id) THEN
        IF NOT public.school_has_entitlement(p_school_id, 'institutional_reporting') THEN
            RETURN FALSE;
        END IF;
    END IF;

    -- School admin has full oversight of own active school
    IF public.is_school_admin(p_school_id) THEN
        -- If classroom filter is provided, verify it belongs to this school
        IF p_classroom_id IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM public.classrooms c
                WHERE c.id = p_classroom_id AND c.school_id = p_school_id
            ) THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    END IF;

    -- Teacher must have active membership and be assigned to classroom + subject
    IF public.is_teacher_in_school(p_school_id) THEN
        -- Teacher MUST provide classroom and subject for teacher reporting
        IF p_classroom_id IS NULL OR p_subject_id IS NULL THEN
            RETURN FALSE; -- Teachers cannot access school-wide aggregate reports
        END IF;

        RETURN EXISTS (
            SELECT 1 FROM public.teacher_subject_assignments tsa
            JOIN public.schools s ON s.id = tsa.school_id
            JOIN public.school_memberships sm ON sm.school_id = tsa.school_id AND sm.user_id = tsa.teacher_user_id
            JOIN public.classrooms c ON c.id = tsa.classroom_id
            WHERE tsa.school_id = p_school_id
              AND tsa.classroom_id = p_classroom_id
              AND tsa.subject_id = p_subject_id
              AND tsa.teacher_user_id = auth.uid()
              AND s.status = 'active'
              AND sm.status = 'active'
              AND sm.role = 'teacher'
              AND c.status = 'active'
              AND (
                  p_exam_variant IS NULL
                  OR tsa.exam_variant IS NULL
                  OR tsa.exam_variant = p_exam_variant
                  OR (p_subject_id = 'math_g12' AND tsa.exam_variant = p_exam_variant)
              )
        );
    END IF;

    RETURN FALSE;
END;
$$;

-- 15k. Scheduled Server Lifecycle Transition Engine
CREATE OR REPLACE FUNCTION public.sync_school_license_expiration_internal(
    p_school_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_now TIMESTAMPTZ := NOW();
    v_expired_count INT := 0;
    v_grace_count INT := 0;
    v_suspended_count INT := 0;
    v_row RECORD;
BEGIN
    IF current_user NOT IN ('postgres', 'supabase_admin') AND auth.role() != 'service_role' AND NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Requires service_role or platform_admin authority'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- 1. Active/trial licenses where ends_at < now -> grace or expired
    FOR v_row IN
        SELECT id, school_id, status, ends_at, grace_ends_at
        FROM public.school_licenses
        WHERE (p_school_id IS NULL OR school_id = p_school_id)
          AND status IN ('trial', 'active')
          AND ends_at IS NOT NULL
          AND ends_at < v_now
        FOR UPDATE
    LOOP
        IF v_row.grace_ends_at IS NOT NULL AND v_row.grace_ends_at >= v_now THEN
            UPDATE public.school_licenses
            SET status = 'grace', updated_at = v_now
            WHERE id = v_row.id;
            v_grace_count := v_grace_count + 1;

            INSERT INTO public.school_license_events (
                school_id, license_id, event_type, old_status, new_status, reason, actor_id
            ) VALUES (
                v_row.school_id, v_row.id, 'license_entered_grace_scheduled', v_row.status, 'grace', 'Ends at reached; within grace period', v_caller_id
            );
        ELSE
            UPDATE public.school_licenses
            SET status = 'expired', updated_at = v_now
            WHERE id = v_row.id;
            v_expired_count := v_expired_count + 1;

            INSERT INTO public.school_license_events (
                school_id, license_id, event_type, old_status, new_status, reason, actor_id
            ) VALUES (
                v_row.school_id, v_row.id, 'license_expired_scheduled', v_row.status, 'expired', 'License term expired', v_caller_id
            );
        END IF;
    END LOOP;

    -- 2. Grace licenses where grace_ends_at < now -> suspended
    FOR v_row IN
        SELECT id, school_id, status
        FROM public.school_licenses
        WHERE (p_school_id IS NULL OR school_id = p_school_id)
          AND status = 'grace'
          AND grace_ends_at IS NOT NULL
          AND grace_ends_at < v_now
        FOR UPDATE
    LOOP
        UPDATE public.school_licenses
        SET status = 'suspended', updated_at = v_now
        WHERE id = v_row.id;
        v_suspended_count := v_suspended_count + 1;

        INSERT INTO public.school_license_events (
            school_id, license_id, event_type, old_status, new_status, reason, actor_id
        ) VALUES (
            v_row.school_id, v_row.id, 'license_suspended_scheduled', 'grace', 'suspended', 'Grace period expired without resolution', v_caller_id
        );
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'completed',
        'transitioned_to_grace', v_grace_count,
        'transitioned_to_expired', v_expired_count,
        'transitioned_to_suspended', v_suspended_count
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 16. PRIVILEGED ACCESS CONTROLS: STRICT REVOCATION & MINIMUM GRANTS
-- =============================================================================

-- Step A: Explicitly REVOKE ALL from PUBLIC and anon on ALL P11 and hooked functions
REVOKE ALL ON FUNCTION public.is_school_license_effective(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_school_seat_usage(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.check_school_seat_capacity(UUID, INT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_school_entitlements(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.school_has_entitlement(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_school_license_internal(UUID, TEXT, INT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, JSONB) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.transition_school_license_internal(UUID, TEXT, TEXT, TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_school_seat_limit_internal(UUID, INT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_school_entitlements_internal(UUID, JSONB, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_school_license(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_school_activation(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.activate_school_internal(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.execute_bulk_student_enrollment_internal(UUID, UUID, JSONB, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.assign_student_to_classroom_internal(UUID, UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_classroom_member_status_internal(UUID, UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.process_billing_event_internal(TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, TIMESTAMPTZ) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.assign_classroom_member_internal(UUID, UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_teacher_class_subject_school(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_teacher_assigned_classes(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_school_admin_authority(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.close_learning_assignment(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.archive_learning_assignment(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.complete_student_intervention(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.close_student_intervention(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_report_authority(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sync_school_license_expiration_internal(UUID) FROM PUBLIC, anon, authenticated;

-- Step B: Minimum Grants for Caller-Facing RPCs
GRANT EXECUTE ON FUNCTION public.is_school_license_effective(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_school_seat_usage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_school_seat_capacity(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_school_entitlements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.school_has_entitlement(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_school_license_internal(UUID, TEXT, INT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transition_school_license_internal(UUID, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_school_seat_limit_internal(UUID, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_school_entitlements_internal(UUID, JSONB, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_school_license(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_school_activation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_school_internal(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.execute_bulk_student_enrollment_internal(UUID, UUID, JSONB, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_student_to_classroom_internal(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_classroom_member_internal(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_classroom_member_status_internal(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_teacher_class_subject_school(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_teacher_assigned_classes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_school_admin_authority(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.close_learning_assignment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_learning_assignment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_student_intervention(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.close_student_intervention(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_report_authority(UUID, UUID, TEXT, TEXT) TO authenticated;

-- Step C: Server / Service-Role Only RPCs
GRANT EXECUTE ON FUNCTION public.process_billing_event_internal(TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION public.sync_school_license_expiration_internal(UUID) TO service_role;

-- Step D: Grant table access so Row Level Security (RLS) policies can evaluate
GRANT SELECT ON public.institutional_plans,
                public.school_licenses,
                public.school_license_events,
                public.school_onboarding_state,
                public.institutional_import_runs,
                public.billing_customers,
                public.billing_subscriptions,
                public.billing_events
TO anon, authenticated, service_role;
-- =============================================================================
-- Migration: 20260925060000_p12_production_readiness.sql
-- Priority 12: Production Launch & Pilot Readiness
--
-- Capabilities:
--   1. Server-side system health & readiness check (system_health_status)
--   2. Client version compatibility registry & evaluation (check_client_compatibility)
--   3. Audited read-only support operational diagnostics (get_school_operational_summary, get_student_sync_diagnostic)
--   4. Production release metadata tracking (production_releases)
--   5. Hardened SECURITY DEFINER execution with SET search_path = public, pg_temp
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. System Health & Readiness Verification
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.system_health_status()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_active_licenses INT := 0;
    v_total_schools INT := 0;
    v_audit_count INT := 0;
    v_now TIMESTAMPTZ := NOW();
    v_is_operator BOOLEAN := FALSE;
BEGIN
    -- Check if caller is platform_admin or service_role
    IF auth.role() = 'service_role' OR public.is_platform_admin() THEN
        v_is_operator := TRUE;
    END IF;

    -- For ordinary authenticated users (students/teachers): data minimization
    IF NOT v_is_operator THEN
        RETURN jsonb_build_object(
            'status', 'operational',
            'database', 'healthy',
            'server_time', v_now
        );
    END IF;

    -- For authorized platform operators: full telemetry
    SELECT COUNT(*) INTO v_active_licenses
    FROM public.school_licenses
    WHERE status IN ('trial', 'active', 'grace');

    SELECT COUNT(*) INTO v_total_schools
    FROM public.schools;

    SELECT COUNT(*) INTO v_audit_count
    FROM public.audit_log;

    RETURN jsonb_build_object(
        'status', 'operational',
        'database', 'healthy',
        'server_time', v_now,
        'schema_version', 'p12_20260925060000',
        'active_licenses_count', v_active_licenses,
        'total_schools_count', v_total_schools,
        'audit_events_count', v_audit_count
    );
END;
$$;

COMMENT ON FUNCTION public.system_health_status() IS
    'Returns server-side system readiness and operational telemetry. Restricted to authenticated and service_role.';

-- -----------------------------------------------------------------------------
-- 2. Client Version Compatibility Registry
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.client_version_compatibility (
    id SERIAL PRIMARY KEY,
    platform TEXT NOT NULL, -- 'android', 'windows', 'web', 'ios'
    minimum_supported_version TEXT NOT NULL,
    recommended_version TEXT NOT NULL,
    latest_version TEXT NOT NULL,
    force_update_message_en TEXT NOT NULL DEFAULT 'Please update FidelLearn to continue accessing exams and syncing.',
    force_update_message_am TEXT NOT NULL DEFAULT 'እባክዎ ፈተናዎችን ለማግኘት እና ለማመሳሰል የፊደል ለርን መተግበሪያን ያዘምኑ።',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_client_compat_platform_active
    ON public.client_version_compatibility(platform)
    WHERE is_active = true;

-- Seed default compatibility records
INSERT INTO public.client_version_compatibility (
    platform, minimum_supported_version, recommended_version, latest_version, is_active
) VALUES
    ('android', '1.0.0', '1.0.0', '1.0.0', true),
    ('windows', '1.0.0', '1.0.0', '1.0.0', true),
    ('web', '1.0.0', '1.0.0', '1.0.0', true),
    ('ios', '1.0.0', '1.0.0', '1.0.0', true)
ON CONFLICT DO NOTHING;

ALTER TABLE public.client_version_compatibility ENABLE ROW LEVEL SECURITY;

CREATE POLICY "client_compatibility_public_read"
    ON public.client_version_compatibility
    FOR SELECT
    TO PUBLIC
    USING (is_active = true);

CREATE POLICY "client_compatibility_admin_write"
    ON public.client_version_compatibility
    FOR ALL
    TO authenticated
    USING (public.is_platform_admin())
    WITH CHECK (public.is_platform_admin());

-- Semver Comparison Helper
CREATE OR REPLACE FUNCTION public.compare_semver(p_v1 TEXT, p_v2 TEXT)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_parts1 INT[];
    v_parts2 INT[];
    v_clean1 TEXT;
    v_clean2 TEXT;
    i INT;
    p1 INT;
    p2 INT;
BEGIN
    -- Strip build metadata / pre-release tags (e.g. 1.0.0+1 -> 1.0.0)
    v_clean1 := split_part(split_part(p_v1, '+', 1), '-', 1);
    v_clean2 := split_part(split_part(p_v2, '+', 1), '-', 1);

    v_parts1 := string_to_array(v_clean1, '.')::INT[];
    v_parts2 := string_to_array(v_clean2, '.')::INT[];

    -- Pad arrays to at least 3 parts (major.minor.patch)
    WHILE array_length(v_parts1, 1) < 3 LOOP
        v_parts1 := array_append(v_parts1, 0);
    END LOOP;
    WHILE array_length(v_parts2, 1) < 3 LOOP
        v_parts2 := array_append(v_parts2, 0);
    END LOOP;

    FOR i IN 1..3 LOOP
        p1 := COALESCE(v_parts1[i], 0);
        p2 := COALESCE(v_parts2[i], 0);
        IF p1 > p2 THEN
            RETURN 1;
        ELSIF p1 < p2 THEN
            RETURN -1;
        END IF;
    END LOOP;

    RETURN 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_client_compatibility(
    p_client_version TEXT,
    p_platform TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_record RECORD;
    v_cmp_min INT;
    v_cmp_rec INT;
    v_status TEXT;
BEGIN
    SELECT * INTO v_record
    FROM public.client_version_compatibility
    WHERE platform = lower(p_platform) AND is_active = true
    LIMIT 1;

    IF NOT FOUND THEN
        -- Default to supported if platform not registered
        RETURN jsonb_build_object(
            'status', 'supported',
            'platform', p_platform,
            'client_version', p_client_version,
            'is_supported', true,
            'is_update_required', false,
            'is_update_recommended', false
        );
    END IF;

    v_cmp_min := public.compare_semver(p_client_version, v_record.minimum_supported_version);
    v_cmp_rec := public.compare_semver(p_client_version, v_record.recommended_version);

    IF v_cmp_min < 0 THEN
        v_status := 'update_required';
    ELSIF v_cmp_rec < 0 THEN
        v_status := 'update_recommended';
    ELSE
        v_status := 'supported';
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'platform', p_platform,
        'client_version', p_client_version,
        'minimum_supported_version', v_record.minimum_supported_version,
        'recommended_version', v_record.recommended_version,
        'latest_version', v_record.latest_version,
        'is_supported', (v_cmp_min >= 0),
        'is_update_required', (v_cmp_min < 0),
        'is_update_recommended', (v_cmp_rec < 0),
        'message_en', v_record.force_update_message_en,
        'message_am', v_record.force_update_message_am
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. Production Release Metadata Ledger
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.production_releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_tag TEXT NOT NULL UNIQUE,
    commit_sha TEXT NOT NULL,
    migration_baseline TEXT NOT NULL,
    app_version TEXT NOT NULL,
    build_number INT NOT NULL,
    deployed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    environment TEXT NOT NULL DEFAULT 'production',
    deployed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT NULL
);

ALTER TABLE public.production_releases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "production_releases_admin_read"
    ON public.production_releases
    FOR SELECT
    TO authenticated
    USING (public.is_platform_admin());

CREATE POLICY "production_releases_admin_insert"
    ON public.production_releases
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_platform_admin());

-- -----------------------------------------------------------------------------
-- 4. Operational Support Tooling (Read-Only, Audited, Tenant-Safe)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_school_operational_summary(
    p_school_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_school RECORD;
    v_license RECORD;
    v_has_license BOOLEAN := FALSE;
    v_seat_usage JSONB;
    v_classes_count INT := 0;
    v_teachers_count INT := 0;
    v_students_count INT := 0;
    v_recent_import RECORD;
    v_has_import BOOLEAN := FALSE;
    v_actor_id UUID := auth.uid();
BEGIN
    -- Strict authorization check: platform admin or service role only
    IF auth.uid() IS NOT NULL AND auth.role() != 'service_role' AND NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: operational support summary requires platform_admin or service_role'
            USING ERRCODE = '42501';
    END IF;

    SELECT id, name, display_name, school_code, status, region, city
    INTO v_school
    FROM public.schools
    WHERE id = p_school_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'School not found: %', p_school_id
            USING ERRCODE = 'P0002';
    END IF;

    SELECT plan_code, status, student_seat_limit, starts_at, ends_at, grace_ends_at,
           source, billing_customer_ref, last_billing_event_at
    INTO v_license
    FROM public.school_licenses
    WHERE school_id = p_school_id;
    IF FOUND THEN
        v_has_license := TRUE;
    END IF;

    v_seat_usage := public.get_school_seat_usage(p_school_id);

    SELECT COUNT(*) INTO v_classes_count
    FROM public.classrooms
    WHERE school_id = p_school_id AND status = 'active';

    SELECT COUNT(DISTINCT user_id) INTO v_teachers_count
    FROM public.school_memberships
    WHERE school_id = p_school_id AND role = 'teacher' AND status = 'active';

    SELECT COUNT(DISTINCT user_id) INTO v_students_count
    FROM public.school_memberships
    WHERE school_id = p_school_id AND role = 'student' AND status = 'active';

    SELECT status, total_rows, valid_rows, created_students, created_at
    INTO v_recent_import
    FROM public.institutional_import_runs
    WHERE school_id = p_school_id
    ORDER BY created_at DESC
    LIMIT 1;
    IF FOUND THEN
        v_has_import := TRUE;
    END IF;

    -- Audit this operational inspection event
    INSERT INTO public.audit_log (
        actor_id, action, target_table, target_id, metadata, created_at
    ) VALUES (
        v_actor_id,
        'school_support_inspection',
        'schools',
        p_school_id::TEXT,
        jsonb_build_object(
            'actor_id', v_actor_id,
            'school_id', p_school_id,
            'school_code', v_school.school_code,
            'inspected_at', NOW()
        ),
        NOW()
    );

    RETURN jsonb_build_object(
        'school', jsonb_build_object(
            'id', v_school.id,
            'name', v_school.name,
            'display_name', v_school.display_name,
            'school_code', v_school.school_code,
            'status', v_school.status,
            'region', v_school.region,
            'city', v_school.city
        ),
        'license', CASE WHEN v_has_license THEN jsonb_build_object(
            'plan_code', v_license.plan_code,
            'status', v_license.status,
            'is_effective', public.is_school_license_effective(p_school_id),
            'seat_limit', v_license.student_seat_limit,
            'starts_at', v_license.starts_at,
            'ends_at', v_license.ends_at,
            'grace_ends_at', v_license.grace_ends_at,
            'source', v_license.source,
            'last_billing_event_at', v_license.last_billing_event_at
        ) ELSE NULL END,
        'seat_usage', v_seat_usage,
        'roster_summary', jsonb_build_object(
            'active_classrooms', v_classes_count,
            'active_teachers', v_teachers_count,
            'active_students', v_students_count
        ),
        'recent_import', CASE WHEN v_has_import THEN jsonb_build_object(
            'status', v_recent_import.status,
            'total_rows', v_recent_import.total_rows,
            'valid_rows', v_recent_import.valid_rows,
            'created_students', v_recent_import.created_students,
            'created_at', v_recent_import.created_at
        ) ELSE NULL END
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_student_sync_diagnostic(
    p_student_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_attempts_count INT := 0;
    v_latest_attempt TIMESTAMPTZ;
    v_memberships JSONB;
    v_actor_id UUID := auth.uid();
BEGIN
    -- Authorization check: student self-check, school admin in same school, or platform admin
    IF auth.uid() IS NOT NULL AND auth.role() != 'service_role' AND NOT public.is_platform_admin() THEN
        IF auth.uid() != p_student_id THEN
            -- Check if caller is school admin of a school where this student is enrolled
            IF NOT EXISTS (
                SELECT 1
                FROM public.school_memberships caller_sm
                JOIN public.school_memberships student_sm ON caller_sm.school_id = student_sm.school_id
                WHERE caller_sm.user_id = auth.uid()
                  AND caller_sm.role = 'school_admin'
                  AND caller_sm.status = 'active'
                  AND student_sm.user_id = p_student_id
            ) THEN
                RAISE EXCEPTION 'Access denied: student diagnostic inspection unauthorized for caller %', auth.uid()
                    USING ERRCODE = '42501';
            END IF;
        END IF;
    END IF;

    SELECT COUNT(*), MAX(end_time)
    INTO v_attempts_count, v_latest_attempt
    FROM public.attempts
    WHERE user_id = p_student_id;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'school_id', sm.school_id,
        'school_name', s.name,
        'role', sm.role,
        'status', sm.status,
        'joined_at', sm.created_at
    )), '[]'::jsonb)
    INTO v_memberships
    FROM public.school_memberships sm
    JOIN public.schools s ON sm.school_id = s.id
    WHERE sm.user_id = p_student_id;

    -- Audit event
    INSERT INTO public.audit_log (
        actor_id, action, target_table, target_id, metadata, created_at
    ) VALUES (
        v_actor_id,
        'student_support_inspection',
        'users',
        p_student_id::TEXT,
        jsonb_build_object(
            'actor_id', v_actor_id,
            'student_id', p_student_id,
            'inspected_at', NOW()
        ),
        NOW()
    );

    RETURN jsonb_build_object(
        'student_id', p_student_id,
        'total_synced_attempts', v_attempts_count,
        'latest_attempt_at', v_latest_attempt,
        'memberships', v_memberships
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. Revoke Public Execution & Grant Minimum Privileges
-- -----------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.system_health_status() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.system_health_status() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.compare_semver(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.compare_semver(TEXT, TEXT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.check_client_compatibility(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_client_compatibility(TEXT, TEXT) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_school_operational_summary(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_operational_summary(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_student_sync_diagnostic(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_sync_diagnostic(UUID) TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 6. Production Hardening: Resolve user_roles RLS Recursion
-- -----------------------------------------------------------------------------
-- Replace direct subquery with SECURITY DEFINER public.is_platform_admin() to prevent
-- infinite recursion when querying public.audit_log or public.user_roles.

DROP POLICY IF EXISTS "user_roles_admin_read_all" ON public.user_roles;
CREATE POLICY "user_roles_admin_read_all"
    ON public.user_roles FOR SELECT
    USING (public.is_platform_admin());

DROP POLICY IF EXISTS "audit_log_admin_read" ON public.audit_log;
CREATE POLICY "audit_log_admin_read"
    ON public.audit_log FOR SELECT
    USING (public.is_platform_admin());

GRANT SELECT ON public.audit_log TO authenticated, service_role;
GRANT SELECT, INSERT ON public.production_releases TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 7. Operational Alerting Infrastructure
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.operational_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    severity TEXT NOT NULL CHECK (severity IN ('SEV-1', 'SEV-2', 'SEV-3')),
    service TEXT NOT NULL,
    alert_name TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    emitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ NULL
);

ALTER TABLE public.operational_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "operational_alerts_admin_read"
    ON public.operational_alerts
    FOR SELECT
    TO authenticated
    USING (public.is_platform_admin());

CREATE OR REPLACE FUNCTION public.emit_operational_alert(
    p_severity TEXT,
    p_service TEXT,
    p_alert_name TEXT,
    p_description TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_alert_id UUID;
    v_actor_id UUID := auth.uid();
BEGIN
    IF auth.uid() IS NOT NULL AND auth.role() != 'service_role' AND NOT public.is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: emitting operational alerts requires platform_admin or service_role'
            USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.operational_alerts (
        severity, service, alert_name, description, metadata, emitted_at
    ) VALUES (
        p_severity, p_service, p_alert_name, p_description, p_metadata, NOW()
    ) RETURNING id INTO v_alert_id;

    -- Also record in canonical audit_log
    INSERT INTO public.audit_log (
        actor_id, action, target_table, target_id, metadata, created_at
    ) VALUES (
        v_actor_id,
        'operational_alert_emitted',
        'operational_alerts',
        v_alert_id::TEXT,
        jsonb_build_object(
            'severity', p_severity,
            'service', p_service,
            'alert_name', p_alert_name,
            'description', p_description,
            'metadata', p_metadata
        ),
        NOW()
    );

    RETURN v_alert_id;
END;
$$;

REVOKE ALL ON FUNCTION public.emit_operational_alert(TEXT, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.emit_operational_alert(TEXT, TEXT, TEXT, TEXT, JSONB) TO authenticated, service_role;
GRANT SELECT ON public.operational_alerts TO authenticated, service_role;



