import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_button.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';

enum ExamYearFilterMode {
  range,
  single,
  all,
}

class ExamBuilderScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? mode; // 'mock' or 'custom'

  const ExamBuilderScreen({super.key, this.initialSubjectId, this.mode});

  @override
  ConsumerState<ExamBuilderScreen> createState() => _ExamBuilderScreenState();
}

class _ExamBuilderScreenState extends ConsumerState<ExamBuilderScreen> {
  // Curriculum Scope State
  int? _selectedGrade; // 9, 10, 11, 12, or null for all (9-12)
  List<Subject> _subjects = [];
  List<Unit> _units = [];
  List<Topic> _topics = [];

  String? _selectedSubjectId;
  String? _selectedUnitId;
  String? _selectedTopicId;
  String? _selectedDifficulty; // null = all

  // National Exam Year Selection
  ExamYearFilterMode _yearMode = ExamYearFilterMode.range;
  int _selectedSingleYear = 2014;
  int _rangeStartYear = 2013;
  int _rangeEndYear = 2017;
  final List<int> _availableYears = const [
    2013,
    2014,
    2015,
    2016,
    2017,
    2018,
    2019,
    2020,
    2021,
    2022,
    2023,
    2024,
  ];

  // Live Matching Questions Counter
  int _matchingQuestionCount = 0;
  bool _isCountingQuestions = false;

