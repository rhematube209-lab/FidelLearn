import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignment_providers.dart';

class StudentAssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends ConsumerState<StudentAssignmentDetailScreen> {
  bool _isStarting = false;

  Future<void> _startAssignment({
    required Map<String, dynamic> detail,
    required String userId,
  }) async {
    setState(() => _isStarting = true);

    try {
      final questionIds = (detail['question_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (questionIds.isEmpty) {
        throw Exception('Assignment does not contain questions.');
      }

      // Load questions from local content repository
      final contentRepo = ref.read(contentRepositoryProvider);
      final allQuestions = await contentRepo.getQuestions(
        subjectId: detail['subject_id'] as String,
        limit: 100,
      );

      final qMap = {for (final q in allQuestions) q.id: q};
      final resolvedQuestions = <Question>[];

      for (final qid in questionIds) {
        final q = qMap[qid];
        if (q != null) {
          resolvedQuestions.add(q);
        }
      }

      if (resolvedQuestions.length < questionIds.length) {
        throw Exception(
          'Historical assignment content incomplete or unavailable. Required content package version must be downloaded.',
        );
      }

      final timeLimit = (detail['time_limit_minutes'] as num?)?.toInt() ?? 0;
      final title = detail['title'] as String? ?? 'Assignment';

      final asgnType = AssignmentType.fromString(
        detail['assignment_type'] as String?,
      );

      final ExamMode resolvedMode = switch (asgnType) {
        AssignmentType.simulation => ExamMode.nationalSimulation,
        AssignmentType.customQuestionSet => ExamMode.custom,
        _ => ExamMode.practice,
      };

      final bool allOfficial = resolvedQuestions.every((q) =>
          q.provenance?.provenanceType ==
              SourceProvenanceType.officialNeaeaPaper ||
          q.provenance?.provenanceType == SourceProvenanceType.nationalArchive);
      final bool allModel = resolvedQuestions.every((q) =>
          q.provenance?.provenanceType ==
          SourceProvenanceType.educatorModelExam);

      final ExamSourceType resolvedSourceType;
      if (asgnType == AssignmentType.simulation) {
        resolvedSourceType = ExamSourceType.generatedSimulation;
      } else if (allOfficial) {
        resolvedSourceType = ExamSourceType.officialHistoricalPaper;
      } else if (allModel) {
        resolvedSourceType = ExamSourceType.verifiedModelPaper;
      } else {
        resolvedSourceType = ExamSourceType.generatedSimulation;
      }

      final exam = Exam(
        id: 'assignment_${widget.assignmentId}',
        title: title,
        examType: ExamType.teacherAssigned,
        examMode: resolvedMode,
        sourceType: resolvedSourceType,
        grade: 12,
        stream: 'natural',
        subjectId: detail['subject_id'] as String?,
        timeLimitMinutes: timeLimit,
        totalQuestions: resolvedQuestions.length,
        questions: resolvedQuestions,
        createdAt: DateTime.now(),
      );

      final attemptId = const Uuid().v4();
      final attempt = ExamEngine.startAttempt(
        attemptId: attemptId,
        userId: userId,
        exam: exam,
      );

      if (mounted) {
        await context.push(
          '/exam_runner',
          extra: {
            'exam': exam,
            'attempt': attempt,
            'showInstantFeedback': timeLimit == 0,
            'assignmentId': widget.assignmentId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cannot start assignment: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailAsync =
        ref.watch(studentAssignmentDetailProvider(widget.assignmentId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Assignment Detail',
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
      ),
      body: detailAsync.when(
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
                Text('Failed to load assignment: $e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(
                      studentAssignmentDetailProvider(widget.assignmentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final title = detail['title'] as String? ?? 'Assignment';
          final instructions = detail['instructions'] as String?;
          final status = detail['student_status'] as String? ?? 'assigned';
          final isSubmitted = status == 'submitted' ||
              status == 'completed' ||
              status == 'late';
          final score = detail['score'] as int?;
          final percentage = (detail['percentage'] as num?)?.toDouble();
          final totalQuestions =
              (detail['total_questions'] as num?)?.toInt() ?? 0;
          final timeLimit =
              (detail['time_limit_minutes'] as num?)?.toInt() ?? 0;
          final dueAtStr = detail['due_at'] as String?;
          final dueAt = dueAtStr != null ? DateTime.parse(dueAtStr) : null;
          final isOverdue =
              dueAt != null && DateTime.now().isAfter(dueAt) && !isSubmitted;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Subject
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.brand.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (detail['subject_id'] as String? ?? '')
                                    .replaceAll('_g12', '')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brand,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSubmitted
                                    ? AppTheme.green.withValues(alpha: 0.15)
                                    : (isOverdue
                                        ? AppTheme.danger
                                            .withValues(alpha: 0.15)
                                        : AppTheme.brand
                                            .withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isSubmitted
                                    ? (status == 'late'
                                        ? 'Submitted (Late)'
                                        : 'Completed')
                                    : (isOverdue ? 'Past Due' : 'Not Started'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSubmitted
                                      ? AppTheme.green
                                      : (isOverdue
                                          ? AppTheme.danger
                                          : AppTheme.brand),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Details Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.help_outline_rounded,
                                label: 'Total Questions',
                                value: '$totalQuestions questions',
                                isDark: isDark,
                              ),
                              const Divider(height: 18),
                              _DetailRow(
                                icon: Icons.timer_outlined,
                                label: 'Time Allowance',
                                value: timeLimit > 0
                                    ? '$timeLimit minutes'
                                    : 'Untimed practice',
                                isDark: isDark,
                              ),
                              if (dueAt != null) ...[
                                const Divider(height: 18),
                                _DetailRow(
                                  icon: Icons.event_available_rounded,
                                  label: 'Deadline',
                                  value:
                                      '${dueAt.month}/${dueAt.day}/${dueAt.year}',
                                  isDark: isDark,
                                  isWarning: isOverdue,
                                ),
                              ],
                              const Divider(height: 18),
                              _DetailRow(
                                icon: Icons.offline_pin_outlined,
                                label: 'Offline Availability',
                                value: 'Ready Offline',
                                isDark: isDark,
                                valueColor: AppTheme.green,
                              ),
                            ],
                          ),
                        ),

                        if (instructions != null &&
                            instructions.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Teacher Instructions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              instructions,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],

                        // Scored Result Card (if completed)
                        if (isSubmitted) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.green,
                                  size: 36,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Submission Finalized',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Score: ${percentage?.toStringAsFixed(0) ?? score?.toString() ?? "Completed"}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Action
                if (!isSubmitted) ...[
                  ElevatedButton(
                    onPressed: _isStarting
                        ? null
                        : () => _startAssignment(
                              detail: detail,
                              userId: currentUser?.id ?? 'guest_student',
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isStarting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Start Assignment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isWarning;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isWarning = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isWarning
                ? AppTheme.danger
                : (valueColor ??
                    (isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ),
      ],
    );
  }
}
