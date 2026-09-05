import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/sync/models/sync_models.dart';
import '../../../../core/sync/repositories/sync_queue_repository.dart';
import '../../domain/models/coin_ledger_entry.dart';
import '../../domain/services/coin_ledger_service.dart';

class DriftCoinLedgerRepository {
  final AppDatabase _db;
  final SyncQueueRepository? _syncQueue;

  DriftCoinLedgerRepository({
    required AppDatabase db,
    SyncQueueRepository? syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  Future<void> appendEntry(CoinLedgerEntry entry) async {
    // 1. Check idempotency
    final existing = await (_db.select(_db.dbCoinLedger)
          ..where((tbl) => tbl.idempotencyKey.equals(entry.idempotencyKey)))
        .getSingleOrNull();

    if (existing != null) {
      throw const DuplicateRewardClaimFailure();
    }

    // 2. If debit, validate balance
    if (entry.transactionType == CoinTransactionType.debit) {
      final currentBalance = await getBalance(entry.userId);
      if (currentBalance < entry.amount) {
        throw InsufficientCoinsFailure(entry.amount, currentBalance);
      }
    }

    // 3. Append to SQLite ledger
    await _db.into(_db.dbCoinLedger).insert(
          DbCoinLedgerEntry(
            id: entry.id,
            userId: entry.userId,
            transactionType: entry.transactionType.toDbString(),
            amount: entry.amount,
            reason: entry.reason,
            relatedEntityId: entry.relatedEntityId,
            idempotencyKey: entry.idempotencyKey,
            createdAt: entry.createdAt,
            serverVerified: entry.serverVerified,
          ),
        );

    // 4. Enqueue sync mutation
    final queue = _syncQueue;
    if (queue != null) {
      await queue.enqueue(
        SyncOperation(
          id: 'sync_coin_${entry.id}',
          operationType: SyncOperationType.appendCoinEntry,
          payload: entry.toJson(),
          idempotencyKey: 'coin_${entry.idempotencyKey}',
          nextRetryAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> recordEntry(CoinLedgerEntry entry) => appendEntry(entry);

  Future<List<CoinLedgerEntry>> getLedger([String? userId]) async {
    final query = _db.select(_db.dbCoinLedger);
    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();

    return rows.map((r) {
      return CoinLedgerEntry(
        id: r.id,
        userId: r.userId,
        transactionType: CoinTransactionType.fromString(r.transactionType),
        amount: r.amount,
        reason: r.reason,
        relatedEntityId: r.relatedEntityId,
        idempotencyKey: r.idempotencyKey,
        createdAt: r.createdAt,
        serverVerified: r.serverVerified,
      );
    }).toList();
  }

  Future<int> getBalance(String userId) async {
    final entries = await getLedger(userId);
    return CoinLedgerService.calculateBalance(entries);
  }
}
