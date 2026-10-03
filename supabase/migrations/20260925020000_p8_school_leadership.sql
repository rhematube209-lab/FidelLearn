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
