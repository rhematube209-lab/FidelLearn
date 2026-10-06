import '../models/sync_models.dart';

abstract class SyncQueueRepository {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> getPendingOperations({int limit = 20});
  Future<void> markOperationSuccess(String operationId);
  Future<void> markOperationFailure(
    String operationId, {
    required String error,
    required Duration retryDelay,
  });
  Future<void> markOperationDeadLetter(
    String operationId, {
    required String reason,
  });
  Future<int> getPendingCount();
  Future<List<Map<String, dynamic>>> getDeadLetterDiagnostics();
  Future<void> clearAll();
}

class LocalSyncQueueRepository implements SyncQueueRepository {
  final List<SyncOperation> _queue = [];

  @override
  Future<void> enqueue(SyncOperation operation) async {
    // Avoid enqueuing duplicates by idempotency key
    final existingIndex = _queue.indexWhere(
      (op) => op.idempotencyKey == operation.idempotencyKey,
    );
    if (existingIndex != -1) {
      return; // Already in queue
    }
    _queue.add(operation);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({int limit = 20}) async {
    final now = DateTime.now();
    final eligible = _queue
        .where((op) =>
            (op.nextRetryAt.isBefore(now) ||
                op.nextRetryAt.isAtSameMomentAs(now)) &&
            !(op.lastError?.startsWith('[DEAD_LETTER]') ?? false))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // FIFO

    if (eligible.length > limit) {
      return eligible.sublist(0, limit);
    }
    return eligible;
  }

  @override
  Future<void> markOperationSuccess(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
  }

  @override
  Future<void> markOperationFailure(
    String operationId, {
    required String error,
    required Duration retryDelay,
  }) async {
    final index = _queue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      final current = _queue[index];
      final newCount = current.retryCount + 1;
      if (newCount >= 10) {
        // Automatically dead-letter after 10 consecutive failed attempts
        _queue[index] = current.copyWith(
          retryCount: newCount,
          nextRetryAt: DateTime.now().add(const Duration(days: 3650)),
          lastError: '[DEAD_LETTER] Max retries exceeded ($newCount): $error',
        );
        return;
      }
      _queue[index] = current.copyWith(
        retryCount: newCount,
        nextRetryAt: DateTime.now().add(retryDelay),
        lastError: error,
      );
    }
  }

  @override
  Future<void> markOperationDeadLetter(
    String operationId, {
    required String reason,
  }) async {
    final index = _queue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      final current = _queue[index];
      _queue[index] = current.copyWith(
        nextRetryAt: DateTime.now().add(const Duration(days: 3650)),
        lastError: '[DEAD_LETTER] $reason',
      );
    }
  }

  @override
  Future<int> getPendingCount() async {
    return _queue
        .where((op) => !(op.lastError?.startsWith('[DEAD_LETTER]') ?? false))
        .length;
  }

  @override
  Future<List<Map<String, dynamic>>> getDeadLetterDiagnostics() async {
    return _queue
        .where((op) => op.lastError?.startsWith('[DEAD_LETTER]') ?? false)
        .map((op) => {
              'id': op.id,
              'operation_type': op.operationType.value,
              'retry_count': op.retryCount,
              'error_code': op.lastError,
              'created_at': op.createdAt.toUtc().toIso8601String(),
            })
        .toList();
  }

  @override
  Future<void> clearAll() async {
    _queue.clear();
  }
}
