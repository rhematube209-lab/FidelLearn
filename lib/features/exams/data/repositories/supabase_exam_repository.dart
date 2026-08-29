import 'package:supabase_flutter/supabase_flutter.dart' hide UserResponse;

import '../../../../core/errors/failures.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/repositories/exam_repository.dart';

class SupabaseExamRepository implements ExamRepository {
  final SupabaseClient _client;
  final Map<String, ExamAttempt> _localActive = {};

  SupabaseExamRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> saveActiveAttempt(ExamAttempt attempt) async {
    // Active incomplete attempts are saved in local storage for zero latency
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

    try {
      // 1. Insert attempt record to Supabase
      await _client.from('exam_attempts').upsert({
        'id': attempt.id,
        'user_id': attempt.userId,
        'exam_id': attempt.examId,
        'exam_title': attempt.examTitle,
        'subject_id': attempt.subjectId,
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
      });

      // 2. Insert user responses
      if (attempt.responses.isNotEmpty) {
        final responsesToInsert = attempt.responses.values.map((resp) {
          return {
            'attempt_id': attempt.id,
            'question_id': resp.questionId,
            'selected_choice_id': resp.selectedChoiceId,
            'is_correct': resp.isCorrect,
            'is_flagged': resp.isFlagged,
            'time_spent_seconds': resp.timeSpentSeconds,
          };
        }).toList();

        await _client.from('user_responses').upsert(responsesToInsert);
      }
    } catch (e) {
      throw StorageFailure('Failed to sync completed attempt to Supabase: $e');
    }
  }

  @override
  Future<List<ExamAttempt>> getAttemptHistory(String userId) async {
    try {
      final response = await _client
          .from('exam_attempts')
          .select('*, responses:user_responses(*)')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('start_time', ascending: false);

      return (response as List<dynamic>).map((json) {
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
          examTitle: map['exam_title'] as String,
          subjectId: map['subject_id'] as String,
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
    } catch (e) {
      throw StorageFailure('Failed to fetch attempt history from Supabase: $e');
    }
  }

  @override
  Future<ExamAttempt?> getAttemptById(String attemptId) async {
    try {
      final response = await _client
          .from('exam_attempts')
          .select('*, responses:user_responses(*)')
          .eq('id', attemptId)
          .maybeSingle();

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
        examTitle: map['exam_title'] as String,
        subjectId: map['subject_id'] as String,
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
