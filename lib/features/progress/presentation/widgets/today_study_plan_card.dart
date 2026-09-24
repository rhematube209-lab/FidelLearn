import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../domain/models/study_plan_models.dart';
import 'why_this_dialog.dart';

class TodayStudyPlanCard extends StatelessWidget {
  final StudyPlan? studyPlan;
  final bool isLoading;
  final bool isAmharic;
  final void Function(StudyPlanSession session) onStartSession;
  final void Function(StudyPlanSession session)? onSkipSession;
  final VoidCallback? onRefreshPlan;

  const TodayStudyPlanCard({
    super.key,
    required this.studyPlan,
    this.isLoading = false,
    this.isAmharic = false,
    required this.onStartSession,
    this.onSkipSession,
    this.onRefreshPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return FidelCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 2.5,
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAmharic
                      ? 'የዛሬውን ግላዊ የጥናት እቅድ በማዘጋጀት ላይ...'
                      : 'Personalizing today\'s study plan...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final plan = studyPlan;
    if (plan == null || plan.sessions.isEmpty) {
      return FidelCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined,
                    color: AppTheme.brand, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmharic ? 'የዛሬ የጥናት እቅድ' : 'Today\'s Study Plan',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAmharic
                          ? 'የመጀመሪያ ልምምድዎን ሲያጠናቅቁ ግላዊ እቅድ በራስ-ሰር ይዘጋጃል።'
                          : 'Complete your first practice session to generate your adaptive plan.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefreshPlan != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: onRefreshPlan,
                ),
            ],
          ),
        ),
      );
    }

    final completedMins = plan.completedMinutes;
    final targetMins = plan.targetMinutes;
    final progressFraction =
        targetMins > 0 ? (completedMins / targetMins).clamp(0.0, 1.0) : 0.0;
    final isAllDone = plan.isFullyCompleted;

    return FidelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title, Daily Goal Pill & Refresh
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppTheme.brand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmharic ? 'የዛሬ የጥናት እቅድ' : 'Today\'s Study Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAmharic
                          ? 'የቀኑ ግብ፦ $completedMins / $targetMins ደቂቃ (${plan.completedSessionsCount}/${plan.sessions.length} ክፍለ-ጊዜ)'
                          : 'Daily Goal: $completedMins / $targetMins min (${plan.completedSessionsCount}/${plan.sessions.length} done)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefreshPlan != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: isAmharic ? 'እቅድ አድስ' : 'Refresh plan',
                  onPressed: onRefreshPlan,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFraction,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? AppTheme.green : AppTheme.brand,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // All Completed Celebration Banner
          if (isAllDone)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAmharic
                          ? 'እንኳን ደስ አለዎት! የዛሬውን ሙሉ የጥናት እቅድ አጠናቀዋል።'
                          : 'Great job! You\'ve completed today\'s personalized study plan.',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // List of Scheduled Sessions
          ...plan.sessions.map((session) => _buildSessionTile(
                context: context,
                session: session,
                isDark: isDark,
              )),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    required BuildContext context,
    required StudyPlanSession session,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final isCompleted = session.status == SessionCompletionStatus.completed;
    final isSkipped = session.status == SessionCompletionStatus.skipped;

    final badgeVariant = _getBadgeVariant(session.reasonCode);
    final badgeLabel =
        isAmharic ? session.reasonCode.labelAm : session.reasonCode.labelEn;
    final title = isAmharic ? session.titleAm : session.titleEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppTheme.green.withOpacity(0.3)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Reason Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAmharic
                          ? '${session.questionTarget} ጥያቄዎች • ${session.estimatedMinutes} ደቂቃ'
                          : '${session.questionTarget} Questions • ${session.estimatedMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FidelBadge(
                text: badgeLabel,
                variant: badgeVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Action Row: "Why this?" Link + Launch Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "Why this?" Button
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => WhyThisDialog.show(
                  context,
                  session: session,
                  isAmharic: isAmharic,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 14, color: AppTheme.brand),
                      SizedBox(width: 4),
                      Text(
                        'Why this?',
                        style: TextStyle(
                          color: AppTheme.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action button: Completed vs Start / Continue
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'ተጠናቋል' : 'Completed',
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isSkipped)
                Text(
                  isAmharic ? 'የታለፈ' : 'Skipped',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onSkipSession != null)
                      TextButton(
                        onPressed: () => onSkipSession!(session),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isAmharic ? 'እለፍ' : 'Skip',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => onStartSession(session),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        session.status == SessionCompletionStatus.inProgress
                            ? (isAmharic ? 'ቀጥል' : 'Continue')
                            : (isAmharic ? 'ጀምር' : 'Start'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  FidelBadgeVariant _getBadgeVariant(RecommendationReasonCode code) {
    switch (code) {
      case RecommendationReasonCode.weakTopic:
      case RecommendationReasonCode.lowRecentAccuracy:
      case RecommendationReasonCode.masteryAtRisk:
      case RecommendationReasonCode.relearningNeeded:
        return FidelBadgeVariant.danger;
      case RecommendationReasonCode.mistakeReview:
      case RecommendationReasonCode.reviewOverdue:
      case RecommendationReasonCode.masteryReviewDue:
        return FidelBadgeVariant.warning;
      case RecommendationReasonCode.newCurriculum:
        return FidelBadgeVariant.primary;
      case RecommendationReasonCode.masteryMaintenance:
      case RecommendationReasonCode.longTermRecall:
        return FidelBadgeVariant.success;
      case RecommendationReasonCode.examApproaching:
      case RecommendationReasonCode.mockDue:
        return FidelBadgeVariant.info;
    }
  }
}
