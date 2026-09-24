import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_mastery_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_aggregation_service.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_engine_service.dart';
import 'package:fidel_learn/features/progress/domain/services/spaced_repetition_scheduler.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Priority 4 Hardening & Freeze Tests', () {
    late AppDatabase db;
    late DriftMasteryRepository repo;
    late SpacedRepetitionScheduler scheduler;
    late MasteryAggregationService aggregationService;
    late MasteryEngineService engine;

    setUp(() {
      db = AppDatabase.inMemory();
      repo = DriftMasteryRepository(db: db);
      scheduler = const SpacedRepetitionScheduler();
      aggregationService = const MasteryAggregationService();
      engine = MasteryEngineService(
        masteryRepo: repo,
        scheduler: scheduler,
        aggregationService: aggregationService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    // =========================================================================
    // 1. MASTERY RECORD IDENTITY & COLLISION SAFETY (Sections 2-10)
    // =========================================================================
    group('1. Identity & Collision Invariants', () {
      test(
          'Target Collision Test: Natural Math vs Social Math with same target name ("limits") never overwrite or collide',
          () async {
        const userId = 'student_1';
        const rawTarget = 'limits';

        // 1. Build Natural Math target record
        final natKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.naturalScience,
          rawTarget: rawTarget,
        );
        expect(natKey, equals('math_g12_naturalScience_limits'));

        final natRecord = LearningTargetMasteryRecord(
          id: '${userId}_$natKey',
          userId: userId,
          targetKey: natKey,
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.naturalScience,
          titleEn: 'Limits and Continuity',
          titleAm: 'ወሰኖች እና ቀጣይነት',
          masteryState: MasteryState.mastered,
          accuracyPercentage: 90.0,
          totalAttempts: 10,
          masteredQuestionCount: 5,
          coveredQuestionCount: 5,
          totalAvailableQuestions: 5,
          updatedAt: DateTime.utc(2026, 9, 24, 10, 0),
        );

        // 2. Build Social Math target record with identical raw target name
        final socKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.socialScience,
          rawTarget: rawTarget,
        );
        expect(socKey, equals('math_g12_socialScience_limits'));

        final socRecord = LearningTargetMasteryRecord(
          id: '${userId}_$socKey',
          userId: userId,
          targetKey: socKey,
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.socialScience,
          titleEn: 'Limits and Continuity',
          titleAm: 'ወሰኖች እና ቀጣይነት',
          masteryState: MasteryState.learning,
          accuracyPercentage: 40.0,
          totalAttempts: 4,
          masteredQuestionCount: 1,
          coveredQuestionCount: 4,
          totalAvailableQuestions: 5,
          updatedAt: DateTime.utc(2026, 9, 24, 10, 30),
        );

        // Save both records to SQLite
        await repo.saveTargetMastery(natRecord);
        await repo.saveTargetMastery(socRecord);

        // Retrieve specifically by target key
        final loadedNat = await repo.getTargetMastery(userId, natKey);
        final loadedSoc = await repo.getTargetMastery(userId, socKey);

        expect(loadedNat, isNotNull);
        expect(loadedSoc, isNotNull);
        expect(loadedNat!.id, isNot(equals(loadedSoc!.id)));
        expect(loadedNat.masteryState, equals(MasteryState.mastered));
        expect(loadedSoc.masteryState, equals(MasteryState.learning));
        expect(loadedNat.accuracyPercentage, equals(90.0));
        expect(loadedSoc.accuracyPercentage, equals(40.0));

        // Query by exam variant
        final natList = await repo.getTargetMasteryList(
          userId,
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.naturalScience,
        );
        final socList = await repo.getTargetMasteryList(
          userId,
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.socialScience,
        );

        expect(natList.length, equals(1));
        expect(socList.length, equals(1));
        expect(
            natList.first.targetKey, equals('math_g12_naturalScience_limits'));
        expect(
            socList.first.targetKey, equals('math_g12_socialScience_limits'));
      });

      test(
          'English Domain Target and Scholastic Aptitude Skill Target remain globally distinct without collision',
          () {
        final engKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'english_g12',
          assessmentStructure: AssessmentStructure.mixed,
          contentDomain: 'reading_comprehension',
          rawTarget: 'reading_comprehension',
        );
        expect(engKey, equals('english_g12_shared_reading_comprehension'));

        final aptKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'aptitude_g12',
          assessmentStructure: AssessmentStructure.skillBased,
          contentDomain: 'quantitative_reasoning',
          skill: 'data_interpretation',
          rawTarget: 'data_interpretation',
        );
        expect(
            aptKey,
            equals(
                'aptitude_g12_shared_quantitative_reasoning_data_interpretation'));

        expect(engKey, isNot(equals(aptKey)));
      });

      test(
          'Same raw topic name across different subjects (e.g. "vectors" in Physics vs Math) produces distinct target keys',
          () {
        final physKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'physics_g12',
          examVariant: ExamVariantCode.naturalScience,
          topicId: 'vectors',
          rawTarget: 'vectors',
        );
        final mathKey = MasteryAggregationService.buildCanonicalTargetKey(
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.naturalScience,
          topicId: 'vectors',
          rawTarget: 'vectors',
        );

        expect(physKey, equals('physics_g12_naturalScience_vectors'));
        expect(mathKey, equals('math_g12_naturalScience_vectors'));
        expect(physKey, isNot(equals(mathKey)));
      });

      test(
          'Review event preserves and recovers subjectId and examVariant unambiguously',
          () async {
        final now = DateTime.utc(2026, 9, 24, 12, 0);
        final event = ReviewEventRecord(
          id: 'rev_evt_001',
          userId: 'usr_math_nat',
          questionId: 'math_nat_q12',
          targetKey: 'math_g12_naturalScience_calculus',
          subjectId: 'math_g12',
          examVariant: ExamVariantCode.naturalScience,
          reviewedAt: now,
          scheduledAt: now,
          isCorrect: true,
          previousState: MasteryState.improving,
          newState: MasteryState.mastered,
          previousIntervalDays: 2,
          newIntervalDays: 5,
        );

        await repo.recordReviewEvent(event);

        final loaded = await repo.getReviewEvents('usr_math_nat');
        expect(loaded.length, equals(1));
        expect(loaded.first.subjectId, equals('math_g12'));
        expect(
            loaded.first.examVariant, equals(ExamVariantCode.naturalScience));
        expect(
            loaded.first.targetKey, equals('math_g12_naturalScience_calculus'));
      });
    });

    // =========================================================================
    // 2. DIFFICULTY & STABILITY NUMERIC BOUNDS AND SAFETY (Sections 11-18)
    // =========================================================================
    group('2. Difficulty & Stability Numeric Bounds', () {
      final baseRecord = QuestionMasteryRecord(
        id: 'usr_q1',
        userId: 'usr',
        questionId: 'q1',
        subjectId: 'physics_g12',
        masteryState: MasteryState.learning,
        attemptCount: 1,
        correctCount: 1,
        consecutiveCorrect: 1,
        stability: 1.0,
        difficulty: 2.0,
        updatedAt: DateTime.utc(2026, 9, 24, 10, 0),
      );

      test('Difficulty normalization clamps within [1.0, 3.0]', () {
        expect(SpacedRepetitionScheduler.normalizeDifficulty(1.0), equals(1.0));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(3.0), equals(3.0));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(0.5), equals(1.0));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(4.5), equals(3.0));
      });

      test(
          'Difficulty normalization handles 0.0, negative, NaN, and Infinity safely',
          () {
        expect(SpacedRepetitionScheduler.normalizeDifficulty(0.0),
            equals(SpacedRepetitionScheduler.defaultDifficulty));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(-3.5),
            equals(SpacedRepetitionScheduler.defaultDifficulty));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(double.nan),
            equals(SpacedRepetitionScheduler.defaultDifficulty));
        expect(SpacedRepetitionScheduler.normalizeDifficulty(double.infinity),
            equals(SpacedRepetitionScheduler.defaultDifficulty));
        expect(
            SpacedRepetitionScheduler.normalizeDifficulty(
                double.negativeInfinity),
            equals(SpacedRepetitionScheduler.defaultDifficulty));
      });

      test('Stability normalization clamps and safely handles NaN / Infinity',
          () {
        expect(SpacedRepetitionScheduler.normalizeStability(5.0), equals(5.0));
        expect(SpacedRepetitionScheduler.normalizeStability(0.5), equals(1.0));
        expect(
            SpacedRepetitionScheduler.normalizeStability(120.0), equals(90.0));
        expect(SpacedRepetitionScheduler.normalizeStability(double.nan),
            equals(SpacedRepetitionScheduler.defaultStability));
        expect(SpacedRepetitionScheduler.normalizeStability(double.infinity),
            equals(SpacedRepetitionScheduler.defaultStability));
      });

      test(
          'Scheduler evaluation with difficulty = 0.0 or negative never crashes or divides by zero',
          () {
        final corruptRecord = baseRecord.copyWith(
          difficulty: 0.0,
          stability: -5.0,
        );

        final result = scheduler.evaluateOutcome(
          currentRecord: corruptRecord,
          isCorrect: true,
          eventTime: DateTime.utc(2026, 9, 24, 12, 0),
        );

        expect(result.nextDifficulty, greaterThanOrEqualTo(1.0));
        expect(result.nextDifficulty, lessThanOrEqualTo(3.0));
        expect(result.nextStability, greaterThanOrEqualTo(1.0));
        expect(result.nextStability.isFinite, isTrue);
        expect(result.nextIntervalDays, greaterThanOrEqualTo(1));
        expect(result.nextReviewAt.isAfter(DateTime.utc(2026, 9, 24, 12, 0)),
            isTrue);
      });

      test(
          'Scheduler evaluation with difficulty = NaN or Infinity remains finite and safe',
          () {
        final nanRecord = baseRecord.copyWith(
          difficulty: double.nan,
          stability: double.infinity,
        );

        final result = scheduler.evaluateOutcome(
          currentRecord: nanRecord,
          isCorrect: true,
          eventTime: DateTime.utc(2026, 9, 24, 12, 0),
        );

        expect(result.nextDifficulty.isFinite, isTrue);
        expect(result.nextStability.isFinite, isTrue);
        expect(result.nextIntervalDays, greaterThanOrEqualTo(1));
      });

      test('Review interval is strictly >= 1 day and nextReviewAt > eventTime',
          () {
        final now = DateTime.utc(2026, 9, 24, 14, 0);
        final result = scheduler.evaluateOutcome(
          currentRecord: baseRecord,
          isCorrect: false, // Lapse
          eventTime: now,
          targetExamDate:
              now.add(const Duration(days: 2)), // Final review phase
        );

        expect(result.nextIntervalDays, greaterThanOrEqualTo(1));
        expect(result.nextReviewAt.isAfter(now), isTrue);
      });
    });

    // =========================================================================
    // 3. LEGACY MASTERY MIGRATION & PROVENANCE (Sections 19-30)
    // =========================================================================
    group('3. Legacy Mastery Provenance & Transition', () {
      test(
          'Initial migrated question record carries legacyMigration provenance',
          () async {
        final record = QuestionMasteryRecord(
          id: 'usr_legacy_q1',
          userId: 'usr_legacy',
          questionId: 'q_legacy_01',
          subjectId: 'chemistry_g12',
          masteryState: MasteryState.mastered,
          evidenceSource: EvidenceSource.legacyMigration,
          attemptCount: 2,
          correctCount: 2,
          stability: 3.0,
          updatedAt: DateTime.utc(2026, 9, 24, 10, 0),
        );

        await repo.saveQuestionMastery(record);

        final loaded =
            await repo.getQuestionMastery('usr_legacy', 'q_legacy_01');
        expect(loaded, isNotNull);
        expect(loaded!.evidenceSource, equals(EvidenceSource.legacyMigration));
        expect(loaded.masteryState, equals(MasteryState.mastered));
      });

      test(
          'First real native review transitions legacyMigration record to native provenance',
          () async {
        const userId = 'usr_migration_student';
        const question = Question(
          id: 'q_chem_periodic',
          grade: 12,
          stream: 'natural',
          subjectId: 'chemistry_g12',
          unitId: 'unit_1',
          topicId: 'periodic_trends',
          questionTextEn: 'Which element has highest electronegativity?',
          questionTextAm: 'ከፍተኛ ኤሌክትሮኔጋቲቪቲ ያለው የትኛው ነው?',
          choices: [],
          difficulty: 'medium',
          verificationStatus: VerificationStatus.verified,
          sourceName: 'seed',
          contentVersion: 1,
          explanation:
              Explanation(solutionTextEn: 'Fluorine has the highest value.'),
        );

        // Seed initial legacy record in SQLite
        final legacyRecord = QuestionMasteryRecord(
          id: '${userId}_${question.id}',
          userId: userId,
          questionId: question.id,
          subjectId: question.subjectId,
          masteryState: MasteryState.mastered,
          evidenceSource: EvidenceSource.legacyMigration,
          attemptCount: 2,
          correctCount: 2,
          consecutiveCorrect: 2,
          stability: 3.0,
          nextReviewAt: DateTime.utc(2026, 9, 24, 8, 0),
          updatedAt: DateTime.utc(2026, 9, 21, 8, 0),
        );
        await repo.saveQuestionMastery(legacyRecord);

        // Verify initial state has legacy provenance
        final preCheck = await repo.getQuestionMastery(userId, question.id);
        expect(
            preCheck!.evidenceSource, equals(EvidenceSource.legacyMigration));

        // Execute first real review via MasteryEngineService
        final reviewTime = DateTime.utc(2026, 9, 24, 9, 0);
        final postReviewRecord = await engine.processQuestionOutcome(
          userId: userId,
          question: question,
          isCorrect: true,
          attemptId: 'att_real_review_01',
          eventTime: reviewTime,
        );

        // Verification: record successfully transitioned to native evidence!
        expect(postReviewRecord.evidenceSource, equals(EvidenceSource.native));
        expect(postReviewRecord.masteryState, equals(MasteryState.mastered));
        expect(postReviewRecord.reviewCount, equals(1));

        final loadedDb = await repo.getQuestionMastery(userId, question.id);
        expect(loadedDb!.evidenceSource, equals(EvidenceSource.native));
      });
    });

    // =========================================================================
    // 4. DUE-REVIEW QUERY & INDEX VERIFICATION (Sections 31-36)
    // =========================================================================
    group('4. Due-Review Query Verification', () {
      test('Due-review query is user-scoped and correctly bounded by date',
          () async {
        final now = DateTime.utc(2026, 9, 24, 12, 0);

        // 1. User 1 due item
        await repo.saveQuestionMastery(QuestionMasteryRecord(
          id: 'u1_q1',
          userId: 'u1',
          questionId: 'q1',
          subjectId: 'physics_g12',
          nextReviewAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now,
        ));

        // 2. User 1 future (not yet due) item
        await repo.saveQuestionMastery(QuestionMasteryRecord(
          id: 'u1_q2',
          userId: 'u1',
          questionId: 'q2',
          subjectId: 'physics_g12',
          nextReviewAt: now.add(const Duration(days: 2)),
          updatedAt: now,
        ));

        // 3. User 2 due item (should not leak to user 1)
        await repo.saveQuestionMastery(QuestionMasteryRecord(
          id: 'u2_q3',
          userId: 'u2',
          questionId: 'q3',
          subjectId: 'physics_g12',
          nextReviewAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now,
        ));

        final u1Due = await repo.getDueQuestionReviews('u1', asOf: now);
        expect(u1Due.length, equals(1));
        expect(u1Due.first.questionId, equals('q1'));

        final u2Due = await repo.getDueQuestionReviews('u2', asOf: now);
        expect(u2Due.length, equals(1));
        expect(u2Due.first.questionId, equals('q3'));
      });
    });
  });
}
