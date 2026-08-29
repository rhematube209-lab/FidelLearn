import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/teacher_models.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  final Classroom? classroom;

  const CreateAssignmentScreen({super.key, this.classroom});

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Topic Quiz 1: Sequences & Limits');
  String _selectedSubjectId = 'math_g12';
  String _selectedSubjectName = 'Mathematics';
  int _timeLimitMinutes = 20;
  List<Question> _availableQuestions = [];
  final Set<String> _selectedQuestionIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableQuestions() async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final questions = await contentRepo.getQuestions(
      grade: widget.classroom?.grade ?? 12,
      subjectId: _selectedSubjectId,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        _availableQuestions = questions;
        // Select first 5 by default
        _selectedQuestionIds.addAll(questions.take(5).map((q) => q.id));
        _isLoading = false;
      });
    }
  }

  Future<void> _publishAssignment() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and select at least 1 question.'),
        ),
      );
      return;
    }

    final cls = widget.classroom;
    if (cls == null) return;

    final teacherRepo = ref.read(teacherRepositoryProvider);
    await teacherRepo.createAssignment(
      classroomId: cls.id,
      classroomName: cls.name,
      title: title,
      subjectId: _selectedSubjectId,
      subjectName: _selectedSubjectName,
      questionIds: _selectedQuestionIds.toList(),
      timeLimitMinutes: _timeLimitMinutes,
      dueAt: DateTime.now().add(const Duration(days: 3)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment Published to Classroom! 🚀')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classroom Banner
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.classroom?.name ?? 'Grade 12 Section A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${widget.classroom?.studentCount ?? 0} Students enrolled',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Assignment Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Assignment Title',
                      hintText: 'e.g. Weekly Calculus Review',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject Selector
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubjectId,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'math_g12',
                              child: Text('Mathematics'),
                            ),
                            DropdownMenuItem(
                              value: 'aptitude_g12',
                              child: Text('Aptitude'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSubjectId = val;
                                _selectedSubjectName =
                                    val == 'math_g12'
                                        ? 'Mathematics'
                                        : 'Aptitude';
                                _isLoading = true;
                              });
                              _loadAvailableQuestions();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _timeLimitMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Time Limit',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 10,
                              child: Text('10 Mins'),
                            ),
                            DropdownMenuItem(
                              value: 20,
                              child: Text('20 Mins'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('30 Mins'),
                            ),
                            DropdownMenuItem(
                              value: 45,
                              child: Text('45 Mins'),
                            ),
                          ],
                          onChanged:
                              (val) => setState(
                                () => _timeLimitMinutes = val ?? 20,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Question Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Questions (${_selectedQuestionIds.length} chosen)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedQuestionIds.length ==
                                _availableQuestions.length) {
                              _selectedQuestionIds.clear();
                            } else {
                              _selectedQuestionIds.addAll(
                                _availableQuestions.map((q) => q.id),
                              );
                            }
                          });
                        },
                        child: Text(
                          _selectedQuestionIds.length ==
                                  _availableQuestions.length
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableQuestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final q = _availableQuestions[index];
                      final isChecked = _selectedQuestionIds.contains(q.id);

                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedQuestionIds.add(q.id);
                            } else {
                              _selectedQuestionIds.remove(q.id);
                            }
                          });
                        },
                        title: Text(
                          q.questionTextEn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '${q.topicId} • ${q.difficulty.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                isChecked
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Publish Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _publishAssignment,
                      icon: const Icon(Icons.send),
                      label: const Text('Publish Assignment'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
