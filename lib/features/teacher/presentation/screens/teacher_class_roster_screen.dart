import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/teacher_portal_providers.dart';
import '../../domain/models/teacher_portal_models.dart';

/// Screen displaying the authorized student roster for a teacher's classroom + subject.
///
/// Features:
/// - Paginated roster list (25 per page with Load More)
/// - Search by student name or school student ID
/// - Key academic indicators: recent accuracy, active mistakes, last activity
/// - Tapping student navigates to Student Academic Summary
/// - Privacy: no phone numbers, tokens, or private credentials displayed
class TeacherClassRosterScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final String subjectId;
  final String? classroomName;
  final String? subjectName;

  const TeacherClassRosterScreen({
    super.key,
    required this.classroomId,
    required this.subjectId,
    this.classroomName,
    this.subjectName,
  });

  @override
  ConsumerState<TeacherClassRosterScreen> createState() =>
      _TeacherClassRosterScreenState();
}

class _TeacherClassRosterScreenState
    extends ConsumerState<TeacherClassRosterScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoadingMore = false;

  ({String classroomId, String subjectId}) get _params => (
        classroomId: widget.classroomId,
        subjectId: widget.subjectId,
      );

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(classRosterProvider(_params).notifier).load(
            search: query.trim().isEmpty ? null : query.trim(),
          );
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      await ref.read(classRosterProvider(_params).notifier).loadNext();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(classRosterProvider(_params));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clsName = widget.classroomName ?? 'Class Roster';
    final subjName = widget.subjectName ?? 'Subject';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clsName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              '$subjName — Authorized Roster',
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
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by student name or ID...',
                hintStyle: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Main List Area
          Expanded(
            child: rosterAsync.when(
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
                        'Failed to load roster',
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
                            .read(classRosterProvider(_params).notifier)
                            .load(),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) {
                if (page == null || page.students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: isDark
                                ? AppTheme.darkTextMuted.withValues(alpha: 0.5)
                                : AppTheme.lightTextMuted
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No students match "${_searchController.text}"'
                                : 'No students found in this roster',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Check the spelling or clear the filter.'
                                : 'Active enrollments will appear here once registered.',
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

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: page.students.length + (page.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == page.students.length) {
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
                                      'Load More (${page.students.length} of ${page.totalCount})'),
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

                    final student = page.students[index];
                    return _StudentRosterCard(
                      student: student,
                      isDark: isDark,
                      onTap: () {
                        context.push(
                          '/teacher/class/${widget.classroomId}/${widget.subjectId}/student/${student.userId}',
                          extra: {
                            'studentName': student.displayName,
                            'schoolStudentId': student.schoolStudentId,
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

class _StudentRosterCard extends StatelessWidget {
  final ClassRosterStudent student;
  final bool isDark;
  final VoidCallback onTap;

  const _StudentRosterCard({
    required this.student,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttention = student.hasAttention;
    final avg = student.recentAvgPercentage;
    final mistakes = student.activeMistakeCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasAttention
                    ? AppTheme.danger.withValues(alpha: 0.35)
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
            ),
            child: Row(
              children: [
                // Initials Circle
                CircleAvatar(
                  radius: 22,
                  backgroundColor: hasAttention
                      ? AppTheme.danger.withValues(alpha: 0.15)
                      : AppTheme.brand.withValues(alpha: 0.12),
                  child: Text(
                    _getInitials(student.displayName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasAttention ? AppTheme.danger : AppTheme.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Student ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (student.schoolStudentId != null) ...[
                            Text(
                              student.schoolStudentId!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatLastActivity(student.lastActivityAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Metrics Chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (avg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: avg >= 70
                              ? AppTheme.green.withValues(alpha: 0.12)
                              : (avg >= 50
                                  ? AppTheme.accent.withValues(alpha: 0.15)
                                  : AppTheme.danger.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${avg.toStringAsFixed(0)}% avg',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: avg >= 70
                                ? AppTheme.green
                                : (avg >= 50
                                    ? const Color(0xFFB45309)
                                    : AppTheme.danger),
                          ),
                        ),
                      )
                    else
                      Text(
                        'No attempts',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (mistakes > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 12,
                            color: mistakes >= 3
                                ? AppTheme.danger
                                : AppTheme.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$mistakes mistakes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: mistakes >= 3
                                  ? AppTheme.danger
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppTheme.darkTextMuted.withValues(alpha: 0.6)
                      : AppTheme.lightTextMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatLastActivity(DateTime? dt) {
    if (dt == null) return 'No recent practice';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Active today';
    if (diff.inDays == 1) return 'Active yesterday';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return 'Over a month ago';
  }
}
