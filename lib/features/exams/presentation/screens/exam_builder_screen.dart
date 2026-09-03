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

class ExamBuilderScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? mode; // 'mock' or 'custom'

  const ExamBuilderScreen({super.key, this.initialSubjectId, this.mode});

  @override
  ConsumerState<ExamBuilderScreen> createState() => _ExamBuilderScreenState();
}

class _ExamBuilderScreenState extends ConsumerState<ExamBuilderScreen> {
  List<Subject> _subjects = [];
  List<Unit> _units = [];
  List<Topic> _topics = [];

  String? _selectedSubjectId;
  String? _selectedUnitId;
  String? _selectedTopicId;
  String? _selectedDifficulty; // null = all
  int? _selectedYear; // null = all
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

    if (user != null) {
      final subs = await contentRepo.getSubjects(
        grade: user.grade,
        stream: user.stream,
      );
      setState(() {
        _subjects = subs;
        if (subs.isNotEmpty) {
          _selectedSubjectId = widget.initialSubjectId ?? subs.first.id;
        }
        _isLoading = false;
      });

      if (_selectedSubjectId != null) {
        await _loadUnitsAndTopics(_selectedSubjectId!);
      }
    }
  }

  Future<void> _loadUnitsAndTopics(String subjectId) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final units = await contentRepo.getUnits(subjectId);
    setState(() {
      _units = units;
      _selectedUnitId = null;
      _selectedTopicId = null;
      _topics = [];
    });
  }

  Future<void> _onUnitChanged(String? unitId) async {
    setState(() {
      _selectedUnitId = unitId;
      _selectedTopicId = null;
    });

    if (unitId != null) {
      final contentRepo = ref.read(contentRepositoryProvider);
      final topics = await contentRepo.getTopics(unitId);
      setState(() => _topics = topics);
    } else {
      setState(() => _topics = []);
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
        grade: user.grade,
        subjectId: _selectedSubjectId!,
        unitId: _selectedUnitId,
        topicId: _selectedTopicId,
        difficulty: _selectedDifficulty,
        examYear: _selectedYear,
      );

      if (questions.isEmpty) {
        setState(() {
          _errorMessage =
              'No questions match the selected filter criteria. Try selecting all units or clearing difficulty.';
          _isLoading = false;
        });
        return;
      }

      final count = questions.length < _questionCount ? questions.length : _questionCount;

      final shuffled = List<Question>.from(questions)..shuffle();
      final selectedQuestions = shuffled.sublist(0, count);

      final subject = _subjects.firstWhere((s) => s.id == _selectedSubjectId);
      final exam = Exam(
        id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
        title: _isTimed
            ? '${subject.nameEn} Timed Mock'
            : '${subject.nameEn} Practice Session',
        examType: _isTimed ? ExamType.mockFull : ExamType.customBuilder,
        grade: user.grade,
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
        await context.push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
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
          _isTimed ? 'Timed National Mock Exam' : 'Custom Exam Builder',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
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
                      // Mode Selector Pill
                      _buildModeSelector(isDark),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.4),
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
                              child: _buildSimulationSettingsCard(context, isDark),
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
                      ? (isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight)
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
                            : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Self-Paced Practice',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: !_isTimed ? FontWeight.w700 : FontWeight.w500,
                          color: !_isTimed
                              ? (isDark ? Colors.white : AppTheme.brandStrong)
                              : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
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
                      ? (isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight)
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
                            : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Timed National Mock',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _isTimed ? FontWeight.w700 : FontWeight.w500,
                          color: _isTimed
                              ? (isDark ? Colors.white : AppTheme.brandStrong)
                              : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppTheme.brand, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Curriculum Scope',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Subject Selector
          Text(
            'Target Subject',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            items: _subjects.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text('${s.nameEn} (${s.code})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSubjectId = val);
                _loadUnitsAndTopics(val);
              }
            },
            decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
          ),
          const SizedBox(height: 18),

          // 2. Unit Filter
          Text(
            'Curriculum Unit',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedUnitId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Units (Comprehensive Examination)'),
              ),
              ..._units.map(
                (u) => DropdownMenuItem(
                  value: u.id,
                  child: Text('Unit ${u.unitNumber}: ${u.titleEn}', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _onUnitChanged,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.layers_outlined)),
          ),
          const SizedBox(height: 18),

          // 3. Topic Filter
          if (_topics.isNotEmpty) ...[
            Text(
              'Specific Topic',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedTopicId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Topics in Selected Unit'),
                ),
                ..._topics.map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.titleEn, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedTopicId = val),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.topic_outlined)),
            ),
            const SizedBox(height: 18),
          ],

          // 4. Difficulty Selector
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
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, String? value, bool isDark) {
    final isSelected = _selectedDifficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDifficulty = value),
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
                child: const Icon(Icons.tune_rounded, color: AppTheme.accent, size: 20),
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
                  color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
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
            children: [10, 20, 30, 50].map((preset) {
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
                          '$preset Qs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppTheme.brandStrong)
                                : (isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft),
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
            value: _questionCount.toDouble(),
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
                    color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                  ),
                ),
                Text(
                  '$_timeLimitMinutes min (${(_timeLimitMinutes * 60 ~/ _questionCount)}s / question)',
                  style: const TextStyle(
                    color: AppTheme.accentDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
              onChanged: (val) => setState(() => _timeLimitMinutes = val.toInt()),
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 16),

          // Start CTA Button
          FidelButton(
            label: _isTimed ? 'Launch Timed Mock Exam' : 'Start Practice Session',
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
