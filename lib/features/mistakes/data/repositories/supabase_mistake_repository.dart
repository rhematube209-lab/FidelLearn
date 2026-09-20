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
    String? unitId,
    String? topicId,
    String? attemptId,
    String? selectedChoiceId,
  }) async {
    final now = DateTime.now();
    final list = _localMistakes.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((m) => m.questionId == questionId);

    // Idempotency: skip if already processed for this attempt
    if (idx != -1 &&
        attemptId != null &&
        list[idx].lastAttemptId == attemptId) {
      if (selectedChoiceId != null &&
          list[idx].lastSelectedChoiceId != selectedChoiceId) {
        list[idx] = list[idx].copyWith(lastSelectedChoiceId: selectedChoiceId);
      }
      return;
    }

    if (idx != -1) {
      final existing = list[idx];
      list[idx] = existing.copyWith(
        unitId: unitId ?? existing.unitId,
        topicId: topicId ?? existing.topicId,
        lastAttemptId: attemptId,
        lastSelectedChoiceId: selectedChoiceId ?? existing.lastSelectedChoiceId,
        missCount: existing.missCount + 1,
        correctRetryCount: 0,
        masteryStatus: MasteryStatus.needsReview,
        lastMissedAt: now,
        lastAttemptAt: now,
        updatedAt: now,
      );
    } else {
      list.add(MistakeRecord(
        id: 'mst_${now.millisecondsSinceEpoch}_${questionId.length > 4 ? questionId.substring(0, 4) : questionId}',
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
        masteryStatus: MasteryStatus.needsReview,
        createdAt: now,
        updatedAt: now,
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
          final count = (existing['miss_count'] ??
                  existing['mistake_count'] as int? ??
                  1) +
              1;
          await client
              .from('mistake_records')
              .update({
                'miss_count': count,
                'correct_retry_count': 0,
                'mastery_status': 'needsReview',
                'last_missed_at': now.toIso8601String(),
                'last_attempt_at': now.toIso8601String(),
                'last_attempt_id': attemptId,
                'last_selected_choice_id': selectedChoiceId,
                // Legacy
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
            'subject_id': subjectId,
            'unit_id': unitId,
            'topic_id': topicId,
            'miss_count': 1,
            'retry_count': 0,
            'correct_retry_count': 0,
            'mastery_status': 'needsReview',
            'first_missed_at': now.toIso8601String(),
            'last_missed_at': now.toIso8601String(),
            'last_attempt_at': now.toIso8601String(),
            'last_attempt_id': attemptId,
            'last_selected_choice_id': selectedChoiceId,
            // Legacy
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
  Future<void> recordRetryResult({
    required String userId,
    required String questionId,
    required bool isCorrect,
    required String attemptId,
    String? selectedChoiceId,
    String? subjectId,
  }) async {
    final list = _localMistakes.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((m) => m.questionId == questionId);
    final now = DateTime.now();

    if (idx != -1 && list[idx].lastAttemptId == attemptId) {
      return;
    }

    if (idx != -1) {
      final existing = list[idx];
      if (!isCorrect) {
        list[idx] = existing.copyWith(
          lastAttemptId: attemptId,
          lastSelectedChoiceId:
              selectedChoiceId ?? existing.lastSelectedChoiceId,
          missCount: existing.missCount + 1,
          correctRetryCount: 0,
          masteryStatus: MasteryStatus.needsReview,
          lastMissedAt: now,
          lastAttemptAt: now,
          updatedAt: now,
        );
      } else {
        final newRetryCount = existing.retryCount + 1;
        final newCorrectRetry = existing.correctRetryCount + 1;
        final newStatus = newCorrectRetry >= 2
            ? MasteryStatus.mastered
            : MasteryStatus.improving;
        list[idx] = existing.copyWith(
          lastAttemptId: attemptId,
          lastSelectedChoiceId:
              selectedChoiceId ?? existing.lastSelectedChoiceId,
          retryCount: newRetryCount,
          correctRetryCount: newCorrectRetry,
          masteryStatus: newStatus,
          lastAttemptAt: now,
          updatedAt: now,
        );
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
          masteryStatus: MasteryStatus.mastered,
          correctRetryCount:
              list[idx].correctRetryCount < 2 ? 2 : list[idx].correctRetryCount,
          updatedAt: DateTime.now(),
        );
      }
    }

    final client = _client;
    if (client != null && _isValidUuid(userId) && _isValidUuid(questionId)) {
      try {
        await client
            .from('mistake_records')
            .update({
              'mastery_status': 'mastered',
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
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) async {
    final localList = _localMistakes[userId] ?? [];
    var filteredLocal = List<MistakeRecord>.from(localList);
    if (onlyUnmastered) {
      filteredLocal = filteredLocal
          .where((m) => m.masteryStatus != MasteryStatus.mastered)
          .toList();
    }
    if (status != null) {
      filteredLocal =
          filteredLocal.where((m) => m.masteryStatus == status).toList();
    }
    if (subjectId != null) {
      filteredLocal =
          filteredLocal.where((m) => m.subjectId == subjectId).toList();
    }
    if (unitId != null) {
      filteredLocal = filteredLocal.where((m) => m.unitId == unitId).toList();
    }
    if (topicId != null) {
      filteredLocal = filteredLocal.where((m) => m.topicId == topicId).toList();
    }

    final client = _client;
    if (client == null || !_isValidUuid(userId)) {
      return filteredLocal;
    }

    try {
      var query = client.from('mistake_records').select().eq('user_id', userId);
      if (onlyUnmastered) {
        query = query.neq('mastery_status', 'mastered');
      }
      if (status != null) {
        query = query.eq('mastery_status', status.toDbString());
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }
      if (topicId != null) {
        query = query.eq('topic_id', topicId);
      }
      final response = await query
          .order('last_missed_at', ascending: false)
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

  @override
  Stream<List<MistakeRecord>> watchMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) {
    return Stream.fromFuture(getMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
      status: status,
      onlyUnmastered: onlyUnmastered,
    ));
  }

  @override
  Future<MistakeCounts> getMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  }) async {
    final list = await getMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
    );
    int needsReview = 0;
    int improving = 0;
    int mastered = 0;

    for (final m in list) {
      switch (m.masteryStatus) {
        case MasteryStatus.improving:
          improving++;
          break;
        case MasteryStatus.mastered:
          mastered++;
          break;
        case MasteryStatus.needsReview:
          needsReview++;
          break;
      }
    }

    return MistakeCounts(
      total: list.length,
      needsReview: needsReview,
      improving: improving,
      mastered: mastered,
    );
  }

  @override
  Stream<MistakeCounts> watchMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  }) {
    return Stream.fromFuture(getMistakeCounts(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
    ));
  }

  @override
  Future<MistakeRecord?> getMistakeById({
    required String userId,
    required String questionId,
  }) async {
    final list = _localMistakes[userId] ?? [];
    return list.cast<MistakeRecord?>().firstWhere(
          (m) => m?.questionId == questionId,
          orElse: () => null,
        );
  }
}
