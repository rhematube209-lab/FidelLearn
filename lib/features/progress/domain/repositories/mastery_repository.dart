import '../../../subjects/domain/models/subject_models.dart';
import '../models/mastery_models.dart';

/// Abstract repository defining contracts for question mastery,
/// learning target mastery, review event auditing, and spaced review queues.
abstract class MasteryRepository {
  /// Fetches question-level mastery record for a specific question.
  Future<QuestionMasteryRecord?> getQuestionMastery(
    String userId,
    String questionId,
  );

  /// Fetches all question mastery records for a user, optionally filtered by subject/variant.
  Future<List<QuestionMasteryRecord>> getQuestionMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  });

  /// Saves or updates a single question mastery record.
  Future<void> saveQuestionMastery(QuestionMasteryRecord record);

  /// Saves or updates multiple question mastery records in a transaction.
  Future<void> saveQuestionMasteryBatch(List<QuestionMasteryRecord> records);

  /// Fetches target-level mastery record for a specific learning target.
  Future<LearningTargetMasteryRecord?> getTargetMastery(
    String userId,
    String targetKey,
  );

  /// Fetches all learning target mastery records for a user.
  Future<List<LearningTargetMasteryRecord>> getTargetMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  });

  /// Saves or updates a target mastery record.
  Future<void> saveTargetMastery(LearningTargetMasteryRecord record);

  /// Saves or updates multiple target mastery records in a transaction.
  Future<void> saveTargetMasteryBatch(
      List<LearningTargetMasteryRecord> records);

  /// Fetches question mastery records that are due for spaced review as of [asOf].
  Future<List<QuestionMasteryRecord>> getDueQuestionReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  });

  /// Fetches learning targets that are due for spaced review as of [asOf].
  Future<List<LearningTargetMasteryRecord>> getDueTargetReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  });

  /// Persists an immutable review event record for auditability.
  Future<void> recordReviewEvent(ReviewEventRecord event);

  /// Fetches past review events for a user or target.
  Future<List<ReviewEventRecord>> getReviewEvents(
    String userId, {
    String? targetKey,
    int? limit,
  });
}
