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

    -- Student populations
    SELECT 
        COUNT(*)::INT,
        COUNT(CASE WHEN p.stream = 'natural' THEN 1 END)::INT,
        COUNT(CASE WHEN p.stream = 'social' THEN 1 END)::INT
    INTO v_student_count, v_natural_count, v_social_count
    FROM public.school_memberships sm
    JOIN public.profiles p ON p.id = sm.user_id
    WHERE sm.school_id = p_school_id
      AND sm.role = 'student'
      AND sm.status = 'active';

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
        SELECT sm.user_id AS student_uid
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
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
        SELECT sm.user_id AS student_uid
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
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
        COUNT(CASE WHEN status IN ('submitted', 'completed', 'late') THEN 1 END)::INT,
        COUNT(CASE WHEN status IN ('completed', 'submitted') THEN 1 END)::INT,
        COUNT(CASE WHEN status IN ('submitted', 'completed') AND deadline_integrity = 'verified' THEN 1 END)::INT,
        COUNT(CASE WHEN status = 'late' AND deadline_integrity = 'verified' THEN 1 END)::INT,
        COUNT(CASE WHEN deadline_integrity = 'unverified' THEN 1 END)::INT,
        COUNT(CASE WHEN deadline_integrity = 'anomaly' THEN 1 END)::INT
    INTO v_assign_required, v_assign_submitted, v_assign_completed, v_assign_on_time_verified, v_assign_late_verified, v_assign_unverified, v_assign_anomaly
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

    -- Data Freshness Distribution based on actual academic evidence (attempts & mistake records)
    WITH student_freshness AS (
        SELECT 
            sm.user_id,
            (SELECT MAX(a.created_at) FROM public.attempts a WHERE a.user_id = sm.user_id) AS last_attempt_at,
            (SELECT MAX(m.last_failed_at) FROM public.mistake_records m WHERE m.user_id = sm.user_id) AS last_mistake_at
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
    ),
    sync_dates AS (
        SELECT 
            user_id,
            GREATEST(last_attempt_at, last_mistake_at) AS last_sync
        FROM student_freshness
    )
    SELECT
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '7 days' AND last_sync < NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '14 days' AND last_sync < NOW() - INTERVAL '7 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync < NOW() - INTERVAL '14 days' THEN 1 END)::INT
    INTO v_fresh_count, v_moderate_count, v_stale_count, v_very_stale_count
    FROM sync_dates;

    -- Teacher assignment coverage
    SELECT 
        CASE 
            WHEN COUNT(*) > 0 THEN ROUND((COUNT(tsa.teacher_user_id)::NUMERIC / COUNT(*)::NUMERIC) * 100.0, 2)
            ELSE 100.0
        END
    INTO v_teacher_coverage
    FROM public.classrooms c
    CROSS JOIN public.subjects s
    LEFT JOIN public.teacher_subject_assignments tsa 
        ON tsa.classroom_id = c.id AND tsa.subject_id = s.id AND tsa.school_id = p_school_id
    WHERE c.school_id = p_school_id 
      AND c.academic_year = v_year 
      AND c.status = 'active'
      AND s.grade = 12
      AND s.id != 'civics_g12';

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
            'completion_rate', CASE WHEN v_assign_required > 0 THEN ROUND((v_assign_submitted::NUMERIC / v_assign_required::NUMERIC) * 100.0, 2) ELSE 0.0 END,
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
            'fresh_data_coverage_rate', CASE WHEN v_student_count > 0 THEN ROUND(((v_fresh_count + v_moderate_count)::NUMERIC / v_student_count::NUMERIC) * 100.0, 2) ELSE 0.0 END,
            'freshness_caveat', 'Stale synchronization indicates lack of recent device connectivity, NOT absence of offline student study.'
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
        SELECT sm.user_id, p.stream
        FROM public.school_memberships sm
        JOIN public.profiles p ON p.id = sm.user_id
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
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
        SELECT sm.user_id, p.stream
        FROM public.school_memberships sm
        JOIN public.profiles p ON p.id = sm.user_id
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
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

    SELECT COUNT(*)::INT INTO v_total_eligible
    FROM public.school_memberships sm
    WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active';

    RETURN QUERY
    WITH school_students AS (
        SELECT sm.user_id
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
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
            COUNT(CASE WHEN r.status IN ('submitted', 'completed', 'late') THEN 1 END)::INT AS sub_count,
            COUNT(CASE WHEN r.status IN ('completed', 'submitted') THEN 1 END)::INT AS comp_count,
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
                ROUND((COALESCE(ra.sub_count, 0)::NUMERIC / ra.req_denominator::NUMERIC) * 100.0, 2)
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

    SELECT COUNT(*)::INT INTO v_total_students
    FROM public.school_memberships sm
    WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active';

    WITH student_sync AS (
        SELECT
            sm.user_id,
            (SELECT MAX(a.created_at) FROM public.attempts a WHERE a.user_id = sm.user_id) AS last_attempt_at,
            (SELECT MAX(m.last_failed_at) FROM public.mistake_records m WHERE m.user_id = sm.user_id) AS last_mistake_at
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id AND sm.role = 'student' AND sm.status = 'active'
    ),
    sync_dates AS (
        SELECT
            user_id,
            GREATEST(last_attempt_at, last_mistake_at) AS last_sync
        FROM student_sync
    )
    SELECT
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '7 days' AND last_sync < NOW() - INTERVAL '2 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync >= NOW() - INTERVAL '14 days' AND last_sync < NOW() - INTERVAL '7 days' THEN 1 END)::INT,
        COUNT(CASE WHEN last_sync < NOW() - INTERVAL '14 days' THEN 1 END)::INT
    INTO v_fresh, v_mod, v_stale, v_very_stale
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
        'fresh_coverage_rate', CASE WHEN v_total_students > 0 THEN ROUND(((v_fresh + v_mod)::NUMERIC / v_total_students::NUMERIC) * 100.0, 2) ELSE 0.0 END,
        'timing_unverified_count', v_timing_unverified,
        'clock_anomaly_count', v_clock_anomaly,
        'methodological_notice', 'Stale synchronization reflects offline mobile usage patterns in network-constrained environments. Missing cloud evidence must not be interpreted as lack of study.'
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
    v_last_sync TIMESTAMPTZ;
    v_as_of TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    IF NOT public.can_access_student(p_student_id, p_school_id) THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED: Caller is not authorized to access this student academic report' USING ERRCODE = '42501';
    END IF;

    v_year := public.resolve_default_academic_year(p_school_id, p_academic_year);
    v_end := COALESCE(p_period_end, TIMEZONE('utc', NOW()));
    v_start := COALESCE(p_period_start, v_end - INTERVAL '90 days');

    SELECT p.display_name, p.stream, p.grade, c.name, p.updated_at
    INTO v_student_name, v_stream, v_grade, v_class_name, v_last_sync
    FROM public.profiles p
    LEFT JOIN public.classroom_memberships cm ON cm.user_id = p.id AND cm.status = 'active'
    LEFT JOIN public.classrooms c ON c.id = cm.classroom_id AND c.school_id = p_school_id AND c.academic_year = v_year
    WHERE p.id = p_student_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student not found' USING ERRCODE = 'P0002';
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

    -- Assignments
    SELECT 
        COUNT(*)::INT,
        COUNT(CASE WHEN r.status IN ('submitted', 'completed', 'late') THEN 1 END)::INT
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
          AND s.id != 'civics_g12'
    ),
    required_slots AS (
        SELECT
            ac.cid AS classroom_id,
            ac.cname AS classroom_name,
            ac.cgrade AS grade,
            ac.cstream AS stream,
            ac.csection AS section,
            cc.sub_id AS subject_id,
            cc.sub_name AS subject_name,
            CASE
                WHEN cc.sub_id = 'math_g12' THEN ac.cstream
                ELSE NULL
            END AS exam_variant
        FROM active_classes ac
        CROSS JOIN core_curriculum cc
        WHERE cc.sub_stream = 'common' OR cc.sub_stream = ac.cstream
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
           AND (rs.exam_variant IS NULL OR tsa.exam_variant IS NULL OR tsa.exam_variant = rs.exam_variant)
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

