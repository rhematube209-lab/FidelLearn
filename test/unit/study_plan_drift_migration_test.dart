import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_study_plan_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Study Plan Schema Migration (v3 -> v4) and Legacy Backfill', () {
    test(
        'Upgrading from schema v3 to v4 preserves legacy sessions and correctly backfills assessmentStructure and examVariant',
        () async {
      final db = AppDatabase.inMemory();

      // Drop any existing tables to simulate a clean v3 environment
      await db.customStatement('DROP TABLE IF EXISTS db_study_plan_sessions');
      await db.customStatement('DROP TABLE IF EXISTS db_study_plans');

      // 1. Create v3 schema for db_study_plans
      await db.customStatement('''
        CREATE TABLE db_study_plans (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          plan_date INTEGER NOT NULL,
          target_minutes INTEGER NOT NULL DEFAULT 45,
          estimated_minutes INTEGER NOT NULL DEFAULT 45,
          status TEXT NOT NULL DEFAULT 'not_started',
          algorithm_version TEXT NOT NULL DEFAULT 'adaptive_planner_v1',
          generated_at INTEGER NOT NULL
        )
      ''');

      // 2. Create v3 schema for db_study_plan_sessions (without exam_variant, assessment_structure, content_domain, skill)
      await db.customStatement('''
        CREATE TABLE db_study_plan_sessions (
          id TEXT NOT NULL PRIMARY KEY,
          plan_id TEXT NOT NULL,
          subject_id TEXT NOT NULL,
          unit_id TEXT,
          topic_id TEXT,
          session_type TEXT NOT NULL,
          title_en TEXT NOT NULL,
          title_am TEXT NOT NULL,
          question_target INTEGER NOT NULL DEFAULT 10,
          estimated_minutes INTEGER NOT NULL DEFAULT 15,
          priority_score REAL NOT NULL DEFAULT 0.0,
          reason_code TEXT NOT NULL,
          reason_detail_en TEXT NOT NULL,
          reason_detail_am TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'not_started',
          question_ids_json TEXT NOT NULL DEFAULT '[]',
          completed_at INTEGER,
          time_spent_seconds INTEGER NOT NULL DEFAULT 0,
          score_percentage REAL
        )
      ''');

      final planDate = DateTime(2026, 9, 20);
      final planEpoch = planDate.millisecondsSinceEpoch ~/ 1000;

      // Insert legacy v3 plan
      await db.customStatement('''
        INSERT INTO db_study_plans (
          id, user_id, plan_date, target_minutes, estimated_minutes,
          status, algorithm_version, generated_at
        ) VALUES (
          'plan_legacy_001', 'student_v3_legacy', $planEpoch, 45, 40,
          'notStarted', 'adaptive_planner_v1', $planEpoch
        )
      ''');

      // Insert legacy v3 sessions (Aptitude, English, Physics, History, Math)
      await db.customStatement('''
        INSERT INTO db_study_plan_sessions (
          id, plan_id, subject_id, unit_id, topic_id, session_type,
          title_en, title_am, question_target, estimated_minutes,
          priority_score, reason_code, reason_detail_en, reason_detail_am,
          status, question_ids_json, time_spent_seconds
        ) VALUES
        ('sess_legacy_apt', 'plan_legacy_001', 'aptitude_g12', NULL, NULL, 'mixedReview',
         'Aptitude: Data Interpretation', 'አፕቲቲዩድ፦ የመረጃ ትንተና', 10, 15, 80.0,
         'weakTopic', 'Low accuracy', 'ዝቅተኛ ውጤት', 'notStarted', '["q_apt_1", "q_apt_2"]', 0),

        ('sess_legacy_eng', 'plan_legacy_001', 'english_g12', 'unit_1', 'topic_vocab', 'curriculumCoverage',
         'English: Vocabulary', 'እንግሊዝኛ፦ ቃላት', 8, 12, 65.0,
         'newCurriculum', 'Unpracticed', 'ያልተሰራ', 'notStarted', '["q_eng_1"]', 0),

        ('sess_legacy_phy', 'plan_legacy_001', 'physics_g12', 'u_em', 't_mag', 'weakTopicPractice',
         'Physics: Magnetism', 'ፊዚክስ፦ ማግኔቲዝም', 10, 15, 78.0,
         'weakTopic', 'Needs review', 'ክለሳ ያስፈልጋል', 'notStarted', '["q_phy_1"]', 0),

        ('sess_legacy_hist', 'plan_legacy_001', 'history_g12', 'u_eth', 't_modern', 'curriculumCoverage',
         'History: Modern Ethiopia', 'ታሪክ፦ ዘመናዊ ኢትዮጵያ', 8, 10, 60.0,
         'newCurriculum', 'Core topic', 'ዋና ርዕስ', 'notStarted', '["q_hist_1"]', 0),

        ('sess_legacy_math', 'plan_legacy_001', 'math_g12', 'u_calc', 't_der', 'mistakeRetry',
         'Math: Derivatives', 'ሒሳብ፦ ዲሪቫቲቭ', 6, 10, 85.0,
         'mistakeReview', 'Previous mistakes', 'ቀደምት ስህተቶች', 'notStarted', '["q_math_1"]', 0)
      ''');

      // Execute migration from schema v3 to v4
      final migrator = db.createMigrator();
      await db.migration.onUpgrade(migrator, 3, 4);

      // Verify at the raw SQL column level that columns were added and backfilled
      final rawSessions = await db
          .customSelect(
            'SELECT id, subject_id, assessment_structure, exam_variant FROM db_study_plan_sessions ORDER BY id',
          )
          .get();

      expect(rawSessions.length, equals(5));

      final aptRow = rawSessions
          .firstWhere((r) => r.read<String>('id') == 'sess_legacy_apt');
      expect(aptRow.read<String>('assessment_structure'), equals('skillBased'));
      expect(aptRow.read<String>('exam_variant'), equals('shared'));

      final engRow = rawSessions
          .firstWhere((r) => r.read<String>('id') == 'sess_legacy_eng');
      expect(engRow.read<String>('assessment_structure'), equals('mixed'));
      expect(engRow.read<String>('exam_variant'), equals('shared'));

      final phyRow = rawSessions
          .firstWhere((r) => r.read<String>('id') == 'sess_legacy_phy');
      expect(phyRow.read<String>('assessment_structure'), equals('curriculum'));
      expect(phyRow.read<String>('exam_variant'), equals('naturalScience'));

      final histRow = rawSessions
          .firstWhere((r) => r.read<String>('id') == 'sess_legacy_hist');
      expect(
          histRow.read<String>('assessment_structure'), equals('curriculum'));
      expect(histRow.read<String>('exam_variant'), equals('socialScience'));

      final mathRow = rawSessions
          .firstWhere((r) => r.read<String>('id') == 'sess_legacy_math');
      expect(
          mathRow.read<String>('assessment_structure'), equals('curriculum'));
      expect(mathRow.read<String?>('exam_variant'),
          isNull); // Ambiguous legacy math safely left null

      // Now verify full repository retrieval with domain model mapping
      final repo = DriftStudyPlanRepository(db: db);
      final retrievedPlan =
          await repo.getStudyPlan('student_v3_legacy', date: planDate);

      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.id, equals('plan_legacy_001'));
      expect(retrievedPlan.sessions.length, equals(5));

      // Check legacy English session domain mapping
      final domainEng =
          retrievedPlan.sessions.firstWhere((s) => s.id == 'sess_legacy_eng');
      expect(domainEng.assessmentStructure, equals(AssessmentStructure.mixed));
      expect(domainEng.examVariant, equals(ExamVariantCode.shared));
      expect(domainEng.questionIds, equals(['q_eng_1']));

      // Check legacy Aptitude session domain mapping
      final domainApt =
          retrievedPlan.sessions.firstWhere((s) => s.id == 'sess_legacy_apt');
      expect(domainApt.assessmentStructure,
          equals(AssessmentStructure.skillBased));
      expect(domainApt.examVariant, equals(ExamVariantCode.shared));

      // Check legacy Physics session domain mapping
      final domainPhy =
          retrievedPlan.sessions.firstWhere((s) => s.id == 'sess_legacy_phy');
      expect(domainPhy.assessmentStructure,
          equals(AssessmentStructure.curriculum));
      expect(domainPhy.examVariant, equals(ExamVariantCode.naturalScience));

      // Check legacy History session domain mapping
      final domainHist =
          retrievedPlan.sessions.firstWhere((s) => s.id == 'sess_legacy_hist');
      expect(domainHist.assessmentStructure,
          equals(AssessmentStructure.curriculum));
      expect(domainHist.examVariant, equals(ExamVariantCode.socialScience));

      // Check legacy Math session domain mapping
      final domainMath =
          retrievedPlan.sessions.firstWhere((s) => s.id == 'sess_legacy_math');
      expect(domainMath.assessmentStructure,
          equals(AssessmentStructure.curriculum));
      expect(domainMath.examVariant, isNull);

      // Verify that saving a new v4 plan with explicit examVariant and assessmentStructure works cleanly alongside migrated data
      final v4PlanDate = DateTime(2026, 9, 21);
      final v4Plan = StudyPlan(
        id: 'plan_v4_002',
        userId: 'student_v3_legacy',
        planDate: v4PlanDate,
        targetMinutes: 30,
        estimatedMinutes: 28,
        sessions: const [
          StudyPlanSession(
            id: 'sess_v4_math_nat',
            planId: 'plan_v4_002',
            subjectId: 'math_g12',
            examVariant: ExamVariantCode.naturalScience,
            assessmentStructure: AssessmentStructure.curriculum,
            contentDomain: 'Analysis and Calculus',
            sessionType: StudySessionType.weakTopicPractice,
            titleEn: 'Math (Natural): Integration',
            titleAm: 'ሒሳብ (የተፈጥሮ ሳይንስ)፦ ኢንቴግሬሽን',
            questionTarget: 10,
            estimatedMinutes: 15,
            priorityScore: 90.0,
            reasonCode: RecommendationReasonCode.weakTopic,
            reasonDetailEn: 'Targeted reinforcement',
            reasonDetailAm: 'የተመረጠ ማጠናከሪያ',
            status: SessionCompletionStatus.notStarted,
            questionIds: ['q_nat_1', 'q_nat_2'],
          ),
        ],
        status: SessionCompletionStatus.notStarted,
        algorithmVersion: kAdaptivePlannerAlgorithmVersion,
        generatedAt: v4PlanDate,
      );

      await repo.saveStudyPlan(v4Plan);

      final retrievedV4 =
          await repo.getStudyPlan('student_v3_legacy', date: v4PlanDate);
      expect(retrievedV4, isNotNull);
      expect(retrievedV4!.id, equals('plan_v4_002'));
      expect(retrievedV4.algorithmVersion,
          equals(kAdaptivePlannerAlgorithmVersion));
      expect(retrievedV4.sessions.first.examVariant,
          equals(ExamVariantCode.naturalScience));
      expect(retrievedV4.sessions.first.contentDomain,
          equals('Analysis and Calculus'));

      await db.close();
    });

    test(
        'Upgrading directly from schema v1 to v6 succeeds without duplicate column error and is idempotent',
        () async {
      final db = AppDatabase.inMemory();

      // Drop any existing tables to simulate a clean v1 environment
      await db.customStatement('DROP TABLE IF EXISTS db_study_plan_sessions');
      await db.customStatement('DROP TABLE IF EXISTS db_study_plans');
      await db.customStatement('DROP TABLE IF EXISTS db_mistakes');
      await db.customStatement('DROP TABLE IF EXISTS db_question_mastery');
      await db
          .customStatement('DROP TABLE IF EXISTS db_learning_target_mastery');
      await db.customStatement('DROP TABLE IF EXISTS db_review_events');

      // 1. Create v1 schema for db_mistakes (original minimal table)
      await db.customStatement('''
        CREATE TABLE db_mistakes (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          subject_id TEXT NOT NULL,
          mistake_count INTEGER NOT NULL DEFAULT 1,
          is_mastered INTEGER NOT NULL DEFAULT 0,
          last_failed_at INTEGER,
          mastered_at INTEGER
        )
      ''');

      // 2. Execute migration from schema v1 to v6
      await db.migration.onUpgrade(db.createMigrator(), 1, 6);

      // Verify tables and columns exist
      final sessionCols = await db
          .customSelect('PRAGMA table_info("db_study_plan_sessions")')
          .get();
      final sessionColNames =
          sessionCols.map((r) => r.read<String>('name')).toSet();
      expect(
          sessionColNames,
          containsAll([
            'exam_variant',
            'assessment_structure',
            'content_domain',
            'skill'
          ]));

      final masteryCols = await db
          .customSelect('PRAGMA table_info("db_question_mastery")')
          .get();
      final masteryColNames =
          masteryCols.map((r) => r.read<String>('name')).toSet();
      expect(masteryColNames, contains('evidence_source'));

      // 3. Test idempotency: re-running onUpgrade must not throw duplicate column errors
      await db.migration.onUpgrade(db.createMigrator(), 1, 6);

      await db.close();
    });
  });
}
