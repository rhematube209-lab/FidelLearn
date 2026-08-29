import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/teacher_models.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  List<ClassAssignment> _assignments = [];
  List<ClassroomTopicStats> _topicStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final teacherRepo = ref.read(teacherRepositoryProvider);

    if (user != null) {
      final classes = await teacherRepo.getTeacherClassrooms(user.id);
      if (classes.isNotEmpty) {
        _classrooms = classes;
        _selectedClassroom = classes.first;
        await _loadClassroomDetails(_selectedClassroom!.id);
      }
      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassroomDetails(String classroomId) async {
    final teacherRepo = ref.read(teacherRepositoryProvider);
    final asgs = await teacherRepo.getClassAssignments(classroomId);
    final stats = await teacherRepo.getClassroomWeakTopics(classroomId);

    if (mounted) {
      setState(() {
        _assignments = asgs;
        _topicStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (_isLoading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.school, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher ${user.displayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Classroom Assignment & Analytics Hub',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Class Selector
            const Text(
              'Select Classroom',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _classrooms.map((cls) {
                  final isSelected = _selectedClassroom?.id == cls.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text('${cls.name} (${cls.studentCount} students)'),
                      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedClassroom = cls);
                          _loadClassroomDetails(cls.id);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Class Weak-Topic Heatmap
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Weak-Topic Heatmap',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedClassroom?.name ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topicStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final topic = _topicStats[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                topic.topicName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: topic.isWeakArea
                                    ? AppTheme.errorRed.withValues(alpha: 0.12)
                                    : AppTheme.successGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                topic.isWeakArea ? 'Needs Review' : 'Strong Mastery',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: topic.isWeakArea
                                      ? AppTheme.errorRed
                                      : AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: topic.averageAccuracyPercentage / 100.0,
                          color: topic.isWeakArea
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${topic.totalQuestionsAttempted} total student attempts',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              '${topic.averageAccuracyPercentage}% accuracy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: topic.isWeakArea
                                    ? AppTheme.errorRed
                                    : AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Active Class Assignments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Assignments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (_selectedClassroom != null) {
                      context.push(
                        '/teacher/create_assignment',
                        extra: _selectedClassroom,
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Assignment'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_assignments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No active assignments for this classroom.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final asg = _assignments[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.assignment, color: AppTheme.primaryGreen),
                      ),
                      title: Text(
                        asg.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${asg.subjectName} • ${asg.questionIds.length} Questions • Due in 3 days',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${asg.totalSubmissions} turned in',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Avg: ${asg.averageScorePercentage}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedClassroom != null) {
            context.push(
              '/teacher/create_assignment',
              extra: _selectedClassroom,
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }
}
