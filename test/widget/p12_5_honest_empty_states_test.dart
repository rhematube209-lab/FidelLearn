import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fidel_learn/core/config/env_config.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/auth/presentation/screens/login_screen.dart';
import 'package:fidel_learn/features/home/presentation/screens/student_home_screen.dart';
import 'package:fidel_learn/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/licensing_onboarding_providers.dart';
import 'package:fidel_learn/features/school/presentation/screens/school_license_screen.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/teacher/domain/models/teacher_portal_models.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/teacher_portal_providers.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_home_screen.dart';

void main() {
  group('P12.5 Honest Empty States & Mock Elimination Widget Tests', () {
    tearDown(() {
      EnvConfig.overrideEnvironment = null;
    });

    testWidgets(
        'LoginScreen in pilot/production shows empty inputs and zero demo chips',
        (WidgetTester tester) async {
      EnvConfig.overrideEnvironment = 'pilot';

      final storage = AuthSessionStorage();
      final authRepo = MockAuthRepository(sessionStorage: storage);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no demo accounts card is rendered
      expect(find.text('Quick-Fill Demo Accounts'), findsNothing);
      expect(find.text('Demo Student'), findsNothing);
      expect(find.text('Demo Teacher'), findsNothing);
      expect(find.text('School Admin'), findsNothing);

      // Verify input fields are empty
      expect(find.text('+251911223344'), findsNothing);
      expect(find.text('password123'), findsNothing);
    });

    testWidgets(
        'OnboardingScreen in pilot/production has zero guest demo bypass',
        (WidgetTester tester) async {
      EnvConfig.overrideEnvironment = 'production';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure guest demo button is hidden
      expect(find.text('Try Demo as Guest'), findsNothing);
    });

    testWidgets(
        'SchoolLicenseScreen renders honest empty state when school has null license',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolLicenseFamilyProvider('sch_no_lic_1').overrideWith(
              (ref) => null,
            ),
            schoolSeatUsageFamilyProvider('sch_no_lic_1').overrideWith(
              (ref) => null,
            ),
          ],
          child: const MaterialApp(
            home: SchoolLicenseScreen(schoolId: 'sch_no_lic_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Institutional License'), findsOneWidget);
      expect(
          find.textContaining(
              'does not currently have an active license recorded'),
          findsOneWidget);
      expect(find.text('500 seats'), findsNothing);
      expect(find.text('430 used'), findsNothing);
    });

    testWidgets(
        'StudentHomeScreen with fresh learner shows honest empty states (zero fake 84% or fake topics)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final freshStudent = UserProfile(
        id: 'fresh-student-pilot',
        phoneNumber: '+251911000000',
        displayName: 'Alemayehu Pilot',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: freshStudent,
      );

      final contentRepo = LocalContentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
          ],
          child: const MaterialApp(
            home: StudentHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Readiness gauge shows honest empty / no data state
      expect(find.text('NO DATA YET 📚'), findsOneWidget);
      expect(find.text('--%'), findsWidgets);

      // Never shows fabricated 84% or 68.5%
      expect(find.text('84%'), findsNothing);
      expect(find.text('68.5%'), findsNothing);

      // Weak topics shows honest empty state
      expect(find.textContaining('No weak topics flagged yet'), findsOneWidget);
    });

    testWidgets(
        'TeacherHomeScreen renders honest empty state when teacher has no assigned classes',
        (WidgetTester tester) async {
      final activeTeacherContext = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.active,
        school: School(
          id: 'sch_real_1',
          name: 'Pilot High School',
          displayName: 'Pilot High School',
          schoolCode: 'PHS01',
          status: SchoolStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        membership: SchoolMembership(
          id: 'mem_t1',
          schoolId: 'sch_real_1',
          userId: 'teacher_real_1',
          role: SchoolMemberRole.teacher,
          status: SchoolMembershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final teacherUser = UserProfile(
        id: 'teacher_real_1',
        displayName: 'Teacher Selam',
        phoneNumber: '+251911223344',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
        role: UserRole.teacher,
      );

      final storage = AuthSessionStorage();
      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: teacherUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => _FakeTeacherUserNotifier(authRepo, teacherUser),
            ),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeTeacherContextNotifier(activeTeacherContext),
            ),
            teacherAssignedClassesProvider
                .overrideWith((ref) => <TeacherAssignedClass>[]),
          ],
          child: const MaterialApp(
            home: TeacherHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Classes Assigned'), findsOneWidget);
      expect(
        find.text(
            'Ask your school administrator to assign you to a class and subject.'),
        findsOneWidget,
      );
    });
  });
}

class _FakeTeacherUserNotifier extends CurrentUserNotifier {
  _FakeTeacherUserNotifier(super.authRepo, UserProfile user) {
    state = AsyncValue.data(user);
  }
}

class _FakeTeacherContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeTeacherContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
