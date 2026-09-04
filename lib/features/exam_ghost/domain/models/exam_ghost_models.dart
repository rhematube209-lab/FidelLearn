import 'package:equatable/equatable.dart';

class ExamGhostComparison extends Equatable {
  final int currentScore;
  final int previousBestScore;
  final int scoreDelta; // current - previous
  final int currentDurationSeconds;
  final int previousBestDurationSeconds;
  final int speedDeltaSeconds; // previous - current (positive means faster)
  final bool improvedScore;
  final bool improvedSpeed;
  final bool isNewPersonalBest;
  final String headline;

  const ExamGhostComparison({
    required this.currentScore,
    required this.previousBestScore,
    required this.scoreDelta,
    required this.currentDurationSeconds,
    required this.previousBestDurationSeconds,
    required this.speedDeltaSeconds,
    required this.improvedScore,
    required this.improvedSpeed,
    required this.isNewPersonalBest,
    required this.headline,
  });

  @override
  List<Object?> get props => [
        currentScore,
        previousBestScore,
        scoreDelta,
        currentDurationSeconds,
        previousBestDurationSeconds,
        speedDeltaSeconds,
        improvedScore,
        improvedSpeed,
        isNewPersonalBest,
        headline,
      ];
}

class ExamGhostRecord extends Equatable {
  final String id;
  final String userId;
  final String examId;
  final int bestScore;
  final int bestDurationSeconds;
  final String bestAttemptId;
  final int totalAttempts;
  final DateTime updatedAt;

  const ExamGhostRecord({
    required this.id,
    required this.userId,
    required this.examId,
    required this.bestScore,
    required this.bestDurationSeconds,
    required this.bestAttemptId,
    required this.totalAttempts,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        examId,
        bestScore,
        bestDurationSeconds,
        bestAttemptId,
        totalAttempts,
        updatedAt,
      ];
}
