import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignment_providers.dart';
import '../providers/teacher_portal_providers.dart';

class TeacherAssignmentCenterScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentCenterScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentCenterScreen> createState() =>
      _TeacherAssignmentCenterScreenState();
}

class _TeacherAssignmentCenterScreenState
    extends ConsumerState<TeacherAssignmentCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassroomId;

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
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (schoolContext.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final schoolId = schoolContext.activeSchool?.id ?? '';
    final assignedClassesAsync = ref.watch(teacherAssignedClassesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Assignment Center',
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
            tooltip: 'Interventions',
            icon:
                const Icon(Icons.support_agent_rounded, color: AppTheme.brand),
            onPressed: () => context.push('/teacher/interventions'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brand,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          indicatorColor: AppTheme.brand,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Drafts'),
            Tab(text: 'Closed / History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Assignment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/teacher/assignment/new'),
      ),
      body: Column(
        children: [
          // Classroom Filter Strip
          assignedClassesAsync.when(
            data: (classes) {
              if (classes.isEmpty) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppTheme.darkSurface : Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Classes'),
                        selected: _selectedClassroomId == null,
                        onSelected: (val) =>
                            setState(() => _selectedClassroomId = null),
                        selectedColor: AppTheme.brand.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.brand,
                      ),
                      const SizedBox(width: 8),
                      ...classes.map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                  '${c.classroom.name} (${c.subjectName})'),
                              selected: _selectedClassroomId == c.classroom.id,
                              onSelected: (val) {
                                setState(() {
                                  _selectedClassroomId =
                                      val ? c.classroom.id : null;
                                });
                              },
                              selectedColor:
                                  AppTheme.brand.withValues(alpha: 0.15),
                              checkmarkColor: AppTheme.brand,
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: AssignmentStatus.published,
                  emptyMessage:
                      'No active assignments published yet.\nCreate one to assign verified practice.',
                  isDark: isDark,
                ),
                _AssignmentListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: AssignmentStatus.draft,
                  emptyMessage:
                      'No draft assignments.\nStart a draft to prepare work ahead of time.',
                  isDark: isDark,
                ),
                _AssignmentListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: AssignmentStatus.closed,
                  emptyMessage: 'No closed or completed assignments.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentListTab extends ConsumerWidget {
  final String schoolId;
  final String? classroomId;
  final AssignmentStatus status;
  final String emptyMessage;
  final bool isDark;

  const _AssignmentListTab({
    required this.schoolId,
    required this.classroomId,
    required this.status,
    required this.emptyMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      schoolId: schoolId,
      classroomId: classroomId,
      subjectId: null,
      status: status,
    );

    final assignmentsAsync = ref.watch(teacherAssignmentsProvider(params));

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
              Text(
                'Failed to load assignments: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.danger),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.refresh(teacherAssignmentsProvider(params)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
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
          onRefresh: () async =>
              ref.refresh(teacherAssignmentsProvider(params)),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = assignments[index];
              return _AssignmentCard(assignment: a, isDark: isDark);
            },
          ),
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final LearningAssignment assignment;
  final bool isDark;

  const _AssignmentCard({
    required this.assignment,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = assignment.assignmentType.labelEn;
    final isDraft = assignment.status == AssignmentStatus.draft;

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
          context.push('/teacher/assignment/${assignment.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Type chip + Status
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
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                  _StatusChip(status: assignment.status, isDark: isDark),
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

              // Classroom + Subject Details
              Text(
                '${assignment.classroomName ?? "Class"} • ${_formatSubject(assignment.subjectId, assignment.examVariant)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),

              // Progress bar (for published/closed)
              if (!isDraft) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submissions: ${assignment.submittedCount}/${assignment.recipientCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    if (assignment.submittedCount > 0)
                      Text(
                        'Avg: ${assignment.avgScorePercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.green,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: assignment.completionRate,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.brand),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Footer: Question count + Due Date
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rounded,
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
                      '${assignment.timeLimitMinutes}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (assignment.dueAt != null) ...[
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: assignment.isOverdue
                          ? AppTheme.danger
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due ${_formatDate(assignment.dueAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: assignment.isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: assignment.isOverdue
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

  String _formatSubject(String subjectId, String? variant) {
    final sub = subjectId.replaceAll('_g12', '').toUpperCase();
    if (variant == 'naturalScience') return '$sub (Natural Science)';
    if (variant == 'socialScience') return '$sub (Social Science)';
    return sub;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final AssignmentStatus status;
  final bool isDark;

  const _StatusChip({required this.status, required this.isDark});

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
        fg = isDark ? Colors.white60 : const Color(0xFF64748B);
        break;
      case AssignmentStatus.archived:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = isDark ? Colors.white38 : const Color(0xFF94A3B8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.labelEn,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
