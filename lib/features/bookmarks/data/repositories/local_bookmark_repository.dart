import '../../domain/models/bookmark_model.dart';
import '../../domain/repositories/bookmark_repository.dart';

class LocalBookmarkRepository implements BookmarkRepository {
  final Map<String, Bookmark> _bookmarks = {}; // Key: "userId_questionId"

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String questionId,
    required String subjectId,
    required String topicId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _bookmarks[key];

    if (existing != null && existing.isActive) {
      _bookmarks[key] = existing.copyWith(isActive: false);
    } else if (existing != null && !existing.isActive) {
      _bookmarks[key] = existing.copyWith(isActive: true);
    } else {
      _bookmarks[key] = Bookmark(
        id: 'bm_$key',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        topicId: topicId,
        createdAt: DateTime.now(),
        isActive: true,
      );
    }
  }

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String questionId,
  }) async {
    final key = '${userId}_$questionId';
    return _bookmarks[key]?.isActive ?? false;
  }

  @override
  Future<List<Bookmark>> getBookmarks(
    String userId, {
    String? subjectId,
  }) async {
    return _bookmarks.values
        .where(
          (b) =>
              b.userId == userId &&
              b.isActive &&
              (subjectId == null || b.subjectId == subjectId),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
