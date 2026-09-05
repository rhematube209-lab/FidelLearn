import '../../../exams/domain/models/exam_models.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/repositories/content_repository.dart';
import '../models/progress_models.dart';

class RemedialDrillService {
  /// Generates a focused, offline-ready 10-question practice drill
  /// targeting the student's weakest unit or topic.
  static Future<Exam> createRemedialExam({
    required ContentRepository contentRepo,
    required WeakTopicRecommendation weakTopic,
    required String userId,
    required int grade,
    required String stream,
    int targetQuestionCount = 10,
  }) async {
    final questions = await contentRepo.getQuestions(
      grade: grade,
      subjectId: weakTopic.subjectId,
      topicId: weakTopic.topicId,
      limit: targetQuestionCount,
    );

    final List<Question> drillQuestions = List.from(questions);

    // If fewer than target count exist in this specific topic, supplement from subject
    if (drillQuestions.length < targetQuestionCount) {
      final fallbackQuestions = await contentRepo.getQuestions(
        grade: grade,
        subjectId: weakTopic.subjectId,
        limit: targetQuestionCount * 2,
      );
      for (final q in fallbackQuestions) {
        if (drillQuestions.length >= targetQuestionCount) break;
        if (!drillQuestions.any((item) => item.id == q.id)) {
          drillQuestions.add(q);
        }
      }
    }

    final examId = 'remedial_${DateTime.now().millisecondsSinceEpoch}';

    return Exam(
      id: examId,
      title: 'Remedial: ${weakTopic.topicTitleEn}',
      examType: ExamType.practice,
      subjectId: weakTopic.subjectId,
      grade: grade,
      stream: stream,
      timeLimitMinutes: 15,
      totalQuestions: drillQuestions.length,
      questions: drillQuestions,
      createdAt: DateTime.now(),
    );
  }

  /// Instantiates a clean initial ExamAttempt for launching the drill
  static ExamAttempt createInitialAttempt({
    required Exam exam,
    required String userId,
  }) {
    return ExamAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      examId: exam.id,
      examTitle: exam.title,
      subjectId: exam.subjectId ?? 'general',
      startTime: DateTime.now(),
      durationSeconds: exam.timeLimitMinutes * 60,
      totalQuestions: exam.totalQuestions,
      score: 0,
      percentage: 0.0,
      correctCount: 0,
      incorrectCount: 0,
      skippedCount: exam.totalQuestions,
      isCompleted: false,
      responses: const {},
    );
  }
}
