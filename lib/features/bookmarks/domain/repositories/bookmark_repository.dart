import '../models/bookmark_model.dart';

abstract class BookmarkRepository {
  Future<void> toggleBookmark({
    required String userId,
    required String questionId,
    required String subjectId,
    required String topicId,
  });
  Future<bool> isBookmarked({
    required String userId,
    required String questionId,
  });
  Future<List<Bookmark>> getBookmarks(String userId, {String? subjectId});
}
