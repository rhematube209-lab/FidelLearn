import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fidel_learn/core/config/env_config.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/local_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_classroom_repository.dart';
import 'package:fidel_learn/features/school/presentation/providers/institutional_reporting_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/licensing_onboarding_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/school_leadership_providers.dart';
import 'package:fidel_learn/features/teacher/data/repositories/local_teacher_portal_repository.dart';
import 'package:fidel_learn/features/teacher/data/repositories/supabase_teacher_portal_repository.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/teacher_portal_providers.dart'
    as feature_tp;

void main() {
  setUp(() {
    EnvConfig.resetTestOverrides();
  });

  tearDown(() {
    EnvConfig.resetTestOverrides();
  });

  group('Priority 1 — Fail-Closed Startup & Provider Wiring', () {
    test(
        'In development without credentials, providers select safe local/mock fallbacks',
        () {
      EnvConfig.overrideEnvironment = 'development';
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Auth repository resolves to MockAuthRepository in offline dev
      expect(
        container.read(authRepositoryProvider),
        isA<MockAuthRepository>(),
      );

      // Teacher portal repository resolves to LocalTeacherPortalRepository
      expect(
        container.read(teacherPortalRepositoryProvider),
        isA<LocalTeacherPortalRepository>(),
      );
      expect(
        container.read(feature_tp.teacherPortalRepositoryProvider),
        isA<LocalTeacherPortalRepository>(),
      );

      // School leadership resolves to LocalSchoolLeadershipRepository
      expect(
        container.read(schoolLeadershipRepositoryProvider),
        isA<LocalSchoolLeadershipRepository>(),
      );

      // Licensing resolves to LocalLicensingOnboardingRepository
      expect(
        container.read(licensingOnboardingRepositoryProvider),
        isA<LocalLicensingOnboardingRepository>(),
      );

      // Institutional reporting resolves to LocalInstitutionalReportingRepository
      expect(
        container.read(institutionalReportingRepositoryProvider),
        isA<LocalInstitutionalReportingRepository>(),
      );
    });

    test(
        'In staging/pilot/production without credentials, institutional providers fail closed with StateError',
        () {
      const prodLikeEnvs = ['staging', 'pilot', 'production'];

      for (final env in prodLikeEnvs) {
        EnvConfig.overrideEnvironment = env;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Auth repo must throw StateError rather than activating MockAuthRepository
        expect(
          () => container.read(authRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason: '$env must fail closed on authRepositoryProvider',
        );

        // Teacher portal repo must throw StateError rather than activating LocalTeacherPortalRepository
        expect(
          () => container.read(teacherPortalRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason: '$env must fail closed on teacherPortalRepositoryProvider',
        );
        expect(
          () => container.read(feature_tp.teacherPortalRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason:
              '$env must fail closed on feature_tp.teacherPortalRepositoryProvider',
        );

        // School leadership repo must throw StateError
        expect(
          () => container.read(schoolLeadershipRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason: '$env must fail closed on schoolLeadershipRepositoryProvider',
        );

        // Licensing onboarding repo must throw StateError
        expect(
          () => container.read(licensingOnboardingRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason:
              '$env must fail closed on licensingOnboardingRepositoryProvider',
        );

        // Institutional reporting repo must throw StateError
        expect(
          () => container.read(institutionalReportingRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Supabase credentials are required'),
              contains(env),
            ),
          )),
          reason:
              '$env must fail closed on institutionalReportingRepositoryProvider',
        );

        // School and classroom repos must throw StateError when credentials missing
        expect(
          () => container.read(schoolRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Supabase credentials are required'),
          )),
          reason: '$env must fail closed on schoolRepositoryProvider',
        );

        expect(
          () => container.read(classroomRepositoryProvider),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Supabase credentials are required'),
          )),
          reason: '$env must fail closed on classroomRepositoryProvider',
        );
      }
    });

    test(
        'In staging/pilot/production with valid credentials, real Supabase repositories are selected',
        () {
      EnvConfig.overrideEnvironment = 'pilot';
      EnvConfig.overrideSupabaseUrl = 'https://api.fidellearn.et';
      EnvConfig.overrideSupabasePublishableKey =
          'client_safe_publishable_anon_key';

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(authRepositoryProvider),
        isA<SupabaseAuthRepository>(),
      );

      expect(
        container.read(teacherPortalRepositoryProvider),
        isA<SupabaseTeacherPortalRepository>(),
      );

      expect(
        container.read(feature_tp.teacherPortalRepositoryProvider),
        isA<SupabaseTeacherPortalRepository>(),
      );

      expect(
        container.read(schoolLeadershipRepositoryProvider),
        isA<SupabaseSchoolLeadershipRepository>(),
      );

      expect(
        container.read(licensingOnboardingRepositoryProvider),
        isA<SupabaseLicensingOnboardingRepository>(),
      );

      expect(
        container.read(institutionalReportingRepositoryProvider),
        isA<SupabaseInstitutionalReportingRepository>(),
      );

      expect(
        container.read(schoolRepositoryProvider),
        isA<SupabaseSchoolRepository>(),
      );

      expect(
        container.read(classroomRepositoryProvider),
        isA<SupabaseClassroomRepository>(),
      );
    });
  });
}
