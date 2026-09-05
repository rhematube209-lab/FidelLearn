import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/core/networking/connectivity_service.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/drift_sync_queue_repository.dart';
import 'package:fidel_learn/core/sync/services/sync_engine.dart';

void main() {
  group('DriftSyncQueueRepository & SyncEngine Tests', () {
    late AppDatabase db;
    late DriftSyncQueueRepository queueRepo;
    late MockConnectivityService connectivity;
    late SyncEngine syncEngine;

    setUp(() {
      db = AppDatabase.inMemory();
      queueRepo = DriftSyncQueueRepository(db);
      connectivity = MockConnectivityService(initialOnline: true);
      syncEngine = SyncEngine(
        connectivityService: connectivity,
        queueRepository: queueRepo,
      );
    });

    tearDown(() async {
      syncEngine.dispose();
      connectivity.dispose();
      await db.close();
    });

    test('enqueues operations and deduplicates by idempotency key in SQLite',
        () async {
      final now = DateTime.now();
      final op1 = SyncOperation(
        id: 'op_drift_1',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attemptId': 'att_101', 'score': 92},
        idempotencyKey: 'idem_attempt_101',
        nextRetryAt: now,
        createdAt: now,
      );

      final opDuplicate = SyncOperation(
        id: 'op_drift_2',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attemptId': 'att_101', 'score': 92},
        idempotencyKey: 'idem_attempt_101',
        nextRetryAt: now,
        createdAt: now,
      );

      await queueRepo.enqueue(op1);
      await queueRepo.enqueue(opDuplicate); // duplicate idempotencyKey

      final count = await queueRepo.getPendingCount();
      expect(count, 1);

      final pending = await queueRepo.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.id, 'op_drift_1');
    });

    test(
        'markOperationFailure increments retry count and sets future nextRetryAt',
        () async {
      final now = DateTime.now();
      final op = SyncOperation(
        id: 'op_fail_test',
        operationType: SyncOperationType.toggleBookmark,
        payload: const {'questionId': 'q_99'},
        idempotencyKey: 'bm_q_99',
        nextRetryAt: now,
        createdAt: now,
      );

      await queueRepo.enqueue(op);

      const delay = Duration(minutes: 5);
      await queueRepo.markOperationFailure(
        'op_fail_test',
        error: 'Network timeout',
        retryDelay: delay,
      );

      // It should still be in the database, but not eligible for immediate execution
      final pendingNow = await queueRepo.getPendingOperations();
      expect(pendingNow, isEmpty);

      // When querying including future, count is 1
      final count = await queueRepo.getPendingCount();
      expect(count, 1);
    });

    test('syncEngine drains Drift SQLite queue in FIFO order upon network sync',
        () async {
      final now = DateTime.now();
      final executedOps = <String>[];

      syncEngine.registerHandler(SyncOperationType.submitAttempt, (op) async {
        executedOps.add(op.id);
        return true;
      });

      syncEngine.registerHandler(SyncOperationType.recordMistake, (op) async {
        executedOps.add(op.id);
        return true;
      });

      await queueRepo.enqueue(
        SyncOperation(
          id: 'drift_op_first',
          operationType: SyncOperationType.submitAttempt,
          payload: const {'attemptId': 'first'},
          idempotencyKey: 'first_idem',
          nextRetryAt: now.subtract(const Duration(seconds: 10)),
          createdAt: now.subtract(const Duration(seconds: 10)),
        ),
      );

      await queueRepo.enqueue(
        SyncOperation(
          id: 'drift_op_second',
          operationType: SyncOperationType.recordMistake,
          payload: const {'questionId': 'second'},
          idempotencyKey: 'second_idem',
          nextRetryAt: now.subtract(const Duration(seconds: 5)),
          createdAt: now.subtract(const Duration(seconds: 5)),
        ),
      );

      final syncedCount = await syncEngine.syncAll();
      expect(syncedCount, 2);
      expect(executedOps, ['drift_op_first', 'drift_op_second']);

      final remaining = await queueRepo.getPendingCount();
      expect(remaining, 0);
      expect(syncEngine.currentStatus, SyncStatus.synced);
    });
  });
}
