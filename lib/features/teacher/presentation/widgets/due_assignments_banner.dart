import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/assignment_providers.dart';

/// Actionable banner showing how many teacher assignments are pending or due.
class DueAssignmentsBanner extends ConsumerWidget {
  final bool isAmharic;

  const DueAssignmentsBanner({
    super.key,
    this.isAmharic = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(null));

    return assignmentsAsync.when(
      data: (assignments) {
        final pending = assignments.where((a) => !a.isCompleted).toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        final count = pending.length;
        final hasOverdue = pending.any((a) => a.isOverdue);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final title = isAmharic
            ? '$count የአስተማሪ የተግባር ስራዎች ደርሰዋል'
            : '$count Teacher Assignment${count > 1 ? "s" : ""} Due';
        final subtitle = hasOverdue
            ? (isAmharic
                ? 'አንዳንድ ስራዎች ጊዜያቸው አልፏል — አሁኑኑ ያጠናቅቁ'
                : 'Action required: Some assignments are past due')
            : (isAmharic
                ? 'የተሰጡዎትን የክፍል ስራዎች አሁን ይጀምሩ'
                : 'Complete assigned practice from your teachers');
        final buttonLabel = isAmharic ? 'ስራዎችን ይመልከቱ' : 'View Inbox';

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? (hasOverdue
                      ? [const Color(0xFF2E1515), const Color(0xFF1E1414)]
                      : [const Color(0xFF1E2433), const Color(0xFF151924)])
                  : (hasOverdue
                      ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)]),
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: hasOverdue
                  ? AppTheme.danger.withValues(alpha: 0.4)
                  : AppTheme.brand.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (hasOverdue ? AppTheme.danger : AppTheme.brand)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasOverdue
                      ? Icons.notification_important_rounded
                      : Icons.assignment_turned_in_rounded,
                  color: hasOverdue ? AppTheme.danger : AppTheme.brand,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasOverdue
                            ? AppTheme.danger
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => context.push('/assignments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasOverdue ? AppTheme.danger : AppTheme.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
