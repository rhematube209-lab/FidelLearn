import 'env_config.dart';

/// Release and build metadata for runtime diagnostic inspection.
class ReleaseInfo {
  ReleaseInfo._();

  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const int driftSchemaVersion = 9;

  /// Current commit hash or release tag injected at build time.
  static const String commitSha = String.fromEnvironment(
    'BUILD_COMMIT_SHA',
    defaultValue: 'production-launch-p12',
  );

  /// Target backend migration baseline compatible with this client.
  static const String migrationBaseline =
      '20260925060000_p12_production_readiness';

  /// Release date string
  static const String releaseDate = '2026-10-06';

  static Map<String, dynamic> toDiagnosticMap() {
    return {
      'app_version': appVersion,
      'build_number': buildNumber,
      'environment': EnvConfig.appEnvironment,
      'drift_schema_version': driftSchemaVersion,
      'commit_sha': commitSha,
      'migration_baseline': migrationBaseline,
      'release_date': releaseDate,
    };
  }

  static String toFormattedString() {
    return 'FidelLearn v$appVersion+$buildNumber (${EnvConfig.appEnvironment}) [schema: v$driftSchemaVersion]';
  }
}
