import '../models/teacher_portal_models.dart';

/// Repository contract for the P7 Teacher Portal analytics layer.
///
/// Authorization contract (enforced at every implementation):
/// - Every call requires an active teacher school_membership (via RLS / server check).
/// - Every class-level call requires an active teacher_subject_assignment for
///   the given (classroomId, subjectId) pair.
/// - Every student-level call additionally verifies the student is enrolled
///   in the specified classroom.
///
/// Cross-school access, cross-subject access, and cross-class access are all
/// denied by the backing PostgreSQL SECURITY DEFINER functions.
///
/// Data honesty contract:
/// - Mastery (P4 fidel_spaced_v1.0) is LOCAL ONLY and is NOT returned here.
/// - Readiness is computed locally and is NOT returned here.
/// - Implementations must return null / empty data rather than fabricate metrics.
abstract class TeacherPortalRepository {
  /// Returns all classroom+subject assignments for the authenticated teacher
  /// within the given school. Verifies active teacher membership.
  Future<List<TeacherAssignedClass>> getAssignedClasses({
    required String schoolId,
  });

  /// Returns a paginated roster of students authorized by the teacher's
  /// classroom + subject assignment.
  /// [pageSize] default 25. [offset] starts at 0.
  /// [search] filters by display_name or school_student_id (optional).
  Future<ClassRosterPage> getClassRoster({
    required String classroomId,
    required String subjectId,
    int pageSize = 25,
    int offset = 0,
    String? search,
  });

  /// Returns class-level topic weakness derived from cloud-synced
  /// mistake_records. NOT from local P4 mastery.
  Future<List<ClassWeakTopic>> getClassWeakTopics({
    required String classroomId,
    required String subjectId,
    int limit = 10,
  });

  /// Returns a summary of recent exams taken by students in this class,
  /// with aggregate participation and score metrics.
  /// P5 exam_type provenance is preserved in [ClassExamSummary.examType].
  Future<List<ClassExamSummary>> getClassExamSummary({
    required String classroomId,
    required String subjectId,
    int limit = 5,
  });

  /// Returns students in the class flagged for academic intervention,
  /// sorted by severity (high → medium → low), then by lowest accuracy.
  Future<AttentionPage> getAttentionStudents({
    required String classroomId,
    required String subjectId,
    int pageSize = 20,
    int offset = 0,
  });

  /// Returns the teacher-facing academic summary for an individual student.
  /// Requires: teacher assigned to classroomId+subjectId AND student
  /// actively enrolled in classroomId.
  Future<StudentAcademicSummary?> getStudentSummary({
    required String studentId,
    required String classroomId,
    required String subjectId,
    required String subjectName,
  });
}
