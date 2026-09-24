import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_mastery_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/domain/services/adaptive_study_planner.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_engine_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  late AppDatabase db;
  late DriftMasteryRepository masteryRepo;
  late MasteryEngineService masteryEngine;
  const planner = AdaptiveStudyPlanner();

  setUp(() {
    db = AppDatabase.inMemory();
    masteryRepo = DriftMasteryRepository(db: db);
    masteryEngine = MasteryEngineService(masteryRepo: masteryRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'Complete Offline Mastery and Spaced Repetition Lifecycle (Learn -> Master -> Due -> Retain -> Lapse -> Recover)',
      () async {
    const userId = 'student_offline_1';
    final startTime = DateTime(2026, 4, 1, 9, 0);

    const question = Question(
      id: 'phy_circuits_42',
      grade: 12,
      stream: 'natural',
      subjectId: 'physics_g12',
      unitId: 'unit_electricity',
      topicId: 'series_circuits',
      questionTextEn: 'Calculate the total resistance of resistors in series.',
      difficulty: 'medium',
      verificationStatus: VerificationStatus.verified,
      sourceName: 'ESSLCE 2016',
      contentVersion: 1,
      choices: [],
      explanation:
          Explanation(solutionTextEn: 'Add values directly: R = R1 + R2.'),
    );

    const subject = Subject(
      id: 'physics_g12',
      code: 'PHYS12',
      nameEn: 'Physics',
      nameAm: 'ፊዚክስ',
      grade: 12,
      stream: 'natural',
      scope: SubjectScope.streamExam,
      sortOrder: 4,
    );

    // ==========================================================
    // STEP 1: First attempt (Correct) -> Moves to learning state
    // ==========================================================
    final day1Record = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: true,
      attemptId: 'att_day1',
      eventTime: startTime,
    );

    expect(day1Record.masteryState, equals(MasteryState.learning));
    expect(day1Record.attemptCount, equals(1));
    expect(day1Record.correctCount, equals(1));
    expect(day1Record.consecutiveCorrect, equals(1));
    expect(day1Record.nextReviewAt,
        equals(startTime.add(const Duration(days: 1))));

    // ==========================================================
    // STEP 2: Repeated practice -> Advances to Improving
    // ==========================================================
    final day2Time = startTime.add(const Duration(hours: 12));
    final day2Record = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: true,
      attemptId: 'att_day2',
      eventTime: day2Time,
    );

    expect(day2Record.masteryState, equals(MasteryState.improving));
    expect(day2Record.attemptCount, equals(2));
    expect(day2Record.consecutiveCorrect, equals(2));

    // ==========================================================
    // STEP 3: Spaced retrieval on Day 4 (with temporal spacing) -> Advances to Mastered!
    // ==========================================================
    final day4Time = startTime.add(const Duration(days: 3));
    final day4Record = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: true,
      attemptId: 'att_day4',
      eventTime: day4Time,
    );

    expect(day4Record.masteryState, equals(MasteryState.mastered));
    expect(day4Record.attemptCount, equals(3));
    expect(day4Record.consecutiveCorrect, equals(3));
    expect(day4Record.stability, greaterThan(2.0));
    final scheduledReviewDate = day4Record.nextReviewAt!;
    expect(scheduledReviewDate.isAfter(day4Time), isTrue);

    // ==========================================================
    // STEP 4: Time advances past scheduled review date -> Becomes Due!
    // ==========================================================
    final reviewDueTime = scheduledReviewDate.add(const Duration(hours: 1));
    final dueReviews = await masteryRepo.getDueQuestionReviews(
      userId,
      asOf: reviewDueTime,
    );

    expect(dueReviews.length, equals(1));
    expect(dueReviews.first.questionId, equals('phy_circuits_42'));

    // ==========================================================
    // STEP 4: Adaptive Study Planner includes due review in Daily Plan
    // ==========================================================
    final allQuestions = [question];
    final plan = planner.generateDailyPlan(
      userId: userId,
      grade: 12,
      stream: 'natural',
      settings: PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: startTime.add(const Duration(days: 60)),
      ),
      completedAttempts: const [],
      unmasteredMistakes: const [],
      availableQuestions: allQuestions,
      allSubjects: [subject],
      unitsBySubject: {
        'physics_g12': [
          const Unit(
              id: 'unit_electricity',
              subjectId: 'physics_g12',
              unitNumber: 1,
              titleEn: 'Electricity',
              titleAm: 'ኤሌክትሪክ'),
        ],
      },
      topicsByUnit: {
        'unit_electricity': [
          const Topic(
              id: 'series_circuits',
              unitId: 'unit_electricity',
              topicNumber: 1,
              titleEn: 'Series Circuits',
              titleAm: 'ተከታታይ ዑደቶች'),
        ],
      },
      installedSubjectIds: {'physics_g12'},
      questionMasteryRecords: dueReviews,
      currentDate: reviewDueTime,
    );

    final spacedSession = plan.sessions.firstWhere(
      (s) => s.sessionType == StudySessionType.masteryMaintenance,
    );
    expect(spacedSession, isNotNull);
    expect(spacedSession.reasonCode,
        equals(RecommendationReasonCode.masteryReviewDue));
    expect(spacedSession.questionIds, contains('phy_circuits_42'));

    // ==========================================================
    // STEP 5: Successful Spaced Review -> Stability expands
    // ==========================================================
    final reviewRetainedRecord = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: true,
      attemptId: 'att_review_success',
      eventTime: reviewDueTime,
      responseTimeSeconds: 15,
    );

    expect(reviewRetainedRecord.masteryState, equals(MasteryState.mastered));
    expect(reviewRetainedRecord.reviewCount, equals(4));
    expect(reviewRetainedRecord.stability, greaterThan(day4Record.stability));
    expect(reviewRetainedRecord.nextReviewAt!.isAfter(reviewDueTime), isTrue);

    // ==========================================================
    // STEP 6: Lapse occurs (Incorrect answer on later test) -> Demotes to Relearning
    // ==========================================================
    final lapseTime =
        reviewRetainedRecord.nextReviewAt!.add(const Duration(days: 1));
    final lapsedRecord = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: false,
      attemptId: 'att_lapse',
      eventTime: lapseTime,
    );

    expect(lapsedRecord.masteryState, equals(MasteryState.relearning));
    expect(lapsedRecord.consecutiveCorrect, equals(0));
    expect(lapsedRecord.lapseCount, equals(1));
    // Interval contracts to 1 day for rapid recovery
    expect(lapsedRecord.nextReviewAt,
        equals(lapseTime.add(const Duration(days: 1))));

    // ==========================================================
    // STEP 7: Relearning completed successfully -> Restores Mastered
    // ==========================================================
    final relearnTime = lapseTime.add(const Duration(days: 1));
    final recoveredRecord = await masteryEngine.processQuestionOutcome(
      userId: userId,
      question: question,
      isCorrect: true,
      attemptId: 'att_relearn_success',
      eventTime: relearnTime,
    );

    expect(recoveredRecord.masteryState, equals(MasteryState.mastered));
    expect(recoveredRecord.nextReviewAt!.isAfter(relearnTime), isTrue);

    // ==========================================================
    // STEP 8: Verify Review Event Audit Trail in SQLite
    // ==========================================================
    final events = await masteryRepo.getReviewEvents(userId);
    expect(events.length, equals(6));
    // Most recent event is the relearning recovery
    expect(events.first.newState, equals(MasteryState.mastered));
    expect(events.first.isCorrect, isTrue);
  });
}
