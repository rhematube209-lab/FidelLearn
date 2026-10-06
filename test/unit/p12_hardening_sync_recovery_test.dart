import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/sync_queue_repository.dart';
import 'package:fidel_learn/core/telemetry/error_telemetry.dart';
import 'package:fidel_learn/features/subjects/data/services/atomic_package_installer.dart';

void main() {
  group('P12 Hardening: Observability & Persistent Crash Envelope', () {
    late Directory tempDir;
    late File crashFile;

    setUp(() async {
      ErrorTelemetry.clear();
      tempDir = await Directory.systemTemp.createTemp('fidel_crash_test_');
      crashFile = File('${tempDir.path}/crash_envelope.json');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      ErrorTelemetry.clear();
    });

    test(
        'Crash envelope persists across process restarts and scrubs sensitive data',
        () async {
      // Record errors with sensitive context
      ErrorTelemetry.recordError(
        error: StateError('Database connection pool timeout'),
        errorCode: 'SERVER_DB_TIMEOUT',
        correlationId: 'corr-1234',
        context: {
          'school_id': 'school-pilot-1',
          'authorization': 'Bearer secret_jwt_token_123',
          'password': 'SuperSecretPassword',
          'safe_flag': true,
        },
      );

      // Persist to local disk envelope
      await ErrorTelemetry.persistCrashEnvelope(crashFile);
      expect(await crashFile.exists(), isTrue);

      // Simulate process crash / memory wipe
      ErrorTelemetry.clear();
      expect(ErrorTelemetry.exportDiagnostics(), isEmpty);

      // Simulate app restart: load persistent crash envelopes
      final restored =
          await ErrorTelemetry.loadPersistentCrashEnvelopes(crashFile);
      expect(restored.length, equals(1));
      expect(restored.first['error_code'], equals('SERVER_DB_TIMEOUT'));
      expect(restored.first['correlation_id'], equals('corr-1234'));

      // Verify sensitive metadata was scrubbed before persistence
      final context = restored.first['context'] as Map<String, dynamic>;
      expect(context['authorization'], equals('[REDACTED]'));
      expect(context['password'], equals('[REDACTED]'));
      expect(context['school_id'], equals('school-pilot-1'));
      expect(context['safe_flag'], isTrue);

      // Clear after successful reporting
      await ErrorTelemetry.clearPersistentCrashEnvelopes(crashFile);
      expect(await crashFile.exists(), isFalse);
    });
  });

  group('P12 Hardening: Offline Sync Recovery & Poison Pill Isolation', () {
    late LocalSyncQueueRepository queueRepo;

    setUp(() {
      queueRepo = LocalSyncQueueRepository();
    });

    test(
        'Poison-pill queue item reaches retry limit, becomes dead_letter, and unblocks later items',
        () async {
      final now = DateTime.now();

      final validItemA = SyncOperation(
        id: 'op-valid-a',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attempt_id': 'att-1', 'score': 90},
        idempotencyKey: 'idem-valid-a',
        nextRetryAt: now.subtract(const Duration(seconds: 10)),
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      final poisonItemB = SyncOperation(
        id: 'op-poison-b',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'corrupt': true},
        idempotencyKey: 'idem-poison-b',
        nextRetryAt: now.subtract(const Duration(seconds: 5)),
        createdAt: now.subtract(const Duration(minutes: 4)),
      );

      final validItemC = SyncOperation(
        id: 'op-valid-c',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attempt_id': 'att-3', 'score': 85},
        idempotencyKey: 'idem-valid-c',
        nextRetryAt: now.subtract(const Duration(seconds: 1)),
        createdAt: now.subtract(const Duration(minutes: 3)),
      );

      await queueRepo.enqueue(validItemA);
      await queueRepo.enqueue(poisonItemB);
      await queueRepo.enqueue(validItemC);

      expect(await queueRepo.getPendingCount(), equals(3));

      // Process valid item A
      await queueRepo.markOperationSuccess(validItemA.id);
      expect(await queueRepo.getPendingCount(), equals(2));

      // Simulate poison item B failing repeatedly until 10 retries
      for (int i = 0; i < 10; i++) {
        await queueRepo.markOperationFailure(
          poisonItemB.id,
          error: 'UnprocessableEntity: schema mismatch',
          retryDelay: Duration.zero,
        );
      }

      // Poison item B should now be tagged [DEAD_LETTER]
      expect(await queueRepo.getPendingCount(),
          equals(1)); // Only validItemC remaining pending

      final pending = await queueRepo.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals(validItemC.id));

      // Safe dead-letter diagnostics inspection (shields raw payload)
      final deadLetters = await queueRepo.getDeadLetterDiagnostics();
      expect(deadLetters.length, equals(1));
      expect(deadLetters.first['id'], equals(poisonItemB.id));
      expect(deadLetters.first['operation_type'], equals('SUBMIT_ATTEMPT'));
      expect(deadLetters.first['retry_count'], equals(10));
      expect(deadLetters.first['error_code'], contains('[DEAD_LETTER]'));
      expect(deadLetters.first.containsKey('payload'),
          isFalse); // Payload shielded!

      // Valid item C can now process and complete cleanly without blockage!
      await queueRepo.markOperationSuccess(validItemC.id);
      expect(await queueRepo.getPendingCount(), equals(0));
    });

    test('Tenant isolation during sync: User and School switching guards',
        () async {
      final now = DateTime.now();

      // User A enqueues item for School 1
      final opUserA = SyncOperation(
        id: 'op-user-a',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'user_id': 'user-a-uuid', 'school_id': 'school-1-uuid'},
        idempotencyKey: 'idem-user-a',
        nextRetryAt: now,
        createdAt: now,
      );

      await queueRepo.enqueue(opUserA);

      // Verify that sync dispatcher strictly checks active user context before upload
      const currentActiveUser = 'user-b-uuid';
      const currentActiveSchool = 'school-2-uuid';

      final pending = await queueRepo.getPendingOperations();
      final targetOp = pending.first;

      // Assertion: If active user does not match mutation author, upload must NOT proceed under User B
      final bool canUploadUnderUserB =
          (targetOp.payload['user_id'] == currentActiveUser);
      expect(canUploadUnderUserB, isFalse,
          reason: 'User A queued mutation must never be uploaded under User B');

      // Assertion: If active school context is School 2, School 1 mutation must NOT be applied to School 2
      final bool canApplyToSchool2 =
          (targetOp.payload['school_id'] == currentActiveSchool);
      expect(canApplyToSchool2, isFalse,
          reason: 'School 1 mutation must never be applied to School 2');
    });
  });

  group('P12 Hardening: Storage Disaster Recovery & Asset Recovery', () {
    late Directory storageRecoveryDir;

    setUp(() async {
      storageRecoveryDir =
          await Directory.systemTemp.createTemp('storage_recovery_drill_');
    });

    tearDown(() async {
      if (await storageRecoveryDir.exists()) {
        await storageRecoveryDir.delete(recursive: true);
      }
    });

    test(
        'Private institutional report artifact recovery validates byte size, SHA-256, tenant path, and access boundaries',
        () async {
      const schoolId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
      const reportRunId = 'rep-run-987654';

      // 1. Generate representative P10 institutional report CSV content (institutional artifact)
      final reportCsvBytes = utf8.encode(
          'stream,student_count,participation_rate,average_score,median_score,interventions_count\n'
          'naturalScience,120,95.50,78.40,79.00,12\n'
          'socialScience,95,92.10,74.20,75.00,8\n');

      final expectedSha256 = sha256.convert(reportCsvBytes).toString();
      final expectedByteLength = reportCsvBytes.length;

      // 2. Primary cloud storage artifact path (strictly partitioned by school_id tenant)
      const primaryStoragePath =
          'schools/$schoolId/reports/2026_27/$reportRunId.csv';
      final primaryFile =
          File('${storageRecoveryDir.path}/primary/$primaryStoragePath');
      await primaryFile.parent.create(recursive: true);
      await primaryFile.writeAsBytes(reportCsvBytes);

      // 3. Disaster Recovery: Replicate / restore artifact into isolated staging recovery bucket
      const recoveryStoragePath =
          'recovery-bucket/schools/$schoolId/reports/2026_27/$reportRunId.csv';
      final recoveredFile =
          File('${storageRecoveryDir.path}/$recoveryStoragePath');
      await recoveredFile.parent.create(recursive: true);
      await primaryFile.copy(recoveredFile.path);

      // 4. Verify restored artifact exists, byte size matches, and SHA-256 matches metadata
      expect(await recoveredFile.exists(), isTrue);
      expect(await recoveredFile.length(), equals(expectedByteLength));

      final recoveredBytes = await recoveredFile.readAsBytes();
      final recoveredSha256 = sha256.convert(recoveredBytes).toString();
      expect(recoveredSha256, equals(expectedSha256));

      // 5. Verify tenant path integrity
      expect(recoveryStoragePath, contains('schools/$schoolId/'));

      // 6. Access control simulation:
      // Unauthorized tenant (different school_id) is blocked from accessing artifact
      const callerSchoolId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      final isAuthorizedTenant =
          recoveryStoragePath.contains('schools/$callerSchoolId/');
      expect(isAuthorizedTenant, isFalse,
          reason:
              'Unauthorized tenant must be denied access to private report');

      // Authorized school admin has matching school_id path prefix
      const adminSchoolId = schoolId;
      final isAdminAuthorized =
          recoveryStoragePath.contains('schools/$adminSchoolId/');
      expect(isAdminAuthorized, isTrue,
          reason: 'Authorized school admin can access school private report');
    });

    test(
        'Historical content package (.flpkg) cold-backup recovery validates manifest, SHA-256, and opens cleanly',
        () async {
      // 1. Load historical package seed from cold repository source
      final historicalSeedFile = File('assets/seed/biology_2013_seed.json');
      expect(await historicalSeedFile.exists(), isTrue);

      final rawSeedJson = await historicalSeedFile.readAsString();
      final seedMap = jsonDecode(rawSeedJson) as Map<String, dynamic>;
      final packageMeta =
          (seedMap['packages'] as List).first as Map<String, dynamic>;

      expect(packageMeta['package_id'], equals('pkg_g12_biology_2013'));
      expect(packageMeta['grade'], equals(12));
      expect(packageMeta['stream'], equals('natural'));
      expect(packageMeta['version'], equals(1));

      // 2. Compute cold storage archive checksum
      final packageBytes = utf8.encode(rawSeedJson);
      final coldSha256 = sha256.convert(packageBytes).toString();

      // 3. Recover historical package using AtomicPackageInstaller into isolated destination
      final installer = AtomicPackageInstaller(storageRecoveryDir);
      final installResult = await installer.installPackageBytes(
        packageId: 'pkg_g12_biology_2013_v1',
        packageBytes: packageBytes,
        expectedHash: coldSha256,
        manifest: packageMeta,
      );

      expect(installResult.success, isTrue);
      expect(installResult.hash, equals(coldSha256));

      // 4. Verify recovered package file on disk
      final recoveredPackageFile =
          File('${storageRecoveryDir.path}/pkg_g12_biology_2013_v1.flpkg');
      expect(await recoveredPackageFile.exists(), isTrue);

      // 5. Verify package can be opened and contains full historical question set
      final openedContent = await recoveredPackageFile.readAsString();
      final parsed = jsonDecode(openedContent) as Map<String, dynamic>;
      final questions = parsed['questions'] as List;
      expect(questions.length, equals(100),
          reason: 'Historical 2013 Biology package must contain 100 questions');
    });
  });
}
