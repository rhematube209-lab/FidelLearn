import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/rewards/domain/services/daily_streak_service.dart';

void main() {
  group('DailyStreakService Tests', () {
    final now = DateTime(2026, 8, 21, 14, 0);

    test('returns 0 streak when activity dates list is empty', () {
      final result = DailyStreakService.calculateStreak(
        activityDates: [],
        referenceDate: now,
      );

      expect(result.currentStreakDays, 0);
      expect(result.isStreakActiveToday, isFalse);
      expect(result.streakFreezesUsed, 0);
      expect(result.earnedBadges, isEmpty);
    });

    test('computes active consecutive streak correctly', () {
      final days = [
        DateTime(2026, 8, 21), // Today
        DateTime(2026, 8, 20), // Yesterday
        DateTime(2026, 8, 19), // 2 days ago
        DateTime(2026, 8, 18), // 3 days ago
      ];

      final result = DailyStreakService.calculateStreak(
        activityDates: days,
        referenceDate: now,
      );

      expect(result.currentStreakDays, 4);
      expect(result.isStreakActiveToday, isTrue);
      expect(result.isAtRisk, isFalse);
      expect(result.earnedBadges, contains('Seedling Scholar (3 Days)'));
    });

    test('protects streak using 1 available streak freeze on missed day', () {
      final daysWithGap = [
        DateTime(2026, 8, 21), // Today
        // Missed Aug 20
        DateTime(2026, 8, 19), // 2 days ago
        DateTime(2026, 8, 18), // 3 days ago
      ];

      final result = DailyStreakService.calculateStreak(
        activityDates: daysWithGap,
        referenceDate: now,
        availableStreakFreezes: 1,
      );

      expect(result.streakFreezesUsed, 1);
      expect(result.currentStreakDays, 4); // gap bridged
    });

    test('breaks streak if gap exceeds 1 day or no freezes available', () {
      final brokenDays = [
        DateTime(2026, 8, 21), // Today
        // Missed Aug 20 and Aug 19
        DateTime(2026, 8, 18),
      ];

      final result = DailyStreakService.calculateStreak(
        activityDates: brokenDays,
        referenceDate: now,
        availableStreakFreezes: 0,
      );

      expect(result.currentStreakDays, 1); // only today
      expect(result.streakFreezesUsed, 0);
    });

    test('flags streak as at-risk if studied yesterday but not today yet', () {
      final yesterdayOnly = [
        DateTime(2026, 8, 20),
        DateTime(2026, 8, 19),
      ];

      final result = DailyStreakService.calculateStreak(
        activityDates: yesterdayOnly,
        referenceDate: now,
      );

      expect(result.currentStreakDays, 2);
      expect(result.isStreakActiveToday, isFalse);
      expect(result.isAtRisk, isTrue);
    });
  });
}
