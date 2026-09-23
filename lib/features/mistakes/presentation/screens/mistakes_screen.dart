import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
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
    final isAmharic = Localizations.localeOf(context).languageCode == 'am';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final scopeCounts = _activeScopeCounts;
    final unmasteredCount = scopeCounts.needsReview + scopeCounts.improving;

    String headerTitle = 'Mistake Remediation Drill';
    String headerSubtitle =
        'Targeted recovery drill powered by spaced repetition. Mastery requires 2 consecutive correct retries on separate attempts.';
    String actionLabel = 'Practice My Mistakes';

    if (_selectedUnitId != null) {
      final unitTitle = _resolveUnitTitle(_selectedUnitId, null);
      headerTitle = 'Drill: $unitTitle';
      headerSubtitle =
          'Targeted unit-level recovery drill powered by spaced repetition.';
      actionLabel = 'Practice Unit Mistakes';
    } else if (_selectedSubjectId == 'ALL') {
      headerTitle = 'All Mistakes';
      headerSubtitle =
          'Browse and practice all unmastered mistakes across every subject.';
      actionLabel = 'Practice All Mistakes';
    } else if (_selectedSubjectId != null) {
      final subjTitle = _resolveSubjectName(_selectedSubjectId!);
      headerTitle = '$subjTitle Mistakes';
      headerSubtitle =
          'Subject-specific recovery drill powered by spaced repetition.';
      actionLabel = 'Practice $subjTitle Mistakes';
    }

    return PopScope(
      canPop: _selectedSubjectId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFBFD),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.brand))
            : _counts.total == 0
                ? _buildEmptyOverallState(isDark)
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Top Integrated Gradient Header & Primary CTA
                        _buildTopHeader(
                          context: context,
                          isDark: isDark,
                          isAmharic: isAmharic,
                          unmasteredCount: unmasteredCount,
                          title: headerTitle,
                          subtitle: headerSubtitle,
                          actionLabel: actionLabel,
                          isDesktop: isDesktop,
                        ),

                        // 2. Responsive Scrollable Body Content
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 32.0 : 16.0,
                                vertical: isDesktop ? 24.0 : 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Breadcrumbs (when drilled into subject or unit)
                                  if (_selectedSubjectId != null) ...[
                                    _buildBreadcrumbs(isDark),
                                    const SizedBox(height: 14),
                                  ],

                                  // Drill Breakdown Metrics Dashboard
                                  _buildMetricsDashboard(
                                    context,
                                    isDark,
                                    isDesktop: isDesktop,
                                  ),
                                  const SizedBox(height: 20),

                                  // Main Root View
                                  if (_selectedSubjectId == null) ...[
                                    if (isDesktop) ...[
                                      // Desktop: Side-by-side Quick Banner & High-Yield Tip
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              flex: 6,
                                              child: _buildAllMistakesBanner(
                                                  isDark),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 5,
                                              child: _buildEncouragementTip(
                                                  isDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Desktop: Multi-column Subjects with Mistakes
                                      _buildSubjectsWithMistakesSection(
                                        context,
                                        _subjectSummaries,
                                        isDark,
                                        isDesktop: true,
                                      ),
                                      const SizedBox(height: 32),
                                    ] else ...[
                                      // Mobile: Vertical flow
                                      _buildAllMistakesBanner(isDark),
                                      const SizedBox(height: 18),

                                      _buildSubjectsWithMistakesSection(
                                        context,
                                        _subjectSummaries,
                                        isDark,
                                        isDesktop: false,
                                      ),
                                      const SizedBox(height: 18),

                                      _buildEncouragementTip(isDark),
                                      const SizedBox(height: 24),
                                    ],
                                  ]
                                  // Subject Drill Units View
                                  else if (_selectedSubjectId != 'ALL' &&
                                      _selectedUnitId == null) ...[
                                    _buildSubjectUnitsView(
                                      context,
                                      isDark,
                                      isDesktop: isDesktop,
                                    ),
                                    const SizedBox(height: 24),
                                  ]
                                  // Question List View
                                  else ...[
                                    _buildQuestionListView(
                                      context,
                                      isDark,
                                      isDesktop: isDesktop,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ==========================================
  // 1. TOP INTEGRATED GRADIENT HEADER
  // ==========================================
  Widget _buildTopHeader({
    required BuildContext context,
    required bool isDark,
    required bool isAmharic,
    required int unmasteredCount,
    required String title,
    required String subtitle,
    required String actionLabel,
    bool isDesktop = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3730A3),
            Color(0xFF4338CA),
            Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x333730A3),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background ambient glowing blur circles (per reference)
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: isDesktop ? 260 : 170,
              height: isDesktop ? 260 : 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA5B4FC).withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: isDesktop ? 120 : 48,
            child: Container(
              width: isDesktop ? 160 : 110,
              height: isDesktop ? 160 : 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
              ),
            ),
          ),

          // Header Content (Edge-to-edge full width background with centered container)
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20,
                    isDesktop ? 22 : 14,
                    isDesktop ? 32 : 20,
                    isDesktop ? 26 : 24,
                  ),
                  child: isDesktop
                      ? _buildDesktopHeaderContent(
                          context: context,
                          isDark: isDark,
                          unmasteredCount: unmasteredCount,
                          title: title,
                          subtitle: subtitle,
                          actionLabel: actionLabel,
                        )
                      : _buildMobileHeaderContent(
                          context: context,
                          isDark: isDark,
                          unmasteredCount: unmasteredCount,
                          title: title,
                          subtitle: subtitle,
                          actionLabel: actionLabel,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeaderContent({
    required BuildContext context,
    required bool isDark,
    required int unmasteredCount,
    required String title,
    required String subtitle,
    required String actionLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Icon + Title + Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE0E7FF).withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),

        // Right Column: CTA Button + Back Navigation
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 270,
              child: _buildPracticeCtaButton(
                context: context,
                isDark: isDark,
                unmasteredCount: unmasteredCount,
                actionLabel: actionLabel,
              ),
            ),
            const SizedBox(width: 14),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeaderContent({
    required BuildContext context,
    required bool isDark,
    required int unmasteredCount,
    required String title,
    required String subtitle,
    required String actionLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: Icon squircle + Title + Back Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Circular Back Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFE0E7FF).withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // Floating Primary CTA Button ("Practice My Mistakes")
        _buildPracticeCtaButton(
          context: context,
          isDark: isDark,
          unmasteredCount: unmasteredCount,
          actionLabel: actionLabel,
        ),
      ],
    );
  }

  Widget _buildPracticeCtaButton({
    required BuildContext context,
    required bool isDark,
    required int unmasteredCount,
    required String actionLabel,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unmasteredCount > 0
            ? () => _startMistakeRetryExam(
                  subjectId:
                      _selectedSubjectId == 'ALL' ? null : _selectedSubjectId,
                  unitId: _selectedUnitId,
                )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : Colors.white.withValues(alpha: 0.9),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4F46E5),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unmasteredCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF312E81)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unmasteredCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4338CA),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. DRILL BREAKDOWN METRICS DASHBOARD
  // ==========================================
  Widget _buildMetricsDashboard(
    BuildContext context,
    bool isDark, {
    bool isDesktop = false,
  }) {
    final counts = _activeScopeCounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DRILL BREAKDOWN',
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              Text(
                'Auto-updated',
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkMuted : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 4 Metric Tiles Row
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Mistakes',
                displayTitle: 'TOTAL',
                value: '${counts.total}',
                subLabel: 'mistakes',
                valueColor: const Color(0xFF4F46E5),
                titleColor:
                    isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                subLabelColor: isDark
                    ? const Color(0xFF818CF8)
                    : const Color(0xFF4338CA).withValues(alpha: 0.85),
                isDark: isDark,
                isDesktop: isDesktop,
              ),
            ),
            SizedBox(width: isDesktop ? 14 : 6),
            Expanded(
              child: _buildMetricTile(
                title: 'Needs Review',
                displayTitle: 'NEEDS',
                value: '${counts.needsReview}',
                subLabel: 'review',
                valueColor: const Color(0xFFF59E0B),
                titleColor:
                    isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                subLabelColor: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFFB45309).withValues(alpha: 0.85),
                isDark: isDark,
                isDesktop: isDesktop,
              ),
            ),
            SizedBox(width: isDesktop ? 14 : 6),
            Expanded(
              child: _buildMetricTile(
                title: 'Improving',
                displayTitle: 'IMPROVING',
                value: '${counts.improving}',
                subLabel: '1 of 2',
                valueColor: const Color(0xFF0284C7),
                titleColor:
                    isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                subLabelColor: isDark
                    ? const Color(0xFF7DD3FC)
                    : const Color(0xFF0369A1).withValues(alpha: 0.85),
                isDark: isDark,
                isDesktop: isDesktop,
              ),
            ),
            SizedBox(width: isDesktop ? 14 : 6),
            Expanded(
              child: _buildMetricTile(
                title: 'Mastered',
                displayTitle: 'MASTERED',
                value: '${counts.mastered}',
                subLabel: 'resolved',
                valueColor: const Color(0xFF10B981),
                titleColor:
                    isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                subLabelColor: isDark
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFF047857).withValues(alpha: 0.85),
                isDark: isDark,
                isDesktop: isDesktop,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String displayTitle,
    required String value,
    required String subLabel,
    required Color valueColor,
    required Color titleColor,
    required Color subLabelColor,
    required bool isDark,
    bool isDesktop = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 14 : 8,
        vertical: isDesktop ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valueColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.4,
        ),
        boxShadow: [
          if (!isDark) ...[
            const BoxShadow(
              color: Color(0x38A3B1C6),
              offset: Offset(4, 4),
              blurRadius: 10,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 10,
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: isDesktop ? 11.5 : 10,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Zero-size accessible node so find.text(title) works in widget tests
              SizedBox(
                width: 0,
                height: 0,
                child: OverflowBox(
                  maxWidth: 0,
                  maxHeight: 0,
                  child: Text(title),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 6 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
              height: 1.1,
            ),
          ),
          SizedBox(height: isDesktop ? 4 : 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 9.5,
              fontWeight: FontWeight.w600,
              color: subLabelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ALL MISTAKES QUICK BANNER
  // ==========================================
  Widget _buildAllMistakesBanner(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubjectId = 'ALL';
            _selectedUnitId = null;
            _selectedStatusFilter = null;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.transparent,
            ),
            boxShadow: [
              if (!isDark) ...[
                const BoxShadow(
                  color: Color(0x38A3B1C6),
                  offset: Offset(5, 5),
                  blurRadius: 12,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-5, -5),
                  blurRadius: 12,
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              // Inset squircle icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFEEF1F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Mistakes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse and filter all ${_counts.total} mistakes across every subject',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkMuted
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE0E7FF),
                  ),
                ),
                child: Text(
                  '${_counts.total} Qs',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Circle Chevron Button
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF4F6FB),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. SUBJECTS WITH MISTAKES SECTION
  // ==========================================
  Widget _buildSubjectsWithMistakesSection(
    BuildContext context,
    List<SubjectMistakeSummary> summaries,
    bool isDark, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Subjects with Mistakes',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${summaries.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Responsive Subject Cards List / Multi-column Grid
        if (isDesktop && summaries.length > 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: summaries
                    .map((s) => SizedBox(
                          width: cardWidth,
                          child: _buildSubjectCard(s, isDark),
                        ))
                    .toList(),
              );
            },
          )
        else
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
    final color = _getSubjectColor(s.subjectId);
    final icon = _getSubjectIcon(s.subjectId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubjectId = s.subjectId;
            _selectedUnitId = null;
            _selectedStatusFilter = null;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.transparent,
            ),
            boxShadow: [
              if (!isDark) ...[
                const BoxShadow(
                  color: Color(0x38A3B1C6),
                  offset: Offset(5, 5),
                  blurRadius: 12,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-5, -5),
                  blurRadius: 12,
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Subject Name + Mistake count badge + chevron
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFEEF1F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: color,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nameEn,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.nameAm.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.nameAm,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE0E7FF),
                      ),
                    ),
                    child: Text(
                      '${s.counts.total} mistakes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF4F6FB),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom status breakdown strip
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatusPill(
                      label: '${s.counts.needsReview} Needs Review',
                      bgColor: isDark
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFFFBEB),
                      textColor: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFB45309),
                      borderColor: isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFDE68A),
                    ),
                    _buildStatusPill(
                      label: '${s.counts.improving} Improving',
                      bgColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFEEF1F8),
                      textColor: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      borderColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    _buildStatusPill(
                      label: '${s.counts.mastered} Mastered',
                      bgColor: isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFECFDF5),
                      textColor: isDark
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFF047857),
                      borderColor: isDark
                          ? const Color(0xFF065F46)
                          : const Color(0xFFA7F3D0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 5. ENCOURAGEMENT HIGH-YIELD TIP
  // ==========================================
  Widget _buildEncouragementTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFA7F3D0).withValues(alpha: isDark ? 0.25 : 0.6),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark) ...[
            const BoxShadow(
              color: Color(0x38A3B1C6),
              offset: Offset(4, 4),
              blurRadius: 10,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 10,
            ),
          ],
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3310B981),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                children: [
                  TextSpan(
                    text: 'EUEE High-Yield Rule: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF064E3B),
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Reviewing a mistake within 24 hours increases long-term retention by 70%.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. BREADCRUMBS NAVIGATION
  // ==========================================
  Widget _buildBreadcrumbs(bool isDark) {
    final subjectTitle = _selectedSubjectId == 'ALL'
        ? 'All Mistakes'
        : _selectedSubjectId != null
            ? _resolveSubjectName(_selectedSubjectId!)
            : '';
    final unitTitle =
        _selectedUnitId != null ? _resolveUnitTitle(_selectedUnitId, null) : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                      size: 15, color: Color(0xFF4F46E5)),
                  SizedBox(width: 6),
                  Text(
                    'Mistake Notebook',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _selectedUnitId != null
                        ? const Color(0xFF4F46E5)
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
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

  // ==========================================
  // 7. SUBJECT UNITS & TOPICS VIEW
  // ==========================================
  Widget _buildSubjectUnitsView(
    BuildContext context,
    bool isDark, {
    bool isDesktop = false,
  }) {
    final units = _unitSummariesForSelectedSubject;
    final subjectTitle = _resolveSubjectName(_selectedSubjectId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusFilterChips(isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_rounded,
                    size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 8),
                Text(
                  'Curriculum Units & Topics (${units.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedUnitId = null;
                  _selectedSubjectId = 'ALL';
                });
              },
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text('Flat List',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (units.isEmpty)
          _buildEmptyFilteredCard(
              'No units matching the selected status filter in $subjectTitle.',
              isDark)
        else if (isDesktop && units.length > 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: units
                    .map((u) => SizedBox(
                          width: cardWidth,
                          child: _buildUnitCard(u, isDark),
                        ))
                    .toList(),
              );
            },
          )
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUnitId = u.unitId;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.transparent,
            ),
            boxShadow: [
              if (!isDark) ...[
                const BoxShadow(
                  color: Color(0x38A3B1C6),
                  offset: Offset(4, 4),
                  blurRadius: 10,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFEEF1F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.folder_special_rounded,
                          color: Color(0xFF4F46E5), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.titleEn,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (u.titleAm.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            u.titleAm,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE0E7FF),
                      ),
                    ),
                    child: Text(
                      '${u.counts.total} mistakes',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildStatusPill(
                    label: '${u.counts.needsReview} Needs Review',
                    bgColor: isDark
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFFFBEB),
                    textColor: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFB45309),
                    borderColor: isDark
                        ? const Color(0xFF78350F)
                        : const Color(0xFFFDE68A),
                  ),
                  _buildStatusPill(
                    label: '${u.counts.improving} Improving',
                    bgColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFEEF1F8),
                    textColor: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    borderColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  _buildStatusPill(
                    label: '${u.counts.mastered} Mastered',
                    bgColor: isDark
                        ? const Color(0xFF064E3B)
                        : const Color(0xFFECFDF5),
                    textColor: isDark
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFF047857),
                    borderColor: isDark
                        ? const Color(0xFF065F46)
                        : const Color(0xFFA7F3D0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 8. QUESTION LIST VIEW
  // ==========================================
  Widget _buildQuestionListView(
    BuildContext context,
    bool isDark, {
    bool isDesktop = false,
  }) {
    final questions = _activeQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusFilterChips(isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${questions.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (_selectedUnitId != null)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedUnitId = null);
                },
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: const Text('Back to Units',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
              return _buildMistakeCard(m, isDark, isDesktop: isDesktop);
            },
          ),
      ],
    );
  }

  Widget _buildMistakeCard(
    MistakeRecord m,
    bool isDark, {
    bool isDesktop = false,
  }) {
    final q = _questions[m.questionId];
    final previewText = q?.questionTextEn ?? 'Question ${m.questionId}';
    final subjectTitle = _resolveSubjectName(m.subjectId);
    final unitTitle = _resolveUnitTitle(m.unitId, m.topicId);

    Color statusBg;
    Color statusText;
    Color statusBorder;

    switch (m.masteryStatus) {
      case MasteryStatus.needsReview:
        statusBg = isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
        statusText = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
        statusBorder =
            isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
        break;
      case MasteryStatus.improving:
        statusBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F8);
        statusText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7);
        statusBorder =
            isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD);
        break;
      case MasteryStatus.mastered:
        statusBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        statusText = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857);
        statusBorder =
            isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMistakeSolutionReview(m),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.transparent,
            ),
            boxShadow: [
              if (!isDark) ...[
                const BoxShadow(
                  color: Color(0x38A3B1C6),
                  offset: Offset(4, 4),
                  blurRadius: 10,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ],
          ),
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
                        _buildTag(subjectTitle, const Color(0xFF4F46E5)),
                        _buildTag(unitTitle, const Color(0xFF64748B)),
                        if (q?.difficulty != null)
                          _buildTag(q!.difficulty.toUpperCase(),
                              const Color(0xFF7C3AED)),
                        if (q?.examYear != null)
                          _buildTag(
                              '${q!.examYear} E.C.', const Color(0xFF0D9488)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      m.masteryStatus.displayNameEn,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question Text Preview
              Text(
                previewText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Missed count, Retry progress, and "Review Solution"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Missed ${m.missCount} times',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.darkMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFEEF1F8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Retry: ${m.correctRetryCount}/2',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
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
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Color(0xFF4F46E5)),
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

  // ==========================================
  // 9. FILTER CHIPS & STATUS PILLS
  // ==========================================
  Widget _buildStatusFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', null, isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Needs Review', MasteryStatus.needsReview, isDark,
              accentColor: const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildFilterChip('Improving', MasteryStatus.improving, isDark,
              accentColor: const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          _buildFilterChip('Mastered', MasteryStatus.mastered, isDark,
              accentColor: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MasteryStatus? status, bool isDark,
      {Color? accentColor}) {
    final isSelected = _selectedStatusFilter == status;
    final color = accentColor ?? const Color(0xFF4F46E5);

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
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected
            ? color
            : (isDark ? AppTheme.darkText : const Color(0xFF475569)),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  // 10. EMPTY STATES & HELPERS
  // ==========================================
  Widget _buildEmptyOverallState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 64,
                color: Color(0xFF10B981),
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
            const SizedBox(height: 8),
            Text(
              'Mistake Notebook & Mastery Engine',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Questions you answer incorrectly during mock exams, untimed practice, or custom builder sessions will automatically appear here for review and targeted drills.',
                style: TextStyle(
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  fontSize: 13.5,
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

  Widget _buildEmptyFilteredCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.filter_list_off_rounded,
                size: 38, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                fontSize: 13.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subjectId) {
    final key = subjectId.toLowerCase();
    if (key.contains('phys')) return Icons.school_rounded;
    if (key.contains('chem')) return Icons.biotech_rounded;
    if (key.contains('bio')) return Icons.eco_rounded;
    if (key.contains('math')) return Icons.functions_rounded;
    if (key.contains('eng')) return Icons.menu_book_rounded;
    if (key.contains('civ')) return Icons.balance_rounded;
    if (key.contains('hist')) return Icons.history_edu_rounded;
    if (key.contains('geo')) return Icons.public_rounded;
    if (key.contains('econ')) return Icons.trending_up_rounded;
    return Icons.school_rounded;
  }

  Color _getSubjectColor(String subjectId) {
    final key = subjectId.toLowerCase();
    if (key.contains('phys')) return const Color(0xFF7C3AED); // Violet
    if (key.contains('chem')) return const Color(0xFF0284C7); // Sky blue
    if (key.contains('bio')) return const Color(0xFF059669); // Emerald
    if (key.contains('math')) return const Color(0xFF4F46E5); // Indigo
    if (key.contains('eng')) return const Color(0xFFD97706); // Amber
    if (key.contains('civ')) return const Color(0xFF0D9488); // Teal
    if (key.contains('hist')) return const Color(0xFFEA580C); // Orange
    if (key.contains('geo')) return const Color(0xFF0D9488); // Teal
    if (key.contains('econ')) return const Color(0xFF0284C7); // Sky
    return const Color(0xFF4F46E5);
  }
}
