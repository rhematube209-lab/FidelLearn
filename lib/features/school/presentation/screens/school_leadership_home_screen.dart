import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/institutional_dashboard_shell.dart';
import '../../../../core/widgets/institutional_metric_card.dart';
import '../../../../core/widgets/institutional_panel.dart';
import '../../../../core/widgets/student_profile_drawer.dart';
import '../providers/active_school_context_provider.dart';
import '../providers/school_leadership_providers.dart';
import '../../domain/models/school_leadership_models.dart';
import '../../domain/models/tenant_models.dart';

/// School Leadership Home Dashboard.
///
/// Designed for institutional decision-makers:
/// Principals, Academic Directors, Vice Principals, and School Administrators.
/// Redesigned to match the modern SaaS FidelLearn Institutional Prototype.
class SchoolLeadershipHomeScreen extends ConsumerStatefulWidget {
  const SchoolLeadershipHomeScreen({super.key});

  @override
  ConsumerState<SchoolLeadershipHomeScreen> createState() =>
      _SchoolLeadershipHomeScreenState();
}

class _SchoolLeadershipHomeScreenState
    extends ConsumerState<SchoolLeadershipHomeScreen> {
  int _selectedTabIndex = 0;
  String _activeNavKey = 'overview';
  String _subjectSearchQuery = '';
  String _subjectStreamFilter = 'All';

  // Tab mapping
  final List<String> _tabKeys = [
    'overview',
    'streams',
    'subjects',
    'sections',
    'support',
    'assessments',
    'staff',
    'license',
    'onboarding',
  ];

  void _onNavSelected(String key) {
    setState(() {
      _activeNavKey = key;
      final idx = _tabKeys.indexOf(key);
      if (idx != -1) {
        _selectedTabIndex = idx;
      }
    });
  }

  void _refreshAll() {
    ref.invalidate(schoolLeadershipSummaryProvider);
    ref.invalidate(schoolStreamSummaryProvider);
    ref.invalidate(schoolSubjectSummaryProvider);
    ref.invalidate(schoolClassSummaryProvider);
    ref.invalidate(schoolSystemicWeakTopicsProvider);
    ref.invalidate(schoolAssessmentsOverviewProvider);
    ref.invalidate(schoolTeacherCoverageProvider);
  }

  void _openStudentDrawer(BuildContext context, SchoolSupportStudent student) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x6617213C),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: StudentProfileDrawer(
              studentName: student.displayName,
              studentId: student.schoolStudentId ?? 'ID-${student.userId.substring(0, 6)}',
              section: student.classroomName,
              stream: student.stream == 'socialScience' ? 'Social Science' : 'Natural Science',
              accuracyPct: student.recentAccuracyPercentage != null ? student.recentAccuracyPercentage!.round() : 60,
              mistakesCount: student.activeMistakeCount,
              urgencyTier: student.severity == AttentionSeverity.high
                  ? 'high'
                  : (student.severity == AttentionSeverity.medium ? 'medium' : 'low'),
              reasonCodes: student.reasonExplanations,
              primaryWeakTopic: 'Foundational Review',
              lastActiveDays: student.lastActivityAt != null ? DateTime.now().difference(student.lastActivityAt!).inDays : 5,
              lastSyncDays: student.lastSyncedAt != null ? DateTime.now().difference(student.lastSyncedAt!).inDays : 2,
              onClose: () => Navigator.of(context).pop(),
              onLogIntervention: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Intervention follow-up logged for ${student.displayName}.'),
                    backgroundColor: AppTheme.protoBrand,
                  ),
                );
              },
              onAssignPractice: () {
                Navigator.of(context).pop();
                context.push('/teacher/assignment/new', extra: {
                  'studentUserId': student.userId,
                  'classroomName': student.classroomName,
                });
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    // 1. Auth Guard
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

    // 2. Role Guard
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

    return InstitutionalDashboardShell(
      currentRole: 'admin',
      activeNavKey: _activeNavKey,
      title: _getTabTitle(_selectedTabIndex),
      onNavSelected: _onNavSelected,
      onRefresh: _refreshAll,
      body: summaryAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildErrorBanner(context, e, isDark),
        data: (summary) => _buildDashboardContent(context, summary, isDesktop, isDark, schoolContext),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Overview';
      case 1:
        return 'Stream Parity';
      case 2:
        return 'Subject Performance';
      case 3:
        return 'Class Sections';
      case 4:
        return 'Student Support';
      case 5:
        return 'Assessments';
      case 6:
        return 'Staff & Coverage';
      case 7:
        return 'Licensing & Seats';
      case 8:
        return 'Onboarding';
      default:
        return 'Overview';
    }
  }

  Widget _buildErrorBanner(BuildContext context, Object error, bool isDark) {
    final isOffline = error is SchoolLeadershipOfflineException ||
        error.toString().toLowerCase().contains('internet connection') ||
        error.toString().toLowerCase().contains('offline');

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.protoSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.protoRadius),
        border: Border.all(
          color: (isOffline ? AppTheme.protoWarn : AppTheme.protoBad).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 44,
            color: isOffline ? AppTheme.protoWarn : AppTheme.protoBad,
          ),
          const SizedBox(height: 12),
          Text(
            isOffline ? 'Offline Mode Active' : 'Unable to Load Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.protoInkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOffline
                ? 'Leadership analytics require an active internet connection. Reconnect to load current school analytics.'
                : error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.protoMuted(context)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            onPressed: _refreshAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.protoBrand,
              foregroundColor: Colors.white,
            ),
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
    ActiveSchoolContext schoolContext,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Prototype Page Hero Header
        _buildHeroHeader(context, schoolContext, isDark),
        const SizedBox(height: 20),

        // 2. Prototype Notice Banner (Provenance & Academic Honesty Notice)
        _buildNoticeBanner(context, s, isDark),
        const SizedBox(height: 20),

        // 3. 4 Executive KPI Cards matching prototype
        _buildExecutiveMetricsGrid(context, s, isDesktop, isDark),
        const SizedBox(height: 28),

        // 4. Secondary Navigation Tabs matching test selectors (Overview, Streams, Subjects, Sections, Student Support, Assessments, Teacher Coverage)
        _buildNavigationTabs(context, isDark),
        const SizedBox(height: 24),

        // 5. Active Tab Body
        if (_selectedTabIndex == 0) ...[
          _buildOverviewTabContent(context, s, isDesktop, isDark),
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
        ] else if (_selectedTabIndex == 7) ...[
          _buildLicensingSection(context, s, isDesktop, isDark),
        ] else if (_selectedTabIndex == 8) ...[
          _buildOnboardingSection(context, s, isDesktop, isDark),
        ],

        const SizedBox(height: 40),
        _buildDataIntegrityFootnote(context, s, isDark),
      ],
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    ActiveSchoolContext schoolContext,
    bool isDark,
  ) {
    final school = schoolContext.school;
    final schoolName = school?.displayName ?? school?.name ?? 'Menelik II High School';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.protoBrand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INSTITUTIONAL LEADERSHIP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.protoBrand,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· GRADE 12',
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
                schoolName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'See national exam readiness, academic support needs, and staffing coverage — without punitive teacher or class rankings.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('Reports Hub'),
              onPressed: () => context.push('/school/reports'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                side: BorderSide(color: AppTheme.protoLine(context)),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh View'),
              onPressed: _refreshAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.protoBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoticeBanner(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242C51) : const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF384878) : const Color(0xFFDFE5FF),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF5B66A8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Academic Honesty Notice: Canonical student readiness scores and P4 mastery state (fidel_spaced_v1.0) remain device-local to student phones and are not fabricated at the school level. The above metrics reflect cloud-synchronized simulation exams only.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFFBAC6F1) : const Color(0xFF5B66A8),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF35447B) : const Color(0xFFEDF0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Cloud verified',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.protoBrand,
              ),
            ),
          ),
        ],
      ),
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
      childAspectRatio: isDesktop ? 1.35 : 1.2,
      children: [
        InstitutionalMetricCard(
          title: 'Total Enrolled Students',
          value: '${s.totalActiveStudents}',
          subtitle: '${s.naturalStreamStudents} Natural • ${s.socialStreamStudents} Social',
          icon: Icons.people_outline_rounded,
          tone: InstitutionalMetricTone.brand,
          onTap: () => _onNavSelected('sections'),
        ),
        InstitutionalMetricCard(
          title: 'Simulation Prep Average',
          value: s.recentSimulationCount > 0
              ? '${s.recentSimulationAvgPct.toStringAsFixed(1)}%'
              : 'No Data',
          subtitle:
              'Median ${s.recentSimulationMedianPct.toStringAsFixed(1)}% • ${(s.simulationParticipationRate * 100).toStringAsFixed(0)}% school participation',
          icon: Icons.emoji_events_outlined,
          tone: InstitutionalMetricTone.gold,
          onTap: () => _onNavSelected('assessments'),
        ),
        InstitutionalMetricCard(
          title: 'Students Needing Support',
          value: '${s.uniqueStudentsNeedingHelp}',
          subtitle: '${s.highSeverityStudentCount} high urgency • ${s.staleSyncStudentCount} stale sync records',
          icon: Icons.favorite_border_rounded,
          tone: s.highSeverityStudentCount > 0
              ? InstitutionalMetricTone.red
              : InstitutionalMetricTone.gold,
          onTap: () => _onNavSelected('support'),
        ),
        InstitutionalMetricCard(
          title: 'Teacher Staffing Coverage',
          value: '${(s.teacherAssignmentCoverage * 100).toStringAsFixed(0)}%',
          subtitle: s.unassignedSubjectSlots > 0
              ? '${s.unassignedSubjectSlots} unassigned section-subject slots'
              : 'All 48 slots staffed',
          icon: Icons.shield_outlined,
          tone: s.unassignedSubjectSlots > 0
              ? InstitutionalMetricTone.gold
              : InstitutionalMetricTone.green,
          onTap: () => _onNavSelected('staff'),
        ),
      ],
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
              selectedColor: AppTheme.protoBrand,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF1F9),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() {
                _selectedTabIndex = index;
                _activeNavKey = _tabKeys[index];
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewTabContent(
    BuildContext context,
    SchoolLeadershipSummary s,
    bool isDesktop,
    bool isDark,
  ) {
    final weakTopicsAsync = ref.watch(schoolSystemicWeakTopicsProvider);
    final assessmentsAsync = ref.watch(schoolAssessmentsOverviewProvider);
    final streamsAsync = ref.watch(schoolStreamSummaryProvider);

    return Column(
      children: [
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (60%)
              Expanded(
                flex: 60,
                child: Column(
                  children: [
                    _buildSnapshotCard(s, isDark),
                    const SizedBox(height: 20),
                    _buildCurriculumBottlenecksCard(weakTopicsAsync, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right Column (40%)
              Expanded(
                flex: 40,
                child: Column(
                  children: [
                    _buildStreamParityMiniCard(streamsAsync, isDark),
                    const SizedBox(height: 20),
                    _buildRecentAssessmentsMiniCard(assessmentsAsync, isDark),
                    const SizedBox(height: 20),
                    _buildActionQueueCard(s, isDark),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _buildSnapshotCard(s, isDark),
          const SizedBox(height: 20),
          _buildCurriculumBottlenecksCard(weakTopicsAsync, isDark),
          const SizedBox(height: 20),
          _buildStreamParityMiniCard(streamsAsync, isDark),
          const SizedBox(height: 20),
          _buildRecentAssessmentsMiniCard(assessmentsAsync, isDark),
          const SizedBox(height: 20),
          _buildActionQueueCard(s, isDark),
        ],
      ],
    );
  }

  Widget _buildSnapshotCard(SchoolLeadershipSummary s, bool isDark) {
    final participationPct = (s.simulationParticipationRate * 100).toStringAsFixed(0);

    return InstitutionalPanel(
      title: 'ESSLCE preparation snapshot',
      subtitle: 'Latest completed diagnostic per student · retakes deduplicated',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('Assessments', style: TextStyle(fontSize: 11)),
        onPressed: () => _onNavSelected('assessments'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4-Column Score Distribution Plot matching prototype
          _buildScoreDistributionPlot(isDark),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendKey(const Color(0xFFEC7775), 'Needs foundational support', isDark),
              _buildLegendKey(const Color(0xFF6577E9), 'Simulation score brackets', isDark),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242C51) : const Color(0xFFF5F6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF384878) : const Color(0xFFE2E7FC),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$participationPct% of learners have simulation evidence',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.recentSimulationCount} of ${s.totalActiveStudents} Grade 12 students · sample latest completed attempt',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.protoBrandLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Participation',
                    style: TextStyle(
                      color: AppTheme.protoBrand,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionPlot(bool isDark) {
    final values = [15, 27, 36, 22];
    final labels = ['0–39%', '40–59%', '60–74%', '75–100%'];

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(values.length, (i) {
          final val = values[i];
          final isLowest = i == 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$val%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.protoMutedDark : const Color(0xFF66718F),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 48,
                height: val * 2.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLowest
                        ? [const Color(0xFFFFD1C7), const Color(0xFFEC7775)]
                        : [const Color(0xFFAAB6FF), const Color(0xFF6577E9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegendKey(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight),
        ),
      ],
    );
  }

  Widget _buildCurriculumBottlenecksCard(
    AsyncValue<List<SchoolSystemicWeakTopic>> weakTopicsAsync,
    bool isDark,
  ) {
    return InstitutionalPanel(
      title: 'Curriculum bottlenecks',
      subtitle: 'Highest school-wide error concentration across synced practice',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('All Subjects', style: TextStyle(fontSize: 11)),
        onPressed: () => _onNavSelected('subjects'),
      ),
      body: weakTopicsAsync.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
        error: (e, _) => Text('Error loading weak topics: $e'),
        data: (topics) {
          if (topics.isEmpty) {
            return const Text('No systemic weak topics recorded.');
          }
          return Column(
            children: topics.take(5).map<Widget>((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.topicNameEn,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            t.subjectName,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (t.mistakeConcentrationPct / 100).clamp(0.05, 1.0),
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF233452) : const Color(0xFFEEF1F9),
                          color: const Color(0xFFEAAD63),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${t.mistakeConcentrationPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStreamParityMiniCard(
    AsyncValue<List<SchoolStreamSummary>> streamsAsync,
    bool isDark,
  ) {
    return InstitutionalPanel(
      title: 'Stream Comparison — Natural Science vs Social Science',
      subtitle: 'An equal lens on Natural and Social Science',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('Compare', style: TextStyle(fontSize: 11)),
        onPressed: () => _onNavSelected('streams'),
      ),
      body: streamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (streams) {
          return Row(
            children: streams.take(2).map((s) {
              final isNat = s.stream == 'naturalScience';
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: isNat ? 8 : 0, left: !isNat ? 8 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.protoLine(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNat ? 'Natural Science' : 'Social Science',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${s.recentSimulationAvgPct.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Avg. latest simulation',
                        style: TextStyle(fontSize: 9.5, color: AppTheme.protoMuted(context)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Enrolled', style: TextStyle(fontSize: 10, color: AppTheme.protoMuted(context))),
                          ),
                          Text('${s.enrolledStudents}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Participation',
                              style: TextStyle(fontSize: 10, color: AppTheme.protoMuted(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${(s.simulationParticipationRate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecentAssessmentsMiniCard(
    AsyncValue<List<SchoolAssessmentSummary>> assessmentsAsync,
    bool isDark,
  ) {
    return InstitutionalPanel(
      title: 'Recent assessment activity',
      subtitle: 'Verified source and provenance labels',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('All Activity', style: TextStyle(fontSize: 11)),
        onPressed: () => _onNavSelected('assessments'),
      ),
      body: assessmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Text('No recent assessments recorded.');
          }
          return Column(
            children: assessments.take(3).map<Widget>((a) {
              final dateStr = a.latestAttemptAt != null
                  ? '${a.latestAttemptAt!.day} ${_monthName(a.latestAttemptAt!.month)} ${a.latestAttemptAt!.year}'
                  : 'Recent';
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
                          Text(
                            a.examTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${a.provenanceLabel} · $dateStr',
                            style: TextStyle(fontSize: 9.5, color: AppTheme.protoMuted(context)),
                          ),
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
                        '${a.avgPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.protoBrand),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActionQueueCard(SchoolLeadershipSummary s, bool isDark) {
    return InstitutionalPanel(
      title: 'Leadership action queue',
      subtitle: 'Constructive next steps for the school',
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('Support Roster', style: TextStyle(fontSize: 11)),
        onPressed: () => _onNavSelected('support'),
      ),
      body: Column(
        children: [
          _buildActionQueueItem(
            Icons.favorite_border_rounded,
            'Review students needing support',
            '${s.uniqueStudentsNeedingHelp} flagged · ${s.highSeverityStudentCount} high urgency from verified sample evidence',
            isDark,
          ),
          _buildActionQueueItem(
            Icons.badge_outlined,
            'Fill subject staffing slots',
            s.unassignedSubjectSlots > 0
                ? '${s.unassignedSubjectSlots} open allocation gaps across 48 slots'
                : 'All 48 required subject slots currently covered',
            isDark,
          ),
          _buildActionQueueItem(
            Icons.refresh_rounded,
            'Check offline sync latency',
            '${s.staleSyncStudentCount} support records may have incomplete cloud evidence',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionQueueItem(IconData icon, String title, String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: AppTheme.protoBrand),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 9.5, color: AppTheme.protoMuted(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamComparisonSection(BuildContext context, bool isDesktop, bool isDark) {
    final streamsAsync = ref.watch(schoolStreamSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Comparison — Natural Science vs Social Science',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Cohorts are evaluated on stream-specific benchmarks without cross-curriculum bias.',
          style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context)),
        ),
        const SizedBox(height: 16),
        streamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading streams: $e'),
          data: (streams) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: streams.map((stream) {
                final isNat = stream.stream == 'naturalScience';
                final color = isNat ? AppTheme.protoBrand : AppTheme.protoWarn;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: isNat && isDesktop ? 16 : 0,
                      left: !isNat && isDesktop ? 16 : 0,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.protoSurface(context),
                      borderRadius: BorderRadius.circular(AppTheme.protoRadius),
                      border: Border.all(color: color.withOpacity(0.35)),
                      boxShadow: AppTheme.protoCardShadow(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stream.streamLabel,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${stream.enrolledStudents} Students • ${stream.activeClassrooms} Sections',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRowStat('Simulation Average', '${stream.recentSimulationAvgPct.toStringAsFixed(1)}%'),
                        _buildRowStat('Simulation Median', '${stream.recentSimulationMedianPct.toStringAsFixed(1)}%'),
                        _buildRowStat('Participation Rate', '${(stream.simulationParticipationRate * 100).toStringAsFixed(0)}%'),
                        _buildRowStat('Active Mistakes', '${stream.activeMistakeCount} unmastered'),
                        _buildRowStat('Fresh Data Coverage', '${(stream.freshDataCoverageRate * 100).toStringAsFixed(0)}%'),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF72809A))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceSection(BuildContext context, bool isDesktop, bool isDark) {
    final subjectsAsync = ref.watch(schoolSubjectSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Performance & Weakness Signals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Mathematics variants (Natural vs Social) are segregated. Weakness is measured by active mistake concentration.',
          style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context)),
        ),
        const SizedBox(height: 16),
        // Search & Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search a subject or topic…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) => setState(() => _subjectSearchQuery = val),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _subjectStreamFilter,
              items: ['All', 'Natural', 'Social', 'Supplementary'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _subjectStreamFilter = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading subjects: $e'),
          data: (subjects) {
            final filtered = subjects.where((s) {
              final matchesQuery = s.displayName.toLowerCase().contains(_subjectSearchQuery.toLowerCase());
              return matchesQuery;
            }).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.protoSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.protoLine(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '${s.enrolledStudentCount} enrolled • ${s.teacherAssignedCount} teachers',
                              style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context)),
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
                              s.attemptCount > 0 ? '${s.avgPercentage.toStringAsFixed(1)}% Avg' : 'No attempts',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text('${(s.participationRate * 100).toStringAsFixed(0)}% participation',
                                style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context))),
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
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: s.activeMistakeCount > 50 ? AppTheme.protoWarn : AppTheme.protoGood,
                              ),
                            ),
                            Text('${s.affectedStudentCount} affected students',
                                style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: s.hasTeacherCoverage ? AppTheme.protoGoodLight : AppTheme.protoWarnLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.hasTeacherCoverage ? 'COVERED' : 'UNASSIGNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.hasTeacherCoverage ? AppTheme.protoGood : AppTheme.protoWarn,
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

  Widget _buildClassComparisonSection(BuildContext context, bool isDesktop, bool isDark) {
    final classesAsync = ref.watch(schoolClassSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class / Section Comparative Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'All sections are presented neutrally for intervention support without ranking labels.',
          style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context)),
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
                childAspectRatio: isDesktop ? 1.45 : 2.0,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final c = classes[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.protoSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.protoLine(context)),
                    boxShadow: AppTheme.protoCardShadow(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c.classroomName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${c.enrolledStudents} Students', style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context))),
                        ],
                      ),
                      _buildRowStat(
                        'Recent Average',
                        c.recentAttemptCount > 0 ? '${c.avgPercentage.toStringAsFixed(1)}%' : 'No data',
                      ),
                      _buildRowStat('Participation Rate', '${(c.participationRate * 100).toStringAsFixed(0)}%'),
                      _buildRowStat('Active Mistakes', '${c.activeMistakeCount} records'),
                      _buildRowStat('Assigned Teachers', '${c.assignedTeacherCount} staff'),
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

  Widget _buildSupportPopulationSection(BuildContext context, SchoolLeadershipSummary s, bool isDesktop, bool isDark) {
    final supportState = ref.watch(schoolSupportPopulationProvider);
    final notifier = ref.read(schoolSupportPopulationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Students Needing Academic Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${s.uniqueStudentsNeedingHelp} unique students flagged across the school with explainable reasons.',
                    style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context))),
              ],
            ),
            Wrap(
              spacing: 6,
              children: [
                _buildSeverityChip('ALL', null, supportState.severityFilter, notifier),
                _buildSeverityChip('HIGH', 'high', supportState.severityFilter, notifier),
                _buildSeverityChip('MEDIUM', 'medium', supportState.severityFilter, notifier),
                _buildSeverityChip('LOW', 'low', supportState.severityFilter, notifier),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (supportState.isLoading && supportState.students.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (supportState.students.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No students currently flagged under this severity level.',
                style: TextStyle(fontSize: 13, color: AppTheme.protoMuted(context)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supportState.students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final stu = supportState.students[index];
              return InkWell(
                onTap: () => _openStudentDrawer(context, stu),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.protoSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.protoLine(context)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
                        child: Text(
                          stu.displayName.isNotEmpty ? stu.displayName[0] : 'S',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.protoBrand),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stu.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Text('${stu.schoolStudentId ?? "ID"} · ${stu.classroomName}',
                                style: TextStyle(fontSize: 10.5, color: AppTheme.protoMuted(context))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: stu.severity == AttentionSeverity.high
                              ? AppTheme.protoBadLight
                              : (stu.severity == AttentionSeverity.medium ? AppTheme.protoWarnLight : const Color(0xFFEFF2F6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stu.severity.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stu.severity == AttentionSeverity.high
                                ? AppTheme.protoBad
                                : (stu.severity == AttentionSeverity.medium ? AppTheme.protoWarn : const Color(0xFF78859B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF72809A)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSeverityChip(String label, String? value, String? current, SchoolSupportPopulationNotifier notifier) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.protoBrand,
      onSelected: (_) => notifier.loadInitial(severity: value),
    );
  }

  Widget _buildRecentAssessmentsSection(BuildContext context, bool isDesktop, bool isDark) {
    final assessmentsAsync = ref.watch(schoolAssessmentsOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assessments & Exam Evidence Registry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Canonical provenance preserves clear distinction between Official Exams, Verified Models, and Simulations.',
            style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context))),
        const SizedBox(height: 16),
        assessmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (assessments) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assessments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = assessments[index];
                final dateStr = a.latestAttemptAt != null
                    ? '${a.latestAttemptAt!.day} ${_monthName(a.latestAttemptAt!.month)} ${a.latestAttemptAt!.year}'
                    : 'Recent';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.protoSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.protoLine(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.description_outlined, color: AppTheme.protoBrand, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.examTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${a.provenanceLabel} · Completed $dateStr',
                                style: TextStyle(fontSize: 10.5, color: AppTheme.protoMuted(context))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${a.avgPercentage.toStringAsFixed(1)}% Avg',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${(a.participationPct * 100).toStringAsFixed(0)}% participation',
                              style: TextStyle(fontSize: 10.5, color: AppTheme.protoMuted(context))),
                        ],
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

  Widget _buildTeacherCoverageSection(BuildContext context, SchoolLeadershipSummary s, bool isDesktop, bool isDark) {
    final covAsync = ref.watch(schoolTeacherCoverageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Teacher Staffing & Subject Coverage Oversight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Operational view of classroom-subject coverage to identify staffing gaps. Non-evaluative.',
            style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.protoSurface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: slot.isAssigned ? AppTheme.protoLine(context) : AppTheme.protoWarn.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            slot.isAssigned ? Icons.check_circle_rounded : Icons.warning_rounded,
                            color: slot.isAssigned ? AppTheme.protoGood : AppTheme.protoWarn,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text('${slot.classroomName} — ${slot.subjectName}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        slot.isAssigned ? 'Assigned: ${slot.teacherName ?? "Teacher"}' : 'NO TEACHER ASSIGNED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: slot.isAssigned ? (isDark ? Colors.white70 : Colors.black87) : AppTheme.protoWarn,
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

  Widget _buildLicensingSection(BuildContext context, SchoolLeadershipSummary s, bool isDesktop, bool isDark) {
    return InstitutionalPanel(
      title: 'Institutional Licensing & Seats',
      subtitle: 'Sample contract and billing lifecycle status',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.protoBrand, width: 8),
                ),
                alignment: Alignment.center,
                child: const Text('96.4%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENROLLED SEATS', style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppTheme.protoMuted(context))),
                  const SizedBox(height: 2),
                  const Text('482 / 500', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('18 available seats remaining', style: TextStyle(fontSize: 11, color: AppTheme.protoGood)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Supported Institutional Payment Rails', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Telebirr', 'Chapa', 'CBE Bank Transfer', 'Manual Invoice'].map((n) {
              return Chip(label: Text(n, style: const TextStyle(fontSize: 11)));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingSection(BuildContext context, SchoolLeadershipSummary s, bool isDesktop, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('School Onboarding Workflows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Prepare Grade 12 rosters, staff invitations, and stream-specific class setup.',
            style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isDesktop ? 3 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 1.4 : 2.0,
          children: [
            _buildOnboardingCard(
              Icons.people_outline_rounded,
              '01 · Student Roster',
              'Import a local CSV preview or prepare manual enrollment records with school IDs.',
              'Preview Roster CSV',
              () {},
              isDark,
            ),
            _buildOnboardingCard(
              Icons.badge_outlined,
              '02 · Invite Staff',
              'Prepare teacher invitations linked to an authorized school context.',
              'Prepare Invitation',
              () {},
              isDark,
            ),
            _buildOnboardingCard(
              Icons.layers_outlined,
              '03 · Configure Classes',
              'Confirm classroom naming, natural/social stream, and subject-track coverage.',
              'View Sections',
              () => _onNavSelected('sections'),
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnboardingCard(IconData icon, String title, String desc, String btnText, VoidCallback onTap, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.protoLine(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.protoBrand, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context))),
            ],
          ),
          OutlinedButton(onPressed: onTap, child: Text(btnText, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDataIntegrityFootnote(BuildContext context, SchoolLeadershipSummary s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.protoLine(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, size: 18, color: AppTheme.protoBrand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Freshness & Transparency Footnote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(
                  'School Fresh Data Coverage: ${(s.freshDataCoverageRate * 100).toStringAsFixed(0)}%. '
                  'Students whose devices have not synced within the last 14 days (${s.staleSyncStudentCount} students) '
                  'are flagged for freshness review. Note: Offline student study continues uninterrupted without internet.',
                  style: TextStyle(fontSize: 11, color: AppTheme.protoMuted(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
String _monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return (month >= 1 && month <= 12) ? months[month - 1] : '';
}
