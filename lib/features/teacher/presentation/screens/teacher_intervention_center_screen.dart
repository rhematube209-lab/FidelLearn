import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignment_providers.dart';
import '../providers/teacher_portal_providers.dart';

class TeacherInterventionCenterScreen extends ConsumerStatefulWidget {
  const TeacherInterventionCenterScreen({super.key});

  @override
  ConsumerState<TeacherInterventionCenterScreen> createState() =>
      _TeacherInterventionCenterScreenState();
}

class _TeacherInterventionCenterScreenState
    extends ConsumerState<TeacherInterventionCenterScreen>
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
          'Interventions',
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
            Tab(text: 'Planned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Classroom Filter Chips
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

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InterventionListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: InterventionStatus.open,
                  emptyMessage:
                      'No planned interventions.\nFlagged students from Needs Attention can be assigned actions.',
                  isDark: isDark,
                ),
                _InterventionListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: InterventionStatus.active,
                  emptyMessage: 'No interventions currently in progress.',
                  isDark: isDark,
                ),
                _InterventionListTab(
                  schoolId: schoolId,
                  classroomId: _selectedClassroomId,
                  status: InterventionStatus.completed,
                  emptyMessage: 'No completed interventions recorded yet.',
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

class _InterventionListTab extends ConsumerWidget {
  final String schoolId;
  final String? classroomId;
  final InterventionStatus status;
  final String emptyMessage;
  final bool isDark;

  const _InterventionListTab({
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

    final interventionsAsync = ref.watch(teacherInterventionsProvider(params));

    return interventionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
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
              ref.refresh(teacherInterventionsProvider(params)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = items[idx];
              return _InterventionCard(
                intervention: item,
                isDark: isDark,
                onRefresh: () =>
                    ref.refresh(teacherInterventionsProvider(params)),
              );
            },
          ),
        );
      },
    );
  }
}

class _InterventionCard extends ConsumerStatefulWidget {
  final StudentIntervention intervention;
  final bool isDark;
  final VoidCallback onRefresh;

  const _InterventionCard({
    required this.intervention,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  ConsumerState<_InterventionCard> createState() => _InterventionCardState();
}

class _InterventionCardState extends ConsumerState<_InterventionCard> {
  bool _isProcessing = false;

  Future<void> _completeIntervention() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Intervention Complete?'),
        content: const Text(
          'This certifies that the planned academic action was carried out. Note: completion does not imply student misconception is proven resolved.',
        ),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(interventionRepositoryProvider);
      await repo.completeIntervention(widget.intervention.id);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intervention marked complete.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.intervention;
    final isDark = widget.isDark;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student & Severity
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.brand),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${item.classroomName} • ${item.subjectId.replaceAll("_g12", "").toUpperCase()}',
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
                if (item.severityAtCreation != null)
                  _SeverityBadge(severity: item.severityAtCreation!),
              ],
            ),
            const SizedBox(height: 12),

            // Planned Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 14, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Action: ${item.actionType.labelEn}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            if (item.linkedAssignmentTitle != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 14, color: AppTheme.brand),
                  const SizedBox(width: 4),
                  Text(
                    'Linked: ${item.linkedAssignmentTitle}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.brand),
                  ),
                ],
              ),
            ],

            if (item.teacherNote != null && item.teacherNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${item.teacherNote}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            if (item.status != InterventionStatus.completed &&
                item.status != InterventionStatus.closed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.linkedAssignmentId == null)
                    TextButton.icon(
                      onPressed: () {
                        context.push(
                          '/teacher/assignment/new',
                          extra: {
                            'classroomId': item.classroomId,
                            'subjectId': item.subjectId,
                            'examVariant': item.examVariant,
                            'studentUserId': item.studentUserId,
                          },
                        );
                      },
                      icon: const Icon(Icons.assignment_add, size: 16),
                      label: const Text('Assign Practice'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _completeIntervention,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Mark Complete',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (severity.toLowerCase()) {
      case 'high':
        color = AppTheme.danger;
        label = 'Immediate Support';
        break;
      case 'medium':
        color = AppTheme.accent;
        label = 'Needs Attention';
        break;
      case 'low':
      default:
        color = AppTheme.info;
        label = 'Monitor';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
