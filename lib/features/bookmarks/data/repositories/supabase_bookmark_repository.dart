import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/bookmark_model.dart';
import '../../domain/repositories/bookmark_repository.dart';

class SupabaseBookmarkRepository implements BookmarkRepository {
  final SupabaseClient _client;

  SupabaseBookmarkRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String questionId,
    required String subjectId,
    String? topicId,
  }) async {
    try {
      final existing = await _client
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('question_id', questionId);
      } else {
        await _client.from('bookmarks').insert({
          'id': 'bm_${DateTime.now().millisecondsSinceEpoch}_${questionId.substring(0, 4)}',
          'user_id': userId,
          'question_id': questionId,
          'subject_id': subjectId,
          'topic_id': topicId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw StorageFailure('Failed to toggle bookmark in Supabase: $e');
    }
  }

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String questionId,
  }) async {
    try {
      final existing = await _client
          .from('bookmarks')
          .select('id')
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle();

      return existing != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks(
    String userId, {
    String? subjectId,
  }) async {
    try {
      var query = _client.from('bookmarks').select().eq('user_id', userId);
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      final response = await query.order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch bookmarks from Supabase: $e');
    }
  }
}
