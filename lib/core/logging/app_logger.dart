import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

enum LogLevel { info, warning, error }

/// Structured logging service with PII/secret redaction and correlation IDs.
class AppLogger {
  AppLogger._();

  static void Function(Map<String, dynamic> logEntry)? onLogSink;

  static final RegExp _sensitiveKeys = RegExp(
    r'(password|token|secret|authorization|key|pan|cvv|refresh|cookie)',
    caseSensitive: false,
  );

  /// Generates a standardized correlation ID for an operation.
  static String generateCorrelationId([String prefix = 'op']) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 100000).toString().padLeft(5, '0');
    return '$prefix-$timestamp-$randomSuffix';
  }

  /// Logs a structured operational event.
  static void log({
    required LogLevel level,
    required String service,
    required String operation,
    String? correlationId,
    String? schoolId,
    String? userRole,
    String? errorCode,
    int? durationMs,
    bool success = true,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'environment': EnvConfig.appEnvironment,
      'level': level.name.toUpperCase(),
      'service': service,
      'operation': operation,
      'success': success,
      if (correlationId != null) 'correlation_id': correlationId,
      if (schoolId != null) 'school_id': schoolId,
      if (userRole != null) 'user_role': userRole,
      if (errorCode != null) 'error_code': errorCode,
      if (durationMs != null) 'duration_ms': durationMs,
      if (message != null) 'message': message,
      if (metadata != null) 'metadata': redactMetadata(metadata),
    };

    if (onLogSink != null) {
      onLogSink!(entry);
    } else {
      final jsonStr = jsonEncode(entry);
      if (level == LogLevel.error) {
        debugPrint('[ERROR] $jsonStr');
      } else if (level == LogLevel.warning) {
        debugPrint('[WARN] $jsonStr');
      } else {
        if (!kReleaseMode) {
          debugPrint('[INFO] $jsonStr');
        }
      }
    }
  }

  static void info({
    required String service,
    required String operation,
    String? correlationId,
    String? schoolId,
    String? message,
    Map<String, dynamic>? metadata,
  }) =>
      log(
        level: LogLevel.info,
        service: service,
        operation: operation,
        correlationId: correlationId,
        schoolId: schoolId,
        message: message,
        metadata: metadata,
        success: true,
      );

  static void warning({
    required String service,
    required String operation,
    String? correlationId,
    String? schoolId,
    String? errorCode,
    String? message,
    Map<String, dynamic>? metadata,
  }) =>
      log(
        level: LogLevel.warning,
        service: service,
        operation: operation,
        correlationId: correlationId,
        schoolId: schoolId,
        errorCode: errorCode,
        message: message,
        metadata: metadata,
        success: false,
      );

  static void error({
    required String service,
    required String operation,
    String? correlationId,
    String? schoolId,
    String? errorCode,
    String? message,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) =>
      log(
        level: LogLevel.error,
        service: service,
        operation: operation,
        correlationId: correlationId,
        schoolId: schoolId,
        errorCode: errorCode,
        durationMs: durationMs,
        message: message,
        metadata: metadata,
        success: false,
      );

  /// Recursively redacts sensitive keys from metadata.
  static Map<String, dynamic> redactMetadata(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      if (_sensitiveKeys.hasMatch(entry.key)) {
        result[entry.key] = '[REDACTED]';
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] = redactMetadata(entry.value as Map<String, dynamic>);
      } else if (entry.value is String &&
          (entry.value as String).length > 500) {
        // Truncate overly long text payloads (e.g. raw CSVs)
        result[entry.key] =
            '${(entry.value as String).substring(0, 100)}... [TRUNCATED]';
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
