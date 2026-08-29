import '../../../question_bank/domain/models/question_models.dart';
import '../models/exam_models.dart';

class ExamEngine {
  ExamEngine._();

  /// Starts a new active attempt
  static ExamAttempt startAttempt({
    required String attemptId,
    required String userId,
    required Exam exam,
  }) {
    final Map<String, UserResponse> initialResponses = {};
    for (final q in exam.questions) {
      initialResponses[q.id] = UserResponse(
        questionId: q.id,
        selectedChoiceId: null,
        isCorrect: false,
        timeSpentSeconds: 0,
        isFlagged: false,
      );
    }

    return ExamAttempt(
      id: attemptId,
      userId: userId,
      examId: exam.id,
      examTitle: exam.title,
      subjectId: exam.subjectId ?? 'unknown',
      startTime: DateTime.now(),
      durationSeconds: 0,
      totalQuestions: exam.totalQuestions,
      score: 0,
      percentage: 0.0,
      correctCount: 0,
      incorrectCount: 0,
      skippedCount: exam.totalQuestions,
      isCompleted: false,
      responses: initialResponses,
    );
  }

  /// Records an answer choice for a question
  static ExamAttempt answerQuestion({
    required ExamAttempt currentAttempt,
    required Question question,
    required String choiceId,
    int timeSpentDeltaSeconds = 0,
  }) {
    if (currentAttempt.isCompleted) return currentAttempt;

    final selectedChoice = question.choices.firstWhere(
      (c) => c.id == choiceId,
      orElse: () => question.choices.first,
    );

    final existingResp =
        currentAttempt.responses[question.id] ??
        UserResponse(questionId: question.id, isCorrect: false);

    final updatedResp = existingResp.copyWith(
      selectedChoiceId: choiceId,
      isCorrect: selectedChoice.isCorrect,
      timeSpentSeconds: existingResp.timeSpentSeconds + timeSpentDeltaSeconds,
    );

    final updatedMap = Map<String, UserResponse>.from(currentAttempt.responses);
    updatedMap[question.id] = updatedResp;

    return currentAttempt.copyWith(responses: updatedMap);
  }

  /// Toggles question flag for review
  static ExamAttempt toggleFlag({
    required ExamAttempt currentAttempt,
    required String questionId,
  }) {
    final existingResp = currentAttempt.responses[questionId];
    if (existingResp == null) return currentAttempt;

    final updatedResp = existingResp.copyWith(
      isFlagged: !existingResp.isFlagged,
    );
    final updatedMap = Map<String, UserResponse>.from(currentAttempt.responses);
    updatedMap[questionId] = updatedResp;

    return currentAttempt.copyWith(responses: updatedMap);
  }

  /// Submits and calculates final score and metrics
  static ExamAttempt submitAttempt({
    required ExamAttempt currentAttempt,
    required List<Question> questions,
    required int totalDurationSeconds,
  }) {
    if (currentAttempt.isCompleted) return currentAttempt;

    int correct = 0;
    int incorrect = 0;
    int skipped = 0;

    final Map<String, UserResponse> validatedResponses = {};

    for (final q in questions) {
      final resp = currentAttempt.responses[q.id];
      if (resp == null || resp.selectedChoiceId == null) {
        skipped++;
        validatedResponses[q.id] = UserResponse(
          questionId: q.id,
          selectedChoiceId: null,
          isCorrect: false,
          timeSpentSeconds: resp?.timeSpentSeconds ?? 0,
          isFlagged: resp?.isFlagged ?? false,
        );
      } else {
        final isCorrect = q.correctChoice.id == resp.selectedChoiceId;
        if (isCorrect) {
          correct++;
        } else {
          incorrect++;
        }
        validatedResponses[q.id] = resp.copyWith(isCorrect: isCorrect);
      }
    }

    final total = questions.isNotEmpty
        ? questions.length
        : currentAttempt.totalQuestions;
    final percentage = total > 0 ? (correct / total) * 100.0 : 0.0;

    return currentAttempt.copyWith(
      endTime: DateTime.now(),
      durationSeconds: totalDurationSeconds,
      score: correct,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      isCompleted: true,
      responses: validatedResponses,
    );
  }
}
