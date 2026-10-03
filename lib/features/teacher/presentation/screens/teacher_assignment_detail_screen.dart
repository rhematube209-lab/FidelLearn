import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignment_providers.dart';

class TeacherAssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const TeacherAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<TeacherAssignmentDetailScreen> createState() =>
      _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState
    extends ConsumerState<TeacherAssignmentDetailScreen> {
  bool _isActionInProgress = false;

  Future<void> _closeAssignment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Assignment?'),
        content: const Text(
          'Closing will prevent students from starting or submitting work (unless late submissions are allowed). Historical results remain preserved.',
        ),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Close Assignment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final repo = ref.read(teacherAssignmentRepositoryProvider);
      await repo.closeAssignment(widget.assignmentId);
      ref.invalidate(assignmentProgressProvider(widget.assignmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment closed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to close assignment: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _archiveAssignment() async {
    setState(() => _isActionInProgress = true);
    try {
      final repo = ref.read(teacherAssignmentRepositoryProvider);
      await repo.archiveAssignment(widget.assignmentId);
      ref.invalidate(assignmentProgressProvider(widget.assignmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment archived.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to archive assignment: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressAsync =
        ref.watch(assignmentProgressProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Assignment Progress',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.refresh(assignmentProgressProvider(widget.assignmentId)),
          ),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.danger, size: 48),
                const SizedBox(height: 12),
                Text('Failed to load progress: $e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref
                      .refresh(assignmentProgressProvider(widget.assignmentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          final assign = summary.assignment;

          return CustomScrollView(
            slivers: [
              // Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brand.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                assign.assignmentType.labelEn,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brand,
                                ),
                              ),
                            ),
                            _StatusBadge(status: assign.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          assign.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (assign.instructions != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            assign.instructions!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _MetaItem(
                              icon: Icons.school_outlined,
                              label: assign.classroomName ?? 'Classroom',
                              isDark: isDark,
                            ),
                            _MetaItem(
                              icon: Icons.menu_book_outlined,
                              label: assign.subjectId
                                  .replaceAll('_g12', '')
                                  .toUpperCase(),
                              isDark: isDark,
                            ),
                            _MetaItem(
                              icon: Icons.help_outline_rounded,
                              label: '${assign.totalQuestions} questions',
                              isDark: isDark,
                            ),
                            if (assign.dueAt != null)
                              _MetaItem(
                                icon: Icons.calendar_today_rounded,
                                label:
                                    'Due ${assign.dueAt!.month}/${assign.dueAt!.day}/${assign.dueAt!.year}',
                                isDark: isDark,
                                isWarning: assign.isOverdue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action row
                        Row(
                          children: [
                            if (assign.status ==
                                AssignmentStatus.published) ...[
                              OutlinedButton.icon(
                                onPressed: _isActionInProgress
                                    ? null
                                    : _closeAssignment,
                                icon: const Icon(Icons.lock_clock_rounded,
                                    size: 16),
                                label: const Text('Close Assignment'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                ),
                              ),
                            ],
                            if (assign.status == AssignmentStatus.closed) ...[
                              OutlinedButton.icon(
                                onPressed: _isActionInProgress
                                    ? null
                                    : _archiveAssignment,
                                icon: const Icon(Icons.archive_outlined,
                                    size: 16),
                                label: const Text('Archive'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // KPI Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Assigned',
                          value: '${summary.totalAssigned}',
                          icon: Icons.people_outline_rounded,
                          color: AppTheme.brand,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Submitted',
                          value: '${summary.submittedCount}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.green,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'In Progress',
                          value: '${summary.inProgressCount}',
                          icon: Icons.pending_outlined,
                          color: AppTheme.accent,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Not Started',
                          value: '${summary.notStartedCount}',
                          icon: Icons.hourglass_empty_rounded,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Roster Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Submissions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Completion: ${summary.completionPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // Roster Items
              if (summary.recipients.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text(
                            'No recipients recorded for this assignment.')),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = summary.recipients[index];
                        return _RecipientTile(recipient: r, isDark: isDark);
                      },
                      childCount: summary.recipients.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isWarning;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? AppTheme.danger
        : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final AssignmentRecipient recipient;
  final bool isDark;

  const _RecipientTile({
    required this.recipient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
            child: Text(
              recipient.studentName?.isNotEmpty == true
                  ? recipient.studentName![0].toUpperCase()
                  : 'S',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.brand,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.studentName ?? 'Student',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  recipient.schoolStudentId ??
                      recipient.studentUserId.substring(0, 8),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          if (recipient.isSubmitted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  recipient.percentage != null
                      ? '${recipient.percentage!.toStringAsFixed(0)}%'
                      : '${recipient.score ?? 0} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.green,
                  ),
                ),
                Text(
                  recipient.status.labelEn,
                  style: TextStyle(
                    fontSize: 11,
                    color: recipient.status == AssignmentRecipientStatus.late
                        ? AppTheme.danger
                        : AppTheme.green,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                recipient.status.labelEn,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AssignmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case AssignmentStatus.published:
        bg = AppTheme.green.withValues(alpha: 0.15);
        fg = AppTheme.green;
        break;
      case AssignmentStatus.draft:
        bg = AppTheme.accent.withValues(alpha: 0.15);
        fg = AppTheme.accent;
        break;
      case AssignmentStatus.closed:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        break;
      case AssignmentStatus.archived:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.blueGrey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.labelEn,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
