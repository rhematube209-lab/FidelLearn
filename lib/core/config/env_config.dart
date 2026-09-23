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

  /// Supabase project URL.
  /// Provide via: --dart-define=SUPABASE_URL=https://your-ref.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase publishable (anon) key — safe for client-side use.
  /// Provide via: --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
  ///
  /// This is NOT the service role key. RLS enforces all authorization.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Deployment environment identifier.
  /// Provide via: --dart-define=APP_ENVIRONMENT=development|staging|production
  static const String appEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isStaging => appEnvironment == 'staging';
  static bool get isProduction => appEnvironment == 'production';

  /// Returns true when both Supabase credentials are present.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Returns true when Supabase is configured; throws in staging/production
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
}
