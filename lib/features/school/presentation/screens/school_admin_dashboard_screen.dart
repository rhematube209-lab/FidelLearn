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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading || _profile == null || _analytics == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }

    final p = _profile!;
    final a = _analytics!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Administrator Portal', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // School Header Banner
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), AppTheme.darkSurfaceStrong],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.4)),
                    boxShadow: AppTheme.cardShadowDark,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: AppTheme.accent, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.region} • ${p.woreda} • Code: ${p.schoolCode}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.green.withOpacity(0.5)),
                        ),
                        child: const Text('OFFLINE LAB ACTIVE 🟢', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 4-Stat Metric Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSchoolStat('Total Students', '${p.totalStudents}', Icons.people_outline_rounded, AppTheme.brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSchoolStat('Teaching Staff', '${p.totalTeachers}', Icons.badge_outlined, AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSchoolStat('Exams Completed', '${a.totalExamsCompleted}', Icons.assignment_turned_in_outlined, AppTheme.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSchoolStat('Projected Pass Rate', '${(a.projectedPassRate * 100).toStringAsFixed(0)}%', Icons.insights_rounded, AppTheme.pink),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Teacher Rosters (50%)
                      Expanded(
                        flex: 50,
                        child: _buildTeacherRosterCard(),
                      ),
                      const SizedBox(width: 28),

                      // Right: School Performance Heatmaps (50%)
                      Expanded(
                        flex: 50,
                        child: _buildSchoolReadinessCard(a),
                      ),
                    ],
                  )
                else ...[
                  _buildTeacherRosterCard(),
                  const SizedBox(height: 20),
                  _buildSchoolReadinessCard(a),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTeacherRosterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Roster & Classrooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _roster.length,
            separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 16),
            itemBuilder: (context, index) {
              final t = _roster[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${t.subjectSpecialty} • ${t.classrooms.join(", ")}', style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${t.studentCount} Students', style: const TextStyle(color: AppTheme.brand, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolReadinessCard(SchoolAnalyticsSummary a) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School National Readiness Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSchoolProgressRow('Biology ESSLCE Exam Readiness', 0.86, AppTheme.green),
          const SizedBox(height: 12),
          _buildSchoolProgressRow('Mathematics Natural Science Readiness', 0.72, AppTheme.brand),
          const SizedBox(height: 12),
          _buildSchoolProgressRow('Aptitude & General Reasoning', 0.79, AppTheme.accent),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.green,
                  content: Text('Exporting Ministry of Education Readiness Report PDF...'),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export Ministry Analytics Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandStrong,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolProgressRow(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(value * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0x1AFFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
