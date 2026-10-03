import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignment_providers.dart';

class StudentAssignmentInboxScreen extends ConsumerStatefulWidget {
  const StudentAssignmentInboxScreen({super.key});

  @override
  ConsumerState<StudentAssignmentInboxScreen> createState() =>
      _StudentAssignmentInboxScreenState();
}

class _StudentAssignmentInboxScreenState
    extends ConsumerState<StudentAssignmentInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'My Assignments',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brand,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          indicatorColor: AppTheme.brand,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Due & Active'),
            Tab(text: 'Past Due'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StudentAssignmentList(
            filter: (a) => !a.isCompleted && !a.isOverdue,
            emptyMessage: 'No pending assignments.\nYou are all caught up! 🎉',
            isDark: isDark,
          ),
          _StudentAssignmentList(
            filter: (a) => !a.isCompleted && a.isOverdue,
            emptyMessage: 'No past due assignments.',
            isDark: isDark,
          ),
          _StudentAssignmentList(
            filter: (a) => a.isCompleted,
            emptyMessage: 'No completed assignments yet.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StudentAssignmentList extends ConsumerWidget {
  final bool Function(StudentAssignment) filter;
  final String emptyMessage;
  final bool isDark;

  const _StudentAssignmentList({
    required this.filter,
    required this.emptyMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(null));

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.danger, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load assignments: $e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.refresh(studentAssignmentsProvider(null)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allAssignments) {
        final filtered = allAssignments.where(filter).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 48,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
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

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(studentAssignmentsProvider(null)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final a = filtered[idx];
              return _StudentAssignmentCard(assignment: a, isDark: isDark);
            },
          ),
        );
      },
    );
  }
}

class _StudentAssignmentCard extends StatelessWidget {
  final StudentAssignment assignment;
  final bool isDark;

  const _StudentAssignmentCard({
    required this.assignment,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = assignment.isCompleted;
    final isOverdue = assignment.isOverdue;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/assignment/${assignment.assignmentId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      assignment.subjectId.replaceAll('_g12', '').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                  if (isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        assignment.studentStatus ==
                                AssignmentRecipientStatus.late
                            ? 'Submitted (Late)'
                            : 'Completed',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ] else if (isOverdue) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Past Due',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        assignment.studentStatus.labelEn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brand,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                assignment.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // Teacher & Classroom
              Text(
                'Assigned by ${assignment.teacherName} • ${assignment.classroomName}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 14,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${assignment.totalQuestions} questions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                    ),
                  ),
                  if (assignment.isTimed) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${assignment.timeLimitMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isCompleted && assignment.percentage != null) ...[
                    Text(
                      'Score: ${assignment.percentage!.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.green,
                      ),
                    ),
                  ] else if (assignment.dueAt != null) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isOverdue
                          ? AppTheme.danger
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due ${assignment.dueAt!.month}/${assignment.dueAt!.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: isOverdue
                            ? AppTheme.danger
                            : (isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
