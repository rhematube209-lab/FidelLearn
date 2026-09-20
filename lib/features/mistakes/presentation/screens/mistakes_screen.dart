import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/mistake_model.dart';

class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  List<MistakeRecord> _allMistakes = [];
  Map<String, Question> _questions = {};
  MistakeCounts _counts = const MistakeCounts.empty();
  bool _isLoading = true;

  MasteryStatus? _selectedStatusFilter; // null = All
  String? _selectedSubjectFilter; // null = All Subjects

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'guest_student';
    final mistakeRepo = ref.read(mistakeRepositoryProvider);

    try {
      final list = await mistakeRepo.getMistakes(userId);
      final counts = await mistakeRepo.getMistakeCounts(userId);
      await _cacheQuestions(list);

      if (mounted) {
        setState(() {
          _allMistakes = list;
          _counts = counts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cacheQuestions(List<MistakeRecord> records) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final Map<String, Question> newMap = Map.from(_questions);

    for (final m in records) {
      if (!newMap.containsKey(m.questionId)) {
        final q = await contentRepo.getQuestionById(m.questionId);
        if (q != null) newMap[m.questionId] = q;
      }
    }
    _questions = newMap;
  }

  List<MistakeRecord> get _filteredMistakes {
    return _allMistakes.where((m) {
      if (_selectedStatusFilter != null &&
          m.masteryStatus != _selectedStatusFilter) {
        return false;
      }
      if (_selectedSubjectFilter != null &&
          m.subjectId != _selectedSubjectFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _availableSubjects {
    final set = <String>{};
    for (final m in _allMistakes) {
      set.add(m.subjectId);
    }
    return set.toList()..sort();
  }

  Future<void> _startMistakeRetryExam() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'guest_student';
    final mistakeRepo = ref.read(mistakeRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    // Section 28 & 45: Fetch unmastered mistakes, needsReview first, then improving
    final unmastered =
        await mistakeRepo.getMistakes(userId, onlyUnmastered: true);

    unmastered.sort((a, b) {
      if (a.masteryStatus == MasteryStatus.needsReview &&
          b.masteryStatus != MasteryStatus.needsReview) {
        return -1;
      }
      if (a.masteryStatus != MasteryStatus.needsReview &&
          b.masteryStatus == MasteryStatus.needsReview) {
        return 1;
      }
      return b.lastMissedAt.compareTo(a.lastMissedAt);
    });

    final List<Question> retryQuestions = [];
    for (final m in unmastered) {
      final q = _questions[m.questionId];
      if (q != null) retryQuestions.add(q);
    }

    if (retryQuestions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No unmastered mistakes to practice! All questions mastered.'),
          ),
        );
      }
      return;
    }

    final exam = Exam(
      id: 'mistake_retry_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Mistake Notebook Remediation Drill',
      examType: ExamType.mistakeRetry,
      grade: user?.grade ?? 12,
      stream: user?.stream ?? 'natural',
      subjectId: retryQuestions.first.subjectId,
      timeLimitMinutes: 0,
      totalQuestions: retryQuestions.length,
      questions: retryQuestions,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_retry_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

    if (mounted) {
      await context
          .push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
      if (mounted) {
        await _loadMistakes();
      }
    }
  }

  void _openMistakeSolutionReview(MistakeRecord m) async {
    final q = _questions[m.questionId];
    if (q == null) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'guest_student';

    // Section 37: In-memory synthetic adapter; do NOT persist or contaminate analytics
    final syntheticAttempt = ExamAttempt(
      id: 'synthetic_review_${m.id}',
      userId: userId,
      examId: 'mistake_notebook_review',
      examTitle: 'Mistake Solution Review',
      subjectId: m.subjectId,
      startTime: m.firstMissedAt,
      endTime: m.lastMissedAt,
      durationSeconds: 0,
      totalQuestions: 1,
      score: 0,
      percentage: 0.0,
      correctCount: 0,
      incorrectCount: 1,
      skippedCount: 0,
      isCompleted: true,
      responses: {
        q.id: UserResponse(
          questionId: q.id,
          selectedChoiceId: m.lastSelectedChoiceId,
          isCorrect: false,
        ),
      },
    );

    await context.push('/solution_review', extra: {
      'questions': [q],
      'attempt': syntheticAttempt,
    });

    if (mounted) {
      await _loadMistakes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final filtered = _filteredMistakes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Notebook & Mastery Engine',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brand))
          : _counts.total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 64,
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No mistakes yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                            'Questions you answer incorrectly during mock exams, untimed practice, or custom builder sessions will automatically appear here for review and targeted drills.',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : AppTheme.lightMuted,
                              fontSize: 14,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48.0 : 16.0,
                    vertical: 24.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Banner & Remediation Drill Action
                          _buildHeaderBanner(isDark),
                          const SizedBox(height: 20),

                          // Summary Metrics Cards (Total, Needs Review, Improving, Mastered)
                          _buildMetricsRow(context, isDark),
                          const SizedBox(height: 20),

                          // Filter Bar
                          _buildFilterBar(isDark),
                          const SizedBox(height: 18),

                          // Empty filtered results state
                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                    color: AppTheme.adaptiveBorder(context)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.filter_alt_off_rounded,
                                      size: 48,
                                      color: isDark
                                          ? AppTheme.darkMuted
                                          : AppTheme.lightMuted),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No questions match this filter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try selecting "All" or a different status filter.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkMuted
                                          : AppTheme.lightMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Mistakes Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: isDesktop ? 520 : 600,
                                mainAxisExtent: 220,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                final q = _questions[m.questionId];
                                return _buildMistakeCard(m, q, isDark);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    final unmasteredCount = _counts.needsReview + _counts.improving;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF831843), AppTheme.darkSurfaceStrong]
              : const [Color(0xFFBE185D), Color(0xFF9D174D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.pink.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unmasteredCount Questions Needing Drill',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Deterministic mastery: answer correctly across 2 distinct attempts to fully master each question.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFFCE7F3),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: unmasteredCount > 0 ? _startMistakeRetryExam : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Practice My Mistakes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandStrong,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBadgeCard(
            label: 'Total Mistakes',
            count: _counts.total,
            color: AppTheme.brand,
            icon: Icons.auto_stories_rounded,
            isSelected: _selectedStatusFilter == null,
            onTap: () => setState(() => _selectedStatusFilter = null),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricBadgeCard(
            label: 'Needs Review',
            count: _counts.needsReview,
            color: AppTheme.danger,
            icon: Icons.warning_amber_rounded,
            isSelected: _selectedStatusFilter == MasteryStatus.needsReview,
            onTap: () => setState(
                () => _selectedStatusFilter = MasteryStatus.needsReview),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricBadgeCard(
            label: 'Improving',
            count: _counts.improving,
            color: AppTheme.accent,
            icon: Icons.trending_up_rounded,
            isSelected: _selectedStatusFilter == MasteryStatus.improving,
            onTap: () =>
                setState(() => _selectedStatusFilter = MasteryStatus.improving),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricBadgeCard(
            label: 'Mastered',
            count: _counts.mastered,
            color: AppTheme.green,
            icon: Icons.verified_rounded,
            isSelected: _selectedStatusFilter == MasteryStatus.mastered,
            onTap: () =>
                setState(() => _selectedStatusFilter = MasteryStatus.mastered),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBadgeCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppTheme.adaptiveBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final availableSubjects = _availableSubjects;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Filter by:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        ChoiceChip(
          label: const Text('All Statuses'),
          selected: _selectedStatusFilter == null,
          onSelected: (_) => setState(() => _selectedStatusFilter = null),
        ),
        ChoiceChip(
          label: const Text('Needs Review'),
          selected: _selectedStatusFilter == MasteryStatus.needsReview,
          onSelected: (_) =>
              setState(() => _selectedStatusFilter = MasteryStatus.needsReview),
        ),
        ChoiceChip(
          label: const Text('Improving'),
          selected: _selectedStatusFilter == MasteryStatus.improving,
          onSelected: (_) =>
              setState(() => _selectedStatusFilter = MasteryStatus.improving),
        ),
        ChoiceChip(
          label: const Text('Mastered'),
          selected: _selectedStatusFilter == MasteryStatus.mastered,
          onSelected: (_) =>
              setState(() => _selectedStatusFilter = MasteryStatus.mastered),
        ),
        if (availableSubjects.length > 1) ...[
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: _selectedSubjectFilter,
            hint: const Text('All Subjects', style: TextStyle(fontSize: 12.5)),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Subjects', style: TextStyle(fontSize: 12.5)),
              ),
              ...availableSubjects.map((s) => DropdownMenuItem<String?>(
                    value: s,
                    child: Text(s.toUpperCase(),
                        style: const TextStyle(fontSize: 12.5)),
                  )),
            ],
            onChanged: (val) => setState(() => _selectedSubjectFilter = val),
          ),
        ],
      ],
    );
  }

  Widget _buildMistakeCard(MistakeRecord m, Question? q, bool isDark) {
    final FidelBadgeVariant badgeVariant;
    switch (m.masteryStatus) {
      case MasteryStatus.mastered:
        badgeVariant = FidelBadgeVariant.success;
        break;
      case MasteryStatus.improving:
        badgeVariant = FidelBadgeVariant.primary;
        break;
      case MasteryStatus.needsReview:
        badgeVariant = FidelBadgeVariant.danger;
        break;
    }

    final String subjectLabel = q?.subjectId.toUpperCase() ??
        m.subjectId.replaceAll('_', ' ').toUpperCase();

    final String unitTopicLabel = (m.unitId != null && m.unitId!.isNotEmpty)
        ? m.unitId!.replaceAll('_', ' ')
        : (q != null ? q.unitId.replaceAll('_', ' ') : 'Unit Drill');

    return InkWell(
      onTap: () => _openMistakeSolutionReview(m),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.adaptiveBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Failure Pill & Subject/Unit Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'MISSED ${m.missCount}X',
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$subjectLabel • $unitTopicLabel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Question Statement Preview
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                q?.questionTextEn ?? 'Question content unavailable offline...',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Bottom Status & Review Prompt
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FidelBadge(
                        text: m.masteryStatus.displayNameEn.toUpperCase(),
                        variant: badgeVariant,
                        isSmall: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retry: ${m.correctRetryCount}/2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diff: ${(q?.difficulty ?? "MED").toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Review Solution',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandStrong,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppTheme.brandStrong),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
