import '../models/exam_models.dart';

abstract class ExamRepository {
  Future<void> saveActiveAttempt(ExamAttempt attempt);
  Future<ExamAttempt?> getActiveAttempt(String userId);
  Future<void> clearActiveAttempt(String userId);
  Future<void> saveCompletedAttempt(ExamAttempt attempt);
  Future<List<ExamAttempt>> getAttemptHistory(String userId);
  Future<ExamAttempt?> getAttemptById(String attemptId);
}
