import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/teacher_portal_providers.dart';
import '../../domain/models/teacher_portal_models.dart';

/// Screen listing students in an authorized classroom + subject who need academic intervention.
///
/// Features:
/// - Severity filter tabs: All, Immediate Support (High), Needs Attention (Medium), Monitor (Low)
/// - Explainable reason codes: transparently clarifies WHY student is flagged
/// - Derived teacher recommendation action for each student
/// - Educational framing: strictly constructive language, no shaming or competitive ranking
/// - Direct navigation to Student Academic Summary
class TeacherAttentionScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final String subjectId;
  final String? classroomName;
  final String? subjectName;

  const TeacherAttentionScreen({
    super.key,
    required this.classroomId,
    required this.subjectId,
    this.classroomName,
    this.subjectName,
  });

  @override
  ConsumerState<TeacherAttentionScreen> createState() =>
      _TeacherAttentionScreenState();
}

class _TeacherAttentionScreenState
    extends ConsumerState<TeacherAttentionScreen> {
  AttentionSeverity? _selectedSeverityFilter;
  bool _isLoadingMore = false;

  ({String classroomId, String subjectId}) get _params => (
        classroomId: widget.classroomId,
        subjectId: widget.subjectId,
      );

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      await ref.read(attentionStudentsProvider(_params).notifier).loadNext();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attentionAsync = ref.watch(attentionStudentsProvider(_params));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clsName = widget.classroomName ?? 'Classroom';
    final subjName = widget.subjectName ?? 'Subject';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students Needing Attention',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              '$clsName • $subjName',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Flagged',
                    isSelected: _selectedSeverityFilter == null,
                    onSelected: () =>
                        setState(() => _selectedSeverityFilter = null),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Immediate Support',
                    color: AppTheme.danger,
                    isSelected:
                        _selectedSeverityFilter == AttentionSeverity.high,
                    onSelected: () => setState(
                        () => _selectedSeverityFilter = AttentionSeverity.high),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Needs Attention',
                    color: AppTheme.accent,
                    isSelected:
                        _selectedSeverityFilter == AttentionSeverity.medium,
                    onSelected: () => setState(() =>
                        _selectedSeverityFilter = AttentionSeverity.medium),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Monitor',
                    color: AppTheme.info,
                    isSelected:
                        _selectedSeverityFilter == AttentionSeverity.low,
                    onSelected: () => setState(
                        () => _selectedSeverityFilter = AttentionSeverity.low),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main Content
          Expanded(
            child: attentionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.danger, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load attention list',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        onPressed: () => ref
                            .read(attentionStudentsProvider(_params).notifier)
                            .load(),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) {
                if (page == null || page.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.green.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 48,
                              color: AppTheme.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Students Flagged',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All students in this class currently meet baseline practice accuracy and mistake thresholds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredItems = _selectedSeverityFilter == null
                    ? page.items
                    : page.items
                        .where((i) => i.severity == _selectedSeverityFilter)
                        .toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No students match the selected severity filter.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredItems.length + (page.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredItems.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoadingMore
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : OutlinedButton.icon(
                                  icon: const Icon(Icons.arrow_downward_rounded,
                                      size: 16),
                                  label: Text(
                                      'Load More (${page.items.length} of ${page.totalCount})'),
                                  onPressed: _loadMore,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.brand,
                                    side: BorderSide(
                                      color: isDark
                                          ? AppTheme.darkBorder
                                          : AppTheme.lightBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }

                    final item = filteredItems[index];
                    return _AttentionItemCard(
                      item: item,
                      isDark: isDark,
                      onTap: () {
                        context.push(
                          '/teacher/class/${widget.classroomId}/${widget.subjectId}/student/${item.studentId}',
                          extra: {
                            'studentName': item.studentName,
                            'schoolStudentId': item.schoolStudentId,
                            'subjectName': subjName,
                            'classroomName': clsName,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onSelected;
  final bool isDark;

  const _FilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.brand;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? chipColor
                : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          ),
        ),
      ),
    );
  }
}

class _AttentionItemCard extends StatelessWidget {
  final StudentAttentionItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _AttentionItemCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(item.severity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Severity Badge + Student Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getSeverityIcon(item.severity),
                                size: 13, color: color),
                            const SizedBox(width: 4),
                            Text(
                              item.severity.displayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (item.schoolStudentId != null)
                        Text(
                          item.schoolStudentId!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Student Name
                  Text(
                    item.studentName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Transparent Reasons (Why the student is flagged)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBg.withValues(alpha: 0.6)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.reasonExplanations.map((reason) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Recommended Action & Action Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.recommendedAction,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'View Summary',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brand,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppTheme.brand,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(AttentionSeverity severity) {
    switch (severity) {
      case AttentionSeverity.high:
        return AppTheme.danger;
      case AttentionSeverity.medium:
        return AppTheme.accent;
      case AttentionSeverity.low:
        return AppTheme.info;
    }
  }

  IconData _getSeverityIcon(AttentionSeverity severity) {
    switch (severity) {
      case AttentionSeverity.high:
        return Icons.warning_rounded;
      case AttentionSeverity.medium:
        return Icons.info_outline_rounded;
      case AttentionSeverity.low:
        return Icons.remove_red_eye_outlined;
    }
  }
}
