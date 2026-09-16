import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/data/repositories/local_content_repository.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';

enum ExamYearFilterMode {
  range,
  single,
  all,
}

class _ExamBuilderTheme {
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color accent;
  final Color gradientStart;
  final Color gradientEnd;
  final Color surfaceTint;
  final String symbol;
  final IconData icon;

  const _ExamBuilderTheme({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.accent,
    required this.gradientStart,
    required this.gradientEnd,
    required this.surfaceTint,
    required this.symbol,
    required this.icon,
  });
}

class ExamBuilderScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? mode; // 'mock' or 'custom'

  const ExamBuilderScreen({super.key, this.initialSubjectId, this.mode});

  @override
  ConsumerState<ExamBuilderScreen> createState() => _ExamBuilderScreenState();
}

class _ExamBuilderScreenState extends ConsumerState<ExamBuilderScreen> {
  // Base Palette Tokens matching HTML / M3 Specification
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE932C);
  static const Color surfaceLight = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurfaceLight = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF404944);
  static const Color outlineVariant = Color(0xFFBFC9C3);

  // Dynamic Subject Theme Resolution
  _ExamBuilderTheme _resolveTheme(Subject? subject) {
    if (subject == null) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF003527),
        primaryContainer: Color(0xFF064E3B),
        onPrimary: Colors.white,
        accent: Color(0xFF10B981),
        gradientStart: Color(0xFF003527),
        gradientEnd: Color(0xFF064E3B),
        surfaceTint: Color(0xFFECFDF5),
        symbol: '🎓',
        icon: Icons.school_rounded,
      );
    }

    final key = '${subject.id} ${subject.code} ${subject.nameEn}'.toLowerCase();
    if (key.contains('math')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF4F46E5),
        primaryContainer: Color(0xFF3730A3),
        onPrimary: Colors.white,
        accent: Color(0xFF6366F1),
        gradientStart: Color(0xFF4F46E5),
        gradientEnd: Color(0xFF312E81),
        surfaceTint: Color(0xFFEEF2FF),
        symbol: '∑',
        icon: Icons.functions_rounded,
      );
    } else if (key.contains('bio')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF059669),
        primaryContainer: Color(0xFF064E3B),
        onPrimary: Colors.white,
        accent: Color(0xFF10B981),
        gradientStart: Color(0xFF059669),
        gradientEnd: Color(0xFF064E3B),
        surfaceTint: Color(0xFFECFDF5),
        symbol: '🧬',
        icon: Icons.biotech_rounded,
      );
    } else if (key.contains('phys')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF2563EB),
        primaryContainer: Color(0xFF1E3A8A),
        onPrimary: Colors.white,
        accent: Color(0xFF3B82F6),
        gradientStart: Color(0xFF2563EB),
        gradientEnd: Color(0xFF1E3A8A),
        surfaceTint: Color(0xFFEFF6FF),
        symbol: '⚡',
        icon: Icons.bolt_rounded,
      );
    } else if (key.contains('chem')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF9333EA),
        primaryContainer: Color(0xFF581C87),
        onPrimary: Colors.white,
        accent: Color(0xFFA855F7),
        gradientStart: Color(0xFF9333EA),
        gradientEnd: Color(0xFF581C87),
        surfaceTint: Color(0xFFFAF5FF),
        symbol: '🧪',
        icon: Icons.science_rounded,
      );
    } else if (key.contains('eng')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFFD97706),
        primaryContainer: Color(0xFF78350F),
        onPrimary: Colors.white,
        accent: Color(0xFFF59E0B),
        gradientStart: Color(0xFFD97706),
        gradientEnd: Color(0xFF78350F),
        surfaceTint: Color(0xFFFEF3C7),
        symbol: '📖',
        icon: Icons.menu_book_rounded,
      );
    } else if (key.contains('hist')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFFEA580C),
        primaryContainer: Color(0xFF7C2D12),
        onPrimary: Colors.white,
        accent: Color(0xFFF97316),
        gradientStart: Color(0xFFEA580C),
        gradientEnd: Color(0xFF7C2D12),
        surfaceTint: Color(0xFFFFF7ED),
        symbol: '🏛️',
        icon: Icons.history_edu_rounded,
      );
    } else if (key.contains('geo')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF0D9488),
        primaryContainer: Color(0xFF134E4A),
        onPrimary: Colors.white,
        accent: Color(0xFF14B8A6),
        gradientStart: Color(0xFF0D9488),
        gradientEnd: Color(0xFF134E4A),
        surfaceTint: Color(0xFFF0FDFA),
        symbol: '🌍',
        icon: Icons.public_rounded,
      );
    } else if (key.contains('econ')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF0284C7),
        primaryContainer: Color(0xFF0C4A6E),
        onPrimary: Colors.white,
        accent: Color(0xFF0EA5E9),
        gradientStart: Color(0xFF0284C7),
        gradientEnd: Color(0xFF0C4A6E),
        surfaceTint: Color(0xFFF0F9FF),
        symbol: '📈',
        icon: Icons.trending_up_rounded,
      );
    } else if (key.contains('civ')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFF475569),
        primaryContainer: Color(0xFF1E293B),
        onPrimary: Colors.white,
        accent: Color(0xFF64748B),
        gradientStart: Color(0xFF475569),
        gradientEnd: Color(0xFF1E293B),
        surfaceTint: Color(0xFFF8FAFC),
        symbol: '⚖️',
        icon: Icons.balance_rounded,
      );
    } else if (key.contains('apt')) {
      return const _ExamBuilderTheme(
        primary: Color(0xFFE11D48),
        primaryContainer: Color(0xFF881337),
        onPrimary: Colors.white,
        accent: Color(0xFFF43F5E),
        gradientStart: Color(0xFFE11D48),
        gradientEnd: Color(0xFF881337),
        surfaceTint: Color(0xFFFFF1F2),
        symbol: '💡',
        icon: Icons.lightbulb_rounded,
      );
    } else {
      return const _ExamBuilderTheme(
        primary: Color(0xFF003527),
        primaryContainer: Color(0xFF064E3B),
        onPrimary: Colors.white,
        accent: Color(0xFF10B981),
        gradientStart: Color(0xFF003527),
        gradientEnd: Color(0xFF064E3B),
        surfaceTint: Color(0xFFECFDF5),
        symbol: '🎓',
        icon: Icons.school_rounded,
      );
    }
  }

  Subject? get _selectedSubject =>
      _subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;

  _ExamBuilderTheme get _currentTheme => _resolveTheme(_selectedSubject);
  Color get activePrimary => _currentTheme.primary;
  Color get activeContainer => _currentTheme.primaryContainer;
  Color get activeAccent => _currentTheme.accent;
  Color get activeSurfaceTint => _currentTheme.surfaceTint;
  String get activeSymbol => _currentTheme.symbol;
  IconData get activeIcon => _currentTheme.icon;

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
    2025,
    2026,
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

  @override
  void didUpdateWidget(covariant ExamBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubjectId != widget.initialSubjectId ||
        oldWidget.mode != widget.mode) {
      if (widget.mode == 'mock') {
        _isTimed = true;
        _questionCount = 20;
      }
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final contentRepo = ref.read(contentRepositoryProvider);

      int targetGrade = user?.grade ?? 12;
      if (widget.initialSubjectId != null &&
          widget.initialSubjectId!.trim().isNotEmpty) {
        final match = RegExp(r'(?:g|grade)(\d+)', caseSensitive: false)
            .firstMatch(widget.initialSubjectId!);
        if (match != null) {
          final parsed = int.tryParse(match.group(1)!);
          if (parsed != null && parsed >= 6 && parsed <= 12) {
            targetGrade = parsed;
          }
        }
      }
      _selectedGrade = targetGrade;

      // Determine stream: social vs natural based on target subject or user stream
      String stream = user?.stream ?? 'natural';
      if (widget.initialSubjectId != null &&
          widget.initialSubjectId!.trim().isNotEmpty) {
        final rawId = widget.initialSubjectId!.toLowerCase();
        if (rawId.contains('hist') ||
            rawId.contains('geo') ||
            rawId.contains('econ')) {
          stream = 'social';
        } else if (rawId.contains('bio') ||
            rawId.contains('phys') ||
            rawId.contains('chem')) {
          stream = 'natural';
        }
      }

      List<Subject> subs = [];
      try {
        subs = await contentRepo.getSubjects(
          grade: _selectedGrade,
          stream: stream,
        );
      } catch (e) {
        debugPrint('ExamBuilderScreen: getSubjects error: $e');
      }

      // Merge with standard default subjects for this grade so subjects are never missing
      final defaultSubs = LocalContentRepository.getAllDefaultSubjects(
          grade: _selectedGrade ?? 12);
      final existingIds = subs.map((s) => s.id.toLowerCase()).toSet();
      final existingNames = subs.map((s) => s.nameEn.toLowerCase()).toSet();
      for (final def in defaultSubs) {
        if (!existingIds.contains(def.id.toLowerCase()) &&
            !existingNames.contains(def.nameEn.toLowerCase())) {
          if (def.stream == stream ||
              def.stream == 'common' ||
              def.stream == 'general') {
            subs.add(def);
          }
        }
      }
      subs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      Subject? matched;
      if (widget.initialSubjectId != null &&
          widget.initialSubjectId!.trim().isNotEmpty) {
        final qId = widget.initialSubjectId!.trim().toLowerCase();

        // 1. Exact ID match in subs
        matched = subs.where((s) => s.id.toLowerCase() == qId).firstOrNull;

        // 2. Canonical subject ID match in subs
        matched ??= subs
            .where((s) => LocalContentRepository.matchesSubjectId(
                s.id, widget.initialSubjectId!))
            .firstOrNull;

        // 3. Discipline match in subs
        matched ??= subs
            .where((s) => LocalContentRepository.matchesSubjectDiscipline(
                s.id, widget.initialSubjectId!))
            .firstOrNull;

        // 4. Code or name substring in subs
        matched ??= subs
            .where((s) =>
                s.code.toLowerCase() == qId ||
                s.nameEn.toLowerCase().contains(qId))
            .firstOrNull;

        // 5. Search in all default subjects regardless of stream
        matched ??= defaultSubs
            .where((s) =>
                s.id.toLowerCase() == qId ||
                LocalContentRepository.matchesSubjectId(
                    s.id, widget.initialSubjectId!) ||
                LocalContentRepository.matchesSubjectDiscipline(
                    s.id, widget.initialSubjectId!) ||
                s.code.toLowerCase() == qId ||
                s.nameEn.toLowerCase().contains(qId))
            .firstOrNull;

        // 6. Synthesize from widget.initialSubjectId if still not found
        matched ??= LocalContentRepository.resolveDefaultSubject(
          widget.initialSubjectId!,
          grade: _selectedGrade ?? 12,
          stream: stream,
        );

        // Ensure the matched subject exists in _subjects list so picker reflects it
        final targetSubject = matched;
        if (!subs.any((s) => s.id == targetSubject.id)) {
          subs.insert(0, targetSubject);
        }
      }

      // CRITICAL: Only fall back to subs.first if NO initialSubjectId was provided!
      if (matched == null && subs.isNotEmpty) {
        matched = subs.first;
      }

      final chosenSubjectId = matched?.id ??
          (widget.initialSubjectId != null &&
                  widget.initialSubjectId!.trim().isNotEmpty
              ? widget.initialSubjectId
              : null);

      if (mounted) {
        setState(() {
          _subjects = subs;
          _selectedSubjectId = chosenSubjectId;
          _isLoading = false;
        });
      }

      if (_selectedSubjectId != null) {
        await _loadUnitsAndTopics(_selectedSubjectId!);
      } else {
        await _updateMatchingQuestionCount();
      }
    } catch (e) {
      debugPrint('ExamBuilderScreen: _loadInitialData failure: $e');
      if (mounted) {
        setState(() {
          if (widget.initialSubjectId != null &&
              widget.initialSubjectId!.trim().isNotEmpty) {
            final fallbackSub = LocalContentRepository.resolveDefaultSubject(
              widget.initialSubjectId!,
              grade: _selectedGrade ?? 12,
            );
            _subjects = [fallbackSub];
            _selectedSubjectId = fallbackSub.id;
          }
          _isLoading = false;
        });
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

    final stream = user?.stream ?? 'natural';
    List<Subject> subs = [];
    try {
      subs = await contentRepo.getSubjects(
        grade: grade,
        stream: stream,
      );
    } catch (_) {}

    final defaultSubs =
        LocalContentRepository.getAllDefaultSubjects(grade: grade ?? 12);
    final existingIds = subs.map((s) => s.id.toLowerCase()).toSet();
    for (final def in defaultSubs) {
      if (!existingIds.contains(def.id.toLowerCase())) {
        if (def.stream == stream ||
            def.stream == 'common' ||
            def.stream == 'general') {
          subs.add(def);
        }
      }
    }
    subs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
    List<Unit> units = [];
    try {
      units = await contentRepo.getUnits(subjectId);
    } catch (_) {}

    if (units.isEmpty) {
      units = LocalContentRepository.getDefaultUnits(subjectId);
    }

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
        endYear: _yearMode == ExamYearFilterMode.range ? _rangeEndYear : null,
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

      final gradeLabel =
          _selectedGrade != null ? 'Grade $_selectedGrade ' : 'Grades 9-12 ';
      final unitObj = _units.where((u) => u.id == _selectedUnitId).firstOrNull;
      final unitLabel = unitObj != null ? ' (Unit ${unitObj.unitNumber})' : '';
      final yearLabel = _yearMode == ExamYearFilterMode.range
          ? ' [$_rangeStartYear-$_rangeEndYear E.C.]'
          : (_yearMode == ExamYearFilterMode.single
              ? ' [$_selectedSingleYear E.C.]'
              : '');
      final modeLabel = _isTimed ? ' Timed Mock' : ' Practice';

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
      {
        'label': 'Grade 12 (Secondary / EUEE Scope)',
        'value': 12,
        'desc': 'Official Ethiopian University Entrance Exam target'
      },
      {
        'label': 'Grade 11 (Preparatory Scope)',
        'value': 11,
        'desc': 'Preparatory stream foundation curriculum'
      },
      {
        'label': 'Grade 10 (Secondary Completion)',
        'value': 10,
        'desc': 'General secondary completion scope'
      },
      {
        'label': 'Grade 9 (General Science & Foundations)',
        'value': 9,
        'desc': 'Secondary entrance & core basics'
      },
      {
        'label': 'All Grades (9-12 Comprehensive Examination)',
        'value': null,
        'desc': 'Comprehensive archive across all high school years'
      },
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
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
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
                              ? activePrimary.withValues(alpha: 0.25)
                              : activeSurfaceTint)
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : surfaceContainerLow.withValues(alpha: 0.7)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? activePrimary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activePrimary
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : surfaceVariant),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : activePrimary),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
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
                          ? Icon(Icons.check_circle_rounded,
                              color: activePrimary)
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
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
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
                        final sTheme = _resolveTheme(s);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? sTheme.primary.withValues(alpha: 0.25)
                                    : sTheme.surfaceTint)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : surfaceContainerLow.withValues(
                                        alpha: 0.7)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? sTheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: sTheme.symbol.isNotEmpty &&
                                        sTheme.symbol.length <= 2
                                    ? Text(
                                        sTheme.symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      )
                                    : Icon(icon, color: onPrimary, size: 24),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s.nameEn,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : onSurfaceLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${s.nameAm})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : onSurfaceVariant,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sTheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${s.code} · Grade ${s.grade}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? sTheme.accent
                                            : sTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: sTheme.primary)
                                : const Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey),
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
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
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
                                    ? activePrimary.withValues(alpha: 0.25)
                                    : activeSurfaceTint)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : surfaceContainerLow.withValues(
                                        alpha: 0.7)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedUnitId == null
                                  ? activePrimary
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
                              child: const Icon(Icons.menu_book_rounded,
                                  color: onSurfaceLight, size: 20),
                            ),
                            title: Text(
                              'All Units (Comprehensive Examination)',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: _selectedUnitId == null
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isDark ? Colors.white : onSurfaceLight,
                              ),
                            ),
                            subtitle: Text(
                              'Chapters 1 to ${_units.length} included',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white60 : onSurfaceVariant,
                              ),
                            ),
                            trailing: _selectedUnitId == null
                                ? Icon(Icons.check_circle_rounded,
                                    color: activePrimary)
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
                                      ? activePrimary.withValues(alpha: 0.25)
                                      : activeSurfaceTint)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : surfaceContainerLow.withValues(
                                          alpha: 0.7)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? activePrimary
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
                                      ? activePrimary
                                      : (isDark
                                          ? const Color(0xFF334155)
                                          : surfaceVariant),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${u.unitNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : onSurfaceLight,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Unit ${u.unitNumber}: ${u.titleEn}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isDark ? Colors.white : onSurfaceLight,
                                ),
                              ),
                              subtitle: Text(
                                u.titleAm,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : onSurfaceVariant,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded,
                                      color: activePrimary)
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                          ? activePrimary.withValues(alpha: 0.25)
                          : activeSurfaceTint)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : surfaceContainerLow.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedTopicId == null
                        ? activePrimary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'All Topics in Selected Unit',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: _selectedTopicId == null
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                  trailing: _selectedTopicId == null
                      ? Icon(Icons.check_circle_rounded, color: activePrimary)
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
                            ? activePrimary.withValues(alpha: 0.25)
                            : activeSurfaceTint)
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : surfaceContainerLow.withValues(alpha: 0.7)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? activePrimary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      t.titleEn,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
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
                        ? Icon(Icons.check_circle_rounded, color: activePrimary)
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

  void _showYearPickerModal(BuildContext context, bool isDark,
      {required bool isStartYear}) {
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                  final isSelected =
                      isStartYear ? _rangeStartYear == yr : _rangeEndYear == yr;
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
                            ? activePrimary
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : surfaceContainerLow),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? activePrimary : Colors.transparent,
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
                                  : (isDark ? Colors.white60 : activePrimary),
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                            ? activePrimary
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : surfaceContainerLow),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? activePrimary : Colors.transparent,
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
                                  : (isDark ? Colors.white60 : activePrimary),
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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAmharic = user?.preferredLanguage == 'am';

    final bgColor = isDark ? const Color(0xFF0B0F19) : surfaceLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: activePrimary))
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🌟 1. Full-Width Edge-to-Edge Hero Card (Zero Side/Top Padding, matching Subject Hub & Home)
                  _buildEdgeToEdgeHeroSection(
                    context,
                    isDesktop,
                    isAmharic,
                    isDark,
                  ),

                  // 📚 2. Content Container Below Hero Card
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 16.0,
                      vertical: 20.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                        _buildCurriculumScopeCard(
                                            context, isDark),
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
                                        _buildExamParametersCard(
                                            context, isDark),
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
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStickyBottomBar(isDark),
          if (!isDesktop) _buildBottomNavigationBar(context, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // 🌟 1. FULL-WIDTH EDGE-TO-EDGE HERO SECTION
  // ==========================================
  Widget _buildEdgeToEdgeHeroSection(
    BuildContext context,
    bool isWide,
    bool isAmharic,
    bool isDark,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final subject = _selectedSubject;
    final theme = _currentTheme;
    final streamLabel = subject != null
        ? (subject.stream.toLowerCase().contains('social')
            ? (isAmharic ? 'ማህበራዊ ሳይንስ' : 'SOCIAL')
            : (isAmharic ? 'የተፈጥሮ ሳይንስ' : 'NATURAL'))
        : (isAmharic ? 'የተፈጥሮ ሳይንስ' : 'NATURAL');
    final gradeLabel = 'Grade ${_selectedGrade ?? subject?.grade ?? 12}';
    final subjectTitle = subject != null
        ? (isAmharic && subject.nameAm.isNotEmpty
            ? subject.nameAm
            : subject.nameEn)
        : (isAmharic ? 'አጠቃላይ የፈተና ዝግጅት' : 'National Exam Practice');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.gradientStart,
            theme.gradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // Top-left ambient glow
            Positioned(
              left: -35,
              top: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            // Bottom-right ambient glow
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Content Container
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding > 0 ? topPadding + 12 : 20,
                    left: isWide ? 48.0 : 16.0,
                    right: isWide ? 48.0 : 16.0,
                    bottom: 22.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row 1: Active Subject Pill (Left) & Back Button (Right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Active Subject Pill
                          InkWell(
                            onTap: _subjects.length > 1
                                ? () => _showSubjectPickerModal(context, isDark)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (theme.symbol.isNotEmpty &&
                                      theme.symbol.runes.length <= 2)
                                    Text(
                                      theme.symbol,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  else
                                    Icon(
                                      theme.icon,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    subjectTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (_subjects.length > 1) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAmharic ? 'ቀይር' : 'Change',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Back Button in top-right corner
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: isAmharic ? 'ተመለስ' : 'Back',
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 2: Primary Headline
                      Text(
                        isAmharic ? 'ብጁ የፈተና ልምምድ' : 'Custom Exam Practice',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Curriculum & Verification Metadata Badges (Flush Left)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EUEE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$gradeLabel • $streamLabel',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF6EE7B7)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF6EE7B7),
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAmharic ? 'ሚኒስቴር-ተስማሚ' : 'MoE Verified',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD1FAE5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 3: Segmented Mode Switcher (Self-Paced vs Timed Exam)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_isTimed) {
                                    setState(() => _isTimed = false);
                                  }
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: !_isTimed
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: !_isTimed
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
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
                                            ? theme.primary
                                            : Colors.white
                                                .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAmharic ? 'በራስ ፍጥነት' : 'Self-Paced',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: !_isTimed
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: !_isTimed
                                              ? const Color(0xFF0F172A)
                                              : Colors.white
                                                  .withValues(alpha: 0.90),
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
                                  if (!_isTimed) {
                                    setState(() => _isTimed = true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _isTimed
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: _isTimed
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
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
                                            ? theme.primary
                                            : Colors.white
                                                .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAmharic
                                            ? 'በጊዜ የተገደበ ፈተና'
                                            : 'Timed Exam',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: _isTimed
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: _isTimed
                                              ? const Color(0xFF0F172A)
                                              : Colors.white
                                                  .withValues(alpha: 0.90),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. STEP 1: CURRICULUM SCOPE CARD
  // ==========================================
  Widget _buildCurriculumScopeCard(BuildContext context, bool isDark) {
    final sub = _selectedSubject;
    final unit = _selectedUnit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: activePrimary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Subject Card Icon + Title + Step 1 of 2 Neumorphic Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          activePrimary.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activePrimary.withValues(
                            alpha: isDark ? 0.40 : 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activePrimary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: isDark ? activeAccent : activePrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Curriculum Scope',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activePrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activePrimary.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Step 1 of 2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : onSurfaceVariant,
                      ),
                    ),
                  ],
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? Colors.white70 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: () => _showGradePickerModal(context, isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  if (!isDark)
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 3,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: activePrimary.withValues(
                              alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: isDark ? activeAccent : activePrimary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedGrade != null
                            ? 'Grade $_selectedGrade (Secondary / EUEE Scope)'
                            : 'All Grades (9-12 Scope)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                      size: 18,
                    ),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? Colors.white70 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: () => _showSubjectPickerModal(context, isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  if (!isDark)
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 3,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                activePrimary,
                                activePrimary.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activePrimary.withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: activeSymbol.isNotEmpty &&
                                  activeSymbol.runes.length <= 2
                              ? Center(
                                  child: Text(
                                    activeSymbol,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Icon(
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
                                        color: isDark
                                            ? Colors.white
                                            : onSurfaceLight,
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
                                        color: isDark
                                            ? Colors.white60
                                            : onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activePrimary.withValues(
                                          alpha: isDark ? 0.20 : 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: activePrimary.withValues(
                                            alpha: isDark ? 0.35 : 0.20),
                                      ),
                                    ),
                                    child: Text(
                                      'Core Subject · EUEE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? activeAccent
                                            : activePrimary,
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                      size: 18,
                    ),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? Colors.white70 : onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: () => _showUnitPickerModal(context, isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  if (!isDark)
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 3,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 19,
                            color: isDark ? activeAccent : activePrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : onSurfaceLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                unit != null
                                    ? unit.titleAm
                                    : 'Chapters 1 to ${_units.length} included',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white60
                                      : onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: isDark ? Colors.white60 : onSurfaceVariant,
                      size: 18,
                    ),
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
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: isDark ? Colors.white70 : onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 7),
            InkWell(
              onTap: () => _showTopicPickerModal(context, isDark),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-1, -1),
                        blurRadius: 3,
                      ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                      offset: const Offset(1, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Icon(Icons.topic_outlined,
                                size: 19,
                                color: isDark ? activeAccent : activePrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTopic?.titleEn ??
                                  'All Topics in Selected Unit',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : onSurfaceLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: isDark ? Colors.white60 : onSurfaceVariant,
                        size: 18,
                      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: secondaryContainer.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Subject Card Style Icon + Title + Step 2 of 2 Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: secondaryContainer.withValues(
                          alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: secondaryContainer.withValues(
                            alpha: isDark ? 0.40 : 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryContainer.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: secondaryContainer,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Past Papers',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : onSurfaceLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Archive',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: secondaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: secondaryContainer,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Step 2 of 2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Neumorphic Filter Mode Switcher (Year Range vs Single Year)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _yearMode = ExamYearFilterMode.range);
                      _updateMatchingQuestionCount();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _yearMode == ExamYearFilterMode.range
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _yearMode == ExamYearFilterMode.range
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.35 : 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                if (!isDark)
                                  const BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 2,
                                    offset: Offset(0, -1),
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
                                ? FontWeight.w800
                                : FontWeight.w600,
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
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _yearMode == ExamYearFilterMode.single
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _yearMode == ExamYearFilterMode.single
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.35 : 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                if (!isDark)
                                  const BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 2,
                                    offset: Offset(0, -1),
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
                                ? FontWeight.w800
                                : FontWeight.w600,
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
                    onTap: () => _showYearPickerModal(context, isDark,
                        isStartYear: true),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-1, -1),
                              blurRadius: 3,
                            ),
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.20 : 0.03),
                            offset: const Offset(1, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Year',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_rangeStartYear',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : onSurfaceLight,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'E.C.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          isDark ? activeAccent : activePrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : onSurfaceVariant,
                                ),
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
                    onTap: () => _showYearPickerModal(context, isDark,
                        isStartYear: false),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-1, -1),
                              blurRadius: 3,
                            ),
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.20 : 0.03),
                            offset: const Offset(1, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To Year',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_rangeEndYear',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : onSurfaceLight,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'E.C.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          isDark ? activeAccent : activePrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : onSurfaceVariant,
                                ),
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
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-1, -1),
                        blurRadius: 3,
                      ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                      offset: const Offset(1, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_selectedSingleYear',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : onSurfaceLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'E.C. National Examination',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? activeAccent : activePrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: isDark ? Colors.white60 : onSurfaceVariant,
                      ),
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? activePrimary.withValues(alpha: 0.28) : activePrimary)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? (isDark ? activePrimary : Colors.transparent)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activePrimary.withValues(alpha: isDark ? 0.30 : 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else if (!isDark)
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-1, -1),
                blurRadius: 2,
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? (isDark ? activeAccent : Colors.white)
                : (isDark ? Colors.white70 : onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveQuestionsIndicator(bool isDark) {
    final hasQuestions = _matchingQuestionCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasQuestions
            ? (isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.40)
                : const Color(0xFFECFDF5))
            : (isDark
                ? const Color(0xFF78350F).withValues(alpha: 0.25)
                : const Color(0xFFFFFBEB)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasQuestions
              ? (isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.50)
                  : const Color(0xFFA7F3D0))
              : (isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A)),
        ),
        boxShadow: [
          BoxShadow(
            color: hasQuestions
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isCountingQuestions)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: activePrimary),
            )
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: hasQuestions
                    ? const Color(0xFF10B981).withValues(alpha: 0.20)
                    : const Color(0xFFD97706).withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuestions
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: hasQuestions
                    ? const Color(0xFF10B981)
                    : const Color(0xFFD97706),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCountingQuestions
                  ? 'Calculating matching questions in national archive...'
                  : (hasQuestions
                      ? '✓ $_matchingQuestionCount Verified Questions match your criteria'
                      : 'No questions match this combination. Try broadening the year range or units.'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: hasQuestions
                    ? (isDark
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFF065F46))
                    : (isDark
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF92400E)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: activePrimary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          activePrimary.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activePrimary.withValues(
                            alpha: isDark ? 0.40 : 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activePrimary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: isDark ? activeAccent : activePrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Exam Parameters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activePrimary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        activePrimary.withValues(alpha: isDark ? 0.35 : 0.20),
                  ),
                ),
                child: Text(
                  '$_questionCount Questions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? activeAccent : activePrimary,
                  ),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: isDark ? Colors.white70 : onSurfaceVariant,
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
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activePrimary
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? activePrimary
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: activePrimary.withValues(alpha: 0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          else if (!isDark)
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-1, -1),
                              blurRadius: 2,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$preset Qs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
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
              activeTrackColor: activePrimary,
              inactiveTrackColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              thumbColor: activePrimary,
              trackHeight: 5,
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Limit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white70 : onSurfaceVariant,
                  ),
                ),
                Text(
                  '$_timeLimitMinutes min (${(_timeLimitMinutes * 60 ~/ _questionCount)}s / q)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? activeAccent : activePrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activePrimary,
                inactiveTrackColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                thumbColor: activePrimary,
                trackHeight: 5,
              ),
              child: Slider(
                value: _timeLimitMinutes.toDouble(),
                min: 5,
                max: 90,
                divisions: 17,
                onChanged: (val) =>
                    setState(() => _timeLimitMinutes = val.toInt()),
              ),
            ),
          ],

          // Difficulty Selector
          const SizedBox(height: 12),
          Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? Colors.white70 : onSurfaceVariant,
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
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? activePrimary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activePrimary
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: activePrimary.withValues(alpha: 0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              else if (!isDark)
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-1, -1),
                  blurRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
    final subName =
        sub != null ? '${sub.nameEn} (Core Subject)' : 'All Subjects';
    final paperLabel = _yearMode == ExamYearFilterMode.range
        ? '$_rangeStartYear–$_rangeEndYear Past Papers'
        : '$_selectedSingleYear E.C. Past Paper';
    final modeLabel = _isTimed
        ? 'Timed Exam ($_questionCount Qs · $_timeLimitMinutes min)'
        : 'Self-Paced ($_questionCount Questions)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? activePrimary.withValues(alpha: 0.30)
              : activePrimary.withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: activePrimary.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          activePrimary.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 19,
                      color: isDark ? activeAccent : activePrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Practice',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : onSurfaceLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981)
                      .withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Curriculum',
            'Grade ${_selectedGrade ?? 12} · $subName',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Papers',
            paperLabel,
            isDark,
          ),
          const SizedBox(height: 8),
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
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.danger, size: 20),
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
        color: isDark
            ? const Color(0xFF111827).withValues(alpha: 0.95)
            : surfaceLight.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B)
                : surfaceVariant.withValues(alpha: 0.4),
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
                backgroundColor: activePrimary,
                foregroundColor: onPrimary,
                disabledBackgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                disabledForegroundColor:
                    isDark ? Colors.white38 : Colors.black38,
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
                color: isDark ? activeAccent : activePrimary,
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
                color: isDark ? activeAccent : activePrimary,
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
        color: isDark
            ? const Color(0xFF111827)
            : surfaceContainerLowest.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B)
                : surfaceVariant.withValues(alpha: 0.4),
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
    final activeColor = isDark ? activeAccent : activePrimary;
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
