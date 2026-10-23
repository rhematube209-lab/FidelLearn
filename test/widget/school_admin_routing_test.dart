import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fidel_learn/app/app.dart';
import 'package:fidel_learn/core/config/env_config.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/routing/app_router.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/auth/presentation/screens/login_screen.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/local_bookmark_repository.dart';
import 'package:fidel_learn/features/exams/data/repositories/local_exam_repository.dart';
import 'package:fidel_learn/features/home/presentation/screens/student_home_screen.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/local_mistake_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/school_leadership_providers.dart';
import 'package:fidel_learn/features/school/data/repositories/local_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/presentation/providers/institutional_reporting_providers.dart';
import 'package:fidel_learn/features/school/presentation/screens/reports_hub_screen.dart';
import 'package:fidel_learn/features/school/presentation/screens/school_leadership_home_screen.dart';
import 'package:fidel_learn/features/school/domain/repositories/classroom_repository.dart';
import 'package:fidel_learn/features/school/domain/repositories/school_repository.dart';
import 'package:fidel_learn/features/school/presentation/screens/report_preview_screen.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_home_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_assignment_center_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_intervention_center_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_class_detail_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_class_roster_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_attention_screen.dart';
import 'package:fidel_learn/features/teacher/presentation/screens/teacher_student_summary_screen.dart';

