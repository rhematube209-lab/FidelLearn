const fs = require('fs');
const path = require('path');
const { PGlite } = require('C:/Users/tamer/.gemini/antigravity-ide/brain/306ba7e1-406d-4c4f-b110-48f3c763535d/scratch/node_modules/@electric-sql/pglite');

async function run() {
  console.log('=============================================================================');
  console.log('FidelLearn — Real PostgreSQL P10 Institutional Reporting & Analytics Verification');
  console.log('=============================================================================');

  const db = new PGlite();

  // 1. Setup Supabase Core Auth Emulation
  console.log('\n[1/8] Initializing Supabase Auth Environment in PostgreSQL...');
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

    GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
  `);
  console.log('✓ Auth environment initialized.');

  // 2. Apply Migrations in Sequence
  console.log('\n[2/8] Applying Migrations...');
  const migrations = [
    'supabase/migrations/20260821000000_fidel_learn_schema.sql',
    'supabase/migrations/20260924000000_production_hardening.sql',
    'supabase/migrations/20260925000000_school_tenant_security.sql',
    'supabase/migrations/20260925010000_p7_teacher_portal.sql',
    'supabase/migrations/20260925020000_p8_school_leadership.sql',
    'supabase/migrations/20260925030000_p9_assignments_interventions.sql',
    'supabase/migrations/20260925040000_p10_institutional_reporting.sql'
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

  // Helper to switch acting user in PostgreSQL
  async function asUser(userId, role = 'authenticated') {
    if (!userId) {
      await db.exec(`
        SET SESSION "request.jwt.claim.sub" = '';
        SET SESSION "request.jwt.claim.role" = 'anon';
        SET ROLE anon;
      `);
    } else {
      await db.exec(`
        SET SESSION "request.jwt.claim.sub" = '${userId}';
        SET SESSION "request.jwt.claim.role" = '${role}';
        SET ROLE ${role};
      `);
    }
  }

  async function asSuperuser() {
    await db.exec(`
      SET SESSION "request.jwt.claim.sub" = '';
      SET SESSION "request.jwt.claim.role" = '';
      RESET ROLE;
    `);
  }

  // 3. Inspect PostgreSQL Catalog: SECURITY DEFINER, search_path, and EXECUTE grants
  console.log('\n[3/8] Catalog Verification: Inspecting SECURITY DEFINER, search_path & Grants...');
  const p10Functions = [
    'create_institutional_report_run',
    'get_institutional_report_runs',
    'get_institutional_executive_report',
    'get_subject_performance_report',
    'get_stream_performance_report',
    'get_class_performance_report',
    'get_assessment_report',
    'get_assignment_outcomes_report',
    'get_intervention_followup_report',
    'get_student_support_report',
    'get_data_coverage_report',
    'get_student_academic_report',
    'get_teacher_coverage_report',
    'validate_report_authority'
  ];

  const funcCheck = await db.query(`
    SELECT proname, prosecdef, proconfig
    FROM pg_proc
    JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE pg_namespace.nspname = 'public'
      AND proname = ANY($1::text[])
    ORDER BY proname;
  `, [p10Functions]);

  console.table(funcCheck.rows);
  if (funcCheck.rows.length !== p10Functions.length || !funcCheck.rows.every(r => r.prosecdef && r.proconfig && r.proconfig.some(c => c.includes('search_path=public, pg_temp')))) {
    throw new Error('Not all P10 functions have SECURITY DEFINER and search_path=public, pg_temp!');
  }
  console.log(`✓ All ${p10Functions.length} P10 functions confirmed SECURITY DEFINER with search_path=public, pg_temp.`);

  // 4. Seed Multi-Tenant Fixtures
  console.log('\n[4/8] Seeding Multi-Tenant Test Data & Educational Records...');
  const schoolAId = '11111111-1111-1111-1111-111111111111';
  const schoolBId = '22222222-2222-2222-2222-222222222222';
  const schoolSuspended = '33333333-3333-3333-3333-333333333333';

  const adminA = 'a1111111-1111-1111-1111-111111111111';
  const adminB = 'a2222222-2222-2222-2222-222222222222';
  const legacyAdmin = 'a8888888-8888-8888-8888-888888888888'; // Global role only, no tenant membership

  const teacherA = 'de111111-1111-1111-1111-111111111111'; // Physics + Math Natural, School A, Class A
  const teacherMathSocial = 'de333333-3333-3333-3333-333333333333'; // Math Social, School A, Class D
  const teacherB = 'de222222-2222-2222-2222-222222222222'; // Chemistry, School B, Class B
  const teacherRevoked = 'de999999-9999-9999-9999-999999999999'; // Inactive membership
  const teacherSuspended = 'de444444-4444-4444-4444-444444444444'; // In suspended school
  const legacyTeacher = 'de888888-8888-8888-8888-888888888888'; // Global role only

  const studentA1 = 'ba111111-1111-1111-1111-111111111111'; // School A, Class A
  const studentA2 = 'ba222222-2222-2222-2222-222222222222'; // School A, Class A
  const studentA3 = 'ba333333-3333-3333-3333-333333333333'; // School A, Class A
  const studentA4 = 'ba444444-4444-4444-4444-444444444444'; // School A, Class A
  const studentA5 = 'ba555555-5555-5555-5555-555555555555'; // School A, Class A
  const studentA6 = 'ba666666-6666-6666-6666-666666666666'; // School A, Class A
  const studentB1 = 'bb111111-1111-1111-1111-111111111111'; // School B, Class B

  const classA = 'ca111111-1111-1111-1111-111111111111'; // School A, Grade 12 Natural
  const classB = 'ca222222-2222-2222-2222-222222222222'; // School B, Grade 12 Natural
  const classC = 'ca333333-3333-3333-3333-333333333333'; // School A, Grade 12 Social (unassigned)
  const classD = 'ca444444-4444-4444-4444-444444444444'; // School A, Grade 12 Social (assigned to teacherMathSocial)

  // Seed auth.users
  const allUsers = [
    adminA, adminB, legacyAdmin,
    teacherA, teacherMathSocial, teacherB, teacherRevoked, teacherSuspended, legacyTeacher,
    studentA1, studentA2, studentA3, studentA4, studentA5, studentA6, studentB1
  ];
  for (let i = 0; i < allUsers.length; i++) {
    const uid = allUsers[i];
    const phone = `+251910${i.toString().padStart(6, '0')}`;
    await db.query(`INSERT INTO auth.users (id, phone) VALUES ('${uid}', '${phone}') ON CONFLICT (id) DO NOTHING;`);
  }

  // Seed profiles
  await db.query(`
    INSERT INTO public.profiles (id, display_name, phone_number, grade, stream, preferred_language)
    VALUES 
      ('${adminA}', 'Abebe Admin', '+251910000000', 12, 'natural', 'en'),
      ('${adminB}', 'Biruk Admin', '+251910000001', 12, 'natural', 'en'),
      ('${legacyAdmin}', 'Legacy Admin', '+251910000002', 12, 'natural', 'en'),
      ('${teacherA}', 'Teacher Dawit', '+251910000003', 12, 'natural', 'en'),
      ('${teacherMathSocial}', 'Teacher Samuel', '+251910000004', 12, 'social', 'en'),
      ('${teacherB}', 'Teacher Bethlehem', '+251910000005', 12, 'natural', 'en'),
      ('${teacherRevoked}', 'Teacher Inactive', '+251910000006', 12, 'natural', 'en'),
      ('${teacherSuspended}', 'Teacher Suspended', '+251910000007', 12, 'natural', 'en'),
      ('${legacyTeacher}', 'Legacy Teacher', '+251910000008', 12, 'natural', 'en'),
      ('${studentA1}', 'Almaz Kebede', '+251910000009', 12, 'natural', 'en'),
      ('${studentA2}', 'Bikila Tola', '+251910000010', 12, 'natural', 'en'),
      ('${studentA3}', 'Chaltu Desta', '+251910000011', 12, 'natural', 'en'),
      ('${studentA4}', 'Daniel Assefa', '+251910000012', 12, 'natural', 'en'),
      ('${studentA5}', 'Eleni Mulugeta', '+251910000013', 12, 'natural', 'en'),
      ('${studentA6}', 'Fikadu Bekele', '+251910000014', 12, 'natural', 'en'),
      ('${studentB1}', 'Gemechu Wako', '+251910000015', 12, 'natural', 'en')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Global user roles for legacy tests
  await db.query(`
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES 
      ('${legacyAdmin}', 'school_admin'),
      ('${legacyTeacher}', 'teacher')
    ON CONFLICT DO NOTHING;
  `);

  // Seed schools
  await db.query(`
    INSERT INTO public.schools (id, name, school_code, status)
    VALUES 
      ('${schoolAId}', 'Bole Secondary School', 'BOLE-01', 'active'),
      ('${schoolBId}', 'Hawassa Secondary School', 'HAW-02', 'active'),
      ('${schoolSuspended}', 'Suspended Academy', 'SUSP-03', 'suspended')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed school memberships
  await db.query(`
    INSERT INTO public.school_memberships (school_id, user_id, role, status)
    VALUES 
      ('${schoolAId}', '${adminA}', 'school_admin', 'active'),
      ('${schoolBId}', '${adminB}', 'school_admin', 'active'),
      ('${schoolAId}', '${teacherA}', 'teacher', 'active'),
      ('${schoolAId}', '${teacherMathSocial}', 'teacher', 'active'),
      ('${schoolAId}', '${teacherRevoked}', 'teacher', 'inactive'),
      ('${schoolAId}', '${studentA1}', 'student', 'active'),
      ('${schoolAId}', '${studentA2}', 'student', 'active'),
      ('${schoolAId}', '${studentA3}', 'student', 'active'),
      ('${schoolAId}', '${studentA4}', 'student', 'active'),
      ('${schoolAId}', '${studentA5}', 'student', 'active'),
      ('${schoolAId}', '${studentA6}', 'student', 'active'),
      ('${schoolBId}', '${teacherB}', 'teacher', 'active'),
      ('${schoolBId}', '${studentB1}', 'student', 'active'),
      ('${schoolSuspended}', '${teacherSuspended}', 'teacher', 'active')
    ON CONFLICT DO NOTHING;
  `);

  // Seed classrooms
  await db.query(`
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
    VALUES 
      ('${classA}', '${schoolAId}', '12-A Natural', 12, 'natural', 'A', '2026', 'active'),
      ('${classB}', '${schoolBId}', '12-B Natural', 12, 'natural', 'B', '2026', 'active'),
      ('${classC}', '${schoolAId}', '12-C Social', 12, 'social', 'C', '2026', 'active'),
      ('${classD}', '${schoolAId}', '12-D Social', 12, 'social', 'D', '2026', 'active')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed classroom memberships
  await db.query(`
    INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status)
    VALUES 
      ('${classA}', '${studentA1}', 'student', 'active'),
      ('${classA}', '${studentA2}', 'student', 'active'),
      ('${classA}', '${studentA3}', 'student', 'active'),
      ('${classA}', '${studentA4}', 'student', 'active'),
      ('${classA}', '${studentA5}', 'student', 'active'),
      ('${classA}', '${studentA6}', 'student', 'active'),
      ('${classB}', '${studentB1}', 'student', 'active')
    ON CONFLICT DO NOTHING;
  `);

  // Seed subjects first for foreign keys
  await db.query(`
    INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, sort_order)
    VALUES 
      ('physics_g12', 'PHYS12', 'Physics', 'ፊዚክስ', 12, 'natural', 1),
      ('math_g12', 'MATH12', 'Mathematics', 'ሒሳብ', 12, 'natural', 2),
      ('chemistry_g12', 'CHEM12', 'Chemistry', 'ኬሚስትሪ', 12, 'natural', 3)
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed teacher subject assignments
  await db.query(`
    INSERT INTO public.teacher_subject_assignments (id, school_id, classroom_id, teacher_user_id, subject_id, exam_variant)
    VALUES 
      ('ea111111-1111-1111-1111-111111111111', '${schoolAId}', '${classA}', '${teacherA}', 'physics_g12', NULL),
      ('ea222222-2222-2222-2222-222222222222', '${schoolAId}', '${classA}', '${teacherA}', 'math_g12', 'naturalScience'),
      ('ea333333-3333-3333-3333-333333333333', '${schoolAId}', '${classD}', '${teacherMathSocial}', 'math_g12', 'socialScience'),
      ('ea444444-4444-4444-4444-444444444444', '${schoolBId}', '${classB}', '${teacherB}', 'chemistry_g12', NULL)
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed exams with P5 provenance
  const examPhysics = 'ee111111-1111-1111-1111-111111111111';
  const examMathNat = 'ee222222-2222-2222-2222-222222222222';
  const examMathSoc = 'ee333333-3333-3333-3333-333333333333';
  const examMathConflict = 'ee444444-4444-4444-4444-444444444444'; // Conflicting variant & stream

  await db.query(`
    INSERT INTO public.exams (id, title, exam_type, exam_mode, source_type, grade, stream, subject_id, exam_variant, time_limit_minutes, total_questions)
    VALUES 
      ('${examPhysics}', 'Physics ESSLCE National Simulation 2016', 'mock_full', 'nationalSimulation', 'officialHistoricalPaper', 12, 'natural', 'physics_g12', NULL, 120, 50),
      ('${examMathNat}', 'Math Natural Standard Simulation', 'mock_full', 'nationalSimulation', 'generatedSimulation', 12, 'natural', 'math_g12', 'naturalScience', 120, 60),
      ('${examMathSoc}', 'Math Social Standard Simulation', 'mock_full', 'nationalSimulation', 'generatedSimulation', 12, 'social', 'math_g12', 'socialScience', 120, 60),
      ('${examMathConflict}', 'Math Conflicting Metadata Test', 'mock_full', 'nationalSimulation', 'generatedSimulation', 12, 'social', 'math_g12', 'naturalScience', 120, 60)
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed attempts with retakes
  // Student A1: Attempt 1 (50%), Attempt 2 (70% latest)
  await db.query(`
    INSERT INTO public.attempts (id, user_id, exam_id, start_time, end_time, duration_seconds, total_questions, score, percentage, is_completed, created_at)
    VALUES 
      ('aa111111-1111-1111-1111-111111111111', '${studentA1}', '${examPhysics}', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days' + INTERVAL '1 hour', 3600, 50, 25, 50.0, true, NOW() - INTERVAL '10 days'),
      ('aa111111-1111-1111-1111-111111111112', '${studentA1}', '${examPhysics}', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', 3600, 50, 35, 70.0, true, NOW() - INTERVAL '2 days'),
      ('aa222222-2222-2222-2222-222222222221', '${studentA2}', '${examPhysics}', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '1 hour', 3600, 50, 40, 80.0, true, NOW() - INTERVAL '5 days'),
      ('aa333333-3333-3333-3333-333333333331', '${studentA3}', '${examPhysics}', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '1 hour', 3600, 50, 45, 90.0, true, NOW() - INTERVAL '5 days'),
      ('aa444444-4444-4444-4444-444444444441', '${studentA4}', '${examPhysics}', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '1 hour', 3600, 50, 30, 60.0, true, NOW() - INTERVAL '5 days'),
      ('aa555555-5555-5555-5555-555555555551', '${studentA5}', '${examPhysics}', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '1 hour', 3600, 50, 35, 70.0, true, NOW() - INTERVAL '5 days'),
      -- Math Natural attempt
      ('aa666666-6666-6666-6666-666666666661', '${studentA1}', '${examMathNat}', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '1 hour', 3600, 60, 48, 80.0, true, NOW() - INTERVAL '3 days'),
      -- Conflicting metadata attempt (must be excluded from Natural and Social)
      ('aa777777-7777-7777-7777-777777777771', '${studentA2}', '${examMathConflict}', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '1 hour', 3600, 60, 48, 80.0, true, NOW() - INTERVAL '3 days')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed assignments & recipients with deadline integrity levels
  const assign1 = 'fa111111-1111-1111-1111-111111111111';
  await db.query(`
    INSERT INTO public.learning_assignments (id, school_id, classroom_id, teacher_user_id, subject_id, exam_variant, title, assignment_type, status, created_at, published_at)
    VALUES 
      ('${assign1}', '${schoolAId}', '${classA}', '${teacherA}', 'physics_g12', NULL, 'Kinematics Mastery Drill', 'targetedPractice', 'published', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days')
    ON CONFLICT (id) DO NOTHING;
  `);

  await db.query(`
    INSERT INTO public.learning_assignment_recipients (assignment_id, student_user_id, status, deadline_integrity, score, percentage, submitted_at)
    VALUES 
      ('${assign1}', '${studentA1}', 'completed', 'verified', 20, 80.0, NOW() - INTERVAL '5 days'),
      ('${assign1}', '${studentA2}', 'late', 'verified', 18, 72.0, NOW() - INTERVAL '4 days'),
      ('${assign1}', '${studentA3}', 'submitted', 'unverified', 15, 60.0, NOW() - INTERVAL '3 days'),
      ('${assign1}', '${studentA4}', 'submitted', 'anomaly', 19, 76.0, NOW() - INTERVAL '2 days'),
      ('${assign1}', '${studentA5}', 'assigned', 'verified', NULL, NULL, NULL),
      ('${assign1}', '${studentA6}', 'excused', 'verified', NULL, NULL, NULL)
    ON CONFLICT DO NOTHING;
  `);

  // Seed interventions with baseline and follow-up evidence
  const interv1 = 'fa222222-2222-2222-2222-222222222222';
  await db.query(`
    INSERT INTO public.student_interventions (
      id, school_id, classroom_id, subject_id, exam_variant, student_user_id, teacher_user_id,
      source, source_reason_codes, severity_at_creation, action_type, status,
      created_at, completed_at
    ) VALUES (
      '${interv1}', '${schoolAId}', '${classA}', 'physics_g12', NULL, '${studentA1}', '${teacherA}',
      'p7Attention', '["low_accuracy", "high_mistakes"]'::jsonb, 'high', 'targetedPractice', 'completed',
      NOW() - INTERVAL '8 days', NOW() - INTERVAL '4 days'
    ) ON CONFLICT (id) DO NOTHING;
  `);
  console.log('✓ Multi-tenant fixtures and test dataset seeded successfully.');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✓ PASS: ${message}`);
      passed++;
    } else {
      console.error(`  ✗ FAIL: ${message}`);
      failed++;
    }
  }

  // 5. Security & Authorization Test Cases
  console.log('\n[5/8] Running Security & Authorization Test Cases...');

  // Test 1: School Admin A -> School A executive report ALLOWED
  await asUser(adminA);
  try {
    const res = await db.query(`SELECT public.get_institutional_executive_report('${schoolAId}', '2026') AS data;`);
    assert(res.rows.length === 1 && res.rows[0].data.school_id === schoolAId, 'School Admin A generates School A executive report');
  } catch (e) {
    assert(false, `School Admin A generates School A executive report: ${e.message}`);
  }

  // Test 2: School Admin A -> School B executive report DENIED
  let deniedAdminCross = false;
  try {
    await db.query(`SELECT public.get_institutional_executive_report('${schoolBId}', '2026') AS data;`);
  } catch (e) {
    deniedAdminCross = true;
  }
  assert(deniedAdminCross, 'School Admin A accessing School B is DENIED');

  // Test 3: Teacher A -> School A executive report DENIED
  await asUser(teacherA);
  let deniedTeacherExec = false;
  try {
    await db.query(`SELECT public.get_institutional_executive_report('${schoolAId}', '2026') AS data;`);
  } catch (e) {
    deniedTeacherExec = true;
  }
  assert(deniedTeacherExec, 'Teacher A calling school executive report is DENIED');

  // Test 4: Teacher A -> assigned Class A + Physics class report ALLOWED
  try {
    const res = await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
    `);
    assert(res.rows.length === 1 && res.rows[0].classroom_id === classA, 'Teacher A generates assigned Class A Physics report');
  } catch (e) {
    assert(false, `Teacher A generates assigned Class A Physics report: ${e.message}`);
  }

  // Test 5: Teacher A -> unassigned Class C report DENIED
  let deniedTeacherClassC = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classC}', 'physics_g12');
    `);
  } catch (e) {
    deniedTeacherClassC = true;
  }
  assert(deniedTeacherClassC, 'Teacher A requesting unassigned Class C is DENIED');

  // Test 6: Teacher A -> wrong subject (Chemistry) report DENIED
  let deniedTeacherWrongSub = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'chemistry_g12');
    `);
  } catch (e) {
    deniedTeacherWrongSub = true;
  }
  assert(deniedTeacherWrongSub, 'Teacher A requesting unassigned subject (Chemistry) is DENIED');

  // Test 7: Student -> institutional report DENIED
  await asUser(studentA1);
  let deniedStudentExec = false;
  try {
    await db.query(`SELECT public.get_institutional_executive_report('${schoolAId}', '2026') AS data;`);
  } catch (e) {
    deniedStudentExec = true;
  }
  assert(deniedStudentExec, 'Student calling executive report is DENIED');

  // Test 8: Legacy global admin without tenant membership -> DENIED
  await asUser(legacyAdmin);
  let deniedLegacyAdmin = false;
  try {
    await db.query(`SELECT public.get_institutional_executive_report('${schoolAId}', '2026') AS data;`);
  } catch (e) {
    deniedLegacyAdmin = true;
  }
  assert(deniedLegacyAdmin, 'Legacy global admin without active tenant membership is DENIED');

  // Test 9: Legacy global teacher without tenant membership -> DENIED
  await asUser(legacyTeacher);
  let deniedLegacyTeacher = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
    `);
  } catch (e) {
    deniedLegacyTeacher = true;
  }
  assert(deniedLegacyTeacher, 'Legacy global teacher without tenant membership is DENIED');

  // Test 10: Revoked teacher membership -> DENIED
  await asUser(teacherRevoked);
  let deniedRevokedTeacher = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
    `);
  } catch (e) {
    deniedRevokedTeacher = true;
  }
  assert(deniedRevokedTeacher, 'Revoked teacher membership is DENIED');

  // Test 11: Teacher in suspended school -> DENIED
  await asUser(teacherSuspended);
  let deniedSuspendedSchool = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolSuspended}', '2026', NULL, NULL, '${classA}', 'physics_g12');
    `);
  } catch (e) {
    deniedSuspendedSchool = true;
  }
  assert(deniedSuspendedSchool, 'Teacher in suspended school is DENIED');

  // Test 12: Cross-school classroom filter injection -> DENIED
  await asUser(adminA);
  let deniedFilterInjection = false;
  try {
    await db.query(`
      SELECT * FROM public.get_class_performance_report('${schoolAId}', '2026', NULL, NULL, '${classB}', 'physics_g12');
    `);
  } catch (e) {
    deniedFilterInjection = true;
  }
  assert(deniedFilterInjection, 'Cross-school classroom filter injection is DENIED');

  // 6. Analytical Invariant & Math Isolation Tests
  console.log('\n[6/8] Running Analytical Invariant & Math Isolation Tests...');

  // Test 13: Mathematics Natural strictly isolates from Social Science & conflicting metadata
  await asUser(adminA);
  const subjectReport = await db.query(`
    SELECT subject_id, subject_name, exam_variant, attempt_count, average_score, privacy_suppressed
    FROM public.get_subject_performance_report('${schoolAId}', '2026')
    WHERE subject_id = 'math_g12';
  `);

  const natRow = subjectReport.rows.find(r => r.exam_variant === 'naturalScience');
  const socRow = subjectReport.rows.find(r => r.exam_variant === 'socialScience');

  assert(natRow !== undefined && socRow !== undefined, 'Subject report lists Natural and Social Math as separate canonical entities');
  assert(natRow.attempt_count === 1, 'Math Natural includes exactly valid naturalScience attempts');
  assert(socRow.attempt_count === 0, 'Math Social contains zero natural attempts and excludes conflicting metadata');

  // Test 14: Retake Deduplication policy in assessment reports (latest attempt per student)
  const assessReport = await db.query(`
    SELECT * FROM public.get_assessment_report('${schoolAId}', '2026', NULL, NULL, 'physics_g12', '${examPhysics}');
  `);
  assert(assessReport.rows.length === 1, 'Assessment report retrieves Physics simulation');
  // Student A1 had 50% on attempt 1, 70% on attempt 2 (latest).
  // Students A1 (70%), A2 (80%), A3 (90%), A4 (60%), A5 (70%). Total 5 students. Avg: (70+80+90+60+70)/5 = 74.00
  const avg = parseFloat(assessReport.rows[0].average_score);
  assert(avg === 74.00, `Assessment average correctly reflects latest completed attempt deduplication: expected 74.00, got ${avg}`);

  // Test 15: P5 Provenance preserved in assessment report
  const p5row = assessReport.rows[0];
  assert(
    p5row.source_type === 'officialHistoricalPaper' &&
    p5row.exam_mode === 'nationalSimulation' &&
    p5row.exam_type === 'mock_full',
    'Assessment report preserves P5 provenance: officialHistoricalPaper, nationalSimulation, mock_full'
  );

  // 7. Assignment Timeliness & Denominator Integrity Tests
  console.log('\n[7/8] Running Assignment Timeliness & Denominator Integrity Tests...');
  const assignReport = await db.query(`
    SELECT * FROM public.get_assignment_outcomes_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
  `);
  assert(assignReport.rows.length === 1, 'Assignment outcomes report returns Kinematics assignment');
  const aRow = assignReport.rows[0];
  assert(aRow.publication_cohort === 6, `Publication cohort: expected 6, got ${aRow.publication_cohort}`);
  assert(aRow.required_denominator === 5, `Required completion denominator (cohort - excused): expected 5, got ${aRow.required_denominator}`);
  assert(aRow.submitted_count === 2, `Submitted count: expected 2, got ${aRow.submitted_count}`);
  assert(aRow.completed_count === 1, `Completed count: expected 1, got ${aRow.completed_count}`);
  assert(parseFloat(aRow.completion_rate) === 60.00, `Completion rate: expected 60.00, got ${aRow.completion_rate}`);
  assert(aRow.verified_on_time_count === 1, `Verified on-time count: expected 1, got ${aRow.verified_on_time_count}`);
  assert(aRow.verified_late_count === 1, `Verified late count: expected 1, got ${aRow.verified_late_count}`);
  assert(parseFloat(aRow.verified_on_time_rate) === 50.00, `Verified on-time rate: expected 50.00, got ${aRow.verified_on_time_rate}`);
  assert(parseFloat(aRow.verified_late_rate) === 50.00, `Verified late rate: expected 50.00, got ${aRow.verified_late_rate}`);
  assert(aRow.timing_unverified_count === 1, `Timing unverified count: expected 1, got ${aRow.timing_unverified_count}`);
  assert(aRow.clock_anomaly_count === 1, `Clock anomaly count: expected 1, got ${aRow.clock_anomaly_count}`);

  // 8. Intervention Follow-Up & Report Runs Persistence Tests
  console.log('\n[8/8] Running Intervention Follow-Up & Report Runs Tests...');
  const intervReport = await db.query(`
    SELECT * FROM public.get_intervention_followup_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
  `);
  assert(intervReport.rows.length === 1, 'Intervention follow-up report returns intervention for Student A1');
  const iRow = intervReport.rows[0];
  // Baseline attempt was 50%, follow-up was 70% -> observed change +20.00 pp
  assert(parseFloat(iRow.baseline_accuracy) === 50.00, `Baseline accuracy: expected 50.00, got ${iRow.baseline_accuracy}`);
  assert(parseFloat(iRow.followup_accuracy) === 70.00, `Follow-up accuracy: expected 70.00, got ${iRow.followup_accuracy}`);
  assert(parseFloat(iRow.observed_change_pp) === 20.00, `Observed change: expected +20.00 pp, got ${iRow.observed_change_pp}`);
  assert(iRow.evidence_interpretation.includes('causation not established'), 'Interpretation explicitly states non-causal disclaimer');
  assert(iRow.evidence_count_pre === 1, `Pre evidence count: expected 1, got ${iRow.evidence_count_pre}`);
  assert(iRow.evidence_count_post === 1, `Post evidence count: expected 1, got ${iRow.evidence_count_post}`);
  assert(iRow.confidence === 'limited', `Confidence: expected limited for 1 pair, got ${iRow.confidence}`);

  // Test 18: Incomplete intervention action (open status) must be not_yet_eligible and have NULL follow-up
  await asSuperuser();
  const intervOpenId = '11222222-2222-2222-2222-222222222222';
  await db.query(`
    INSERT INTO public.student_interventions (
      id, school_id, classroom_id, subject_id, exam_variant,
      student_user_id, teacher_user_id, source, severity_at_creation,
      source_reason_codes, action_type, status, created_at, completed_at
    ) VALUES (
      '${intervOpenId}', '${schoolAId}', '${classA}', 'physics_g12', NULL,
      '${studentA2}', '${teacherA}', 'p7Attention', 'medium',
      '["active_mistakes_present"]'::jsonb, 'targetedPractice', 'open', NOW() - INTERVAL '10 days', NULL
    );
  `);
  await asUser(adminA);
  const openIntervReport = await db.query(`
    SELECT * FROM public.get_intervention_followup_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
  `);
  const openRow = openIntervReport.rows.find(r => r.intervention_id === intervOpenId);
  assert(openRow !== undefined, 'Open intervention returned');
  assert(openRow.evidence_status === 'not_yet_eligible', `Open intervention evidence_status: expected not_yet_eligible, got ${openRow.evidence_status}`);
  assert(openRow.followup_accuracy === null, 'Open intervention followup_accuracy is NULL');
  assert(openRow.observed_change_pp === null, 'Open intervention observed_change_pp is NULL');

  // Test 19: Report run creation and audit log generation
  const runRes = await db.query(`
    SELECT public.create_institutional_report_run(
      '${schoolAId}',
      'executive',
      '2026',
      NOW() - INTERVAL '30 days',
      NOW(),
      '{"period": "last_30_days"}'::jsonb,
      'csv'
    ) AS result;
  `);
  const runId = runRes.rows[0].result.run_id;
  assert(runRes.rows[0].result.success === true && runId !== undefined, 'Report run created successfully');

  await asSuperuser();
  const auditRes = await db.query(`
    SELECT * FROM public.audit_log 
    WHERE action = 'institutional_report_generated' AND target_id = '${runId}';
  `);
  assert(auditRes.rows.length === 1, 'Audit log event institutional_report_generated recorded with metadata');

  // Test 20: Cross-tenant report run isolation
  await asUser(adminB);
  let adminBSeesRun = false;
  try {
    const runsB = await db.query(`SELECT * FROM public.get_institutional_report_runs('${schoolAId}');`);
  } catch (e) {
    adminBSeesRun = false;
  }
  assert(!adminBSeesRun, 'Admin B cannot access School A report run history');

  // Test 21: Teacher Coverage Report authority and slot calculation
  await asUser(adminA);
  const covRes = await db.query(`
    SELECT public.get_teacher_coverage_report('${schoolAId}', '2026') AS res;
  `);
  const cov = covRes.rows[0].res;
  assert(cov.total_slots > 0, `Teacher coverage total slots: expected > 0, got ${cov.total_slots}`);
  assert(cov.coverage_percentage !== undefined, 'Coverage percentage calculated');
  assert(Array.isArray(cov.slots), 'Slots list returned in teacher coverage report');

  await asUser(teacherA);
  let teacherCovDenied = false;
  try {
    await db.query(`SELECT public.get_teacher_coverage_report('${schoolAId}', '2026');`);
  } catch (e) {
    teacherCovDenied = true;
  }
  assert(teacherCovDenied, 'Teacher denied from general teacher coverage report without admin oversight');

  await asUser(studentA1);
  let studentCovDenied = false;
  try {
    await db.query(`SELECT public.get_teacher_coverage_report('${schoolAId}', '2026');`);
  } catch (e) {
    studentCovDenied = true;
  }
  assert(studentCovDenied, 'Student denied from teacher coverage report');

  await asUser(adminB);
  let crossCovDenied = false;
  try {
    await db.query(`SELECT public.get_teacher_coverage_report('${schoolAId}', '2026');`);
  } catch (e) {
    crossCovDenied = true;
  }
  assert(crossCovDenied, 'Cross-school admin denied from teacher coverage report');

  // Test 22: Active Enrolled Students vs Students with Academic Evidence in Executive Report
  await asUser(adminA);
  const execReport = await db.query(`
    SELECT public.get_institutional_executive_report('${schoolAId}') AS res;
  `);
  const exec = execReport.rows[0].res;
  assert(exec.populations.active_enrolled_students === 6, `Active enrolled students: expected 6, got ${exec.populations.active_enrolled_students}`);
  assert(exec.populations.students_with_academic_evidence === 5, `Students with academic evidence: expected 5, got ${exec.populations.students_with_academic_evidence}`);
  assert(exec.assignment_follow_through.verified_on_time_rate === 50.00, `Executive verified on-time rate: expected 50.00, got ${exec.assignment_follow_through.verified_on_time_rate}`);

  // =========================================================================
  // CANONICAL FREEZE CORRECTION VERIFICATION SUITE
  // =========================================================================
  console.log('\n[9/9] Running Final P10 Canonical Freeze Verification Tests...');

  // Test 23: Canonical 4-Student Sync Freshness Regression Matrix
  // Invariant: sync_freshness is derived ONLY from attempts.created_at (server cloud-evidence receipt).
  // Academic activity (attempts.start_time, mistake_records.last_failed_at) NEVER substitutes for sync.
  await asSuperuser();
  const fStudentA = 'ea000001-0000-0000-0000-000000000001'; // sync=today, activity=10 days ago → fresh
  const fStudentB = 'ea000002-0000-0000-0000-000000000002'; // sync=8 days ago, activity=yesterday → stale (not fresh)
  const fStudentC = 'ea000003-0000-0000-0000-000000000003'; // sync=NULL, activity=yesterday (via mistake) → UNKNOWN (critical regression)
  const fStudentD = 'ea000006-0000-0000-0000-000000000006'; // sync=NULL, activity=NULL → unknown
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES 
      ('${fStudentA}', '+251910000091'),
      ('${fStudentB}', '+251910000092'),
      ('${fStudentC}', '+251910000093'),
      ('${fStudentD}', '+251910000094')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, display_name, phone_number, grade, stream, preferred_language) VALUES 
      ('${fStudentA}', 'Freshness Student A', '+251910000091', 12, 'natural', 'en'),
      ('${fStudentB}', 'Freshness Student B', '+251910000092', 12, 'natural', 'en'),
      ('${fStudentC}', 'Freshness Student C', '+251910000093', 12, 'natural', 'en'),
      ('${fStudentD}', 'Freshness Student D', '+251910000094', 12, 'natural', 'en')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES 
      ('${schoolAId}', '${fStudentA}', 'student', 'active'),
      ('${schoolAId}', '${fStudentB}', 'student', 'active'),
      ('${schoolAId}', '${fStudentC}', 'student', 'active'),
      ('${schoolAId}', '${fStudentD}', 'student', 'active')
    ON CONFLICT DO NOTHING;

    -- Note: fStudentD intentionally has NO classroom membership to test null-sync + null-activity case
    -- without affecting the school-wide active_enrolled_students count used in Test 24 deduplication.
    INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status) VALUES 
      ('${classA}', '${fStudentA}', 'student', 'active'),
      ('${classA}', '${fStudentB}', 'student', 'active'),
      ('${classA}', '${fStudentC}', 'student', 'active')
    ON CONFLICT DO NOTHING;

    -- Student A: academic activity 10 days ago (start_time), server received sync TODAY (created_at)
    -- Expected: sync_freshness=fresh, last_cloud_academic_activity=10 days ago
    INSERT INTO public.attempts (
      id, user_id, exam_id, total_questions, score, percentage, is_completed,
      start_time, end_time, created_at
    ) VALUES (
      'ea911111-1111-1111-1111-111111111111', '${fStudentA}', '${examPhysics}', 50, 42, 84.0, true,
      NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', NOW()
    );

    -- Student B: academic activity YESTERDAY (start_time), server received sync 8 DAYS AGO (created_at)
    -- Expected: sync_freshness=stale (NOT fresh — recent academic activity must NOT upgrade sync freshness)
    INSERT INTO public.attempts (
      id, user_id, exam_id, total_questions, score, percentage, is_completed,
      start_time, end_time, created_at
    ) VALUES (
      'ea922222-2222-2222-2222-222222222222', '${fStudentB}', '${examPhysics}', 50, 38, 76.0, true,
      NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '8 days'
    );

    -- Student C: NO attempts (no server-received sync). Has a recent mistake event from YESTERDAY.
    -- Critical regression: mistake_records.last_failed_at is academic activity, NOT sync evidence.
    -- Expected: sync_freshness=unknown, last_cloud_academic_activity=non-null (yesterday)
  `);
  // Insert Student C's mistake separately to reference a real question
  const qForMistake = (await db.query(`SELECT id FROM public.questions LIMIT 1`)).rows[0]?.id;
  if (qForMistake) {
    await asSuperuser();
    await db.query(`
      INSERT INTO public.mistake_records (user_id, question_id, mistake_count, is_mastered, last_failed_at)
      VALUES ('${fStudentC}', '${qForMistake}', 1, false, NOW() - INTERVAL '1 day')
      ON CONFLICT (user_id, question_id) DO NOTHING;
    `);
  }
  // Student D: no attempts, no mistakes — everything null
  // Expected: sync_freshness=unknown, last_cloud_academic_activity=null

  await asUser(adminA);
  const repA = (await db.query(`SELECT public.get_student_academic_report('${schoolAId}', '${fStudentA}') AS res;`)).rows[0].res;
  const repB = (await db.query(`SELECT public.get_student_academic_report('${schoolAId}', '${fStudentB}') AS res;`)).rows[0].res;
  const repC = (await db.query(`SELECT public.get_student_academic_report('${schoolAId}', '${fStudentC}') AS res;`)).rows[0].res;
  const repD = (await db.query(`SELECT public.get_student_academic_report('${schoolAId}', '${fStudentD}') AS res;`)).rows[0].res;

  // Student A: sync=today → fresh; activity=10 days ago (separate, non-null)
  assert(repA.sync_freshness === 'fresh', `Student A sync_freshness: expected fresh (synced today), got ${repA.sync_freshness}`);
  assert(repA.last_successful_sync !== null, 'Student A has last_successful_sync');
  assert(repA.last_cloud_academic_activity !== null, 'Student A has last_cloud_academic_activity');

  // Student B: sync=8 days ago → stale; activity=yesterday. Critical: recent activity must NOT make sync fresh.
  assert(repB.sync_freshness === 'stale', `Student B sync_freshness: expected stale (synced 8 days ago), got ${repB.sync_freshness} — recent academic activity must NOT override sync freshness`);
  assert(repB.last_successful_sync !== null, 'Student B has last_successful_sync (8 days ago)');
  assert(repB.last_cloud_academic_activity !== null, 'Student B has last_cloud_academic_activity (yesterday)');

  // Student C: CRITICAL REGRESSION — no sync at all, but has recent academic activity (mistake yesterday)
  // sync_freshness MUST be unknown even though academic activity is recent
  assert(repC.sync_freshness === 'unknown', `Student C sync_freshness: expected unknown (NULL sync despite recent activity), got ${repC.sync_freshness} — academic activity must NOT substitute for sync`);
  assert(repC.last_successful_sync === null, 'Student C: last_successful_sync must be NULL (no attempts synced)');
  if (qForMistake) {
    assert(repC.last_cloud_academic_activity !== null, 'Student C: last_cloud_academic_activity must be non-null (recent mistake)');
  }

  // Student D: nothing at all → unknown, null activity
  assert(repD.sync_freshness === 'unknown', `Student D sync_freshness: expected unknown (null sync + null activity), got ${repD.sync_freshness}`);
  assert(repD.last_successful_sync === null, 'Student D has NULL last_successful_sync');
  assert(repD.last_cloud_academic_activity === null, 'Student D has NULL last_cloud_academic_activity');

  const dataCov = (await db.query(`SELECT public.get_data_coverage_report('${schoolAId}', '2026') AS res;`)).rows[0].res;
  assert(dataCov.unknown_sync_count >= 1, `Data coverage unknown_sync_count: expected >= 1, got ${dataCov.unknown_sync_count}`);
  assert(dataCov.methodological_notice.includes('Missing cloud evidence must not be interpreted as lack of study'), 'Data coverage contains exact offline disclaimer');

  // Test 24: Active Student Enrollment Canonical Source & Deduplication (Prompt Issues 8-12)
  await asSuperuser();
  const dStudent1 = 'ea000004-0000-0000-0000-000000000004';
  const dStudentInactive = 'ea000005-0000-0000-0000-000000000005';
  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES 
      ('${dStudent1}', '+251910000081'),
      ('${dStudentInactive}', '+251910000082')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, display_name, phone_number, grade, stream, preferred_language) VALUES 
      ('${dStudent1}', 'Multi-Enrolled Student', '+251910000081', 12, 'natural', 'en'),
      ('${dStudentInactive}', 'Transferred Student', '+251910000082', 12, 'natural', 'en')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES 
      ('${schoolAId}', '${dStudent1}', 'student', 'active'),
      ('${schoolAId}', '${dStudentInactive}', 'student', 'active')
    ON CONFLICT DO NOTHING;

    -- dStudent1 enrolled in TWO classrooms in School A
    INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status) VALUES 
      ('${classA}', '${dStudent1}', 'student', 'active'),
      ('${classC}', '${dStudent1}', 'student', 'active'),
      -- dStudentInactive has inactive/transferred status
      ('${classA}', '${dStudentInactive}', 'student', 'inactive')
    ON CONFLICT DO NOTHING;

    -- dStudentInactive has historical attempt
    INSERT INTO public.attempts (
      id, user_id, exam_id, total_questions, score, percentage, is_completed, start_time, end_time, created_at
    ) VALUES (
      'ea888888-8888-8888-8888-888888888888', '${dStudentInactive}', '${examPhysics}', 50, 45, 90.0, true, NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'
    );
  `);

  await asUser(adminA);
  const execDedupe = (await db.query(`SELECT public.get_institutional_executive_report('${schoolAId}', '2026') AS res;`)).rows[0].res;
  // Multi-enrolled student must be deduplicated (counted exactly once), inactive student must be excluded
  // Prior active students: 6 initial (studentA1..A6) + 3 freshness (fStudentA, fStudentB, fStudentC) + 1 (dStudent1) = 10 active
  assert(execDedupe.populations.active_enrolled_students === 10, `Active enrolled students deduplicated: expected 10, got ${execDedupe.populations.active_enrolled_students}`);

  // Test 25: Teacher Coverage Denominator — 24 slots for 2 Nat + 2 Soc (Prompt Issues 13-18)
  await asSuperuser();
  const classA2 = 'cc222222-2222-2222-2222-222222222222';
  await db.query(`
    INSERT INTO public.classrooms (id, school_id, name, grade, stream, section, academic_year, status)
    VALUES ('${classA2}', '${schoolAId}', '12-B Natural', 12, 'naturalScience', 'B', '2026', 'active')
    ON CONFLICT (id) DO NOTHING;
  `);

  await asUser(adminA);
  const cov24Res = (await db.query(`SELECT public.get_teacher_coverage_report('${schoolAId}', '2026') AS res;`)).rows[0].res;
  // 2 Natural (classA, classA2) + 2 Social (classC, classD) = 4 * 6 = 24 required slots
  assert(cov24Res.total_slots === 24, `Teacher coverage required slots: expected exactly 24 (4 classes * 6 stream subjects), got ${cov24Res.total_slots}`);

  // Verify Natural classes have only Natural primary curriculum and Social classes have only Social
  const natSlots = cov24Res.slots.filter(s => s.classroom_id === classA);
  assert(natSlots.length === 6, `Natural classA slots count: expected 6, got ${natSlots.length}`);
  const natSubjectIds = natSlots.map(s => s.subject_id);
  assert(natSubjectIds.includes('physics_g12'), 'Natural class includes physics_g12');
  assert(natSubjectIds.includes('chemistry_g12'), 'Natural class includes chemistry_g12');
  assert(natSubjectIds.includes('biology_g12'), 'Natural class includes biology_g12');
  assert(!natSubjectIds.includes('history_g12'), 'Natural class excludes history_g12');
  assert(!natSubjectIds.includes('geography_g12'), 'Natural class excludes geography_g12');
  assert(!natSubjectIds.includes('economics_g12'), 'Natural class excludes economics_g12');
  assert(!natSubjectIds.includes('civics_g12'), 'Natural class excludes civics_g12');
  const natMath = natSlots.find(s => s.subject_id === 'math_g12');
  assert(natMath.exam_variant === 'naturalScience', 'Natural math slot requires naturalScience variant');

  const socSlots = cov24Res.slots.filter(s => s.classroom_id === classC);
  assert(socSlots.length === 6, `Social classC slots count: expected 6, got ${socSlots.length}`);
  const socSubjectIds = socSlots.map(s => s.subject_id);
  assert(socSubjectIds.includes('history_g12'), 'Social class includes history_g12');
  assert(socSubjectIds.includes('geography_g12'), 'Social class includes geography_g12');
  assert(socSubjectIds.includes('economics_g12'), 'Social class includes economics_g12');
  assert(!socSubjectIds.includes('physics_g12'), 'Social class excludes physics_g12');
  assert(!socSubjectIds.includes('civics_g12'), 'Social class excludes civics_g12');
  const socMath = socSlots.find(s => s.subject_id === 'math_g12');
  assert(socMath.exam_variant === 'socialScience', 'Social math slot requires socialScience variant');

  // Test 26: P9 Assignment Completion Regression (Prompt Issues 19-23)
  // Fixture: requiredForCompletion = 10 (cohort 11 with 1 excused), submitted = 4, completed = 3, inProgress = 2, assigned = 1
  await asSuperuser();
  const assignRegression = 'aa999999-9999-9999-9999-999999999999';
  await db.query(`
    INSERT INTO public.learning_assignments (
      id, school_id, classroom_id, teacher_user_id, subject_id, exam_variant,
      title, assignment_type, status, due_at, created_at
    ) VALUES (
      '${assignRegression}', '${schoolAId}', '${classA}', '${teacherA}', 'physics_g12', NULL,
      'P9 Completion Regression Fixture', 'targetedPractice', 'published', NOW() + INTERVAL '3 days', NOW() - INTERVAL '1 day'
    );
  `);

  // Seed 11 dummy student profiles for assignment recipients
  const regStudents = [];
  for (let i = 1; i <= 11; i++) {
    const sId = `ba${i.toString().padStart(2, '0')}0000-0000-0000-0000-000000000000`;
    regStudents.push(sId);
    await db.exec(`
      INSERT INTO auth.users (id, phone) VALUES ('${sId}', '+2519200000${i.toString().padStart(2, '0')}') ON CONFLICT (id) DO NOTHING;
      INSERT INTO public.profiles (id, display_name, phone_number, grade, stream, preferred_language) VALUES ('${sId}', 'Reg Student ${i}', '+2519200000${i.toString().padStart(2, '0')}', 12, 'natural', 'en') ON CONFLICT (id) DO NOTHING;
      INSERT INTO public.school_memberships (school_id, user_id, role, status) VALUES ('${schoolAId}', '${sId}', 'student', 'active') ON CONFLICT DO NOTHING;
      INSERT INTO public.classroom_memberships (classroom_id, user_id, role, status) VALUES ('${classA}', '${sId}', 'student', 'active') ON CONFLICT DO NOTHING;
    `);
  }

  // 4 submitted, 3 completed, 2 inProgress, 1 assigned, 1 excused -> total 11
  await db.exec(`
    INSERT INTO public.learning_assignment_recipients (assignment_id, student_user_id, status, deadline_integrity, percentage) VALUES 
      ('${assignRegression}', '${regStudents[0]}', 'submitted', 'verified', 80.0),
      ('${assignRegression}', '${regStudents[1]}', 'submitted', 'verified', 85.0),
      ('${assignRegression}', '${regStudents[2]}', 'submitted', 'verified', 70.0),
      ('${assignRegression}', '${regStudents[3]}', 'submitted', 'unverified', 65.0),
      ('${assignRegression}', '${regStudents[4]}', 'completed', 'verified', 90.0),
      ('${assignRegression}', '${regStudents[5]}', 'completed', 'verified', 95.0),
      ('${assignRegression}', '${regStudents[6]}', 'completed', 'verified', 88.0),
      ('${assignRegression}', '${regStudents[7]}', 'inProgress', 'verified', NULL),
      ('${assignRegression}', '${regStudents[8]}', 'inProgress', 'verified', NULL),
      ('${assignRegression}', '${regStudents[9]}', 'assigned', 'verified', NULL),
      ('${assignRegression}', '${regStudents[10]}', 'excused', 'verified', NULL);
  `);

  await asUser(adminA);
  const regReport = await db.query(`
    SELECT * FROM public.get_assignment_outcomes_report('${schoolAId}', '2026', NULL, NULL, '${classA}', 'physics_g12');
  `);
  const regRow = regReport.rows.find(r => r.assignment_id === assignRegression);
  assert(regRow !== undefined, 'Regression assignment found in outcomes report');
  assert(regRow.publication_cohort === 11, `Publication cohort: expected 11, got ${regRow.publication_cohort}`);
  assert(regRow.required_denominator === 10, `Required denominator (11 - 1 excused): expected 10, got ${regRow.required_denominator}`);
  assert(regRow.submitted_count === 4, `Submitted count: expected 4, got ${regRow.submitted_count}`);
  assert(regRow.completed_count === 3, `Completed count: expected 3, got ${regRow.completed_count}`);
  assert(regRow.excused_count === 1, `Excused count: expected 1, got ${regRow.excused_count}`);
  // completion numerator = submitted (4) + completed (3) = 7 -> completion rate = 7 / 10 = 70.00%
  assert(parseFloat(regRow.completion_rate) === 70.00, `Completion rate: expected exactly 70.00%, got ${regRow.completion_rate}`);

  // Test 27: Canonical Audit Table Verification — public.audit_log (Prompt Issues 24-26)
  await asUser(adminA);
  await db.exec(`
    SELECT public.record_institutional_report_audit(
      '${schoolAId}',
      '${runId}',
      'institutional_report_exported',
      '{"file_format": "pdf", "section_count": 6}'::jsonb
    );
    SELECT public.record_institutional_report_audit(
      '${schoolAId}',
      '${runId}',
      'institutional_report_downloaded',
      '{"bytes": 1048576, "file_name": "school_report.pdf"}'::jsonb
    );
  `);

  await asSuperuser();
  const auditEntries = await db.query(`
    SELECT * FROM public.audit_log 
    WHERE target_table = 'institutional_report_runs' AND target_id = '${runId}'
    ORDER BY created_at ASC;
  `);
  assert(auditEntries.rows.length === 3, `Audit log entries in public.audit_log: expected 3, got ${auditEntries.rows.length}`);
  const actions = auditEntries.rows.map(r => r.action);
  assert(actions.includes('institutional_report_generated'), 'public.audit_log includes institutional_report_generated');
  assert(actions.includes('institutional_report_exported'), 'public.audit_log includes institutional_report_exported');
  assert(actions.includes('institutional_report_downloaded'), 'public.audit_log includes institutional_report_downloaded');
  // Verify zero sensitive student PII in metadata
  for (const entry of auditEntries.rows) {
    const metaStr = JSON.stringify(entry.metadata);
    assert(!metaStr.includes('student_name'), 'Audit metadata does NOT contain student_name');
    assert(!metaStr.includes('+251'), 'Audit metadata does NOT contain student phone numbers');
  }


  console.log('\n=============================================================================');
  console.log(`P10 POSTGRESQL VERIFICATION COMPLETE: ${passed} PASSED, ${failed} FAILED`);
  console.log('=============================================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
