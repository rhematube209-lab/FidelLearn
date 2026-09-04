import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide UserResponse;

import '../../domain/models/exam_models.dart';
import '../../domain/repositories/exam_repository.dart';

class SupabaseExamRepository implements ExamRepository {
  final SupabaseClient? _client;
  final Map<String, ExamAttempt> _localActive = {};
  final List<ExamAttempt> _localHistory = [];

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseExamRepository({SupabaseClient? client})
      : _client = client ?? _getSafeClient();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String str) => _uuidRegex.hasMatch(str);

  @override
  Future<void> saveActiveAttempt(ExamAttempt attempt) async {
    _localActive[attempt.userId] = attempt;
  }

  @override
  Future<ExamAttempt?> getActiveAttempt(String userId) async {
    return _localActive[userId];
  }

  @override
  Future<void> clearActiveAttempt(String userId) async {
    _localActive.remove(userId);
  }

  @override
  Future<void> saveCompletedAttempt(ExamAttempt attempt) async {
    _localActive.remove(attempt.userId);
    // Always store locally first for offline guarantee
    _localHistory.removeWhere((a) => a.id == attempt.id);
    _localHistory.insert(0, attempt);

    // If IDs are valid UUIDs and remote client available, attempt remote sync safely
    final client = _client;
    if (client != null &&
        _isValidUuid(attempt.userId) &&
        _isValidUuid(attempt.id) &&
        _isValidUuid(attempt.examId)) {
      try {
        await client.from('attempts').upsert({
          'id': attempt.id,
          'user_id': attempt.userId,
          'exam_id': attempt.examId,
          'start_time': attempt.startTime.toIso8601String(),
          'end_time': attempt.endTime?.toIso8601String(),
          'duration_seconds': attempt.durationSeconds,
          'total_questions': attempt.totalQuestions,
          'score': attempt.score,
          'percentage': attempt.percentage,
          'correct_count': attempt.correctCount,
          'incorrect_count': attempt.incorrectCount,
          'skipped_count': attempt.skippedCount,
          'is_completed': attempt.isCompleted,
        }).timeout(const Duration(seconds: 5));

        if (attempt.responses.isNotEmpty) {
          final responsesToInsert = <Map<String, dynamic>>[];
          for (final resp in attempt.responses.values) {
            if (_isValidUuid(resp.questionId)) {
              responsesToInsert.add({
                'attempt_id': attempt.id,
                'question_id': resp.questionId,
                'selected_choice_id': (resp.selectedChoiceId != null &&
                        _isValidUuid(resp.selectedChoiceId!))
                    ? resp.selectedChoiceId
                    : null,
                'is_correct': resp.isCorrect,
                'is_flagged': resp.isFlagged,
                'time_spent_seconds': resp.timeSpentSeconds,
              });
            }
          }
          if (responsesToInsert.isNotEmpty) {
            await client
                .from('attempt_responses')
                .upsert(responsesToInsert)
                .timeout(const Duration(seconds: 5));
          }
        }
      } catch (e) {
        debugPrint(
            'SupabaseExamRepository: remote sync failed (safe fallback to local): $e');
      }
    }
  }

  @override
  Future<List<ExamAttempt>> getAttemptHistory(String userId) async {
    final localUserHistory =
        _localHistory.where((a) => a.userId == userId).toList();
    final client = _client;

    if (client == null || !_isValidUuid(userId)) {
      return localUserHistory;
    }

    try {
      final response = await client
          .from('attempts')
          .select('*, responses:attempt_responses(*)')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('start_time', ascending: false)
          .timeout(const Duration(seconds: 5));

      final remoteAttempts = (response as List<dynamic>).map((json) {
        final map = json as Map<String, dynamic>;
        final responsesMap = <String, UserResponse>{};

        if (map['responses'] != null) {
          for (final r in map['responses'] as List<dynamic>) {
            final rMap = r as Map<String, dynamic>;
            final qId = rMap['question_id'] as String;
            responsesMap[qId] = UserResponse(
              questionId: qId,
              selectedChoiceId: rMap['selected_choice_id'] as String?,
              isCorrect: rMap['is_correct'] as bool? ?? false,
              isFlagged: rMap['is_flagged'] as bool? ?? false,
              timeSpentSeconds: rMap['time_spent_seconds'] as int? ?? 0,
            );
          }
        }

        return ExamAttempt(
          id: map['id'] as String,
          userId: map['user_id'] as String,
          examId: map['exam_id'] as String,
          examTitle: map['exam_title'] as String? ?? 'Practice Exam',
          subjectId: map['subject_id'] as String? ?? 'general',
          startTime: DateTime.parse(map['start_time'] as String),
          endTime: map['end_time'] != null
              ? DateTime.parse(map['end_time'] as String)
              : null,
          durationSeconds: map['duration_seconds'] as int? ?? 0,
          totalQuestions: map['total_questions'] as int? ?? 0,
          score: map['score'] as int? ?? 0,
          percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
          correctCount: map['correct_count'] as int? ?? 0,
          incorrectCount: map['incorrect_count'] as int? ?? 0,
          skippedCount: map['skipped_count'] as int? ?? 0,
          isCompleted: map['is_completed'] as bool? ?? true,
          responses: responsesMap,
        );
      }).toList();

      final seenIds = remoteAttempts.map((a) => a.id).toSet();
      for (final localAttempt in localUserHistory) {
        if (!seenIds.contains(localAttempt.id)) {
          remoteAttempts.add(localAttempt);
        }
      }

      remoteAttempts.sort((a, b) => b.startTime.compareTo(a.startTime));
      return remoteAttempts;
    } catch (e) {
      debugPrint(
          'SupabaseExamRepository: getAttemptHistory error, returning local: $e');
      return localUserHistory;
    }
  }

  @override
  Future<ExamAttempt?> getAttemptById(String attemptId) async {
    for (final a in _localHistory) {
      if (a.id == attemptId) return a;
    }

    final client = _client;
    if (client == null || !_isValidUuid(attemptId)) return null;

    try {
      final response = await client
          .from('attempts')
          .select('*, responses:attempt_responses(*)')
          .eq('id', attemptId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return null;
      final map = response;
      final responsesMap = <String, UserResponse>{};

      if (map['responses'] != null) {
        for (final r in map['responses'] as List<dynamic>) {
          final rMap = r as Map<String, dynamic>;
          final qId = rMap['question_id'] as String;
          responsesMap[qId] = UserResponse(
            questionId: qId,
            selectedChoiceId: rMap['selected_choice_id'] as String?,
            isCorrect: rMap['is_correct'] as bool? ?? false,
            isFlagged: rMap['is_flagged'] as bool? ?? false,
            timeSpentSeconds: rMap['time_spent_seconds'] as int? ?? 0,
          );
        }
      }

      return ExamAttempt(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        examId: map['exam_id'] as String,
        examTitle: map['exam_title'] as String? ?? 'Practice Exam',
        subjectId: map['subject_id'] as String? ?? 'general',
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
        totalQuestions: map['total_questions'] as int? ?? 0,
        score: map['score'] as int? ?? 0,
        percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
        correctCount: map['correct_count'] as int? ?? 0,
        incorrectCount: map['incorrect_count'] as int? ?? 0,
        skippedCount: map['skipped_count'] as int? ?? 0,
        isCompleted: map['is_completed'] as bool? ?? true,
        responses: responsesMap,
      );
    } catch (_) {
      return null;
    }
  }
}
