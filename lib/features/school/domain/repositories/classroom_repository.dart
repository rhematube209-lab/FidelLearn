import '../models/tenant_models.dart';

/// Contract for institutional classroom and teacher-subject assignment operations.
abstract interface class ClassroomRepository {
  /// Retrieve classrooms accessible to the current user, optionally filtered by schoolId.
  /// For students: returns classrooms where enrolled.
  /// For teachers: returns classrooms where assigned.
  /// For school admins: returns all active classrooms in the school.
  Future<List<Classroom>> getMyClassrooms({String? schoolId});

  /// Retrieve a specific classroom by its UUID.
  Future<Classroom?> getClassroom(String classroomId);

  /// Retrieve classroom memberships for the caller.
  Future<List<ClassroomMembership>> getMyClassroomMemberships({
    String? classroomId,
  });

  /// Retrieve teacher subject assignments for the caller, optionally filtered by schoolId.
  Future<List<TeacherSubjectAssignment>> getMyTeacherAssignments({
    String? schoolId,
  });

  /// Retrieve teacher subject assignments for a specific classroom.
  Future<List<TeacherSubjectAssignment>> getAssignmentsForClassroom(
    String classroomId,
  );
}
