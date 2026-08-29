import '../models/exam_ghost_models.dart';

class ExamGhostComparator {
  ExamGhostComparator._();

  /// Compares a newly completed attempt with the recorded personal best Ghost
  static ExamGhostComparison compare({
    required int currentScore,
    required int currentDurationSeconds,
    required int previousBestScore,
    required int previousBestDurationSeconds,
  }) {
    final scoreDelta = currentScore - previousBestScore;
    final speedDelta =
        previousBestDurationSeconds -
        currentDurationSeconds; // positive = faster

    final improvedScore = scoreDelta > 0;
    final improvedSpeed = speedDelta > 0;

    // A new personal best is achieved if score is higher, or if score is equal and duration is faster
    final isNewPersonalBest =
        improvedScore || (scoreDelta == 0 && improvedSpeed);

    String headline;
    if (improvedScore && improvedSpeed) {
      headline =
          'New Personal Best! Higher score (+$scoreDelta pts) & ${speedDelta}s faster!';
    } else if (improvedScore) {
      headline =
          'Score Improvement! Scored +$scoreDelta more than your previous best!';
    } else if (improvedSpeed && scoreDelta == 0) {
      headline =
          'Speed Improvement! Matched your score and finished ${speedDelta}s faster!';
    } else if (scoreDelta == 0 && speedDelta == 0) {
      headline = 'Tied with your Personal Best Ghost!';
    } else {
      headline =
          'Keep pushing! Ghost benchmark was $previousBestScore in ${previousBestDurationSeconds}s.';
    }

    return ExamGhostComparison(
      currentScore: currentScore,
      previousBestScore: previousBestScore,
      scoreDelta: scoreDelta,
      currentDurationSeconds: currentDurationSeconds,
      previousBestDurationSeconds: previousBestDurationSeconds,
      speedDeltaSeconds: speedDelta,
      improvedScore: improvedScore,
      improvedSpeed: improvedSpeed,
      isNewPersonalBest: isNewPersonalBest,
      headline: headline,
    );
  }
}
