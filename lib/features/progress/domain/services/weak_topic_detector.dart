import '../../../exams/domain/models/exam_models.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../models/progress_models.dart';

class WeakTopicDetector {
  /// Minimum attempts required in a topic before drawing statistical conclusions
  final int minAttemptsThreshold;

  /// Accuracy threshold below which a topic is flagged as weak
  final double weakAccuracyThreshold;

  const WeakTopicDetector({
    this.minAttemptsThreshold = 3,
    this.weakAccuracyThreshold = 60.0,
  });

  /// Evaluates historical attempts and returns ranked weak topics
  List<WeakTopicRecommendation> detectWeakTopics({
    required List<ExamAttempt> completedAttempts,
    required Map<String, Question> questionMap,
    required Map<String, String> topicTitleMap,
  }) {
    if (completedAttempts.isEmpty) return [];

    // Aggregate stats per topic: [correct, total, mistake, skipped, totalTimeSeconds]
    final Map<String, _TopicStats> statsByTopic = {};

    for (final entry in completedAttempts) {
      for (final respEntry in entry.responses.entries) {
        final qId = respEntry.key;
        final resp = respEntry.value;
        final q = questionMap[qId];
        if (q == null) continue;

        final topicId = q.topicId;
        final stats = statsByTopic.putIfAbsent(
          topicId,
          () => _TopicStats(topicId: topicId, subjectId: q.subjectId),
        );

        stats.totalAttempts++;
        stats.totalTimeSeconds += resp.timeSpentSeconds;

        if (resp.selectedChoiceId == null) {
          stats.skippedCount++;
          stats.mistakeCount++;
        } else if (resp.isCorrect) {
          stats.correctCount++;
        } else {
          stats.mistakeCount++;
        }
      }
    }

    final List<WeakTopicRecommendation> recommendations = [];

    for (final stats in statsByTopic.values) {
      // 1. Guard against insufficient data
      if (stats.totalAttempts < minAttemptsThreshold) {
        continue;
      }

      final accuracy = (stats.correctCount / stats.totalAttempts) * 100.0;

      // 2. Identify weak topics below threshold
      if (accuracy < weakAccuracyThreshold) {
        final urgency = accuracy < 40.0
            ? 'high'
            : (accuracy < 55.0 ? 'medium' : 'low');

        final reason =
            'Accuracy is ${accuracy.toStringAsFixed(0)}% across ${stats.totalAttempts} practice questions with ${stats.mistakeCount} mistakes.';

        recommendations.add(
          WeakTopicRecommendation(
            topicId: stats.topicId,
            topicTitleEn: topicTitleMap[stats.topicId] ?? stats.topicId,
            subjectId: stats.subjectId,
            accuracyPercentage: double.parse(accuracy.toStringAsFixed(1)),
            totalAttempts: stats.totalAttempts,
            mistakeCount: stats.mistakeCount,
            urgencyLevel: urgency,
            recommendationReason: reason,
          ),
        );
      }
    }

    // Sort by lowest accuracy and highest mistake count first
    recommendations.sort((a, b) {
      final comp = a.accuracyPercentage.compareTo(b.accuracyPercentage);
      if (comp != 0) return comp;
      return b.mistakeCount.compareTo(a.mistakeCount);
    });

    return recommendations;
  }

  /// Calculates national exam readiness score (0 - 100)
  static double calculateReadinessScore({
    required int totalExamsCompleted,
    required double averageScorePercentage,
    required int weakTopicCount,
    required int studyStreakDays,
  }) {
    if (totalExamsCompleted == 0) return 0.0;

    // Weight formula:
    // - 50% from average exam score
    // - 25% from volume of exams completed (capped at 20 exams)
    // - 15% from streak consistency (capped at 15 days)
    // - 10% penalty reduction based on remaining weak topics
    final scoreComponent = averageScorePercentage * 0.50;
    final volumeComponent = (totalExamsCompleted.clamp(0, 20) / 20.0) * 25.0;
    final streakComponent = (studyStreakDays.clamp(0, 15) / 15.0) * 15.0;
    final weakPenalty = (weakTopicCount.clamp(0, 5) * 2.0); // max -10 pts

    final readiness =
        scoreComponent + volumeComponent + streakComponent - weakPenalty;
    return double.parse(readiness.clamp(0.0, 100.0).toStringAsFixed(1));
  }
}

class _TopicStats {
  final String topicId;
  final String subjectId;
  int totalAttempts = 0;
  int correctCount = 0;
  int mistakeCount = 0;
  int skippedCount = 0;
  int totalTimeSeconds = 0;

  _TopicStats({required this.topicId, required this.subjectId});
}
