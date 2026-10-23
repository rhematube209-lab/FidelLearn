-- =============================================================================
-- FidelLearn Production Seed: Demo Accounts & Institutional Setup (v3)
-- Description: Self-contained setup script. Automatically ensures all required
--              tables exist, creates both auth.users AND auth.identities records
--              (required by Supabase GoTrue Auth for password login), confirms
--              emails/phones, and links school memberships.
-- Password:    'password123' for ALL demo accounts.
-- Execution:   Paste and run directly in the Supabase Dashboard SQL Editor.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 0. SCHEMA PREREQUISITES (Ensures tables exist even if migrations were not run)
-- -----------------------------------------------------------------------------

-- Profiles
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

-- Global Roles
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

-- Subjects
CREATE TABLE IF NOT EXISTS public.subjects (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    grade INT NOT NULL,
    stream TEXT,
    icon_asset TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, sort_order) VALUES 
    ('physics_g12', 'PHYS12', 'Physics', 'ፊዚክስ', 12, 'natural', 1),
    ('math_g12', 'MATH12', 'Mathematics', 'ሒሳብ', 12, 'natural', 2),
    ('biology_g12', 'BIO12', 'Biology', 'ባዮሎጂ', 12, 'natural', 3),
    ('chemistry_g12', 'CHEM12', 'Chemistry', 'ኬሚስትሪ', 12, 'natural', 4),
    ('english_g12', 'ENG12', 'English', 'እንግሊዝኛ', 12, 'common', 5)
ON CONFLICT (id) DO NOTHING;

-- Schools
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

-- School Memberships
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

-- Classrooms
CREATE TABLE IF NOT EXISTS public.classrooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 8, 12)),
    stream TEXT NOT NULL CHECK (stream IN ('naturalScience', 'socialScience', 'common')),
    section TEXT NOT NULL,
    academic_year TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'archived')) DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_classrooms_school_grade_section_year UNIQUE (school_id, grade, section, academic_year)
);

-- Classroom Memberships
CREATE TABLE IF NOT EXISTS public.classroom_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher')),
    status TEXT NOT NULL CHECK (status IN ('active', 'transferred', 'dropped')) DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_classroom_memberships_class_user UNIQUE (classroom_id, user_id)
);

-- Teacher Subject Assignments
CREATE TABLE IF NOT EXISTS public.teacher_subject_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    exam_variant TEXT CHECK (exam_variant IN ('naturalScience', 'socialScience', 'shared')),
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Institutional Plans
CREATE TABLE IF NOT EXISTS public.institutional_plans (
    plan_code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    max_student_seats INT NOT NULL,
    feature_entitlements JSONB NOT NULL,
    billing_cadence TEXT NOT NULL CHECK (billing_cadence IN ('monthly', 'annual', 'term')),
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- School Licenses
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

-- -----------------------------------------------------------------------------
-- 0b. RLS POLICIES (Allow authenticated users to read institutional records)
-- -----------------------------------------------------------------------------
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classroom_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_subject_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schools' AND policyname = 'schools_read_all') THEN
        CREATE POLICY "schools_read_all" ON public.schools FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'school_memberships' AND policyname = 'school_memberships_read_all') THEN
        CREATE POLICY "school_memberships_read_all" ON public.school_memberships FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'classrooms' AND policyname = 'classrooms_read_all') THEN
        CREATE POLICY "classrooms_read_all" ON public.classrooms FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'classroom_memberships' AND policyname = 'classroom_memberships_read_all') THEN
        CREATE POLICY "classroom_memberships_read_all" ON public.classroom_memberships FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'teacher_subject_assignments' AND policyname = 'teacher_subject_assignments_read_all') THEN
        CREATE POLICY "teacher_subject_assignments_read_all" ON public.teacher_subject_assignments FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'school_licenses' AND policyname = 'school_licenses_read_all') THEN
        CREATE POLICY "school_licenses_read_all" ON public.school_licenses FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_read_all') THEN
        CREATE POLICY "profiles_read_all" ON public.profiles FOR SELECT TO authenticated USING (true);
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 1. SEED SCHOOLS
-- -----------------------------------------------------------------------------
INSERT INTO public.schools (id, name, display_name, school_code, status, city, region, timezone)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Bole Senior Secondary School', 'Bole Secondary', 'FID-BOL001', 'active', 'Addis Ababa', 'Addis Ababa', 'Africa/Addis_Ababa'),
    ('22222222-2222-2222-2222-222222222222', 'Hawassa Comprehensive Secondary School', 'Hawassa Secondary', 'FID-HAW002', 'active', 'Hawassa', 'Sidama', 'Africa/Addis_Ababa')
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    display_name = EXCLUDED.display_name,
    status = 'active';

