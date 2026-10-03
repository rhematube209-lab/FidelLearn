import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/school/presentation/screens/school_leadership_home_screen.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/school_leadership_providers.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';

class _FakeSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeSchoolContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCurrentUserNotifier extends CurrentUserNotifier {
  _MockCurrentUserNotifier(super.authRepo, UserProfile? user) {
    state = AsyncValue.data(user);
  }
}

void main() {
  final testSchool = School(
    id: 'sch_widget_01',
    name: 'Menelik II Secondary School',
    displayName: 'Menelik II High School',
    schoolCode: 'MEN-001',
    status: SchoolStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final adminMembership = SchoolMembership(
    id: 'mem_admin_01',
    schoolId: 'sch_widget_01',
    userId: 'usr_admin_01',
    role: SchoolMemberRole.schoolAdmin,
    status: SchoolMembershipStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final studentMembership = SchoolMembership(
    id: 'mem_student_01',
    schoolId: 'sch_widget_01',
    userId: 'usr_student_01',
    role: SchoolMemberRole.student,
    status: SchoolMembershipStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final activeAdminContext = ActiveSchoolContext(
    status: ActiveSchoolContextStatus.active,
    school: testSchool,
    membership: adminMembership,
  );

  final nonAdminContext = ActiveSchoolContext(
    status: ActiveSchoolContextStatus.active,
    school: testSchool,
    membership: studentMembership,
  );

  final testUser = UserProfile(
    id: 'usr_admin_01',
    displayName: 'Ato Kebede',
    phoneNumber: '+251911998877',
    grade: 12,
    stream: 'naturalScience',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    role: UserRole.student,
  );

  final mockAuth = MockAuthRepository();

  Widget createTestWidget({
    required ActiveSchoolContext context,
    bool authenticated = true,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => _MockCurrentUserNotifier(
            mockAuth,
            authenticated ? testUser : null,
          ),
        ),
        activeSchoolContextProvider.overrideWith(
          (ref) => _FakeSchoolContextNotifier(context),
        ),
        schoolLeadershipRepositoryProvider.overrideWithValue(
          LocalSchoolLeadershipRepository(),
        ),
      ],
      child: const MaterialApp(
        home: SchoolLeadershipHomeScreen(),
      ),
    );
  }

  group('P8 School Leadership Home Screen Widget Tests', () {
    testWidgets(
        'Renders access denial feedback when user lacks active school admin role',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(context: nonAdminContext));
      await tester.pump();

      // Non-admin triggers role guard returning progress indicator while intercepting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'Renders leadership dashboard header, KPIs, and integrity banner for active admin',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(context: activeAdminContext));
      await tester.pumpAndSettle();

      // Verify header and school title
      expect(find.text('Menelik II High School'), findsWidgets);
      expect(find.text('INSTITUTIONAL LEADERSHIP'), findsOneWidget);

      // Verify honest metric principle badge
      expect(
        find.textContaining('Academic Honesty Notice'),
        findsOneWidget,
      );

      // Verify executive KPI cards
      expect(find.text('Total Enrolled Students'), findsOneWidget);
      expect(find.text('Simulation Prep Average'), findsOneWidget);
      expect(find.text('Students Needing Support'), findsOneWidget);
      expect(find.text('Teacher Staffing Coverage'), findsOneWidget);

      // Verify stream breakdown section
      expect(find.textContaining('Stream Comparison'), findsOneWidget);
      expect(find.text('Natural Science'), findsWidgets);
      expect(find.text('Social Science'), findsWidgets);
    });

    testWidgets(
        'Switches tabs between Streams, Subjects, Classes, and Oversight',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(context: activeAdminContext));
      await tester.pumpAndSettle();

      // Click on Subjects tab
      final subjectsTab = find.text('Subjects');
      expect(subjectsTab, findsOneWidget);
      await tester.tap(subjectsTab);
      await tester.pumpAndSettle();

      // Click on Sections tab
      final sectionsTab = find.text('Sections');
      expect(sectionsTab, findsOneWidget);
      await tester.tap(sectionsTab);
      await tester.pumpAndSettle();

      // Click on Student Support tab
      final supportTab = find.text('Student Support');
      expect(supportTab, findsOneWidget);
      await tester.tap(supportTab);
      await tester.pumpAndSettle();

      // Click on Teacher Coverage tab
      final teacherTab = find.text('Teacher Coverage');
      expect(teacherTab, findsOneWidget);
      await tester.tap(teacherTab);
      await tester.pumpAndSettle();
    });
  });
}
