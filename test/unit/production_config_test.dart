import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/config/env_config.dart';

void main() {
  setUp(() {
    EnvConfig.resetTestOverrides();
  });

  tearDown(() {
    EnvConfig.resetTestOverrides();
  });

  group('EnvConfig — fail-closed behavior', () {
    test('isSupabaseConfigured is false when URL is empty', () {
      expect(EnvConfig.supabaseUrl, isEmpty);
      expect(EnvConfig.supabasePublishableKey, isEmpty);
      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('isSupabaseConfigured is true when both credentials are present', () {
      EnvConfig.overrideSupabaseUrl = 'https://example.supabase.co';
      EnvConfig.overrideSupabasePublishableKey = 'test_pub_key';
      expect(EnvConfig.isSupabaseConfigured, isTrue);
    });

    test('isSupabaseConfigured is false if only one credential is present', () {
      EnvConfig.overrideSupabaseUrl = 'https://example.supabase.co';
      EnvConfig.overrideSupabasePublishableKey = '';
      expect(EnvConfig.isSupabaseConfigured, isFalse);

      EnvConfig.overrideSupabaseUrl = '';
      EnvConfig.overrideSupabasePublishableKey = 'test_pub_key';
      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('isolated demo ignores Supabase variables even when supplied', () {
      EnvConfig.overrideEnvironment = 'demo';
      EnvConfig.overrideSupabaseUrl = 'https://example.supabase.co';
      EnvConfig.overrideSupabasePublishableKey = 'test_pub_key';
      expect(EnvConfig.isDemo, isTrue);
      expect(EnvConfig.isProductionLike, isFalse);
      expect(EnvConfig.isSupabaseConfigured, isFalse);
      expect(EnvConfig.requireSupabase, isFalse);
    });

    test('appEnvironment defaults to development', () {
      expect(EnvConfig.appEnvironment, equals('development'));
      expect(EnvConfig.isDevelopment, isTrue);
      expect(EnvConfig.isStaging, isFalse);
      expect(EnvConfig.isPilot, isFalse);
      expect(EnvConfig.isProduction, isFalse);
      expect(EnvConfig.isProductionLike, isFalse);
    });

    test(
        'requireSupabase returns false in development when credentials missing',
        () {
      expect(
        () => EnvConfig.requireSupabase,
        returnsNormally,
      );
      expect(EnvConfig.requireSupabase, isFalse);
    });

    test(
        'requireSupabase throws StateError in staging, pilot, and production when credentials missing',
        () {
      const productionLikeEnvs = ['staging', 'pilot', 'production'];

      for (final env in productionLikeEnvs) {
        EnvConfig.overrideEnvironment = env;
        expect(EnvConfig.isProductionLike, isTrue,
            reason: '$env should be production-like');

        expect(
          () => EnvConfig.requireSupabase,
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY'),
              contains(env),
            ),
          )),
          reason: '$env must fail closed when credentials are missing',
        );
      }
    });

    test(
        'requireSupabase returns true in staging, pilot, and production when credentials present',
        () {
      EnvConfig.overrideSupabaseUrl = 'https://project.supabase.co';
      EnvConfig.overrideSupabasePublishableKey = 'client_safe_anon_key';

      const productionLikeEnvs = ['staging', 'pilot', 'production'];

      for (final env in productionLikeEnvs) {
        EnvConfig.overrideEnvironment = env;
        expect(EnvConfig.requireSupabase, isTrue,
            reason: '$env with valid configuration must return true');
      }
    });

    test('assertNoMockInProduction throws StateError only when production-like',
        () {
      // In development, does not throw
      EnvConfig.overrideEnvironment = 'development';
      expect(
        () => EnvConfig.assertNoMockInProduction('TestMock'),
        returnsNormally,
      );

      // In production-like, always throws StateError with component name
      for (final env in ['staging', 'pilot', 'production']) {
        EnvConfig.overrideEnvironment = env;
        expect(
          () => EnvConfig.assertNoMockInProduction('TestMock'),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('TestMock'),
              contains(env),
            ),
          )),
        );
      }
    });
  });

  group('EnvConfig — key naming', () {
    test(
        'supabasePublishableKey is the correct field name (not supabaseAnonKey)',
        () {
      final _ = EnvConfig.supabasePublishableKey;
      expect(true, isTrue);
    });
  });
}
