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
      ..where((tbl) => tbl.nextRetryAt.isSmallerOrEqualValue(now))
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
      await (_db.update(_db.dbSyncQueue)
            ..where((tbl) => tbl.id.equals(operationId)))
          .write(
        DbSyncQueueCompanion(
          retryCount: Value(current.retryCount + 1),
          nextRetryAt: Value(DateTime.now().add(retryDelay)),
          lastError: Value(error),
        ),
      );
    }
  }

  @override
  Future<int> getPendingCount() async {
    final countExp = _db.dbSyncQueue.id.count();
    final query = _db.selectOnly(_db.dbSyncQueue)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.dbSyncQueue).go();
  }
}
