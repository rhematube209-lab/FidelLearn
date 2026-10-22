import '../../domain/models/tenant_models.dart';
import '../../domain/repositories/classroom_repository.dart';

/// Test and mock implementation of ClassroomRepository.
class MockClassroomRepository implements ClassroomRepository {
  final List<Classroom> _classrooms = [];
  final List<ClassroomMembership> _memberships = [];
  final List<TeacherSubjectAssignment> _assignments = [];

  MockClassroomRepository({
    List<Classroom>? initialClassrooms,
    List<ClassroomMembership>? initialMemberships,
    List<TeacherSubjectAssignment>? initialAssignments,
  }) {
    if (initialClassrooms != null) {
      _classrooms.addAll(initialClassrooms);
    } else {
      _seedDefaultClassrooms();
    }

    if (initialMemberships != null) {
      _memberships.addAll(initialMemberships);
    }
    if (initialAssignments != null) {
      _assignments.addAll(initialAssignments);
    } else {
      _seedDefaultAssignments();
    }
  }

  void _seedDefaultAssignments() {
    final now = DateTime.now();
    _assignments.addAll([
      TeacherSubjectAssignment(
        id: 'tsa-1',
        teacherUserId: 'usr_teacher',
        schoolId: '11111111-1111-1111-1111-111111111111',
        classroomId: 'cls-12A',
        subjectId: 'math_g12',
        createdAt: now,
        updatedAt: now,
      ),
      TeacherSubjectAssignment(
        id: 'tsa-2',
        teacherUserId: '00000000-0000-0000-0000-000000000002',
        schoolId: '11111111-1111-1111-1111-111111111111',
        classroomId: 'cls-12A',
        subjectId: 'math_g12',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  void _seedDefaultClassrooms() {
    final now = DateTime.now();
    _classrooms.addAll([
      Classroom(
        id: 'cls-12A',
        schoolId: '11111111-1111-1111-1111-111111111111',
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        stream: 'naturalScience',
        section: 'A',
        academicYear: '2026/27',
        status: 'active',
        studentCount: 48,
        createdAt: now,
        updatedAt: now,
      ),
      Classroom(
        id: 'cls-12B',
        schoolId: '11111111-1111-1111-1111-111111111111',
        name: 'Grade 12 Social - Section B',
        grade: 12,
        stream: 'socialScience',
        section: 'B',
        academicYear: '2026/27',
        status: 'active',
        studentCount: 42,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  @override
  Future<List<Classroom>> getMyClassrooms({String? schoolId}) async {
    if (schoolId != null && schoolId.isNotEmpty) {
      return _classrooms.where((c) => c.schoolId == schoolId).toList();
    }
    return List.unmodifiable(_classrooms);
  }

  @override
  Future<Classroom?> getClassroom(String classroomId) async {
    return _classrooms.cast<Classroom?>().firstWhere(
          (c) => c?.id == classroomId,
          orElse: () => null,
        );
  }

  @override
  Future<List<ClassroomMembership>> getMyClassroomMemberships({
    String? classroomId,
  }) async {
    if (classroomId != null && classroomId.isNotEmpty) {
      return _memberships.where((m) => m.classroomId == classroomId).toList();
    }
    return List.unmodifiable(_memberships);
  }

  @override
  Future<List<TeacherSubjectAssignment>> getMyTeacherAssignments({
    String? schoolId,
  }) async {
    if (schoolId != null && schoolId.isNotEmpty) {
      return _assignments.where((a) => a.schoolId == schoolId).toList();
    }
    return List.unmodifiable(_assignments);
  }

  @override
  Future<List<TeacherSubjectAssignment>> getAssignmentsForClassroom(
    String classroomId,
  ) async {
    return _assignments.where((a) => a.classroomId == classroomId).toList();
  }
}
