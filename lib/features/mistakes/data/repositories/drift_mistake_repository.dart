import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/models/sync_models.dart';
import '../../../../core/sync/repositories/sync_queue_repository.dart';
import '../../domain/models/mistake_model.dart';
import '../../domain/repositories/mistake_repository.dart';

class DriftMistakeRepository implements MistakeRepository {
  final AppDatabase _db;
  final SyncQueueRepository? _syncQueue;
  static const _uuid = Uuid();

  DriftMistakeRepository({
    required AppDatabase db,
    SyncQueueRepository? syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  MistakeRecord _toDomain(DbMistake r) {
    final defaultTime = r.lastFailedAt ?? DateTime.now();
    return MistakeRecord(
      id: r.id,
      userId: r.userId,
      questionId: r.questionId,
      subjectId: r.subjectId,
      unitId: r.unitId,
      topicId: r.topicId,
      lastAttemptId: r.lastAttemptId,
      lastSelectedChoiceId: r.lastSelectedChoiceId,
      firstMissedAt: r.firstMissedAt ?? defaultTime,
      lastMissedAt: r.lastMissedAt ?? defaultTime,
      lastAttemptAt: r.lastAttemptAt,
      missCount: r.missCount,
      retryCount: r.retryCount,
      correctRetryCount: r.correctRetryCount,
      masteryStatus: MasteryStatus.fromString(r.masteryStatus),
      createdAt: r.createdAt ?? defaultTime,
      updatedAt: r.updatedAt ?? r.masteredAt ?? defaultTime,
      syncStatus: r.syncStatus,
    );
  }

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? attemptId,
    String? selectedChoiceId,
  }) async {
    final now = DateTime.now();

    MistakeRecord? recordToSync;

    await _db.transaction(() async {
      final existing = await (_db.select(_db.dbMistakes)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
          .getSingleOrNull();

      // Section 14 & 16: Attempt + Question Idempotency
      // If already recorded for this attempt, update choice if needed, but do not increment missCount
      if (existing != null &&
          attemptId != null &&
          existing.lastAttemptId == attemptId) {
        if (selectedChoiceId != null &&
            existing.lastSelectedChoiceId != selectedChoiceId) {
          await (_db.update(_db.dbMistakes)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(
            DbMistakesCompanion(
              lastSelectedChoiceId: Value(selectedChoiceId),
            ),
          );
        }
        return;
      }

      if (existing != null) {
        final newMissCount = existing.missCount + 1;
        final updatedCompanion = DbMistakesCompanion(
          unitId: unitId != null ? Value(unitId) : Value(existing.unitId),
          topicId: topicId != null ? Value(topicId) : Value(existing.topicId),
          lastAttemptId: Value(attemptId),
          lastSelectedChoiceId:
              Value(selectedChoiceId ?? existing.lastSelectedChoiceId),
          lastMissedAt: Value(now),
          lastAttemptAt: Value(now),
          missCount: Value(newMissCount),
          correctRetryCount:
              const Value(0), // Reset correct retry count on miss
          masteryStatus: const Value('needsReview'), // Demote to needsReview
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
          // Legacy backward compatibility
          mistakeCount: Value(newMissCount),
          isMastered: const Value(false),
          lastFailedAt: Value(now),
        );

        await (_db.update(_db.dbMistakes)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(updatedCompanion);

        final updatedRow = await (_db.select(_db.dbMistakes)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .getSingle();
        recordToSync = _toDomain(updatedRow);
      } else {
        final mistakeId = _uuid.v4();
        final newRow = DbMistake(
          id: mistakeId,
          userId: userId,
          questionId: questionId,
          subjectId: subjectId,
          unitId: unitId,
          topicId: topicId,
          lastAttemptId: attemptId,
          lastSelectedChoiceId: selectedChoiceId,
          firstMissedAt: now,
          lastMissedAt: now,
          lastAttemptAt: now,
          missCount: 1,
          retryCount: 0,
          correctRetryCount: 0,
          masteryStatus: 'needsReview',
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pending',
          mistakeCount: 1,
          isMastered: false,
          lastFailedAt: now,
        );

        await _db.into(_db.dbMistakes).insert(newRow);
        recordToSync = _toDomain(newRow);
      }
    });

    final queue = _syncQueue;
    if (queue != null && recordToSync != null) {
      await queue.enqueue(
        SyncOperation(
          id: 'sync_mistake_${recordToSync!.id}_${now.millisecondsSinceEpoch}',
          operationType: SyncOperationType.recordMistake,
          payload: recordToSync!.toJson(),
          idempotencyKey:
              'mistake_${userId}_${questionId}_${attemptId ?? recordToSync!.missCount}',
          nextRetryAt: now,
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<void> recordRetryResult({
    required String userId,
    required String questionId,
    required bool isCorrect,
    required String attemptId,
    String? selectedChoiceId,
    String? subjectId,
  }) async {
    final now = DateTime.now();
    MistakeRecord? recordToSync;

    await _db.transaction(() async {
      final existing = await (_db.select(_db.dbMistakes)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
          .getSingleOrNull();

      // Section 14, 15, 16: Strict Attempt+Question Retry Idempotency
      // The same attempt cannot trigger multiple retry state transitions for the same question
      if (existing != null && existing.lastAttemptId == attemptId) {
        return;
      }

      if (existing != null) {
        if (!isCorrect) {
          // Retry failed: increment missCount, reset correctRetryCount to 0, demote to needsReview
          final newMissCount = existing.missCount + 1;
          await (_db.update(_db.dbMistakes)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(
            DbMistakesCompanion(
              lastAttemptId: Value(attemptId),
              lastSelectedChoiceId:
                  Value(selectedChoiceId ?? existing.lastSelectedChoiceId),
              lastMissedAt: Value(now),
              lastAttemptAt: Value(now),
              missCount: Value(newMissCount),
              correctRetryCount: const Value(0),
              masteryStatus: const Value('needsReview'),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
              // Legacy
              mistakeCount: Value(newMissCount),
              isMastered: const Value(false),
              lastFailedAt: Value(now),
            ),
          );
        } else {
          // Retry succeeded: increment retryCount and correctRetryCount
          final newRetryCount = existing.retryCount + 1;
          final newCorrectRetryCount = existing.correctRetryCount + 1;
          final String newStatus =
              newCorrectRetryCount >= 2 ? 'mastered' : 'improving';
          final DateTime? masteredAt =
              newCorrectRetryCount >= 2 ? now : existing.masteredAt;

          await (_db.update(_db.dbMistakes)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(
            DbMistakesCompanion(
              lastAttemptId: Value(attemptId),
              lastSelectedChoiceId:
                  Value(selectedChoiceId ?? existing.lastSelectedChoiceId),
              lastAttemptAt: Value(now),
              retryCount: Value(newRetryCount),
              correctRetryCount: Value(newCorrectRetryCount),
              masteryStatus: Value(newStatus),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
              // Legacy
              isMastered: Value(newCorrectRetryCount >= 2),
              masteredAt: Value(masteredAt),
            ),
          );
        }

        final updatedRow = await (_db.select(_db.dbMistakes)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .getSingle();
        recordToSync = _toDomain(updatedRow);
      } else {
        // Record didn't exist yet: insert initial record
        final mistakeId = _uuid.v4();
        final newRow = DbMistake(
          id: mistakeId,
          userId: userId,
          questionId: questionId,
          subjectId: subjectId ?? 'general',
          lastAttemptId: attemptId,
          lastSelectedChoiceId: selectedChoiceId,
          firstMissedAt: now,
          lastMissedAt: now,
          lastAttemptAt: now,
          missCount: isCorrect ? 0 : 1,
          retryCount: isCorrect ? 1 : 0,
          correctRetryCount: isCorrect ? 1 : 0,
          masteryStatus: isCorrect ? 'improving' : 'needsReview',
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pending',
          mistakeCount: isCorrect ? 0 : 1,
          isMastered: false,
          lastFailedAt: now,
        );

        await _db.into(_db.dbMistakes).insert(newRow);
        recordToSync = _toDomain(newRow);
      }
    });

    final queue = _syncQueue;
    if (queue != null && recordToSync != null) {
      await queue.enqueue(
        SyncOperation(
          id: 'sync_retry_${recordToSync!.id}_${now.millisecondsSinceEpoch}',
          operationType: SyncOperationType.recordMistake,
          payload: recordToSync!.toJson(),
          idempotencyKey: 'retry_${userId}_${questionId}_$attemptId',
          nextRetryAt: now,
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<void> markMastered({
    required String userId,
    required String questionId,
  }) async {
    final now = DateTime.now();
    MistakeRecord? recordToSync;

    await _db.transaction(() async {
      final existing = await (_db.select(_db.dbMistakes)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
          .getSingleOrNull();

      if (existing == null) return;

      await (_db.update(_db.dbMistakes)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(
        DbMistakesCompanion(
          masteryStatus: const Value('mastered'),
          correctRetryCount: Value(
              existing.correctRetryCount < 2 ? 2 : existing.correctRetryCount),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
          // Legacy
          isMastered: const Value(true),
          masteredAt: Value(now),
        ),
      );

      final updatedRow = await (_db.select(_db.dbMistakes)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .getSingle();
      recordToSync = _toDomain(updatedRow);
    });

    final queue = _syncQueue;
    if (queue != null && recordToSync != null) {
      await queue.enqueue(
        SyncOperation(
          id: 'sync_mastered_${recordToSync!.id}_${now.millisecondsSinceEpoch}',
          operationType: SyncOperationType.recordMistake,
          payload: recordToSync!.toJson(),
          idempotencyKey: 'mistake_mastered_${userId}_$questionId',
          nextRetryAt: now,
          createdAt: now,
        ),
      );
    }
  }

  SimpleSelectStatement<$DbMistakesTable, DbMistake> _buildQuery(
    String userId, {
    String? subjectId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) {
    var query = _db.select(_db.dbMistakes)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.lastMissedAt),
        (tbl) => OrderingTerm.desc(tbl.createdAt),
      ]);

    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }

    if (status != null) {
      query = query
        ..where((tbl) => tbl.masteryStatus.equals(status.toDbString()));
    } else if (onlyUnmastered) {
      query = query..where((tbl) => tbl.masteryStatus.isNotIn(['mastered']));
    }

    return query;
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) async {
    final rows = await _buildQuery(
      userId,
      subjectId: subjectId,
      status: status,
      onlyUnmastered: onlyUnmastered,
    ).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<MistakeRecord>> watchMistakes(
    String userId, {
    String? subjectId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) {
    return _buildQuery(
      userId,
      subjectId: subjectId,
      status: status,
      onlyUnmastered: onlyUnmastered,
    ).watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<MistakeCounts> getMistakeCounts(
    String userId, {
    String? subjectId,
  }) async {
    var query = _db.select(_db.dbMistakes)
      ..where((tbl) => tbl.userId.equals(userId));
    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }
    final rows = await query.get();
    return _aggregateCounts(rows);
  }

  @override
  Stream<MistakeCounts> watchMistakeCounts(
    String userId, {
    String? subjectId,
  }) {
    var query = _db.select(_db.dbMistakes)
      ..where((tbl) => tbl.userId.equals(userId));
    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }
    return query.watch().map(_aggregateCounts);
  }

  MistakeCounts _aggregateCounts(List<DbMistake> rows) {
    int needsReview = 0;
    int improving = 0;
    int mastered = 0;

    for (final r in rows) {
      switch (r.masteryStatus) {
        case 'improving':
          improving++;
          break;
        case 'mastered':
          mastered++;
          break;
        case 'needsReview':
        default:
          needsReview++;
          break;
      }
    }

    return MistakeCounts(
      total: rows.length,
      needsReview: needsReview,
      improving: improving,
      mastered: mastered,
    );
  }

  @override
  Future<MistakeRecord?> getMistakeById({
    required String userId,
    required String questionId,
  }) async {
    final row = await (_db.select(_db.dbMistakes)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
        .getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }
}
