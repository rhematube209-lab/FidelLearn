import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
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
    if (_isTimed) _questionCount = 10;
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
              'No questions match the selected criteria. Try removing filters.';
          _isLoading = false;
        });
        return;
      }

      final count = questions.length < _questionCount ? questions.length : _questionCount;

      // Shuffle and take requested count
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'mock' ? 'Timed National Mock Exam' : 'Custom Exam Builder Studio',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.danger),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
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
                            // Left Section: Curriculum Syllabus Selector
                            Expanded(
                              flex: 55,
                              child: _buildCurriculumCard(context),
                            ),
                            const SizedBox(width: 24),

                            // Right Section: Simulation Settings & Live Summary
                            Expanded(
                              flex: 45,
                              child: _buildSimulationSettingsCard(context),
                            ),
                          ],
                        )
                      else ...[
                        _buildCurriculumCard(context),
                        const SizedBox(height: 20),
                        _buildSimulationSettingsCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurriculumCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppTheme.brand, size: 22),
              SizedBox(width: 10),
              Text(
                'Curriculum & Syllabus Scope',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Subject Selector
          const Text('Target Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          const Text('Curriculum Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            const Text('Specific Topic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          const Text('Difficulty Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDifficultyChip('All', null),
              const SizedBox(width: 8),
              _buildDifficultyChip('Easy', 'easy'),
              const SizedBox(width: 8),
              _buildDifficultyChip('Medium', 'medium'),
              const SizedBox(width: 8),
              _buildDifficultyChip('Hard', 'hard'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, String? value) {
    final isSelected = _selectedDifficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDifficulty = value),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandStrong.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected ? AppTheme.brand : AppTheme.darkBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.brand : AppTheme.darkTextSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.accent, size: 22),
              SizedBox(width: 10),
              Text(
                'Exam Engine Parameters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Question Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Question Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_questionCount items',
                  style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          Slider(
            value: _questionCount.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: '$_questionCount',
            activeColor: AppTheme.brand,
            onChanged: (val) => setState(() => _questionCount = val.toInt()),
          ),
          const SizedBox(height: 14),

          // Timed Mode Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Strict Examination Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(
                _isTimed ? 'Auto-submits when time reaches 00:00' : 'Self-paced untimed practice mode',
                style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
              ),
              value: _isTimed,
              activeColor: AppTheme.accent,
              onChanged: (val) => setState(() => _isTimed = val),
            ),
          ),

          if (_isTimed) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  '$_timeLimitMinutes minutes',
                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
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
          ],
          const SizedBox(height: 28),

          // Start CTA
          ElevatedButton.icon(
            onPressed: _startExam,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              _isTimed ? 'Launch Timed Examination' : 'Start Practice Session',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandStrong,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
