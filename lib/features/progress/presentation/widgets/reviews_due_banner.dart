import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Actionable banner showing how many spaced reviews are currently due.
class ReviewsDueBanner extends StatelessWidget {
  final int dueCount;
  final bool isAmharic;
  final VoidCallback onReviewNow;

  const ReviewsDueBanner({
    super.key,
    required this.dueCount,
    this.isAmharic = false,
    required this.onReviewNow,
  });

  @override
  Widget build(BuildContext context) {
    if (dueCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isAmharic
        ? '$dueCount የተቀጠሩ የክለሳ ጥያቄዎች ደርሰዋል'
        : '$dueCount Spaced Reviews Due Today';
    final subtitle = isAmharic
        ? 'የተማሩትን ይዘት ሳያረሱ ለማጠናከር ፈጣን ክለሳ ያድርጉ'
        : 'Review now to keep retrievability high before exam day';
    final buttonLabel = isAmharic ? 'አሁን ከልስ' : 'Review Now';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2B2117), const Color(0xFF1E1A17)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alarm_on_rounded,
              color: AppTheme.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amber[200] : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onReviewNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
