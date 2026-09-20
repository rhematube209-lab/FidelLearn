import '../models/mistake_model.dart';

abstract class MistakeRepository {
  /// Records or updates an incorrect answer in the notebook.
  /// Idempotent per (attemptId, questionId).
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? attemptId,
    String? selectedChoiceId,
  });

  /// Records the outcome of a retry answer and deterministically advances/demotes mastery.
  /// Idempotent per (attemptId, questionId).
  Future<void> recordRetryResult({
    required String userId,
    required String questionId,
    required bool isCorrect,
    required String attemptId,
    String? selectedChoiceId,
    String? subjectId,
  });

  /// Fetches mistake records filtered by user, optional subject, unit, topic, and status.
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  });

  /// Watches mistake records reactively.
  Stream<List<MistakeRecord>> watchMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  });

  /// Fetches current mistake counts (Total, Needs Review, Improving, Mastered).
  Future<MistakeCounts> getMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  });

  /// Watches mistake counts reactively.
  Stream<MistakeCounts> watchMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  });

  /// Gets a single mistake record by user and question id.
  Future<MistakeRecord?> getMistakeById({
    required String userId,
    required String questionId,
  });

  /// Manually marks a question as mastered (kept for compatibility).
  Future<void> markMastered({
    required String userId,
    required String questionId,
  });
}
