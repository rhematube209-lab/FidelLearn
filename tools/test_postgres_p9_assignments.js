const fs = require('fs');
const path = require('path');
const { PGlite } = require('C:/Users/tamer/.gemini/antigravity-ide/brain/306ba7e1-406d-4c4f-b110-48f3c763535d/scratch/node_modules/@electric-sql/pglite');

async function run() {
  console.log('=============================================================================');
  console.log('FidelLearn — Real PostgreSQL P9 Assignments + Interventions Verification');
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
    'supabase/migrations/20260925030000_p9_assignments_interventions.sql'
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

  // 3. Inspect PostgreSQL Catalog: SECURITY DEFINER, search_path, and EXECUTE grants
  console.log('\n[3/8] Catalog Verification: Inspecting SECURITY DEFINER, search_path & Grants...');
  const p9Functions = [
    'can_teacher_manage_assignment',
    'create_learning_assignment',
    'update_learning_assignment_draft',
    'publish_learning_assignment',
    'close_learning_assignment',
    'archive_learning_assignment',
    'add_assignment_recipient',
    'get_teacher_assignments',
    'get_teacher_assignment_progress',
    'get_student_assignments',
    'get_student_assignment_detail',
    'submit_student_assignment',
    'create_student_intervention',
    'complete_student_intervention',
    'close_student_intervention',
    'get_teacher_interventions'
  ];

  const funcCheck = await db.query(`
    SELECT proname, prosecdef, proconfig
    FROM pg_proc
    JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE pg_namespace.nspname = 'public'
      AND proname = ANY($1::text[])
    ORDER BY proname;
  `, [p9Functions]);

  console.table(funcCheck.rows);
  if (funcCheck.rows.length !== p9Functions.length || !funcCheck.rows.every(r => r.prosecdef && r.proconfig && r.proconfig.some(c => c.includes('search_path=public, pg_temp')))) {
    throw new Error('Not all P9 functions have SECURITY DEFINER and search_path=public, pg_temp!');
  }
  console.log(`✓ All ${p9Functions.length} P9 functions confirmed SECURITY DEFINER with search_path=public, pg_temp.`);

  // 4. Seed Multi-Tenant Fixtures
  console.log('\n[4/8] Seeding Multi-Tenant Test Data & Educational Records...');
  const schoolAId = '11111111-1111-1111-1111-111111111111';
  const schoolBId = '22222222-2222-2222-2222-222222222222';
  const schoolSuspended = '33333333-3333-3333-3333-333333333333';

  const teacherA = 'de111111-1111-1111-1111-111111111111'; // Physics + Math Natural, School A, Class A
  const teacherB = 'de222222-2222-2222-2222-222222222222'; // Chemistry, School B, Class B
  const teacherMathSocial = 'de333333-3333-3333-3333-333333333333'; // Math Social, School A, Class D
  const teacherRevoked = 'de999999-9999-9999-9999-999999999999'; // Inactive membership
  const teacherSuspended = 'de444444-4444-4444-4444-444444444444'; // In suspended school
  const adminA = 'a1111111-1111-1111-1111-111111111111';

  const studentA1 = 'ba111111-1111-1111-1111-111111111111'; // School A, Class A
  const studentA2 = 'ba222222-2222-2222-2222-222222222222'; // School A, Class A
  const studentB1 = 'ba333333-3333-3333-3333-333333333333'; // School B, Class B
  const studentForeign = 'ba555555-5555-5555-5555-555555555555'; // Unenrolled

  const classA = 'ca111111-1111-1111-1111-111111111111'; // School A, Grade 12 Natural
  const classB = 'ca222222-2222-2222-2222-222222222222'; // School B, Grade 12 Natural
  const classC = 'ca333333-3333-3333-3333-333333333333'; // School A, Grade 12 Social (unassigned to Teacher A)
  const classD = 'ca444444-4444-4444-4444-444444444444'; // School A, Grade 12 Social (assigned to teacherMathSocial)

  // Seed auth.users
  const allUsers = [
    adminA, teacherA, teacherB, teacherMathSocial, teacherRevoked, teacherSuspended,
    studentA1, studentA2, studentB1, studentForeign
  ];
  for (let i = 0; i < allUsers.length; i++) {
    const uid = allUsers[i];
    const phone = `+251912${i.toString().padStart(6, '0')}`;
    await db.query(`INSERT INTO auth.users (id, phone) VALUES ('${uid}', '${phone}') ON CONFLICT (id) DO NOTHING;`);
  }

  // Seed profiles
  await db.query(`
    INSERT INTO public.profiles (id, display_name, phone_number, grade, stream, preferred_language)
    VALUES 
      ('${adminA}', 'Abebe Admin', '+251912000000', 12, 'natural', 'en'),
      ('${teacherA}', 'Teacher Dawit', '+251912000001', 12, 'natural', 'en'),
      ('${teacherB}', 'Teacher Bethlehem', '+251912000002', 12, 'natural', 'en'),
      ('${teacherMathSocial}', 'Teacher Samuel', '+251912000003', 12, 'social', 'en'),
      ('${teacherRevoked}', 'Teacher Inactive', '+251912000004', 12, 'natural', 'en'),
      ('${teacherSuspended}', 'Teacher Suspended', '+251912000005', 12, 'natural', 'en'),
      ('${studentA1}', 'Almaz Kebede', '+251912000006', 12, 'natural', 'en'),
      ('${studentA2}', 'Bikila Tola', '+251912000007', 12, 'natural', 'en'),
      ('${studentB1}', 'Chala Gemechu', '+251912000008', 12, 'natural', 'en'),
      ('${studentForeign}', 'Danayt Haile', '+251912000009', 12, 'natural', 'en')
    ON CONFLICT (id) DO NOTHING;
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
      ('${schoolAId}', '${teacherA}', 'teacher', 'active'),
      ('${schoolAId}', '${teacherMathSocial}', 'teacher', 'active'),
      ('${schoolAId}', '${teacherRevoked}', 'teacher', 'inactive'),
      ('${schoolAId}', '${studentA1}', 'student', 'active'),
      ('${schoolAId}', '${studentA2}', 'student', 'active'),
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
      ('${classB}', '${studentB1}', 'student', 'active')
    ON CONFLICT DO NOTHING;
  `);

  // Seed subjects
  await db.query(`
    INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, sort_order)
    VALUES 
      ('physics_g12', 'PHYS12', 'Physics', 'ፊዚክስ', 12, 'natural', 1),
      ('math_g12', 'MATH12', 'Mathematics', 'ሒሳብ', 12, 'natural', 2),
      ('chemistry_g12', 'CHEM12', 'Chemistry', 'ኬሚስትሪ', 12, 'natural', 3)
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed units & topics for foreign keys in questions
  await db.exec(`
    INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am)
    VALUES 
      ('u_phys_1', 'physics_g12', 1, 'Mechanics', 'መካኒክስ'),
      ('u_math_1', 'math_g12', 1, 'Calculus', 'ካልኩለስ')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am)
    VALUES 
      ('t_phys_1', 'u_phys_1', 1, 'Kinematics', 'ኪነማቲክስ'),
      ('t_math_1', 'u_math_1', 1, 'Limits', 'ሊሚት')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed teacher_subject_assignments
  await db.query(`
    INSERT INTO public.teacher_subject_assignments (school_id, classroom_id, teacher_user_id, subject_id, exam_variant, status)
    VALUES 
      ('${schoolAId}', '${classA}', '${teacherA}', 'physics_g12', NULL, 'active'),
      ('${schoolAId}', '${classA}', '${teacherA}', 'math_g12', 'naturalScience', 'active'),
      ('${schoolAId}', '${classD}', '${teacherMathSocial}', 'math_g12', 'socialScience', 'active'),
      ('${schoolBId}', '${classB}', '${teacherB}', 'chemistry_g12', NULL, 'active')
    ON CONFLICT DO NOTHING;
  `);

  // Seed sample verified questions
  const qPhys1 = '11111111-aaaa-1111-1111-111111111111';
  const qPhys2 = '22222222-aaaa-2222-2222-222222222222';
  const qMathNat1 = '33333333-aaaa-3333-3333-333333333333';
  const qMathNat2 = '44444444-aaaa-4444-4444-444444444444';
  const qMathSoc1 = '55555555-aaaa-5555-5555-555555555555';
  const qUnverified = '66666666-aaaa-6666-6666-666666666666';

  await db.query(`
    INSERT INTO public.questions (id, subject_id, unit_id, topic_id, stream, exam_variant, grade, verification_status, question_text_en)
    VALUES 
      ('${qPhys1}', 'physics_g12', 'u_phys_1', 't_phys_1', 'natural', NULL, 12, 'approved', 'A particle moves with constant acceleration...'),
      ('${qPhys2}', 'physics_g12', 'u_phys_1', 't_phys_1', 'natural', NULL, 12, 'approved', 'What is the electric flux through a closed surface?'),
      ('${qMathNat1}', 'math_g12', 'u_math_1', 't_math_1', 'natural', 'naturalScience', 12, 'approved', 'Find the limit as x approaches 0 of sin(x)/x'),
      ('${qMathNat2}', 'math_g12', 'u_math_1', 't_math_1', 'natural', 'naturalScience', 12, 'approved', 'Evaluate the vector cross product...'),
      ('${qMathSoc1}', 'math_g12', 'u_math_1', 't_math_1', 'social', 'socialScience', 12, 'approved', 'Calculate the compound interest rate...'),
      ('${qUnverified}', 'physics_g12', 'u_phys_1', 't_phys_1', 'natural', NULL, 12, 'draft', 'Draft physics question not yet approved')
    ON CONFLICT (id) DO NOTHING;
  `);

  // Seed exam & attempt fixtures for student submission tests
  const attemptId1 = 'ea111111-1111-1111-1111-111111111111';
  const attemptId2 = 'ea222222-2222-2222-2222-222222222222';
  const examAssignId = 'ea000000-0000-0000-0000-000000000000';
  await db.exec(`
    INSERT INTO public.exams (id, title, grade, stream, subject_id, exam_type, exam_mode, source_type, total_questions, time_limit_minutes)
    VALUES ('${examAssignId}', 'Physics Assignment Exam', 12, 'natural', 'physics_g12', 'practice', 'practice', 'curriculumPractice', 2, 60)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.attempts (id, user_id, exam_id, start_time, end_time, duration_seconds, total_questions, score, percentage, is_completed, created_at)
    VALUES 
      ('${attemptId1}', '${studentA1}', '${examAssignId}', NOW(), NOW(), 600, 2, 2, 100.0, TRUE, NOW()),
      ('${attemptId2}', '${studentA2}', '${examAssignId}', NOW(), NOW(), 600, 2, 1, 50.0, TRUE, NOW())
    ON CONFLICT (id) DO NOTHING;
  `);

  console.log('✓ Multi-tenant fixtures seeded successfully.');

  // ---------------------------------------------------------------------------
  // 5. TEST SUITE: Teacher Authorization & Cross-Tenant / Subject Guards
  // ---------------------------------------------------------------------------
  console.log('\n[5/8] Running Security & Authorization Test Cases...');
  let passCount = 0;
  let failCount = 0;

  async function testExpect(desc, fn) {
    try {
      await fn();
      console.log(`  ✓ PASS: ${desc}`);
      passCount++;
    } catch (e) {
      console.error(`  ✗ FAIL: ${desc} ->`, e.message);
      failCount++;
    }
  }

  // 5.1 Teacher allowed in own class and subject
  let draftPhysicsAssignId;
  await testExpect('Teacher creates draft assignment in authorized class + subject', async () => {
    await asUser(teacherA);
    const res = await db.query(`
      SELECT public.create_learning_assignment(
        '${schoolAId}',
        '${classA}',
        'physics_g12',
        NULL,
        'Mechanics Problem Set 1',
        'Complete all questions before Friday.',
        'targetedPractice',
        30,
        NOW() + INTERVAL '3 days',
        true
      ) AS assign_id;
    `);
    draftPhysicsAssignId = res.rows[0].assign_id;
    if (!draftPhysicsAssignId) throw new Error('Failed to return assignment ID');
  });

  // 5.2 Cross-school creation denied
  await testExpect('Cross-school creation is DENIED', async () => {
    await asUser(teacherA);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolBId}',
          '${classB}',
          'physics_g12',
          NULL,
          'Unauthorized Cross School Assignment',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected cross-school assignment creation to fail!');
  });

  // 5.3 Wrong classroom denied
  await testExpect('Wrong classroom creation is DENIED', async () => {
    await asUser(teacherA);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolAId}',
          '${classC}',
          'physics_g12',
          NULL,
          'Wrong Class Assignment',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected wrong-class assignment creation to fail!');
  });

  // 5.4 Wrong subject denied
  await testExpect('Wrong subject creation is DENIED', async () => {
    await asUser(teacherA);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolAId}',
          '${classA}',
          'chemistry_g12',
          NULL,
          'Chemistry Assignment by Physics Teacher',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected wrong-subject assignment creation to fail!');
  });

  // 5.5 Math exact variant isolation: Natural teacher assigning Social Math is DENIED
  await testExpect('Math Natural teacher creating Social Math assignment is DENIED', async () => {
    await asUser(teacherA);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolAId}',
          '${classA}',
          'math_g12',
          'socialScience',
          'Social Math by Natural Teacher',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected Math variant mismatch to fail!');
  });

  // 5.6 Inactive teacher membership denied
  await testExpect('Inactive teacher membership is DENIED', async () => {
    await asUser(teacherRevoked);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolAId}',
          '${classA}',
          'physics_g12',
          NULL,
          'Assignment by Inactive Teacher',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected inactive teacher to fail!');
  });

  // 5.7 Suspended school denied
  await testExpect('Teacher in suspended school is DENIED', async () => {
    await asUser(teacherSuspended);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolSuspended}',
          '${classA}',
          'physics_g12',
          NULL,
          'Assignment in Suspended School',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected suspended school action to fail!');
  });

  // 5.8 Student mutation denied
  await testExpect('Student cannot create learning assignments', async () => {
    await asUser(studentA1);
    let threw = false;
    try {
      await db.query(`
        SELECT public.create_learning_assignment(
          '${schoolAId}',
          '${classA}',
          'physics_g12',
          NULL,
          'Student forged assignment',
          'Instructions',
          'targetedPractice'
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected student assignment creation to fail!');
  });

  // ---------------------------------------------------------------------------
  // 6. TEST SUITE: Atomic Publication, Rollback, Idempotency & Snapshotting
  // ---------------------------------------------------------------------------
  console.log('\n[6/8] Running Publication Transaction & Immutability Tests...');

  // 6.1 Publishing with unverified question ROLLS BACK atomically
  await testExpect('Publishing with unverified question rolls back atomically', async () => {
    await asUser(teacherA);
    let threw = false;
    try {
      await db.query(`
        SELECT public.publish_learning_assignment(
          '${draftPhysicsAssignId}',
          ARRAY['${qPhys1}', '${qUnverified}']::UUID[]
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected publication with unverified question to fail!');

    // Verify assignment remains in draft status and 0 questions/recipients stored
    const check = await db.query(`
      SELECT status, total_questions, content_hash
      FROM public.learning_assignments
      WHERE id = '${draftPhysicsAssignId}';
    `);
    if (check.rows[0].status !== 'draft') throw new Error('Assignment status altered despite rollback!');
    
    const qCount = await db.query(`SELECT COUNT(*) FROM public.learning_assignment_questions WHERE assignment_id = '${draftPhysicsAssignId}';`);
    if (parseInt(qCount.rows[0].count) !== 0) throw new Error('Partial questions leaked into table!');
  });

  // 6.2 Publishing with cross-variant question ROLLS BACK (Natural Math assignment with Social question)
  let draftMathAssignId;
  await testExpect('Natural Math assignment cannot include Social Math questions', async () => {
    await asUser(teacherA);
    const createRes = await db.query(`
      SELECT public.create_learning_assignment(
        '${schoolAId}',
        '${classA}',
        'math_g12',
        'naturalScience',
        'Calculus & Vectors Drill',
        'Instructions',
        'targetedPractice'
      ) AS assign_id;
    `);
    draftMathAssignId = createRes.rows[0].assign_id;

    let threw = false;
    try {
      await db.query(`
        SELECT public.publish_learning_assignment(
          '${draftMathAssignId}',
          ARRAY['${qMathNat1}', '${qMathSoc1}']::UUID[]
        );
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected cross-variant Math question to fail publication!');
  });

  // 6.3 Successful atomic publication with frozen questions and classroom recipient snapshot
  let pubPhysicsResult;
  await testExpect('Publishing verified assignment freezes questions and resolves roster', async () => {
    await asUser(teacherA);
    const res = await db.query(`
      SELECT public.publish_learning_assignment(
        '${draftPhysicsAssignId}',
        ARRAY['${qPhys1}', '${qPhys2}']::UUID[]
      ) AS result;
    `);
    pubPhysicsResult = res.rows[0].result;
    if (!pubPhysicsResult.success) throw new Error('Publication did not report success');
    if (pubPhysicsResult.total_questions !== 2) throw new Error('Expected 2 total questions');
    if (pubPhysicsResult.recipient_count !== 2) throw new Error('Expected 2 classroom recipients (studentA1, studentA2)');
    if (!pubPhysicsResult.content_hash) throw new Error('Expected content_hash to be populated');
  });

  // 6.4 Idempotent publication test: calling publish again returns idempotent success
  await testExpect('Publishing an already-published assignment is strictly idempotent', async () => {
    await asUser(teacherA);
    const res = await db.query(`
      SELECT public.publish_learning_assignment(
        '${draftPhysicsAssignId}',
        ARRAY['${qPhys1}', '${qPhys2}']::UUID[]
      ) AS result;
    `);
    const rePub = res.rows[0].result;
    if (!rePub.idempotent) throw new Error('Expected idempotent flag on second publish call');

    // Confirm recipient count didn't duplicate
    const countRes = await db.query(`
      SELECT COUNT(*) FROM public.learning_assignment_recipients WHERE assignment_id = '${draftPhysicsAssignId}';
    `);
    if (parseInt(countRes.rows[0].count) !== 2) throw new Error('Duplicate recipient rows created!');
  });

  // ---------------------------------------------------------------------------
  // 7. TEST SUITE: Student Inbox, Access Control & Submission Sync
  // ---------------------------------------------------------------------------
  console.log('\n[7/8] Running Student Inbox, Offline Sync & Progress Tests...');

  // 7.1 Student A1 can read own assignment in inbox
  await testExpect('Student A1 sees published assignment in Assignment Inbox', async () => {
    await asUser(studentA1);
    const inbox = await db.query(`
      SELECT * FROM public.get_student_assignments();
    `);
    if (inbox.rows.length !== 1) throw new Error(`Expected 1 assignment in inbox, got ${inbox.rows.length}`);
    const item = inbox.rows[0];
    if (item.assignment_id !== draftPhysicsAssignId) throw new Error('Assignment ID mismatch');
    if (item.student_status !== 'assigned') throw new Error(`Expected status assigned, got ${item.student_status}`);
    if (item.total_questions !== 2) throw new Error('Expected total_questions = 2');
  });

  // 7.2 Student A1 fetches detail and receives question IDs in frozen order
  await testExpect('Student A1 retrieves assignment detail with question sequence', async () => {
    await asUser(studentA1);
    const detailRes = await db.query(`
      SELECT public.get_student_assignment_detail('${draftPhysicsAssignId}') AS detail;
    `);
    const detail = detailRes.rows[0].detail;
    if (detail.assignment_id !== draftPhysicsAssignId) throw new Error('Assignment ID mismatch');
    if (!Array.isArray(detail.question_ids) || detail.question_ids.length !== 2) {
      throw new Error('Expected 2 ordered question IDs');
    }
    if (detail.question_ids[0] !== qPhys1 || detail.question_ids[1] !== qPhys2) {
      throw new Error('Question sequence does not match frozen publication order');
    }
  });

  // 7.3 Student B1 (different school/class) cannot access Student A1 assignment detail
  await testExpect('Student B1 (unauthorized class) CANNOT read Student A1 assignment', async () => {
    await asUser(studentB1);
    let threw = false;
    try {
      await db.query(`
        SELECT public.get_student_assignment_detail('${draftPhysicsAssignId}');
      `);
    } catch (e) {
      threw = true;
    }
    if (!threw) throw new Error('Expected Student B1 access to be denied!');
  });

  // 7.4 Student A1 submits assignment attempt
  await testExpect('Student A1 submits completed assignment', async () => {
    await asUser(studentA1);
    const subRes = await db.query(`
      SELECT public.submit_student_assignment(
        '${draftPhysicsAssignId}',
        '${attemptId1}',
        2,
        100.0,
        NOW()
      ) AS res;
    `);
    const res = subRes.rows[0].res;
    if (!res.success) throw new Error('Submission link reported failure');
    if (res.status !== 'submitted') throw new Error(`Expected status submitted, got ${res.status}`);
  });

  // 7.5 Duplicate student submission is idempotent
  await testExpect('Duplicate submission sync is strictly idempotent', async () => {
    await asUser(studentA1);
    const subRes = await db.query(`
      SELECT public.submit_student_assignment(
        '${draftPhysicsAssignId}',
        '${attemptId1}',
        2,
        100.0,
        NOW()
      ) AS res;
    `);
    const res = subRes.rows[0].res;
    if (!res.idempotent) throw new Error('Expected idempotent true on re-submission');
  });

  // 7.6 Late submission policy test
  await testExpect('Submission after deadline with allow_late_submission = true marks status "late"', async () => {
    await asUser(studentA2);
    // Student A2 submits 5 days after due date
    const subRes = await db.query(`
      SELECT public.submit_student_assignment(
        '${draftPhysicsAssignId}',
        '${attemptId2}',
        1,
        50.0,
        NOW() + INTERVAL '10 days'
      ) AS res;
    `);
    const res = subRes.rows[0].res;
    if (res.status !== 'late') throw new Error(`Expected late status, got ${res.status}`);
  });

  // 7.7 Teacher views assignment progress view
  await testExpect('Teacher retrieves assignment progress summary', async () => {
    await asUser(teacherA);
    const prog = await db.query(`
      SELECT * FROM public.get_teacher_assignment_progress('${draftPhysicsAssignId}');
    `);
    if (prog.rows.length !== 2) throw new Error(`Expected 2 progress rows, got ${prog.rows.length}`);
    const s1 = prog.rows.find(r => r.student_user_id === studentA1);
    const s2 = prog.rows.find(r => r.student_user_id === studentA2);
    if (s1.status !== 'submitted' || s1.score !== 2) throw new Error('Student A1 progress mismatch');
    if (s2.status !== 'late' || s2.score !== 1) throw new Error('Student A2 progress mismatch');
  });

  // 7.8 School Admin has read-only oversight
  await testExpect('School Admin has read-only oversight of teacher assignments', async () => {
    await asUser(adminA);
    const adminAssignments = await db.query(`
      SELECT * FROM public.get_teacher_assignments('${schoolAId}');
    `);
    if (adminAssignments.rows.length < 1) throw new Error('School Admin could not read school assignments');
  });

  // ---------------------------------------------------------------------------
  // 8. TEST SUITE: Academic Interventions & P7 Needs Attention Link
  // ---------------------------------------------------------------------------
  console.log('\n[8/8] Running Student Interventions & P7 Integration Tests...');

  let interventionId;
  await testExpect('Teacher creates academic intervention linked to attention reasons', async () => {
    await asUser(teacherA);
    const intRes = await db.query(`
      SELECT public.create_student_intervention(
        '${schoolAId}',
        '${classA}',
        'physics_g12',
        NULL,
        '${studentA1}',
        'p7Attention',
        '["lowRecentAccuracy", "highMistakeCount"]'::jsonb,
        'high',
        'targetedPractice',
        '${draftPhysicsAssignId}',
        'Student struggled with uniform acceleration concepts. Assigned remedial practice.'
      ) AS int_id;
    `);
    interventionId = intRes.rows[0].int_id;
    if (!interventionId) throw new Error('Failed to return intervention ID');
  });

  await testExpect('Teacher retrieves intervention list with attention snapshots', async () => {
    await asUser(teacherA);
    const list = await db.query(`
      SELECT * FROM public.get_teacher_interventions('${schoolAId}');
    `);
    if (list.rows.length !== 1) throw new Error(`Expected 1 intervention, got ${list.rows.length}`);
    const item = list.rows[0];
    if (item.intervention_id !== interventionId) throw new Error('Intervention ID mismatch');
    if (item.severity_at_creation !== 'high') throw new Error('Severity snapshot mismatch');
    if (item.linked_assignment_id !== draftPhysicsAssignId) throw new Error('Linked assignment mismatch');
  });

  await testExpect('Teacher completes intervention without falsifying academic resolution', async () => {
    await asUser(teacherA);
    const comp = await db.query(`
      SELECT public.complete_student_intervention('${interventionId}') AS completed;
    `);
    if (!comp.rows[0].completed) throw new Error('Expected complete_student_intervention to return true');

    const check = await db.query(`
      SELECT status, completed_at FROM public.student_interventions WHERE id = '${interventionId}';
    `);
    if (check.rows[0].status !== 'completed' || !check.rows[0].completed_at) {
      throw new Error('Intervention status or completed_at not updated');
    }
  });

  console.log('\n=============================================================================');
  console.log(`P9 POSTGRESQL VERIFICATION COMPLETE: ${passCount} PASSED, ${failCount} FAILED`);
  console.log('=============================================================================');

  if (failCount > 0) {
    process.exit(1);
  }
}

run().catch(e => {
  console.error('Fatal execution error:', e);
  process.exit(1);
});
