import 'package:equatable/equatable.dart';

class DailyStreakResult extends Equatable {
  final int currentStreakDays;
  final int bestStreakDays;
  final int streakFreezesUsed;
  final bool isStreakActiveToday;
  final bool isAtRisk;
  final List<String> earnedBadges;

  const DailyStreakResult({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.streakFreezesUsed,
    required this.isStreakActiveToday,
    required this.isAtRisk,
    required this.earnedBadges,
  });

  @override
  List<Object?> get props => [
    currentStreakDays,
    bestStreakDays,
    streakFreezesUsed,
    isStreakActiveToday,
    isAtRisk,
    earnedBadges,
  ];
}

class DailyStreakService {
  DailyStreakService._();

  /// Calculates current streak and preserves streak if a streak freeze is available
  static DailyStreakResult calculateStreak({
    required List<DateTime> activityDates,
    DateTime? referenceDate,
    int availableStreakFreezes = 0,
  }) {
    if (activityDates.isEmpty) {
      return const DailyStreakResult(
        currentStreakDays: 0,
        bestStreakDays: 0,
        streakFreezesUsed: 0,
        isStreakActiveToday: false,
        isAtRisk: false,
        earnedBadges: [],
      );
    }

    final ref = referenceDate ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Normalize and sort unique study days descending
    final uniqueDays = activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final isStudiedToday = uniqueDays.contains(today);
    final isStudiedYesterday = uniqueDays.contains(yesterday);

    int currentStreak = 0;
    int freezesUsed = 0;
    int remainingFreezes = availableStreakFreezes;

    DateTime expectedDay = isStudiedToday ? today : yesterday;
    bool atRisk = !isStudiedToday && isStudiedYesterday;

    for (final day in uniqueDays) {
      if (day.isAfter(expectedDay)) {
        continue;
      }

      final diffDays = expectedDay.difference(day).inDays;

      if (diffDays == 0) {
        currentStreak++;
        expectedDay = expectedDay.subtract(const Duration(days: 1));
      } else if (diffDays == 1 && remainingFreezes > 0) {
        // Missed 1 day, consume 1 streak freeze to bridge the gap
        freezesUsed++;
        remainingFreezes--;
        currentStreak += 2; // the missed day + the current day
        expectedDay = day.subtract(const Duration(days: 1));
      } else {
        // Streak broken
        break;
      }
    }

    final badges = <String>[];
    if (currentStreak >= 3) badges.add('Seedling Scholar (3 Days)');
    if (currentStreak >= 7) badges.add('Week Warrior (7 Days)');
    if (currentStreak >= 30) badges.add('National Top Ranker (30 Days)');

    return DailyStreakResult(
      currentStreakDays: currentStreak,
      bestStreakDays: currentStreak,
      streakFreezesUsed: freezesUsed,
      isStreakActiveToday: isStudiedToday,
      isAtRisk: atRisk,
      earnedBadges: badges,
    );
  }
}
