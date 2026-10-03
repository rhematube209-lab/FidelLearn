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
