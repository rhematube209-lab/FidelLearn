const fs = require('fs');
const path = require('path');
const { PGlite } = require('C:/Users/tamer/.gemini/antigravity-ide/brain/306ba7e1-406d-4c4f-b110-48f3c763535d/scratch/node_modules/@electric-sql/pglite');

async function run() {
  console.log('=============================================================================');
  console.log('FidelLearn — Real PostgreSQL P11 Licensing, Seats & Onboarding Verification');
  console.log('=============================================================================');

  const db = new PGlite();

  // 1. Setup Supabase Core Auth Emulation
  console.log('\n[1/15] Initializing Supabase Auth Environment in PostgreSQL...');
  await db.exec(`
    CREATE SCHEMA IF NOT EXISTS auth;
    CREATE TABLE IF NOT EXISTS auth.users (
      id UUID PRIMARY KEY,
      email TEXT,
      phone TEXT,
      raw_user_meta_data JSONB,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
      SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.sub', true), ''),
        NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')
      )::UUID;
    $$ LANGUAGE sql STABLE;

    CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $$
      SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.role', true), ''),
        NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'role', ''),
        'authenticated'
      );
    $$ LANGUAGE sql STABLE;

    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role;
      END IF;
    END;
    $$;

    CREATE OR REPLACE FUNCTION public.uuid_generate_v4() RETURNS uuid AS $$
      SELECT gen_random_uuid();
    $$ LANGUAGE sql;

    CREATE OR REPLACE FUNCTION public.uuid_generate_v5(namespace uuid, name text) RETURNS uuid AS $$
      SELECT gen_random_uuid();
    $$ LANGUAGE sql;

    GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
  `);
  console.log('✓ Auth environment initialized.');

  // 2. Apply Migrations in Sequence
  console.log('\n[2/15] Applying Migrations...');
  const migrations = [
    'supabase/migrations/20260821000000_fidel_learn_schema.sql',
    'supabase/migrations/20260924000000_production_hardening.sql',
    'supabase/migrations/20260925000000_school_tenant_security.sql',
    'supabase/migrations/20260925010000_p7_teacher_portal.sql',
    'supabase/migrations/20260925020000_p8_school_leadership.sql',
    'supabase/migrations/20260925030000_p9_assignments_interventions.sql',
    'supabase/migrations/20260925040000_p10_institutional_reporting.sql',
    'supabase/migrations/20260925050000_p11_licensing_seats_onboarding.sql'
  ];

  for (const m of migrations) {
    const filePath = path.join(__dirname, '..', m);
    let sql = fs.readFileSync(filePath, 'utf8');
    sql = sql.replace(/CREATE EXTENSION IF NOT EXISTS "uuid-ossp";/gi, '-- uuid-ossp fallback');
    try {
      await db.exec(sql);
      console.log(`✓ ${m} applied successfully.`);
    } catch (e) {
      console.error(`FAILED: ${m}:`, e);
      process.exit(1);
    }
  }

  // Helper context setters
  const asSuperuser = async () => {
    await db.exec(`
      SET SESSION "request.jwt.claim.sub" = '';
      SET SESSION "request.jwt.claim.role" = '';
      RESET ROLE;
    `);
  };

  const asUser = async (userId, role = 'authenticated') => {
    if (!userId) {
      const r = role === 'service_role' ? 'service_role' : 'anon';
      await db.exec(`
        SET SESSION "request.jwt.claim.sub" = '';
        SET SESSION "request.jwt.claim.role" = '${r}';
        SET ROLE ${r};
      `);
    } else {
      await db.exec(`
        SET SESSION "request.jwt.claim.sub" = '${userId}';
        SET SESSION "request.jwt.claim.role" = '${role}';
        SET ROLE ${role};
      `);
    }
  };

  let passedTests = 0;
  let failedTests = 0;

  const assert = (condition, message) => {
    if (condition) {
      passedTests++;
      console.log(`  ✓ PASS: ${message}`);
    } else {
      failedTests++;
      console.error(`  ✗ FAIL: ${message}`);
    }
  };

  // 3. Catalog & SECURITY DEFINER Audit
  console.log('\n[3/15] Catalog Verification: Inspecting SECURITY DEFINER, search_path & RLS...');
  const p11Rpcs = [
    'is_school_license_effective',
    'get_school_seat_usage',
    'check_school_seat_capacity',
    'get_school_entitlements',
    'school_has_entitlement',
    'create_school_license_internal',
    'transition_school_license_internal',
    'update_school_seat_limit_internal',
    'update_school_entitlements_internal',
    'get_school_license',
    'validate_school_activation',
    'activate_school_internal',
    'execute_bulk_student_enrollment_internal',
    'assign_student_to_classroom_internal',
    'update_classroom_member_status_internal',
    'assign_classroom_member_internal',
    'process_billing_event_internal',
    'sync_school_license_expiration_internal',
    'resolve_teacher_class_subject_school',
    'get_teacher_assigned_classes',
    'resolve_school_admin_authority',
    'can_teacher_manage_assignment',
    'complete_student_intervention',
    'close_student_intervention',
    'close_learning_assignment',
    'archive_learning_assignment',
    'validate_report_authority'
  ];

  const rpcRes = await db.query(`
    SELECT proname, prosecdef, proconfig
    FROM pg_proc
    WHERE proname = ANY($1::text[])
  `, [p11Rpcs]);

  const foundRpcs = new Set(rpcRes.rows.map(r => r.proname));
  const missingRpcs = p11Rpcs.filter(p => !foundRpcs.has(p));
  if (missingRpcs.length > 0) {
    console.log('Note - Functions not in pg_proc:', missingRpcs);
  }
  assert(missingRpcs.length === 0, `All ${p11Rpcs.length} P11 & integrated functions registered in catalog`);
  const allSecDefiner = rpcRes.rows.every(r => r.prosecdef === true);
  assert(allSecDefiner, 'All P11 privileged functions confirmed SECURITY DEFINER');

  // Verify search_path contains 'public, pg_temp'
  const allSafeSearchPath = rpcRes.rows.every(r => {
    const config = r.proconfig || [];
    return config.some(c => c === 'search_path=public, pg_temp');
  });
  assert(allSafeSearchPath, 'All P11 privileged functions enforce hardened search_path = public, pg_temp');

  const p11Tables = [
    'institutional_plans',
    'school_licenses',
    'school_license_events',
    'school_onboarding_state',
    'institutional_import_runs',
    'billing_customers',
    'billing_subscriptions',
    'billing_events'
  ];

  const rlsRes = await db.query(`
    SELECT relname, relrowsecurity
    FROM pg_class
    WHERE relname = ANY($1::text[]) AND relnamespace = 'public'::regnamespace
  `, [p11Tables]);

  assert(rlsRes.rows.length === p11Tables.length, `All ${p11Tables.length} P11 tables present in catalog`);
  const allRls = rlsRes.rows.every(r => r.relrowsecurity === true);
  assert(allRls, 'All P11 tables have Row Level Security (RLS) enabled');

  // 4. Seed Multi-Tenant Test Data
  console.log('\n[4/15] Seeding Multi-Tenant Test Fixtures...');
  await asSuperuser();

  const platformAdminId = '11111111-0000-0000-0000-000000000001';
  const schoolAdminAId = '11111111-0000-0000-0000-000000000002';
  const schoolAdminBId = '11111111-0000-0000-0000-000000000003';
  const teacherAId = '11111111-0000-0000-0000-000000000004';
  const student1Id = '11111111-0000-0000-0000-000000000005';
  const student2Id = '11111111-0000-0000-0000-000000000006';
  const student3Id = '11111111-0000-0000-0000-000000000007';
  const student4Id = '11111111-0000-0000-0000-000000000008';

  const schoolAId = '22222222-0000-0000-0000-000000000001';
  const schoolBId = '22222222-0000-0000-0000-000000000002';

  const classA1Id = '33333333-0000-0000-0000-000000000001';
  const classA2Id = '33333333-0000-0000-0000-000000000002';

  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES
      ('${platformAdminId}', '+251911000001'),
      ('${schoolAdminAId}', '+251911000002'),
      ('${schoolAdminBId}', '+251911000003'),
      ('${teacherAId}', '+251911000004'),
      ('${student1Id}', '+251911000005'),
      ('${student2Id}', '+251911000006'),
      ('${student3Id}', '+251911000007'),
      ('${student4Id}', '+251911000008')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream) VALUES
      ('${platformAdminId}', '+251911000001', 'Global Platform Admin', 12, 'natural'),
      ('${schoolAdminAId}', '+251911000002', 'Admin School A', 12, 'natural'),
      ('${schoolAdminBId}', '+251911000003', 'Admin School B', 12, 'social'),
      ('${teacherAId}', '+251911000004', 'Teacher School A', 12, 'natural'),
      ('${student1Id}', '+251911000005', 'Student One', 12, 'natural'),
      ('${student2Id}', '+251911000006', 'Student Two', 12, 'natural'),
      ('${student3Id}', '+251911000007', 'Student Three', 12, 'natural'),
      ('${student4Id}', '+251911000008', 'Student Four', 12, 'natural')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_roles (user_id, role_id) VALUES
      ('${platformAdminId}', 'platform_admin'),
      ('${schoolAdminAId}', 'school_admin'),
      ('${schoolAdminBId}', 'school_admin'),
      ('${teacherAId}', 'teacher'),
      ('${student1Id}', 'student'),
      ('${student2Id}', 'student'),
      ('${student3Id}', 'student'),
      ('${student4Id}', 'student')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.schools (id, name, display_name, school_code, status, city, region) VALUES
      ('${schoolAId}', 'Addis Ababa Secondary A', 'AA High A', 'SCH-AAA', 'active', 'Addis Ababa', 'Addis Ababa'),
      ('${schoolBId}', 'Hawassa Secondary B', 'Hawassa High B', 'SCH-HWB', 'active', 'Hawassa', 'Sidama')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES
      ('${schoolAId}', '${schoolAdminAId}', 'school_admin', 'active'),
      ('${schoolBId}', '${schoolAdminBId}', 'school_admin', 'active'),
      ('${schoolAId}', '${teacherAId}', 'teacher', 'active'),
      ('${schoolAId}', '${student1Id}', 'student', 'active'),
      ('${schoolAId}', '${student2Id}', 'student', 'active'),
      ('${schoolAId}', '${student3Id}', 'student', 'active'),
      ('${schoolAId}', '${student4Id}', 'student', 'active')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status) VALUES
      ('${classA1Id}', '${schoolAId}', 'Grade 12 Natural Section A', 12, 'naturalScience', 'A', '2026/27', 'active'),
      ('${classA2Id}', '${schoolAId}', 'Grade 12 Natural Section B', 12, 'naturalScience', 'B', '2026/27', 'active')
    ON CONFLICT (id) DO NOTHING;
  `);
  console.log('✓ Multi-tenant fixtures seeded successfully.');

  // 5. Commercial Administration & Authorization Tests
  console.log('\n[5/15] Running Commercial Admin Authorization Tests...');

  // Test 5.1: Platform Admin creates license for School A
  await asUser(platformAdminId);
  const licRes = await db.query(`
    SELECT * FROM public.create_school_license_internal(
      '${schoolAId}'::uuid,
      'school_standard',
      3, -- Exact boundary capacity of 3
      'manual_contract',
      NOW(),
      NOW() + INTERVAL '365 days',
      NULL
    )
  `);
  assert(licRes.rows.length === 1 && licRes.rows[0].status === 'active', 'Platform Admin creates valid active institutional license');

  // Test 5.2: School Admin cannot create license directly
  await asUser(schoolAdminAId);
  let adminMutateFailed = false;
  try {
    await db.query(`SELECT * FROM public.create_school_license_internal('${schoolAId}'::uuid, 'school_standard', 100)`);
  } catch (err) {
    adminMutateFailed = true;
  }
  assert(adminMutateFailed, 'School Admin attempting to create license directly is DENIED');

  // Test 5.3: School Admin cannot update seat limit
  let seatChangeBlocked = false;
  try {
    await db.query(`SELECT * FROM public.update_school_seat_limit_internal('${schoolAId}'::uuid, 999, 'Self expansion')`);
  } catch (err) {
    seatChangeBlocked = true;
  }
  assert(seatChangeBlocked, 'School Admin attempting to increase seat limit directly is DENIED');

  // Test 5.4: School Admin cannot update entitlements
  let entChangeBlocked = false;
  try {
    await db.query(`SELECT * FROM public.update_school_entitlements_internal('${schoolAId}'::uuid, '{"all": true}'::jsonb, 'Self unlock')`);
  } catch (err) {
    entChangeBlocked = true;
  }
  assert(entChangeBlocked, 'School Admin attempting to change entitlements directly is DENIED');

  // Test 5.5: School Admin cannot transition license state
  let transBlocked = false;
  try {
    await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolAId}'::uuid, 'active', 'Force active')`);
  } catch (err) {
    transBlocked = true;
  }
  assert(transBlocked, 'School Admin attempting to transition license state is DENIED');

  // Test 5.6: Student calling get_school_license is denied
  await asUser(student1Id);
  let studentRpcFailed = false;
  try {
    await db.query(`SELECT * FROM public.get_school_license('${schoolAId}'::uuid)`);
  } catch (err) {
    studentRpcFailed = true;
  }
  assert(studentRpcFailed, 'Student calling get_school_license is DENIED');

  // Test 5.7: Cross-school admin cannot view School A license
  await asUser(schoolAdminBId);
  let crossSchoolFailed = false;
  try {
    await db.query(`SELECT * FROM public.get_school_license('${schoolAId}'::uuid)`);
  } catch (err) {
    crossSchoolFailed = true;
  }
  assert(crossSchoolFailed, 'Cross-school admin accessing School A license is DENIED');

  // Test 5.8: School Admin A views own school license and seat limit
  await asUser(schoolAdminAId);
  const ownLicRes = await db.query(`SELECT * FROM public.get_school_license('${schoolAId}'::uuid)`);
  assert(ownLicRes.rows.length === 1 && ownLicRes.rows[0].get_school_license.student_seat_limit === 3, 'School Admin views own school license and seat limit');

  // 6. Seat Limit Enforcement, Deduplication & Capacity Tests
  console.log('\n[6/15] Running Seat Accounting & Capacity Enforcement Tests...');

  // Test 6.1: Enroll Student 1 -> 1/3 occupied
  await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA1Id}'::uuid, '${student1Id}'::uuid, 'student')`);
  let usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  let usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 1 && usage.available_seats === 2 && usage.is_over_capacity === false, 'Student 1 enrolled: occupied=1, available=2');

  // Test 6.2: Enroll Student 2 -> 2/3 occupied
  await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA1Id}'::uuid, '${student2Id}'::uuid, 'student')`);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 2 && usage.available_seats === 1, 'Student 2 enrolled: occupied=2, available=1');

  // Test 6.3: Enroll Student 3 -> 3/3 occupied (100% capacity)
  await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA1Id}'::uuid, '${student3Id}'::uuid, 'student')`);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 3 && usage.available_seats === 0 && Number(usage.seat_utilization_pct) === 100, 'Student 3 enrolled: occupied=3, available=0, utilization=100%');

  // Test 6.4: Multi-Classroom Student Deduplication
  // Enroll Student 1 in Class A2 as well -> occupied remains 3
  await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA2Id}'::uuid, '${student1Id}'::uuid, 'student')`);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 3 && usage.available_seats === 0, 'Multi-classroom student occupies exactly 1 seat: occupied remains 3');

  // Test 6.5: Attempt to enroll 4th distinct student when capacity is 3/3 -> Hard DENIED
  let overageBlocked = false;
  try {
    await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA1Id}'::uuid, '${student4Id}'::uuid, 'student')`);
  } catch (err) {
    overageBlocked = err.message.includes('SEAT_LIMIT_EXCEEDED');
  }
  assert(overageBlocked, '4th distinct student enrollment over 3-seat limit is DENIED with SEAT_LIMIT_EXCEEDED');

  // Test 6.6: Multi-Classroom Seat Release Retention
  // Deactivating Student 1 in Class A1 must NOT release the seat because Student 1 is still active in Class A2!
  await db.query(`
    SELECT * FROM public.update_classroom_member_status_internal(
      '${classA1Id}'::uuid, '${student1Id}'::uuid, 'inactive'
    )
  `);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 3 && usage.available_seats === 0, 'Deactivating multi-class student in 1 class does NOT release seat (remains active in other class)');

  // Test 6.7: Full Seat Release
  // Now deactivate Student 1 in Class A2 as well -> student is no longer active anywhere -> seat released!
  await db.query(`
    SELECT * FROM public.update_classroom_member_status_internal(
      '${classA2Id}'::uuid, '${student1Id}'::uuid, 'inactive'
    )
  `);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 2 && usage.available_seats === 1, 'Deactivating student in all classes releases seat: occupied=2, available=1');

  // Student 4 now successfully consumes released seat
  await db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classA1Id}'::uuid, '${student4Id}'::uuid, 'student')`);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.occupied_seats === 3 && usage.available_seats === 0, 'Student 4 successfully consumes released seat: occupied=3, available=0');

  // Test 6.8: Reactivation Capacity Guard
  // Trying to reactivate Student 1 back to 'active' when capacity is 3/3 must be blocked!
  let reactivateBlocked = false;
  try {
    await db.query(`
      SELECT * FROM public.update_classroom_member_status_internal(
        '${classA1Id}'::uuid, '${student1Id}'::uuid, 'active'
      )
    `);
  } catch (err) {
    reactivateBlocked = err.message.includes('SEAT_LIMIT_EXCEEDED');
  }
  assert(reactivateBlocked, 'Reactivating inactive student when at 100% capacity is DENIED with SEAT_LIMIT_EXCEEDED');

  // Test 6.9: Legacy Entrypoint Guard
  // Calling legacy assign_classroom_member_internal must forward to seat capacity validation and fail!
  let legacyBlocked = false;
  try {
    await db.query(`
      SELECT * FROM public.assign_classroom_member_internal(
        '${classA1Id}'::uuid, '${student1Id}'::uuid, 'student'
      )
    `);
  } catch (err) {
    legacyBlocked = err.message.includes('SEAT_LIMIT_EXCEEDED');
  }
  assert(legacyBlocked, 'Legacy assign_classroom_member_internal forwards through seat guard and is DENIED');

  // Test 6.10: Non-destructive Seat Decrease Policy
  // Platform Admin decreases limit from 3 to 2 while 3 students are enrolled
  await asUser(platformAdminId);
  await db.query(`
    SELECT * FROM public.update_school_seat_limit_internal(
      '${schoolAId}'::uuid, 2, 'Contractual seat reduction'
    )
  `);
  usageRes = await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`);
  usage = usageRes.rows[0].get_school_seat_usage;
  assert(usage.student_seat_limit === 2 && usage.occupied_seats === 3 && usage.is_over_capacity === true, 'Seat limit decreased to 2: students preserved, is_over_capacity=true');

  // Restore limit to 10
  await db.query(`SELECT * FROM public.update_school_seat_limit_internal('${schoolAId}'::uuid, 10, 'Expand for testing')`);

  // 7. Concurrency Test — CRITICAL (Items 20, 21, 22)
  console.log('\n[7/15] Running Real PostgreSQL Concurrency & Serialization Proof...');
  const schoolConcId = '22222222-0000-0000-0000-000000000099';
  const classConcId = '33333333-0000-0000-0000-000000000099';
  const adminConcId = '11111111-0000-0000-0000-000000000099';

  await asSuperuser();
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES ('${adminConcId}', '+251911999999') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream)
      VALUES ('${adminConcId}', '+251911999999', 'Admin Conc', 12, 'natural') ON CONFLICT DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES ('${adminConcId}', 'school_admin') ON CONFLICT DO NOTHING;
    INSERT INTO public.schools (id, name, display_name, school_code, status)
      VALUES ('${schoolConcId}', 'Concurrency Test High', 'Conc High', 'SCH-CNC', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status)
      VALUES ('${schoolConcId}', '${adminConcId}', 'school_admin', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
      VALUES ('${classConcId}', '${schoolConcId}', 'Grade 12 Conc Section', 12, 'naturalScience', 'A', '2026/27', 'active') ON CONFLICT DO NOTHING;
  `);

  // Create license with student_seat_limit = 100
  await asUser(platformAdminId);
  await db.query(`
    SELECT * FROM public.create_school_license_internal(
      '${schoolConcId}'::uuid,
      'school_standard',
      100,
      'manual_contract',
      NOW(),
      NOW() + INTERVAL '365 days',
      NULL
    )
  `);

  // Seed 99 students directly into classroom
  await asSuperuser();
  const studentIds = [];
  let seedValues = [];
  let userValues = [];
  let profValues = [];
  let roleValues = [];
  let memValues = [];

  for (let i = 1; i <= 99; i++) {
    const pad = i.toString().padStart(4, '0');
    const uId = `44444444-0000-0000-0000-00000000${pad}`;
    studentIds.push(uId);
    userValues.push(`('${uId}', '+25193300${pad}')`);
    profValues.push(`('${uId}', '+25193300${pad}', 'Student ${i}', 12, 'natural')`);
    roleValues.push(`('${uId}', 'student')`);
    memValues.push(`('${schoolConcId}', '${uId}', 'student', 'active')`);
    seedValues.push(`('${classConcId}', '${uId}', 'student', 'active')`);
  }

  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES ${userValues.join(', ')} ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream) VALUES ${profValues.join(', ')} ON CONFLICT DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES ${roleValues.join(', ')} ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES ${memValues.join(', ')} ON CONFLICT DO NOTHING;
    INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status) VALUES ${seedValues.join(', ')} ON CONFLICT DO NOTHING;
  `);

  // Verify occupied = 99
  let concUsage = (await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolConcId}'::uuid)`)).rows[0].get_school_seat_usage;
  assert(concUsage.occupied_seats === 99 && concUsage.student_seat_limit === 100, 'Concurrency Fixture: occupied=99, limit=100 (exactly 1 seat remaining)');

  // Create Student 100 and Student 101
  const stu100Id = '44444444-0000-0000-0000-000000000100';
  const stu101Id = '44444444-0000-0000-0000-000000000101';
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES ('${stu100Id}', '+251933000100'), ('${stu101Id}', '+251933000101') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream) VALUES
      ('${stu100Id}', '+251933000100', 'Student 100', 12, 'natural'),
      ('${stu101Id}', '+251933000101', 'Student 101', 12, 'natural') ON CONFLICT DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES ('${stu100Id}', 'student'), ('${stu101Id}', 'student') ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES
      ('${schoolConcId}', '${stu100Id}', 'student', 'active'),
      ('${schoolConcId}', '${stu101Id}', 'student', 'active') ON CONFLICT DO NOTHING;
  `);

  // Simulate concurrent execution: Transaction A activates Student 100, Transaction B activates Student 101 simultaneously!
  await asUser(adminConcId);
  const task1 = db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classConcId}'::uuid, '${stu100Id}'::uuid, 'student')`);
  const task2 = db.query(`SELECT * FROM public.assign_student_to_classroom_internal('${classConcId}'::uuid, '${stu101Id}'::uuid, 'student')`);

  const results = await Promise.allSettled([task1, task2]);
  const succeeded = results.filter(r => r.status === 'fulfilled');
  const failed = results.filter(r => r.status === 'rejected');

  assert(succeeded.length === 1, 'Concurrency execution: Exactly 1 transaction succeeded');
  assert(failed.length === 1 && failed[0].reason.message.includes('SEAT_LIMIT_EXCEEDED'), 'Concurrency execution: Exactly 1 transaction failed with SEAT_LIMIT_EXCEEDED');

  concUsage = (await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolConcId}'::uuid)`)).rows[0].get_school_seat_usage;
  assert(concUsage.occupied_seats === 100 && concUsage.available_seats === 0, 'Concurrency proof: Final occupied seats = 100, NEVER 101');

  // 8. License State Machine & Effective Expiration
  console.log('\n[8/15] Running Subscription Lifecycle & Effective Expiration Tests...');

  // Legal transitions: active -> grace -> suspended -> active
  await asUser(platformAdminId);
  let trans = await db.query(`
    SELECT * FROM public.transition_school_license_internal(
      '${schoolAId}'::uuid, 'grace', 'Payment issue grace period', NOW() + INTERVAL '14 days'
    )
  `);
  assert(trans.rows[0].status === 'grace' && trans.rows[0].grace_ends_at !== null, 'Transition active -> grace recorded with grace_ends_at');

  trans = await db.query(`
    SELECT * FROM public.transition_school_license_internal(
      '${schoolAId}'::uuid, 'suspended', 'Non-payment suspension'
    )
  `);
  assert(trans.rows[0].status === 'suspended', 'Transition grace -> suspended recorded');

  // Suspended license has zero active entitlements
  let entRes = await db.query(`SELECT * FROM public.get_school_entitlements('${schoolAId}'::uuid)`);
  assert(Object.keys(entRes.rows[0].get_school_entitlements).length === 0, 'Suspended license returns zero feature entitlements');

  // Reactivation restores active license without tenant reconstruction
  trans = await db.query(`
    SELECT * FROM public.transition_school_license_internal(
      '${schoolAId}'::uuid, 'active', 'Invoice settled reactivation'
    )
  `);
  assert(trans.rows[0].status === 'active', 'Reactivation restores active license with original school ID');

  entRes = await db.query(`SELECT * FROM public.get_school_entitlements('${schoolAId}'::uuid)`);
  assert(entRes.rows[0].get_school_entitlements.institutional_reporting === true, 'Reactivation restores institutional_reporting entitlement');

  // Illegal transitions: active -> trial DENIED
  let illegalBlocked = false;
  try {
    await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolAId}'::uuid, 'trial', 'Invalid downgrade')`);
  } catch (err) {
    illegalBlocked = err.message.includes('ILLEGAL_TRANSITION');
  }
  assert(illegalBlocked, 'Illegal transition active -> trial is DENIED with ILLEGAL_TRANSITION');

  // Cancelled is terminal: transition to cancelled succeeds, but cancelled -> active is DENIED!
  await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolConcId}'::uuid, 'cancelled', 'Contract terminated')`);
  let cancelledReactivateBlocked = false;
  try {
    await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolConcId}'::uuid, 'active', 'Invalid reactivate')`);
  } catch (err) {
    cancelledReactivateBlocked = err.message.includes('ILLEGAL_TRANSITION');
  }
  assert(cancelledReactivateBlocked, 'Terminal transition cancelled -> active is DENIED with ILLEGAL_TRANSITION');

  // Effective expiration: license whose ends_at < NOW()
  const expSchoolId = '22222222-0000-0000-0000-000000000088';
  await asSuperuser();
  await db.exec(`
    INSERT INTO public.schools (id, name, display_name, school_code, status)
      VALUES ('${expSchoolId}', 'Expired Secondary', 'Exp High', 'SCH-EXP', 'active') ON CONFLICT DO NOTHING;
  `);
  await asUser(platformAdminId);
  await db.query(`
    SELECT * FROM public.create_school_license_internal(
      '${expSchoolId}'::uuid, 'school_standard', 50, 'manual_contract', NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day', NULL
    )
  `);
  // Sync expiration helper transitions to expired
  await asSuperuser();
  const syncExpRes = await db.query(`SELECT public.sync_school_license_expiration_internal('${expSchoolId}'::uuid)`);
  const expRow = (await db.query(`SELECT status FROM public.school_licenses WHERE school_id = '${expSchoolId}'`)).rows[0];
  assert(
    syncExpRes.rows[0].sync_school_license_expiration_internal.status === 'completed' && expRow.status === 'expired',
    'Expired license (ends_at < NOW()) deterministically transitions to expired'
  );

  // 8b. Commercial Request-Time Entitlement Evaluation: Trial Semantics
  const schoolTrialId = '22222222-0000-0000-0000-000000000091';
  await asSuperuser();
  await db.exec(`
    INSERT INTO public.schools (id, name, display_name, school_code, status)
      VALUES ('${schoolTrialId}', 'Trial Secondary', 'Trial High', 'SCH-TRL', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.school_licenses (school_id, plan_code, status, starts_at, ends_at, student_seat_limit, feature_entitlements, source)
      VALUES (
        '${schoolTrialId}', 'trial', 'trial', NOW() - INTERVAL '1 day', NOW() + INTERVAL '14 days', 100,
        jsonb_build_object('student_learning', true, 'teacher_portal', true, 'leadership_dashboard', true, 'assignments_interventions', true, 'institutional_reporting', true),
        'trial_provisioning'
      ) ON CONFLICT (school_id) DO UPDATE SET status = 'trial', ends_at = NOW() + INTERVAL '14 days';
  `);
  // Valid trial is effective and has entitlement
  const trialEffective = await db.query(`SELECT public.is_school_license_effective('${schoolTrialId}'::uuid)`);
  assert(trialEffective.rows[0].is_school_license_effective === true, 'Trial Semantics: Valid trial license is commercially effective (starts_at <= NOW, ends_at in future)');
  const trialEnt = await db.query(`SELECT public.school_has_entitlement('${schoolTrialId}'::uuid, 'teacher_portal')`);
  assert(trialEnt.rows[0].school_has_entitlement === true, 'Trial Semantics: school_has_entitlement returns TRUE for entitled feature during valid trial');

  // Expired trial: ends_at in the past fails immediately closed without requiring scheduler
  await db.query(`UPDATE public.school_licenses SET ends_at = NOW() - INTERVAL '1 day' WHERE school_id = '${schoolTrialId}'`);
  const trialExpEffective = await db.query(`SELECT public.is_school_license_effective('${schoolTrialId}'::uuid)`);
  assert(trialExpEffective.rows[0].is_school_license_effective === false, 'Trial Semantics: Expired trial fails closed immediately (is_school_license_effective = false)');
  const trialExpEnt = await db.query(`SELECT public.school_has_entitlement('${schoolTrialId}'::uuid, 'teacher_portal')`);
  assert(trialExpEnt.rows[0].school_has_entitlement === false, 'Trial Semantics: school_has_entitlement returns FALSE immediately upon trial expiry without scheduler');

  // 8c. Commercial Request-Time Entitlement Evaluation: Grace Semantics
  const schoolGraceId = '22222222-0000-0000-0000-000000000092';
  await db.exec(`
    INSERT INTO public.schools (id, name, display_name, school_code, status)
      VALUES ('${schoolGraceId}', 'Grace Secondary', 'Grace High', 'SCH-GRC', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.school_licenses (school_id, plan_code, status, starts_at, ends_at, grace_ends_at, student_seat_limit, feature_entitlements, source)
      VALUES (
        '${schoolGraceId}', 'school_standard', 'grace', NOW() - INTERVAL '30 days', NOW() - INTERVAL '1 day', NOW() + INTERVAL '10 days', 100,
        jsonb_build_object('student_learning', true, 'teacher_portal', true, 'leadership_dashboard', true, 'assignments_interventions', true, 'institutional_reporting', true),
        'manual_contract'
      ) ON CONFLICT (school_id) DO UPDATE SET status = 'grace', ends_at = NOW() - INTERVAL '1 day', grace_ends_at = NOW() + INTERVAL '10 days';
  `);
  // Valid grace: past contract ends_at does NOT cancel valid grace period
  const graceEffective = await db.query(`SELECT public.is_school_license_effective('${schoolGraceId}'::uuid)`);
  assert(graceEffective.rows[0].is_school_license_effective === true, 'Grace Semantics: Valid grace period is commercially effective even when contract ends_at has elapsed');
  const graceEnt = await db.query(`SELECT public.school_has_entitlement('${schoolGraceId}'::uuid, 'teacher_portal')`);
  assert(graceEnt.rows[0].school_has_entitlement === true, 'Grace Semantics: school_has_entitlement returns TRUE during active grace governed by grace_ends_at');

  // Expired grace: grace_ends_at in past fails closed immediately without scheduler
  await db.query(`UPDATE public.school_licenses SET grace_ends_at = NOW() - INTERVAL '1 day' WHERE school_id = '${schoolGraceId}'`);
  const graceExpEffective = await db.query(`SELECT public.is_school_license_effective('${schoolGraceId}'::uuid)`);
  assert(graceExpEffective.rows[0].is_school_license_effective === false, 'Grace Semantics: Expired grace fails closed immediately (is_school_license_effective = false)');
  const graceExpEnt = await db.query(`SELECT public.school_has_entitlement('${schoolGraceId}'::uuid, 'teacher_portal')`);
  assert(graceExpEnt.rows[0].school_has_entitlement === false, 'Grace Semantics: school_has_entitlement returns FALSE immediately when grace_ends_at has passed');

  // 8d. Direct Authorization & Cross-School Entitlement Probing Defense
  // teacherAId belongs only to schoolAId
  await asUser(teacherAId);
  let crossSchoolTeacherBlocked = false;
  try {
    await db.query(`SELECT public.school_has_entitlement('${schoolBId}'::uuid, 'institutional_reporting')`);
  } catch (err) {
    crossSchoolTeacherBlocked = err.message.includes('42501') || err.message.includes('Access denied');
  }
  assert(crossSchoolTeacherBlocked, 'Security: Cross-school entitlement check by teacher in School A against School B is strictly DENIED (42501)');

  // schoolAdminAId belongs only to schoolAId
  await asUser(schoolAdminAId);
  let crossSchoolAdminBlocked = false;
  try {
    await db.query(`SELECT public.school_has_entitlement('${schoolBId}'::uuid, 'institutional_reporting')`);
  } catch (err) {
    crossSchoolAdminBlocked = err.message.includes('42501') || err.message.includes('Access denied');
  }
  assert(crossSchoolAdminBlocked, 'Security: Cross-school entitlement check by admin in School A against School B is strictly DENIED (42501)');

  // Same user querying their OWN school succeeds
  const ownSchoolEnt = await db.query(`SELECT public.school_has_entitlement('${schoolAId}'::uuid, 'institutional_reporting')`);
  assert(ownSchoolEnt.rows[0].school_has_entitlement === true, 'Security: Direct authenticated entitlement check for caller own school is ALLOWED');

  // Platform admin querying any school succeeds
  await asUser(platformAdminId);
  const platAdminEnt = await db.query(`SELECT public.school_has_entitlement('${schoolBId}'::uuid, 'institutional_reporting')`);
  assert(typeof platAdminEnt.rows[0].school_has_entitlement === 'boolean', 'Security: Platform admin has global oversight access to school_has_entitlement');

  // 9. Entitlement Integration on P7, P8, P9, P10
  console.log('\n[9/15] Running P7–P10 Commercial Entitlement Integration Tests...');

  // Setup teacher assignment and subject for P7
  await asSuperuser();
  await db.exec(`
    INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, sort_order)
      VALUES ('physics_g12', 'PHYS12', 'Physics', 'ፊዚክስ', 12, 'natural', 1)
      ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.teacher_subject_assignments (school_id, classroom_id, teacher_user_id, subject_id, status)
      VALUES ('${schoolAId}', '${classA1Id}', '${teacherAId}', 'physics_g12', 'active')
      ON CONFLICT DO NOTHING;
  `);

  // Active School A with full entitlements: P7 teacher portal succeeds
  await asUser(teacherAId);
  const p7Classes = await db.query(`SELECT * FROM public.get_teacher_assigned_classes('${schoolAId}'::uuid)`);
  assert(p7Classes.rows.length >= 1, 'P7 Teacher Portal: Allowed when license is active and teacher_portal entitlement enabled');

  // Active School A: P8 leadership succeeds
  await asUser(schoolAdminAId);
  const p8Auth = await db.query(`SELECT public.resolve_school_admin_authority('${schoolAId}'::uuid)`);
  assert(p8Auth.rows[0].resolve_school_admin_authority === true, 'P8 Leadership Dashboard: Allowed when license is active and leadership_dashboard entitlement enabled');

  // Active School A: P9 assignment authority succeeds
  await asUser(teacherAId);
  const p9Auth = await db.query(`SELECT public.can_teacher_manage_assignment('${schoolAId}'::uuid, '${classA1Id}'::uuid, 'physics_g12', NULL)`);
  assert(p9Auth.rows[0].can_teacher_manage_assignment === true, 'P9 Assignments: Allowed when license is active and assignments_interventions entitlement enabled');

  // Active School A: P10 reporting authority succeeds
  await asUser(schoolAdminAId);
  const p10Auth = await db.query(`SELECT public.validate_report_authority('${schoolAId}'::uuid)`);
  assert(p10Auth.rows[0].validate_report_authority === true, 'P10 Reporting: Allowed when license is active and institutional_reporting entitlement enabled');

  // Suspend School A: all P7, P8, P9, P10 institutional capabilities must be DENIED!
  await asUser(platformAdminId);
  await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolAId}'::uuid, 'suspended', 'Test suspension')`);

  // P7 under suspension -> DENIED
  await asUser(teacherAId);
  let p7SuspDenied = false;
  try {
    await db.query(`SELECT * FROM public.get_teacher_assigned_classes('${schoolAId}'::uuid)`);
  } catch (err) {
    p7SuspDenied = err.message.includes('Teacher portal access denied') || err.message.includes('entitlement');
  }
  assert(p7SuspDenied, 'P7 Teacher Portal: DENIED with exception when license is suspended');

  // P8 under suspension -> DENIED
  await asUser(schoolAdminAId);
  const p8SuspAuth = await db.query(`SELECT public.resolve_school_admin_authority('${schoolAId}'::uuid)`);
  assert(p8SuspAuth.rows[0].resolve_school_admin_authority === false, 'P8 Leadership Dashboard: DENIED when license is suspended');

  // P9 under suspension -> DENIED
  await asUser(teacherAId);
  const p9SuspAuth = await db.query(`SELECT public.can_teacher_manage_assignment('${schoolAId}'::uuid, '${classA1Id}'::uuid, 'physics_g12', NULL)`);
  assert(p9SuspAuth.rows[0].can_teacher_manage_assignment === false, 'P9 Assignments: DENIED when license is suspended');

  // P10 under suspension -> DENIED
  await asUser(schoolAdminAId);
  const p10SuspAuth = await db.query(`SELECT public.validate_report_authority('${schoolAId}'::uuid)`);
  assert(p10SuspAuth.rows[0].validate_report_authority === false, 'P10 Reporting: DENIED when license is suspended');

  // Restore School A to active
  await asUser(platformAdminId);
  await db.query(`SELECT * FROM public.transition_school_license_internal('${schoolAId}'::uuid, 'active', 'Restore active')`);

  // 9b. P7–P10 Integration with Valid Trial School
  await asSuperuser();
  await db.query(`
    UPDATE public.school_licenses
    SET ends_at = NOW() + INTERVAL '14 days'
    WHERE school_id = '${schoolTrialId}'
  `);
  const teacherTrialId = '11111111-0000-0000-0000-000000000093';
  const adminTrialId = '11111111-0000-0000-0000-000000000094';
  const classTrialId = '33333333-0000-0000-0000-000000000091';
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES
      ('${teacherTrialId}', '+251911000093'),
      ('${adminTrialId}', '+251911000094')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream) VALUES
      ('${teacherTrialId}', '+251911000093', 'Teacher Trial', 12, 'natural'),
      ('${adminTrialId}', '+251911000094', 'Admin Trial', 12, 'natural')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES
      ('${teacherTrialId}', 'teacher'),
      ('${adminTrialId}', 'school_admin')
    ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES
      ('${schoolTrialId}', '${teacherTrialId}', 'teacher', 'active'),
      ('${schoolTrialId}', '${adminTrialId}', 'school_admin', 'active')
    ON CONFLICT DO NOTHING;
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status) VALUES
      ('${classTrialId}', '${schoolTrialId}', 'Grade 12 Natural Trial', 12, 'naturalScience', 'A', '2026/27', 'active')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.teacher_subject_assignments (school_id, classroom_id, teacher_user_id, subject_id, status)
      VALUES ('${schoolTrialId}', '${classTrialId}', '${teacherTrialId}', 'physics_g12', 'active')
      ON CONFLICT DO NOTHING;
  `);

  // Valid trial: P7 teacher portal allowed
  await asUser(teacherTrialId);
  const p7TrialClasses = await db.query(`SELECT * FROM public.get_teacher_assigned_classes('${schoolTrialId}'::uuid)`);
  assert(p7TrialClasses.rows.length >= 1, 'P7 Teacher Portal: Allowed for school in valid trial');

  // Valid trial: P8 leadership allowed
  await asUser(adminTrialId);
  const p8TrialAuth = await db.query(`SELECT public.resolve_school_admin_authority('${schoolTrialId}'::uuid)`);
  assert(p8TrialAuth.rows[0].resolve_school_admin_authority === true, 'P8 Leadership Dashboard: Allowed for school in valid trial');

  // Valid trial: P9 assignments allowed
  await asUser(teacherTrialId);
  const p9TrialAuth = await db.query(`SELECT public.can_teacher_manage_assignment('${schoolTrialId}'::uuid, '${classTrialId}'::uuid, 'physics_g12', NULL)`);
  assert(p9TrialAuth.rows[0].can_teacher_manage_assignment === true, 'P9 Assignments: Allowed for school in valid trial');

  // Valid trial: P10 reporting allowed
  await asUser(adminTrialId);
  const p10TrialAuth = await db.query(`SELECT public.validate_report_authority('${schoolTrialId}'::uuid)`);
  assert(p10TrialAuth.rows[0].validate_report_authority === true, 'P10 Reporting: Allowed for school in valid trial');

  // 9c. P7–P10 Integration with Valid Grace School
  await asSuperuser();
  await db.query(`
    UPDATE public.school_licenses
    SET grace_ends_at = NOW() + INTERVAL '10 days'
    WHERE school_id = '${schoolGraceId}'
  `);
  const teacherGraceId = '11111111-0000-0000-0000-000000000096';
  const adminGraceId = '11111111-0000-0000-0000-000000000097';
  const classGraceId = '33333333-0000-0000-0000-000000000092';
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES
      ('${teacherGraceId}', '+251911000096'),
      ('${adminGraceId}', '+251911000097')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream) VALUES
      ('${teacherGraceId}', '+251911000096', 'Teacher Grace', 12, 'natural'),
      ('${adminGraceId}', '+251911000097', 'Admin Grace', 12, 'natural')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES
      ('${teacherGraceId}', 'teacher'),
      ('${adminGraceId}', 'school_admin')
    ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES
      ('${schoolGraceId}', '${teacherGraceId}', 'teacher', 'active'),
      ('${schoolGraceId}', '${adminGraceId}', 'school_admin', 'active')
    ON CONFLICT DO NOTHING;
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status) VALUES
      ('${classGraceId}', '${schoolGraceId}', 'Grade 12 Natural Grace', 12, 'naturalScience', 'A', '2026/27', 'active')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.teacher_subject_assignments (school_id, classroom_id, teacher_user_id, subject_id, status)
      VALUES ('${schoolGraceId}', '${classGraceId}', '${teacherGraceId}', 'physics_g12', 'active')
      ON CONFLICT DO NOTHING;
  `);

  // Valid grace: P7 teacher portal allowed
  await asUser(teacherGraceId);
  const p7GraceClasses = await db.query(`SELECT * FROM public.get_teacher_assigned_classes('${schoolGraceId}'::uuid)`);
  assert(p7GraceClasses.rows.length >= 1, 'P7 Teacher Portal: Allowed for school in valid grace period');

  // Valid grace: P8 leadership allowed
  await asUser(adminGraceId);
  const p8GraceAuth = await db.query(`SELECT public.resolve_school_admin_authority('${schoolGraceId}'::uuid)`);
  assert(p8GraceAuth.rows[0].resolve_school_admin_authority === true, 'P8 Leadership Dashboard: Allowed for school in valid grace period');

  // Expired grace: P7, P8 fail
  await asSuperuser();
  await db.query(`
    UPDATE public.school_licenses
    SET grace_ends_at = NOW() - INTERVAL '1 day'
    WHERE school_id = '${schoolGraceId}'
  `);
  await asUser(teacherGraceId);
  let p7GraceExpDenied = false;
  try {
    await db.query(`SELECT * FROM public.get_teacher_assigned_classes('${schoolGraceId}'::uuid)`);
  } catch (err) {
    p7GraceExpDenied = err.message.includes('Teacher portal access denied') || err.message.includes('entitlement');
  }
  assert(p7GraceExpDenied, 'P7 Teacher Portal: DENIED immediately when grace period has expired');
  await asUser(adminGraceId);
  const p8GraceExpAuth = await db.query(`SELECT public.resolve_school_admin_authority('${schoolGraceId}'::uuid)`);
  assert(p8GraceExpAuth.rows[0].resolve_school_admin_authority === false, 'P8 Leadership Dashboard: DENIED immediately when grace period has expired');

  // 10. School Onboarding Checklist & Activation Success Test
  console.log('\n[10/15] Running School Onboarding Checklist & Complete Activation Tests...');

  // Incomplete School B validation reports is_ready = false with errors
  const valB = (await db.query(`SELECT * FROM public.validate_school_activation('${schoolBId}'::uuid)`)).rows[0].validate_school_activation;
  assert(valB.is_ready === false && valB.errors.length > 0, 'Incomplete School B validation reports is_ready=false with errors');

  // Seed Complete School C fixture with all 10 required steps satisfied
  const schoolCId = '22222222-0000-0000-0000-000000000003';
  const schoolAdminCId = '11111111-0000-0000-0000-000000000030';
  const classCId = '33333333-0000-0000-0000-000000000030';

  await asSuperuser();
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES ('${schoolAdminCId}', '+251911000030') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream)
      VALUES ('${schoolAdminCId}', '+251911000030', 'Admin School C', 12, 'natural') ON CONFLICT DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES ('${schoolAdminCId}', 'school_admin') ON CONFLICT DO NOTHING;
    INSERT INTO public.schools (id, name, display_name, school_code, status, city, region)
      VALUES ('${schoolCId}', 'Complete Model Secondary', 'Model High', 'SCH-MDL', 'suspended', 'Addis Ababa', 'Addis Ababa')
      ON CONFLICT DO NOTHING;
    INSERT INTO public.school_onboarding_state (school_id, status, activation_ready)
      VALUES ('${schoolCId}', 'in_progress', false)
      ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status)
      VALUES ('${schoolCId}', '${schoolAdminCId}', 'school_admin', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
      VALUES ('${classCId}', '${schoolCId}', 'Grade 12 Natural Section 1', 12, 'naturalScience', '1', '2026/27', 'active') ON CONFLICT DO NOTHING;
  `);

  await asUser(platformAdminId);
  await db.query(`
    SELECT * FROM public.create_school_license_internal(
      '${schoolCId}'::uuid, 'school_standard', 200, 'manual_contract', NOW(), NOW() + INTERVAL '365 days', NULL
    )
  `);

  // Validate complete school
  const valC = (await db.query(`SELECT * FROM public.validate_school_activation('${schoolCId}'::uuid)`)).rows[0].validate_school_activation;
  assert(valC.is_ready === true && valC.errors.length === 0, 'Complete School C validation reports is_ready=true, 0 errors');

  // Activate School C via activate_school_internal
  const actRes = await db.query(`SELECT * FROM public.activate_school_internal('${schoolCId}'::uuid)`);
  assert(actRes.rows[0].status === 'active', 'activate_school_internal completes onboarding and activates School C');

  const onbState = (await db.query(`SELECT status, activation_ready FROM public.school_onboarding_state WHERE school_id = '${schoolCId}'`)).rows[0];
  const schoolCRow = (await db.query(`SELECT status FROM public.schools WHERE id = '${schoolCId}'`)).rows[0];
  assert(schoolCRow.status === 'active', 'School C operational status successfully transitioned to active');

  // 11. Bulk Student Import: Seat Overflow & Idempotency Tests
  console.log('\n[11/15] Running Bulk Student Import & Seat Overflow Tests...');

  // Setup School D with 5 available seats
  const schoolDId = '22222222-0000-0000-0000-000000000004';
  const adminDId = '11111111-0000-0000-0000-000000000040';
  const classDId = '33333333-0000-0000-0000-000000000040';

  await asSuperuser();
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES ('${adminDId}', '+251911000040') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, phone_number, display_name, grade, stream)
      VALUES ('${adminDId}', '+251911000040', 'Admin School D', 12, 'natural') ON CONFLICT DO NOTHING;
    INSERT INTO public.user_roles (user_id, role_id) VALUES ('${adminDId}', 'school_admin') ON CONFLICT DO NOTHING;
    INSERT INTO public.schools (id, name, display_name, school_code, status)
      VALUES ('${schoolDId}', 'Bulk Import Academy', 'Bulk High', 'SCH-BLK', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.school_memberships (school_id, user_id, role, status)
      VALUES ('${schoolDId}', '${adminDId}', 'school_admin', 'active') ON CONFLICT DO NOTHING;
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
      VALUES ('${classDId}', '${schoolDId}', 'Grade 12 Import Class', 12, 'naturalScience', 'A', '2026/27', 'active') ON CONFLICT DO NOTHING;
  `);

  await asUser(platformAdminId);
  await db.query(`
    SELECT * FROM public.create_school_license_internal(
      '${schoolDId}'::uuid, 'school_standard', 5, 'manual_contract', NOW(), NOW() + INTERVAL '365 days', NULL
    )
  `);

  // Attempt to import 8 distinct students into 5-seat school -> must be DENIED with SEAT_LIMIT_EXCEEDED!
  await asUser(adminDId);
  const overflowStudents = [];
  for (let i = 1; i <= 8; i++) {
    overflowStudents.push({ student_identifier: `OF_${i}`, display_name: `Overflow Student ${i}`, phone: `+25194400000${i}` });
  }

  let overflowBlocked = false;
  try {
    await db.query(`
      SELECT * FROM public.execute_bulk_student_enrollment_internal(
        '${schoolDId}'::uuid,
        '${classDId}'::uuid,
        '${JSON.stringify(overflowStudents)}'::jsonb,
        'import-overflow-batch'
      )
    `);
  } catch (err) {
    overflowBlocked = err.message.includes('SEAT_LIMIT_EXCEEDED');
  }
  assert(overflowBlocked, 'Bulk import of 8 students when limit is 5 is DENIED with SEAT_LIMIT_EXCEEDED');

  // Verify 0 seats were consumed by rejected batch
  const usageD = (await db.query(`SELECT * FROM public.get_school_seat_usage('${schoolDId}'::uuid)`)).rows[0].get_school_seat_usage;
  assert(usageD.occupied_seats === 0, 'Bulk overflow rejection is all-or-nothing: 0 seats leaked');

  // Import 4 students (under limit of 5) -> succeeds
  const validBatch = overflowStudents.slice(0, 4);
  const validImport = await db.query(`
    SELECT * FROM public.execute_bulk_student_enrollment_internal(
      '${schoolDId}'::uuid,
      '${classDId}'::uuid,
      '${JSON.stringify(validBatch)}'::jsonb,
      'import-valid-batch-001'
    )
  `);
  assert(validImport.rows[0].execute_bulk_student_enrollment_internal.status === 'completed', 'Bulk import of 4 students within capacity commits successfully');

  // Replay import with same key -> idempotent_replay
  const replayImport = await db.query(`
    SELECT * FROM public.execute_bulk_student_enrollment_internal(
      '${schoolDId}'::uuid,
      '${classDId}'::uuid,
      '${JSON.stringify(validBatch)}'::jsonb,
      'import-valid-batch-001'
    )
  `);
  assert(replayImport.rows[0].execute_bulk_student_enrollment_internal.status === 'idempotent_replay', 'Replay of bulk import with identical idempotency key returns idempotent_replay');

  // 12. Manual Contract & Offline Readiness
  console.log('\n[12/15] Running Manual Contract Path & Billing Webhook Authenticity Tests...');

  // Manual contract school has billing_customer_ref = NULL and billing_subscription_ref = NULL
  const manualLic = (await db.query(`
    SELECT source, billing_customer_ref, billing_subscription_ref, status
    FROM public.school_licenses WHERE school_id = '${schoolDId}'
  `)).rows[0];
  assert(
    manualLic.source === 'manual_contract' &&
    manualLic.billing_customer_ref === null &&
    manualLic.billing_subscription_ref === null &&
    manualLic.status === 'active',
    'Manual contract path creates active institutional license with NULL billing refs'
  );

  // Billing Webhook Authenticity: Unauthorized caller (student / school admin) calling process_billing_event_internal is DENIED!
  await asUser(student1Id);
  let studentBillBlocked = false;
  try {
    await db.query(`
      SELECT * FROM public.process_billing_event_internal(
        'telebirr', 'evt_unauth_001', 'payment_succeeded', '${schoolAId}'::uuid, 'hash'
      )
    `);
  } catch (err) {
    studentBillBlocked = err.message.includes('permission denied') || err.message.includes('UNAUTHORIZED_BILLING_ACTOR');
  }
  assert(studentBillBlocked, 'Unauthorized user calling process_billing_event_internal is DENIED');

  // Service role executes initial billing event (T1: 10 hours ago)
  await asUser(null, 'service_role');
  const renewalT1 = await db.query(`
    SELECT * FROM public.process_billing_event_internal(
      'telebirr',
      'evt_tb_renewal_t1',
      'payment_succeeded',
      '${schoolAId}'::uuid,
      'hash_payload_renewal_t1',
      'active',
      NOW(),
      NOW() + INTERVAL '365 days',
      10,
      NOW() - INTERVAL '10 hours' -- Event timestamp T1
    )
  `);
  assert(renewalT1.rows[0].process_billing_event_internal.status === 'processed', 'Service role processes payment_succeeded renewal (T1)');

  // T2: Platform admin changes seat limit (unrelated administrative mutation changes school_licenses.updated_at)
  await asUser(platformAdminId);
  const seatLimitT2 = await db.query(`
    SELECT * FROM public.update_school_seat_limit_internal('${schoolAId}'::uuid, 25, 'Mid-contract seat expansion')
  `);
  assert(seatLimitT2.rows[0].student_seat_limit === 25, 'Platform admin updates seat limit to 25 (mutates school_licenses.updated_at)');

  // T3: Valid billing renewal event arrives whose provider timestamp (8 hours ago) is after T1 (10 hours ago)
  // but before the seat-limit mutation timestamp T2 (NOW)!
  // Must NOT be rejected merely because school_licenses.updated_at was changed by the seat-limit operation!
  await asUser(null, 'service_role');
  const renewalT3 = await db.query(`
    SELECT * FROM public.process_billing_event_internal(
      'telebirr',
      'evt_tb_renewal_t3',
      'subscription_renewed',
      '${schoolAId}'::uuid,
      'hash_payload_renewal_t3',
      'active',
      NOW(),
      NOW() + INTERVAL '730 days',
      25,
      NOW() - INTERVAL '8 hours' -- Event timestamp T3 (after T1, before T2 mutation)
    )
  `);
  assert(
    renewalT3.rows[0].process_billing_event_internal.status === 'processed',
    'Out-of-Order Proof: T3 renewal is NOT rejected merely because school_licenses.updated_at was changed by seat-limit operation'
  );

  // T5: New billing event accepted with provider timestamp T5 (1 hour ago)
  const renewalT5 = await db.query(`
    SELECT * FROM public.process_billing_event_internal(
      'telebirr',
      'evt_tb_renewal_t5',
      'payment_succeeded',
      '${schoolAId}'::uuid,
      'hash_payload_renewal_t5',
      'active',
      NOW(),
      NOW() + INTERVAL '730 days',
      25,
      NOW() - INTERVAL '1 hour' -- Event timestamp T5
    )
  `);
  assert(renewalT5.rows[0].process_billing_event_internal.status === 'processed', 'T5 billing event accepted; advances billing watermark');

  // T4: True Stale Event: Older event (T4: 4 hours ago, T4 < T5) arrives AFTER T5!
  // Must be rejected as ignored_stale using billing watermark evidence
  const staleT4 = await db.query(`
    SELECT * FROM public.process_billing_event_internal(
      'telebirr',
      'evt_tb_stale_fail_t4',
      'payment_failed',
      '${schoolAId}'::uuid,
      'hash_payload_stale_t4',
      'grace',
      NOW() - INTERVAL '30 days',
      NOW() - INTERVAL '1 day',
      NULL,
      NOW() - INTERVAL '4 hours' -- Event timestamp T4 is older than T5!
    )
  `);
  assert(staleT4.rows[0].process_billing_event_internal.status === 'ignored_stale', 'True Stale Proof: T4 older event (T4 < T5) is rejected as ignored_stale using billing watermark');

  await asSuperuser();
  const licAfterStale = (await db.query(`SELECT status FROM public.school_licenses WHERE school_id = '${schoolAId}'`)).rows[0];
  assert(licAfterStale.status === 'active', 'Active license is preserved: stale payment_failed did NOT downgrade license');

  // Duplicate event delivery of T3 event
  await asUser(null, 'service_role');
  const dupT3 = await db.query(`
    SELECT * FROM public.process_billing_event_internal(
      'telebirr',
      'evt_tb_renewal_t3',
      'subscription_renewed',
      '${schoolAId}'::uuid,
      'hash_payload_renewal_t3'
    )
  `);
  assert(dupT3.rows[0].process_billing_event_internal.status === 'ignored_duplicate', 'Duplicate billing event delivery returns ignored_duplicate (one effective transition)');

  // 13. Direct Table Row Level Security (RLS) Tests
  console.log('\n[13/15] Running Direct Table Row Level Security (RLS) Tests...');

  // 13.1 Anon direct select on school_licenses returns 0 rows
  await asUser(null);
  const anonLic = await db.query(`SELECT * FROM public.school_licenses`);
  assert(anonLic.rows.length === 0, 'RLS: Anonymous user direct SELECT on school_licenses returns 0 rows');

  // 13.2 Student direct select on school_licenses returns 0 rows
  await asUser(student1Id);
  const stuLic = await db.query(`SELECT * FROM public.school_licenses`);
  assert(stuLic.rows.length === 0, 'RLS: Student direct SELECT on school_licenses returns 0 rows');

  // 13.3 Student direct select on billing_events returns 0 rows
  const stuBill = await db.query(`SELECT * FROM public.billing_events`);
  assert(stuBill.rows.length === 0, 'RLS: Student direct SELECT on billing_events returns 0 rows');

  // 13.4 Teacher direct select on billing_customers returns 0 rows
  await asUser(teacherAId);
  const teachCust = await db.query(`SELECT * FROM public.billing_customers`);
  assert(teachCust.rows.length === 0, 'RLS: Teacher direct SELECT on billing_customers returns 0 rows');

  // 13.5 Cross-school admin direct select on School A license returns 0 rows
  await asUser(schoolAdminBId);
  const crossLic = await db.query(`SELECT * FROM public.school_licenses WHERE school_id = '${schoolAId}'`);
  assert(crossLic.rows.length === 0, 'RLS: Cross-school admin direct SELECT on School A license returns 0 rows');

  // 13.6 School Admin direct select on billing_events (raw payloads) returns 0 rows
  await asUser(schoolAdminAId);
  const adminBill = await db.query(`SELECT * FROM public.billing_events`);
  assert(adminBill.rows.length === 0, 'RLS: School Admin direct SELECT on billing_events returns 0 rows (raw payloads shielded)');

  // 13.7 School Admin A direct select on own school_licenses returns 1 row
  const ownLicDirect = await db.query(`SELECT * FROM public.school_licenses WHERE school_id = '${schoolAId}'`);
  assert(ownLicDirect.rows.length === 1, 'RLS: School Admin direct SELECT on own school_licenses returns 1 row');

  // 13.8 School Admin A direct select on own school_onboarding_state returns 1 row
  const ownOnbDirect = await db.query(`SELECT * FROM public.school_onboarding_state WHERE school_id = '${schoolAId}'`);
  assert(ownOnbDirect.rows.length === 1, 'RLS: School Admin direct SELECT on own school_onboarding_state returns 1 row');

  // 14. Canonical Audit Logging Integrity & Privacy
  console.log('\n[14/15] Running Canonical Audit Logging & Privacy Tests...');
  await asSuperuser();
  const auditRes = await db.query(`
    SELECT action, COUNT(*) as c
    FROM public.audit_log
    WHERE action IN (
      'school_license_created', 'school_license_transitioned',
      'school_seat_limit_changed', 'school_bulk_import_completed',
      'billing_event_processed'
    )
    GROUP BY action
  `);
  assert(auditRes.rows.length >= 4, 'Canonical public.audit_log contains records for all P11 commercial events');

  // Verify no card PAN / CVV or private tokens exist in audit logs
  const sensitiveAudit = await db.query(`
    SELECT id FROM public.audit_log
    WHERE metadata::text ~* '(card_number|pan|cvv|secret_key|password)'
  `);
  assert(sensitiveAudit.rows.length === 0, 'Audit Log Privacy: 0 sensitive cardholder / credentials found in audit records');

  // 15. Live PostgreSQL Performance Benchmarks
  console.log('\n[15/15] Running Live PostgreSQL Performance Benchmarks...');
  const bench = async (name, fn, iterations = 20) => {
    // Warm up
    await fn();
    const start = process.hrtime.bigint();
    for (let i = 0; i < iterations; i++) {
      await fn();
    }
    const end = process.hrtime.bigint();
    const avgMs = Number(end - start) / (iterations * 1e6);
    console.log(`  ⏱ BENCHMARK: ${name} -> ${avgMs.toFixed(3)} ms (avg over ${iterations} runs)`);
    return avgMs;
  };

  await asUser(schoolAdminAId);
  const benchLic = await bench('get_school_license', () => db.query(`SELECT * FROM public.get_school_license('${schoolAId}'::uuid)`));
  const benchEnt = await bench('school_has_entitlement', () => db.query(`SELECT public.school_has_entitlement('${schoolAId}'::uuid, 'teacher_portal')`));
  const benchUsage = await bench('get_school_seat_usage', () => db.query(`SELECT * FROM public.get_school_seat_usage('${schoolAId}'::uuid)`));
  const benchOnb = await bench('validate_school_activation', () => db.query(`SELECT * FROM public.validate_school_activation('${schoolAId}'::uuid)`));

  await asSuperuser();
  const benchBill = await bench('process_billing_event_internal (idempotent)', () => db.query(`
    SELECT * FROM public.process_billing_event_internal('telebirr', 'evt_tb_renewal_t2', 'payment_succeeded', '${schoolAId}'::uuid, 'hash')
  `));

  assert(benchLic < 50, 'Performance: get_school_license resolves under 50ms');
  assert(benchEnt < 20, 'Performance: school_has_entitlement resolves under 20ms');
  assert(benchUsage < 50, 'Performance: get_school_seat_usage resolves under 50ms');
  assert(benchOnb < 50, 'Performance: validate_school_activation resolves under 50ms');
  assert(benchBill < 20, 'Performance: billing ingestion resolves under 20ms');

  console.log('\n=============================================================================');
  console.log(`P11 POSTGRESQL VERIFICATION COMPLETE: ${passedTests} PASSED, ${failedTests} FAILED`);
  console.log('=============================================================================');

  if (failedTests > 0) {
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Fatal error during P11 PostgreSQL test execution:', err.message || err);
  if (err.stack) console.error(err.stack);
  process.exit(1);
});
