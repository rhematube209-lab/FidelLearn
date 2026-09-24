import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/progress/domain/services/spaced_repetition_scheduler.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_aggregation_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('SpacedRepetitionScheduler Tests (fidel_spaced_v1.0)', () {
    const scheduler = SpacedRepetitionScheduler();
    final baseTime = DateTime(2026, 4, 1, 10, 0);

    test('Initial correct answer moves newItem to learning/improving', () {
      final initial = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'physics_g12',
        masteryState: MasteryState.newItem,
        updatedAt: baseTime,
      );

      final result = scheduler.evaluateOutcome(
        currentRecord: initial,
        isCorrect: true,
        eventTime: baseTime,
      );

      expect(result.nextState, equals(MasteryState.learning));
      expect(result.consecutiveCorrect, equals(1));
      expect(result.nextIntervalDays, equals(1));
      expect(
          result.nextReviewAt, equals(baseTime.add(const Duration(days: 1))));
    });

    test('Second consecutive correct answer transitions to improving', () {
      final improvingRecord = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'physics_g12',
        masteryState: MasteryState.learning,
        consecutiveCorrect: 1,
        lastCorrectAt: baseTime,
        updatedAt: baseTime,
      );

      final result = scheduler.evaluateOutcome(
        currentRecord: improvingRecord,
        isCorrect: true,
        eventTime: baseTime.add(const Duration(hours: 2)), // Same day
      );

      expect(result.nextState, equals(MasteryState.improving));
      expect(result.consecutiveCorrect, equals(2));
      expect(result.nextIntervalDays, equals(2));
    });

    test(
        'Temporal spacing requirement: distinct day retrieval elevates improving to mastered',
        () {
      final improvingRecord = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'physics_g12',
        masteryState: MasteryState.improving,
        consecutiveCorrect: 1,
        stability: 2.0,
        lastCorrectAt: baseTime,
        updatedAt: baseTime,
      );

      final nextDayTime =
          baseTime.add(const Duration(days: 2)); // 48 hours later
      final result = scheduler.evaluateOutcome(
        currentRecord: improvingRecord,
        isCorrect: true,
        eventTime: nextDayTime,
      );

      expect(result.nextState, equals(MasteryState.mastered));
      expect(result.consecutiveCorrect, equals(2));
      expect(result.nextIntervalDays, greaterThanOrEqualTo(3));
      expect(result.nextReviewAt,
          equals(nextDayTime.add(Duration(days: result.nextIntervalDays))));
    });

    test(
        'Lapse on mastered item contracts interval to 1 day and demotes to relearning',
        () {
      final masteredRecord = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'chemistry_g12',
        masteryState: MasteryState.mastered,
        stability: 14.0,
        consecutiveCorrect: 4,
        reviewCount: 3,
        lapseCount: 0,
        updatedAt: baseTime,
      );

      final result = scheduler.evaluateOutcome(
        currentRecord: masteredRecord,
        isCorrect: false,
        eventTime: baseTime,
      );

      expect(result.nextState, equals(MasteryState.relearning));
      expect(result.nextIntervalDays, equals(1));
      expect(result.consecutiveCorrect, equals(0));
      expect(result.lapseCount, equals(1));
      // Stability decayed by 50%
      expect(result.nextStability, equals(7.0));
      expect(
          result.nextReviewAt, equals(baseTime.add(const Duration(days: 1))));
    });

    test('Relearning item returns to mastered after successful retrieval', () {
      final relearningRecord = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'chemistry_g12',
        masteryState: MasteryState.relearning,
        stability: 7.0,
        consecutiveCorrect: 1,
        lastCorrectAt: baseTime,
        updatedAt: baseTime,
      );

      final nextDay = baseTime.add(const Duration(days: 1));
      final result = scheduler.evaluateOutcome(
        currentRecord: relearningRecord,
        isCorrect: true,
        eventTime: nextDay,
      );

      expect(result.nextState, equals(MasteryState.mastered));
      expect(result.consecutiveCorrect, equals(2));
      expect(result.nextIntervalDays, greaterThanOrEqualTo(3));
    });

    test('Algorithm determinism: identical inputs produce identical scheduling',
        () {
      final record = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'biology_g12',
        masteryState: MasteryState.improving,
        consecutiveCorrect: 2,
        stability: 3.5,
        difficulty: 2.0,
        updatedAt: baseTime,
      );

      final result1 = scheduler.evaluateOutcome(
        currentRecord: record,
        isCorrect: true,
        eventTime: baseTime.add(const Duration(days: 2)),
      );
      final result2 = scheduler.evaluateOutcome(
        currentRecord: record,
        isCorrect: true,
        eventTime: baseTime.add(const Duration(days: 2)),
      );

      expect(result1.nextState, equals(result2.nextState));
      expect(result1.nextIntervalDays, equals(result2.nextIntervalDays));
      expect(result1.nextReviewAt, equals(result2.nextReviewAt));
      expect(result1.nextStability, equals(result2.nextStability));
    });

    test(
        'Exam-date capping: never schedules reviews past the national exam date',
        () {
      final examDate = baseTime
          .add(const Duration(days: 5)); // 5 days until exam (final review)

      final masteredRecord = QuestionMasteryRecord(
        id: 'user1_q1',
        userId: 'user1',
        questionId: 'q1',
        subjectId: 'physics_g12',
        masteryState: MasteryState.mastered,
        stability: 20.0, // Would normally schedule 20 days out
        updatedAt: baseTime,
      );

      final result = scheduler.evaluateOutcome(
        currentRecord: masteredRecord,
        isCorrect: true,
        eventTime: baseTime,
        targetExamDate: examDate,
      );

      // Must be capped before exam date: max 4 days (daysUntilExam - 1)
      expect(result.nextIntervalDays, lessThan(5));
      expect(result.nextReviewAt.isBefore(examDate), isTrue);
    });
  });

  group('MasteryAggregationService Tests (Curriculum, English, Aptitude)', () {
    const aggregationService = MasteryAggregationService();
    final now = DateTime(2026, 4, 1, 10, 0);

    test('Aggregates curriculum topic with mixed question masteries', () {
      final qRecords = [
        QuestionMasteryRecord(
          id: 'u1_q1',
          userId: 'u1',
          questionId: 'q1',
          subjectId: 'physics_g12',
          masteryState: MasteryState.mastered,
          attemptCount: 3,
          correctCount: 3,
          lastSeenAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
        ),
        QuestionMasteryRecord(
          id: 'u1_q2',
          userId: 'u1',
          questionId: 'q2',
          subjectId: 'physics_g12',
          masteryState: MasteryState.mastered,
          attemptCount: 2,
          correctCount: 2,
          lastSeenAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
        ),
        QuestionMasteryRecord(
          id: 'u1_q3',
          userId: 'u1',
          questionId: 'q3',
          subjectId: 'physics_g12',
          masteryState: MasteryState.improving,
          attemptCount: 2,
          correctCount: 1,
          lastSeenAt: now,
          updatedAt: now,
        ),
      ];

      final questions = [
        const Question(
          id: 'q1',
          grade: 12,
          stream: 'natural',
          subjectId: 'physics_g12',
          unitId: 'unit1',
          topicId: 'circuits',
          questionTextEn: 'Q1',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.verified,
          sourceName: 'Exam',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Sol'),
        ),
        const Question(
          id: 'q2',
          grade: 12,
          stream: 'natural',
          subjectId: 'physics_g12',
          unitId: 'unit1',
          topicId: 'circuits',
          questionTextEn: 'Q2',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.verified,
          sourceName: 'Exam',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Sol'),
        ),
        const Question(
          id: 'q3',
          grade: 12,
          stream: 'natural',
          subjectId: 'physics_g12',
          unitId: 'unit1',
          topicId: 'circuits',
          questionTextEn: 'Q3',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.verified,
          sourceName: 'Exam',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Sol'),
        ),
      ];

      final target = aggregationService.aggregateTargetMastery(
        userId: 'u1',
        targetKey: 'circuits',
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        assessmentStructure: AssessmentStructure.curriculum,
        unitId: 'unit1',
        topicId: 'circuits',
        titleEn: 'Circuits',
        titleAm: 'የኤሌክትሪክ ዑደቶች',
        targetQuestionRecords: qRecords,
        targetAvailableQuestions: questions,
        currentTime: now,
      );

      // 2 mastered out of 3, accuracy = 6/7 = 85.7% -> Mastered
      expect(target.masteryState, equals(MasteryState.mastered));
      expect(target.masteredQuestionCount, equals(2));
      expect(target.coveredQuestionCount, equals(3));
      expect(target.totalAvailableQuestions, equals(3));
      expect(target.accuracyPercentage, greaterThan(80.0));
      expect(target.coverageRatio, equals(1.0));
    });

    test('English Mixed Reading Comprehension target aggregation', () {
      final qRecords = [
        QuestionMasteryRecord(
          id: 'u1_eng1',
          userId: 'u1',
          questionId: 'eng1',
          subjectId: 'english_g12',
          masteryState: MasteryState.learning,
          attemptCount: 1,
          correctCount: 0,
          updatedAt: now,
        ),
      ];

      final target = aggregationService.aggregateTargetMastery(
        userId: 'u1',
        targetKey: 'reading_inference',
        subjectId: 'english_g12',
        examVariant: ExamVariantCode.shared,
        assessmentStructure: AssessmentStructure.mixed,
        contentDomain: 'Reading Comprehension',
        skill: 'Inference',
        titleEn: 'English: Inference',
        titleAm: 'እንግሊዝኛ፦ ፍንጭ ማውጣት',
        targetQuestionRecords: qRecords,
        targetAvailableQuestions: const [],
        currentTime: now,
      );

      expect(target.masteryState, equals(MasteryState.learning));
      expect(target.contentDomain, equals('Reading Comprehension'));
      expect(target.skill, equals('Inference'));
    });

    test('Scholastic Aptitude skill-based target without fake units', () {
      final qRecords = [
        QuestionMasteryRecord(
          id: 'u1_apt1',
          userId: 'u1',
          questionId: 'apt1',
          subjectId: 'aptitude_g12',
          masteryState: MasteryState.mastered,
          attemptCount: 2,
          correctCount: 2,
          updatedAt: now,
        ),
        QuestionMasteryRecord(
          id: 'u1_apt2',
          userId: 'u1',
          questionId: 'apt2',
          subjectId: 'aptitude_g12',
          masteryState: MasteryState.mastered,
          attemptCount: 2,
          correctCount: 2,
          updatedAt: now,
        ),
      ];

      final target = aggregationService.aggregateTargetMastery(
        userId: 'u1',
        targetKey: 'quant_data_interpretation',
        subjectId: 'aptitude_g12',
        examVariant: ExamVariantCode.shared,
        assessmentStructure: AssessmentStructure.skillBased,
        unitId: null, // No textbook unit
        topicId: null, // No textbook topic
        contentDomain: 'Quantitative Reasoning',
        skill: 'Data Interpretation',
        titleEn: 'Aptitude: Data Interpretation',
        titleAm: 'አፕቲትዩድ፦ መረጃ መተርጎም',
        targetQuestionRecords: qRecords,
        targetAvailableQuestions: const [],
        currentTime: now,
      );

      expect(target.masteryState, equals(MasteryState.mastered));
      expect(target.unitId, isNull);
      expect(target.topicId, isNull);
      expect(target.contentDomain, equals('Quantitative Reasoning'));
      expect(target.skill, equals('Data Interpretation'));
    });
  });

  group('Mathematics Variant Isolation Tests', () {
    test(
        'Natural Science Math and Social Science Math records remain completely separate',
        () {
      final naturalRecord = QuestionMasteryRecord(
        id: 'u1_math_nat_1',
        userId: 'u1',
        questionId: 'math_nat_1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        assessmentStructure: AssessmentStructure.curriculum,
        masteryState: MasteryState.mastered,
        updatedAt: DateTime.now(),
      );

      final socialRecord = QuestionMasteryRecord(
        id: 'u1_math_soc_1',
        userId: 'u1',
        questionId: 'math_soc_1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.socialScience,
        assessmentStructure: AssessmentStructure.curriculum,
        masteryState: MasteryState.learning,
        updatedAt: DateTime.now(),
      );

      expect(naturalRecord.examVariant, equals(ExamVariantCode.naturalScience));
      expect(socialRecord.examVariant, equals(ExamVariantCode.socialScience));
      expect(
          naturalRecord.examVariant, isNot(equals(socialRecord.examVariant)));
    });
  });
}
