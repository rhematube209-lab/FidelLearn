import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/assignment_models.dart';
import '../../domain/models/teacher_portal_models.dart';
import '../providers/assignment_providers.dart';
import '../providers/teacher_portal_providers.dart';
import '../../../../core/providers/app_providers.dart'
    hide teacherPortalRepositoryProvider;

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  final String? initialClassroomId;
  final String? initialSubjectId;
  final String? initialExamVariant;
  final String? initialStudentUserId;
  final String? initialTopicId;

  const CreateAssignmentScreen({
    super.key,
    this.initialClassroomId,
    this.initialSubjectId,
    this.initialExamVariant,
    this.initialStudentUserId,
    this.initialTopicId,
  });

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  int _currentStep = 0;

  // Step 1: Class & Subject
  TeacherAssignedClass? _selectedClass;

  // Step 2: Details & Type
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  AssignmentType _assignmentType = AssignmentType.targetedPractice;

  // Step 3: Content Selection
  List<Question> _availableQuestions = [];
  final Set<String> _selectedQuestionIds = {};
  final int _targetQuestionCount = 10;
  bool _isLoadingQuestions = false;

  // Step 4: Recipients
  bool _entireClass = true;
  final Set<String> _selectedStudentUserIds = {};
  List<ClassRosterStudent> _classRoster = [];
  bool _isLoadingRoster = false;

  // Step 5: Policy
  DateTime? _dueDate;
  bool _allowLate = true;
  bool _isTimed = false;
  int _timeLimitMinutes = 20;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromParams();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _initFromParams() async {
    final classesAsync = ref.read(teacherAssignedClassesProvider);
    final classes = classesAsync.valueOrNull ?? [];

    if (classes.isNotEmpty) {
      if (widget.initialClassroomId != null &&
          widget.initialSubjectId != null) {
        _selectedClass = classes.firstWhere(
          (c) =>
              c.classroom.id == widget.initialClassroomId &&
              c.subjectId == widget.initialSubjectId,
          orElse: () => classes.first,
        );
      } else {
        _selectedClass = classes.first;
      }

      if (_titleController.text.isEmpty) {
        _titleController.text =
            '${_selectedClass?.subjectName ?? "Subject"} Practice - ${DateTime.now().month}/${DateTime.now().day}';
      }

      await _loadRosterAndQuestions();

      if (widget.initialStudentUserId != null) {
        setState(() {
          _entireClass = false;
          _selectedStudentUserIds.add(widget.initialStudentUserId!);
        });
      }
    }
  }

  Future<void> _loadRosterAndQuestions() async {
    final cls = _selectedClass;
    if (cls == null) return;

    setState(() {
      _isLoadingQuestions = true;
      _isLoadingRoster = true;
    });

    try {
      // 1. Load questions from verified content repository
      final contentRepo = ref.read(contentRepositoryProvider);
      final questions = await contentRepo.getQuestions(
        grade: cls.classroom.grade,
        subjectId: cls.subjectId,
        limit: 50,
      );

      // Filter questions according to exact Mathematics variant rules
      final filtered = questions.where((q) {
        if (q.subjectId == 'math_g12') {
          if (cls.examVariant == 'naturalScience') {
            return q.examVariant == ExamVariantCode.naturalScience;
          } else if (cls.examVariant == 'socialScience') {
            return q.examVariant == ExamVariantCode.socialScience;
          }
          return false;
        }
        return true;
      }).toList();

      // 2. Load class roster
      final teacherRepo = ref.read(teacherPortalRepositoryProvider);
      final rosterPage = await teacherRepo.getClassRoster(
        classroomId: cls.classroom.id,
        subjectId: cls.subjectId,
        pageSize: 100,
      );

      if (mounted) {
        setState(() {
          _availableQuestions = filtered;
          _selectedQuestionIds.clear();
          // Select default subset
          _selectedQuestionIds.addAll(
            filtered.take(_targetQuestionCount).map((q) => q.id),
          );
          _classRoster = rosterPage.students;
          _isLoadingQuestions = false;
          _isLoadingRoster = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
          _isLoadingRoster = false;
        });
      }
    }
  }

  Future<void> _submitAssignment({required bool publishImmediately}) async {
    final cls = _selectedClass;
    if (cls == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an assignment title.')),
      );
      return;
    }

    if (_selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 question.')),
      );
      return;
    }

    if (!_entireClass && _selectedStudentUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select at least 1 student or assign to entire class.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(teacherAssignmentRepositoryProvider);
      final schoolContext = ref.read(activeSchoolContextProvider);
      final schoolId = schoolContext.activeSchool?.id ?? '';

      // 1. Create Draft
      final assignmentId = await repo.createAssignmentDraft(
        schoolId: schoolId,
        classroomId: cls.classroom.id,
        subjectId: cls.subjectId,
        examVariant: cls.examVariant,
        title: title,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        assignmentType: _assignmentType,
        timeLimitMinutes: _isTimed ? _timeLimitMinutes : 0,
        dueAt: _dueDate,
        allowLateSubmission: _allowLate,
      );

      // 2. If publishing immediately, call publish transaction
      if (publishImmediately) {
        await repo.publishAssignment(
          assignmentId: assignmentId,
          questionIds: _selectedQuestionIds.toList(),
          recipientStudentIds:
              _entireClass ? null : _selectedStudentUserIds.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publishImmediately
                  ? 'Assignment published to classroom!'
                  : 'Assignment draft saved successfully.',
            ),
            backgroundColor: AppTheme.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save assignment: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classesAsync = ref.watch(teacherAssignedClassesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Create Assignment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child:
                  Text('No active classes assigned to this teacher account.'),
            );
          }

          _selectedClass ??= classes.first;

          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.brand,
                  ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  context.pop();
                }
              },
              onStepContinue: () {
                if (_currentStep < 4) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitAssignment(publishImmediately: true);
                }
              },
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 4;
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      if (isLastStep) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _submitAssignment(
                                    publishImmediately: false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () =>
                                    _submitAssignment(publishImmediately: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Publish Now',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Class & Subject
                Step(
                  title: const Text('Class & Subject'),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Classroom & Subject',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TeacherAssignedClass>(
                        value: _selectedClass,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: classes.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                                '${c.classroom.name} — ${c.subjectDisplayLabel}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedClass) {
                            setState(() {
                              _selectedClass = val;
                              _titleController.text =
                                  '${val.subjectName} Practice - ${DateTime.now().month}/${DateTime.now().day}';
                            });
                            _loadRosterAndQuestions();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Assignment Title',
                          hintText: 'e.g. Unit 3 Kinematics Drill',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _instructionsController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Instructions for Students (Optional)',
                          hintText:
                              'e.g. Complete before Wednesday class discussion.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 2: Assignment Type
                Step(
                  title: const Text('Assignment Type'),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      _TypeRadioTile(
                        value: AssignmentType.targetedPractice,
                        groupValue: _assignmentType,
                        title: 'Targeted Practice',
                        subtitle:
                            'Assign focused practice questions on specific curriculum targets.',
                        icon: Icons.track_changes_rounded,
                        onChanged: (val) =>
                            setState(() => _assignmentType = val!),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _TypeRadioTile(
                        value: AssignmentType.customQuestionSet,
                        groupValue: _assignmentType,
                        title: 'Selected Question Set',
                        subtitle:
                            'Hand-pick specific verified questions from the question bank.',
                        icon: Icons.checklist_rounded,
                        onChanged: (val) =>
                            setState(() => _assignmentType = val!),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _TypeRadioTile(
                        value: AssignmentType.simulation,
                        groupValue: _assignmentType,
                        title: 'ESSLCE Exam Simulation',
                        subtitle:
                            'Assign a full national exam simulation adhering to blueprint quotas.',
                        icon: Icons.school_rounded,
                        onChanged: (val) =>
                            setState(() => _assignmentType = val!),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Step 3: Question Selection & Preview
                Step(
                  title: const Text('Questions'),
                  isActive: _currentStep >= 2,
                  state:
                      _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _isLoadingQuestions
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Selected: ${_selectedQuestionIds.length} / ${_availableQuestions.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 8),
                            if (_availableQuestions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                    'No verified questions available for this subject/variant.'),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _availableQuestions.take(15).length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, idx) {
                                  final q = _availableQuestions[idx];
                                  final isSelected =
                                      _selectedQuestionIds.contains(q.id);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppTheme.brand,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    title: Text(
                                      'Q${idx + 1}: ${q.questionTextEn}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '${q.unitId} • ${q.difficulty.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppTheme.darkTextMuted
                                            : AppTheme.lightTextMuted,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedQuestionIds.add(q.id);
                                        } else {
                                          _selectedQuestionIds.remove(q.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                ),

                // Step 4: Recipients
                Step(
                  title: const Text('Recipients'),
                  isActive: _currentStep >= 3,
                  state:
                      _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Assign to Entire Class'),
                        subtitle: Text(
                          '${_classRoster.length} students currently enrolled in ${_selectedClass?.classroom.name ?? ""}',
                        ),
                        value: _entireClass,
                        activeColor: AppTheme.brand,
                        onChanged: (val) {
                          setState(() {
                            _entireClass = val;
                            if (val) _selectedStudentUserIds.clear();
                          });
                        },
                      ),
                      if (!_entireClass) ...[
                        const Divider(),
                        const Text(
                          'Select Specific Students:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingRoster)
                          const Center(child: CircularProgressIndicator())
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _classRoster.length,
                            itemBuilder: (context, idx) {
                              final student = _classRoster[idx];
                              final isSelected = _selectedStudentUserIds
                                  .contains(student.userId);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: AppTheme.brand,
                                title: Text(student.displayName),
                                subtitle: Text(
                                  student.schoolStudentId ??
                                      student.userId.substring(0, 8),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentUserIds
                                          .add(student.userId);
                                    } else {
                                      _selectedStudentUserIds
                                          .remove(student.userId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),

                // Step 5: Schedule & Policy Review
                Step(
                  title: const Text('Schedule & Review'),
                  isActive: _currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event_available_rounded,
                            color: AppTheme.brand),
                        title: const Text('Due Date'),
                        subtitle: Text(
                          _dueDate != null
                              ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                              : 'No deadline',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ??
                                  DateTime.now().add(const Duration(days: 3)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Allow Late Submissions'),
                        subtitle: const Text(
                            'Submissions after deadline are accepted but marked "late".'),
                        value: _allowLate,
                        activeColor: AppTheme.brand,
                        onChanged: (val) => setState(() => _allowLate = val),
                      ),
                      SwitchListTile(
                        title: const Text('Timed Assessment'),
                        subtitle: Text(_isTimed
                            ? '$_timeLimitMinutes minutes'
                            : 'Untimed practice session'),
                        value: _isTimed,
                        activeColor: AppTheme.brand,
                        onChanged: (val) => setState(() => _isTimed = val),
                      ),
                      if (_isTimed) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text('Time limit:'),
                              Expanded(
                                child: Slider(
                                  value: _timeLimitMinutes.toDouble(),
                                  min: 5,
                                  max: 90,
                                  divisions: 17,
                                  label: '$_timeLimitMinutes mins',
                                  activeColor: AppTheme.brand,
                                  onChanged: (val) => setState(
                                      () => _timeLimitMinutes = val.toInt()),
                                ),
                              ),
                              Text('$_timeLimitMinutes min'),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Review Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Summary',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('• Title: ${_titleController.text.trim()}'),
                            Text(
                                '• Class: ${_selectedClass?.classroom.name ?? ""}'),
                            Text(
                                '• Questions: ${_selectedQuestionIds.length} verified items'),
                            Text(
                                '• Recipients: ${_entireClass ? "Entire Class (${_classRoster.length})" : "${_selectedStudentUserIds.length} students"}'),
                            Text(
                                '• Late policy: ${_allowLate ? "Allowed (marked late)" : "Strict cutoff"}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeRadioTile extends StatelessWidget {
  final AssignmentType value;
  final AssignmentType groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<AssignmentType?> onChanged;
  final bool isDark;

  const _TypeRadioTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brand.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.brand
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.brand
                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppTheme.brand : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Radio<AssignmentType>(
              value: value,
              groupValue: groupValue,
              activeColor: AppTheme.brand,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
