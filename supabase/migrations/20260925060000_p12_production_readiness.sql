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



