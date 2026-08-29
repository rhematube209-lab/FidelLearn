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
  int _questionCount = 5;
  bool _isTimed = false;
  int _timeLimitMinutes = 15;
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

      if (questions.length < _questionCount) {
        setState(() {
          _errorMessage =
              'Only ${questions.length} matching questions found (requested $_questionCount). Adjust your question count.';
          _isLoading = false;
        });
        return;
      }

      // Shuffle and take requested count
      final shuffled = List<Question>.from(questions)..shuffle();
      final selectedQuestions = shuffled.sublist(0, _questionCount);

      final subject = _subjects.firstWhere((s) => s.id == _selectedSubjectId);
      final exam = Exam(
        id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
        title: _isTimed
            ? '${subject.nameEn} Timed Mock'
            : '${subject.nameEn} Practice',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'mock' ? 'Full Mock Exam' : 'Custom Exam Builder',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.errorRed),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Subject Selector
                  const Text(
                    'Subject',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    items: _subjects.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nameEn),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSubjectId = val);
                        _loadUnitsAndTopics(val);
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Unit Filter (Optional)
                  const Text(
                    'Unit (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedUnitId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Units'),
                      ),
                      ..._units.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('Unit ${u.unitNumber}: ${u.titleEn}'),
                        ),
                      ),
                    ],
                    onChanged: _onUnitChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Topic Filter (Optional)
                  if (_topics.isNotEmpty) ...[
                    const Text(
                      'Topic (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedTopicId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Topics in Unit'),
                        ),
                        ..._topics.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.titleEn),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedTopicId = val),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.topic_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Difficulty Selector
                  const Text(
                    'Difficulty Level',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip(
                        'All',
                        _selectedDifficulty == null,
                        () => setState(() => _selectedDifficulty = null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Easy',
                        _selectedDifficulty == 'easy',
                        () => setState(() => _selectedDifficulty = 'easy'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Medium',
                        _selectedDifficulty == 'medium',
                        () => setState(() => _selectedDifficulty = 'medium'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Hard',
                        _selectedDifficulty == 'hard',
                        () => setState(() => _selectedDifficulty = 'hard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Question Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Number of Questions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$_questionCount questions',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 10,
                    divisions: 1,
                    label: '$_questionCount',
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) =>
                        setState(() => _questionCount = val.toInt()),
                  ),
                  const SizedBox(height: 16),

                  // 6. Timed Mode Toggle
                  SwitchListTile(
                    title: const Text(
                      'Timed Examination Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _isTimed
                          ? 'Auto-submits when time expires'
                          : 'Practice at your own pace (untimed)',
                    ),
                    value: _isTimed,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) => setState(() => _isTimed = val),
                  ),

                  if (_isTimed) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Time Limit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$_timeLimitMinutes minutes',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGoldDark,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _timeLimitMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '$_timeLimitMinutes min',
                      activeColor: AppTheme.accentGold,
                      onChanged: (val) =>
                          setState(() => _timeLimitMinutes = val.toInt()),
                    ),
                  ],
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _startExam,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _isTimed
                          ? 'Start Timed Mock Exam'
                          : 'Start Practice Session',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
