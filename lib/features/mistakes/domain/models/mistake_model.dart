import 'package:equatable/equatable.dart';

class MistakeRecord extends Equatable {
  final String id;
  final String userId;
  final String questionId;
  final String subjectId;
  final int mistakeCount;
  final bool isMastered;
  final DateTime lastFailedAt;
  final DateTime? masteredAt;

  const MistakeRecord({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.subjectId,
    required this.mistakeCount,
    required this.isMastered,
    required this.lastFailedAt,
    this.masteredAt,
  });

  MistakeRecord copyWith({
    int? mistakeCount,
    bool? isMastered,
    DateTime? lastFailedAt,
    DateTime? masteredAt,
  }) {
    return MistakeRecord(
      id: id,
      userId: userId,
      questionId: questionId,
      subjectId: subjectId,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      isMastered: isMastered ?? this.isMastered,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      masteredAt: masteredAt ?? this.masteredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'subject_id': subjectId,
      'mistake_count': mistakeCount,
      'is_mastered': isMastered,
      'last_failed_at': lastFailedAt.toIso8601String(),
      'mastered_at': masteredAt?.toIso8601String(),
    };
  }

  factory MistakeRecord.fromJson(Map<String, dynamic> json) {
    return MistakeRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      subjectId: json['subject_id'] as String? ?? 'math_g12',
      mistakeCount: json['mistake_count'] as int? ?? 1,
      isMastered: json['is_mastered'] as bool? ?? false,
      lastFailedAt: DateTime.parse(json['last_failed_at'] as String),
      masteredAt: json['mastered_at'] != null
          ? DateTime.parse(json['mastered_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questionId,
        subjectId,
        mistakeCount,
        isMastered,
        lastFailedAt,
        masteredAt,
      ];
}
