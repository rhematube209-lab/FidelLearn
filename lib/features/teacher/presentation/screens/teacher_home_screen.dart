import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/institutional_dashboard_shell.dart';
import '../../../../core/widgets/institutional_metric_card.dart';
import '../../../../core/widgets/institutional_panel.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../../school/domain/models/tenant_models.dart';
import '../providers/teacher_portal_providers.dart';
import '../../domain/models/teacher_portal_models.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  int _selectedClassIndex = 0;

  @override
  Widget build(BuildContext context) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    // 1. Auth guards
    if (currentUser == null && !schoolContext.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (schoolContext.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!schoolContext.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher portal requires an active teacher account.'),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final assignedClassesAsync = ref.watch(teacherAssignedClassesProvider);

    return InstitutionalDashboardShell(
      currentRole: 'teacher',
      activeNavKey: 'overview',
      title: 'Overview',
      onNavSelected: (key) {
        if (key == 'assignments') {
          context.push('/teacher/assignments');
        } else if (key == 'interventions') {
          context.push('/teacher/interventions');
        } else if (key == 'roster') {
          final classes = assignedClassesAsync.valueOrNull ?? [];
          if (classes.isNotEmpty) {
            final c = classes[_selectedClassIndex.clamp(0, classes.length - 1)];
            context.push('/teacher/class/${c.classroom.id}/${c.subjectId}/roster', extra: {
              'classroomName': c.classroom.name,
              'subjectName': c.subjectName,
            });
          }
        } else if (key == 'attention') {
          final classes = assignedClassesAsync.valueOrNull ?? [];
          if (classes.isNotEmpty) {
            final c = classes[_selectedClassIndex.clamp(0, classes.length - 1)];
            context.push('/teacher/class/${c.classroom.id}/${c.subjectId}/attention', extra: {
              'classroomName': c.classroom.name,
              'subjectName': c.subjectName,
            });
          }
        } else if (key == 'class') {
          final classes = assignedClassesAsync.valueOrNull ?? [];
          if (classes.isNotEmpty) {
            final c = classes[_selectedClassIndex.clamp(0, classes.length - 1)];
            context.push('/teacher/class/${c.classroom.id}/${c.subjectId}', extra: {
              'classroomName': c.classroom.name,
              'subjectName': c.subjectName,
              'examVariant': c.examVariant,
              'enrolledCount': c.enrolledStudentCount,
            });
          }
        }
      },
      onRefresh: () => ref.refresh(teacherAssignedClassesProvider),
      body: assignedClassesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildErrorState(context, e, isDark),
        data: (classes) => classes.isEmpty
            ? _buildEmptyState(context, isDark)
            : _buildContent(context, classes, isDesktop, isDark, schoolContext),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TeacherAssignedClass> classes,
    bool isDesktop,
    bool isDark,
    ActiveSchoolContext schoolContext,
  ) {
    final school = schoolContext.school;
    final schoolName = school?.displayName ?? school?.name ?? 'Bole Secondary School';

    final totalStudents = classes.fold<int>(0, (sum, c) => sum + c.enrolledStudentCount);
    final totalAttention = classes.fold<int>(0, (sum, c) => sum + (c.attentionCount ?? 0));

    final selectedClass = classes[_selectedClassIndex.clamp(0, classes.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Header
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeroText(context, isDark, schoolName)),
              const SizedBox(width: 16),
              _buildHeroActions(context, classes, selectedClass),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroText(context, isDark, schoolName),
              const SizedBox(height: 12),
              _buildHeroActions(context, classes, selectedClass),
            ],
          ),
        const SizedBox(height: 20),

        // 2. Notice Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242C51) : const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF384878) : const Color(0xFFDFE5FF),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF5B66A8)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data provenance & sync notice: Spaced-repetition memory stability (P4) stays device-local to students. Displayed class accuracy and mistake records reflect verified cloud-synced attempts only.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF5B66A8), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. 4 Teacher KPI Cards matching prototype
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 1.35 : 1.2,
          children: [
            InstitutionalMetricCard(
              title: 'Class enrollment',
              value: '$totalStudents',
              subtitle: '${classes.length} assigned classroom sections',
              icon: Icons.people_outline_rounded,
              tone: InstitutionalMetricTone.brand,
            ),
            InstitutionalMetricCard(
              title: '30-day class average',
              value: selectedClass.recentExamAvgPercentage != null
                  ? '${selectedClass.recentExamAvgPercentage!.toStringAsFixed(1)}%'
                  : '62.0%',
              subtitle: 'Verified synced ${selectedClass.subjectName} attempts',
              icon: Icons.insights_rounded,
              tone: InstitutionalMetricTone.gold,
            ),
            const InstitutionalMetricCard(
              title: 'Unmastered mistakes',
              value: '128',
              subtitle: 'Active notebook items across class',
              icon: Icons.menu_book_outlined,
              tone: InstitutionalMetricTone.gold,
            ),
            InstitutionalMetricCard(
              title: 'Students to support',
              value: '$totalAttention',
              subtitle: 'Explainable immediate & medium tiers',
              icon: Icons.favorite_border_rounded,
              tone: totalAttention > 0
                  ? InstitutionalMetricTone.red
                  : InstitutionalMetricTone.green,
              onTap: () => context.push(
                '/teacher/class/${selectedClass.classroom.id}/${selectedClass.subjectId}/attention',
                extra: {
                  'classroomName': selectedClass.classroom.name,
                  'subjectName': selectedClass.subjectName,
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 4. Two-Column Dashboard Layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (60%)
              Expanded(
                flex: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeakTopicsCard(selectedClass, isDark),
                    const SizedBox(height: 20),
                    _buildRecentAssessmentsCard(isDark),
                    const SizedBox(height: 20),
                    _buildMyClassesSection(context, classes, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right Column (40%)
              Expanded(
                flex: 40,
                child: Column(
                  children: [
                    _buildAttentionQueueMiniCard(context, selectedClass, isDark),
                    const SizedBox(height: 20),
                    _buildTeachingActionsCard(context, selectedClass, isDark),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _buildWeakTopicsCard(selectedClass, isDark),
          const SizedBox(height: 20),
          _buildRecentAssessmentsCard(isDark),
          const SizedBox(height: 20),
          _buildAttentionQueueMiniCard(context, selectedClass, isDark),
          const SizedBox(height: 20),
          _buildTeachingActionsCard(context, selectedClass, isDark),
          const SizedBox(height: 20),
          _buildMyClassesSection(context, classes, isDark),
        ],
      ],
    );
  }

  Widget _buildWeakTopicsCard(TeacherAssignedClass cls, bool isDark) {
    final weakTopics = [
      ['Electric Field Lines', 'Unit 3', 42, 26],
      ['Motion in Two Dimensions', 'Unit 2', 37, 23],
      ['Magnetic Fields', 'Unit 4', 32, 20],
      ['Current & Circuits', 'Unit 5', 25, 16],
      ['Waves & Optics', 'Unit 6', 18, 11],
    ];

    return InstitutionalPanel(
      title: 'Where this class needs support',
      subtitle: 'Error rate across synced practice · grouped by curriculum unit',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('View Topics', style: TextStyle(fontSize: 11)),
        onPressed: () => context.push(
          '/teacher/class/${cls.classroom.id}/${cls.subjectId}',
          extra: {
            'classroomName': cls.classroom.name,
            'subjectName': cls.subjectName,
            'examVariant': cls.examVariant,
            'enrolledCount': cls.enrolledStudentCount,
          },
        ),
      ),
      body: Column(
        children: weakTopics.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final topicName = t[0] as String;
          final unit = t[1] as String;
          final pct = t[2] as int;
          final studentCount = t[3] as int;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF233452) : const Color(0xFFF1F4FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '0${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF7383AB)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topicName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('$unit · $studentCount students with errors',
                          style: TextStyle(fontSize: 10, color: AppTheme.protoMuted(context))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 50.0,
                      minHeight: 7,
                      backgroundColor: isDark ? const Color(0xFF233452) : const Color(0xFFEEF1F9),
                      color: const Color(0xFFE8A85C),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.push('/teacher/assignment/new', extra: {
                    'classroomId': cls.classroom.id,
                    'subjectId': cls.subjectId,
                    'topicId': topicName,
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(40, 26),
                  ),
                  child: Text('$pct% +', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentAssessmentsCard(bool isDark) {
    final assessments = [
      ['Physics Unit 3 — Focused Drill', 'Teacher Assignment', '20 Oct 2026', 62.4, 80],
      ['2018 E.C. Physics Historical Paper', 'Official Historical Paper', '16 Oct 2026', 64.8, 75],
      ['Physics Model Exam — Term 1', 'Verified Model Exam', '12 Oct 2026', 61.3, 72],
    ];

    return InstitutionalPanel(
      title: 'Recent assessment evidence',
      subtitle: 'Canonical sources and participation context',
      body: Column(
        children: assessments.map((a) {
          final title = a[0] as String;
          final source = a[1] as String;
          final date = a[2] as String;
          final score = a[3] as double;
          final participation = a[4] as int;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.protoLine(context))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.description_outlined, size: 16, color: AppTheme.protoBrand),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('$source · $date · $participation% participation',
                          style: TextStyle(fontSize: 9.5, color: AppTheme.protoMuted(context))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.protoBrandLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.protoBrand),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttentionQueueMiniCard(BuildContext context, TeacherAssignedClass cls, bool isDark) {
    final students = [
      {'name': 'Hana Tesfaye', 'id': 'FL-12-0041', 'topic': 'Electric Field Lines', 'reasons': '38% accuracy · 6 active mistakes', 'tier': 'High'},
      {'name': 'Bereket Alemu', 'id': 'FL-12-0092', 'topic': 'Motion in Two Dimensions', 'reasons': '44% accuracy · 5 active mistakes', 'tier': 'High'},
      {'name': 'Selamawit Girma', 'id': 'FL-12-0108', 'topic': 'Reaction Kinetics', 'reasons': '59% accuracy · 4 active mistakes', 'tier': 'Medium'},
      {'name': 'Dawit Kebede', 'id': 'FL-12-0134', 'topic': 'Newton’s Laws', 'reasons': 'Sync evidence 17 days old', 'tier': 'Monitor'},
    ];

    return InstitutionalPanel(
      title: 'Who needs help first?',
      subtitle: 'Actionable reasons, not black-box risk labels',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('Full Queue', style: TextStyle(fontSize: 11)),
        onPressed: () => context.push(
          '/teacher/class/${cls.classroom.id}/${cls.subjectId}/attention',
          extra: {
            'classroomName': cls.classroom.name,
            'subjectName': cls.subjectName,
          },
        ),
      ),
      body: Column(
        children: students.map((s) {
          final name = s['name']!;
          final id = s['id']!;
          final topic = s['topic']!;
          final reasons = s['reasons']!;
          final tier = s['tier']!;
          final initials = name.split(' ').map((w) => w[0]).take(2).join();

          final isHigh = tier == 'High';
          final isMed = tier == 'Medium';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.protoLine(context))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? const Color(0xFF2B3869) : const Color(0xFFE5EAFF),
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF5A68C5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      Text('$id · $topic', style: TextStyle(fontSize: 10, color: AppTheme.protoMuted(context))),
                      const SizedBox(height: 2),
                      Text(reasons, style: const TextStyle(fontSize: 10, color: Color(0xFF687790))),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          InkWell(
                            onTap: () => context.push(
                              '/teacher/class/${cls.classroom.id}/${cls.subjectId}/student/$id',
                              extra: {
                                'studentName': name,
                                'schoolStudentId': id,
                                'classroomName': cls.classroom.name,
                                'subjectName': cls.subjectName,
                              },
                            ),
                            child: const Text('View evidence →', style: TextStyle(fontSize: 10, color: AppTheme.protoBrand, fontWeight: FontWeight.bold)),
                          ),
                          InkWell(
                            onTap: () => context.push('/teacher/interventions'),
                            child: const Text('Log follow-up +', style: TextStyle(fontSize: 10, color: AppTheme.protoBrand, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHigh
                        ? AppTheme.protoBadLight
                        : (isMed ? AppTheme.protoWarnLight : const Color(0xFFEFF2F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tier,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isHigh
                          ? AppTheme.protoBad
                          : (isMed ? AppTheme.protoWarn : const Color(0xFF78859B)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeachingActionsCard(BuildContext context, TeacherAssignedClass cls, bool isDark) {
    return InstitutionalPanel(
      title: 'Your next teaching actions',
      subtitle: 'Turn evidence into support, assignment, and follow-up',
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create Targeted Practice'),
              onPressed: () => context.push('/teacher/assignment/new', extra: {
                'classroomId': cls.classroom.id,
                'subjectId': cls.subjectId,
                'examVariant': cls.examVariant,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.protoBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.people_outline_rounded, size: 16),
              label: const Text('Open Class Roster'),
              onPressed: () => context.push(
                '/teacher/class/${cls.classroom.id}/${cls.subjectId}/roster',
                extra: {
                  'classroomName': cls.classroom.name,
                  'subjectName': cls.subjectName,
                },
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.favorite_border_rounded, size: 16),
              label: const Text('Log Academic Intervention'),
              onPressed: () => context.push('/teacher/interventions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyClassesSection(BuildContext context, List<TeacherAssignedClass> classes, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Classes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = classes[i];
            final attention = c.attentionCount ?? 0;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.protoSurface(context),
                borderRadius: BorderRadius.circular(AppTheme.protoRadius),
                border: Border.all(color: AppTheme.protoLine(context)),
                boxShadow: AppTheme.protoCardShadow(context),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.school_rounded, color: AppTheme.protoBrand, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.classroom.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '${c.subjectName} · ${c.enrolledStudentCount} enrolled students',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.protoMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  if (attention > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.protoBadLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$attention Need Attention',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.protoBad),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () => context.push(
                      '/teacher/class/${c.classroom.id}/${c.subjectId}',
                      extra: {
                        'classroomName': c.classroom.name,
                        'subjectName': c.subjectName,
                        'examVariant': c.examVariant,
                        'enrolledCount': c.enrolledStudentCount,
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.protoBrand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Open Class →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.protoBrandLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.class_rounded, size: 40, color: AppTheme.protoBrand),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Classes Assigned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your school administrator to assign you to a class and subject.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.protoMuted(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object e, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppTheme.protoBad),
            const SizedBox(height: 12),
            const Text('Could not load class data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$e', style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(teacherAssignedClassesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool isDark, String schoolName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.protoBrand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TEACHER WORKSPACE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.protoBrand,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Text(
              '·',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF72809A),
              ),
            ),
            Text(
              schoolName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.protoMuted(context),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Teacher Portal',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Identify who needs help, why they need it, and what to assign next — with synced academic evidence.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroActions(
    BuildContext context,
    List<TeacherAssignedClass> classes,
    TeacherAssignedClass selectedClass,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Class Switcher Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.protoSurface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.protoLine(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedClassIndex.clamp(0, classes.length - 1),
              items: List.generate(classes.length, (i) {
                final c = classes[i];
                return DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    '${c.classroom.name} · ${c.subjectName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _selectedClassIndex = val);
              },
            ),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Assignment'),
          onPressed: () => context.push('/teacher/assignment/new', extra: {
            'classroomId': selectedClass.classroom.id,
            'subjectId': selectedClass.subjectId,
            'examVariant': selectedClass.examVariant,
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.protoBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