-- -----------------------------------------------------------------------------
-- 2. SEED CLASSROOMS
-- -----------------------------------------------------------------------------
INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
VALUES 
    ('ca111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section A', 12, 'naturalScience', 'A', '2026/27', 'active'),
    ('ca333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section C', 12, 'naturalScience', 'C', '2026/27', 'active'),
    ('ca222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Grade 12 Natural - Section B', 12, 'naturalScience', 'B', '2026/27', 'active')
ON CONFLICT (id) DO UPDATE SET status = 'active';

-- -----------------------------------------------------------------------------
-- 3. SEED SCHOOL LICENSES (Standard Institutional License - 500 Seats)
-- -----------------------------------------------------------------------------
INSERT INTO public.institutional_plans (plan_code, name, max_student_seats, feature_entitlements, billing_cadence, is_public)
VALUES (
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
) ON CONFLICT (plan_code) DO NOTHING;

INSERT INTO public.school_licenses (
    school_id, plan_code, status, starts_at, ends_at, grace_ends_at, student_seat_limit, feature_entitlements, source
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'school_standard',
    'active',
    NOW() - INTERVAL '30 days',
    NOW() + INTERVAL '335 days',
    NOW() + INTERVAL '365 days',
    500,
    jsonb_build_object(
        'student_learning', true,
        'teacher_portal', true,
        'leadership_dashboard', true,
        'assignments_interventions', true,
        'institutional_reporting', true,
        'national_exam_simulation', true
    ),
    'manual_contract'
) ON CONFLICT (school_id) DO UPDATE SET 
    status = 'active',
    student_seat_limit = 500,
    ends_at = NOW() + INTERVAL '335 days';

INSERT INTO public.school_licenses (
    school_id, plan_code, status, starts_at, ends_at, grace_ends_at, student_seat_limit, feature_entitlements, source
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    'school_standard',
    'active',
    NOW() - INTERVAL '30 days',
    NOW() + INTERVAL '335 days',
    NOW() + INTERVAL '365 days',
    500,
    jsonb_build_object(
        'student_learning', true,
        'teacher_portal', true,
        'leadership_dashboard', true,
        'assignments_interventions', true,
        'institutional_reporting', true,
        'national_exam_simulation', true
    ),
    'manual_contract'
) ON CONFLICT (school_id) DO UPDATE SET 
    status = 'active',
    student_seat_limit = 500,
    ends_at = NOW() + INTERVAL '335 days';

