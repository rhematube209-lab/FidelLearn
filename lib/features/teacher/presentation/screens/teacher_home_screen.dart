import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../../school/domain/models/tenant_models.dart';
import '../providers/teacher_portal_providers.dart';
import '../../domain/models/teacher_portal_models.dart';
import '../../../../core/providers/app_providers.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auth guards
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
              content:
                  Text('Teacher portal requires an active teacher account.'),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final assignedClassesAsync = ref.watch(teacherAssignedClassesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, schoolContext, isDark),
          if (schoolContext.isOfflineCached)
            SliverToBoxAdapter(child: _buildOfflineBanner(context)),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: assignedClassesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _buildErrorState(context, e, isDark),
                data: (classes) => classes.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _buildContent(context, classes, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ActiveSchoolContext schoolContext,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.brand,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4F46E5), // brandStrong
                Color(0xFF6366F1), // brand
                Color(0xFF818CF8), // lighter brand
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schoolContext.school?.name ?? 'My School',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Teacher Portal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'My Classes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.accent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analytics require connection. Showing last cached class info.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TeacherAssignedClass> classes,
    bool isDark,
  ) {
    // Aggregate stats
    final totalStudents =
        classes.fold<int>(0, (sum, c) => sum + c.enrolledStudentCount);
    final totalAttention =
        classes.fold<int>(0, (sum, c) => sum + (c.attentionCount ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              _StatChip(
                label: 'Students',
                value: '$totalStudents',
                icon: Icons.people_alt_rounded,
                color: AppTheme.brand,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Needs Attention',
                value: '$totalAttention',
                icon: Icons.flag_rounded,
                color: totalAttention > 0 ? AppTheme.accent : AppTheme.green,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Classes',
                value: '${classes.length}',
                icon: Icons.class_rounded,
                color: AppTheme.info,
              ),
            ],
          ),
        ),
        // Classes header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            'My Classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ),
        // Class cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: classes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _ClassCard(cls: classes[i], isDark: isDark),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.class_rounded,
              size: 48,
              color: AppTheme.brand,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Classes Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your school administrator to assign you to a class and subject.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object e, bool isDark) {
    final isAuthError = e.toString().contains('NOT_AUTHORIZED');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(
            isAuthError ? 'Access Denied' : 'Could not load class data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAuthError
                ? 'You are not authorized to view teacher data for this school.'
                : 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(teacherAssignedClassesProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets
// =============================================================================

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherAssignedClass cls;
  final bool isDark;

  const _ClassCard({required this.cls, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final attention = cls.attentionCount ?? 0;
    final avg = cls.recentExamAvgPercentage;

    return GestureDetector(
      onTap: () => context.push(
        '/teacher/class/${cls.classroom.id}/${cls.subjectId}',
        extra: {
          'classroomName': cls.classroom.name,
          'subjectName': cls.subjectName,
          'examVariant': cls.examVariant,
          'enrolledCount': cls.enrolledStudentCount,
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject + grade pill
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    cls.subjectDisplayLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brand,
                    ),
                  ),
                ),
                const Spacer(),
                if (attention > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag_rounded,
                            size: 12, color: AppTheme.accent),
                        const SizedBox(width: 3),
                        Text(
                          '$attention need attention',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Class name
            Text(
              cls.classroom.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 6),
            // Metrics row
            Row(
              children: [
                _MetricPill(
                  icon: Icons.people_rounded,
                  label: '${cls.enrolledStudentCount} students',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                if (avg != null)
                  _MetricPill(
                    icon: Icons.bar_chart_rounded,
                    label: 'Avg ${avg.toStringAsFixed(0)}%',
                    isDark: isDark,
                    highlight: avg < 60,
                  ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppTheme.brand),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool highlight;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? AppTheme.accent
        : (isDark ? AppTheme.darkTextSoft : AppTheme.lightMuted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
