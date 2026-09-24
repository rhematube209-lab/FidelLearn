import '../models/study_plan_models.dart';

abstract class StudyPlanRepository {
  /// Fetches the study plan for a user on a given date (defaults to today).
  Future<StudyPlan?> getStudyPlan(String userId, {DateTime? date});

  /// Watches the study plan for a user on a given date reactively.
  Stream<StudyPlan?> watchStudyPlan(String userId, {DateTime? date});

  /// Saves or updates a full study plan with its sessions.
  Future<void> saveStudyPlan(StudyPlan plan);

  /// Updates status and metrics for a specific session within a plan.
  Future<void> updateSessionStatus({
    required String sessionId,
    required SessionCompletionStatus status,
    DateTime? completedAt,
    int? timeSpentSeconds,
    double? scorePercentage,
  });

  /// Fetches student's planner preferences.
  Future<PlannerSettings> getPlannerSettings(String userId);

  /// Persists student's planner preferences.
  Future<void> savePlannerSettings(String userId, PlannerSettings settings);
}
