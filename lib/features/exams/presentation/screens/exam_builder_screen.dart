import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
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
  // Theme Palette Tokens matching HTML / M3 Specification
  static const Color primarySpruce = Color(0xFF003527);
  static const Color primaryContainer = Color(0xFF064E3B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE932C);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color surfaceLight = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurfaceLight = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF404944);
  static const Color outlineVariant = Color(0xFFBFC9C3);

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
    2010,
    2011,
    2012,
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
    } else {
      if (mounted) setState(() => _isLoading = false);
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
        examYear:
            _yearMode == ExamYearFilterMode.single ? _selectedSingleYear : null,
        startYear:
            _yearMode == ExamYearFilterMode.range ? _rangeStartYear : null,
        endYear:
            _yearMode == ExamYearFilterMode.range ? _rangeEndYear : null,
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
      final modeLabel = _isTimed ? ' Timed Mock' : ' Practice';

      final title = '$gradeLabel${subject.nameEn}$unitLabel$yearLabel$modeLabel';

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

  IconData _getSubjectIcon(String? code, String? nameEn) {
    final name = (nameEn ?? '').toLowerCase();
    final c = (code ?? '').toLowerCase();
    if (name.contains('math') || c.contains('mat')) {
      return Icons.functions_rounded;
    }
    if (name.contains('phys') || c.contains('phy')) {
      return Icons.bolt_rounded;
    }
    if (name.contains('chem') || c.contains('chm')) {
      return Icons.biotech_rounded;
    }
    if (name.contains('bio') || c.contains('bio')) {
      return Icons.eco_rounded;
    }
    if (name.contains('eng') || c.contains('eng')) {
      return Icons.menu_book_rounded;
    }
    if (name.contains('hist') || c.contains('his')) {
      return Icons.history_edu_rounded;
    }
    if (name.contains('geog') || c.contains('geo')) {
      return Icons.public_rounded;
    }
    if (name.contains('civ') || c.contains('cit')) {
      return Icons.balance_rounded;
    }
    if (name.contains('econ') || c.contains('ecn')) {
      return Icons.trending_up_rounded;
    }
    return Icons.school_rounded;
  }

  Subject? get _selectedSubject {
    return _subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
  }

  Unit? get _selectedUnit {
    return _units.where((u) => u.id == _selectedUnitId).firstOrNull;
  }

  Topic? get _selectedTopic {
    return _topics.where((t) => t.id == _selectedTopicId).firstOrNull;
  }

  // ==========================================
  // 🎨 MODAL SELECTION SHEETS
  // ==========================================
  void _showGradePickerModal(BuildContext context, bool isDark) {
    final gradeOptions = [
      {'label': 'Grade 12 (Secondary / EUEE Scope)', 'value': 12, 'desc': 'Official Ethiopian University Entrance Exam target'},
      {'label': 'Grade 11 (Preparatory Scope)', 'value': 11, 'desc': 'Preparatory stream foundation curriculum'},
      {'label': 'Grade 10 (Secondary Completion)', 'value': 10, 'desc': 'General secondary completion scope'},
      {'label': 'Grade 9 (General Science & Foundations)', 'value': 9, 'desc': 'Secondary entrance & core basics'},
      {'label': 'All Grades (9-12 Comprehensive Examination)', 'value': null, 'desc': 'Comprehensive archive across all high school years'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Target Grade Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : onSurfaceLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...gradeOptions.map((opt) {
                  final val = opt['value'] as int?;
                  final label = opt['label'] as String;
                  final desc = opt['desc'] as String;
                  final isSelected = _selectedGrade == val;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? primaryContainer.withValues(alpha: 0.3)
                              : primaryContainer.withValues(alpha: 0.08))
                          : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? primaryContainer
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryContainer
                              : (isDark ? const Color(0xFF334155) : surfaceVariant),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : primaryContainer),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                      subtitle: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _onGradeChanged(val);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubjectPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Examination Subject',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _subjects.length,
                      itemBuilder: (context, idx) {
                        final s = _subjects[idx];
                        final isSelected = s.id == _selectedSubjectId;
                        final icon = _getSubjectIcon(s.code, s.nameEn);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? primaryContainer.withValues(alpha: 0.3)
                                    : primaryContainer.withValues(alpha: 0.08))
                                : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? primaryContainer
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: onPrimary, size: 24),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s.nameEn,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : onSurfaceLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${s.nameAm})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryContainer.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${s.code} · Grade ${s.grade}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                                : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(ctx);
                              _onSubjectChanged(s.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUnitPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Unit Coverage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // All Units Option
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _selectedUnitId == null
                                ? (isDark
                                    ? primaryContainer.withValues(alpha: 0.3)
                                    : primaryContainer.withValues(alpha: 0.08))
                                : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedUnitId == null
                                  ? primaryContainer
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.menu_book_rounded, color: onSurfaceLight, size: 20),
                            ),
                            title: Text(
                              'All Units (Comprehensive Examination)',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: _selectedUnitId == null ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : onSurfaceLight,
                              ),
                            ),
                            subtitle: Text(
                              'Chapters 1 to ${_units.length} included',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : onSurfaceVariant,
                              ),
                            ),
                            trailing: _selectedUnitId == null
                                ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              _onUnitChanged(null);
                            },
                          ),
                        ),
                        ..._units.map((u) {
                          final isSelected = u.id == _selectedUnitId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? primaryContainer.withValues(alpha: 0.3)
                                      : primaryContainer.withValues(alpha: 0.08))
                                  : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primaryContainer
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryContainer
                                      : (isDark ? const Color(0xFF334155) : surfaceVariant),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${u.unitNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : onSurfaceLight,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Unit ${u.unitNumber}: ${u.titleEn}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isDark ? Colors.white : onSurfaceLight,
                                ),
                              ),
                              subtitle: Text(
                                u.titleAm,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : onSurfaceVariant,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                                  : null,
                              onTap: () {
                                Navigator.pop(ctx);
                                _onUnitChanged(u.id);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTopicPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Specific Topic',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // All Topics option
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selectedTopicId == null
                      ? (isDark
                          ? primaryContainer.withValues(alpha: 0.3)
                          : primaryContainer.withValues(alpha: 0.08))
                      : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedTopicId == null
                        ? primaryContainer
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'All Topics in Selected Unit',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: _selectedTopicId == null ? FontWeight.bold : FontWeight.w600,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  trailing: _selectedTopicId == null
                      ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedTopicId = null);
                    _updateMatchingQuestionCount();
                  },
                ),
              ),
              ..._topics.map((t) {
                final isSelected = t.id == _selectedTopicId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? primaryContainer.withValues(alpha: 0.3)
                            : primaryContainer.withValues(alpha: 0.08))
                        : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primaryContainer
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      t.titleEn,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? Colors.white : onSurfaceLight,
                      ),
                    ),
                    subtitle: Text(
                      t.titleAm,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : onSurfaceVariant,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: primaryContainer)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedTopicId = t.id);
                      _updateMatchingQuestionCount();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showYearPickerModal(BuildContext context, bool isDark, {required bool isStartYear}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isStartYear ? 'Select Starting Year' : 'Select Ending Year',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableYears.map((yr) {
                  final isSelected = isStartYear ? _rangeStartYear == yr : _rangeEndYear == yr;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        if (isStartYear) {
                          _rangeStartYear = yr;
                          if (_rangeEndYear < yr) _rangeEndYear = yr;
                        } else {
                          _rangeEndYear = yr;
                          if (_rangeStartYear > yr) _rangeStartYear = yr;
                        }
                      });
                      _updateMatchingQuestionCount();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryContainer
                            : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryContainer : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$yr',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : onSurfaceLight),
                            ),
                          ),
                          Text(
                            'E.C.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : (isDark ? Colors.white60 : primarySpruce),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSingleYearPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select National Exam Year',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableYears.map((yr) {
                  final isSelected = _selectedSingleYear == yr;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedSingleYear = yr);
                      _updateMatchingQuestionCount();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryContainer
                            : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryContainer : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$yr',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : onSurfaceLight),
                            ),
                          ),
                          Text(
                            'E.C.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : (isDark ? Colors.white60 : primarySpruce),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 🖥️ SCREEN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B0F19) : surfaceLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Fixed Header Bar
            _buildTopFixedHeader(context, isDark),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryContainer))
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48.0 : 16.0,
                        vertical: 16.0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Page Title & Mode Switcher
                              _buildHeaderAndModeSwitcher(isDark),
                              const SizedBox(height: 16),

                              if (_errorMessage != null) ...[
                                _buildErrorBanner(),
                                const SizedBox(height: 16),
                              ],

                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 55,
                                      child: Column(
                                        children: [
                                          _buildCurriculumScopeCard(context, isDark),
                                          const SizedBox(height: 16),
                                          _buildPastPapersCard(context, isDark),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 45,
                                      child: Column(
                                        children: [
                                          _buildExamParametersCard(context, isDark),
                                          const SizedBox(height: 16),
                                          _buildSummaryConfirmationCard(isDark),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildCurriculumScopeCard(context, isDark),
                                const SizedBox(height: 16),
                                _buildPastPapersCard(context, isDark),
                                const SizedBox(height: 16),
                                _buildExamParametersCard(context, isDark),
                                const SizedBox(height: 16),
                                _buildSummaryConfirmationCard(isDark),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            // Sticky Primary CTA & Bottom Bar
            _buildStickyBottomBar(isDark),

            // 4-Tab Bottom Navigation Bar (Mobile)
            if (!isDesktop) _buildBottomNavigationBar(context, isDark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP FIXED HEADER
  // ==========================================
  Widget _buildTopFixedHeader(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: onPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FidelLearn',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : primarySpruce,
                    ),
                  ),
                  Text(
                    'EXCELLENCE PREP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: secondaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF111827) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: primarySpruce,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. HEADER & MODE SWITCHER
  // ==========================================
  Widget _buildHeaderAndModeSwitcher(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Exam Practice',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : onSurfaceLight,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'EUEE',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                '·',
                style: TextStyle(
                  color: isDark ? Colors.white38 : outlineVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Ministry Aligned Archive',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segmented Mode Switcher (Self-Paced vs Timed Exam)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : surfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isTimed = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !_isTimed
                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: !_isTimed
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          size: 18,
                          color: !_isTimed
                              ? (isDark ? const Color(0xFF6EE7B7) : primarySpruce)
                              : (isDark ? Colors.white60 : onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Self-Paced',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: !_isTimed ? FontWeight.w700 : FontWeight.w500,
                            color: !_isTimed
                                ? (isDark ? Colors.white : onSurfaceLight)
                                : (isDark ? Colors.white60 : onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isTimed = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _isTimed
                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: _isTimed
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: _isTimed
                              ? (isDark ? const Color(0xFF6EE7B7) : primarySpruce)
                              : (isDark ? Colors.white60 : onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Timed Exam',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: _isTimed ? FontWeight.w700 : FontWeight.w500,
                            color: _isTimed
                                ? (isDark ? Colors.white : onSurfaceLight)
                                : (isDark ? Colors.white60 : onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. STEP 1: CURRICULUM SCOPE CARD
  // ==========================================
  Widget _buildCurriculumScopeCard(BuildContext context, bool isDark) {
    final sub = _selectedSubject;
    final unit = _selectedUnit;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: primarySpruce,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Curriculum Scope',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Step 1 of 2',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Target Grade Level Selector
          Text(
            'Target Grade Level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showGradePickerModal(context, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: primaryContainer, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        _selectedGrade != null
                            ? 'Grade $_selectedGrade (Secondary / EUEE Scope)'
                            : 'All Grades (9-12 Scope)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: isDark ? Colors.white60 : onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Subject Selector Card
          Text(
            'Subject',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showSubjectPickerModal(context, isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getSubjectIcon(sub?.code, sub?.nameEn),
                            color: onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sub?.nameEn ?? 'Select Subject',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : onSurfaceLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (sub != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${sub.nameAm})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryContainer.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Core Subject · EUEE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF6EE7B7) : primaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white60 : onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Unit Coverage Selector
          Text(
            'Unit Coverage',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showUnitPickerModal(context, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : onSurfaceLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit != null
                                    ? 'Unit ${unit.unitNumber}: ${unit.titleEn}'
                                    : 'All Units (Comprehensive Examination)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : onSurfaceLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                unit != null
                                    ? unit.titleAm
                                    : 'Chapters 1 to ${_units.length} included',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: isDark ? Colors.white60 : onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // 4. Topic Coverage Selector (if unit selected & topics exist)
          if (_topics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Topic Coverage (ንዑስ ርዕስ)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showTopicPickerModal(context, isDark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.topic_outlined, size: 18, color: primaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedTopic?.titleEn ?? 'All Topics in Selected Unit',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : onSurfaceLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 4. STEP 2: PAST PAPERS ARCHIVE CARD
  // ==========================================
  Widget _buildPastPapersCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Past Papers',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Archive',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Step 2 of 2',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Mode Switcher (Year Range vs Single Year)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _yearMode = ExamYearFilterMode.range);
                      _updateMatchingQuestionCount();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _yearMode == ExamYearFilterMode.range
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _yearMode == ExamYearFilterMode.range
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Year Range',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _yearMode == ExamYearFilterMode.range
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _yearMode == ExamYearFilterMode.range
                                ? (isDark ? Colors.white : onSurfaceLight)
                                : (isDark ? Colors.white60 : onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _yearMode = ExamYearFilterMode.single);
                      _updateMatchingQuestionCount();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _yearMode == ExamYearFilterMode.single
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _yearMode == ExamYearFilterMode.single
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Single Year',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _yearMode == ExamYearFilterMode.single
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _yearMode == ExamYearFilterMode.single
                                ? (isDark ? Colors.white : onSurfaceLight)
                                : (isDark ? Colors.white60 : onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ethiopian Calendar Year Pickers
          if (_yearMode == ExamYearFilterMode.range)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showYearPickerModal(context, isDark, isStartYear: true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Year',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_rangeStartYear',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : onSurfaceLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'E.C.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: isDark ? Colors.white60 : onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showYearPickerModal(context, isDark, isStartYear: false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To Year',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_rangeEndYear',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : onSurfaceLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'E.C.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: isDark ? Colors.white60 : onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: () => _showSingleYearPickerModal(context, isDark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : surfaceContainerLow.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_selectedSingleYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : onSurfaceLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'E.C. National Examination',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Quick Preset Filter Chips (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickPresetChip(
                  label: 'Recent (2015-2017)',
                  startYear: 2015,
                  endYear: 2017,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickPresetChip(
                  label: '5-Year Archive',
                  startYear: 2013,
                  endYear: 2017,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickPresetChip(
                  label: 'All Verified (2010-2017)',
                  startYear: 2010,
                  endYear: 2017,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickPresetChip(
                  label: 'Pre-2015',
                  startYear: 2010,
                  endYear: 2014,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Matching Questions Indicator
          _buildLiveQuestionsIndicator(isDark),
        ],
      ),
    );
  }

  Widget _buildQuickPresetChip({
    required String label,
    required int startYear,
    required int endYear,
    required bool isDark,
  }) {
    final isActive = _yearMode == ExamYearFilterMode.range &&
        _rangeStartYear == startYear &&
        _rangeEndYear == endYear;

    return InkWell(
      onTap: () {
        setState(() {
          _yearMode = ExamYearFilterMode.range;
          _rangeStartYear = startYear;
          _rangeEndYear = endYear;
        });
        _updateMatchingQuestionCount();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? secondaryFixed
              : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? secondaryContainer : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? onSecondaryFixed
                : (isDark ? Colors.white70 : onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveQuestionsIndicator(bool isDark) {
    final hasQuestions = _matchingQuestionCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasQuestions
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFFFBEB)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasQuestions
              ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
              : (isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A)),
        ),
      ),
      child: Row(
        children: [
          if (_isCountingQuestions)
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryContainer),
            )
          else
            Icon(
              hasQuestions ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 17,
              color: hasQuestions ? const Color(0xFF059669) : const Color(0xFFD97706),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isCountingQuestions
                  ? 'Calculating matching questions in national archive...'
                  : (hasQuestions
                      ? '✓ $_matchingQuestionCount Verified Questions match your criteria'
                      : 'No questions match this combination. Try broadening the year range or units.'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasQuestions
                    ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                    : (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. STEP 3 / EXAM PARAMETERS CARD
  // ==========================================
  Widget _buildExamParametersCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: secondaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: secondaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Exam Parameters',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : onSurfaceLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Count Preset Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question Count',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_questionCount Questions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 20, 30, 50].map((preset) {
              final isSelected = _questionCount == preset;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () => setState(() => _questionCount = preset),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryContainer
                            : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$preset Qs',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryContainer,
              inactiveTrackColor: isDark ? const Color(0xFF334155) : surfaceContainerLow,
              thumbColor: primaryContainer,
              trackHeight: 4,
            ),
            child: Slider(
              value: _questionCount.toDouble().clamp(5.0, 50.0),
              min: 5,
              max: 50,
              divisions: 9,
              onChanged: (val) => setState(() => _questionCount = val.toInt()),
            ),
          ),

          // Timed Mode Settings
          if (_isTimed) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Limit',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : onSurfaceVariant,
                  ),
                ),
                Text(
                  '$_timeLimitMinutes min (${(_timeLimitMinutes * 60 ~/ _questionCount)}s / q)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryContainer,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: secondaryContainer,
                inactiveTrackColor: isDark ? const Color(0xFF334155) : surfaceContainerLow,
                thumbColor: secondaryContainer,
                trackHeight: 4,
              ),
              child: Slider(
                value: _timeLimitMinutes.toDouble(),
                min: 5,
                max: 90,
                divisions: 17,
                onChanged: (val) => setState(() => _timeLimitMinutes = val.toInt()),
              ),
            ),
          ],

          // Difficulty Selector
          const SizedBox(height: 10),
          Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDiffChip('All', null, isDark),
              const SizedBox(width: 6),
              _buildDiffChip('Easy', 'easy', isDark),
              const SizedBox(width: 6),
              _buildDiffChip('Medium', 'medium', isDark),
              const SizedBox(width: 6),
              _buildDiffChip('Hard', 'hard', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffChip(String label, String? val, bool isDark) {
    final isSelected = _selectedDifficulty == val;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedDifficulty = val);
          _updateMatchingQuestionCount();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryContainer
                : (isDark ? const Color(0xFF1E293B) : surfaceContainerLow),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. SUMMARY CONFIRMATION CARD
  // ==========================================
  Widget _buildSummaryConfirmationCard(bool isDark) {
    final sub = _selectedSubject;
    final subName = sub != null ? '${sub.nameEn} (Core Subject)' : 'All Subjects';
    final paperLabel = _yearMode == ExamYearFilterMode.range
        ? '$_rangeStartYear–$_rangeEndYear Past Papers'
        : '$_selectedSingleYear E.C. Past Paper';
    final modeLabel = _isTimed
        ? 'Timed Exam ($_questionCount Qs · $_timeLimitMinutes min)'
        : 'Self-Paced ($_questionCount Questions)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.8)
            : surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryContainer.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.task_alt_rounded, size: 18, color: primaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Your Practice',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF6EE7B7) : primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : surfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Curriculum',
            'Grade ${_selectedGrade ?? 12} · $subName',
            isDark,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Papers',
            paperLabel,
            isDark,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Practice Mode',
            modeLabel,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.white60 : onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurfaceLight,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. STICKY PRIMARY CTA & BOTTOM BAR
  // ==========================================
  Widget _buildStickyBottomBar(bool isDark) {
    final hasQuestions = _matchingQuestionCount > 0;
    final isDisabled = _isLoading || (!hasQuestions && !_isCountingQuestions);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827).withValues(alpha: 0.95) : surfaceLight.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isDisabled ? null : _startExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryContainer,
                foregroundColor: onPrimary,
                disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isTimed ? 'Start Timed Mock Exam' : 'Start Practice Exam',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_done_rounded,
                size: 15,
                color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
              ),
              const SizedBox(width: 4),
              Text(
                'Available offline',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : onSurfaceVariant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white38 : outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Icon(
                Icons.sync_rounded,
                size: 15,
                color: isDark ? const Color(0xFF6EE7B7) : primarySpruce,
              ),
              const SizedBox(width: 4),
              Text(
                'Auto-saved to device',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. 4-TAB BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar(BuildContext context, bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : surfaceContainerLowest.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : surfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isActive: false,
            onTap: () => context.go('/home'),
            isDark: isDark,
          ),
          _buildBottomNavItem(
            icon: Icons.edit_note_rounded,
            activeIcon: Icons.edit_note_rounded,
            label: 'Practice',
            isActive: true,
            onTap: () {}, // Already here
            isDark: isDark,
          ),
          _buildBottomNavItem(
            icon: Icons.military_tech_outlined,
            activeIcon: Icons.military_tech_rounded,
            label: 'Rewards',
            isActive: false,
            onTap: () => context.push('/rewards'),
            isDark: isDark,
          ),
          _buildBottomNavItem(
            icon: Icons.query_stats_rounded,
            activeIcon: Icons.query_stats_rounded,
            label: 'Progress',
            isActive: false,
            onTap: () => context.push('/progress'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? const Color(0xFF6EE7B7) : primaryContainer;
    final inactiveColor = isDark ? Colors.white54 : onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
