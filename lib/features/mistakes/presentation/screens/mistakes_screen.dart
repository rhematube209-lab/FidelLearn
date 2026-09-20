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
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/mistake_model.dart';

class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  List<MistakeRecord> _allMistakes = [];
  Map<String, Question> _questions = {};
  Map<String, Subject> _subjectsMap = {};
  Map<String, Unit> _unitsMap = {};
  MistakeCounts _counts = const MistakeCounts.empty();
  bool _isLoading = true;

  // Navigation hierarchy state:
  // _selectedSubjectId: null = Main Subjects Overview, 'ALL' = All Mistakes List, or specific subjectId
  String? _selectedSubjectId;
  // _selectedUnitId: null = Subject Detail (Units List), or specific unitId for Question List
  String? _selectedUnitId;

  // Secondary status filter: All (null), needsReview, improving, mastered
  MasteryStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'guest_student';
    final mistakeRepo = ref.read(mistakeRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);

    try {
      final list = await mistakeRepo.getMistakes(userId);
      final counts = await mistakeRepo.getMistakeCounts(userId);
      await _cacheQuestions(list);

      // Cache subjects metadata
      final subjects = await contentRepo.getSubjects(
        grade: user?.grade,
        stream: user?.stream ?? 'natural',
      );
      final Map<String, Subject> subjectsMap = {
        for (final s in subjects) s.id: s,
      };

      // Cache units metadata for available subjects
      final Map<String, Unit> unitsMap = {};
      final uniqueSubjectIds = list.map((m) => m.subjectId).toSet();
      for (final sId in uniqueSubjectIds) {
        final units = await contentRepo.getUnits(sId);
        for (final u in units) {
          unitsMap[u.id] = u;
        }
      }

      if (mounted) {
        setState(() {
          _allMistakes = list;
          _counts = counts;
          _subjectsMap = subjectsMap;
          _unitsMap = unitsMap;
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

  String _resolveSubjectName(String subjectId) {
    final subj = _subjectsMap[subjectId];
    if (subj != null) return subj.nameEn;
    final clean = subjectId
        .replaceAll('_g12', '')
        .replaceAll('_g11', '')
        .replaceAll('_', ' ');
    if (clean.isNotEmpty) {
      return clean[0].toUpperCase() + clean.substring(1);
    }
    return subjectId;
  }

  String? _resolveSubjectAmharic(String subjectId) {
    return _subjectsMap[subjectId]?.nameAm;
  }

  String _resolveUnitTitle(String? unitId, String? topicId) {
    if (unitId != null && _unitsMap.containsKey(unitId)) {
      return _unitsMap[unitId]!.titleEn;
    }
    if (unitId != null && unitId.isNotEmpty) {
      final parts = unitId.split('_');
      if (parts.isNotEmpty && parts.last.startsWith('u')) {
        final numPart = parts.last.substring(1);
        return 'Unit $numPart: ${topicId ?? unitId}';
      }
      return 'Unit: $unitId';
    }
    if (topicId != null && topicId.isNotEmpty) {
      return 'Topic: $topicId';
    }
    return 'General Practice';
  }

  String? _resolveUnitAmharic(String? unitId) {
    if (unitId != null && _unitsMap.containsKey(unitId)) {
      return _unitsMap[unitId]!.titleAm;
    }
    return null;
  }

  List<SubjectMistakeSummary> get _subjectSummaries {
    final Map<String, List<MistakeRecord>> grouped = {};
    for (final m in _allMistakes) {
      grouped.putIfAbsent(m.subjectId, () => []).add(m);
    }

    final List<SubjectMistakeSummary> summaries = [];
    for (final entry in grouped.entries) {
      final sId = entry.key;
      final recs = entry.value;

      int needsReview = 0;
      int improving = 0;
      int mastered = 0;
      for (final r in recs) {
        switch (r.masteryStatus) {
          case MasteryStatus.needsReview:
            needsReview++;
            break;
          case MasteryStatus.improving:
            improving++;
            break;
          case MasteryStatus.mastered:
            mastered++;
            break;
        }
      }

      summaries.add(
        SubjectMistakeSummary(
          subjectId: sId,
          nameEn: _resolveSubjectName(sId),
          nameAm: _resolveSubjectAmharic(sId) ?? '',
          counts: MistakeCounts(
            total: recs.length,
            needsReview: needsReview,
            improving: improving,
            mastered: mastered,
          ),
        ),
      );
    }

    summaries.sort((a, b) => b.counts.total.compareTo(a.counts.total));
    return summaries;
  }

  List<UnitMistakeSummary> get _unitSummariesForSelectedSubject {
    if (_selectedSubjectId == null || _selectedSubjectId == 'ALL') return [];

    final subjectMistakes =
        _allMistakes.where((m) => m.subjectId == _selectedSubjectId).toList();
    final Map<String, List<MistakeRecord>> grouped = {};
    for (final m in subjectMistakes) {
      final uKey = m.unitId ?? (m.topicId ?? 'general');
      grouped.putIfAbsent(uKey, () => []).add(m);
    }

    final List<UnitMistakeSummary> summaries = [];
    for (final entry in grouped.entries) {
      final uId = entry.key;
      final recs = entry.value;

      int needsReview = 0;
      int improving = 0;
      int mastered = 0;
      for (final r in recs) {
        switch (r.masteryStatus) {
          case MasteryStatus.needsReview:
            needsReview++;
            break;
          case MasteryStatus.improving:
            improving++;
            break;
          case MasteryStatus.mastered:
            mastered++;
            break;
        }
      }

      summaries.add(
        UnitMistakeSummary(
          unitId: uId,
          subjectId: _selectedSubjectId!,
          titleEn: _resolveUnitTitle(uId, recs.first.topicId),
          titleAm: _resolveUnitAmharic(uId) ?? '',
          counts: MistakeCounts(
            total: recs.length,
            needsReview: needsReview,
            improving: improving,
            mastered: mastered,
          ),
        ),
      );
    }

    summaries.sort((a, b) => b.counts.total.compareTo(a.counts.total));
    return summaries;
  }

  List<MistakeRecord> get _activeQuestions {
    var list = _allMistakes;
    if (_selectedSubjectId != null && _selectedSubjectId != 'ALL') {
      list = list.where((m) => m.subjectId == _selectedSubjectId).toList();
    }
    if (_selectedUnitId != null) {
      list = list
          .where((m) => (m.unitId ?? m.topicId ?? 'general') == _selectedUnitId)
          .toList();
    }
    if (_selectedStatusFilter != null) {
      list =
          list.where((m) => m.masteryStatus == _selectedStatusFilter).toList();
    }
    return list;
  }

  MistakeCounts get _activeScopeCounts {
    if (_selectedSubjectId == null || _selectedSubjectId == 'ALL') {
      return _counts;
    }
    var list =
        _allMistakes.where((m) => m.subjectId == _selectedSubjectId).toList();
    if (_selectedUnitId != null) {
      list = list
          .where((m) => (m.unitId ?? m.topicId ?? 'general') == _selectedUnitId)
          .toList();
    }

    int nr = 0;
    int imp = 0;
    int mst = 0;
    for (final m in list) {
      switch (m.masteryStatus) {
        case MasteryStatus.needsReview:
          nr++;
          break;
        case MasteryStatus.improving:
          imp++;
          break;
        case MasteryStatus.mastered:
          mst++;
          break;
      }
    }
    return MistakeCounts(
      total: list.length,
      needsReview: nr,
      improving: imp,
      mastered: mst,
    );
  }

  void _navigateBack() {
    if (_selectedUnitId != null) {
      setState(() => _selectedUnitId = null);
    } else if (_selectedSubjectId != null) {
      setState(() {
        _selectedSubjectId = null;
        _selectedStatusFilter = null;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _startMistakeRetryExam({
    String? subjectId,
    String? unitId,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'guest_student';
    final mistakeRepo = ref.read(mistakeRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    final unmastered = await mistakeRepo.getMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      onlyUnmastered: true,
    );

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
                'No unmastered mistakes to practice in this scope! All questions mastered.'),
          ),
        );
      }
      return;
    }

    final targetSubject = subjectId ??
        (retryQuestions.isNotEmpty
            ? retryQuestions.first.subjectId
            : 'general');
    final subjectTitle = _resolveSubjectName(targetSubject);

    final exam = Exam(
      id: 'mistake_retry_${DateTime.now().millisecondsSinceEpoch}',
      title: unitId != null
          ? 'Remediation Drill: ${_resolveUnitTitle(unitId, null)}'
          : subjectId != null
              ? '$subjectTitle Mistake Drill'
              : 'Mistake Notebook Remediation Drill',
      examType: ExamType.mistakeRetry,
      grade: user?.grade ?? 12,
      stream: user?.stream ?? 'natural',
      subjectId: targetSubject,
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

    return PopScope(
      canPop: _selectedSubjectId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedUnitId != null
                ? _resolveUnitTitle(_selectedUnitId, null)
                : _selectedSubjectId == 'ALL'
                    ? 'All Mistakes'
                    : _selectedSubjectId != null
                        ? '${_resolveSubjectName(_selectedSubjectId!)} Mistakes'
                        : 'Mistake Notebook & Mastery Engine',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _navigateBack,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.brand))
            : _counts.total == 0
                ? _buildEmptyOverallState(isDark)
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
                            // Breadcrumbs Navigation
                            if (_selectedSubjectId != null) ...[
                              _buildBreadcrumbs(isDark),
                              const SizedBox(height: 16),
                            ],

                            // Top Header Banner & Remediation Drill Action
                            _buildHeaderBanner(isDark),
                            const SizedBox(height: 20),

                            // Summary Metrics Row
                            _buildMetricsRow(context, isDark),
                            const SizedBox(height: 20),

                            // Main View: Subjects List + "All Mistakes" tile
                            if (_selectedSubjectId == null) ...[
                              _buildMainSubjectListView(context, isDark),
                            ]
                            // Subject View: Curriculum Units / Topics list
                            else if (_selectedSubjectId != 'ALL' &&
                                _selectedUnitId == null) ...[
                              _buildSubjectUnitsView(context, isDark),
                            ]
                            // Question List: Unit Detail or All Mistakes
                            else ...[
                              _buildQuestionListView(context, isDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildBreadcrumbs(bool isDark) {
    final subjectTitle = _selectedSubjectId == 'ALL'
        ? 'All Mistakes'
        : _selectedSubjectId != null
            ? _resolveSubjectName(_selectedSubjectId!)
            : '';
    final unitTitle =
        _selectedUnitId != null ? _resolveUnitTitle(_selectedUnitId, null) : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedSubjectId = null;
                _selectedUnitId = null;
                _selectedStatusFilter = null;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 16, color: AppTheme.brand),
                  SizedBox(width: 6),
                  Text(
                    'Mistake Notebook',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (subjectTitle.isNotEmpty) ...[
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.grey),
            InkWell(
              onTap: _selectedUnitId != null
                  ? () {
                      setState(() {
                        _selectedUnitId = null;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  subjectTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedUnitId != null
                        ? AppTheme.brand
                        : (isDark ? AppTheme.darkText : AppTheme.lightText),
                  ),
                ),
              ),
            ),
          ],
          if (unitTitle.isNotEmpty) ...[
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.grey),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  unitTitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOverallState(bool isDark) {
    return Center(
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
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    final scopeCounts = _activeScopeCounts;
    final unmasteredCount = scopeCounts.needsReview + scopeCounts.improving;

    String bannerTitle = 'Mistake Remediation Drill';
    String bannerSubtitle =
        'Mastery requires 2 consecutive correct retries on separate attempts.';
    String actionLabel = 'Practice My Mistakes ($unmasteredCount)';

    if (_selectedUnitId != null) {
      final unitTitle = _resolveUnitTitle(_selectedUnitId, null);
      bannerTitle = 'Drill: $unitTitle';
      actionLabel = 'Practice Unit Mistakes ($unmasteredCount)';
    } else if (_selectedSubjectId == 'ALL') {
      bannerTitle = 'All Subjects Remediation Drill';
      actionLabel = 'Practice All Mistakes ($unmasteredCount)';
    } else if (_selectedSubjectId != null) {
      final subjTitle = _resolveSubjectName(_selectedSubjectId!);
      bannerTitle = '$subjTitle Mistakes Drill';
      actionLabel = 'Practice $subjTitle Mistakes ($unmasteredCount)';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: AppTheme.brand, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bannerSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: unmasteredCount > 0
                  ? () => _startMistakeRetryExam(
                        subjectId: _selectedSubjectId == 'ALL'
                            ? null
                            : _selectedSubjectId,
                        unitId: _selectedUnitId,
                      )
                  : null,
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isDark) {
    final counts = _activeScopeCounts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 4;
        final useGrid = itemWidth < 120;

        if (useGrid) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _buildCountCard(
                  'Total Mistakes', counts.total, AppTheme.brand, isDark),
              _buildCountCard(
                  'Needs Review', counts.needsReview, AppTheme.accent, isDark),
              _buildCountCard(
                  'Improving', counts.improving, AppTheme.info, isDark),
              _buildCountCard(
                  'Mastered', counts.mastered, AppTheme.green, isDark),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
                child: _buildCountCard(
                    'Total Mistakes', counts.total, AppTheme.brand, isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCountCard('Needs Review', counts.needsReview,
                    AppTheme.accent, isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCountCard(
                    'Improving', counts.improving, AppTheme.info, isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCountCard(
                    'Mastered', counts.mastered, AppTheme.green, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildCountCard(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', null, isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Needs Review', MasteryStatus.needsReview, isDark,
              accentColor: AppTheme.accent),
          const SizedBox(width: 8),
          _buildFilterChip('Improving', MasteryStatus.improving, isDark,
              accentColor: AppTheme.info),
          const SizedBox(width: 8),
          _buildFilterChip('Mastered', MasteryStatus.mastered, isDark,
              accentColor: AppTheme.green),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MasteryStatus? status, bool isDark,
      {Color? accentColor}) {
    final isSelected = _selectedStatusFilter == status;
    final color = accentColor ?? AppTheme.brand;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
      selectedColor: color.withValues(alpha: 0.18),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? color
            : (isDark ? AppTheme.darkText : AppTheme.lightText),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
    );
  }

  Widget _buildMainSubjectListView(BuildContext context, bool isDark) {
    final summaries = _subjectSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "All Mistakes" Master Tile
        InkWell(
          onTap: () {
            setState(() {
              _selectedSubjectId = 'ALL';
              _selectedUnitId = null;
              _selectedStatusFilter = null;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.brand.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded,
                      color: AppTheme.brand, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Mistakes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse and filter all ${_counts.total} mistakes across every subject',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FidelBadge(
                  text: '${_counts.total} Qs',
                  variant: FidelBadgeVariant.primary,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section Title: Subjects
        Row(
          children: [
            const Icon(Icons.category_rounded, size: 20, color: AppTheme.brand),
            const SizedBox(width: 8),
            Text(
              'Subjects with Mistakes (${summaries.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Subject Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summaries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = summaries[index];
            return _buildSubjectCard(s, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectMistakeSummary s, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubjectId = s.subjectId;
          _selectedUnitId = null;
          _selectedStatusFilter = null;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: AppTheme.brand, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nameEn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (s.nameAm.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.nameAm,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkMuted
                                : AppTheme.lightMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FidelBadge(
                  text: '${s.counts.total} mistakes',
                  variant: FidelBadgeVariant.primary,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMiniBadge(
                    '${s.counts.needsReview} Needs Review', AppTheme.accent),
                _buildMiniBadge(
                    '${s.counts.improving} Improving', AppTheme.info),
                _buildMiniBadge(
                    '${s.counts.mastered} Mastered', AppTheme.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectUnitsView(BuildContext context, bool isDark) {
    final units = _unitSummariesForSelectedSubject;
    final subjectTitle = _resolveSubjectName(_selectedSubjectId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar for Subject
        _buildStatusFilterChips(isDark),
        const SizedBox(height: 18),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_rounded,
                    size: 20, color: AppTheme.brand),
                const SizedBox(width: 8),
                Text(
                  'Curriculum Units & Topics (${units.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedUnitId = null;
                  // Switch to viewing all questions for this subject
                  _selectedSubjectId = 'ALL';
                });
              },
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text('View Flat List'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (units.isEmpty)
          _buildEmptyFilteredCard(
              'No units matching the selected status filter in $subjectTitle.',
              isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final u = units[index];
              return _buildUnitCard(u, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildUnitCard(UnitMistakeSummary u, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUnitId = u.unitId;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_special_rounded,
                      color: AppTheme.brand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.titleEn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (u.titleAm.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          u.titleAm,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkMuted
                                : AppTheme.lightMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FidelBadge(
                  text: '${u.counts.total} mistakes',
                  variant: FidelBadgeVariant.primary,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMiniBadge(
                    '${u.counts.needsReview} Needs Review', AppTheme.accent),
                _buildMiniBadge(
                    '${u.counts.improving} Improving', AppTheme.info),
                _buildMiniBadge(
                    '${u.counts.mastered} Mastered', AppTheme.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionListView(BuildContext context, bool isDark) {
    final questions = _activeQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar
        _buildStatusFilterChips(isDark),
        const SizedBox(height: 18),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${questions.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedUnitId != null)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedUnitId = null);
                },
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: const Text('Back to Units'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (questions.isEmpty)
          _buildEmptyFilteredCard(
              'No mistake questions match the current filters.', isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = questions[index];
              return _buildMistakeCard(m, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyFilteredCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.filter_list_off_rounded,
                size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeCard(MistakeRecord m, bool isDark) {
    final q = _questions[m.questionId];
    final previewText = q?.questionTextEn ?? 'Question ${m.questionId}';
    final subjectTitle = _resolveSubjectName(m.subjectId);
    final unitTitle = _resolveUnitTitle(m.unitId, m.topicId);

    FidelBadgeVariant badgeVariant;
    switch (m.masteryStatus) {
      case MasteryStatus.needsReview:
        badgeVariant = FidelBadgeVariant.warning;
        break;
      case MasteryStatus.improving:
        badgeVariant = FidelBadgeVariant.info;
        break;
      case MasteryStatus.mastered:
        badgeVariant = FidelBadgeVariant.success;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: () => _openMistakeSolutionReview(m),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject/Unit pills & Mastery badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(subjectTitle, AppTheme.brand),
                        _buildTag(unitTitle, Colors.grey),
                        if (q?.difficulty != null)
                          _buildTag(q!.difficulty.toUpperCase(), Colors.purple),
                        if (q?.examYear != null)
                          _buildTag('${q!.examYear} E.C.', Colors.teal),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FidelBadge(
                    text: m.masteryStatus.displayNameEn,
                    variant: badgeVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question Preview Text
              Text(
                previewText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Miss count, Retry progress, and Tap action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Missed ${m.missCount} times',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkMuted
                                : AppTheme.lightMuted,
                          ),
                        ),
                        FidelBadge(
                          text: 'Retry: ${m.correctRetryCount}/2',
                          variant: FidelBadgeVariant.primary,
                          isSmall: true,
                        ),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Review Solution',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brand,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppTheme.brand),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
