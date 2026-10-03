import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/institutional_reporting_models.dart';
import '../../data/repositories/supabase_institutional_reporting_repository.dart';
import '../providers/active_school_context_provider.dart';
import '../providers/institutional_reporting_providers.dart';

/// Reports Hub screen for School Leadership and authorized teachers.
/// Route: `/school/reports` or `/teacher/reports`.
class ReportsHubScreen extends ConsumerStatefulWidget {
  final bool isTeacherView;

  const ReportsHubScreen({
    super.key,
    this.isTeacherView = false,
  });

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWindowDays = 90;
  late DateTime _windowEnd;
  late DateTime _windowStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _recomputeWindow();
  }

  void _recomputeWindow() {
    final now = DateTime.now().toUtc();
    _windowEnd = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    _windowStart = _windowEnd.subtract(Duration(days: _selectedWindowDays));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final school = schoolContext.school;

    if (school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Institutional Reports Hub')),
        body: const Center(
          child: Text('No active school context found.'),
        ),
      );
    }

    final schoolId = school.id;

    final execAsync = ref.watch(
      schoolExecutiveReportProvider((
        schoolId: schoolId,
        academicYear: '2026/27',
        start: _windowStart,
        end: _windowEnd,
      )),
    );

    final runsAsync = ref.watch(
      institutionalReportRunsProvider((
        schoolId: schoolId,
        type: null,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isTeacherView
                  ? 'Teacher Reports & Evidence'
                  : 'Institutional Reports Hub',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${school.name} • Academic Year 2026/27',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Executive KPIs'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Subject Evidence'),
            Tab(
                icon: Icon(Icons.assignment_turned_in_outlined),
                text: 'Assignments & Interventions'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Report History'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Reporting Window',
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() {
                _selectedWindowDays = days;
                _recomputeWindow();
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 30, child: Text('Last 30 Days')),
              PopupMenuItem(value: 90, child: Text('Last 90 Days (Quarter)')),
              PopupMenuItem(value: 180, child: Text('Last 180 Days')),
              PopupMenuItem(value: 365, child: Text('Full Academic Year')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Executive KPIs
          _buildExecutiveTab(execAsync, schoolId),

          // Tab 2: Subject Evidence
          _buildSubjectsTab(schoolId, _windowStart, _windowEnd),

          // Tab 3: Assignments & Interventions
          _buildAssignmentsTab(schoolId, _windowStart, _windowEnd),

          // Tab 4: Historical Report Runs
          _buildHistoryTab(runsAsync, schoolId),
        ],
      ),
    );
  }

  Widget _buildExecutiveTab(
      AsyncValue<ExecutiveReport> execAsync, String schoolId) {
    return execAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Colors.blueGrey),
              const SizedBox(height: 12),
              Text(
                err is ReportingOfflineException ||
                        err.toString().contains('internet connection')
                    ? 'Institutional reports require an internet connection.\nReconnect to load current synchronized analytics.'
                    : 'Failed to load executive report: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      data: (report) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data As-Of & Methodology Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.blueGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data as of: ${report.dataAsOf.toLocal().toString().substring(0, 16)} UTC',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Engine: institutional_analytics_v1 • Non-causal longitudinal evidence',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Full Preview'),
                      onPressed: () {
                        context.push(
                          '/school/reports/preview?type=executive&schoolId=$schoolId',
                          extra: report,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Cards Grid
              const Text(
                'Key Institutional Metrics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  _buildMetricCard(
                    title: 'Active Enrolled',
                    value: '${report.activeEnrolledStudents}',
                    subtitle:
                        'Evidence: ${report.studentsWithAcademicEvidence} • Nat: ${report.naturalStreamStudents} • Soc: ${report.socialStreamStudents}',
                    icon: Icons.people_outline,
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Assessment Participation',
                    value: '${report.assessmentParticipationRate}%',
                    subtitle:
                        '${report.assessmentParticipants} / ${report.assessmentEligibleStudents} students',
                    icon: Icons.fact_check_outlined,
                    color: Colors.teal,
                  ),
                  _buildMetricCard(
                    title: 'Simulation Average',
                    value: '${report.simulationAverage}%',
                    subtitle: 'Median: ${report.simulationMedian}%',
                    icon: Icons.assessment_outlined,
                    color: Colors.indigo,
                  ),
                  _buildMetricCard(
                    title: 'Assignment Completion',
                    value: '${report.completionRate}%',
                    subtitle:
                        '${report.submittedCount} / ${report.requiredForCompletion} required',
                    icon: Icons.task_alt_outlined,
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Interventions Followed Up',
                    value: '${report.interventionsWithFollowupEvidence}',
                    subtitle:
                        '${report.interventionsCompleted} of ${report.interventionsCreated} completed',
                    icon: Icons.support_agent_outlined,
                    color: Colors.deepPurple,
                  ),
                  _buildMetricCard(
                    title: 'Data Coverage (14d)',
                    value: '${report.freshDataCoverageRate}%',
                    subtitle:
                        '${report.freshSyncCount + report.moderateSyncCount} fresh students',
                    icon: Icons.sync_outlined,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Non-causal notice callout
              Card(
                color: Colors.amber.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          report.nonCausalNotice,
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Data freshness notice
              Card(
                color: Colors.grey.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.offline_pin_outlined,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          report.freshnessCaveat,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectsTab(String schoolId, DateTime start, DateTime end) {
    final subAsync = ref.watch(
      subjectPerformanceReportProvider((
        schoolId: schoolId,
        academicYear: '2026/27',
        start: start,
        end: end,
        stream: null,
      )),
    );

    return subAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
              child: Text(
                  'No subject assessment evidence recorded in this window.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = rows[i];
            return Card(
              child: ListTile(
                title: Text(r.subjectName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Eligible: ${r.eligibleStudents} • Participants: ${r.participants} (${r.participationRate}%) • Mistakes: ${r.activeMistakes}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      r.privacySuppressed
                          ? 'Suppressed (n<5)'
                          : '${r.averageScore ?? "N/A"}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            r.privacySuppressed ? Colors.grey : AppTheme.brand,
                      ),
                    ),
                    Text(
                      r.privacySuppressed
                          ? 'Cohort privacy'
                          : 'Median: ${r.medianScore ?? "N/A"}%',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignmentsTab(String schoolId, DateTime start, DateTime end) {
    final assignAsync = ref.watch(
      assignmentOutcomesReportProvider((
        schoolId: schoolId,
        academicYear: '2026/27',
        start: start,
        end: end,
        classroomId: null,
        subjectId: null,
      )),
    );

    return assignAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
              child:
                  Text('No assignments published in this reporting window.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = rows[i];
            return Card(
              child: ListTile(
                title: Text(r.assignmentTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Class: ${r.classroomName} • Teacher: ${r.teacherName}\n'
                  'Required: ${r.requiredDenominator} • Submitted: ${r.submittedCount} • Late Verified: ${r.verifiedLateCount} • Unverified: ${r.timingUnverifiedCount}',
                ),
                trailing: Text(
                  '${r.completionRate}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(
      AsyncValue<List<InstitutionalReportRun>> runsAsync, String schoolId) {
    return runsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (runs) {
        if (runs.isEmpty) {
          return const Center(child: Text('No previous report runs found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final run = runs[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.description_outlined),
                ),
                title: Text(run.reportType.titleEn,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Requested by: ${run.requestedByName} • ${run.createdAt.toLocal().toString().substring(0, 16)}\n'
                  'Format: ${(run.fileFormat ?? "csv").toUpperCase()} • Status: ${run.status.name.toUpperCase()}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push(
                      '/school/reports/preview?runId=${run.id}&schoolId=$schoolId');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
