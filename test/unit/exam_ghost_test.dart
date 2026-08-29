import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exam_ghost/domain/services/exam_ghost_comparator.dart';

void main() {
  group('ExamGhostComparator Tests', () {
    test('detects improved score and speed as New Personal Best', () {
      final comp = ExamGhostComparator.compare(
        currentScore: 8,
        currentDurationSeconds: 100,
        previousBestScore: 6,
        previousBestDurationSeconds: 150,
      );

      expect(comp.scoreDelta, 2);
      expect(comp.speedDeltaSeconds, 50);
      expect(comp.improvedScore, isTrue);
      expect(comp.improvedSpeed, isTrue);
      expect(comp.isNewPersonalBest, isTrue);
      expect(comp.headline, contains('New Personal Best'));
    });

    test(
      'detects equal score with faster time as Speed Improvement Personal Best',
      () {
        final comp = ExamGhostComparator.compare(
          currentScore: 7,
          currentDurationSeconds: 90,
          previousBestScore: 7,
          previousBestDurationSeconds: 120,
        );

        expect(comp.scoreDelta, 0);
        expect(comp.speedDeltaSeconds, 30);
        expect(comp.improvedScore, isFalse);
        expect(comp.improvedSpeed, isTrue);
        expect(comp.isNewPersonalBest, isTrue);
        expect(comp.headline, contains('Speed Improvement'));
      },
    );

    test('handles lower score correctly', () {
      final comp = ExamGhostComparator.compare(
        currentScore: 4,
        currentDurationSeconds: 180,
        previousBestScore: 7,
        previousBestDurationSeconds: 120,
      );

      expect(comp.scoreDelta, -3);
      expect(comp.speedDeltaSeconds, -60);
      expect(comp.improvedScore, isFalse);
      expect(comp.improvedSpeed, isFalse);
      expect(comp.isNewPersonalBest, isFalse);
    });
  });
}
