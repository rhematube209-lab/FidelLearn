import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_indicator_widget.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../subjects/domain/models/subject_models.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  List<Subject> _subjects = [];
  ExamAttempt? _recentAttempt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    if (user != null) {
      final subs = await contentRepo.getSubjects(
        grade: user.grade,
        stream: user.stream,
      );
      final history = await examRepo.getAttemptHistory(user.id);
      if (mounted) {
        setState(() {
          _subjects = subs;
          _recentAttempt = history.isNotEmpty ? history.first : null;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final coinBalance = ref.watch(coinLedgerProvider.notifier).balance;

    if (_isLoading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAmharic = user.preferredLanguage == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'ፊ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'FidelLearn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SyncIndicatorWidget(isCompact: true),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student Greeting & Config
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic
                            ? 'ሰላም, ${user.displayName}'
                            : 'Hello, ${user.displayName}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grade ${user.grade} • ${user.stream.toUpperCase()} Science',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  // Coins pill
                  InkWell(
                    onTap: () => context.push('/rewards'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentGold),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: AppTheme.accentGold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$coinBalance',
                            style: const TextStyle(
                              color: AppTheme.accentGoldDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Daily Goal & Streak Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: AppTheme.warningOrange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5-Day Study Streak! 🔥',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Daily Goal: 15 / 20 questions completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/exam_builder'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Practice'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Quick Action Grid (Custom Exam, Full Mock, Mistakes, Bookmarks)
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.tune,
                      title: 'Custom Exam',
                      subtitle: 'Filter by topic & year',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/exam_builder'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.timer,
                      title: 'Timed Mock',
                      subtitle: 'Real exam conditions',
                      color: AppTheme.infoBlue,
                      onTap: () => context.push('/exam_builder?mode=mock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.history_edu,
                      title: 'Mistake Notebook',
                      subtitle: 'Review and master errors',
                      color: AppTheme.errorRed,
                      onTap: () => context.push('/mistakes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.bookmark,
                      title: 'Bookmarks',
                      subtitle: 'Saved questions',
                      color: AppTheme.accentGold,
                      onTap: () => context.push('/bookmarks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.emoji_events,
                      title: 'Exam Challenges',
                      subtitle: 'Friend duels & contests',
                      color: Colors.deepPurple,
                      onTap: () => context.push('/challenges'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.insights,
                      title: 'Readiness & Analytics',
                      subtitle: 'Weak-topic analysis',
                      color: Colors.teal,
                      onTap: () => context.push('/progress'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.phone_android,
                      title: 'Airtime Store',
                      subtitle: 'Redeem Ethio/Saf vouchers',
                      color: AppTheme.accentGoldDark,
                      onTap: () => context.push('/airtime_store'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.wifi_tethering,
                      title: 'P2P Offline Share',
                      subtitle: 'Zero data transfer',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/p2p_share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Subjects
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Subjects',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/subjects'),
                    child: const Text('View Packages'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sub = _subjects[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withOpacity(
                          0.12,
                        ),
                        child: Text(
                          sub.nameEn[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        isAmharic ? sub.nameAm : sub.nameEn,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${sub.code} • 2 Units • Offline Available',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () =>
                          context.push('/exam_builder?subjectId=${sub.id}'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 5. Recent Result / Exam Ghost Card
              if (_recentAttempt != null) ...[
                const Text(
                  'Recent Performance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _recentAttempt!.examTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _recentAttempt!.percentage >= 70.0
                                    ? AppTheme.successGreen.withOpacity(0.12)
                                    : AppTheme.warningOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_recentAttempt!.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _recentAttempt!.percentage >= 70.0
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: ${_recentAttempt!.score}/${_recentAttempt!.totalQuestions} • Duration: ${_recentAttempt!.durationSeconds}s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/results/${_recentAttempt!.id}',
                              ),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('Review'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => context.push(
                                '/exam_ghost/${_recentAttempt!.examId}',
                              ),
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: const Text('Ghost Challenge'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.military_tech),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/exam_builder');
              break;
            case 2:
              context.push('/progress');
              break;
            case 3:
              context.push('/rewards');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
