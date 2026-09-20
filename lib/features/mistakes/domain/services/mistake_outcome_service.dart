import '../../../exams/domain/models/exam_models.dart';
import '../repositories/mistake_repository.dart';

class MistakeOutcomeService {
  final MistakeRepository _mistakeRepo;

  const MistakeOutcomeService(this._mistakeRepo);

  /// Centralized handler for processing question outcomes across all session types
  /// (normal exams, practice, immediate feedback, mistake retry, adaptive practice).
  ///
  /// Idempotent per (attemptId, questionId).
  Future<void> processQuestionOutcome({
    required String userId,
    required String questionId,
    required String subjectId,
    String? unitId,
    String? topicId,
    required String attemptId,
    required String? selectedChoiceId,
    required bool isCorrect,
    required ExamType sessionType,
  }) async {
    // If student skipped the question without selecting an answer, do not record as wrong choice
    if (selectedChoiceId == null) return;

    if (sessionType == ExamType.mistakeRetry) {
      // Mistake Retry session: deterministically update retry and mastery counts
      await _mistakeRepo.recordRetryResult(
        userId: userId,
        questionId: questionId,
        isCorrect: isCorrect,
        attemptId: attemptId,
        selectedChoiceId: selectedChoiceId,
        subjectId: subjectId,
      );
    } else {
      // Standard exams / practice / adaptive practice:
      if (!isCorrect) {
        // Record or increment mistake
        await _mistakeRepo.recordMistake(
          userId: userId,
          questionId: questionId,
          subjectId: subjectId,
          unitId: unitId,
          topicId: topicId,
          attemptId: attemptId,
          selectedChoiceId: selectedChoiceId,
        );
      } else {
        // Section 30: Adaptive Practice compatibility
        // If question already exists in Mistake Notebook, a distinct correct answer advances mastery!
        final existing = await _mistakeRepo.getMistakeById(
          userId: userId,
          questionId: questionId,
        );
        if (existing != null) {
          await _mistakeRepo.recordRetryResult(
            userId: userId,
            questionId: questionId,
            isCorrect: true,
            attemptId: attemptId,
            selectedChoiceId: selectedChoiceId,
            subjectId: subjectId,
          );
        }
      }
    }
  }
}
