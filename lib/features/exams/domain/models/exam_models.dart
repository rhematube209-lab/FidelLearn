import 'package:equatable/equatable.dart';

import '../../../question_bank/domain/models/question_models.dart';

enum ExamType {
  practice,
  unitTest,
  mockFull,
  customBuilder,
  teacherAssigned;

  static ExamType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'unit_test':
        return ExamType.unitTest;
      case 'mock_full':
        return ExamType.mockFull;
      case 'custom_builder':
        return ExamType.customBuilder;
      case 'teacher_assigned':
        return ExamType.teacherAssigned;
      case 'practice':
      default:
        return ExamType.practice;
    }
  }

  String toDbString() {
    switch (this) {
      case ExamType.unitTest:
        return 'unit_test';
      case ExamType.mockFull:
        return 'mock_full';
      case ExamType.customBuilder:
        return 'custom_builder';
      case ExamType.teacherAssigned:
        return 'teacher_assigned';
      case ExamType.practice:
        return 'practice';
    }
  }
}

class Exam extends Equatable {
  final String id;
  final String title;
  final ExamType examType;
  final int grade;
  final String stream;
  final String? subjectId;
  final int timeLimitMinutes; // 0 for untimed
  final int totalQuestions;
  final List<Question> questions;
  final DateTime createdAt;

  const Exam({
    required this.id,
    required this.title,
    required this.examType,
    required this.grade,
    required this.stream,
    this.subjectId,
    required this.timeLimitMinutes,
    required this.totalQuestions,
    required this.questions,
    required this.createdAt,
  });

  bool get isTimed => timeLimitMinutes > 0;

  @override
  List<Object?> get props => [
    id,
    title,
    examType,
    grade,
    stream,
    subjectId,
    timeLimitMinutes,
    totalQuestions,
    questions,
    createdAt,
  ];
}

class UserResponse extends Equatable {
  final String questionId;
  final String? selectedChoiceId;
  final bool isCorrect;
  final int timeSpentSeconds;
  final bool isFlagged;

  const UserResponse({
    required this.questionId,
    this.selectedChoiceId,
    required this.isCorrect,
    this.timeSpentSeconds = 0,
    this.isFlagged = false,
  });

  UserResponse copyWith({
    String? selectedChoiceId,
    bool? isCorrect,
    int? timeSpentSeconds,
    bool? isFlagged,
  }) {
    return UserResponse(
      questionId: questionId,
      selectedChoiceId: selectedChoiceId ?? this.selectedChoiceId,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_choice_id': selectedChoiceId,
      'is_correct': isCorrect,
      'time_spent_seconds': timeSpentSeconds,
      'is_flagged': isFlagged,
    };
  }

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      questionId: json['question_id'] as String,
      selectedChoiceId: json['selected_choice_id'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      timeSpentSeconds: json['time_spent_seconds'] as int? ?? 0,
      isFlagged: json['is_flagged'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    questionId,
    selectedChoiceId,
    isCorrect,
    timeSpentSeconds,
    isFlagged,
  ];
}

class ExamAttempt extends Equatable {
  final String id;
  final String userId;
  final String examId;
  final String examTitle;
  final String subjectId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int totalQuestions;
  final int score;
  final double percentage;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final bool isCompleted;
  final Map<String, UserResponse> responses;
  final String syncStatus; // 'synced' | 'pending' | 'failed'

  const ExamAttempt({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examTitle,
    required this.subjectId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.totalQuestions,
    required this.score,
    required this.percentage,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.isCompleted,
    required this.responses,
    this.syncStatus = 'synced',
  });

  ExamAttempt copyWith({
    DateTime? endTime,
    int? durationSeconds,
    int? score,
    double? percentage,
    int? correctCount,
    int? incorrectCount,
    int? skippedCount,
    bool? isCompleted,
    Map<String, UserResponse>? responses,
    String? syncStatus,
  }) {
    return ExamAttempt(
      id: id,
      userId: userId,
      examId: examId,
      examTitle: examTitle,
      subjectId: subjectId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalQuestions: totalQuestions,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      skippedCount: skippedCount ?? this.skippedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      responses: responses ?? this.responses,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exam_id': examId,
      'exam_title': examTitle,
      'subject_id': subjectId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'total_questions': totalQuestions,
      'score': score,
      'percentage': percentage,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'skipped_count': skippedCount,
      'is_completed': isCompleted,
      'responses': responses.map((k, v) => MapEntry(k, v.toJson())),
      'sync_status': syncStatus,
    };
  }

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawResp =
        (json['responses'] as Map<String, dynamic>?) ?? {};
    final Map<String, UserResponse> parsedResp = rawResp.map(
      (k, v) => MapEntry(k, UserResponse.fromJson(v as Map<String, dynamic>)),
    );

    return ExamAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      examId: json['exam_id'] as String,
      examTitle: json['exam_title'] as String? ?? 'Practice Exam',
      subjectId: json['subject_id'] as String? ?? 'math_g12',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int,
      score: json['score'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      correctCount: json['correct_count'] as int? ?? 0,
      incorrectCount: json['incorrect_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      responses: parsedResp,
      syncStatus: json['sync_status'] as String? ?? 'synced',
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    examId,
    examTitle,
    subjectId,
    startTime,
    endTime,
    durationSeconds,
    totalQuestions,
    score,
    percentage,
    correctCount,
    incorrectCount,
    skippedCount,
    isCompleted,
    responses,
    syncStatus,
  ];
}
