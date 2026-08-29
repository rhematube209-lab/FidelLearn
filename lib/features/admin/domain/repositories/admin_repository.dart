import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<AdminContentOverview> getContentOverview();
  Future<List<Question>> getPendingReviewQuestions();
  Future<List<ContentAuditLog>> getAuditLogs({int limit = 50});
  Future<void> updateVerificationStatus({
    required String questionId,
    required String status,
    required String actorUserId,
    required String actorRole,
    String? rejectionReason,
  });
  Future<void> saveQuestion({
    required Question question,
    required String actorUserId,
    required String actorRole,
  });
}
