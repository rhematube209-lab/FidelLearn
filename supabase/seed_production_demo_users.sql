-- =============================================================================
-- FidelLearn Production Seed: Demo Accounts & Institutional Setup
-- Description: Creates real Supabase auth.users records, profiles, roles, 
--              schools, classrooms, memberships, and licenses for testing 
--              the redesigned dashboards on deployed staging/production.
-- Execution: Paste and run directly in the Supabase Dashboard SQL Editor.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. SCHOOLS
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
-- 2. CLASSROOMS
-- -----------------------------------------------------------------------------
INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
VALUES 
    ('ca111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section A', 12, 'naturalScience', 'A', '2026/27', 'active'),
    ('ca333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section C', 12, 'naturalScience', 'C', '2026/27', 'active'),
    ('ca222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Grade 12 Natural - Section B', 12, 'naturalScience', 'B', '2026/27', 'active')
ON CONFLICT (id) DO UPDATE SET status = 'active';

-- -----------------------------------------------------------------------------
-- 3. SCHOOL LICENSES (Active standard institutional license)
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
-- 4. HELPER UPSERT FUNCTION FOR AUTH & PROFILE PROVISIONING
-- -----------------------------------------------------------------------------
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
BEGIN
    -- Check if user already exists in auth.users by email or phone
    SELECT id INTO v_user_id FROM auth.users WHERE email = p_email OR phone = p_phone LIMIT 1;

    IF v_user_id IS NULL THEN
        -- Check if desired UUID is already taken
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
            p_email,
            crypt(p_password, gen_salt('bf')),
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
        -- Update password and confirmation timestamps on existing user
        UPDATE auth.users SET
            encrypted_password = crypt(p_password, gen_salt('bf')),
            email = p_email,
            phone = p_phone,
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
-- 5. SEED ACCOUNTS
-- -----------------------------------------------------------------------------

-- 1. School Admin: Director Abebe (Bole Senior Secondary School)
SELECT public.provision_demo_user(
    'a1111111-1111-1111-1111-111111111111'::uuid,
    '+251944556677',
    'fidel_251944556677@gmail.com',
    'schoolAdminPass123',
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
    'tenantAdminPass123',
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
    'teacherPass123',
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
    'tenantTeacherPass123',
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
    'adminPass123',
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
ON CONFLICT (teacher_user_id, classroom_id, subject_id, COALESCE(exam_variant, 'shared')) DO NOTHING;

-- Cleanup temporary helper function
DROP FUNCTION IF EXISTS public.provision_demo_user(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, UUID, TEXT, UUID);

-- -----------------------------------------------------------------------------
-- 7. VERIFICATION OUTPUT
-- -----------------------------------------------------------------------------
SELECT 
    p.phone_number,
    p.display_name,
    p.grade,
    sm.role AS school_role,
    s.name AS school_name
FROM public.profiles p
LEFT JOIN public.school_memberships sm ON sm.user_id = p.id
LEFT JOIN public.schools s ON s.id = sm.school_id
WHERE p.phone_number IN ('+251944556677', '+251955667788', '+251922334455', '+251966778899', '+251949652355', '+251911223344', '+251933445566')
ORDER BY p.phone_number;
