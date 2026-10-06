import 'dart:convert';
import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../models/sync_models.dart';
import 'sync_queue_repository.dart';

class DriftSyncQueueRepository implements SyncQueueRepository {
  final AppDatabase _db;

  DriftSyncQueueRepository(this._db);

  @override
  Future<void> enqueue(SyncOperation operation) async {
    final existing = await (_db.select(_db.dbSyncQueue)
          ..where((tbl) => tbl.idempotencyKey.equals(operation.idempotencyKey)))
        .getSingleOrNull();

    if (existing != null) return;

    await _db.into(_db.dbSyncQueue).insert(
          DbSyncQueueCompanion.insert(
            id: operation.id,
            operationType: operation.operationType.value,
            payloadJson: jsonEncode(operation.payload),
            idempotencyKey: operation.idempotencyKey,
            retryCount: Value(operation.retryCount),
            nextRetryAt: operation.nextRetryAt,
            lastError: Value(operation.lastError),
            createdAt: operation.createdAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({int limit = 20}) async {
    final now = DateTime.now();
    final query = _db.select(_db.dbSyncQueue)
      ..where((tbl) =>
          tbl.nextRetryAt.isSmallerOrEqualValue(now) &
          (tbl.lastError.isNull() | tbl.lastError.like('[DEAD_LETTER]%').not()))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      return SyncOperation(
        id: row.id,
        operationType: SyncOperationType.fromString(row.operationType),
        payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
        idempotencyKey: row.idempotencyKey,
        retryCount: row.retryCount,
        nextRetryAt: row.nextRetryAt,
        lastError: row.lastError,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  @override
  Future<void> markOperationSuccess(String operationId) async {
    await (_db.delete(_db.dbSyncQueue)
          ..where((tbl) => tbl.id.equals(operationId)))
        .go();
  }

  @override
  Future<void> markOperationFailure(
    String operationId, {
    required String error,
    required Duration retryDelay,
  }) async {
    final current = await (_db.select(_db.dbSyncQueue)
          ..where((tbl) => tbl.id.equals(operationId)))
        .getSingleOrNull();

    if (current != null) {
      final newRetryCount = current.retryCount + 1;
      if (newRetryCount >= 10) {
        await (_db.update(_db.dbSyncQueue)
              ..where((tbl) => tbl.id.equals(operationId)))
            .write(
          DbSyncQueueCompanion(
            retryCount: Value(newRetryCount),
            nextRetryAt: Value(DateTime.now().add(const Duration(days: 3650))),
            lastError: Value(
                '[DEAD_LETTER] Max retries exceeded ($newRetryCount): $error'),
          ),
        );
        return;
      }
      await (_db.update(_db.dbSyncQueue)
            ..where((tbl) => tbl.id.equals(operationId)))
          .write(
        DbSyncQueueCompanion(
          retryCount: Value(newRetryCount),
          nextRetryAt: Value(DateTime.now().add(retryDelay)),
          lastError: Value(error),
        ),
      );
    }
  }

  @override
  Future<void> markOperationDeadLetter(
    String operationId, {
    required String reason,
  }) async {
    await (_db.update(_db.dbSyncQueue)
          ..where((tbl) => tbl.id.equals(operationId)))
        .write(
      DbSyncQueueCompanion(
        nextRetryAt: Value(DateTime.now().add(const Duration(days: 3650))),
        lastError: Value('[DEAD_LETTER] $reason'),
      ),
    );
  }

  @override
  Future<int> getPendingCount() async {
    final countExp = _db.dbSyncQueue.id.count();
    final query = _db.selectOnly(_db.dbSyncQueue)
      ..addColumns([countExp])
      ..where(_db.dbSyncQueue.lastError.isNull() |
          _db.dbSyncQueue.lastError.like('[DEAD_LETTER]%').not());
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getDeadLetterDiagnostics() async {
    final query = _db.select(_db.dbSyncQueue)
      ..where((tbl) =>
          tbl.lastError.isNotNull() & tbl.lastError.like('[DEAD_LETTER]%'))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    final rows = await query.get();
    return rows
        .map((r) => {
              'id': r.id,
              'operation_type': r.operationType,
              'retry_count': r.retryCount,
              'error_code': r.lastError,
              'created_at': r.createdAt.toUtc().toIso8601String(),
              // Raw payload is shielded from support visibility
            })
        .toList();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.dbSyncQueue).go();
  }
}
