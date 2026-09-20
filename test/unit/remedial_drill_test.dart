import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_availability.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/progress/domain/models/progress_models.dart';
import 'package:fidel_learn/features/progress/domain/services/remedial_drill_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/repositories/content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/services/delta_package_service.dart';

class MockContentRepository implements ContentRepository {
  final List<Question> availableQuestions;

  MockContentRepository(this.availableQuestions);

  @override
  Future<void> initializeSeedData() async {}

  @override
  Future<List<Subject>> getSubjects(
          {int? grade, required String stream}) async =>
      [];

  @override
  Future<List<Unit>> getUnits(String subjectId) async => [];

  @override
  Future<List<Topic>> getTopics(String unitId) async => [];

  @override
  Future<List<ContentPackage>> getPackages(
          {required int grade, required String stream}) async =>
      [];

  @override
  Future<void> downloadPackage(String packageId) async {}

  @override
  Future<void> removePackage(String packageId) async {}

  @override
  Future<PackageDelta?> checkPackageUpdate(String packageId) async => null;

  @override
  Future<void> applyDeltaUpdate(String packageId, PackageDelta delta) async {}

  @override
  Future<List<Question>> getQuestions({
    int? grade,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? difficulty,
    int? examYear,
    int? startYear,
    int? endYear,
    List<int>? examYears,
    int? limit,
  }) async {
    var filtered = availableQuestions.where((q) {
      if (grade != null && q.grade != grade) return false;
      if (q.subjectId != subjectId) return false;
      if (unitId != null && q.unitId != unitId) return false;
      if (topicId != null && q.topicId != topicId) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      return true;
    }).toList();

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }
    return filtered;
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    final list = availableQuestions.where((q) => q.id == id);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<int>> getAvailableExamYears(String subjectId) async => [];

  @override
  Future<List<ExamAvailability>> getExamAvailabilities(String subjectId) async => [];

  @override
  Future<Map<String, int>> getUnitQuestionCounts({
    required String subjectId,
    int? examYear,
    int? grade,
  }) async => {};
}

void main() {
  group('RemedialDrillService Tests', () {
    const weakTopic = WeakTopicRecommendation(
      subjectId: 'math_g12',
      topicId: 'topic_derivatives',
      topicTitleEn: 'Derivatives & Applications',
      accuracyPercentage: 42.5,
      totalAttempts: 12,
      mistakeCount: 7,
      urgencyLevel: 'high',
      recommendationReason: 'Practice calculus slope formulas.',
    );

    Question makeQuestion({
      required String id,
      required String topicId,
      required String subjectId,
    }) {
      return Question(
        id: id,
        grade: 12,
        stream: 'natural',
        subjectId: subjectId,
        unitId: 'unit_calc',
        topicId: topicId,
        difficulty: 'medium',
        questionTextEn: 'Sample question $id',
        verificationStatus: VerificationStatus.published,
        sourceName: 'National Exam',
        contentVersion: 1,
        choices: const [],
        explanation: const Explanation(solutionTextEn: 'Exp'),
      );
    }

    test(
        'createRemedialExam creates 10-question drill when topic has enough questions',
        () async {
      final questions = List.generate(
        15,
        (i) => makeQuestion(
          id: 'q_deriv_$i',
          topicId: 'topic_derivatives',
          subjectId: 'math_g12',
        ),
      );

      final repo = MockContentRepository(questions);

      final exam = await RemedialDrillService.createRemedialExam(
        contentRepo: repo,
        weakTopic: weakTopic,
        userId: 'student_123',
        grade: 12,
        stream: 'natural',
        targetQuestionCount: 10,
      );

      expect(exam.subjectId, equals('math_g12'));
      expect(exam.grade, equals(12));
      expect(exam.stream, equals('natural'));
      expect(exam.timeLimitMinutes, equals(15));
      expect(exam.isTimed, isTrue);
      expect(exam.questions.length, equals(10));
      expect(exam.totalQuestions, equals(10));
      expect(exam.title, contains('Derivatives & Applications'));
      expect(exam.questions.every((q) => q.topicId == 'topic_derivatives'),
          isTrue);
    });

    test(
        'createRemedialExam supplements questions from subject when topic questions are insufficient',
        () async {
      // 4 questions in topic_derivatives, 10 questions in topic_integrals for the same subject
      final topicQuestions = List.generate(
        4,
        (i) => makeQuestion(
          id: 'q_deriv_$i',
          topicId: 'topic_derivatives',
          subjectId: 'math_g12',
        ),
      );
      final otherQuestions = List.generate(
        10,
        (i) => makeQuestion(
          id: 'q_integ_$i',
          topicId: 'topic_integrals',
          subjectId: 'math_g12',
        ),
      );

      final repo =
          MockContentRepository([...topicQuestions, ...otherQuestions]);

      final exam = await RemedialDrillService.createRemedialExam(
        contentRepo: repo,
        weakTopic: weakTopic,
        userId: 'student_123',
        grade: 12,
        stream: 'natural',
        targetQuestionCount: 10,
      );

      expect(exam.questions.length, equals(10));
      // First 4 are from target topic, remaining 6 supplemented from subject
      expect(
          exam.questions.take(4).every((q) => q.topicId == 'topic_derivatives'),
          isTrue);
      expect(
          exam.questions.skip(4).every((q) => q.topicId == 'topic_integrals'),
          isTrue);
    });

    test('createInitialAttempt builds valid uncompleted exam attempt', () {
      final exam = Exam(
        id: 'remedial_exam_99',
        title: 'Remedial: Calculus',
        examType: ExamType.practice,
        subjectId: 'math_g12',
        grade: 12,
        stream: 'natural',
        timeLimitMinutes: 15,
        totalQuestions: 10,
        questions: const [],
        createdAt: DateTime(2026, 1, 1),
      );

      final attempt = RemedialDrillService.createInitialAttempt(
        exam: exam,
        userId: 'user_xyz',
      );

      expect(attempt.examId, equals('remedial_exam_99'));
      expect(attempt.userId, equals('user_xyz'));
      expect(attempt.examTitle, equals('Remedial: Calculus'));
      expect(attempt.subjectId, equals('math_g12'));
      expect(attempt.durationSeconds, equals(15 * 60));
      expect(attempt.totalQuestions, equals(10));
      expect(attempt.skippedCount, equals(10));
      expect(attempt.score, equals(0));
      expect(attempt.percentage, equals(0.0));
      expect(attempt.isCompleted, isFalse);
      expect(attempt.responses, isEmpty);
    });
  });
}
