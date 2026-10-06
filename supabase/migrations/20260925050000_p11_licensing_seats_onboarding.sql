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
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_school_licenses_school UNIQUE (school_id)
);

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
    status TEXT NOT NULL CHECK (status IN ('received', 'processed', 'ignored', 'failed')) DEFAULT 'received',
    processed_at TIMESTAMPTZ NULL,
    error_message TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_billing_events_provider_event UNIQUE (provider, provider_event_id)
);

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
    v_now TIMESTAMPTZ := TIMEZONE('utc', NOW());
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
        -- Derive effective status based on timestamps (Section 8 & 9)
        IF v_status IN ('trial', 'active') AND v_ends_at IS NOT NULL AND v_ends_at < v_now THEN
            IF v_grace_ends_at IS NOT NULL AND v_grace_ends_at >= v_now THEN
                v_status := 'grace';
            ELSE
                v_status := 'expired';
            END IF;
        END IF;
        IF v_status = 'grace' AND v_grace_ends_at IS NOT NULL AND v_grace_ends_at < v_now THEN
            v_status := 'suspended';
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
    v_now TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    SELECT * INTO v_license
    FROM public.school_licenses
    WHERE school_id = p_school_id
    FOR UPDATE; -- Concurrency lock to prevent race conditions during activation

    IF NOT FOUND THEN
        RAISE EXCEPTION 'School % has no commercial license configured', p_school_id
            USING ERRCODE = 'check_violation';
    END IF;

    -- Derive effective status based on timestamps (Section 8 & 9)
    v_effective_status := v_license.status;
    IF v_effective_status IN ('trial', 'active') AND v_license.ends_at IS NOT NULL AND v_license.ends_at < v_now THEN
        IF v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at >= v_now THEN
            v_effective_status := 'grace';
        ELSE
            v_effective_status := 'expired';
        END IF;
    END IF;
    IF v_effective_status = 'grace' AND v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at < v_now THEN
        v_effective_status := 'suspended';
    END IF;

    -- Verify effective license operational status
    IF v_effective_status NOT IN ('trial', 'active', 'grace') THEN
        RAISE EXCEPTION 'School % license is % (effective: %) — cannot enroll students', p_school_id, v_license.status, v_effective_status
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

-- 8a. get_school_entitlements: Returns active feature entitlements for a school
CREATE OR REPLACE FUNCTION public.get_school_entitlements(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_license public.school_licenses%ROWTYPE;
    v_school_status TEXT;
    v_effective_status TEXT;
    v_now TIMESTAMPTZ := TIMEZONE('utc', NOW());
BEGIN
    SELECT status INTO v_school_status FROM public.schools WHERE id = p_school_id;
    IF NOT FOUND THEN
        RETURN '{}'::jsonb;
    END IF;

    -- If school itself is suspended or archived, institutional features are disabled
    IF v_school_status != 'active' THEN
        RETURN '{}'::jsonb;
    END IF;

    SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id;
    IF NOT FOUND THEN
        RETURN '{}'::jsonb;
    END IF;

    -- Derive effective status based on timestamps (Section 8 & 9)
    v_effective_status := v_license.status;
    IF v_effective_status IN ('trial', 'active') AND v_license.ends_at IS NOT NULL AND v_license.ends_at < v_now THEN
        IF v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at >= v_now THEN
            v_effective_status := 'grace';
        ELSE
            v_effective_status := 'expired';
        END IF;
    END IF;
    IF v_effective_status = 'grace' AND v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at < v_now THEN
        v_effective_status := 'suspended';
    END IF;

    -- License status check: trial, active, grace have active entitlements
    IF v_effective_status IN ('trial', 'active', 'grace') THEN
        RETURN v_license.feature_entitlements;
    END IF;

    -- Suspended, expired, cancelled return empty entitlements
    RETURN '{}'::jsonb;
END;
$$ LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 8b. school_has_entitlement: Fast boolean check for specific feature key
CREATE OR REPLACE FUNCTION public.school_has_entitlement(
    p_school_id   UUID,
    p_entitlement TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_entitlements JSONB;
BEGIN
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
        v_now TIMESTAMPTZ := TIMEZONE('utc', NOW());
    BEGIN
        IF v_effective_status IN ('trial', 'active') AND v_license.ends_at IS NOT NULL AND v_license.ends_at < v_now THEN
            IF v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at >= v_now THEN
                v_effective_status := 'grace';
            ELSE
                v_effective_status := 'expired';
            END IF;
        END IF;
        IF v_effective_status = 'grace' AND v_license.grace_ends_at IS NOT NULL AND v_license.grace_ends_at < v_now THEN
            v_effective_status := 'suspended';
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
        provider, provider_event_id, event_type, school_id, payload_hash, status, processed_at
    ) VALUES (
        p_provider, p_provider_event_id, p_event_type, p_school_id, p_payload_hash, 'processed', TIMEZONE('utc', NOW())
    ) RETURNING * INTO v_event;

    -- If school_id is provided and license exists, apply business logic transitions:
    -- Billing determines whether money was paid; Licensing updates access.
    IF p_school_id IS NOT NULL THEN
        SELECT * INTO v_license FROM public.school_licenses WHERE school_id = p_school_id FOR UPDATE;
        IF FOUND THEN
            -- Payment Succeeded / Invoice Paid -> Activate or renew license
            IF p_event_type IN ('payment_succeeded', 'invoice_paid', 'subscription_renewed') THEN
                UPDATE public.school_licenses
                SET status = 'active',
                    starts_at = COALESCE(p_period_start, starts_at),
                    ends_at = COALESCE(p_period_end, ends_at),
                    student_seat_limit = COALESCE(p_seat_limit, student_seat_limit),
                    grace_ends_at = NULL,
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

            -- Payment Failed -> Enter grace period (with stale-event guard)
            ELSIF p_event_type IN ('payment_failed', 'invoice_payment_failed') THEN
                -- Only enter grace if currently active
                IF v_license.status = 'active' THEN
                    -- Stale event guard: If the license was already renewed with a period end in the future,
                    -- or if an event timestamp is older than last renewal, do NOT downgrade the active license!
                    IF (p_period_end IS NOT NULL AND v_license.ends_at IS NOT NULL AND p_period_end < v_license.ends_at)
                       OR (p_event_timestamp IS NOT NULL AND p_event_timestamp < v_license.updated_at) THEN
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
    v_now TIMESTAMPTZ := TIMEZONE('utc', NOW());
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
