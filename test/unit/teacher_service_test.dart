import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/teacher/data/repositories/local_teacher_repository.dart';

void main() {
  group('TeacherRepository & Classroom Tests', () {
    late LocalTeacherRepository repository;

    setUp(() {
      repository = LocalTeacherRepository();
    });

    test('retrieves teacher classrooms and student counts', () async {
      final classrooms = await repository.getTeacherClassrooms('teacher_1');
      expect(classrooms.isNotEmpty, isTrue);
      expect(classrooms.first.name, contains('Grade 12 Natural'));
      expect(classrooms.first.studentCount, greaterThan(0));
    });

    test('creates new class assignment with question set and deadline', () async {
      final assignment = await repository.createAssignment(
        classroomId: 'cls_12A',
        classroomName: 'Grade 12 Natural - Section A',
        title: 'Integral Calculus Quiz',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        questionIds: ['q1', 'q2', 'q3'],
        timeLimitMinutes: 25,
        dueAt: DateTime.now().add(const Duration(days: 4)),
      );

      expect(assignment.id, isNotNull);
      expect(assignment.title, 'Integral Calculus Quiz');
      expect(assignment.questionIds.length, 3);

      final list = await repository.getClassAssignments('cls_12A');
      expect(list.any((a) => a.id == assignment.id), isTrue);
    });

    test('computes classroom weak-topic analytics and flags areas needing review', () async {
      final stats = await repository.getClassroomWeakTopics('cls_12A');
      expect(stats.isNotEmpty, isTrue);

      final weakTopics = stats.where((s) => s.isWeakArea).toList();
      expect(weakTopics.isNotEmpty, isTrue);
      expect(weakTopics.first.averageAccuracyPercentage, lessThan(60.0));
    });
  });
}
