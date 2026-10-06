import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import '../config/release_info.dart';
import '../logging/app_logger.dart';

class TelemetryEvent {
  final String id;
  final DateTime timestamp;
  final String errorType;
  final String errorCode;
  final String message;
  final String? stackTrace;
  final String? correlationId;
  final Map<String, dynamic> context;

  TelemetryEvent({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.errorCode,
    required this.message,
    this.stackTrace,
    this.correlationId,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'error_type': errorType,
      'error_code': errorCode,
      'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (correlationId != null) 'correlation_id': correlationId,
      'context': context,
      'release': ReleaseInfo.toDiagnosticMap(),
    };
  }
}

/// Production-safe error & crash telemetry abstraction.
class ErrorTelemetry {
  ErrorTelemetry._();

  static const int maxBufferSize = 50;
  static final Queue<TelemetryEvent> _eventBuffer = Queue<TelemetryEvent>();

  static void Function(TelemetryEvent event)? onTelemetryRecorded;

  /// Records an operational or runtime error event.
  static void recordError({
    required dynamic error,
    StackTrace? stackTrace,
    String errorCode = 'UNKNOWN_ERROR',
    String? correlationId,
    Map<String, dynamic>? context,
  }) {
    final sanitizedContext = context != null
        ? AppLogger.redactMetadata(context)
        : <String, dynamic>{};
    final event = TelemetryEvent(
      id: AppLogger.generateCorrelationId('err'),
      timestamp: DateTime.now(),
      errorType: error.runtimeType.toString(),
      errorCode: errorCode,
      message: error.toString(),
      stackTrace: stackTrace != null
          ? _sanitizeStackTrace(stackTrace.toString())
          : null,
      correlationId: correlationId,
      context: sanitizedContext,
    );

    if (_eventBuffer.length >= maxBufferSize) {
      _eventBuffer.removeFirst();
    }
    _eventBuffer.addLast(event);

    if (onTelemetryRecorded != null) {
      onTelemetryRecorded!(event);
    }
  }

  /// Exports recorded diagnostic telemetry for support troubleshooting.
  static List<Map<String, dynamic>> exportDiagnostics() {
    return _eventBuffer.map((e) => e.toJson()).toList();
  }

  /// Clears the in-memory telemetry buffer.
  static void clear() {
    _eventBuffer.clear();
  }

  /// Persists current telemetry events to a local crash envelope file.
  static Future<void> persistCrashEnvelope(File envelopeFile) async {
    final events = exportDiagnostics();
    await envelopeFile.writeAsString(jsonEncode(events));
  }

  /// Loads crash envelopes from a local file across app restarts.
  static Future<List<Map<String, dynamic>>> loadPersistentCrashEnvelopes(
      File envelopeFile) async {
    if (!await envelopeFile.exists()) return [];
    try {
      final content = await envelopeFile.readAsString();
      if (content.isEmpty) return [];
      final decoded = jsonDecode(content) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clears persistent crash envelope file once reported.
  static Future<void> clearPersistentCrashEnvelopes(File envelopeFile) async {
    if (await envelopeFile.exists()) {
      await envelopeFile.delete();
    }
  }

  static String _sanitizeStackTrace(String trace) {
    // Keep top 10 stack frames only, without user file paths if possible
    final lines = trace.split('\n');
    return lines.take(10).join('\n');
  }
}
