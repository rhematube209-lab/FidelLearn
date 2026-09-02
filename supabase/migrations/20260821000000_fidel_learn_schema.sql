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
