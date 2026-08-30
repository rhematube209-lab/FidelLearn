import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_indicator_widget.dart';
import '../../../auth/domain/models/user_profile.dart';
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.brand),
        ),
      );
    }

    final isAmharic = user.preferredLanguage == 'am';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.brandStrong, AppTheme.brand],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppTheme.brandGlow,
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
                  const Text(
                    'FidelLearn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
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
      body: Row(
        children: [
          // 🖥️ 1. Futuristic Desktop Left Navigation Rail (Visible on Desktop)
          if (isDesktop) _buildDesktopNavigationRail(context, user, coinBalance),

          // 📱/🖥️ 2. Main Content Canvas
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 36.0 : (isTablet ? 24.0 : 16.0),
                  vertical: isDesktop ? 32.0 : 20.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Header (Desktop View)
                        if (isDesktop) ...[
                          _buildDesktopHeader(context, user, coinBalance, isAmharic),
                          const SizedBox(height: 28),
                        ],

                        // Futuristic Cosmic Hero Banner (Exam Countdown & Diagnostic)
                        _buildFuturisticHeroBanner(context, user, isAmharic),
                        const SizedBox(height: 24),

                        // 4-Stat Metric Counter Grid
                        _buildMetricCardsGrid(context, coinBalance, isDesktop),
                        const SizedBox(height: 32),

                        // Multi-Column Desktop Layout
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Main Section (Subjects & Quick Action Hub)
                              Expanded(
                                flex: 62,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSubjectPackageSection(context, isAmharic),
                                    const SizedBox(height: 32),
                                    _buildQuickActionsHub(context),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),

                              // Right Intelligence Section (Weak Topics & Performance)
                              Expanded(
                                flex: 38,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildFeaturedBiologyExamCard(context),
                                    const SizedBox(height: 24),
                                    _buildWeakTopicRadarCard(context),
                                    const SizedBox(height: 24),
                                    if (_recentAttempt != null)
                                      _buildRecentPerformanceCard(context),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          // Single-Column Mobile/Tablet Flow
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFeaturedBiologyExamCard(context),
                              const SizedBox(height: 24),
                              _buildQuickActionsHub(context),
                              const SizedBox(height: 28),
                              _buildSubjectPackageSection(context, isAmharic),
                              const SizedBox(height: 28),
                              _buildWeakTopicRadarCard(context),
                              const SizedBox(height: 24),
                              if (_recentAttempt != null) ...[
                                _buildRecentPerformanceCard(context),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.brand,
              unselectedItemColor: AppTheme.darkMuted,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Practice'),
                BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Analytics'),
                BottomNavigationBarItem(icon: Icon(Icons.military_tech_rounded), label: 'Rewards'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
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

  // ==========================================
  // 🖥️ DESKTOP NAVIGATION RAIL
  // ==========================================
  Widget _buildDesktopNavigationRail(BuildContext context, UserProfile user, int coinBalance) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.darkSurfaceStrong,
        border: Border(right: BorderSide(color: AppTheme.darkBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brandStrong, AppTheme.brand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.brandGlow,
                ),
                child: const Center(
                  child: Text(
                    'ፊ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FidelLearn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'National Exam Prep',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Nav Items
          _buildNavRailItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: true,
            onTap: () {},
          ),
          _buildNavRailItem(
            icon: Icons.tune_rounded,
            label: 'Custom Exam Builder',
            onTap: () => context.push('/exam_builder'),
          ),
          _buildNavRailItem(
            icon: Icons.history_edu_rounded,
            label: 'Mistake Notebook',
            onTap: () => context.push('/mistakes'),
          ),
          _buildNavRailItem(
            icon: Icons.bookmark_rounded,
            label: 'Saved Bookmarks',
            onTap: () => context.push('/bookmarks'),
          ),
          _buildNavRailItem(
            icon: Icons.emoji_events_rounded,
            label: 'Championship Duels',
            onTap: () => context.push('/challenges'),
          ),
          _buildNavRailItem(
            icon: Icons.phone_android_rounded,
            label: 'Airtime Store',
            onTap: () => context.push('/airtime_store'),
          ),
          _buildNavRailItem(
            icon: Icons.wifi_tethering_rounded,
            label: 'P2P Offline Share',
            onTap: () => context.push('/p2p_share'),
          ),
          _buildNavRailItem(
            icon: Icons.insights_rounded,
            label: 'Weak Topics & IRT',
            onTap: () => context.push('/progress'),
          ),

          const Spacer(),

          // Desktop Bottom Profile Card
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.brandStrong,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0] : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Grade ${user.grade} • ${user.stream}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.darkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: AppTheme.darkMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRailItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brandStrong.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isActive ? AppTheme.brand.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppTheme.brand : AppTheme.darkMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppTheme.darkText : AppTheme.darkTextSoft,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🖥️ TOP DESKTOP HEADER
  // ==========================================
  Widget _buildDesktopHeader(BuildContext context, dynamic user, int coinBalance, bool isAmharic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAmharic ? 'ሰላም, ${user.displayName} 👋' : 'Welcome Back, ${user.displayName} 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grade ${user.grade} National Curriculum • ${user.stream.toUpperCase()} Science Stream',
                style: const TextStyle(fontSize: 14, color: AppTheme.darkMuted),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const SyncIndicatorWidget(isCompact: true),
            const SizedBox(width: 14),
            // Coin Balance Pill
            InkWell(
              onTap: () => context.push('/rewards'),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$coinBalance Coins',
                      style: const TextStyle(
                        color: AppTheme.accent,
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
      ],
    );
  }

  // ==========================================
  // 🌌 FUTURISTIC HERO BANNER
  // ==========================================
  Widget _buildFuturisticHeroBanner(BuildContext context, dynamic user, bool isAmharic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brand.withOpacity(0.35)),
        boxShadow: AppTheme.cardShadowDark,
      ),
      child: Stack(
        children: [
          // Background subtle ambient glow
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withOpacity(0.15),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brand.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.brand.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: AppTheme.brand, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'ESSLCE / PSLCE NATIONAL EXAM 2026',
                            style: TextStyle(
                              color: AppTheme.brand,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAmharic
                          ? 'የፈተና ዝግጁነትዎን ያረጋግጡ'
                          : 'Master Your National Exam Score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI-free verified questions with step-by-step solutions, offline Exam Ghost personal bests, and weak-topic diagnostics.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkTextSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/exam_builder'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Start Adaptive Practice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandStrong,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/challenges'),
                          icon: const Icon(Icons.flash_on, size: 18, color: AppTheme.accent),
                          label: const Text(
                            'Exam Ghost Duels',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.brand.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Radial Readiness Gauge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceStrong.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.green.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '84%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.green,
                        ),
                      ),
                      Text(
                        'READINESS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 4-STAT METRIC CARDS GRID
  // ==========================================
  Widget _buildMetricCardsGrid(BuildContext context, int coinBalance, bool isDesktop) {
    final cards = [
      _buildStatCard(
        title: 'Study Coins',
        value: '$coinBalance 🪙',
        subtitle: '10 Coins = 1 ETB (Telebirr)',
        icon: Icons.monetization_on_rounded,
        accentColor: AppTheme.accent,
        onTap: () => context.push('/rewards'),
      ),
      _buildStatCard(
        title: 'Daily Streak',
        value: '5 Days 🔥',
        subtitle: 'Freeze Shield Active',
        icon: Icons.local_fire_department_rounded,
        accentColor: AppTheme.pink,
        onTap: () => context.push('/rewards'),
      ),
      _buildStatCard(
        title: 'Exam Accuracy',
        value: '88.4%',
        subtitle: '100+ Questions Solved',
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppTheme.green,
        onTap: () => context.push('/progress'),
      ),
      _buildStatCard(
        title: 'Avg Speed',
        value: '42s / Q',
        subtitle: 'Top 5% National Pace',
        icon: Icons.speed_rounded,
        accentColor: AppTheme.brand,
        onTap: () => context.push('/progress'),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: c,
        ))).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 500 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: cards,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: accentColor.withOpacity(0.2)),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: accentColor, size: 18),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
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

  // ==========================================
  // 📚 SUBJECT PACKAGE SECTION
  // ==========================================
  Widget _buildSubjectPackageSection(BuildContext context, bool isAmharic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'National Exam Subjects & Packages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/subjects'),
              icon: const Icon(Icons.folder_zip_outlined, size: 16),
              label: const Text('Manage Packages'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: 130,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final sub = _subjects[index];
            return InkWell(
              onTap: () => context.push('/exam_builder?subjectId=${sub.id}'),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.brand.withOpacity(0.15),
                          child: Text(
                            sub.nameEn[0],
                            style: const TextStyle(
                              color: AppTheme.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isAmharic ? sub.nameAm : sub.nameEn,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OFFLINE',
                            style: TextStyle(
                              color: AppTheme.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${sub.code} • Comprehensive Question Bank & Vector Diagrams',
                      style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Practice Subject →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brand,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppTheme.brand.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // ⚡ QUICK ACTIONS HUB
  // ==========================================
  Widget _buildQuickActionsHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions & Command Center',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.tune_rounded,
                title: 'Custom Exam',
                subtitle: 'Filter by year & topic',
                color: AppTheme.brand,
                onTap: () => context.push('/exam_builder'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.timer_outlined,
                title: 'Timed Mock',
                subtitle: 'Real national conditions',
                color: AppTheme.accent,
                onTap: () => context.push('/exam_builder?mode=mock'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.history_edu_rounded,
                title: 'Mistake Notebook',
                subtitle: 'Review & retry errors',
                color: AppTheme.danger,
                onTap: () => context.push('/mistakes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.wifi_tethering_rounded,
                title: 'P2P Offline Share',
                subtitle: 'Zero data transfer',
                color: AppTheme.green,
                onTap: () => context.push('/p2p_share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🧬 FEATURED BIOLOGY 2013 EXAM CARD
  // ==========================================
  Widget _buildFeaturedBiologyExamCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEW EXAM PAPER',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Flexible(
                child: Text(
                  '2013 E.C. (2021 G.C.)',
                  style: TextStyle(color: AppTheme.darkMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ESSLCE Biology (100 Questions)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Official National Exam with vector diagrams, bacteriophage models, & complete solutions.',
            style: TextStyle(fontSize: 12, color: AppTheme.darkTextSoft, height: 1.3),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.push('/exam_builder?subjectId=biology_g12'),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Start 100-Question Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🎯 WEAK TOPIC RADAR CARD
  // ==========================================
  Widget _buildWeakTopicRadarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Priority Focus Areas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.radar_rounded, color: AppTheme.pink, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _buildWeakTopicRow('Cellular Respiration & Krebs Cycle', 'Biology (Grade 12)', 0.45),
          const SizedBox(height: 10),
          _buildWeakTopicRow('Arithmetic & Geometric Sequences', 'Math (Grade 12)', 0.58),
          const SizedBox(height: 10),
          _buildWeakTopicRow('Battle of Adwa Treaties', 'History (Grade 12)', 0.62),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.push('/progress'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
            ),
            child: const Text('View Full Analytics & IRT Projection'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakTopicRow(String title, String subject, double accuracy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(accuracy * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: accuracy,
            backgroundColor: const Color(0x1FFFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.danger),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🏆 RECENT PERFORMANCE CARD
  // ==========================================
  Widget _buildRecentPerformanceCard(BuildContext context) {
    final attempt = _recentAttempt!;
    final isGoodScore = attempt.percentage >= 70.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Performance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isGoodScore ? AppTheme.green : AppTheme.accent).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isGoodScore ? AppTheme.green : AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            attempt.examTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: ${attempt.score}/${attempt.totalQuestions} • Time: ${attempt.durationSeconds}s',
            style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/results/${attempt.id}'),
                  child: const Text('Review Solutions'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/exam_ghost/${attempt.examId}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandStrong,
                  ),
                  child: const Text('Race Ghost'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
