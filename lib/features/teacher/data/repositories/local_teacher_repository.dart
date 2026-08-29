import '../../domain/models/teacher_models.dart';
import '../../domain/repositories/teacher_repository.dart';

class LocalTeacherRepository implements TeacherRepository {
  final List<Classroom> _classrooms = [];
  final List<ClassAssignment> _assignments = [];

  LocalTeacherRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    _classrooms.addAll([
      const Classroom(
        id: 'cls_12A',
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        stream: 'natural',
        studentCount: 48,
        teacherId: 'teacher_1',
      ),
      const Classroom(
        id: 'cls_12B',
        name: 'Grade 12 Social - Section B',
        grade: 12,
        stream: 'social',
        studentCount: 42,
        teacherId: 'teacher_1',
      ),
    ]);

    _assignments.addAll([
      ClassAssignment(
        id: 'asg_1',
        classroomId: 'cls_12A',
        classroomName: 'Grade 12 Natural - Section A',
        title: 'Weekly Calculus & Sequence Review',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        questionIds: const ['q_math_seq_1', 'q_math_seq_2', 'q_math_lim_1'],
        timeLimitMinutes: 20,
        dueAt: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 1)),
        totalSubmissions: 36,
        averageScorePercentage: 78.5,
      ),
    ]);
  }

  @override
  Future<List<Classroom>> getTeacherClassrooms(String teacherId) async {
    return _classrooms.where((c) => c.teacherId == teacherId).toList();
  }

  @override
  Future<List<ClassAssignment>> getClassAssignments(String classroomId) async {
    return _assignments.where((a) => a.classroomId == classroomId).toList();
  }

  @override
  Future<ClassAssignment> createAssignment({
    required String classroomId,
    required String classroomName,
    required String title,
    required String subjectId,
    required String subjectName,
    required List<String> questionIds,
    required int timeLimitMinutes,
    required DateTime dueAt,
  }) async {
    final assignment = ClassAssignment(
      id: 'asg_${DateTime.now().millisecondsSinceEpoch}',
      classroomId: classroomId,
      classroomName: classroomName,
      title: title,
      subjectId: subjectId,
      subjectName: subjectName,
      questionIds: questionIds,
      timeLimitMinutes: timeLimitMinutes,
      dueAt: dueAt,
      createdAt: DateTime.now(),
      totalSubmissions: 0,
      averageScorePercentage: 0.0,
    );

    _assignments.insert(0, assignment);
    return assignment;
  }

  @override
  Future<List<ClassroomTopicStats>> getClassroomWeakTopics(
    String classroomId,
  ) async {
    return const [
      ClassroomTopicStats(
        topicId: 'math_limits',
        topicName: 'Limits at Infinity & Continuity',
        averageAccuracyPercentage: 48.2,
        totalQuestionsAttempted: 144,
        isWeakArea: true,
      ),
      ClassroomTopicStats(
        topicId: 'math_sequences',
        topicName: 'Arithmetic & Geometric Sequences',
        averageAccuracyPercentage: 82.5,
        totalQuestionsAttempted: 144,
        isWeakArea: false,
      ),
      ClassroomTopicStats(
        topicId: 'math_derivatives',
        topicName: 'Derivatives & Rate of Change',
        averageAccuracyPercentage: 54.0,
        totalQuestionsAttempted: 120,
        isWeakArea: true,
      ),
    ];
  }
}
