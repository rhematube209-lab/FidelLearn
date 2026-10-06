import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/config/release_info.dart';
import 'package:fidel_learn/core/logging/app_logger.dart';
import 'package:fidel_learn/core/telemetry/error_telemetry.dart';
import 'package:fidel_learn/core/errors/error_taxonomy.dart';
import 'package:fidel_learn/core/health/health_service.dart';
import 'package:fidel_learn/core/compatibility/compatibility_service.dart';
import 'package:fidel_learn/core/networking/connectivity_service.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/sync_queue_repository.dart';
import 'package:fidel_learn/features/subjects/data/services/atomic_package_installer.dart';

void main() {
  group('P12 ReleaseInfo Tests', () {
    test('ReleaseInfo exposes frozen schema v9 and valid diagnostics', () {
      expect(ReleaseInfo.driftSchemaVersion, 9);
      expect(ReleaseInfo.appVersion, '1.0.0');
      expect(ReleaseInfo.buildNumber, 1);
      final diag = ReleaseInfo.toDiagnosticMap();
      expect(diag['drift_schema_version'], 9);
      expect(diag['app_version'], '1.0.0');
      expect(ReleaseInfo.toFormattedString(), contains('v1.0.0+1'));
      expect(ReleaseInfo.toFormattedString(), contains('schema: v9'));
    });
  });

  group('P12 AppLogger & Secret Redaction Tests', () {
    test('AppLogger redacts sensitive fields from metadata', () {
      final input = {
        'username': 'student_1',
        'password': 'super_secret_password',
        'auth_token': 'eyJh...token',
        'refresh_token': 'refresh_123',
        'credit_card_pan': '4111222233334444',
        'nested': {
          'api_key': 'secret_key_abc',
          'normal_field': 'hello',
        },
      };

      final redacted = AppLogger.redactMetadata(input);
      expect(redacted['username'], 'student_1');
      expect(redacted['password'], '[REDACTED]');
      expect(redacted['auth_token'], '[REDACTED]');
      expect(redacted['refresh_token'], '[REDACTED]');
      expect(redacted['credit_card_pan'], '[REDACTED]');
      expect((redacted['nested'] as Map)['api_key'], '[REDACTED]');
      expect((redacted['nested'] as Map)['normal_field'], 'hello');
    });

    test('AppLogger generates valid correlation IDs', () {
      final id1 = AppLogger.generateCorrelationId('sync');
      final id2 = AppLogger.generateCorrelationId('sync');
      expect(id1.startsWith('sync-'), isTrue);
      expect(id2.startsWith('sync-'), isTrue);
    });

    test('AppLogger logs through pluggable sink', () {
      Map<String, dynamic>? recorded;
      AppLogger.onLogSink = (entry) => recorded = entry;

      AppLogger.info(
        service: 'TestService',
        operation: 'testOp',
        correlationId: 'corr-123',
        message: 'Test message',
      );

      expect(recorded, isNotNull);
      expect(recorded!['service'], 'TestService');
      expect(recorded!['operation'], 'testOp');
      expect(recorded!['correlation_id'], 'corr-123');
      expect(recorded!['success'], isTrue);

      AppLogger.onLogSink = null;
    });
  });

  group('P12 ErrorTelemetry Tests', () {
    setUp(() {
      ErrorTelemetry.clear();
    });

    test('ErrorTelemetry records and exports diagnostic buffer', () {
      ErrorTelemetry.recordError(
        error: Exception('Test exception'),
        errorCode: 'ERR_TEST',
        correlationId: 'corr-telemetry',
        context: {'user_id': 'u1', 'token': 'sensitive'},
      );

      final exported = ErrorTelemetry.exportDiagnostics();
      expect(exported.length, 1);
      final first = exported.first;
      expect(first['error_code'], 'ERR_TEST');
      expect(first['correlation_id'], 'corr-telemetry');
      expect(first['context']['token'], '[REDACTED]');
      expect(first['context']['user_id'], 'u1');
      expect(first['release']['drift_schema_version'], 9);
    });
  });

  group('P12 ErrorTaxonomy Tests', () {
    test('Maps network exceptions into retryable NETWORK_UNAVAILABLE', () {
      final desc = AppErrorDescriptor.fromException(
          'SocketException: OS Error: Connection refused');
      expect(desc.category, ErrorCategory.network);
      expect(desc.code, 'NETWORK_UNAVAILABLE');
      expect(desc.isRetryable, isTrue);
      expect(desc.userMessageEn, contains('saved locally'));
      expect(desc.userMessageAm, contains('በስልክዎ ተቀምጧል'));
    });

    test('Maps SEAT_LIMIT_EXCEEDED into non-retryable descriptor', () {
      final desc = AppErrorDescriptor.fromException(
          'PostgrestException: SEAT_LIMIT_EXCEEDED');
      expect(desc.category, ErrorCategory.seatLimit);
      expect(desc.code, 'SEAT_LIMIT_EXCEEDED');
      expect(desc.isRetryable, isFalse);
      expect(desc.userMessageEn, contains('capacity'));
    });

    test('Maps permission denied (42501) into non-retryable descriptor', () {
      final desc = AppErrorDescriptor.fromException(
          'Error 42501: Access denied: caller is not member');
      expect(desc.category, ErrorCategory.authorization);
      expect(desc.code, 'PERMISSION_DENIED');
      expect(desc.isRetryable, isFalse);
    });
  });

  group('P12 HealthService Tests', () {
    test('Reports operational when database and network are ready', () async {
      final conn = MockConnectivityService(initialOnline: true);
      final health = HealthService(
        connectivityService: conn,
        dbCheck: () async => true,
        remoteCheck: () async => true,
      );

      final report = await health.checkHealth();
      expect(report.status, SystemOperationalStatus.operational);
      expect(report.isAlive, isTrue);
      expect(report.isReady, isTrue);
      expect(report.isDatabaseReady, isTrue);
      expect(report.isBackendReachable, isTrue);
    });

    test(
        'Reports degraded when offline but local DB is ready (offline learning preserved)',
        () async {
      final conn = MockConnectivityService(initialOnline: false);
      final health = HealthService(
        connectivityService: conn,
        dbCheck: () async => true,
        remoteCheck: () async => false,
      );

      final report = await health.checkHealth();
      expect(report.status, SystemOperationalStatus.degraded);
      expect(report.isAlive, isTrue);
      expect(report.isReady, isTrue);
      expect(report.isDatabaseReady, isTrue);
      expect(report.isBackendReachable, isFalse);
    });

    test('Reports unavailable when local DB fails', () async {
      final conn = MockConnectivityService(initialOnline: true);
      final health = HealthService(
        connectivityService: conn,
        dbCheck: () async => false,
      );

      final report = await health.checkHealth();
      expect(report.status, SystemOperationalStatus.unavailable);
      expect(report.isReady, isFalse);
      expect(report.isDatabaseReady, isFalse);
    });
  });

  group('P12 CompatibilityService Tests', () {
    test('compareSemver handles standard and tagged versions', () {
      expect(CompatibilityService.compareSemver('1.0.0', '1.0.0'), 0);
      expect(CompatibilityService.compareSemver('1.1.0', '1.0.0'), 1);
      expect(CompatibilityService.compareSemver('0.9.0', '1.0.0'), -1);
      expect(CompatibilityService.compareSemver('1.0.0+1', '1.0.0'), 0);
      expect(CompatibilityService.compareSemver('1.0.1', '1.0.0'), 1);
    });

    test('evaluate returns required update when below minimum', () {
      final res = CompatibilityService.evaluate(
        currentVersion: '0.8.0',
        minimumSupportedVersion: '1.0.0',
        recommendedVersion: '1.2.0',
        latestVersion: '1.2.0',
      );
      expect(res.action, UpdateAction.required);
      expect(res.isBlocked, isTrue);
    });

    test(
        'evaluate returns recommended update when above min but below recommended',
        () {
      final res = CompatibilityService.evaluate(
        currentVersion: '1.0.0',
        minimumSupportedVersion: '1.0.0',
        recommendedVersion: '1.2.0',
        latestVersion: '1.2.0',
      );
      expect(res.action, UpdateAction.recommended);
      expect(res.isBlocked, isFalse);
    });

    test('evaluate returns none when up to date', () {
      final res = CompatibilityService.evaluate(
        currentVersion: '1.2.0',
        minimumSupportedVersion: '1.0.0',
        recommendedVersion: '1.2.0',
        latestVersion: '1.2.0',
      );
      expect(res.action, UpdateAction.none);
      expect(res.isBlocked, isFalse);
    });

    test('offlineFallback returns unblocked status for student continuity', () {
      final res = CompatibilityResult.offlineFallback('1.0.0');
      expect(res.action, UpdateAction.none);
      expect(res.isBlocked, isFalse);
      expect(res.isOfflineFallback, isTrue);
    });
  });

  group('P12 AtomicPackageInstaller Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('flpkg_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Installs package atomically when SHA-256 matches', () async {
      final installer = AtomicPackageInstaller(tempDir);
      final bytes = utf8.encode('valid_package_payload_biology_2013');
      final expectedHash = AtomicPackageInstaller.computeSha256(bytes);

      final result = await installer.installPackageBytes(
        packageId: 'biology_2013',
        packageBytes: bytes,
        expectedHash: expectedHash,
      );

      expect(result.success, isTrue);
      expect(result.packageId, 'biology_2013');
      expect(result.hash, expectedHash);
      final activeFile = File('${tempDir.path}/biology_2013.flpkg');
      expect(await activeFile.exists(), isTrue);
      expect(await activeFile.readAsString(),
          'valid_package_payload_biology_2013');
    });

    test('Rejects corrupt package and rolls back without touching active file',
        () async {
      final installer = AtomicPackageInstaller(tempDir);
      final initialBytes = utf8.encode('initial_good_version');
      final initialHash = AtomicPackageInstaller.computeSha256(initialBytes);

      // Install initial version
      await installer.installPackageBytes(
        packageId: 'physics_2014',
        packageBytes: initialBytes,
        expectedHash: initialHash,
      );

      // Attempt corrupt upgrade with mismatched hash
      final corruptBytes = utf8.encode('corrupt_tampered_payload');
      final result = await installer.installPackageBytes(
        packageId: 'physics_2014',
        packageBytes: corruptBytes,
        expectedHash: 'wrong_expected_hash_000000',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Hash mismatch'));

      // Active file must still contain the initial valid version!
      final activeFile = File('${tempDir.path}/physics_2014.flpkg');
      expect(await activeFile.exists(), isTrue);
      expect(await activeFile.readAsString(), 'initial_good_version');

      // Temp file must be cleaned up
      final tempFile = File('${tempDir.path}/physics_2014.flpkg.tmp');
      expect(await tempFile.exists(), isFalse);
    });
  });

  group('P12 Sync Dead-Letter Queue Tests', () {
    test(
        'LocalSyncQueueRepository isolates dead-letter operations so queue is not blocked',
        () async {
      final queue = LocalSyncQueueRepository();

      final op1 = SyncOperation(
        id: 'op-1',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'id': 'attempt-1'},
        idempotencyKey: 'idem-1',
        nextRetryAt: DateTime.now().subtract(const Duration(seconds: 5)),
        createdAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );

      final op2 = SyncOperation(
        id: 'op-2',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'id': 'attempt-2'},
        idempotencyKey: 'idem-2',
        nextRetryAt: DateTime.now().subtract(const Duration(seconds: 5)),
        createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );

      await queue.enqueue(op1);
      await queue.enqueue(op2);

      expect(await queue.getPendingCount(), 2);

      // Simulate op1 failing repeatedly until dead-lettered
      await queue.markOperationDeadLetter(op1.id,
          reason: 'Invalid non-retryable attempt');

      // op1 must no longer be considered pending or eligible for immediate retry
      expect(await queue.getPendingCount(), 1);

      final pending = await queue.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.id, op2.id); // op2 is unblocked and processed!
    });
  });
}
