import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/mistake_model.dart';
import '../../domain/repositories/mistake_repository.dart';

class SupabaseMistakeRepository implements MistakeRepository {
  final SupabaseClient _client;

  SupabaseMistakeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
  }) async {
    try {
      final existing = await _client
          .from('mistakes')
          .select()
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle();

      final now = DateTime.now();

      if (existing != null) {
        final failCount = (existing['failure_count'] as int? ?? 1) + 1;
        await _client.from('mistakes').update({
          'failure_count': failCount,
          'last_failed_at': now.toIso8601String(),
          'is_mastered': false,
        }).eq('id', existing['id'] as Object);
      } else {
        await _client.from('mistakes').insert({
          'id': 'mst_${now.millisecondsSinceEpoch}_${questionId.substring(0, 4)}',
          'user_id': userId,
          'question_id': questionId,
          'subject_id': subjectId,
          'failure_count': 1,
          'last_failed_at': now.toIso8601String(),
          'is_mastered': false,
        });
      }
    } catch (e) {
      throw StorageFailure('Failed to record mistake in Supabase: $e');
    }
  }

  @override
  Future<void> markMastered({
    required String userId,
    required String questionId,
  }) async {
    try {
      await _client
          .from('mistakes')
          .update({'is_mastered': true})
          .eq('user_id', userId)
          .eq('question_id', questionId);
    } catch (e) {
      throw StorageFailure('Failed to mark mistake as mastered: $e');
    }
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    bool onlyUnmastered = true,
  }) async {
    try {
      var query = _client.from('mistakes').select().eq('user_id', userId);
      if (onlyUnmastered) {
        query = query.eq('is_mastered', false);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      final response = await query.order('last_failed_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => MistakeRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch mistakes from Supabase: $e');
    }
  }
}