-- -----------------------------------------------------------------------------
-- 4. HARDENED PROVISIONING FUNCTION (Populates BOTH auth.users AND auth.identities)
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.provision_demo_user(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, UUID, TEXT, UUID);
CREATE OR REPLACE FUNCTION public.provision_demo_user(
    p_desired_id UUID,
    p_phone TEXT,
    p_email TEXT,
    p_password TEXT,
    p_display_name TEXT,
    p_global_role TEXT,
    p_grade INT,
    p_stream TEXT,
    p_school_id UUID DEFAULT NULL,
    p_school_role TEXT DEFAULT NULL,
    p_classroom_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_has_provider_id BOOLEAN;
    v_has_confirmed_at BOOLEAN;
    v_has_is_anonymous BOOLEAN;
BEGIN
    -- Check if user already exists in auth.users by email or phone
    SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER(p_email) OR phone = p_phone LIMIT 1;

    -- Inspect auth.users schema dynamically
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'confirmed_at'
    ) INTO v_has_confirmed_at;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous'
    ) INTO v_has_is_anonymous;

    IF v_user_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM auth.users WHERE id = p_desired_id) THEN
            v_user_id := gen_random_uuid();
        ELSE
            v_user_id := p_desired_id;
        END IF;

        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            phone,
            phone_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            created_at,
            updated_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            LOWER(p_email),
            crypt(p_password, gen_salt('bf', 10)),
            NOW(),
            p_phone,
            NOW(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object(
                'phone_number', p_phone,
                'display_name', p_display_name,
                'role', p_global_role,
                'grade', p_grade,
                'stream', p_stream,
                'preferred_language', 'en'
            ),
            false,
            NOW(),
            NOW()
        );
    ELSE
        UPDATE auth.users SET
            encrypted_password = crypt(p_password, gen_salt('bf', 10)),
            email = LOWER(p_email),
            phone = p_phone,
            aud = 'authenticated',
            role = 'authenticated',
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            phone_confirmed_at = COALESCE(phone_confirmed_at, NOW()),
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            raw_user_meta_data = jsonb_build_object(
                'phone_number', p_phone,
                'display_name', p_display_name,
                'role', p_global_role,
                'grade', p_grade,
                'stream', p_stream,
                'preferred_language', 'en'
            ),
            updated_at = NOW()
        WHERE id = v_user_id;
    END IF;

    -- Update confirmed_at if column exists
    IF v_has_confirmed_at THEN
        EXECUTE 'UPDATE auth.users SET confirmed_at = NOW() WHERE id = $1' USING v_user_id;
    END IF;

    -- Update is_anonymous if column exists
    IF v_has_is_anonymous THEN
        EXECUTE 'UPDATE auth.users SET is_anonymous = false WHERE id = $1' USING v_user_id;
    END IF;

    -- CRITICAL STEP: Provision auth.identities so GoTrue allows email/password sign-in!
    DELETE FROM auth.identities WHERE user_id = v_user_id OR (provider = 'email' AND identity_data->>'email' = LOWER(p_email));

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'identities' AND column_name = 'provider_id'
    ) INTO v_has_provider_id;

    IF v_has_provider_id THEN
        EXECUTE 'INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at) ' ||
                'VALUES ($1, $2, $3, ''email'', $1, NOW(), NOW(), NOW())'
        USING v_user_id::text, v_user_id, jsonb_build_object('sub', v_user_id::text, 'email', LOWER(p_email), 'email_verified', true, 'phone_verified', true);
    ELSE
        EXECUTE 'INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) ' ||
                'VALUES ($1, $2, $3, ''email'', NOW(), NOW(), NOW())'
        USING v_user_id::text, v_user_id, jsonb_build_object('sub', v_user_id::text, 'email', LOWER(p_email), 'email_verified', true, 'phone_verified', true);
    END IF;

    -- Upsert public.profiles
    INSERT INTO public.profiles (
        id, phone_number, display_name, grade, stream, preferred_language, created_at, updated_at
    ) VALUES (
        v_user_id, p_phone, p_display_name, p_grade, p_stream, 'en', NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        phone_number = EXCLUDED.phone_number,
        display_name = EXCLUDED.display_name,
        grade = EXCLUDED.grade,
        stream = EXCLUDED.stream,
        updated_at = NOW();

    -- Ensure unique phone number on profiles if conflict with another record
    UPDATE public.profiles SET phone_number = p_phone WHERE id = v_user_id;

    -- Upsert global user role
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_user_id, p_global_role)
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- Link institutional school membership if school is specified
    IF p_school_id IS NOT NULL AND p_school_role IS NOT NULL THEN
        INSERT INTO public.school_memberships (
            school_id, user_id, role, status, joined_at
        ) VALUES (
            p_school_id, v_user_id, p_school_role, 'active', NOW()
        ) ON CONFLICT (school_id, user_id) DO UPDATE SET
            role = EXCLUDED.role,
            status = 'active';
    END IF;

    -- Link classroom membership if classroom is specified
    IF p_classroom_id IS NOT NULL THEN
        INSERT INTO public.classroom_memberships (
            classroom_id, user_id, role, status
        ) VALUES (
            p_classroom_id, v_user_id, CASE WHEN p_school_role = 'teacher' THEN 'teacher' ELSE 'student' END, 'active'
        ) ON CONFLICT (classroom_id, user_id) DO UPDATE SET
            status = 'active';
    END IF;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- 5. SEED ACCOUNTS (All configured with password: 'password123')
