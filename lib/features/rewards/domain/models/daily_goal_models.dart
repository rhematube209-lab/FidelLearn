import 'package:equatable/equatable.dart';

class DailyGoal extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final int targetQuestions;
  final int completedQuestions;
  final double targetAccuracyPercentage;
  final double currentAccuracyPercentage;
  final bool isCompleted;
  final int rewardCoins;
  final bool isRewardClaimed;

  const DailyGoal({
    required this.id,
    required this.userId,
    required this.date,
    this.targetQuestions = 10,
    this.completedQuestions = 0,
    this.targetAccuracyPercentage = 70.0,
    this.currentAccuracyPercentage = 0.0,
    this.isCompleted = false,
    this.rewardCoins = 25,
    this.isRewardClaimed = false,
  });

  DailyGoal copyWith({
    int? completedQuestions,
    double? currentAccuracyPercentage,
    bool? isCompleted,
    bool? isRewardClaimed,
  }) {
    final newCompleted = completedQuestions ?? this.completedQuestions;
    final newAcc = currentAccuracyPercentage ?? this.currentAccuracyPercentage;
    final completed =
        newCompleted >= targetQuestions && newAcc >= targetAccuracyPercentage;

    return DailyGoal(
      id: id,
      userId: userId,
      date: date,
      targetQuestions: targetQuestions,
      completedQuestions: newCompleted,
      targetAccuracyPercentage: targetAccuracyPercentage,
      currentAccuracyPercentage: newAcc,
      isCompleted: isCompleted ?? completed,
      rewardCoins: rewardCoins,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  double get progressFraction =>
      (completedQuestions / targetQuestions).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
    id,
    userId,
    date,
    targetQuestions,
    completedQuestions,
    targetAccuracyPercentage,
    currentAccuracyPercentage,
    isCompleted,
    rewardCoins,
    isRewardClaimed,
  ];
}
