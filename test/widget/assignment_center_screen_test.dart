import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/features/teacher/domain/models/assignment_models.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/assignment_providers.dart';
import 'package:fidel_learn/features/teacher/presentation/widgets/due_assignments_banner.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_assignment_center_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/student_assignment_inbox_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/teacher_portal_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/teacher/domain/models/teacher_portal_models.dart';

class _FakeActiveTeacherContextNotifier
    extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeActiveTeacherContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testSchool = School(
    id: 'school_1',
    name: 'Bole Secondary School',
    displayName: 'Bole Secondary School',
    schoolCode: 'BOLE01',
    status: SchoolStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testTeacherMembership = SchoolMembership(
    id: 'mem_1',
    schoolId: 'school_1',
    userId: 'teacher_1',
    role: SchoolMemberRole.teacher,
    status: SchoolMembershipStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final activeTeacherContext = ActiveSchoolContext(
    status: ActiveSchoolContextStatus.active,
    school: testSchool,
    membership: testTeacherMembership,
  );

  final sampleClasses = [
    TeacherAssignedClass(
      assignmentId: 'tsa-001',
      classroom: Classroom(
        id: 'cls-12a',
        schoolId: 'school_1',
        name: 'Grade 12-A',
        grade: 12,
        stream: 'natural',
        section: 'A',
        academicYear: '2026',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      subjectId: 'math_g12',
      subjectName: 'Mathematics',
      examVariant: 'naturalScience',
      enrolledStudentCount: 45,
    ),
  ];

  final sampleAssignments = [
    LearningAssignment(
      id: 'asgn-001',
      schoolId: 'school_1',
      classroomId: 'cls-12a',
      classroomName: 'Grade 12-A',
      teacherUserId: 'teacher_1',
      subjectId: 'math_g12',
      examVariant: 'naturalScience',
      title: 'Differential Calculus Drill',
      instructions: 'Practice 2014 exam questions',
      assignmentType: AssignmentType.targetedPractice,
      status: AssignmentStatus.published,
      totalQuestions: 15,
      createdAt: DateTime.now(),
    ),
  ];

  final sampleStudentAssignments = [
    StudentAssignment(
      assignmentId: 'asgn-001',
      recipientId: 'rcp-101',
      schoolId: 'school_1',
      classroomId: 'cls-12a',
      classroomName: 'Grade 12-A',
      teacherName: 'Ato Abebe',
      subjectId: 'math_g12',
      examVariant: 'naturalScience',
      title: 'Differential Calculus Drill',
      instructions: 'Practice 2014 exam questions',
      assignmentType: AssignmentType.targetedPractice,
      assignmentStatus: AssignmentStatus.published,
      studentStatus: AssignmentRecipientStatus.assigned,
      dueAt: DateTime.now().add(const Duration(days: 2)),
      allowLateSubmission: false,
      timeLimitMinutes: 40,
      totalQuestions: 15,
    ),
  ];

  group('P9 Assignment Center & Inbox Widget Tests', () {
    testWidgets(
        'DueAssignmentsBanner renders count and action button when pending',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider(null).overrideWith(
              (ref) => Future.value(sampleStudentAssignments),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueAssignmentsBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 Teacher Assignment Due'), findsOneWidget);
      expect(find.text('View Inbox'), findsOneWidget);
    });

    testWidgets(
        'DueAssignmentsBanner renders nothing when no assignments are pending',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider(null).overrideWith(
              (ref) => Future.value(const []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueAssignmentsBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Teacher Assignment Due'), findsNothing);
      expect(find.byType(DueAssignmentsBanner), findsOneWidget);
    });

    testWidgets(
        'TeacherAssignmentCenterScreen renders tabs and assignment cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeActiveTeacherContextNotifier(activeTeacherContext),
            ),
            teacherAssignedClassesProvider.overrideWith(
              (ref) => Future.value(sampleClasses),
            ),
            teacherAssignmentsProvider(
              (
                schoolId: 'school_1',
                classroomId: null,
                subjectId: null,
                status: AssignmentStatus.published,
              ),
            ).overrideWith(
              (ref) => Future.value(sampleAssignments),
            ),
            teacherAssignmentsProvider(
              (
                schoolId: 'school_1',
                classroomId: null,
                subjectId: null,
                status: AssignmentStatus.draft,
              ),
            ).overrideWith(
              (ref) => Future.value(const []),
            ),
            teacherAssignmentsProvider(
              (
                schoolId: 'school_1',
                classroomId: null,
                subjectId: null,
                status: AssignmentStatus.closed,
              ),
            ).overrideWith(
              (ref) => Future.value(const []),
            ),
          ],
          child: const MaterialApp(
            home: TeacherAssignmentCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assignment Center'), findsOneWidget);
      expect(find.text('Active'), findsAtLeastNWidgets(1));
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Closed / History'), findsOneWidget);
      expect(find.text('Differential Calculus Drill'), findsOneWidget);
      expect(find.text('New Assignment'), findsOneWidget);
    });

    testWidgets(
        'StudentAssignmentInboxScreen renders tabs and student assignment cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider(null).overrideWith(
              (ref) => Future.value(sampleStudentAssignments),
            ),
          ],
          child: const MaterialApp(
            home: StudentAssignmentInboxScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Assignments'), findsOneWidget);
      expect(find.text('Due & Active'), findsOneWidget);
      expect(find.text('Past Due'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Differential Calculus Drill'), findsOneWidget);
      expect(find.text('15 questions'), findsOneWidget);
      expect(find.text('Not Started'), findsOneWidget);
    });
  });
}
