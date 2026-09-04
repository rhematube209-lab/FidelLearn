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
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final teacherRepo = ref.read(teacherRepositoryProvider);

      if (user != null) {
        final classes = await teacherRepo.getTeacherClassrooms(user.id);
        if (classes.isNotEmpty) {
          _classrooms = classes;
          _selectedClassroom = classes.first;
          await _loadClassroomDetails(_selectedClassroom!.id);
        }
      }
    } catch (e) {
      debugPrint('TeacherDashboardScreen: error loading teacher data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassroomDetails(String classroomId) async {
    try {
      final teacherRepo = ref.read(teacherRepositoryProvider);
      final asgs = await teacherRepo.getClassAssignments(classroomId);
      final stats = await teacherRepo.getClassroomWeakTopics(classroomId);

      if (mounted) {
        setState(() {
          _assignments = asgs;
          _topicStats = stats;
        });
      }
    } catch (e) {
      debugPrint('TeacherDashboardScreen: error loading classroom details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Command Portal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 20.0,
          vertical: 28.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Header
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), AppTheme.darkSurfaceStrong],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.4)),
                    boxShadow: AppTheme.cardShadowDark,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.brandStrong,
                        child: Icon(Icons.school_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Dashboard • ${user.displayName}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_classrooms.length} Active Classrooms • Section 12-A & 12-B Natural Science',
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.darkTextSoft),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        ElevatedButton.icon(
                          onPressed: () => context.push('/create_assignment'),
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Create Exam Assignment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandStrong,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Class Selector & Assignments (50%)
                      Expanded(
                        flex: 50,
                        child: Column(
                          children: [
                            _buildClassSelectorCard(),
                            const SizedBox(height: 24),
                            _buildAssignmentsCard(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),

                      // Right: Class Weak Topics Heatmap (50%)
                      Expanded(
                        flex: 50,
                        child: _buildTopicHeatmapCard(),
                      ),
                    ],
                  )
                else ...[
                  _buildClassSelectorCard(),
                  const SizedBox(height: 20),
                  _buildAssignmentsCard(context),
                  const SizedBox(height: 20),
                  _buildTopicHeatmapCard(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create_assignment'),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Create Exam Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandStrong,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Classroom',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          DropdownButtonFormField<Classroom>(
            value: _selectedClassroom,
            items: _classrooms.map((c) {
              return DropdownMenuItem(
                  value: c,
                  child: Text(
                      '${c.name} (Grade ${c.grade} • ${c.studentCount} Students)'));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedClassroom = val);
                _loadClassroomDetails(val.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Class Assignments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (_assignments.isEmpty)
            const Text('No assignments published for this class yet.',
                style: TextStyle(fontSize: 12, color: AppTheme.darkMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignments.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppTheme.darkBorder, height: 16),
              itemBuilder: (context, index) {
                final asg = _assignments[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asg.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                            '${asg.questionIds.length} Questions • Due ${asg.dueAt.month}/${asg.dueAt.day}',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.darkMuted)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ACTIVE',
                          style: TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopicHeatmapCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Classroom Weak Topics Diagnostic',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (_topicStats.isEmpty)
            const Text(
                'Student attempt analytics will populate topic heatmaps automatically.',
                style: TextStyle(fontSize: 12, color: AppTheme.darkMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topicStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final stat = _topicStats[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(stat.topicName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                            '${stat.averageAccuracyPercentage.toStringAsFixed(0)}% Class Avg',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.danger,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stat.averageAccuracyPercentage / 100,
                        backgroundColor: const Color(0x1AFFFFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.danger),
                        minHeight: 6,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
