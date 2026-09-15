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
