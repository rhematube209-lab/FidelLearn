import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';
import 'package:fidel_learn/features/mistakes/domain/services/mistake_outcome_service.dart';

void main() {
  late AppDatabase db;
  late DriftMistakeRepository mistakeRepo;
  late MistakeOutcomeService outcomeService;

  setUp(() {
    db = AppDatabase.inMemory();
    mistakeRepo = DriftMistakeRepository(db: db);
    outcomeService = MistakeOutcomeService(mistakeRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('Mistake Notebook & Mastery Engine Deterministic Transitions', () {
    const userId = 'student_test_1';
    const questionId = 'q_math_101';
    const subjectId = 'math_g12';

    test(
        '1. First wrong answer on Attempt A sets needsReview, missCount=1, correctRetryCount=0',
        () async {
      await outcomeService.processQuestionOutcome(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        unitId: 'unit_1',
        topicId: 'topic_calculus',
        attemptId: 'att_a',
        selectedChoiceId: 'choice_b', // incorrect
        isCorrect: false,
        sessionType: ExamType.practice,
      );

      final mistake = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );

      expect(mistake, isNotNull);
      expect(mistake!.missCount, equals(1));
      expect(mistake.retryCount, equals(0));
      expect(mistake.correctRetryCount, equals(0));
      expect(mistake.masteryStatus, equals(MasteryStatus.needsReview));
      expect(mistake.lastAttemptId, equals('att_a'));
      expect(mistake.lastSelectedChoiceId, equals('choice_b'));
      expect(mistake.firstMissedAt, isNotNull);
      expect(mistake.lastMissedAt, equals(mistake.firstMissedAt));
    });

    test(
        '2. Critical Idempotency: Re-processing Attempt A does not increment missCount',
        () async {
      // First submission
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
        selectedChoiceId: 'choice_b',
      );

      final initial = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(initial!.missCount, equals(1));

      // Accidental second submission with same attemptId (e.g., immediate feedback + exam submit)
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
        selectedChoiceId: 'choice_b',
      );

      final afterDuplicate = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(afterDuplicate!.missCount, equals(1));
    });

    test(
        '3. Same question wrong on NEW Attempt B increments missCount and preserves firstMissedAt',
        () async {
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
        selectedChoiceId: 'choice_b',
      );

      final first = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      final initialFirstMissed = first!.firstMissedAt;

      // New attempt later
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_b',
        selectedChoiceId: 'choice_c',
      );

      final second = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(second!.missCount, equals(2));
      expect(second.correctRetryCount, equals(0));
      expect(second.masteryStatus, equals(MasteryStatus.needsReview));
      expect(second.firstMissedAt, equals(initialFirstMissed));
      expect(second.lastAttemptId, equals('att_b'));
    });

    test('4. First correct retry on Attempt C transitions to Improving',
        () async {
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
        selectedChoiceId: 'choice_b',
      );

      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_c',
        selectedChoiceId: 'choice_a', // correct
      );

      final mistake = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(mistake!.retryCount, equals(1));
      expect(mistake.correctRetryCount, equals(1));
      expect(mistake.masteryStatus, equals(MasteryStatus.improving));
      expect(mistake.lastAttemptId, equals('att_c'));
    });

    test(
        '5. Critical Retry Idempotency: Attempt C processed twice does NOT transition to Mastered',
        () async {
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
      );

      // Attempt C - correct
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_c',
      );

      final firstCheck = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(firstCheck!.masteryStatus, equals(MasteryStatus.improving));
      expect(firstCheck.correctRetryCount, equals(1));

      // Attempt C re-submitted or processed again by accident
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_c',
      );

      final secondCheck = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      // MUST STILL BE IMPROVING! Cannot earn Mastered in a single attempt
      expect(secondCheck!.masteryStatus, equals(MasteryStatus.improving));
      expect(secondCheck.correctRetryCount, equals(1));
      expect(secondCheck.retryCount, equals(1));
    });

    test(
        '6. Second correct retry on distinct Attempt D transitions to Mastered',
        () async {
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
      );

      // Attempt C: 1st correct retry -> Improving
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_c',
      );

      // Attempt D: 2nd correct retry -> Mastered
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_d',
      );

      final mistake = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(mistake!.retryCount, equals(2));
      expect(mistake.correctRetryCount, equals(2));
      expect(mistake.masteryStatus, equals(MasteryStatus.mastered));
      expect(mistake.isMastered, isTrue);
      expect(mistake.lastAttemptId, equals('att_d'));
    });

    test(
        '7. Wrong after Mastered on Attempt E demotes to Needs Review and resets correctRetryCount=0',
        () async {
      // 1. Initial miss
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_a',
      );

      // 2. First correct
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_c',
      );

      // 3. Second correct -> Mastered
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
        attemptId: 'att_d',
      );

      final mastered = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(mastered!.masteryStatus, equals(MasteryStatus.mastered));

      // 4. Student misses it again on Attempt E
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_e',
      );

      final demoted = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(demoted!.masteryStatus, equals(MasteryStatus.needsReview));
      expect(demoted.correctRetryCount, equals(0));
      expect(demoted.missCount, equals(2));
      expect(demoted.isMastered, isFalse);
    });

    test(
        '8. MistakeCounts aggregates Total, NeedsReview, Improving, and Mastered accurately',
        () async {
      // Create Q1: Needs Review
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: 'q1',
        subjectId: subjectId,
        attemptId: 'att_1',
      );

      // Create Q2: Improving
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: 'q2',
        subjectId: subjectId,
        attemptId: 'att_1',
      );
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: 'q2',
        isCorrect: true,
        attemptId: 'att_2',
      );

      // Create Q3: Mastered
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: 'q3',
        subjectId: subjectId,
        attemptId: 'att_1',
      );
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: 'q3',
        isCorrect: true,
        attemptId: 'att_2',
      );
      await mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: 'q3',
        isCorrect: true,
        attemptId: 'att_3',
      );

      final counts = await mistakeRepo.getMistakeCounts(userId);
      expect(counts.total, equals(3));
      expect(counts.needsReview, equals(1));
      expect(counts.improving, equals(1));
      expect(counts.mastered, equals(1));
    });

    test(
        '9. Section 30: Adaptive Practice correct answer advances mastery for question in notebook',
        () async {
      // Missed initially in exam
      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_mock_1',
      );

      // Student later encounters this question in Adaptive Practice and gets it right
      await outcomeService.processQuestionOutcome(
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        attemptId: 'att_adaptive_2',
        selectedChoiceId: 'choice_correct',
        isCorrect: true,
        sessionType: ExamType.customBuilder,
      );

      final mistake = await mistakeRepo.getMistakeById(
        userId: userId,
        questionId: questionId,
      );
      expect(mistake!.masteryStatus, equals(MasteryStatus.improving));
      expect(mistake.correctRetryCount, equals(1));
    });
  });
}
