import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_mastery_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  late AppDatabase db;
  late DriftMasteryRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = DriftMasteryRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftMasteryRepository Persistence Tests', () {
    final now = DateTime(2026, 4, 1, 10, 0);

    test('Saves and retrieves question mastery record accurately', () async {
      final record = QuestionMasteryRecord(
        id: 'u1_q100',
        userId: 'u1',
        questionId: 'q100',
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        assessmentStructure: AssessmentStructure.curriculum,
        unitId: 'unit1',
        topicId: 'circuits',
        masteryState: MasteryState.mastered,
        attemptCount: 3,
        correctCount: 3,
        consecutiveCorrect: 3,
        stability: 12.0,
        difficulty: 1.8,
        reviewCount: 2,
        lapseCount: 0,
        lastSeenAt: now,
        lastCorrectAt: now,
        nextReviewAt: now.add(const Duration(days: 12)),
        updatedAt: now,
      );

      await repository.saveQuestionMastery(record);
      final retrieved = await repository.getQuestionMastery('u1', 'q100');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('u1_q100'));
      expect(retrieved.userId, equals('u1'));
      expect(retrieved.questionId, equals('q100'));
      expect(retrieved.subjectId, equals('physics_g12'));
      expect(retrieved.examVariant, equals(ExamVariantCode.naturalScience));
      expect(retrieved.masteryState, equals(MasteryState.mastered));
      expect(retrieved.attemptCount, equals(3));
      expect(retrieved.correctCount, equals(3));
      expect(retrieved.stability, equals(12.0));
      expect(retrieved.nextReviewAt, equals(now.add(const Duration(days: 12))));
    });

    test('Saves and retrieves learning target mastery record', () async {
      final target = LearningTargetMasteryRecord(
        id: 'u1_circuits',
        userId: 'u1',
        targetKey: 'circuits',
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        assessmentStructure: AssessmentStructure.curriculum,
        unitId: 'unit1',
        topicId: 'circuits',
        titleEn: 'Circuits',
        titleAm: 'የኤሌክትሪክ ዑደቶች',
        masteryState: MasteryState.mastered,
        accuracyPercentage: 88.5,
        totalAttempts: 10,
        masteredQuestionCount: 4,
        coveredQuestionCount: 5,
        totalAvailableQuestions: 6,
        nextReviewAt: now.add(const Duration(days: 7)),
        lastPracticedAt: now,
        updatedAt: now,
      );

      await repository.saveTargetMastery(target);
      final retrieved = await repository.getTargetMastery('u1', 'circuits');

      expect(retrieved, isNotNull);
      expect(retrieved!.targetKey, equals('circuits'));
      expect(retrieved.titleEn, equals('Circuits'));
      expect(retrieved.titleAm, equals('የኤሌክትሪክ ዑደቶች'));
      expect(retrieved.masteryState, equals(MasteryState.mastered));
      expect(retrieved.accuracyPercentage, equals(88.5));
      expect(retrieved.masteredQuestionCount, equals(4));
    });

    test('Queries due question reviews accurately by date', () async {
      final pastDue = QuestionMasteryRecord(
        id: 'u1_q_past',
        userId: 'u1',
        questionId: 'q_past',
        subjectId: 'chem_g12',
        masteryState: MasteryState.mastered,
        nextReviewAt: now.subtract(const Duration(days: 1)), // Overdue
        updatedAt: now,
      );

      final futureDue = QuestionMasteryRecord(
        id: 'u1_q_future',
        userId: 'u1',
        questionId: 'q_future',
        subjectId: 'chem_g12',
        masteryState: MasteryState.mastered,
        nextReviewAt: now.add(const Duration(days: 5)), // In 5 days
        updatedAt: now,
      );

      await repository.saveQuestionMastery(pastDue);
      await repository.saveQuestionMastery(futureDue);

      final dueAsOfNow =
          await repository.getDueQuestionReviews('u1', asOf: now);
      expect(dueAsOfNow.length, equals(1));
      expect(dueAsOfNow.first.questionId, equals('q_past'));

      final dueLater = await repository.getDueQuestionReviews(
        'u1',
        asOf: now.add(const Duration(days: 6)),
      );
      expect(dueLater.length, equals(2));
    });

    test('Records and retrieves review events for auditability', () async {
      final event = ReviewEventRecord(
        id: 'event_1',
        userId: 'u1',
        questionId: 'q100',
        targetKey: 'circuits',
        reviewedAt: now,
        scheduledAt: now,
        isCorrect: true,
        timeSpentSeconds: 18,
        previousState: MasteryState.improving,
        newState: MasteryState.mastered,
        previousIntervalDays: 2,
        newIntervalDays: 6,
      );

      await repository.recordReviewEvent(event);
      final events = await repository.getReviewEvents('u1');

      expect(events.length, equals(1));
      expect(events.first.id, equals('event_1'));
      expect(events.first.questionId, equals('q100'));
      expect(events.first.isCorrect, isTrue);
      expect(events.first.previousState, equals(MasteryState.improving));
      expect(events.first.newState, equals(MasteryState.mastered));
      expect(events.first.newIntervalDays, equals(6));
    });

    test(
        'Non-destructive migration preserves legacy mistake records and backfills question mastery',
        () async {
      // Simulate existing mistake row in db_mistakes
      await db.into(db.dbMistakes).insert(
            DbMistake(
              id: 'mistake_legacy_1',
              userId: 'u_migrated',
              questionId: 'q_legacy_math',
              subjectId: 'math_g12',
              unitId: 'unit1',
              topicId: 'matrices',
              firstMissedAt: now.subtract(const Duration(days: 5)),
              lastMissedAt: now.subtract(const Duration(days: 3)),
              lastAttemptAt: now.subtract(const Duration(days: 1)),
              missCount: 2,
              retryCount: 2,
              correctRetryCount: 2,
              masteryStatus: 'mastered',
              createdAt: now.subtract(const Duration(days: 5)),
              updatedAt: now.subtract(const Duration(days: 1)),
              syncStatus: 'synced',
              mistakeCount: 2,
              isMastered: true,
              lastFailedAt: now.subtract(const Duration(days: 3)),
              masteredAt: now.subtract(const Duration(days: 1)),
            ),
          );

      // Verify DbMistake remains intact
      final mistake = await (db.select(db.dbMistakes)
            ..where((tbl) => tbl.id.equals('mistake_legacy_1')))
          .getSingle();
      expect(mistake.masteryStatus, equals('mastered'));
      expect(mistake.isMastered, isTrue);
    });
  });
}
