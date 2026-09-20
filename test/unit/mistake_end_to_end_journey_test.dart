import 'package:drift/native.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';
import 'package:fidel_learn/features/mistakes/domain/services/mistake_outcome_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftMistakeRepository repository;
  late MistakeOutcomeService outcomeService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftMistakeRepository(db: db);
    outcomeService = MistakeOutcomeService(repository);
  });

  tearDown(() async {
    await db.close();
  });

  test('Section 57 & 58: Full End-to-End Student Mistake Journey & App Restart',
      () async {
    const userId = 'student_e2e_1';

    // Step 1: Normal Practice Session (Attempt 1)
    // Q1: Wrong, Q2: Wrong, Q3: Correct
    const attempt1 = 'attempt_normal_1';

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q1',
      subjectId: 'math',
      attemptId: attempt1,
      selectedChoiceId: 'c_b',
      isCorrect: false,
      sessionType: ExamType.practice,
    );

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q2',
      subjectId: 'math',
      attemptId: attempt1,
      selectedChoiceId: 'c_c',
      isCorrect: false,
      sessionType: ExamType.practice,
    );

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q3',
      subjectId: 'math',
      attemptId: attempt1,
      selectedChoiceId: 'c_a',
      isCorrect: true,
      sessionType: ExamType.practice,
    );

    // Verify Notebook contains Q1 and Q2 only
    final initialMistakes = await repository.getMistakes(userId);
    expect(initialMistakes.length, equals(2));
    final qIds = initialMistakes.map((m) => m.questionId).toSet();
    expect(qIds, equals({'q1', 'q2'}));

    var counts = await repository.getMistakeCounts(userId);
    expect(counts.total, equals(2));
    expect(counts.needsReview, equals(2));
    expect(counts.improving, equals(0));
    expect(counts.mastered, equals(0));

    // Step 2: Practice My Mistakes - Attempt 2
    // Q1: Correct, Q2: Wrong
    const attempt2 = 'attempt_retry_2';

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q1',
      subjectId: 'math',
      attemptId: attempt2,
      selectedChoiceId: 'c_a',
      isCorrect: true,
      sessionType: ExamType.mistakeRetry,
    );

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q2',
      subjectId: 'math',
      attemptId: attempt2,
      selectedChoiceId: 'c_d',
      isCorrect: false,
      sessionType: ExamType.mistakeRetry,
    );

    final q1AfterRetry1 =
        await repository.getMistakeById(userId: userId, questionId: 'q1');
    final q2AfterRetry1 =
        await repository.getMistakeById(userId: userId, questionId: 'q2');

    expect(q1AfterRetry1!.masteryStatus, equals(MasteryStatus.improving));
    expect(q1AfterRetry1.correctRetryCount, equals(1));
    expect(q2AfterRetry1!.masteryStatus, equals(MasteryStatus.needsReview));
    expect(q2AfterRetry1.correctRetryCount, equals(0));

    counts = await repository.getMistakeCounts(userId);
    expect(counts.total, equals(2));
    expect(counts.needsReview, equals(1));
    expect(counts.improving, equals(1));
    expect(counts.mastered, equals(0));

    // Step 3: Practice My Mistakes - Attempt 3
    // Q1: Correct again on different attempt
    const attempt3 = 'attempt_retry_3';

    await outcomeService.processQuestionOutcome(
      userId: userId,
      questionId: 'q1',
      subjectId: 'math',
      attemptId: attempt3,
      selectedChoiceId: 'c_a',
      isCorrect: true,
      sessionType: ExamType.mistakeRetry,
    );

    final q1AfterRetry2 =
        await repository.getMistakeById(userId: userId, questionId: 'q1');
    expect(q1AfterRetry2!.masteryStatus, equals(MasteryStatus.mastered));
    expect(q1AfterRetry2.correctRetryCount, equals(2));

    counts = await repository.getMistakeCounts(userId);
    expect(counts.total, equals(2));
    expect(counts.needsReview, equals(1));
    expect(counts.improving, equals(0));
    expect(counts.mastered, equals(1));

    // Step 4: Section 58 App Restart / Reload State
    // Close repository/db and reload with new instance pointing to same DB
    // To simulate persistent DB across app restarts, we query with another repository instance
    final restartRepo = DriftMistakeRepository(db: db);
    final reloadedMistakes = await restartRepo.getMistakes(userId);
    expect(reloadedMistakes.length, equals(2));

    final reloadedCounts = await restartRepo.getMistakeCounts(userId);
    expect(reloadedCounts.total, equals(2));
    expect(reloadedCounts.needsReview, equals(1));
    expect(reloadedCounts.improving, equals(0));
    expect(reloadedCounts.mastered, equals(1));

    final reloadedQ1 =
        await restartRepo.getMistakeById(userId: userId, questionId: 'q1');
    expect(reloadedQ1!.masteryStatus, equals(MasteryStatus.mastered));
    expect(reloadedQ1.correctRetryCount, equals(2));
  });
}
