import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final String id;
  final String userId;
  final String questionId;
  final String subjectId;
  final String topicId;
  final DateTime createdAt;
  final bool isActive;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.subjectId,
    required this.topicId,
    required this.createdAt,
    this.isActive = true,
  });

  Bookmark copyWith({bool? isActive}) {
    return Bookmark(
      id: id,
      userId: userId,
      questionId: questionId,
      subjectId: subjectId,
      topicId: topicId,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'subject_id': subjectId,
      'topic_id': topicId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      subjectId: json['subject_id'] as String,
      topicId: json['topic_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questionId,
        subjectId,
        topicId,
        createdAt,
        isActive,
      ];
}
