import '../models/assignment_models.dart';

/// Contract for student assignment inbox and submission operations.
abstract class StudentAssignmentRepository {
  /// Fetches assigned work for the authenticated student.
  Future<List<StudentAssignment>> getStudentAssignments({
    AssignmentRecipientStatus? status,
    int limit = 50,
    int offset = 0,
  });

  /// Fetches assignment metadata and frozen question IDs for offline exam runner initialization.
  Future<Map<String, dynamic>> getAssignmentDetail(String assignmentId);

  /// Submits student attempt link, score, and timestamps to the cloud.
  Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    required String attemptId,
    required int score,
    required double percentage,
    DateTime? submittedAt,
  });
}