  // Exam Simulation Parameters
  int _questionCount = 10;
  bool _isTimed = false;
  int _timeLimitMinutes = 20;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isTimed = widget.mode == 'mock';
    if (_isTimed) _questionCount = 20;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);

    _selectedGrade = user?.grade ?? 12;

    if (user != null) {
      final subs = await contentRepo.getSubjects(
        grade: _selectedGrade,
        stream: user.stream,
      );
      if (mounted) {
        setState(() {
          _subjects = subs;
          if (subs.isNotEmpty) {
            _selectedSubjectId = widget.initialSubjectId ?? subs.first.id;
          }
          _isLoading = false;
        });
      }

      if (_selectedSubjectId != null) {
        await _loadUnitsAndTopics(_selectedSubjectId!);
      } else {
        await _updateMatchingQuestionCount();
      }
    }
  }

  Future<void> _onGradeChanged(int? grade) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);

    setState(() {
      _selectedGrade = grade;
      _selectedSubjectId = null;
      _selectedUnitId = null;
      _selectedTopicId = null;
      _units = [];
      _topics = [];
    });

    final subs = await contentRepo.getSubjects(
      grade: grade,
      stream: user?.stream ?? 'natural',
    );

    if (mounted) {
      setState(() {
        _subjects = subs;
        if (subs.isNotEmpty) {
          _selectedSubjectId = subs.first.id;
        }
      });
    }

    if (_selectedSubjectId != null) {
      await _loadUnitsAndTopics(_selectedSubjectId!);
    } else {
      await _updateMatchingQuestionCount();
    }
  }

  Future<void> _loadUnitsAndTopics(String subjectId) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final units = await contentRepo.getUnits(subjectId);
    if (mounted) {
      setState(() {
        _units = units;
        _selectedUnitId = null;
        _selectedTopicId = null;
        _topics = [];
      });
    }
    await _updateMatchingQuestionCount();
  }

  Future<void> _onSubjectChanged(String? subjectId) async {
    if (subjectId == null) return;
    setState(() => _selectedSubjectId = subjectId);
    await _loadUnitsAndTopics(subjectId);
  }

  Future<void> _onUnitChanged(String? unitId) async {
    setState(() {
      _selectedUnitId = unitId;
      _selectedTopicId = null;
    });

    if (unitId != null) {
      final contentRepo = ref.read(contentRepositoryProvider);
      final topics = await contentRepo.getTopics(unitId);
      if (mounted) {
        setState(() => _topics = topics);
      }
    } else {
      if (mounted) {
        setState(() => _topics = []);
      }
    }
    await _updateMatchingQuestionCount();
  }

  Future<void> _updateMatchingQuestionCount() async {
    if (_selectedSubjectId == null) {
      if (mounted) setState(() => _matchingQuestionCount = 0);
      return;
    }
    if (mounted) setState(() => _isCountingQuestions = true);
    final contentRepo = ref.read(contentRepositoryProvider);
    try {
      final qs = await contentRepo.getQuestions(
        grade: _selectedGrade,
        subjectId: _selectedSubjectId!,
        unitId: _selectedUnitId,
        topicId: _selectedTopicId,
        difficulty: _selectedDifficulty,
        examYear: _yearMode == ExamYearFilterMode.single ? _selectedSingleYear : null,
        startYear: _yearMode == ExamYearFilterMode.range ? _rangeStartYear : null,
        endYear: _yearMode == ExamYearFilterMode.range ? _rangeEndYear : null,
      );
      if (mounted) {
        setState(() {
          _matchingQuestionCount = qs.length;
          _isCountingQuestions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCountingQuestions = false);
      }
    }
  }

  Future<void> _startExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    if (user == null || _selectedSubjectId == null) return;

    try {
      final questions = await contentRepo.getQuestions(
        grade: _selectedGrade,
        subjectId: _selectedSubjectId!,
        unitId: _selectedUnitId,
        topicId: _selectedTopicId,
        difficulty: _selectedDifficulty,
        examYear:
            _yearMode == ExamYearFilterMode.single ? _selectedSingleYear : null,
        startYear:
            _yearMode == ExamYearFilterMode.range ? _rangeStartYear : null,
        endYear:
            _yearMode == ExamYearFilterMode.range ? _rangeEndYear : null,
      );

      if (questions.isEmpty) {
        setState(() {
          _errorMessage =
              'No questions match the selected criteria. Try selecting all units, broadening the year range (e.g. 2013-2017), or clearing difficulty.';
          _isLoading = false;
        });
        return;
      }

      final count =
          questions.length < _questionCount ? questions.length : _questionCount;

      final shuffled = List<Question>.from(questions)..shuffle();
      final selectedQuestions = shuffled.sublist(0, count);

      final subject = _subjects.firstWhere(
        (s) => s.id == _selectedSubjectId,
        orElse: () => Subject(
          id: _selectedSubjectId!,
          code: 'SUBJ',
          nameEn: 'Practice Subject',
          nameAm: 'የትምህርት ዓይነት',
          grade: _selectedGrade ?? 12,
          stream: user.stream,
          sortOrder: 1,
        ),
      );

      // Build descriptive exam title
      final gradeLabel = _selectedGrade != null
          ? 'Grade $_selectedGrade '
          : 'Grades 9-12 ';
      final unitObj =
          _units.where((u) => u.id == _selectedUnitId).firstOrNull;
      final unitLabel = unitObj != null ? ' (Unit ${unitObj.unitNumber})' : '';
      final yearLabel = _yearMode == ExamYearFilterMode.range
          ? ' [$_rangeStartYear-$_rangeEndYear E.C.]'
          : (_yearMode == ExamYearFilterMode.single
              ? ' [$_selectedSingleYear E.C.]'
              : '');
      final modeLabel =
          _isTimed ? ' Timed Mock' : ' Practice';

      final title =
          '$gradeLabel${subject.nameEn}$unitLabel$yearLabel$modeLabel';

      final exam = Exam(
        id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        examType: _isTimed ? ExamType.mockFull : ExamType.customBuilder,
        grade: _selectedGrade ?? user.grade,
        stream: user.stream,
        subjectId: _selectedSubjectId,
        timeLimitMinutes: _isTimed ? _timeLimitMinutes : 0,
        totalQuestions: selectedQuestions.length,
        questions: selectedQuestions,
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        exam: exam,
      );

      await examRepo.saveActiveAttempt(attempt);

      if (mounted) {
        await context
            .push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isTimed ? 'Timed National Mock Exam' : 'Custom National Exam Practice',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brand))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode Selector Pill (Practice vs Mock)
                      _buildModeSelector(isDark),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppTheme.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 55,
                              child: _buildCurriculumCard(context, isDark),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 45,
                              child:
                                  _buildSimulationSettingsCard(context, isDark),
                            ),
                          ],
                        )
                      else ...[
                        _buildCurriculumCard(context, isDark),
                        const SizedBox(height: 20),
                        _buildSimulationSettingsCard(context, isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isTimed = false),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isTimed
                      ? (isDark ? AppTheme.brandStrong : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  boxShadow: !_isTimed
                      ? (isDark
                          ? AppTheme.cardShadowDark
                          : AppTheme.cardShadowLight)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 18,
                        color: !_isTimed
                            ? (isDark ? Colors.white : AppTheme.brandStrong)
                            : (isDark
                                ? AppTheme.darkMuted
                                : AppTheme.lightMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Self-Paced Practice',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              !_isTimed ? FontWeight.w700 : FontWeight.w500,
                          color: !_isTimed
                              ? (isDark ? Colors.white : AppTheme.brandStrong)
                              : (isDark
                                  ? AppTheme.darkMuted
                                  : AppTheme.lightMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isTimed = true),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isTimed
                      ? (isDark ? AppTheme.brandStrong : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  boxShadow: _isTimed
                      ? (isDark
                          ? AppTheme.cardShadowDark
                          : AppTheme.cardShadowLight)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: _isTimed
                            ? (isDark ? Colors.white : AppTheme.brandStrong)
                            : (isDark
                                ? AppTheme.darkMuted
                                : AppTheme.lightMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Timed National Mock',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              _isTimed ? FontWeight.w700 : FontWeight.w500,
                          color: _isTimed
                              ? (isDark ? Colors.white : AppTheme.brandStrong)
                              : (isDark
                                  ? AppTheme.darkMuted
                                  : AppTheme.lightMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard(BuildContext context, bool isDark) {
    return FidelCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppTheme.brand, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Curriculum & Exam Scope',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ],
              ),
              const FidelBadge(
                text: 'Secondary 9-12',
                variant: FidelBadgeVariant.primary,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Grade Selector (9-12)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curriculum Grade (ክፍል)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                ),
              ),
              Text(
                'National Exam Scope',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGradeSelector(isDark),
          const SizedBox(height: 18),

          // 2. Subject Selector
          Text(
            'Target Subject (የትምህርት ዓይነት)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedSubjectId,
            items: _subjects.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text('${s.nameEn} (${s.nameAm}) - ${s.code}',
                    overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _onSubjectChanged,
            decoration:
                const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
          ),
          const SizedBox(height: 18),

          // 3. Unit Filter
          Text(
            'Curriculum Unit (ምዕራፍ)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            value: _selectedUnitId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Units (Comprehensive Examination)',
                    overflow: TextOverflow.ellipsis),
              ),
              ..._units.map(
                (u) => DropdownMenuItem(
                  value: u.id,
                  child: Text('Unit ${u.unitNumber}: ${u.titleEn} (${u.titleAm})',
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _onUnitChanged,
            decoration:
                const InputDecoration(prefixIcon: Icon(Icons.layers_outlined)),
          ),
          const SizedBox(height: 18),

          // 4. Specific Topic (if unit selected & topics exist)
          if (_topics.isNotEmpty) ...[
            Text(
              'Specific Topic (ንዑስ ርዕስ)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              value: _selectedTopicId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Topics in Selected Unit',
                      overflow: TextOverflow.ellipsis),
                ),
                ..._topics.map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.titleEn, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedTopicId = val);
                _updateMatchingQuestionCount();
              },
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.topic_outlined)),
            ),
            const SizedBox(height: 18),
          ],

          // 5. National Examination Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'National Exam Year (የፈተና ዓመት)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                ),
              ),
              const FidelBadge(
                text: 'Archive Filter',
                variant: FidelBadgeVariant.neutral,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildYearModePills(isDark),
          const SizedBox(height: 12),
          _buildYearSelectorContent(isDark),
          const SizedBox(height: 18),

          // 6. Difficulty Selector
          Text(
            'Difficulty Level',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDifficultyChip('All', null, isDark),
              const SizedBox(width: 8),
              _buildDifficultyChip('Easy', 'easy', isDark),
              const SizedBox(width: 8),
              _buildDifficultyChip('Medium', 'medium', isDark),
              const SizedBox(width: 8),
              _buildDifficultyChip('Hard', 'hard', isDark),
            ],
          ),
          const SizedBox(height: 18),

          // 7. Live Matching Questions Counter Badge
          _buildLiveQuestionsIndicator(isDark),
        ],
      ),
    );
  }

  Widget _buildGradeSelector(bool isDark) {
    final gradeOptions = [
      {'label': 'Grade 9', 'value': 9},
      {'label': 'Grade 10', 'value': 10},
      {'label': 'Grade 11', 'value': 11},
      {'label': 'Grade 12', 'value': 12},
      {'label': 'All (9-12)', 'value': null},
    ];

    return Row(
      children: gradeOptions.map((opt) {
        final val = opt['value'] as int?;
        final label = opt['label'] as String;
        final isSelected = _selectedGrade == val;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: InkWell(
              onTap: () => _onGradeChanged(val),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppTheme.brand.withValues(alpha: 0.25)
                          : AppTheme.brandSubtle)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.brand
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppTheme.brandStrong)
                          : (isDark
                              ? AppTheme.darkTextSoft
                              : AppTheme.lightTextSoft),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearModePills(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          _buildYearModeOption(
            label: 'Year Range (ክልል)',
            mode: ExamYearFilterMode.range,
            isDark: isDark,
          ),
          _buildYearModeOption(
            label: 'Single Year (አንድ ዓመት)',
            mode: ExamYearFilterMode.single,
            isDark: isDark,
          ),
          _buildYearModeOption(
            label: 'All Years (ሁሉም)',
            mode: ExamYearFilterMode.all,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildYearModeOption({
    required String label,
    required ExamYearFilterMode mode,
    required bool isDark,
  }) {
    final isSelected = _yearMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _yearMode = mode);
          _updateMatchingQuestionCount();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.brandStrong : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
            boxShadow: isSelected
                ? (isDark
                    ? AppTheme.cardShadowDark
                    : AppTheme.cardShadowLight)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.brandStrong)
                    : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelectorContent(bool isDark) {
    if (_yearMode == ExamYearFilterMode.range) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From Year (ከዓመተ ምሕረት)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _rangeStartYear,
                      items: _availableYears.map((yr) {
                        return DropdownMenuItem(
                          value: yr,
                          child: Text('$yr E.C.'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rangeStartYear = val;
                            if (_rangeEndYear < val) _rangeEndYear = val;
                          });
                          _updateMatchingQuestionCount();
                        }
                      },
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                child: Text('→',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To Year (እስከ ዓመተ ምሕረት)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _rangeEndYear,
                      items: _availableYears.map((yr) {
                        return DropdownMenuItem(
                          value: yr,
                          child: Text('$yr E.C.'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rangeEndYear = val;
                            if (_rangeStartYear > val) _rangeStartYear = val;
                          });
                          _updateMatchingQuestionCount();
                        }
                      },
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildYearPresetChip('2013 - 2017 (5-Year Retrospective)', 2013, 2017, isDark),
              _buildYearPresetChip('2018 - 2021', 2018, 2021, isDark),
              _buildYearPresetChip('2022 - 2024 (Latest)', 2022, 2024, isDark),
            ],
          ),
        ],
      );
    } else if (_yearMode == ExamYearFilterMode.single) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Examination Year',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _selectedSingleYear,
            items: _availableYears.map((yr) {
              return DropdownMenuItem(
                value: yr,
                child: Text('ESSLCE $yr E.C. National Examination'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSingleYear = val);
                _updateMatchingQuestionCount();
              }
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.event_note_rounded),
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.brand.withValues(alpha: 0.12)
              : AppTheme.brandSubtle,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isDark
                ? AppTheme.brand.withValues(alpha: 0.3)
                : AppTheme.brandSubtle,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_edu_rounded,
                size: 18, color: AppTheme.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Includes questions across all archived Ethiopian national examination series (2013–2024 E.C.).',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSoft : AppTheme.brandStrong,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildYearPresetChip(
      String label, int start, int end, bool isDark) {
    final isActive = _rangeStartYear == start && _rangeEndYear == end;
    return InkWell(
      onTap: () {
        setState(() {
          _rangeStartYear = start;
          _rangeEndYear = end;
        });
        _updateMatchingQuestionCount();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppTheme.brand.withValues(alpha: 0.25)
                  : AppTheme.brandSubtle)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isActive
                ? AppTheme.brand
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : AppTheme.brandStrong)
                : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveQuestionsIndicator(bool isDark) {
    final hasQuestions = _matchingQuestionCount > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: hasQuestions
            ? (isDark
                ? AppTheme.green.withValues(alpha: 0.12)
                : const Color(0xFFECFDF5))
            : (isDark
                ? AppTheme.accent.withValues(alpha: 0.12)
                : const Color(0xFFFFFBEB)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: hasQuestions
              ? AppTheme.green.withValues(alpha: 0.35)
              : AppTheme.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          if (_isCountingQuestions)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brand,
              ),
            )
          else
            Icon(
              hasQuestions
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              size: 18,
              color: hasQuestions ? AppTheme.green : AppTheme.accent,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCountingQuestions
                  ? 'Calculating matching questions in national archive...'
                  : (hasQuestions
                      ? '✓ $_matchingQuestionCount Verified Questions match your custom criteria'
                      : 'No questions match this combination. Try selecting all units or expanding the year range.'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: hasQuestions
                    ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                    : (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, String? value, bool isDark) {
    final isSelected = _selectedDifficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedDifficulty = value);
          _updateMatchingQuestionCount();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0x334F46E5) : const Color(0xFFEEF2FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected
                  ? AppTheme.brand
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.brandStrong)
                    : (isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationSettingsCard(BuildContext context, bool isDark) {
    return FidelCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Exam Parameters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Question Count Preset Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question Count',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                ),
              ),
              FidelBadge(
                text: '$_questionCount Questions',
                variant: FidelBadgeVariant.primary,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [5, 10, 20, 30].map((preset) {
              final isSelected = _questionCount == preset;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _questionCount = preset),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0x334F46E5)
                                : const Color(0xFFEEF2FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.brand
                              : (isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$preset Qs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppTheme.brandStrong)
                                : (isDark
                                    ? AppTheme.darkTextSoft
                                    : AppTheme.lightTextSoft),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Slider for fine tuning
          Slider(
            value: _questionCount.toDouble().clamp(5.0, 50.0),
            min: 5,
            max: 50,
            divisions: 9,
            label: '$_questionCount Qs',
            activeColor: AppTheme.brand,
            onChanged: (val) => setState(() => _questionCount = val.toInt()),
          ),
          const SizedBox(height: 14),

          // Timed Mode Settings
          if (_isTimed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Limit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                        isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                  ),
                ),
                Flexible(
                  child: Text(
                    '$_timeLimitMinutes min (${(_timeLimitMinutes * 60 ~/ _questionCount)}s / q)',
                    style: const TextStyle(
                      color: AppTheme.accentDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Slider(
              value: _timeLimitMinutes.toDouble(),
              min: 5,
              max: 90,
              divisions: 17,
              label: '$_timeLimitMinutes min',
              activeColor: AppTheme.accent,
              onChanged: (val) =>
                  setState(() => _timeLimitMinutes = val.toInt()),
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 16),

          // Start CTA Button
          FidelButton(
            label:
                _isTimed ? 'Launch Timed Mock Exam' : 'Start Practice Session',
            icon: Icons.play_arrow_rounded,
            onPressed: _startExam,
            isFullWidth: true,
            height: 48,
          ),
        ],
      ),
    );
  }
}
