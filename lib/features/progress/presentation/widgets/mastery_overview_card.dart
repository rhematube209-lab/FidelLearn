import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/mastery_models.dart';

/// Clean, responsive card displaying learning-target mastery statistics
/// for a subject or overall stream track.
class MasteryOverviewCard extends StatelessWidget {
  final SubjectMasterySummary summary;
  final String subjectNameEn;
  final String subjectNameAm;
  final bool isAmharic;
  final VoidCallback? onReviewTap;

  const MasteryOverviewCard({
    super.key,
    required this.summary,
    required this.subjectNameEn,
    required this.subjectNameAm,
    this.isAmharic = false,
    this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectTitle = isAmharic ? subjectNameAm : subjectNameEn;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3040) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Subject title, Variant badge, Reviews Due chip
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (summary.examVariant != null) ...[
                      const SizedBox(height: 4),
                      FidelBadge(
                        text: summary.examVariant ==
                                ExamVariantCode.naturalScience
                            ? (isAmharic ? 'የተፈጥሮ ሳይንስ' : 'Natural Science')
                            : (summary.examVariant ==
                                    ExamVariantCode.socialScience
                                ? (isAmharic ? 'የማህበራዊ ሳይንስ' : 'Social Science')
                                : (isAmharic ? 'የጋራ ፈተና' : 'Shared Paper')),
                        variant: FidelBadgeVariant.info,
                      ),
                    ],
                  ],
                ),
              ),
              if (summary.reviewsDue > 0)
                InkWell(
                  onTap: onReviewTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alarm_on_rounded,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAmharic
                              ? '${summary.reviewsDue} ክለሳ'
                              : '${summary.reviewsDue} Due',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-Pillar Mastery Grid
          Row(
            children: [
              _buildPillar(
                context,
                label: isAmharic ? 'የተካኑበት' : 'Mastered',
                count: summary.masteredTargets,
                color: AppTheme.green,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(width: 8),
              _buildPillar(
                context,
                label: isAmharic ? 'እየተሻሻለ' : 'Improving',
                count: summary.improvingTargets,
                color: AppTheme.info,
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 8),
              _buildPillar(
                context,
                label: isAmharic ? 'ክለሳ የሚሻ' : 'At Risk',
                count: summary.atRiskTargets,
                color: AppTheme.danger,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 8),
              _buildPillar(
                context,
                label: isAmharic ? 'አዲስ' : 'New',
                count: summary.newTargets,
                color: Colors.grey,
                icon: Icons.circle_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillar(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
