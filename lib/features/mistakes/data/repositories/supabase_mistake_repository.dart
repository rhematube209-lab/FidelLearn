import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/mistake_model.dart';
import '../../domain/repositories/mistake_repository.dart';

class SupabaseMistakeRepository implements MistakeRepository {
  final SupabaseClient? _client;
  final Map<String, List<MistakeRecord>> _localMistakes = {};

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseMistakeRepository({SupabaseClient? client})
      : _client = client ?? _getSafeClient();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String str) => _uuidRegex.hasMatch(str);

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
  }) async {
    final now = DateTime.now();
    final list = _localMistakes.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((m) => m.questionId == questionId);
    if (idx != -1) {
      final existing = list[idx];
      list[idx] = existing.copyWith(
        mistakeCount: existing.mistakeCount + 1,
        lastFailedAt: now,
        isMastered: false,
      );
    } else {
      list.add(MistakeRecord(
        id: 'mst_${now.millisecondsSinceEpoch}_${questionId.length > 4 ? questionId.substring(0, 4) : questionId}',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        mistakeCount: 1,
        isMastered: false,
        lastFailedAt: now,
      ));
    }

    final client = _client;
    if (client != null && _isValidUuid(userId) && _isValidUuid(questionId)) {
      try {
        final existing = await client
            .from('mistake_records')
            .select()
            .eq('user_id', userId)
            .eq('question_id', questionId)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        if (existing != null) {
          final count = (existing['mistake_count'] as int? ?? 1) + 1;
          await client
              .from('mistake_records')
              .update({
                'mistake_count': count,
                'last_failed_at': now.toIso8601String(),
                'is_mastered': false,
              })
              .eq('id', existing['id'] as Object)
              .timeout(const Duration(seconds: 5));
        } else {
          await client.from('mistake_records').insert({
            'user_id': userId,
            'question_id': questionId,
            'mistake_count': 1,
            'last_failed_at': now.toIso8601String(),
            'is_mastered': false,
          }).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint(
            'SupabaseMistakeRepository: sync failed (fallback to local): $e');
      }
    }
  }

  @override
  Future<void> markMastered({
    required String userId,
    required String questionId,
  }) async {
    final list = _localMistakes[userId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.questionId == questionId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          isMastered: true,
          masteredAt: DateTime.now(),
        );
      }
    }

    final client = _client;
    if (client != null && _isValidUuid(userId) && _isValidUuid(questionId)) {
      try {
        await client
            .from('mistake_records')
            .update({
              'is_mastered': true,
              'mastered_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('question_id', questionId)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint(
            'SupabaseMistakeRepository: markMastered remote sync error: $e');
      }
    }
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    bool onlyUnmastered = true,
  }) async {
    final localList = _localMistakes[userId] ?? [];
    var filteredLocal = List<MistakeRecord>.from(localList);
    if (onlyUnmastered) {
      filteredLocal = filteredLocal.where((m) => !m.isMastered).toList();
    }
    if (subjectId != null) {
      filteredLocal =
          filteredLocal.where((m) => m.subjectId == subjectId).toList();
    }

    final client = _client;
    if (client == null || !_isValidUuid(userId)) {
      return filteredLocal;
    }

    try {
      var query = client.from('mistake_records').select().eq('user_id', userId);
      if (onlyUnmastered) {
        query = query.eq('is_mastered', false);
      }
      final response = await query
          .order('last_failed_at', ascending: false)
          .timeout(const Duration(seconds: 5));

      final remoteRecords = (response as List<dynamic>)
          .map((json) => MistakeRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      return remoteRecords.isNotEmpty ? remoteRecords : filteredLocal;
    } catch (e) {
      debugPrint(
          'SupabaseMistakeRepository: getMistakes failed, using local: $e');
      return filteredLocal;
    }
  }
}
