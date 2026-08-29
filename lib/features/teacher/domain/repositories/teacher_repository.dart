import '../models/teacher_models.dart';

abstract class TeacherRepository {
  Future<List<Classroom>> getTeacherClassrooms(String teacherId);
  Future<List<ClassAssignment>> getClassAssignments(String classroomId);
  Future<ClassAssignment> createAssignment({
    required String classroomId,
    required String classroomName,
    required String title,
    required String subjectId,
    required String subjectName,
    required List<String> questionIds,
    required int timeLimitMinutes,
    required DateTime dueAt,
  });
  Future<List<ClassroomTopicStats>> getClassroomWeakTopics(String classroomId);
}