-- -----------------------------------------------------------------------------

-- 1. School Admin: Director Abebe (Bole Senior Secondary School)
SELECT public.provision_demo_user(
    'a1111111-1111-1111-1111-111111111111'::uuid,
    '+251944556677',
    'fidel_251944556677@gmail.com',
    'password123',
    'Director Abebe',
    'school_admin',
    12,
    'common',
    '11111111-1111-1111-1111-111111111111'::uuid,
    'school_admin'
);

-- 2. School Admin: Director Kebede (Hawassa Comprehensive Secondary School)
SELECT public.provision_demo_user(
    'a2222222-2222-2222-2222-222222222222'::uuid,
    '+251955667788',
    'fidel_251955667788@gmail.com',
    'password123',
    'Director Kebede',
    'school_admin',
    12,
    'common',
    '22222222-2222-2222-2222-222222222222'::uuid,
    'school_admin'
);

-- 3. Teacher: Teacher Alemayehu (Bole Senior Secondary School)
SELECT public.provision_demo_user(
    'de111111-1111-1111-1111-111111111111'::uuid,
    '+251922334455',
    'fidel_251922334455@gmail.com',
    'password123',
    'Teacher Alemayehu',
    'teacher',
    12,
    'natural',
    '11111111-1111-1111-1111-111111111111'::uuid,
    'teacher',
    'ca111111-1111-1111-1111-111111111111'::uuid
);

-- 4. Teacher: Teacher Bekele (Hawassa Comprehensive Secondary School)
SELECT public.provision_demo_user(
    'de222222-2222-2222-2222-222222222222'::uuid,
    '+251966778899',
    'fidel_251966778899@gmail.com',
    'password123',
    'Teacher Bekele',
    'teacher',
    12,
    'natural',
    '22222222-2222-2222-2222-222222222222'::uuid,
    'teacher',
    'ca222222-2222-2222-2222-222222222222'::uuid
);

-- 5. Student: Tamerat Mengesha (Bole Senior Secondary School)
SELECT public.provision_demo_user(
    'ba111111-1111-1111-1111-111111111111'::uuid,
    '+251949652355',
    'fidel_251949652355@gmail.com',
    'password123',
    'Tamerat Mengesha',
    'student',
    12,
    'natural',
    '11111111-1111-1111-1111-111111111111'::uuid,
    'student',
    'ca111111-1111-1111-1111-111111111111'::uuid
);

-- 6. Student: Demo Student (Bole Senior Secondary School)
SELECT public.provision_demo_user(
    'ba333333-3333-3333-3333-333333333333'::uuid,
    '+251911223344',
    'fidel_251911223344@gmail.com',
    'password123',
    'Demo Student',
    'student',
    12,
    'natural',
    '11111111-1111-1111-1111-111111111111'::uuid,
    'student',
    'ca111111-1111-1111-1111-111111111111'::uuid
);

-- 7. Platform Admin (Global CMS & Economy)
SELECT public.provision_demo_user(
    '00000000-0000-0000-0000-000000000001'::uuid,
    '+251933445566',
    'fidel_251933445566@gmail.com',
    'password123',
    'Global Platform Admin',
    'platform_admin',
    12,
    'common'
);

