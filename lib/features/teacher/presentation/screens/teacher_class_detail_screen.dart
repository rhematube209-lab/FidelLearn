import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/teacher_portal_providers.dart';
import '../../domain/models/teacher_portal_models.dart';

class TeacherClassDetailScreen extends ConsumerWidget {
  final String classroomId;
  final String subjectId;
  final String classroomName;
  final String subjectName;
  final String? examVariant;
  final int enrolledCount;

  const TeacherClassDetailScreen({
    super.key,
    required this.classroomId,
    required this.subjectId,
    required this.classroomName,
    required this.subjectName,
    this.examVariant,
    required this.enrolledCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final params = (classroomId: classroomId, subjectId: subjectId);

    final weakTopicsAsync = ref.watch(classWeakTopicsProvider(params));
    final examsAsync = ref.watch(classExamSummaryProvider(params));
    final attentionAsync = ref.watch(attentionStudentsProvider(params));

    final attentionCount = attentionAsync.valueOrNull?.totalCount ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.brand,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroomName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          examVariant != null
                              ? '$subjectName — ${_formatVariant(examVariant!)}'
                              : subjectName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                subjectName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(classWeakTopicsProvider(params));
                  ref.invalidate(classExamSummaryProvider(params));
                  ref.invalidate(attentionStudentsProvider(params));
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI chips
                  Row(
                    children: [
                      _KpiChip(
                        label: 'Students',
                        value: '$enrolledCount',
                        icon: Icons.people_rounded,
                        color: AppTheme.brand,
                      ),
                      const SizedBox(width: 8),
                      _KpiChip(
                        label: 'Need Attention',
                        value: '$attentionCount',
                        icon: Icons.flag_rounded,
                        color: attentionCount > 0
                            ? AppTheme.accent
                            : AppTheme.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'View Roster',
                          icon: Icons.list_alt_rounded,
                          color: AppTheme.brand,
                          onTap: () => context.push(
                            '/teacher/class/$classroomId/$subjectId/roster',
                            extra: {
                              'classroomName': classroomName,
                              'subjectName': subjectName,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'Needs Attention',
                          icon: Icons.flag_rounded,
                          color: AppTheme.accent,
                          badge: attentionCount > 0 ? '$attentionCount' : null,
                          onTap: () => context.push(
                            '/teacher/class/$classroomId/$subjectId/attention',
                            extra: {
                              'classroomName': classroomName,
                              'subjectName': subjectName,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'Assignments',
                          icon: Icons.assignment_outlined,
                          color: AppTheme.brand,
                          onTap: () => context.push('/teacher/assignments'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weak Topics
                  const _SectionHeader(
                    title: 'Weak Topics',
                    subtitle: 'Based on synced mistake records',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.accent,
                  ),
                  const SizedBox(height: 10),
                  weakTopicsAsync.when(
                    loading: () => const _SkeletonLoader(lines: 3),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (topics) => topics.isEmpty
                        ? const _EmptyCard(
                            message: 'No weak topics detected yet.\n'
                                'Mistake data will appear as students practice.',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppTheme.green,
                          )
                        : Column(
                            children: topics
                                .take(6)
                                .map((t) => _WeakTopicTile(
                                      topic: t,
                                      isDark: isDark,
                                      total: enrolledCount,
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Exams
                  const _SectionHeader(
                    title: 'Recent Assessments',
                    subtitle: 'Last 5 exams with participation data',
                    icon: Icons.quiz_rounded,
                    iconColor: AppTheme.brand,
                  ),
                  const SizedBox(height: 10),
                  examsAsync.when(
                    loading: () => const _SkeletonLoader(lines: 3),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (exams) => exams.isEmpty
                        ? const _EmptyCard(
                            message: 'No completed assessments yet.\n'
                                'Exam data appears as students submit attempts.',
                            icon: Icons.pending_actions_rounded,
                            color: AppTheme.info,
                          )
                        : Column(
                            children: exams
                                .map((e) => _ExamSummaryTile(
                                      exam: e,
                                      isDark: isDark,
                                    ))
                                .toList(),
                          ),
                  ),
                  // Mastery gap note
                  const SizedBox(height: 16),
                  _MasteryGapNotice(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVariant(String v) {
    if (v == 'naturalScience') return 'Natural Science';
    if (v == 'socialScience') return 'Social Science';
    return v;
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted)),
          ],
        ),
      ],
    );
  }
}

class _WeakTopicTile extends StatelessWidget {
  final ClassWeakTopic topic;
  final bool isDark;
  final int total;

  const _WeakTopicTile({
    required this.topic,
    required this.isDark,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? topic.affectedStudentCount / total : 0.0;
    final color = pct > 0.5
        ? AppTheme.danger
        : pct > 0.25
            ? AppTheme.accent
            : AppTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.protoLine(context)),
        boxShadow: AppTheme.protoCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.topicName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                      ),
                    ),
                    if (topic.unitName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        topic.unitName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.protoMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${topic.affectedStudentCount} / $total students',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${topic.activeMistakeCount} active mistakes',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.protoMuted(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF233452) : const Color(0xFFEEF1F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSummaryTile extends StatelessWidget {
  final ClassExamSummary exam;
  final bool isDark;

  const _ExamSummaryTile({required this.exam, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final avgColor = exam.avgPercentage >= 70
        ? AppTheme.green
        : exam.avgPercentage >= 50
            ? AppTheme.accent
            : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${exam.avgPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: avgColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.examTitle,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _ExamPill(
                        label: exam.provenanceLabel, color: AppTheme.brand),
                    const SizedBox(width: 6),
                    _ExamPill(
                        label:
                            '${exam.participantCount}/${exam.enrolledCount} submitted',
                        color: exam.notSubmitted > 0
                            ? AppTheme.accent
                            : AppTheme.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPill extends StatelessWidget {
  final String label;
  final Color color;
  const _ExamPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _MasteryGapNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: AppTheme.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mastery distribution is device-local (P4 fidel_spaced_v1.0). '
              'It will appear here once cloud sync is implemented.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  final int lines;
  const _SkeletonLoader({required this.lines});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(
        lines,
        (_) => Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.dangerSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.contains('NOT_AUTHORIZED')
                  ? 'Access denied. Contact your school admin.'
                  : 'Failed to load. Check your connection.',
              style: const TextStyle(fontSize: 12, color: AppTheme.dangerDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  const _EmptyCard(
      {required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12, color: color.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
  }
}
