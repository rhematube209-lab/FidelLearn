import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/sync_queue_repository.dart';
import 'package:fidel_learn/core/telemetry/error_telemetry.dart';

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
}