-- -----------------------------------------------------------------------------
-- 6. TEACHER SUBJECT ASSIGNMENTS
-- -----------------------------------------------------------------------------
INSERT INTO public.teacher_subject_assignments (
    school_id, teacher_user_id, classroom_id, subject_id, exam_variant, status
) VALUES 
    ('11111111-1111-1111-1111-111111111111', (SELECT id FROM auth.users WHERE email = 'fidel_251922334455@gmail.com'), 'ca111111-1111-1111-1111-111111111111', 'physics_g12', 'naturalScience', 'active'),
    ('22222222-2222-2222-2222-222222222222', (SELECT id FROM auth.users WHERE email = 'fidel_251966778899@gmail.com'), 'ca222222-2222-2222-2222-222222222222', 'math_g12', 'naturalScience', 'active')
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- 7. HELPER: PROVISION OR UPGRADE ANY REGISTERED PHONE NUMBER
--    Usage: SELECT public.assign_school_role('+2519xxxxxxxx', 'school_admin');
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.assign_school_role(TEXT, TEXT, UUID);
CREATE OR REPLACE FUNCTION public.assign_school_role(
    p_phone TEXT,
    p_role TEXT, -- 'school_admin', 'teacher', or 'student'
    p_school_id UUID DEFAULT '11111111-1111-1111-1111-111111111111'::uuid
) RETURNS TEXT AS $$
DECLARE
    v_user_id UUID;
    v_clean_phone TEXT;
    v_school_name TEXT;
BEGIN
    v_clean_phone := REPLACE(REPLACE(p_phone, '+', ''), ' ', '');
    IF v_clean_phone LIKE '0%' THEN
        v_clean_phone := '251' || SUBSTRING(v_clean_phone, 2);
    END IF;
    IF LENGTH(v_clean_phone) = 9 THEN
        v_clean_phone := '251' || v_clean_phone;
    END IF;

    SELECT id INTO v_user_id FROM public.profiles WHERE phone_number = p_phone OR phone_number = '+' || v_clean_phone LIMIT 1;
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id FROM auth.users WHERE phone = p_phone OR phone = '+' || v_clean_phone OR email = 'fidel_' || v_clean_phone || '@gmail.com' LIMIT 1;
    END IF;
    
    IF v_user_id IS NULL THEN
        RETURN 'ERROR: User with phone ' || p_phone || ' not found. Please register on the app first.';
    END IF;

    SELECT name INTO v_school_name FROM public.schools WHERE id = p_school_id;
    IF v_school_name IS NULL THEN
        RETURN 'ERROR: School ID ' || p_school_id || ' not found.';
    END IF;

    -- Upsert school membership
    INSERT INTO public.school_memberships (school_id, user_id, role, status, joined_at)
    VALUES (p_school_id, v_user_id, p_role, 'active', NOW())
    ON CONFLICT (school_id, user_id) DO UPDATE SET
        role = p_role,
        status = 'active';

    -- Upsert global user role
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_user_id, p_role)
    ON CONFLICT (user_id, role_id) DO NOTHING;

    RETURN 'SUCCESS: Assigned role ' || p_role || ' to ' || p_phone || ' at ' || v_school_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup temporary helper function
DROP FUNCTION IF EXISTS public.provision_demo_user(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, UUID, TEXT, UUID);

-- -----------------------------------------------------------------------------
-- 8. VERIFICATION OUTPUT
-- -----------------------------------------------------------------------------
SELECT 
    p.phone_number,
    p.display_name,
    sm.role AS school_role,
    s.name AS school_name,
    u.email AS auth_email,
    EXISTS(SELECT 1 FROM auth.identities i WHERE i.user_id = u.id) AS has_auth_identity,
    u.email_confirmed_at IS NOT NULL AS email_confirmed
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.school_memberships sm ON sm.user_id = p.id
LEFT JOIN public.schools s ON s.id = sm.school_id
WHERE p.phone_number IN ('+251944556677', '+251955667788', '+251922334455', '+251966778899', '+251949652355', '+251911223344', '+251933445566')
ORDER BY p.phone_number;
