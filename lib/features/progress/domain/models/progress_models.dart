import 'package:equatable/equatable.dart';

class WeakTopicRecommendation extends Equatable {
  final String topicId;
  final String topicTitleEn;
  final String subjectId;
  final double accuracyPercentage;
  final int totalAttempts;
  final int mistakeCount;
  final String urgencyLevel; // 'high' | 'medium' | 'low'
  final String recommendationReason;

  const WeakTopicRecommendation({
    required this.topicId,
    required this.topicTitleEn,
    required this.subjectId,
    required this.accuracyPercentage,
    required this.totalAttempts,
    required this.mistakeCount,
    required this.urgencyLevel,
    required this.recommendationReason,
  });

  @override
  List<Object?> get props => [
    topicId,
    topicTitleEn,
    subjectId,
    accuracyPercentage,
    totalAttempts,
    mistakeCount,
    urgencyLevel,
    recommendationReason,
  ];
}

class ProgressSummary extends Equatable {
  final int examsCompleted;
  final int questionsAnswered;
  final double averageScore;
  final int totalStudyTimeMinutes;
  final int currentStreakDays;
  final int bestStreakDays;
  final double readinessScore; // 0.0 - 100.0
  final List<WeakTopicRecommendation> weakTopics;

  const ProgressSummary({
    required this.examsCompleted,
    required this.questionsAnswered,
    required this.averageScore,
    required this.totalStudyTimeMinutes,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.readinessScore,
    required this.weakTopics,
  });

  @override
  List<Object?> get props => [
    examsCompleted,
    questionsAnswered,
    averageScore,
    totalStudyTimeMinutes,
    currentStreakDays,
    bestStreakDays,
    readinessScore,
    weakTopics,
  ];
}
