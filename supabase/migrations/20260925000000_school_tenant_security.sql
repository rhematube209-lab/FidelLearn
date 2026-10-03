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

