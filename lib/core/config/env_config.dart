/// Environment configuration for FidelLearn.
///
/// All values are injected at compile time via:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=APP_ENVIRONMENT=...
///
/// LOCAL DEVELOPMENT:
///   Missing credentials → offline/mock mode (safe fallback).
///
/// STAGING / PRODUCTION:
///   Missing credentials → [requireSupabase] throws a [StateError] at startup.
///   A staging or production build must never silently run in mock mode.
///
/// IMPORTANT: The SUPABASE_PUBLISHABLE_KEY is the client-safe public key.
/// It is NOT the service role key and is safe to embed in Flutter.
/// Server-only secrets live exclusively in Supabase Vault and CI/CD secrets —
/// never in Dart source code or committed environment files.
class EnvConfig {
  EnvConfig._();

  static const String _defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _defaultSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String _defaultAppEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Test hooks to override configuration in tests.
  static String? overrideSupabaseUrl;
  static String? overrideSupabasePublishableKey;
  static String? overrideEnvironment;

  /// Resets all test overrides to their compile-time defaults.
  static void resetTestOverrides() {
    overrideEnvironment = null;
    overrideSupabaseUrl = null;
    overrideSupabasePublishableKey = null;
  }

  /// Supabase project URL.
  /// Provide via: --dart-define=SUPABASE_URL=https://your-ref.supabase.co
  static String get supabaseUrl => overrideSupabaseUrl ?? _defaultSupabaseUrl;

  /// Supabase publishable (anon) key — safe for client-side use.
  /// Provide via: --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
  ///
  /// This is NOT the service role key. RLS enforces all authorization.
  static String get supabasePublishableKey =>
      overrideSupabasePublishableKey ?? _defaultSupabasePublishableKey;

  /// Deployment environment identifier.
  /// Provide via: --dart-define=APP_ENVIRONMENT=development|staging|production
  static String get appEnvironment =>
      overrideEnvironment ?? _defaultAppEnvironment;

  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isStaging => appEnvironment == 'staging';
  static bool get isPilot => appEnvironment == 'pilot';
  static bool get isProduction => appEnvironment == 'production';

  /// Staging, pilot, and production are all production-like environments where
  /// real backend repositories are mandatory and mock fallbacks are strictly prohibited.
  static bool get isProductionLike => isProduction || isPilot || isStaging;

  /// Returns true when both Supabase credentials are present.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Returns true when Supabase is configured; throws in staging/pilot/production
  /// if either credential is missing.
  ///
  /// This ensures that CI/CD jobs which omit secrets fail loudly at startup
  /// rather than silently deploying a mock/offline build to real users.
  ///
  /// In development, returns false and the app enters offline/mock mode.
  static bool get requireSupabase {
    if (isSupabaseConfigured) return true;
    if (isDevelopment) return false;
    throw StateError(
      '[FidelLearn] FATAL: SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY '
      'must be provided for APP_ENVIRONMENT=$appEnvironment. '
      'A $appEnvironment build must not run in offline/mock mode. '
      'Pass them via --dart-define or CI/CD secrets.',
    );
  }

  /// Startup/runtime guard: prevents mock repository or mock data activation
  /// in any production-like environment (staging, pilot, production).
  static void assertNoMockInProduction(String componentName) {
    if (isProductionLike) {
      throw StateError(
        '[FidelLearn] FATAL: Mock component "$componentName" cannot be activated '
        'in APP_ENVIRONMENT=$appEnvironment. Production truth must never be fabricated.',
      );
    }
  }
}
