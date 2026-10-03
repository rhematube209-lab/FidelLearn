import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/active_school_context_provider.dart';
import '../providers/school_leadership_providers.dart';
import '../../domain/models/school_leadership_models.dart';
import '../../domain/models/tenant_models.dart';

/// School Leadership Home Dashboard.
///
/// Designed for institutional decision-makers:
/// Principals, Academic Directors, Vice Principals, and School Administrators.
class SchoolLeadershipHomeScreen extends ConsumerStatefulWidget {
  const SchoolLeadershipHomeScreen({super.key});

  @override
  ConsumerState<SchoolLeadershipHomeScreen> createState() =>
      _SchoolLeadershipHomeScreenState();
}

class _SchoolLeadershipHomeScreenState
    extends ConsumerState<SchoolLeadershipHomeScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    // 1. Auth Guard: Authenticated user required
    if (currentUser == null && !schoolContext.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.go('/login');
          } catch (_) {}
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (schoolContext.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Role Guard: Active school admin membership in active school required
    if (!schoolContext.isSchoolAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.go('/home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Access denied: School Leadership Dashboard requires an active school administrator account.',
                ),
                backgroundColor: AppTheme.danger,
              ),
            );
          } catch (_) {}
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summaryAsync = ref.watch(schoolLeadershipSummaryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, schoolContext, isDark),
          if (schoolContext.isOfflineCached)
            SliverToBoxAdapter(child: _buildOfflineNotice(context)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32.0 : 16.0,
                    vertical: 24.0,
                  ),
                  child: summaryAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _buildErrorBanner(context, e, isDark),
                    data: (summary) => _buildDashboardContent(
                        context, summary, isDesktop, isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ActiveSchoolContext schoolContext,
    bool isDark,
  ) {
    final school = schoolContext.school;
    final schoolName = school?.displayName ?? school?.name ?? 'School';
    final schoolCode = school?.schoolCode ?? '';
    final region = school?.region ?? 'Ethiopia';

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 2,
      backgroundColor: const Color(0xFF1E293B),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          tooltip: 'Refresh analytics',
          onPressed: () {
            ref.invalidate(schoolLeadershipSummaryProvider);
            ref.invalidate(schoolStreamSummaryProvider);
            ref.invalidate(schoolSubjectSummaryProvider);
            ref.invalidate(schoolClassSummaryProvider);
            ref.invalidate(schoolSystemicWeakTopicsProvider);
            ref.invalidate(schoolAssessmentsOverviewProvider);
            ref.invalidate(schoolTeacherCoverageProvider);
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.only(left: 72, right: 24, bottom: 20),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppTheme.brand.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'INSTITUTIONAL LEADERSHIP',
                      style: TextStyle(
                        color: AppTheme.brandSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Code: $schoolCode',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                schoolName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Region: $region • Academic Year: 2026/27 (Active)',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineNotice(BuildContext context) {
    return Container(
      color: Colors.amber.shade900.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Leadership analytics require an internet connection. School identity is active, but live institutional analytics require network connectivity.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, Object error, bool isDark) {
    final isOffline = error is SchoolLeadershipOfflineException ||
        error.toString().toLowerCase().contains('internet connection') ||
        error.toString().toLowerCase().contains('offline');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (isOffline ? AppTheme.accent : AppTheme.danger).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: isOffline ? AppTheme.accent : AppTheme.danger,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isOffline
                ? 'Analytics Unavailable Offline'
                : 'Failed to load leadership analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOffline
                ? 'Leadership analytics require an active internet connection. Reconnect to load current school analytics.'
                : error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => ref.invalidate(schoolLeadershipSummaryProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Executive Metric Grid
        _buildExecutiveMetricsGrid(context, s, isDesktop, isDark),
        const SizedBox(height: 32),

        // 2. Navigation Tabs
        _buildNavigationTabs(context, isDark),
        const SizedBox(height: 24),

        // 3. Tab Body
        if (_selectedTabIndex == 0) ...[
          _buildNationalExamPrepSection(context, s, isDesktop, isDark),
          const SizedBox(height: 32),
          _buildStreamComparisonSection(context, isDesktop, isDark),
          const SizedBox(height: 32),
          _buildSubjectPerformanceSection(context, isDesktop, isDark),
        ] else if (_selectedTabIndex == 1) ...[
          _buildStreamComparisonSection(context, isDesktop, isDark),
        ] else if (_selectedTabIndex == 2) ...[
          _buildSubjectPerformanceSection(context, isDesktop, isDark),
        ] else if (_selectedTabIndex == 3) ...[
          _buildClassComparisonSection(context, isDesktop, isDark),
        ] else if (_selectedTabIndex == 4) ...[
          _buildSupportPopulationSection(context, s, isDesktop, isDark),
        ] else if (_selectedTabIndex == 5) ...[
          _buildRecentAssessmentsSection(context, isDesktop, isDark),
        ] else if (_selectedTabIndex == 6) ...[
          _buildTeacherCoverageSection(context, s, isDesktop, isDark),
        ],

        const SizedBox(height: 48),
        _buildDataIntegrityFootnote(context, s, isDark),
      ],
    );
  }

  Widget _buildExecutiveMetricsGrid(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    final crossAxisCount = isDesktop ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.6 : 1.3,
      children: [
        _buildMetricCard(
          title: 'Total Enrolled Students',
          value: '${s.totalActiveStudents}',
          subtitle:
              '${s.naturalStreamStudents} Natural • ${s.socialStreamStudents} Social',
          icon: Icons.people_alt_outlined,
          color: AppTheme.brand,
          isDark: isDark,
        ),
        _buildMetricCard(
          title: 'Simulation Prep Average',
          value: s.recentSimulationCount > 0
              ? '${s.recentSimulationAvgPct.toStringAsFixed(1)}%'
              : 'No Data',
          subtitle:
              '${(s.simulationParticipationRate * 100).toStringAsFixed(0)}% school participation',
          icon: Icons.insights_rounded,
          color: AppTheme.accent,
          isDark: isDark,
        ),
        _buildMetricCard(
          title: 'Students Needing Support',
          value: '${s.uniqueStudentsNeedingHelp}',
          subtitle:
              '${s.highSeverityStudentCount} High • ${s.staleSyncStudentCount} Stale sync',
          icon: Icons.support_agent_rounded,
          color: s.highSeverityStudentCount > 0
              ? AppTheme.danger
              : AppTheme.accent,
          isDark: isDark,
          onTap: () => setState(() => _selectedTabIndex = 4),
        ),
        _buildMetricCard(
          title: 'Teacher Staffing Coverage',
          value: '${(s.teacherAssignmentCoverage * 100).toStringAsFixed(0)}%',
          subtitle: s.unassignedSubjectSlots > 0
              ? '${s.unassignedSubjectSlots} unassigned slots'
              : 'All sections covered',
          icon: Icons.badge_outlined,
          color:
              s.unassignedSubjectSlots > 0 ? AppTheme.accent : AppTheme.green,
          isDark: isDark,
          onTap: () => setState(() => _selectedTabIndex = 6),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: isDark ? null : AppTheme.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.darkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context, bool isDark) {
    final tabs = [
      'Overview',
      'Streams',
      'Subjects',
      'Sections',
      'Student Support',
      'Assessments',
      'Teacher Coverage',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              selectedColor: AppTheme.brand,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedTabIndex = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNationalExamPrepSection(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 16,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'National Exam Preparation Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Derived from cloud-synced national exam simulations (ESSLCE Mock Full).',
                    style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View All Assessments'),
                onPressed: () => setState(() => _selectedTabIndex = 5),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSubStat(
                  'Simulation Average',
                  s.recentSimulationCount > 0
                      ? '${s.recentSimulationAvgPct.toStringAsFixed(1)}%'
                      : 'No Data',
                  'Latest completed attempt per student',
                  AppTheme.brand,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSubStat(
                  'Simulation Median',
                  s.recentSimulationCount > 0
                      ? '${s.recentSimulationMedianPct.toStringAsFixed(1)}%'
                      : 'No Data',
                  '50th percentile of cohort scores',
                  AppTheme.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSubStat(
                  'Participation Rate',
                  '${(s.simulationParticipationRate * 100).toStringAsFixed(0)}%',
                  'Of ${s.totalActiveStudents} total enrolled students',
                  AppTheme.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Academic Honesty Notice: Canonical student readiness scores and P4 mastery state (fidel_spaced_v1.0) remain device-local to student phones and are not fabricated at the school level. The above metrics reflect cloud-synchronized simulation exams only.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(
    String label,
    String value,
    String footnote,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.darkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamComparisonSection(
    BuildContext context,
    bool isDesktop,
    bool isDark,
  ) {
    final streamsAsync = ref.watch(schoolStreamSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Comparison — Natural Science vs Social Science',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cohorts are evaluated on stream-specific benchmarks without cross-curriculum bias.',
          style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
        ),
        const SizedBox(height: 16),
        streamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading streams: $e'),
          data: (streams) {
            if (streams.isEmpty) {
              return const Text('No stream data available.');
            }
            return Row(
              children: streams.map((stream) {
                final isNat = stream.stream == 'naturalScience';
                final color = isNat ? AppTheme.brand : AppTheme.accent;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: isNat && isDesktop ? 16 : 0,
                      left: !isNat && isDesktop ? 16 : 0,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          spacing: 12,
                          children: [
                            Text(
                              stream.streamLabel,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${stream.enrolledStudents} Students • ${stream.activeClassrooms} Sections',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRowStat(
                          'Simulation Average',
                          '${stream.recentSimulationAvgPct.toStringAsFixed(1)}%',
                        ),
                        _buildRowStat(
                          'Simulation Median',
                          '${stream.recentSimulationMedianPct.toStringAsFixed(1)}%',
                        ),
                        _buildRowStat(
                          'Participation Rate',
                          '${(stream.simulationParticipationRate * 100).toStringAsFixed(0)}%',
                        ),
                        _buildRowStat(
                          'Active Mistakes',
                          '${stream.activeMistakeCount} unmastered',
                        ),
                        _buildRowStat(
                          'Fresh Data Coverage',
                          '${(stream.freshDataCoverageRate * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRowStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.darkMuted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceSection(
    BuildContext context,
    bool isDesktop,
    bool isDark,
  ) {
    final subjectsAsync = ref.watch(schoolSubjectSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Performance & Weakness Signals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Mathematics variants (Natural vs Social) are segregated. Weakness is measured by active mistake concentration.',
          style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
        ),
        const SizedBox(height: 16),
        subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading subjects: $e'),
          data: (subjects) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = subjects[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.enrolledStudentCount} enrolled • ${s.teacherAssignedCount} teachers',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.attemptCount > 0
                                  ? '${s.avgPercentage.toStringAsFixed(1)}% Avg'
                                  : 'No attempts',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(s.participationRate * 100).toStringAsFixed(0)}% participation',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.activeMistakeCount} mistakes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: s.activeMistakeCount > 50
                                    ? AppTheme.accent
                                    : AppTheme.green,
                              ),
                            ),
                            Text(
                              '${s.affectedStudentCount} affected students',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: s.hasTeacherCoverage
                              ? AppTheme.green.withOpacity(0.12)
                              : AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.hasTeacherCoverage ? 'COVERED' : 'UNASSIGNED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: s.hasTeacherCoverage
                                ? AppTheme.green
                                : AppTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassComparisonSection(
    BuildContext context,
    bool isDesktop,
    bool isDark,
  ) {
    final classesAsync = ref.watch(schoolClassSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class / Section Comparative Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'All sections are presented neutrally for intervention support without ranking labels.',
          style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
        ),
        const SizedBox(height: 16),
        classesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading classes: $e'),
          data: (classes) {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.5 : 2.0,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final c = classes[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c.classroomName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${c.enrolledStudents} Students',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkMuted,
                            ),
                          ),
                        ],
                      ),
                      _buildRowStat(
                        'Recent Average',
                        c.recentAttemptCount > 0
                            ? '${c.avgPercentage.toStringAsFixed(1)}%'
                            : 'No data',
                      ),
                      _buildRowStat(
                        'Participation Rate',
                        '${(c.participationRate * 100).toStringAsFixed(0)}%',
                      ),
                      _buildRowStat(
                        'Active Mistakes',
                        '${c.activeMistakeCount} records',
                      ),
                      _buildRowStat(
                        'Assigned Teachers',
                        '${c.assignedTeacherCount} staff',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupportPopulationSection(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    final supportState = ref.watch(schoolSupportPopulationProvider);
    final notifier = ref.read(schoolSupportPopulationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Students Needing Academic Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.uniqueStudentsNeedingHelp} unique students flagged across the school with explainable reasons.',
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.darkMuted),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSeverityFilterChip(
                    'ALL', null, supportState.severityFilter, notifier),
                _buildSeverityFilterChip(
                    'HIGH', 'high', supportState.severityFilter, notifier),
                _buildSeverityFilterChip(
                    'MEDIUM', 'medium', supportState.severityFilter, notifier),
                _buildSeverityFilterChip(
                    'LOW', 'low', supportState.severityFilter, notifier),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (supportState.isLoading && supportState.students.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (supportState.students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No students currently flagged under this severity level.',
                style: TextStyle(fontSize: 14, color: AppTheme.darkMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supportState.students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final stu = supportState.students[index];
              final isHigh = stu.severity == AttentionSeverity.high;
              final isMed = stu.severity == AttentionSeverity.medium;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHigh
                        ? AppTheme.danger.withOpacity(0.3)
                        : (isMed
                            ? AppTheme.accent.withOpacity(0.3)
                            : (isDark ? Colors.white12 : Colors.grey.shade200)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isHigh
                                ? AppTheme.danger
                                : (isMed ? AppTheme.accent : AppTheme.green))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isHigh
                            ? Icons.priority_high_rounded
                            : (isMed
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline_rounded),
                        color: isHigh
                            ? AppTheme.danger
                            : (isMed ? AppTheme.accent : AppTheme.green),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stu.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stu.classroomName} • ID: ${stu.schoolStudentId ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: stu.reasonExplanations.map((exp) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exp,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stu.recentAccuracyPercentage != null
                                ? '${stu.recentAccuracyPercentage!.toStringAsFixed(0)}% Acc'
                                : 'No practice',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${stu.activeMistakeCount} mistakes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkMuted,
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
      ],
    );
  }

  Widget _buildSeverityFilterChip(
    String label,
    String? filterVal,
    String? currentFilter,
    SchoolSupportPopulationNotifier notifier,
  ) {
    final isSelected = (filterVal == null && currentFilter == null) ||
        (filterVal != null &&
            currentFilter != null &&
            filterVal.toLowerCase() == currentFilter.toLowerCase());

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.filterBySeverity(filterVal),
    );
  }

  Widget _buildRecentAssessmentsSection(
    BuildContext context,
    bool isDesktop,
    bool isDark,
  ) {
    final assessAsync = ref.watch(schoolAssessmentsOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'School-Wide Assessments Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Preserves canonical P5 provenance. Averages reflect the latest attempt per student per exam.',
          style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
        ),
        const SizedBox(height: 16),
        assessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading assessments: $e'),
          data: (assessments) {
            if (assessments.isEmpty) {
              return const Text('No assessments completed yet.');
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assessments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = assessments[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.examTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${a.subjectName} • ${a.totalQuestions} Questions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.provenanceLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandSubtle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${a.avgPercentage.toStringAsFixed(1)}% Avg',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Median: ${a.medianPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${a.participantCount} / ${a.eligibleCount}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${a.participationPct.toStringAsFixed(0)}% participated',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeacherCoverageSection(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    final covAsync = ref.watch(schoolTeacherCoverageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teacher Staffing & Subject Coverage Oversight',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Operational view of classroom-subject coverage to identify staffing gaps. Non-evaluative.',
          style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
        ),
        const SizedBox(height: 16),
        covAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading teacher coverage: $e'),
          data: (slots) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: slot.isAssigned
                          ? (isDark ? Colors.white12 : Colors.grey.shade200)
                          : AppTheme.accent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            slot.isAssigned
                                ? Icons.check_circle_rounded
                                : Icons.warning_rounded,
                            color: slot.isAssigned
                                ? AppTheme.green
                                : AppTheme.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${slot.classroomName} — ${slot.subjectName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        slot.isAssigned
                            ? 'Assigned: ${slot.teacherName ?? "Teacher"}'
                            : 'NO TEACHER ASSIGNED',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: slot.isAssigned
                              ? (isDark ? Colors.white70 : Colors.black87)
                              : AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataIntegrityFootnote(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 18, color: AppTheme.brand),
              const SizedBox(width: 8),
              Text(
                'Data Freshness & Transparency Footnote',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'School Fresh Data Coverage: ${(s.freshDataCoverageRate * 100).toStringAsFixed(0)}%. '
            'Students whose devices have not synced within the last 14 days (${s.staleSyncStudentCount} students) '
            'are flagged for freshness review. Note: Offline student study continues uninterrupted without internet.',
            style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted),
          ),
        ],
      ),
    );
  }
}
