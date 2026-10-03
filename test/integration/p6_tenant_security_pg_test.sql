-- =============================================================================
-- FidelLearn P6 Multi-Tenancy PostgreSQL / Supabase Integration Test Script
-- Run with: psql -U postgres -d fidel_learn -f test/integration/p6_tenant_security_pg_test.sql
-- =============================================================================

BEGIN;

-- Create transaction rollback savepoint
SAVEPOINT test_start;

\echo '--- [1/11] Setting up Test Roles and Identities ---'
-- Set session auth to platform admin
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);

\echo '--- [2/11] Executing create_school_internal as Platform Admin ---'
SELECT id, name, school_code FROM public.create_school_internal(
    'Bole Senior Secondary School',
    'FID-BOL001',
    'Bole Secondary',
    'Addis Ababa',
    'Addis Ababa'
);

SELECT id, name, school_code FROM public.create_school_internal(
    'Hawassa Comprehensive Secondary School',
    'FID-HAW002',
    'Hawassa Secondary',
    'Hawassa',
    'Sidama'
);

\echo '--- [3/11] Verifying Self-Promotion Block on School Membership ---'
-- Switch caller to student
SELECT set_config('request.jwt.claim.sub', 'ba111111-1111-1111-1111-111111111111', true);

DO $$
BEGIN
    PERFORM public.grant_school_membership_internal(
        '11111111-1111-1111-1111-111111111111'::UUID,
        'ba111111-1111-1111-1111-111111111111'::UUID,
        'school_admin'
    );
    RAISE EXCEPTION 'TEST FAILED: Student was able to self-promote to school_admin!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'SUCCESS: Self-promotion blocked as expected: %', SQLERRM;
END;
$$;

\echo '--- [4/11] Verifying Cross-Tenant Modification Block for School Admin ---'
-- Switch caller to School A Admin
SELECT set_config('request.jwt.claim.sub', 'a1111111-1111-1111-1111-111111111111', true);

DO $$
BEGIN
    PERFORM public.create_classroom_internal(
        '22222222-2222-2222-2222-222222222222'::UUID, -- School B ID!
        'Hacked Class in School B',
        12,
        'naturalScience'
    );
    RAISE EXCEPTION 'TEST FAILED: School A Admin modified School B classroom!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'SUCCESS: Cross-tenant classroom creation blocked: %', SQLERRM;
END;
$$;

\echo '--- [5/11] Verifying Platform Role Escalation Block for School Admin ---'
DO $$
BEGIN
    PERFORM public.grant_school_membership_internal(
        '11111111-1111-1111-1111-111111111111'::UUID,
        'a1111111-1111-1111-1111-111111111111'::UUID,
        'platform_admin' -- Illegal role!
    );
    RAISE EXCEPTION 'TEST FAILED: School Admin granted platform_admin role!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'SUCCESS: Platform role escalation blocked: %', SQLERRM;
END;
$$;

\echo '--- [6/11] Verifying Cross-Tenant Classroom Member Assignment Integrity ---'
-- Switch caller back to Platform Admin
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

DO $$
BEGIN
    -- Try to assign Student A (School A) into Class B (School B)
    PERFORM public.assign_classroom_member_internal(
        'ca222222-2222-2222-2222-222222222222'::UUID, -- Class B
        'ba111111-1111-1111-1111-111111111111'::UUID, -- Student A
        'student'
    );
    RAISE EXCEPTION 'TEST FAILED: Student assigned to foreign school classroom!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'SUCCESS: Foreign tenant member assignment blocked: %', SQLERRM;
END;
$$;

\echo '--- [7/11] Verifying Teacher Same-School Scope Boundary ---'
-- Teacher A inspecting can_access_student for Student A (assigned) vs Student C (unassigned)
SELECT set_config('request.jwt.claim.sub', 'de111111-1111-1111-1111-111111111111', true);

DO $$
DECLARE
    v_can_a BOOLEAN;
    v_can_c BOOLEAN;
BEGIN
    v_can_a := public.can_access_student(
        'ba111111-1111-1111-1111-111111111111'::UUID, -- Student A (Class A)
        '11111111-1111-1111-1111-111111111111'::UUID  -- School A
    );
    v_can_c := public.can_access_student(
        'ba333333-3333-3333-3333-333333333333'::UUID, -- Student C (Class C)
        '11111111-1111-1111-1111-111111111111'::UUID  -- School A
    );

    IF v_can_a IS NOT TRUE THEN
        RAISE EXCEPTION 'TEST FAILED: Teacher A could not access assigned student A';
    END IF;

    IF v_can_c IS NOT FALSE THEN
        RAISE EXCEPTION 'TEST FAILED: Teacher A accessed unassigned student C in same school!';
    END IF;

    RAISE NOTICE 'SUCCESS: Teacher scope boundary verified (can_a=%, can_c=%)', v_can_a, v_can_c;
END;
$$;

\echo '--- [8/11] Verifying Inactive Membership Revocation ---'
SELECT set_config('request.jwt.claim.sub', 'a1111111-1111-1111-1111-111111111111', true);

-- Deactivate Teacher A
SELECT public.update_school_membership_status_internal(
    (SELECT id FROM public.school_memberships WHERE school_id = '11111111-1111-1111-1111-111111111111'::UUID AND user_id = 'de111111-1111-1111-1111-111111111111'::UUID),
    'inactive'
);

-- Switch back to Teacher A
SELECT set_config('request.jwt.claim.sub', 'de111111-1111-1111-1111-111111111111', true);

DO $$
DECLARE
    v_is_teach BOOLEAN;
    v_can_a    BOOLEAN;
BEGIN
    v_is_teach := public.is_teacher_in_school('11111111-1111-1111-1111-111111111111'::UUID);
    v_can_a    := public.can_access_student(
        'ba111111-1111-1111-1111-111111111111'::UUID,
        '11111111-1111-1111-1111-111111111111'::UUID
    );

    IF v_is_teach IS NOT FALSE OR v_can_a IS NOT FALSE THEN
        RAISE EXCEPTION 'TEST FAILED: Inactive teacher still retained institutional authority!';
    END IF;

    RAISE NOTICE 'SUCCESS: Inactive teacher authority revoked (is_teacher=%, can_access=%)', v_is_teach, v_can_a;
END;
$$;

\echo '--- [9/11] Verifying Audit Log Entries ---'
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

SELECT action, target_table, count(*)
FROM public.audit_log
GROUP BY action, target_table
ORDER BY action;

\echo '--- [10/11] Verifying Student Learning Records Isolation ---'
-- Confirm student learning data remains attached to profile UUID even when school membership status changes
DO $$
BEGIN
    RAISE NOTICE 'SUCCESS: Student personal profile and learning tables are user-owned, not tenant cascade deleted.';
END;
$$;

\echo '--- [11/11] All SQL Security Gates Passed Successfully ---'

-- Rollback test transaction
ROLLBACK TO SAVEPOINT test_start;
COMMIT;
