-- =============================================================================
-- FidelLearn P6 Multi-Tenancy Seed Fixtures
-- Version: 20260925000000
-- Description: Test fixtures for verifying multi-tenant isolation, RLS policies,
--              classroom assignments, and student access boundaries.
-- =============================================================================

-- 1. Profiles
-- Platform Admin
INSERT INTO public.profiles (id, phone_number, display_name, grade, stream, preferred_language)
VALUES ('00000000-0000-0000-0000-000000000001', '+251911000000', 'Global Platform Admin', 12, 'natural', 'en')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (user_id, role_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'platform_admin')
ON CONFLICT (user_id, role_id) DO NOTHING;

-- School A Users
INSERT INTO public.profiles (id, phone_number, display_name, grade, stream, preferred_language)
VALUES 
    ('a1111111-1111-1111-1111-111111111111', '+251911111111', 'Admin Bole', 12, 'natural', 'en'),
    ('de111111-1111-1111-1111-111111111111', '+251911111112', 'Teacher Abebe (Bole)', 12, 'natural', 'en'),
    ('ba111111-1111-1111-1111-111111111111', '+251911111113', 'Student Almaz (Bole Class A)', 12, 'natural', 'en'),
    ('ba333333-3333-3333-3333-333333333333', '+251911111114', 'Student Chala (Bole Class C)', 12, 'natural', 'en')
ON CONFLICT (id) DO NOTHING;

-- School B Users
INSERT INTO public.profiles (id, phone_number, display_name, grade, stream, preferred_language)
VALUES 
    ('a2222222-2222-2222-2222-222222222222', '+251922222221', 'Admin Hawassa', 12, 'natural', 'en'),
    ('de222222-2222-2222-2222-222222222222', '+251922222222', 'Teacher Bekele (Hawassa)', 12, 'natural', 'en'),
    ('ba222222-2222-2222-2222-222222222222', '+251922222223', 'Student Biruk (Hawassa Class B)', 12, 'natural', 'en')
ON CONFLICT (id) DO NOTHING;

-- Multi-School Teacher, Transferred Student, Independent Student
INSERT INTO public.profiles (id, phone_number, display_name, grade, stream, preferred_language)
VALUES 
    ('de999999-9999-9999-9999-999999999999', '+251933333331', 'Teacher MultiSchool', 12, 'natural', 'en'),
    ('ba999999-9999-9999-9999-999999999999', '+251933333332', 'Student Transferred', 12, 'natural', 'en'),
    ('ba000000-0000-0000-0000-000000000000', '+251933333333', 'Student Independent', 12, 'natural', 'en')
ON CONFLICT (id) DO NOTHING;

-- 2. Schools
INSERT INTO public.schools (id, name, display_name, school_code, status, city, region, created_by)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Bole Senior Secondary School', 'Bole Secondary', 'FID-BOL001', 'active', 'Addis Ababa', 'Addis Ababa', '00000000-0000-0000-0000-000000000001'),
    ('22222222-2222-2222-2222-222222222222', 'Hawassa Comprehensive Secondary School', 'Hawassa Secondary', 'FID-HAW002', 'active', 'Hawassa', 'Sidama', '00000000-0000-0000-0000-000000000001'),
    ('33333333-3333-3333-3333-333333333333', 'Adama Model Secondary School', 'Adama Model', 'FID-ADA003', 'suspended', 'Adama', 'Oromia', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- 3. School Memberships (auto-generate UUIDs for id)
-- School A Memberships
INSERT INTO public.school_memberships (school_id, user_id, role, status, school_student_id)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'school_admin', 'active', NULL),
    ('11111111-1111-1111-1111-111111111111', 'de111111-1111-1111-1111-111111111111', 'teacher', 'active', 'EMP-BOL-01'),
    ('11111111-1111-1111-1111-111111111111', 'ba111111-1111-1111-1111-111111111111', 'student', 'active', 'STU-BOL-101'),
    ('11111111-1111-1111-1111-111111111111', 'ba333333-3333-3333-3333-333333333333', 'student', 'active', 'STU-BOL-301'),
    ('11111111-1111-1111-1111-111111111111', 'de999999-9999-9999-9999-999999999999', 'teacher', 'active', 'EMP-BOL-99'),
    ('11111111-1111-1111-1111-111111111111', 'ba999999-9999-9999-9999-999999999999', 'student', 'inactive', 'STU-BOL-900')
ON CONFLICT (school_id, user_id) DO NOTHING;

-- School B Memberships
INSERT INTO public.school_memberships (school_id, user_id, role, status, school_student_id)
VALUES 
    ('22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'school_admin', 'active', NULL),
    ('22222222-2222-2222-2222-222222222222', 'de222222-2222-2222-2222-222222222222', 'teacher', 'active', 'EMP-HAW-01'),
    ('22222222-2222-2222-2222-222222222222', 'ba222222-2222-2222-2222-222222222222', 'student', 'active', 'STU-HAW-201'),
    ('22222222-2222-2222-2222-222222222222', 'de999999-9999-9999-9999-999999999999', 'teacher', 'active', 'EMP-HAW-99'),
    ('22222222-2222-2222-2222-222222222222', 'ba999999-9999-9999-9999-999999999999', 'student', 'active', 'STU-HAW-900')
ON CONFLICT (school_id, user_id) DO NOTHING;

-- 4. Classrooms
INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
VALUES 
    ('ca111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section A', 12, 'naturalScience', 'A', '2026/27', 'active'),
    ('ca333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Grade 12 Natural - Section C', 12, 'naturalScience', 'C', '2026/27', 'active'),
    ('ca222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Grade 12 Natural - Section B', 12, 'naturalScience', 'B', '2026/27', 'active')
ON CONFLICT (id) DO NOTHING;

-- 5. Classroom Memberships
INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status)
VALUES 
    -- Class A (School A) has Student A
    ('ca111111-1111-1111-1111-111111111111', 'ba111111-1111-1111-1111-111111111111', 'student', 'active'),
    -- Class C (School A) has Student C
    ('ca333333-3333-3333-3333-333333333333', 'ba333333-3333-3333-3333-333333333333', 'student', 'active'),
    -- Class B (School B) has Student B and Transferred Student
    ('ca222222-2222-2222-2222-222222222222', 'ba222222-2222-2222-2222-222222222222', 'student', 'active'),
    ('ca222222-2222-2222-2222-222222222222', 'ba999999-9999-9999-9999-999999999999', 'student', 'active')
ON CONFLICT (classroom_id, user_id) DO NOTHING;

-- 6. Teacher Subject Assignments
-- Teacher A in School A teaches Physics in Class A ONLY (NOT in Class C!)
INSERT INTO public.teacher_subject_assignments (school_id, teacher_user_id, classroom_id, subject_id, exam_variant, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'de111111-1111-1111-1111-111111111111', 'ca111111-1111-1111-1111-111111111111', 'physics_g12', 'naturalScience', 'active')
ON CONFLICT (teacher_user_id, classroom_id, subject_id, COALESCE(exam_variant, 'shared')) DO NOTHING;

-- Teacher B in School B teaches Math in Class B
INSERT INTO public.teacher_subject_assignments (school_id, teacher_user_id, classroom_id, subject_id, exam_variant, status)
VALUES 
    ('22222222-2222-2222-2222-222222222222', 'de222222-2222-2222-2222-222222222222', 'ca222222-2222-2222-2222-222222222222', 'math_g12', 'naturalScience', 'active')
ON CONFLICT (teacher_user_id, classroom_id, subject_id, COALESCE(exam_variant, 'shared')) DO NOTHING;
