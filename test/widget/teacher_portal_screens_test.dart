import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_home_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_class_detail_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_class_roster_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_attention_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_student_summary_screen.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';

class _FakeActiveTeacherContextNotifier
    extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeActiveTeacherContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCurrentUserNotifier extends CurrentUserNotifier {
  _MockCurrentUserNotifier(super.authRepo, UserProfile user) {
    state = AsyncValue.data(user);
  }
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

  final testUser = UserProfile(
    id: 'teacher_1',
    displayName: 'Ato Abebe',
    phoneNumber: '+251911223344',
    grade: 12,
    stream: 'naturalScience',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    role: UserRole.teacher,
  );

  final mockAuth = MockAuthRepository();

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => _MockCurrentUserNotifier(mockAuth, testUser),
        ),
        activeSchoolContextProvider.overrideWith(
          (ref) => _FakeActiveTeacherContextNotifier(activeTeacherContext),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('P7 Teacher Portal Widget Tests', () {
    testWidgets('TeacherHomeScreen displays class cards and KPI metrics',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const TeacherHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Portal'), findsOneWidget);
      expect(find.text('Bole Secondary School'), findsOneWidget);
      expect(find.text('My Classes'), findsWidgets);
      expect(find.textContaining('Physics'), findsWidgets);
    });

    testWidgets(
        'TeacherClassDetailScreen displays overview, weak topics, and recent exams',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const TeacherClassDetailScreen(
            classroomId: 'cls_12A',
            subjectId: 'physics_g12',
            classroomName: 'Grade 12 Natural - Section A',
            subjectName: 'Physics',
            examVariant: 'naturalScience',
            enrolledCount: 44,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grade 12 Natural - Section A'), findsOneWidget);
      expect(find.text('View Roster'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Weak Topics'), findsOneWidget);
      expect(find.text('Recent Assessments'), findsOneWidget);
    });

    testWidgets(
        'TeacherClassRosterScreen displays search bar and student cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const TeacherClassRosterScreen(
            classroomId: 'cls_12A',
            subjectId: 'physics_g12',
            classroomName: 'Grade 12 Natural A',
            subjectName: 'Physics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Grade 12 Natural A'), findsOneWidget);
      expect(find.textContaining('Authorized Roster'), findsOneWidget);
      expect(find.text('Abebe Bekele'), findsWidgets);
    });

    testWidgets(
        'TeacherAttentionScreen renders severity filters and flagged items',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const TeacherAttentionScreen(
            classroomId: 'cls_12A',
            subjectId: 'physics_g12',
            classroomName: 'Grade 12 Natural A',
            subjectName: 'Physics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Students Needing Attention'), findsOneWidget);
      expect(find.text('All Flagged'), findsOneWidget);
      expect(find.text('Immediate Support'), findsOneWidget);
      expect(find.text('Needs Attention'), findsWidgets);
      expect(find.text('Monitor'), findsWidgets);
      expect(find.text('Almaz Tesfaye'), findsOneWidget);
    });

    testWidgets(
        'TeacherStudentSummaryScreen displays metrics and intervention recommendation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const TeacherStudentSummaryScreen(
            classroomId: 'cls_12A',
            subjectId: 'physics_g12',
            studentId: 'student_3',
            studentName: 'Almaz Tesfaye',
            schoolStudentId: 'STU1003',
            subjectName: 'Physics',
            classroomName: 'Grade 12 Natural A',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Almaz Tesfaye'), findsWidgets);
      expect(find.text('Recommended Intervention'), findsOneWidget);
      expect(find.text('Prepare Practice Assignment'), findsOneWidget);
      expect(find.text('30-Day Avg'), findsOneWidget);
      expect(find.text('Active Mistakes'), findsOneWidget);
      expect(find.text('Flagged Weak Topics'), findsOneWidget);
      expect(
          find.text('Data Authenticity & Privacy Guarantee'), findsOneWidget);
    });
  });
}