class _FakeSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeSchoolContextNotifier(super.state);

  void updateState(ActiveSchoolContext next) {
    state = next;
  }

  @override
  Future<ActiveSchoolContext> resolveContext({UserProfile? user}) async {
    return state;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettableCurrentUserNotifier extends CurrentUserNotifier {
  _SettableCurrentUserNotifier(super.authRepo, UserProfile? initialUser) {
    state = AsyncValue.data(initialUser);
  }

  void updateUser(UserProfile? user) {
    state = AsyncValue.data(user);
  }
}

class _EmptySchoolRepo implements SchoolRepository {
  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyClassroomRepo implements ClassroomRepository {
  @override
  Future<List<Classroom>> getMyClassrooms({String? schoolId}) async => [];

  @override
  Future<List<ClassroomMembership>> getMyClassroomMemberships(
          {String? classroomId}) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledSchoolContextNotifier
    extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  final Completer<ActiveSchoolContext>? _completer;

  _ControlledSchoolContextNotifier(
    super.state, [
    this._completer,
  ]);

  void update(ActiveSchoolContext next) {
    state = next;
  }

  @override
  Future<ActiveSchoolContext> resolveContext({UserProfile? user}) async {
    if (_completer != null) {
      final result = await _completer.future;
      state = result;
      return result;
    }
    return state;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMultiSchoolRepo implements SchoolRepository {
  final List<SchoolMembershipWithSchool> schools;
  _MockMultiSchoolRepo({required this.schools});

  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async => schools;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingSchoolRepo implements SchoolRepository {
  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    throw Exception('Network timeout connecting to server');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControllableMultiSchoolRepo implements SchoolRepository {
  final List<SchoolMembershipWithSchool> entries;
  final Completer<void> _resolveCompleter = Completer<void>();
  bool _immediateForSelect = false;

  _ControllableMultiSchoolRepo({required this.entries});

  void enableImmediateForSelect() {
    _immediateForSelect = true;
  }

  void releaseResolve() {
    if (!_resolveCompleter.isCompleted) {
      _resolveCompleter.complete();
    }
  }

  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    if (!_immediateForSelect && !_resolveCompleter.isCompleted) {
      await _resolveCompleter.future;
    }
    return entries;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PausingStorage extends AuthSessionStorage {
  Completer<void>? writePauseCompleter;
  int? pauseOnVersion;

  @override
  Future<bool> commitSchoolContext({
    required int version,
    required String? schoolId,
    required CachedSchoolContext? context,
  }) async {
    if (pauseOnVersion == version &&
        writePauseCompleter != null &&
        !writePauseCompleter!.isCompleted) {
      await writePauseCompleter!.future;
    }
    return super.commitSchoolContext(
      version: version,
      schoolId: schoolId,
      context: context,
    );
  }
}

void main() {
  final testSchool = School(
    id: 'sch_test_01',
    name: 'Addis Ababa Secondary School',
    displayName: 'Addis Ababa High School',
    schoolCode: 'AAS-001',
    status: SchoolStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final adminMembership = SchoolMembership(
    id: 'mem_admin_01',
    schoolId: 'sch_test_01',
    userId: 'usr_school_admin',
    role: SchoolMemberRole.schoolAdmin,
    status: SchoolMembershipStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final teacherMembership = SchoolMembership(
    id: 'mem_teacher_01',
    schoolId: 'sch_test_01',
    userId: 'usr_teacher',
    role: SchoolMemberRole.teacher,
    status: SchoolMembershipStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final studentMembership = SchoolMembership(
    id: 'mem_student_01',
    schoolId: 'sch_test_01',
    userId: 'usr_student',
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

  final activeTeacherContext = ActiveSchoolContext(
    status: ActiveSchoolContextStatus.active,
    school: testSchool,
    membership: teacherMembership,
  );

  final studentSchoolContext = ActiveSchoolContext(
    status: ActiveSchoolContextStatus.active,
    school: testSchool,
    membership: studentMembership,
  );

  // Realistic user: newly registered / standard global student role with active admin membership
  final adminUser = UserProfile(
    id: 'usr_school_admin',
    phoneNumber: '+251955667788',
    displayName: 'Director Abebe',
    grade: 12,
    stream: 'natural',
    preferredLanguage: 'en',
    role: UserRole.student,
    createdAt: DateTime.now(),
  );

  final studentUser = UserProfile(
    id: 'usr_student',
    phoneNumber: '+251911223344',
    displayName: 'Student Almaz',
    grade: 12,
    stream: 'natural',
    preferredLanguage: 'en',
    role: UserRole.student,
    createdAt: DateTime.now(),
  );

  // Realistic user: newly registered / standard global student role with active teacher membership
  final teacherUser = UserProfile(
    id: 'usr_teacher',
    phoneNumber: '+251966778899',
    displayName: 'Teacher Bekele',
    grade: 12,
    stream: 'natural',
    preferredLanguage: 'en',
    role: UserRole.student,
    createdAt: DateTime.now(),
  );

  // Legacy global schoolAdmin user fixture (for verifying legacy role alone is insufficient)
  final legacyGlobalAdminUser = UserProfile(
    id: 'usr_legacy_admin',
    phoneNumber: '+251944556677',
    displayName: 'Legacy Global Admin',
    grade: 12,
    stream: 'common',
    preferredLanguage: 'en',
    role: UserRole.schoolAdmin,
    createdAt: DateTime.now(),
  );

  final platformAdminUser = UserProfile(
    id: 'usr_platform_admin',
    phoneNumber: '+251900000000',
    displayName: 'Super Admin',
    grade: 12,
    stream: 'natural',
    preferredLanguage: 'en',
    role: UserRole.platformAdmin,
    createdAt: DateTime.now(),
  );

  group('Priority 3 — School Admin Routing & Role Guard Tests', () {
    testWidgets(
        'Restored session from splash screen navigates school admin to /school (SchoolLeadershipHomeScreen)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: adminUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: adminUser,
        sessionStorage: storage,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        subjects: const [],
        units: const [],
        topics: const [],
        questions: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
            schoolLeadershipRepositoryProvider
                .overrideWithValue(LocalSchoolLeadershipRepository()),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(activeAdminContext),
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      // Settle splash delay (300ms) and navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // School admin must land on SchoolLeadershipHomeScreen
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Successful login navigates school admin to /school (SchoolLeadershipHomeScreen)',
        (WidgetTester tester) async {
      EnvConfig.overrideEnvironment = 'demo';
      addTearDown(EnvConfig.resetTestOverrides);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.clearSession();

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            schoolLeadershipRepositoryProvider
                .overrideWithValue(LocalSchoolLeadershipRepository()),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(activeAdminContext),
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      // Splash completes, navigates to LoginScreen
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      expect(find.text('Quick-Fill Demo Accounts'), findsOneWidget);
      expect(find.text('School Admin'), findsOneWidget);

      // Enter school admin credentials using TextFields
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), '0955667788');
      await tester.enterText(textFields.at(1), 'tenantAdminPass123');

      final loginBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully landed on SchoolLeadershipHomeScreen
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Successful login navigates teacher (student role + active teacher membership) to /teacher',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.clearSession();

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), '0966778899');
      await tester.enterText(textFields.at(1), 'tenantTeacherPass123');

      final loginBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully landed on TeacherHomeScreen
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Direct URL navigation to /school by student with active admin membership lands on /school',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeAdminContext),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Direct URL navigation to /school by legacy global schoolAdmin without active membership redirects to /home',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
                MockAuthRepository(), legacyGlobalAdminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(
                const ActiveSchoolContext.independent()),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Legacy global role alone never grants school access -> redirected to /home
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Direct URL navigation to /school by unauthenticated user redirects to /login',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(MockAuthRepository(), null),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(
                const ActiveSchoolContext.independent()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unauthorized unauthenticated access denied -> redirected to /login
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Direct URL navigation to /school by student redirects to /home',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), studentUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(studentSchoolContext),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Student is denied access to school admin -> redirected to /home
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Direct URL navigation to /school_admin redirects to /school for authorized admin',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeAdminContext),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school_admin',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lands on /school -> SchoolLeadershipHomeScreen
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
    });

    testWidgets(
        'School admin is NOT kicked away when activeSchoolContextProvider is initially loading',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = _FakeSchoolContextNotifier(
        const ActiveSchoolContext.loading(),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => fakeNotifier,
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Not redirected to /home or /login! Screen remains on /school showing CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(StudentHomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);

      // Now active context completes loading
      fakeNotifier.updateState(activeAdminContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Screen transitions to full leadership dashboard
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
      expect(find.text('INSTITUTIONAL LEADERSHIP'), findsOneWidget);
    });

    testWidgets(
        'Dynamic router refresh: loading -> unauthorized redirects to /home and never builds protected screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = _FakeSchoolContextNotifier(
        const ActiveSchoolContext.loading(),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => fakeNotifier,
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Unresolved authority: displays neutral loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);

      // School context resolves as unauthorized (e.g. 0 memberships / independent learner)
      fakeNotifier.updateState(const ActiveSchoolContext.independent());

      // Trigger router refresh
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Redirected to /home; protected screen was NEVER built
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Dynamic router refresh: logout while on protected /school route redirects to /login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeUserNotifier =
          _SettableCurrentUserNotifier(MockAuthRepository(), adminUser);
      final fakeSchoolNotifier = _FakeSchoolContextNotifier(activeAdminContext);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => fakeUserNotifier),
          activeSchoolContextProvider.overrideWith((ref) => fakeSchoolNotifier),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully on /school
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);

      // User logs out -> currentUserProvider becomes null
      fakeUserNotifier.updateUser(null);
      fakeSchoolNotifier.updateState(const ActiveSchoolContext.independent());

      // Router's refreshListenable triggers recheck
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Redirected to /login
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Dynamic router refresh: membership revocation while on protected /school route redirects to /home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSchoolNotifier = _FakeSchoolContextNotifier(activeAdminContext);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith((ref) => fakeSchoolNotifier),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully on /school
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);

      // School membership is deactivated / revoked
      fakeSchoolNotifier.updateState(
        const ActiveSchoolContext.permissionRevoked(
          'Institutional membership was revoked.',
        ),
      );

      // Router's refreshListenable triggers recheck
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Redirected to /home
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Dynamic router refresh: account switch to student while on protected /school redirects to /home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeUserNotifier =
          _SettableCurrentUserNotifier(MockAuthRepository(), adminUser);
      final fakeSchoolNotifier = _FakeSchoolContextNotifier(activeAdminContext);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => fakeUserNotifier),
          activeSchoolContextProvider.overrideWith((ref) => fakeSchoolNotifier),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);

      // Switch account to student
      fakeUserNotifier.updateUser(studentUser);
      fakeSchoolNotifier.updateState(studentSchoolContext);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Denied access to /school -> redirected to /home
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Direct URL navigation to /school by platform admin redirects to /admin',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
                MockAuthRepository(), platformAdminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(
                const ActiveSchoolContext.independent()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Platform admin portal policy: /school redirects to /admin
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);
    });

    testWidgets(
        'Protected reporting route /school/reports denies unauthorized student',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), studentUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(studentSchoolContext),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school/reports',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(ReportsHubScreen), findsNothing);
    });

    testWidgets(
        'Protected reporting route /teacher/reports allows active teacher',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
          ),
          institutionalReportingRepositoryProvider.overrideWithValue(
            LocalInstitutionalReportingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher/reports',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReportsHubScreen), findsOneWidget);
    });

    testWidgets('Preserves normal student navigation from splash to /home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: studentUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: studentUser,
        sessionStorage: storage,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        subjects: const [],
        units: const [],
        topics: const [],
        questions: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
          ],
          child: const FidelLearnApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });

    testWidgets('Preserves normal teacher navigation from splash to /teacher',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: teacherUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: teacherUser,
        sessionStorage: storage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Preserves normal platform admin navigation from splash to /admin',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: platformAdminUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: platformAdminUser,
        sessionStorage: storage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const FidelLearnApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets(
        'Protected reporting route /school/reports allows student with active admin membership',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeAdminContext),
          ),
          institutionalReportingRepositoryProvider.overrideWithValue(
            LocalInstitutionalReportingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/school/reports',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReportsHubScreen), findsOneWidget);
    });

    testWidgets(
        'Protected reporting route /teacher/reports denies unauthorized student',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), studentUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(studentSchoolContext),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher/reports',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(ReportsHubScreen), findsNothing);
    });

    testWidgets(
        'Protected reporting route /school/reports/preview allows student with active admin membership',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), adminUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeAdminContext),
          ),
          institutionalReportingRepositoryProvider.overrideWithValue(
            LocalInstitutionalReportingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation:
            '/school/reports/preview?schoolId=sch_test_01&type=schoolPerformanceSummary',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReportPreviewScreen), findsOneWidget);
    });

    testWidgets(
        'Protected reporting route /school/reports/preview allows student with active teacher membership',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
          ),
          institutionalReportingRepositoryProvider.overrideWithValue(
            LocalInstitutionalReportingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation:
            '/school/reports/preview?schoolId=sch_test_01&type=subjectMasteryHeatmap',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReportPreviewScreen), findsOneWidget);
    });

    testWidgets(
        'Protected reporting route /school/reports/preview denies regular student',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), studentUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(studentSchoolContext),
          ),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation:
            '/school/reports/preview?schoolId=sch_test_01&type=schoolPerformanceSummary',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(ReportPreviewScreen), findsNothing);
    });

    test(
        'Cache isolation: cached context for previous user is rejected and purged for a different signed-in user',
        () async {
      final storage = AuthSessionStorage();
      await storage.clearSchoolContext();

      // Seed cached context belonging to usr_school_admin
      await storage.saveCachedSchoolContext(
        CachedSchoolContext(
          schoolId: 'sch_test_01',
          schoolName: 'Addis Ababa High School',
          schoolCode: 'AAS-001',
          membershipId: 'mem_admin_01',
          membershipRole: SchoolMemberRole.schoolAdmin,
          membershipStatus: SchoolMembershipStatus.active,
          userId: 'usr_school_admin',
          cachedAt: DateTime.now(),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              studentUser, // id: 'usr_student' != 'usr_school_admin'
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(_EmptySchoolRepo()),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);
      final resolved = await notifier.resolveContext(user: studentUser);

      // Student user does NOT inherit usr_school_admin's cached admin context!
      expect(resolved.isSchoolAdmin, isFalse);
      expect(resolved.status, equals(ActiveSchoolContextStatus.independent));

      // Cache from storage was completely purged
      final remainingCache = await storage.getCachedSchoolContext();
      expect(remainingCache, isNull);
    });

    test(
        'ActiveSchoolContextNotifier.resolveContext sets loading state synchronously before cache read',
        () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              studentUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(_EmptySchoolRepo()),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);
      final future = notifier.resolveContext(user: adminUser);

      // Synchronously immediately after calling, state must be loading
      expect(notifier.state.isLoading, isTrue);

      await future;
    });

    testWidgets(
        'Slow school context resolution (> 4s) does not route to /home prematurely and lands on /school when resolved',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: adminUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: adminUser,
        sessionStorage: storage,
      );

      final completer = Completer<ActiveSchoolContext>();
      final slowFakeNotifier = _ControlledSchoolContextNotifier(
        const ActiveSchoolContext.loading(),
        completer,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            schoolLeadershipRepositoryProvider
                .overrideWithValue(LocalSchoolLeadershipRepository()),
            activeSchoolContextProvider.overrideWith(
              (ref) => slowFakeNotifier,
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      // Settle initial splash delay
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Advance past the 4-second timeout threshold
      await tester.pump(const Duration(seconds: 4));

      // Assert user is NOT sent to /home merely because 4s expired while loading
      expect(find.byType(StudentHomeScreen), findsNothing);
      expect(find.byType(SchoolLeadershipHomeScreen), findsNothing);

      // Assert informative slow-resolution state is displayed without an indefinite blank screen
      expect(find.text('Checking school membership...'), findsOneWidget);
      expect(find.text('Continue to Home'), findsOneWidget);

      // Now active admin membership lookup resolves
      completer.complete(activeAdminContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Successfully landed on /school
      expect(find.byType(SchoolLeadershipHomeScreen), findsOneWidget);
      expect(find.byType(StudentHomeScreen), findsNothing);
    });

    testWidgets(
        'Slow school context resolution (> 4s) routes to /home only after actually resolving as independent',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      await storage.saveSession(user: studentUser, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: studentUser,
        sessionStorage: storage,
      );

      final completer = Completer<ActiveSchoolContext>();
      final slowFakeNotifier = _ControlledSchoolContextNotifier(
        const ActiveSchoolContext.loading(),
        completer,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider
                .overrideWithValue(LocalContentRepository()),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
            activeSchoolContextProvider.overrideWith(
              (ref) => slowFakeNotifier,
            ),
          ],
          child: const FidelLearnApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));

      // Not routed to /home yet
      expect(find.byType(StudentHomeScreen), findsNothing);
      expect(find.text('Checking school membership...'), findsOneWidget);

      // Resolves as independent
      completer.complete(const ActiveSchoolContext.independent());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Now routes to /home after actual independent resolution
      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });

    test(
        'selectSchool settles deterministically on unavailable school ID without leaving loading indefinitely',
        () async {
      final storage = AuthSessionStorage();
      await storage.clearSchoolContext();

      final fakeSchoolRepo = _MockMultiSchoolRepo(
        schools: [
          SchoolMembershipWithSchool(
            school: testSchool,
            membership: adminMembership,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              adminUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(fakeSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);
      await notifier.resolveContext(user: adminUser);
      expect(notifier.state.isSchoolAdmin, isTrue);

      // Now try to select an unavailable school ID
      await notifier.selectSchool('sch_non_existent');

      // Must settle deterministically into error state, NOT remain loading
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.status, equals(ActiveSchoolContextStatus.error));
      expect(notifier.state.errorMessage, contains('sch_non_existent'));
    });

    test(
        'selectSchool settles deterministically on repository failure without leaving loading indefinitely',
        () async {
      final storage = AuthSessionStorage();
      await storage.clearSchoolContext();

      final failingSchoolRepo = _FailingSchoolRepo();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              adminUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(failingSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);

      // Attempt to select school with failing repository
      await notifier.selectSchool(testSchool.id);

      // Must settle deterministically into error state, NOT remain loading
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.status, equals(ActiveSchoolContextStatus.error));
      expect(notifier.state.errorMessage, contains('Network timeout'));
    });

    test(
        'Older in-flight resolveContext does not overwrite newer selectSchool or its cache',
        () async {
      final storage = AuthSessionStorage();
      await storage.clearSchoolContext();

      final schoolA = testSchool;
      final schoolB = School(
        id: 'sch_test_02',
        name: 'Hawassa High School',
        schoolCode: 'HHS-002',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memA = SchoolMembership(
        id: 'mem_a',
        schoolId: schoolA.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memB = SchoolMembership(
        id: 'mem_b',
        schoolId: schoolB.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dualUser = UserProfile(
        id: 'usr_dual_role',
        phoneNumber: '+251977889900',
        displayName: 'Dual Staff Member',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final slowSchoolRepo = _ControllableMultiSchoolRepo(
        entries: [
          SchoolMembershipWithSchool(school: schoolA, membership: memA),
          SchoolMembershipWithSchool(school: schoolB, membership: memB),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              dualUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(slowSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);

      // 1. Start a slow resolveContext (older request, epoch 1)
      final resolveFuture = notifier.resolveContext(user: dualUser);

      // 2. While resolveContext is paused in-flight at getMySchools, call selectSchool(schoolB.id) (newer request, epoch 2)
      slowSchoolRepo.enableImmediateForSelect();
      final selectFuture = notifier.selectSchool(schoolB.id);
      await selectFuture;

      // Assert that selectSchool completed and set School B (Teacher)
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(notifier.state.isTeacher, isTrue);
      expect(notifier.state.isSchoolAdmin, isFalse);

      // Check that cache has schoolB
      var cached = await storage.getCachedSchoolContext();
      expect(cached?.schoolId, equals(schoolB.id));
      expect(cached?.membershipRole, equals(SchoolMemberRole.teacher));

      // 3. Now release the older resolveContext request
      slowSchoolRepo.releaseResolve();
      await resolveFuture;

      // 4. Crucial invariant: Older resolveContext MUST NOT have overwritten School B with School A!
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(notifier.state.isTeacher, isTrue);
      expect(notifier.state.isSchoolAdmin, isFalse);

      cached = await storage.getCachedSchoolContext();
      expect(cached?.schoolId, equals(schoolB.id));
      expect(cached?.membershipRole, equals(SchoolMemberRole.teacher));
    });

    test(
        'Switching between school-admin and teacher memberships updates roles and providers deterministically',
        () async {
      final storage = AuthSessionStorage();
      await storage.clearSchoolContext();

      final schoolA = testSchool;
      final schoolB = School(
        id: 'sch_test_02',
        name: 'Hawassa High School',
        schoolCode: 'HHS-002',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memA = SchoolMembership(
        id: 'mem_a',
        schoolId: schoolA.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memB = SchoolMembership(
        id: 'mem_b',
        schoolId: schoolB.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dualUser = UserProfile(
        id: 'usr_dual_role',
        phoneNumber: '+251977889900',
        displayName: 'Dual Staff Member',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final multiRepo = _MockMultiSchoolRepo(
        schools: [
          SchoolMembershipWithSchool(school: schoolA, membership: memA),
          SchoolMembershipWithSchool(school: schoolB, membership: memB),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              dualUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(multiRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);
      await notifier.resolveContext(user: dualUser);

      // Initially on School A (admin)
      expect(notifier.state.school?.id, equals(schoolA.id));
      expect(notifier.state.isSchoolAdmin, isTrue);
      expect(notifier.state.isTeacher, isFalse);

      // Switch to School B (teacher)
      await notifier.selectSchool(schoolB.id);
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(notifier.state.isSchoolAdmin, isFalse);
      expect(notifier.state.isTeacher, isTrue);

      // Switch back to School A (admin)
      await notifier.selectSchool(schoolA.id);
      expect(notifier.state.school?.id, equals(schoolA.id));
      expect(notifier.state.isSchoolAdmin, isTrue);
      expect(notifier.state.isTeacher, isFalse);
    });

    test(
        'Older resolveContext paused inside storage write cannot overwrite newer selection or its persisted values',
        () async {
      AuthSessionStorage.resetForTesting();
      final schoolA = School(
        id: 'sch_store_01',
        name: 'School One',
        displayName: 'School One',
        schoolCode: 'SCH-01',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final schoolB = School(
        id: 'sch_store_02',
        name: 'School Two',
        displayName: 'School Two',
        schoolCode: 'SCH-02',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final memA = SchoolMembership(
        id: 'mem_store_01',
        schoolId: schoolA.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final memB = SchoolMembership(
        id: 'mem_store_02',
        schoolId: schoolB.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final dualUser = UserProfile(
        id: 'usr_dual_role',
        phoneNumber: '+251977889900',
        displayName: 'Dual Staff Member',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      final multiRepo = _MockMultiSchoolRepo(
        schools: [
          SchoolMembershipWithSchool(school: schoolA, membership: memA),
          SchoolMembershipWithSchool(school: schoolB, membership: memB),
        ],
      );

      final storage = _PausingStorage();
      storage.pauseOnVersion = 2;
      storage.writePauseCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              dualUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(multiRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
          activeSchoolContextProvider.overrideWith(
            (ref) => ActiveSchoolContextNotifier(
              schoolRepo: multiRepo,
              classroomRepo: _EmptyClassroomRepo(),
              storage: storage,
              ref: ref,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);

      // Start older operation (resolveContext, version 2)
      final op1Future = notifier.resolveContext(user: dualUser);
      // Give resolveContext time to fetch schools and pause inside commitSchoolContext
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Newer selection (selectSchool to schoolB, version 3) runs and completes
      await notifier.selectSchool(schoolB.id);

      // Verify that newer selection succeeded immediately
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(await storage.getActiveSchoolId(), equals(schoolB.id));
      final cachedMid = await storage.getCachedSchoolContext();
      expect(cachedMid?.schoolId, equals(schoolB.id));

      // Now release the older operation's storage write
      storage.writePauseCompleter!.complete();
      await op1Future;

      // Verify that older write was discarded and NEVER overwrote state or storage
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(await storage.getActiveSchoolId(), equals(schoolB.id));
      final cachedFinal = await storage.getCachedSchoolContext();
      expect(cachedFinal?.schoolId, equals(schoolB.id));
      expect(await storage.getSchoolContextVersion(), equals(3));
    });

    test(
        'Older selectSchool paused inside storage write cannot overwrite newer selectSchool or its persisted values',
        () async {
      AuthSessionStorage.resetForTesting();
      final schoolA = School(
        id: 'sch_store_01',
        name: 'School One',
        displayName: 'School One',
        schoolCode: 'SCH-01',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final schoolB = School(
        id: 'sch_store_02',
        name: 'School Two',
        displayName: 'School Two',
        schoolCode: 'SCH-02',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final memA = SchoolMembership(
        id: 'mem_store_01',
        schoolId: schoolA.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final memB = SchoolMembership(
        id: 'mem_store_02',
        schoolId: schoolB.id,
        userId: 'usr_dual_role',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final dualUser = UserProfile(
        id: 'usr_dual_role',
        phoneNumber: '+251977889900',
        displayName: 'Dual Staff Member',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      final multiRepo = _MockMultiSchoolRepo(
        schools: [
          SchoolMembershipWithSchool(school: schoolA, membership: memA),
          SchoolMembershipWithSchool(school: schoolB, membership: memB),
        ],
      );

      final storage = _PausingStorage();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _SettableCurrentUserNotifier(
              MockAuthRepository(),
              dualUser,
            ),
          ),
          schoolRepositoryProvider.overrideWithValue(multiRepo),
          classroomRepositoryProvider.overrideWithValue(_EmptyClassroomRepo()),
          activeSchoolContextProvider.overrideWith(
            (ref) => ActiveSchoolContextNotifier(
              schoolRepo: multiRepo,
              classroomRepo: _EmptyClassroomRepo(),
              storage: storage,
              ref: ref,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSchoolContextProvider.notifier);
      await notifier.resolveContext(user: dualUser); // version 2 completes

      // Configure pause on version 3 (first selectSchool)
      storage.pauseOnVersion = 3;
      storage.writePauseCompleter = Completer<void>();

      final opA = notifier.selectSchool(schoolA.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Fast selectSchool to schoolB (version 4) runs and completes
      await notifier.selectSchool(schoolB.id);

      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(await storage.getActiveSchoolId(), equals(schoolB.id));

      // Release older selectSchool write
      storage.writePauseCompleter!.complete();
      await opA;

      // Both state and persisted values remain schoolB
      expect(notifier.state.school?.id, equals(schoolB.id));
      expect(await storage.getActiveSchoolId(), equals(schoolB.id));
      final cached = await storage.getCachedSchoolContext();
      expect(cached?.schoolId, equals(schoolB.id));
      expect(await storage.getSchoolContextVersion(), equals(4));
    });

    testWidgets(
        'Direct URL navigation to /teacher by global student with active teacher membership lands on /teacher',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser),
          ),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Direct URL navigation to nested institutional /teacher routes by active teacher lands on protected screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCases = [
        ('/teacher/assignments', TeacherAssignmentCenterScreen),
        ('/teacher/interventions', TeacherInterventionCenterScreen),
        ('/teacher/class/cls_1/sub_1', TeacherClassDetailScreen),
        ('/teacher/class/cls_1/sub_1/roster', TeacherClassRosterScreen),
        ('/teacher/class/cls_1/sub_1/attention', TeacherAttentionScreen),
        (
          '/teacher/class/cls_1/sub_1/student/stu_1',
          TeacherStudentSummaryScreen
        ),
      ];

      for (final testCase in testCases) {
        final path = testCase.$1;
        final screenType = testCase.$2;

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => _SettableCurrentUserNotifier(
                  MockAuthRepository(), teacherUser),
            ),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
            ),
          ],
        );

        final router = createAppRouter(
          initialLocation: path,
          container: container,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(screenType), findsOneWidget,
            reason: 'Path $path should mount $screenType');
        container.dispose();
      }
    });

    testWidgets(
        'Direct URL navigation to /teacher and nested routes by unauthenticated user redirects to /login',
        (WidgetTester tester) async {
      final paths = [
        '/teacher',
        '/teacher/assignments',
        '/teacher/interventions',
        '/teacher/class/cls_1/sub_1',
      ];

      for (final path in paths) {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => _SettableCurrentUserNotifier(MockAuthRepository(), null),
            ),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(
                  const ActiveSchoolContext.independent()),
            ),
          ],
        );

        final router = createAppRouter(
          initialLocation: path,
          container: container,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget,
            reason:
                'Unauthenticated path $path should redirect to LoginScreen');
        container.dispose();
      }
    });

    testWidgets(
        'Direct URL navigation to /teacher and nested routes by student without teacher membership redirects to /home',
        (WidgetTester tester) async {
      final paths = [
        '/teacher',
        '/teacher/assignments',
        '/teacher/interventions',
        '/teacher/class/cls_1/sub_1',
      ];

      for (final path in paths) {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => _SettableCurrentUserNotifier(
                  MockAuthRepository(), studentUser),
            ),
            activeSchoolContextProvider.overrideWith(
              (ref) => _FakeSchoolContextNotifier(studentSchoolContext),
            ),
            contentRepositoryProvider
                .overrideWithValue(LocalContentRepository()),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
          ],
        );

        final router = createAppRouter(
          initialLocation: path,
          container: container,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));

        expect(find.byType(StudentHomeScreen), findsOneWidget,
            reason:
                'Unauthorized student path $path should redirect to StudentHomeScreen');
        container.dispose();
      }
    });

    testWidgets(
        'Teacher is NOT kicked away when activeSchoolContextProvider is initially loading and screen stays unmounted',
        (WidgetTester tester) async {
      final contextNotifier =
          _ControlledSchoolContextNotifier(const ActiveSchoolContext.loading());

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser),
          ),
          activeSchoolContextProvider.overrideWith((ref) => contextNotifier),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // In neutral loading state:
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TeacherHomeScreen), findsNothing);
      expect(find.byType(StudentHomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);

      // Context finishes loading as teacher:
      contextNotifier.update(activeTeacherContext);
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets(
        'Dynamic router refresh: logout while on protected /teacher route redirects to /login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userNotifier =
          _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => userNotifier),
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeTeacherContext),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomeScreen), findsOneWidget);

      // Simulate logout
      userNotifier.updateUser(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TeacherHomeScreen), findsNothing);
    });

    testWidgets(
        'Dynamic router refresh: membership revocation while on protected /teacher route redirects to /home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final contextNotifier =
          _ControlledSchoolContextNotifier(activeTeacherContext);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) =>
                _SettableCurrentUserNotifier(MockAuthRepository(), teacherUser),
          ),
          activeSchoolContextProvider.overrideWith((ref) => contextNotifier),
          contentRepositoryProvider.overrideWithValue(LocalContentRepository()),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createAppRouter(
        initialLocation: '/teacher',
        container: container,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomeScreen), findsOneWidget);

      // Revoke membership
      contextNotifier.update(
        const ActiveSchoolContext.permissionRevoked(
          'Your teacher membership has been revoked.',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(TeacherHomeScreen), findsNothing);
    });
  });
}
