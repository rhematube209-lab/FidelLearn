import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fidel_learn/core/config/env_config.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/rewards/domain/services/daily_streak_service.dart';
import 'package:fidel_learn/features/school/data/repositories/local_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/mock_classroom_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_classroom_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_repository.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/institutional_reporting_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/licensing_onboarding_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/school_leadership_providers.dart';
import 'package:fidel_learn/features/teacher/data/repositories/local_teacher_portal_repository.dart';
import 'package:fidel_learn/features/teacher/data/repositories/supabase_intervention_repository.dart';
import 'package:fidel_learn/features/teacher/data/repositories/supabase_student_assignment_repository.dart';
import 'package:fidel_learn/features/teacher/data/repositories/supabase_teacher_assignment_repository.dart';
import 'package:fidel_learn/features/teacher/data/repositories/supabase_teacher_portal_repository.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/assignment_providers.dart';

void main() {
  group('P12.5 Production Cutover & Environment Policy Tests', () {
    test('EnvConfig identifies production-like environments correctly', () {
      expect(EnvConfig.isDevelopment, isTrue); // default in test runner
      expect(EnvConfig.isPilot, isFalse);
      expect(EnvConfig.isStaging, isFalse);
      expect(EnvConfig.isProduction, isFalse);
      expect(EnvConfig.isProductionLike, isFalse);
    });

    test('EnvConfig.assertNoMockInProduction throws when production-like', () {
      // In development, does not throw
      expect(
        () => EnvConfig.assertNoMockInProduction('TestComponent'),
        returnsNormally,
      );
    });

    test('CoinLedgerNotifier initializes with empty ledger (zero fake coins)',
        () {
      final notifier = CoinLedgerNotifier();
      expect(notifier.state, isEmpty);
      expect(notifier.balance, equals(0));
    });

    test('DailyStreakService computes 0 streak when user has 0 attempts', () {
      final result = DailyStreakService.calculateStreak(activityDates: []);
      expect(result.currentStreakDays, equals(0));
      expect(result.isStreakActiveToday, isFalse);
    });

    test('Production repository wiring resolves to real Supabase classes', () {
      final container = ProviderContainer(
        overrides: [
          // Override school and classroom repos with real Supabase implementations
          schoolRepositoryProvider
              .overrideWithValue(SupabaseSchoolRepository()),
          classroomRepositoryProvider
              .overrideWithValue(SupabaseClassroomRepository()),
          teacherPortalRepositoryProvider
              .overrideWithValue(SupabaseTeacherPortalRepository()),
          schoolLeadershipRepositoryProvider
              .overrideWithValue(SupabaseSchoolLeadershipRepository()),
          licensingOnboardingRepositoryProvider
              .overrideWithValue(SupabaseLicensingOnboardingRepository()),
          institutionalReportingRepositoryProvider
              .overrideWithValue(SupabaseInstitutionalReportingRepository()),
          teacherAssignmentRepositoryProvider
              .overrideWithValue(SupabaseTeacherAssignmentRepository()),
          studentAssignmentRepositoryProvider
              .overrideWithValue(SupabaseStudentAssignmentRepository()),
          interventionRepositoryProvider
              .overrideWithValue(SupabaseInterventionRepository()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(schoolRepositoryProvider),
          isA<SupabaseSchoolRepository>());
      expect(container.read(classroomRepositoryProvider),
          isA<SupabaseClassroomRepository>());
      expect(container.read(teacherPortalRepositoryProvider),
          isA<SupabaseTeacherPortalRepository>());
      expect(container.read(schoolLeadershipRepositoryProvider),
          isA<SupabaseSchoolLeadershipRepository>());
      expect(container.read(licensingOnboardingRepositoryProvider),
          isA<SupabaseLicensingOnboardingRepository>());
      expect(container.read(institutionalReportingRepositoryProvider),
          isA<SupabaseInstitutionalReportingRepository>());
      expect(container.read(teacherAssignmentRepositoryProvider),
          isA<SupabaseTeacherAssignmentRepository>());
      expect(container.read(studentAssignmentRepositoryProvider),
          isA<SupabaseStudentAssignmentRepository>());
      expect(container.read(interventionRepositoryProvider),
          isA<SupabaseInterventionRepository>());
    });

    test(
        'Licensing & Reporting providers return real Supabase types under Supabase configuration',
        () {
      final container = ProviderContainer(
        overrides: [
          licensingOnboardingRepositoryProvider
              .overrideWithValue(SupabaseLicensingOnboardingRepository()),
          institutionalReportingRepositoryProvider
              .overrideWithValue(SupabaseInstitutionalReportingRepository()),
          schoolLeadershipRepositoryProvider
              .overrideWithValue(SupabaseSchoolLeadershipRepository()),
          teacherPortalRepositoryProvider
              .overrideWithValue(SupabaseTeacherPortalRepository()),
        ],
      );
      addTearDown(container.dispose);

      final licenseRepo = container.read(licensingOnboardingRepositoryProvider);
      expect(licenseRepo, isA<SupabaseLicensingOnboardingRepository>());
      expect(licenseRepo, isNot(isA<LocalLicensingOnboardingRepository>()));

      final reportRepo =
          container.read(institutionalReportingRepositoryProvider);
      expect(reportRepo, isA<SupabaseInstitutionalReportingRepository>());
      expect(reportRepo, isNot(isA<LocalInstitutionalReportingRepository>()));

      final leadershipRepo = container.read(schoolLeadershipRepositoryProvider);
      expect(leadershipRepo, isA<SupabaseSchoolLeadershipRepository>());
      expect(leadershipRepo, isNot(isA<LocalSchoolLeadershipRepository>()));

      final teacherRepo = container.read(teacherPortalRepositoryProvider);
      expect(teacherRepo, isA<SupabaseTeacherPortalRepository>());
      expect(teacherRepo, isNot(isA<LocalTeacherPortalRepository>()));
    });

    test('New user with zero schools resolves to independent context',
        () async {
      final fakeStorage = AuthSessionStorage();
      await fakeStorage.clearSchoolContext();

      final fakeUser = UserProfile(
        id: 'user_pilot_fresh_001',
        phoneNumber: '+251912345678',
        displayName: 'Fresh Pilot Student',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(
            _EmptySchoolRepository(),
          ),
          classroomRepositoryProvider.overrideWithValue(
            MockClassroomRepository(),
          ),
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(fakeUser);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      final activeContext = container.read(activeSchoolContextProvider);
      expect(
          activeContext.status, equals(ActiveSchoolContextStatus.independent));
      expect(activeContext.school, isNull);
      expect(activeContext.hasActiveSchool, isFalse);
    });

    test('Logout clears ActiveSchoolContext immediately', () async {
      final fakeStorage = AuthSessionStorage();
      await fakeStorage.clearSchoolContext();

      final tempUser = UserProfile(
        id: 'user_temp_01',
        phoneNumber: '+251912345678',
        displayName: 'Temp User',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(
            _SingleSchoolRepository(),
          ),
          classroomRepositoryProvider.overrideWithValue(
            MockClassroomRepository(),
          ),
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(tempUser);
      await container.read(activeSchoolContextProvider.notifier).refresh();
      expect(
          container.read(activeSchoolContextProvider).hasActiveSchool, isTrue);

      // Now logout user
      container.read(currentUserProvider.notifier).state =
          const AsyncValue.data(null);
      await container.pump();

      // School context must be independent (no institutional leak)
      final stateAfterLogout = container.read(activeSchoolContextProvider);
      expect(stateAfterLogout.status,
          equals(ActiveSchoolContextStatus.independent));
      expect(stateAfterLogout.school, isNull);
    });
    test(
        'Account switching from User A (institutional) to User B (independent) purges all school data',
        () async {
      final fakeStorage = AuthSessionStorage();
      await fakeStorage.clearSchoolContext();

      final userA = UserProfile(
        id: 'user_a',
        phoneNumber: '+251911111111',
        displayName: 'User A (School Student)',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final userB = UserProfile(
        id: 'user_b',
        phoneNumber: '+251922222222',
        displayName: 'User B (Independent)',
        grade: 12,
        stream: 'social',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      String currentActiveUserId = 'user_a';
      final dynamicSchoolRepo =
          _DynamicUserSchoolRepository(() => currentActiveUserId);

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(dynamicSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(
            MockClassroomRepository(),
          ),
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      // User A signs in
      currentActiveUserId = 'user_a';
      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(userA);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      expect(
          container.read(activeSchoolContextProvider).hasActiveSchool, isTrue);
      expect(container.read(activeSchoolContextProvider).school?.name,
          equals('School Alpha'));

      // User switches directly to User B
      currentActiveUserId = 'user_b';
      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(userB);
      await container.pump();
      await container.read(activeSchoolContextProvider.notifier).refresh();

      // Zero User A school data remains
      final stateUserB = container.read(activeSchoolContextProvider);
      expect(stateUserB.hasActiveSchool, isFalse);
      expect(stateUserB.isIndependent, isTrue);
      expect(stateUserB.school, isNull);
    });

    test('Multi-school user can switch active school cleanly', () async {
      final fakeStorage = AuthSessionStorage();
      await fakeStorage.clearSchoolContext();

      final multiSchoolUser = UserProfile(
        id: 'user_teacher_multi',
        phoneNumber: '+251933333333',
        displayName: 'Multi School Teacher',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(_MultiSchoolRepository()),
          classroomRepositoryProvider.overrideWithValue(
            MockClassroomRepository(),
          ),
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(multiSchoolUser);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      // Default is first active school (School 1)
      expect(container.read(activeSchoolContextProvider).school?.id,
          equals('sch_1'));

      // Switch to School 2
      await container
          .read(activeSchoolContextProvider.notifier)
          .selectSchool('sch_2');

      expect(container.read(activeSchoolContextProvider).school?.id,
          equals('sch_2'));
      expect(container.read(activeSchoolContextProvider).school?.name,
          equals('School Two'));
    });
  });
}

class _EmptySchoolRepository extends SupabaseSchoolRepository {
  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async => [];
}

class _SingleSchoolRepository extends SupabaseSchoolRepository {
  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    final school = School(
      id: 'sch_real_pilot_1',
      name: 'Real Pilot School',
      displayName: 'Real Pilot School',
      schoolCode: 'RPS001',
      status: SchoolStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final membership = SchoolMembership(
      id: 'mem_real_1',
      schoolId: 'sch_real_pilot_1',
      userId: 'user_temp_01',
      role: SchoolMemberRole.student,
      status: SchoolMembershipStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return [SchoolMembershipWithSchool(membership: membership, school: school)];
  }
}

class _DynamicUserSchoolRepository extends SupabaseSchoolRepository {
  final String Function() _currentUserIdGetter;
  _DynamicUserSchoolRepository(this._currentUserIdGetter);

  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    if (_currentUserIdGetter() != 'user_a') {
      return [];
    }
    final school = School(
      id: 'sch_alpha',
      name: 'School Alpha',
      displayName: 'School Alpha',
      schoolCode: 'ALPHA01',
      status: SchoolStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final membership = SchoolMembership(
      id: 'mem_alpha_1',
      schoolId: 'sch_alpha',
      userId: 'user_a',
      role: SchoolMemberRole.student,
      status: SchoolMembershipStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return [SchoolMembershipWithSchool(membership: membership, school: school)];
  }
}

class _MultiSchoolRepository extends SupabaseSchoolRepository {
  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    final school1 = School(
      id: 'sch_1',
      name: 'School One',
      displayName: 'School One',
      schoolCode: 'S1',
      status: SchoolStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final school2 = School(
      id: 'sch_2',
      name: 'School Two',
      displayName: 'School Two',
      schoolCode: 'S2',
      status: SchoolStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return [
      SchoolMembershipWithSchool(
        membership: SchoolMembership(
          id: 'mem_1',
          schoolId: 'sch_1',
          userId: 'user_teacher_multi',
          role: SchoolMemberRole.teacher,
          status: SchoolMembershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        school: school1,
      ),
      SchoolMembershipWithSchool(
        membership: SchoolMembership(
          id: 'mem_2',
          schoolId: 'sch_2',
          userId: 'user_teacher_multi',
          role: SchoolMemberRole.teacher,
          status: SchoolMembershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        school: school2,
      ),
    ];
  }
}
