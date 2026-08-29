import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/school_models.dart';

class SchoolAdminDashboardScreen extends ConsumerStatefulWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  ConsumerState<SchoolAdminDashboardScreen> createState() =>
      _SchoolAdminDashboardScreenState();
}

class _SchoolAdminDashboardScreenState
    extends ConsumerState<SchoolAdminDashboardScreen> {
  SchoolProfile? _profile;
  List<RosterTeacher> _roster = [];
  SchoolAnalyticsSummary? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    final schoolRepo = ref.read(schoolRepositoryProvider);
    final prof = await schoolRepo.getSchoolProfile('sch_bole_1');
    final ros = await schoolRepo.getTeacherRoster('sch_bole_1');
    final an = await schoolRepo.getSchoolAnalytics('sch_bole_1');

    if (mounted) {
      setState(() {
        _profile = prof;
        _roster = ros;
        _analytics = an;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null || _analytics == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final p = _profile!;
    final a = _analytics!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Admin Portal'),
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
            // School Profile Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: AppTheme.accentGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${p.region} • National Exam Prep Readiness Dashboard',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('Total Students', '${p.totalStudents}'),
                      _buildHeaderStat('Teachers', '${p.totalTeachers}'),
                      _buildHeaderStat('Natural Stream', '${p.naturalStreamStudents}'),
                      _buildHeaderStat('Social Stream', '${p.socialStreamStudents}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Readiness Analytics Summary
            const Text(
              'National Exam Readiness Index',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Overall School',
                    score: a.overallReadinessScore,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Natural Stream',
                    score: a.naturalStreamReadiness,
                    color: AppTheme.infoBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Social Stream',
                    score: a.socialStreamReadiness,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject Insights Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top Performing Subject 🌟',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.topPerformingSubject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Priority Weak Subject ⚠️',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.priorityWeakSubject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Teacher Rosters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Department & Teacher Roster',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_roster.length} Active Departments',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _roster.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final teacher = _roster[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                    ),
                    title: Text(
                      teacher.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${teacher.subject} • ${teacher.classroomCount} Classes (${teacher.studentCount} students)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${teacher.averageClassAccuracy}% Avg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Export Reports Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('School Exam Readiness Report generated (PDF/CSV ready) 📄'),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Export School Readiness Report (CSV / PDF)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildReadinessCard({
    required String title,
    required double score,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
