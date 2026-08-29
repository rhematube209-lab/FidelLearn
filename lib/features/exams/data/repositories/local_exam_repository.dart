import '../../domain/models/exam_models.dart';
import '../../domain/repositories/exam_repository.dart';

class LocalExamRepository implements ExamRepository {
  final Map<String, ExamAttempt> _activeAttemptsByUser = {};
  final List<ExamAttempt> _completedAttempts = [];

  @override
  Future<void> saveActiveAttempt(ExamAttempt attempt) async {
    _activeAttemptsByUser[attempt.userId] = attempt;
  }

  @override
  Future<ExamAttempt?> getActiveAttempt(String userId) async {
    return _activeAttemptsByUser[userId];
  }

  @override
  Future<void> clearActiveAttempt(String userId) async {
    _activeAttemptsByUser.remove(userId);
  }

  @override
  Future<void> saveCompletedAttempt(ExamAttempt attempt) async {
    _activeAttemptsByUser.remove(attempt.userId);
    _completedAttempts.removeWhere((a) => a.id == attempt.id);
    _completedAttempts.insert(0, attempt);
  }

  @override
  Future<List<ExamAttempt>> getAttemptHistory(String userId) async {
    return _completedAttempts.where((a) => a.userId == userId).toList();
  }

  @override
  Future<ExamAttempt?> getAttemptById(String attemptId) async {
    try {
      return _completedAttempts.firstWhere((a) => a.id == attemptId);
    } catch (_) {
      return null;
    }
  }
}
