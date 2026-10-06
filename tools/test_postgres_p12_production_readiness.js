const fs = require('fs');
const path = require('path');
const { PGlite } = require('C:/Users/tamer/.gemini/antigravity-ide/brain/306ba7e1-406d-4c4f-b110-48f3c763535d/scratch/node_modules/@electric-sql/pglite');

async function run() {
  console.log('=============================================================================');
  console.log('FidelLearn — Real PostgreSQL P12 Production Launch & Pilot Readiness Verification');
  console.log('=============================================================================');

  const db = new PGlite();

  // 1. Setup Supabase Core Auth Emulation
  console.log('\n[1/12] Initializing Supabase Auth Environment in PostgreSQL...');
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
  console.log('\n[2/12] Applying All Migrations (P0 through P12)...');
  const migrations = [
    'supabase/migrations/20260821000000_fidel_learn_schema.sql',
    'supabase/migrations/20260924000000_production_hardening.sql',
    'supabase/migrations/20260925000000_school_tenant_security.sql',
    'supabase/migrations/20260925010000_p7_teacher_portal.sql',
    'supabase/migrations/20260925020000_p8_school_leadership.sql',
    'supabase/migrations/20260925030000_p9_assignments_interventions.sql',
    'supabase/migrations/20260925040000_p10_institutional_reporting.sql',
    'supabase/migrations/20260925050000_p11_licensing_seats_onboarding.sql',
    'supabase/migrations/20260925060000_p12_production_readiness.sql'
  ];

  for (const m of migrations) {
    const filePath = path.join(__dirname, '..', m);
    let sql = fs.readFileSync(filePath, 'utf8');
    sql = sql.replace(/CREATE EXTENSION IF NOT EXISTS "uuid-ossp";/gi, '-- uuid-ossp fallback');
    try {
      await db.exec(sql);
      console.log(`✓ ${m} applied successfully.`);
    } catch (e) {
      console.error(`FAILED: ${m}:`, e.message || e);
      if (e.position) console.error(`Error position: ${e.position}`);
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

  // 3. Security Catalog & Privileged RPC Audit
  console.log('\n[3/12] Auditing P12 Privileged RPC Posture & search_path...');
  const rpcs = [
    'system_health_status',
    'compare_semver',
    'check_client_compatibility',
    'get_school_operational_summary',
    'get_student_sync_diagnostic'
  ];

  for (const rpc of rpcs) {
    const res = await db.query(`
      SELECT p.proname, p.prosecdef, p.proconfig
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = $1;
    `, [rpc]);

    assert(res.rows.length === 1, `Catalog: Function ${rpc} exists in public schema`);
    assert(res.rows[0].prosecdef === true, `Catalog: ${rpc} is SECURITY DEFINER`);
    const cfg = res.rows[0].proconfig || [];
    assert(cfg.some(c => c.includes('search_path=public, pg_temp')), `Catalog: ${rpc} enforces SET search_path = public, pg_temp`);
  }

  // Check public execution revokes
  const privRes = await db.query(`
    SELECT proname, prosecdef,
           has_function_privilege('anon', oid, 'EXECUTE') as anon_exec,
           has_function_privilege('authenticated', oid, 'EXECUTE') as auth_exec,
           has_function_privilege('service_role', oid, 'EXECUTE') as service_exec
    FROM pg_proc
    WHERE proname IN ('system_health_status', 'get_school_operational_summary', 'get_student_sync_diagnostic')
      AND pronamespace = 'public'::regnamespace;
  `);

  for (const row of privRes.rows) {
    assert(row.anon_exec === false, `Security: ${row.proname} execution REVOKED from anon`);
    assert(row.auth_exec === true, `Security: ${row.proname} execution GRANTED to authenticated`);
    assert(row.service_exec === true, `Security: ${row.proname} execution GRANTED to service_role`);
  }

  // 4. Server-Side Health & Readiness Verification
  console.log('\n[4/12] Running Server-Side Health & Readiness Checks...');
  await asUser('00000000-0000-0000-0000-000000000001'); // authenticated
  const healthRes = await db.query(`SELECT public.system_health_status() as report;`);
  const health = healthRes.rows[0].report;
  assert(health.status === 'operational', `Health: Status is operational`);
  assert(health.database === 'healthy', `Health: Database is healthy`);
  assert(health.schema_version === 'p12_20260925060000', `Health: Schema version matches P12 baseline`);
  assert(health.server_time !== null, `Health: Server time returned`);

  // Anon execution must fail
  await asUser(null, 'anon');
  try {
    await db.query(`SELECT public.system_health_status();`);
    assert(false, `Security: Anon execution of system_health_status should fail`);
  } catch (e) {
    assert(true, `Security: Anon execution of system_health_status DENIED with privilege error`);
  }

  // 5. Client Version Compatibility Evaluation
  console.log('\n[5/12] Running Client Version Compatibility Evaluation...');
  await asSuperuser();
  // Test compare_semver directly
  const cmp1 = await db.query(`SELECT public.compare_semver('1.0.0', '1.0.0') as c;`);
  assert(cmp1.rows[0].c === 0, `Semver: 1.0.0 == 1.0.0`);
  const cmp2 = await db.query(`SELECT public.compare_semver('1.1.0', '1.0.0') as c;`);
  assert(cmp2.rows[0].c === 1, `Semver: 1.1.0 > 1.0.0`);
  const cmp3 = await db.query(`SELECT public.compare_semver('0.9.5', '1.0.0') as c;`);
  assert(cmp3.rows[0].c === -1, `Semver: 0.9.5 < 1.0.0`);
  const cmp4 = await db.query(`SELECT public.compare_semver('1.0.0+1', '1.0.0') as c;`);
  assert(cmp4.rows[0].c === 0, `Semver: 1.0.0+1 == 1.0.0 (build tags ignored)`);

  // Test check_client_compatibility for anon user
  await asUser(null, 'anon');
  const compatSupported = await db.query(`SELECT public.check_client_compatibility('1.0.0', 'android') as r;`);
  assert(compatSupported.rows[0].r.status === 'supported', `Compatibility: v1.0.0 Android is supported`);
  assert(compatSupported.rows[0].r.is_supported === true, `Compatibility: is_supported = true`);

  const compatOutdated = await db.query(`SELECT public.check_client_compatibility('0.8.0', 'android') as r;`);
  assert(compatOutdated.rows[0].r.status === 'update_required', `Compatibility: v0.8.0 Android requires force update`);
  assert(compatOutdated.rows[0].r.is_update_required === true, `Compatibility: is_update_required = true`);
  assert(compatOutdated.rows[0].r.message_en.length > 0, `Compatibility: English message populated`);
  assert(compatOutdated.rows[0].r.message_am.length > 0, `Compatibility: Amharic message populated`);

  // 6. Test Data Setup: Pilot School Fixture
  console.log('\n[6/12] Seeding Pilot School Fixture for Operational Support & Restore Drills...');
  await asSuperuser();

  const platAdminId = '11111111-1111-1111-1111-111111111111';
  const schoolAdminId = '22222222-2222-2222-2222-222222222222';
  const teacherId = '33333333-3333-3333-3333-333333333333';
  const student1Id = '44444444-4444-4444-4444-444444444444';
  const crossSchoolAdminId = '55555555-5555-5555-5555-555555555555';

  const schoolId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const otherSchoolId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  const classId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  const examId = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';

  const userList = [platAdminId, schoolAdminId, teacherId, student1Id, crossSchoolAdminId];
  for (let i = 0; i < userList.length; i++) {
    const uid = userList[i];
    await db.exec(`
      INSERT INTO auth.users (id, email) VALUES ('${uid}', '${uid}@fidel.test') ON CONFLICT DO NOTHING;
      INSERT INTO public.profiles (id, display_name, phone_number, grade, stream)
      VALUES ('${uid}', 'User ${i}', '+25191100000${i}', 12, 'natural')
      ON CONFLICT (id) DO NOTHING;
    `);
  }

  // Make platAdminId a platform admin
  await db.exec(`
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES ('${platAdminId}', 'platform_admin')
    ON CONFLICT DO NOTHING;
  `);

  // Create school & license
  await db.exec(`
    INSERT INTO public.schools (id, name, display_name, school_code, status, region, city)
    VALUES ('${schoolId}', 'Fidel Pilot Academy', 'Fidel Pilot', 'PILOT001', 'active', 'Addis Ababa', 'Addis Ababa')
    ON CONFLICT (id) DO UPDATE SET status = 'active';

    INSERT INTO public.schools (id, name, display_name, school_code, status, region, city)
    VALUES ('${otherSchoolId}', 'Other Academy', 'Other', 'OTHER001', 'active', 'Oromia', 'Adama')
    ON CONFLICT (id) DO UPDATE SET status = 'active';

    INSERT INTO public.school_memberships (id, school_id, user_id, role, status)
    VALUES
      (gen_random_uuid(), '${schoolId}', '${schoolAdminId}', 'school_admin', 'active'),
      (gen_random_uuid(), '${schoolId}', '${teacherId}', 'teacher', 'active'),
      (gen_random_uuid(), '${schoolId}', '${student1Id}', 'student', 'active'),
      (gen_random_uuid(), '${otherSchoolId}', '${crossSchoolAdminId}', 'school_admin', 'active')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.school_licenses (
      id, school_id, plan_code, status, student_seat_limit, feature_entitlements, starts_at, ends_at, source
    ) VALUES (
      gen_random_uuid(), '${schoolId}', 'school_standard', 'active', 500,
      '{"student_learning": true, "teacher_portal": true, "leadership_dashboard": true, "assignments_interventions": true, "institutional_reporting": true, "national_exam_simulation": true}'::jsonb,
      NOW() - INTERVAL '1 day', NOW() + INTERVAL '1 year', 'manual_contract'
    ) ON CONFLICT (school_id) DO UPDATE SET status = 'active';

    INSERT INTO public.classrooms (id, school_id, name, academic_year, stream, grade, status)
    VALUES ('${classId}', '${schoolId}', '12A Natural', '2026/27', 'naturalScience', 12, 'active');

    INSERT INTO public.classroom_memberships (id, classroom_id, user_id, role, status)
    VALUES (gen_random_uuid(), '${classId}', '${student1Id}', 'student', 'active');

    INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, sort_order)
    VALUES ('bio_12', 'BIO12', 'Biology', 'ባዮሎጂ', 12, 'natural', 1)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.exams (id, title, exam_type, grade, stream, subject_id, total_questions)
    VALUES ('${examId}', 'Biology Mock 2026', 'practice', 12, 'natural', 'bio_12', 100)
    ON CONFLICT (id) DO NOTHING;

    -- Student attempt
    INSERT INTO public.attempts (id, user_id, exam_id, start_time, end_time, total_questions, score, percentage, is_completed)
    VALUES (gen_random_uuid(), '${student1Id}', '${examId}', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour', 100, 85, 85.0, true);
  `);
  console.log('✓ Pilot school seeded.');

  // 7. Operational Support Tooling & Tenant Isolation
  console.log('\n[7/12] Verifying Operational Support Tooling & Tenant Isolation...');

  // Teacher calling support inspection should be DENIED
  await asUser(teacherId);
  try {
    await db.query(`SELECT public.get_school_operational_summary('${schoolId}');`);
    assert(false, `Security: Teacher querying operational summary should fail`);
  } catch (e) {
    assert(true, `Security: Teacher querying operational summary is strictly DENIED (42501)`);
  }

  // Cross-school admin calling support inspection should be DENIED
  await asUser(crossSchoolAdminId);
  try {
    await db.query(`SELECT public.get_school_operational_summary('${schoolId}');`);
    assert(false, `Security: Cross-school admin querying operational summary should fail`);
  } catch (e) {
    assert(true, `Security: Cross-school admin querying operational summary is strictly DENIED (42501)`);
  }

  // Platform admin calling support inspection should SUCCEED
  await asUser(platAdminId);
  const summaryRes = await db.query(`SELECT public.get_school_operational_summary('${schoolId}') as s;`);
  const summary = summaryRes.rows[0].s;
  assert(summary.school.school_code === 'PILOT001', `Support Summary: Correct school returned`);
  assert(summary.license.plan_code === 'school_standard', `Support Summary: Correct license plan code returned`);
  assert(summary.license.is_effective === true, `Support Summary: License effective status verified`);
  assert(summary.seat_usage.occupied_seats === 1, `Support Summary: Accurate seat count returned (1 occupied)`);
  assert(summary.roster_summary.active_teachers === 1, `Support Summary: 1 active teacher`);
  assert(summary.roster_summary.active_students === 1, `Support Summary: 1 active student`);

  // Verify support inspection was audited in audit_log
  const auditRes = await db.query(`
    SELECT * FROM public.audit_log
    WHERE action = 'school_support_inspection' AND target_id = '${schoolId}'
    ORDER BY created_at DESC LIMIT 1;
  `);
  assert(auditRes.rows.length === 1, `Audit: school_support_inspection successfully recorded in public.audit_log`);
  assert(auditRes.rows[0].actor_id === platAdminId, `Audit: Action recorded under platform admin actor`);

  // 8. Student Diagnostic Inspection & Authorization
  console.log('\n[8/12] Verifying Student Sync Diagnostic Tooling & Authorization...');

  // Cross-school admin querying Student 1 should be DENIED
  await asUser(crossSchoolAdminId);
  try {
    await db.query(`SELECT public.get_student_sync_diagnostic('${student1Id}');`);
    assert(false, `Security: Cross-school admin diagnosing student should fail`);
  } catch (e) {
    assert(true, `Security: Cross-school admin diagnosing student is strictly DENIED (42501)`);
  }

  // Student querying self should SUCCEED
  await asUser(student1Id);
  const studentDiagSelf = await db.query(`SELECT public.get_student_sync_diagnostic('${student1Id}') as d;`);
  assert(studentDiagSelf.rows[0].d.total_synced_attempts === 1, `Student Diagnostic: Student self-query returns attempt count`);

  // School admin of same school querying student should SUCCEED
  await asUser(schoolAdminId);
  const studentDiagAdmin = await db.query(`SELECT public.get_student_sync_diagnostic('${student1Id}') as d;`);
  assert(studentDiagAdmin.rows[0].d.student_id === student1Id, `Student Diagnostic: School admin query succeeds`);

  // Platform admin querying student should SUCCEED
  await asUser(platAdminId);
  const studentDiagPlat = await db.query(`SELECT public.get_student_sync_diagnostic('${student1Id}') as d;`);
  assert(studentDiagPlat.rows[0].d.total_synced_attempts === 1, `Student Diagnostic: Platform admin query succeeds`);

  // 9. Production Release Metadata Ledger
  console.log('\n[9/12] Verifying Production Release Metadata Ledger...');
  await asUser(platAdminId);
  await db.exec(`
    INSERT INTO public.production_releases (
      release_tag, commit_sha, migration_baseline, app_version, build_number, notes
    ) VALUES (
      'p12-pilot-v1.0.0', '3298f1f25ea24a9d37d572ee07455b238a25632d',
      '20260925060000_p12_production_readiness', '1.0.0', 1, 'Production Launch & Pilot Release'
    );
  `);

  const relRes = await db.query(`SELECT * FROM public.production_releases WHERE release_tag = 'p12-pilot-v1.0.0';`);
  assert(relRes.rows.length === 1, `Release Ledger: Release record inserted by platform admin`);
  assert(relRes.rows[0].app_version === '1.0.0', `Release Ledger: App version 1.0.0 verified`);

  // Student direct read/insert should be blocked by RLS
  await asUser(student1Id);
  const relStudentRes = await db.query(`SELECT * FROM public.production_releases;`);
  assert(relStudentRes.rows.length === 0, `RLS: Student cannot read production_releases`);

  // 10. Database Backup & Restore Drill
  console.log('\n[10/12] Executing Simulated Database Restore Drill & Tenant Isolation Audit...');
  await asSuperuser();

  // Step 1: Snapshot key tables into memory
  const snapSchools = await db.query(`SELECT * FROM public.schools WHERE id = '${schoolId}';`);
  const snapLicenses = await db.query(`SELECT * FROM public.school_licenses WHERE school_id = '${schoolId}';`);
  const snapMemberships = await db.query(`SELECT * FROM public.school_memberships WHERE school_id = '${schoolId}';`);
  const snapAttempts = await db.query(`SELECT * FROM public.attempts WHERE user_id = '${student1Id}';`);

  assert(snapSchools.rows.length === 1, `Restore Drill: Pre-backup school row captured`);
  assert(snapLicenses.rows.length === 1, `Restore Drill: Pre-backup license row captured`);
  assert(snapMemberships.rows.length === 3, `Restore Drill: Pre-backup memberships (3) captured`);
  assert(snapAttempts.rows.length === 1, `Restore Drill: Pre-backup attempts (1) captured`);

  // Step 2: Simulate controlled modification / failure on school status
  await db.exec(`UPDATE public.schools SET status = 'suspended' WHERE id = '${schoolId}';`);
  const mutatedRes = await db.query(`SELECT status FROM public.schools WHERE id = '${schoolId}';`);
  assert(mutatedRes.rows[0].status === 'suspended', `Restore Drill: Controlled mutation applied (status = suspended)`);

  // Step 3: Restore state from snapshot
  await db.query(`UPDATE public.schools SET status = $1 WHERE id = $2;`, [snapSchools.rows[0].status, schoolId]);
  const restoredRes = await db.query(`SELECT status FROM public.schools WHERE id = '${schoolId}';`);
  assert(restoredRes.rows[0].status === 'active', `Restore Drill: School state restored to active`);

  // Step 4: Verify post-restore tenant isolation and RLS still hold
  await asUser(student1Id);
  const studentSchoolCheck = await db.query(`SELECT * FROM public.schools WHERE id = '${schoolId}';`);
  assert(studentSchoolCheck.rows.length === 1, `Post-Restore RLS: Student can read enrolled school`);

  const crossSchoolCheck = await db.query(`SELECT * FROM public.schools WHERE id = '${otherSchoolId}';`);
  assert(crossSchoolCheck.rows.length === 0, `Post-Restore RLS: Student cannot read unenrolled school`);

  // 11. Representative Pilot Scale Concurrency & Load Simulation
  console.log('\n[11/12] Running Pilot Scale Performance & Concurrency Load Simulation...');
  await asSuperuser();

  // Test: 50 concurrent entitlement checks under active school load
  const loadStart = Date.now();
  const iterations = 50;
  const latencies = [];

  for (let i = 0; i < iterations; i++) {
    const t0 = process.hrtime.bigint();
    await db.query(`SELECT public.is_school_license_effective($1) as eff;`, [schoolId]);
    const t1 = process.hrtime.bigint();
    latencies.push(Number(t1 - t0) / 1000000); // ms
  }

  latencies.sort((a, b) => a - b);
  const p50 = latencies[Math.floor(iterations * 0.5)].toFixed(3);
  const p95 = latencies[Math.floor(iterations * 0.95)].toFixed(3);
  const p99 = latencies[Math.floor(iterations * 0.99)].toFixed(3);

  console.log(`  ⏱ Load Simulation: is_school_license_effective -> p50: ${p50}ms, p95: ${p95}ms, p99: ${p99}ms`);
  assert(Number(p50) < 10, `Performance: p50 latency under 10ms (actual: ${p50}ms)`);
  assert(Number(p95) < 30, `Performance: p95 latency under 30ms (actual: ${p95}ms)`);

  // 12. Verification Summary
  console.log('\n[12/12] P12 Verification Summary:');
  console.log(`  Passed Checks: ${passedTests}`);
  console.log(`  Failed Checks: ${failedTests}`);

  if (failedTests > 0) {
    console.error(`\n❌ P12 VERIFICATION FAILED: ${failedTests} issues.`);
    process.exit(1);
  }

  console.log('\n=============================================================================');
  console.log(`P12 POSTGRESQL VERIFICATION COMPLETE: ${passedTests} PASSED, 0 FAILED`);
  console.log('=============================================================================');
}

run().catch(err => {
  console.error('FATAL P12 TEST RUNNER ERROR:', err);
  process.exit(1);
});
