import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/study_plan_models.dart';

class WhyThisDialog extends StatelessWidget {
  final StudyPlanSession session;
  final bool isAmharic;

  const WhyThisDialog({
    super.key,
    required this.session,
    this.isAmharic = false,
  });

  static Future<void> show(
    BuildContext context, {
    required StudyPlanSession session,
    bool isAmharic = false,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => WhyThisDialog(session: session, isAmharic: isAmharic),
    );
  }

  FidelBadgeVariant _getBadgeVariant(RecommendationReasonCode code) {
    switch (code) {
      case RecommendationReasonCode.weakTopic:
      case RecommendationReasonCode.lowRecentAccuracy:
        return FidelBadgeVariant.danger;
      case RecommendationReasonCode.mistakeReview:
      case RecommendationReasonCode.reviewOverdue:
        return FidelBadgeVariant.warning;
      case RecommendationReasonCode.newCurriculum:
        return FidelBadgeVariant.primary;
      case RecommendationReasonCode.masteryMaintenance:
        return FidelBadgeVariant.success;
      case RecommendationReasonCode.examApproaching:
      case RecommendationReasonCode.mockDue:
        return FidelBadgeVariant.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeVariant = _getBadgeVariant(session.reasonCode);
    final badgeLabel =
        isAmharic ? session.reasonCode.labelAm : session.reasonCode.labelEn;
    final sessionTitle = isAmharic ? session.titleAm : session.titleEn;
    final reasonDetail =
        isAmharic ? session.reasonDetailAm : session.reasonDetailEn;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E1F2A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Reason Badge, Track Badge & Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FidelBadge(
                        text: badgeLabel,
                        variant: badgeVariant,
                      ),
                      if (session.examVariant != null)
                        FidelBadge(
                          text: session.examVariant ==
                                  ExamVariantCode.naturalScience
                              ? (isAmharic ? 'የተፈጥሮ ሳይንስ' : 'Natural Track')
                              : (session.examVariant ==
                                      ExamVariantCode.socialScience
                                  ? (isAmharic ? 'የማህበራዊ ሳይንስ' : 'Social Track')
                                  : (isAmharic ? 'የጋራ ፈተና' : 'Shared Paper')),
                          variant: FidelBadgeVariant.info,
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                sessionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),

              // Primary Explainability Reason Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.brand,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reasonDetail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metadata Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetaChip(
                      icon: Icons.timer_outlined,
                      label: isAmharic
                          ? '${session.estimatedMinutes} ደቂቃ'
                          : '${session.estimatedMinutes} min',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetaChip(
                      icon: Icons.quiz_outlined,
                      label: isAmharic
                          ? '${session.questionTarget} ጥያቄዎች'
                          : '${session.questionTarget} Questions',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetaChip(
                      icon: Icons.speed_rounded,
                      label: isAmharic
                          ? 'ቅድሚያ ${session.priorityScore.toStringAsFixed(0)}'
                          : 'Priority ${session.priorityScore.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Trust & Explainability Principle Callout
              Text(
                isAmharic
                    ? 'ፊደል ሌርን ይህንን ክፍለ-ጊዜ የመረጠው በራስዎ የልምምድ ውጤት፣ ባልተሸፈኑ ርዕሶች እና በሀገር አቀፍ ፈተናው ቅርበት ላይ ተመስርቶ ነው።'
                    : 'FidelLearn selected this session deterministically from your actual performance history, curriculum gaps, and exam proximity.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isAmharic ? 'ተረድቻለሁ' : 'Got it',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
