import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/bookmark_model.dart';
import '../../domain/repositories/bookmark_repository.dart';

class SupabaseBookmarkRepository implements BookmarkRepository {
  final SupabaseClient? _client;
  final Map<String, List<Bookmark>> _localBookmarks = {};

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseBookmarkRepository({SupabaseClient? client})
      : _client = client ?? _getSafeClient();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String str) => _uuidRegex.hasMatch(str);

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String questionId,
    required String subjectId,
    String? topicId,
  }) async {
    final list = _localBookmarks.putIfAbsent(userId, () => []);
    final existingIdx = list.indexWhere((b) => b.questionId == questionId);

    if (existingIdx != -1) {
      list.removeAt(existingIdx);
    } else {
      list.add(Bookmark(
        id: 'bm_${DateTime.now().millisecondsSinceEpoch}_${questionId.length > 4 ? questionId.substring(0, 4) : questionId}',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        topicId: topicId ?? 'general',
        createdAt: DateTime.now(),
      ));
    }

    final client = _client;
    if (client != null && _isValidUuid(userId) && _isValidUuid(questionId)) {
      try {
        final existing = await client
            .from('bookmarks')
            .select()
            .eq('user_id', userId)
            .eq('question_id', questionId)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        if (existing != null) {
          await client
              .from('bookmarks')
              .delete()
              .eq('user_id', userId)
              .eq('question_id', questionId)
              .timeout(const Duration(seconds: 5));
        } else {
          await client.from('bookmarks').insert({
            'user_id': userId,
            'question_id': questionId,
            'subject_id': subjectId,
            'topic_id': topicId ?? 'general',
            'created_at': DateTime.now().toIso8601String(),
          }).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint(
            'SupabaseBookmarkRepository: toggleBookmark error (using local): $e');
      }
    }
  }

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String questionId,
  }) async {
    final list = _localBookmarks[userId];
    if (list != null && list.any((b) => b.questionId == questionId)) {
      return true;
    }

    final client = _client;
    if (client == null || !_isValidUuid(userId) || !_isValidUuid(questionId)) {
      return false;
    }

    try {
      final existing = await client
          .from('bookmarks')
          .select('id')
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

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
    final localList = _localBookmarks[userId] ?? [];
    var filteredLocal = List<Bookmark>.from(localList);
    if (subjectId != null) {
      filteredLocal =
          filteredLocal.where((b) => b.subjectId == subjectId).toList();
    }

    final client = _client;
    if (client == null || !_isValidUuid(userId)) {
      return filteredLocal;
    }

    try {
      var query = client.from('bookmarks').select().eq('user_id', userId);
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      final response = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 5));

      final remoteBookmarks = (response as List<dynamic>)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      return remoteBookmarks.isNotEmpty ? remoteBookmarks : filteredLocal;
    } catch (e) {
      debugPrint(
          'SupabaseBookmarkRepository: getBookmarks error (using local): $e');
      return filteredLocal;
    }
  }
}
