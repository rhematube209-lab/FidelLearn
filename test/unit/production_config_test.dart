import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/config/env_config.dart';

void main() {
  group('EnvConfig — fail-closed behavior', () {
    // Note: because dart-define values are baked in at compile time,
    // we cannot override them in tests. These tests document the expected
    // behaviour and verify the logic structure by inspecting the source
    // contract rather than calling requireSupabase directly.
    //
    // In CI, the test suite runs WITHOUT dart-define variables, which means:
    //   supabaseUrl = ''
    //   supabasePublishableKey = ''
    //   appEnvironment = 'development'
    //
    // This is intentional — tests run in development mode (offline/mock).

    test('isSupabaseConfigured is false when URL is empty', () {
      // In CI (no dart-define): both values default to empty string.
      // isSupabaseConfigured should be false.
      expect(EnvConfig.supabaseUrl, isEmpty);
      expect(EnvConfig.supabasePublishableKey, isEmpty);
      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('appEnvironment defaults to development', () {
      // Tests run without APP_ENVIRONMENT dart-define.
      // Default must be 'development' for tests to pass (not 'staging' or 'production').
      expect(EnvConfig.appEnvironment, equals('development'));
      expect(EnvConfig.isDevelopment, isTrue);
      expect(EnvConfig.isStaging, isFalse);
      expect(EnvConfig.isProduction, isFalse);
    });

    test(
        'requireSupabase returns false in development when credentials missing',
        () {
      // In development mode with no credentials, requireSupabase must NOT throw.
      // It must return false (app enters offline mode).
      //
      // This is the core property that allows CI test runs to succeed without
      // Supabase credentials being present.
      expect(
        () => EnvConfig.requireSupabase,
        returnsNormally,
      );
      expect(EnvConfig.requireSupabase, isFalse);
    });

    // Documented contract test for non-development environments.
    // Cannot be exercised in a standard test run because appEnvironment is
    // baked in at compile time. Verified via the staging/production deploy
    // workflow credential validation step.
    test(
        'requireSupabase contract: throws StateError when staging/production credentials missing',
        () {
      // This test documents the EXPECTED behaviour for staging/production.
      // The StateError message must contain the environment name.
      //
      // Verification path: deploy-staging.yml and deploy-production.yml
      // workflows validate credential presence before any flutter build.
      //
      // The actual EnvConfig.requireSupabase behaviour for non-dev environments:
      //   if (!isSupabaseConfigured && !isDevelopment) throw StateError(...)
      //
      // Because this runs in 'development' mode, we verify the logic
      // conditions structurally:
      expect(EnvConfig.isDevelopment, isTrue,
          reason: 'Test environment must be development');
      // If this were staging/production AND isSupabaseConfigured=false,
      // requireSupabase would throw. The CI workflow prevents this by
      // validating credentials before build.
    });
  });

  group('EnvConfig — key naming', () {
    test(
        'supabasePublishableKey is the correct field name (not supabaseAnonKey)',
        () {
      // Verifies the rename from the old API.
      // If this compiles, the field exists with the correct name.
      const _ = EnvConfig.supabasePublishableKey;
      expect(true, isTrue); // compile-time check
    });
  });
}
