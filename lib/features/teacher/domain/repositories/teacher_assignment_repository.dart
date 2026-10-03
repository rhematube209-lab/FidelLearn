import '../models/assignment_models.dart';

/// Contract for teacher-managed assignments in P9.
/// All methods enforce tenant and teacher authority gates.
abstract class TeacherAssignmentRepository {
  /// Fetches paginated assignments authored by the teacher or accessible via admin oversight.
  Future<List<LearningAssignment>> getTeacherAssignments({
    required String schoolId,
    String? classroomId,
    String? subjectId,
    AssignmentStatus? status,
    int limit = 50,
    int offset = 0,
  });

  /// Fetches detailed assignment recipient progress.
  Future<AssignmentProgressSummary> getAssignmentProgress({
    required String assignmentId,
    int limit = 100,
    int offset = 0,
  });

  /// Creates a new draft assignment. Returns the generated assignment ID.
  Future<String> createAssignmentDraft({
    required String schoolId,
    required String classroomId,
    required String subjectId,
    String? examVariant,
    required String title,
    String? instructions,
    required AssignmentType assignmentType,
    int timeLimitMinutes = 0,
    DateTime? dueAt,
    bool allowLateSubmission = true,
  });

  /// Updates an editable draft assignment.
  Future<void> updateAssignmentDraft({
    required String assignmentId,
    required String title,
    String? instructions,
    int? timeLimitMinutes,
    DateTime? dueAt,
    bool? allowLateSubmission,
  });

  /// Atomically freezes question set and resolves recipient roster, transitioning to 'published'.
  Future<Map<String, dynamic>> publishAssignment({
    required String assignmentId,
    required List<String> questionIds,
    List<String>? recipientStudentIds,
  });

  /// Closes an active assignment preventing new starts/submissions per policy.
  Future<void> closeAssignment(String assignmentId);

  /// Archives a closed assignment into institutional historical records.
  Future<void> archiveAssignment(String assignmentId);

  /// Deliberately adds a newly enrolled student to an already published assignment.
  Future<void> addRecipient({
    required String assignmentId,
    required String studentUserId,
  });
}
