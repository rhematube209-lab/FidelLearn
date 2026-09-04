import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/networking/connectivity_service.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/sync_queue_repository.dart';
import 'package:fidel_learn/core/sync/services/sync_engine.dart';

void main() {
  group('SyncEngine & Offline Queue Tests', () {
    late LocalSyncQueueRepository queueRepo;
    late MockConnectivityService connectivity;
    late SyncEngine syncEngine;

    setUp(() {
      queueRepo = LocalSyncQueueRepository();
      connectivity = MockConnectivityService(initialOnline: true);
      syncEngine = SyncEngine(
        connectivityService: connectivity,
        queueRepository: queueRepo,
      );
    });

    tearDown(() {
      syncEngine.dispose();
      connectivity.dispose();
    });

    test('enqueues operations and deduplicates by idempotency key', () async {
      final now = DateTime.now();
      final op1 = SyncOperation(
        id: 'op_1',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attemptId': 'att_1', 'score': 85},
        idempotencyKey: 'idem_attempt_1',
        nextRetryAt: now,
        createdAt: now,
      );

      final opDuplicate = SyncOperation(
        id: 'op_2',
        operationType: SyncOperationType.submitAttempt,
        payload: const {'attemptId': 'att_1', 'score': 85},
        idempotencyKey: 'idem_attempt_1',
        nextRetryAt: now,
        createdAt: now,
      );

      await queueRepo.enqueue(op1);
      await queueRepo.enqueue(opDuplicate); // duplicate key

      final count = await queueRepo.getPendingCount();
      expect(count, 1);
    });

    test(
        'calculateBackoff produces correctly bounded exponential delays with jitter',
        () {
      final deterministicRandom = Random(42);

      // retry 0: 2 * 2^0 = 2s
      final delay0 = SyncEngine.calculateBackoff(
        retryCount: 0,
        random: deterministicRandom,
      );
      expect(delay0.inSeconds, 2);

      // retry 3: 2 * 2^3 = 16s
      final delay3 = SyncEngine.calculateBackoff(
        retryCount: 3,
        random: deterministicRandom,
      );
      expect(delay3.inSeconds, 16);

      // retry 10: capped at maxSeconds (300s)
      final delay10 = SyncEngine.calculateBackoff(
        retryCount: 10,
        maxSeconds: 300,
        random: deterministicRandom,
      );
      expect(delay10.inSeconds, 300);
    });

    test('syncAll drains operations in FIFO order when online', () async {
      final now = DateTime.now();
      final processedTypes = <SyncOperationType>[];

      syncEngine.registerHandler(SyncOperationType.submitAttempt, (op) async {
        processedTypes.add(op.operationType);
        return true;
      });

      syncEngine.registerHandler(SyncOperationType.toggleBookmark, (op) async {
        processedTypes.add(op.operationType);
        return true;
      });

      await queueRepo.enqueue(
        SyncOperation(
          id: 'op_attempt',
          operationType: SyncOperationType.submitAttempt,
          payload: const {'attemptId': 'att_1'},
          idempotencyKey: 'idem_1',
          nextRetryAt: now,
          createdAt: now.subtract(const Duration(seconds: 10)),
        ),
      );

      await queueRepo.enqueue(
        SyncOperation(
          id: 'op_bm',
          operationType: SyncOperationType.toggleBookmark,
          payload: const {'questionId': 'q_1'},
          idempotencyKey: 'idem_2',
          nextRetryAt: now,
          createdAt: now,
        ),
      );

      final syncedCount = await syncEngine.syncAll();
      expect(syncedCount, 2);
      expect(processedTypes, [
        SyncOperationType.submitAttempt,
        SyncOperationType.toggleBookmark,
      ]);

      final remaining = await queueRepo.getPendingCount();
      expect(remaining, 0);
      expect(syncEngine.currentStatus, SyncStatus.synced);
    });

    test('pauses sync when offline and updates SyncStatus to offline',
        () async {
      connectivity.setOnline(false);

      final now = DateTime.now();
      await queueRepo.enqueue(
        SyncOperation(
          id: 'op_offline',
          operationType: SyncOperationType.submitAttempt,
          payload: const {},
          idempotencyKey: 'idem_off',
          nextRetryAt: now,
          createdAt: now,
        ),
      );

      final count = await syncEngine.syncAll();
      expect(count, 0);
      expect(syncEngine.currentStatus, SyncStatus.offline);

      // Pending operation remains safely in queue
      final remaining = await queueRepo.getPendingCount();
      expect(remaining, 1);
    });

    test('schedules retry with exponential backoff when handler fails',
        () async {
      final now = DateTime.now();

      syncEngine.registerHandler(SyncOperationType.submitAttempt, (op) async {
        return false; // Simulate transient server error
      });

      await queueRepo.enqueue(
        SyncOperation(
          id: 'op_fail',
          operationType: SyncOperationType.submitAttempt,
          payload: const {},
          idempotencyKey: 'idem_fail',
          nextRetryAt: now,
          createdAt: now,
        ),
      );

      final count = await syncEngine.syncAll();
      expect(count, 0);

      final pending = await queueRepo.getPendingCount();
      expect(pending, 1);

      // The operation was marked with retryCount = 1 and future nextRetryAt
      final eligibleNow = await queueRepo.getPendingOperations();
      // Because nextRetryAt is in the future, it should not be returned immediately
      expect(eligibleNow, isEmpty);
    });
  });
}
