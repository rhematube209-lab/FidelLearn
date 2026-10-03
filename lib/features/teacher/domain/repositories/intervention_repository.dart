import '../models/assignment_models.dart';

/// Contract for academic interventions.
abstract class InterventionRepository {
  /// Fetches interventions for the authorized teacher within a school tenant.
  Future<List<StudentIntervention>> getTeacherInterventions({
    required String schoolId,
    String? classroomId,
    String? subjectId,
    InterventionStatus? status,
    int limit = 50,
    int offset = 0,
  });

  /// Creates a teacher-controlled intervention linked to attention signals or observations.
  Future<String> createIntervention({
    required String schoolId,
    required String classroomId,
    required String subjectId,
    String? examVariant,
    required String studentUserId,
    required InterventionSource source,
    required List<String> sourceReasonCodes,
    String? severityAtCreation,
    required InterventionActionType actionType,
    String? linkedAssignmentId,
    String? teacherNote,
  });

  /// Marks an intervention completed (certifies the planned action was carried out).
  Future<void> completeIntervention(String interventionId);

  /// Closes an intervention record.
  Future<void> closeIntervention(String interventionId);
}
