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

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
  }) async {
    final existing = await (_db.select(_db.dbMistakes)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
        .getSingleOrNull();

    final String mistakeId;
    final int newCount;
    final now = DateTime.now();

    if (existing != null) {
      mistakeId = existing.id;
      newCount = existing.mistakeCount + 1;

      await (_db.update(_db.dbMistakes)
            ..where((tbl) => tbl.id.equals(mistakeId)))
          .write(
        DbMistakesCompanion(
          mistakeCount: Value(newCount),
          isMastered: const Value(false),
          lastFailedAt: Value(now),
        ),
      );
    } else {
      mistakeId = _uuid.v4();
      newCount = 1;

      await _db.into(_db.dbMistakes).insert(
            DbMistake(
              id: mistakeId,
              userId: userId,
              questionId: questionId,
              subjectId: subjectId,
              mistakeCount: 1,
              isMastered: false,
              lastFailedAt: now,
            ),
          );
    }

    final queue = _syncQueue;
    if (queue != null) {
      final payload = {
        'id': mistakeId,
        'user_id': userId,
        'question_id': questionId,
        'subject_id': subjectId,
        'mistake_count': newCount,
        'is_mastered': false,
        'last_failed_at': now.toIso8601String(),
      };
      await queue.enqueue(
        SyncOperation(
          id: 'sync_mistake_${mistakeId}_${now.millisecondsSinceEpoch}',
          operationType: SyncOperationType.recordMistake,
          payload: payload,
          idempotencyKey: 'mistake_${userId}_${questionId}_$newCount',
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
    final existing = await (_db.select(_db.dbMistakes)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
        .getSingleOrNull();

    if (existing == null) return;

    await (_db.update(_db.dbMistakes)
          ..where((tbl) => tbl.id.equals(existing.id)))
        .write(
      DbMistakesCompanion(
        isMastered: const Value(true),
        masteredAt: Value(now),
      ),
    );

    final queue = _syncQueue;
    if (queue != null) {
      final payload = {
        'id': existing.id,
        'user_id': userId,
        'question_id': questionId,
        'subject_id': existing.subjectId,
        'mistake_count': existing.mistakeCount,
        'is_mastered': true,
        'mastered_at': now.toIso8601String(),
      };
      await queue.enqueue(
        SyncOperation(
          id: 'sync_mastered_${existing.id}_${now.millisecondsSinceEpoch}',
          operationType: SyncOperationType.recordMistake,
          payload: payload,
          idempotencyKey: 'mistake_mastered_${userId}_$questionId',
          nextRetryAt: now,
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    bool onlyUnmastered = true,
  }) async {
    var query = _db.select(_db.dbMistakes)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastFailedAt)]);

    if (onlyUnmastered) {
      query = query..where((tbl) => tbl.isMastered.equals(false));
    }

    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }

    final rows = await query.get();
    return rows.map((r) {
      return MistakeRecord(
        id: r.id,
        userId: r.userId,
        questionId: r.questionId,
        subjectId: r.subjectId,
        mistakeCount: r.mistakeCount,
        isMastered: r.isMastered,
        lastFailedAt: r.lastFailedAt,
        masteredAt: r.masteredAt,
      );
    }).toList();
  }
}
