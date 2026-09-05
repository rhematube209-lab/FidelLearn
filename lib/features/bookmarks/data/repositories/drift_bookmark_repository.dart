import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/models/sync_models.dart';
import '../../../../core/sync/repositories/sync_queue_repository.dart';
import '../../domain/models/bookmark_model.dart';
import '../../domain/repositories/bookmark_repository.dart';

class DriftBookmarkRepository implements BookmarkRepository {
  final AppDatabase _db;
  final SyncQueueRepository? _syncQueue;
  static const _uuid = Uuid();

  DriftBookmarkRepository({
    required AppDatabase db,
    SyncQueueRepository? syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String questionId,
    required String subjectId,
    required String topicId,
  }) async {
    final existing = await (_db.select(_db.dbBookmarks)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.questionId.equals(questionId)))
        .getSingleOrNull();

    final bool newActiveState;
    final String bookmarkId;
    final DateTime createdAt;

    if (existing != null) {
      newActiveState = !existing.isActive;
      bookmarkId = existing.id;
      createdAt = existing.createdAt;

      await (_db.update(_db.dbBookmarks)
            ..where((tbl) => tbl.id.equals(bookmarkId)))
          .write(
        DbBookmarksCompanion(
          isActive: Value(newActiveState),
        ),
      );
    } else {
      newActiveState = true;
      bookmarkId = _uuid.v4();
      createdAt = DateTime.now();

      await _db.into(_db.dbBookmarks).insert(
            DbBookmark(
              id: bookmarkId,
              userId: userId,
              questionId: questionId,
              subjectId: subjectId,
              topicId: topicId,
              createdAt: createdAt,
              isActive: true,
            ),
          );
    }

    // Register offline sync mutation
    final queue = _syncQueue;
    if (queue != null) {
      final payload = {
        'id': bookmarkId,
        'user_id': userId,
        'question_id': questionId,
        'subject_id': subjectId,
        'topic_id': topicId,
        'is_active': newActiveState,
        'created_at': createdAt.toIso8601String(),
      };
      await queue.enqueue(
        SyncOperation(
          id: 'sync_bm_${bookmarkId}_${DateTime.now().millisecondsSinceEpoch}',
          operationType: SyncOperationType.toggleBookmark,
          payload: payload,
          idempotencyKey: 'bookmark_${userId}_$questionId',
          nextRetryAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String questionId,
  }) async {
    final row = await (_db.select(_db.dbBookmarks)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.questionId.equals(questionId) &
              tbl.isActive.equals(true)))
        .getSingleOrNull();

    return row != null;
  }

  @override
  Future<List<Bookmark>> getBookmarks(String userId,
      {String? subjectId}) async {
    var query = _db.select(_db.dbBookmarks)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }

    final rows = await query.get();
    return rows.map((r) {
      return Bookmark(
        id: r.id,
        userId: r.userId,
        questionId: r.questionId,
        subjectId: r.subjectId,
        topicId: r.topicId,
        createdAt: r.createdAt,
        isActive: r.isActive,
      );
    }).toList();
  }
}
