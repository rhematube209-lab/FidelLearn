import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../../../core/widgets/fidel_section_header.dart';
import '../../../../core/widgets/fidel_stat_card.dart';
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
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final contentRepo = ref.read(contentRepositoryProvider);
      final examRepo = ref.read(examRepositoryProvider);

      if (user != null) {
        List<Subject> subs = [];
        try {
          subs = await contentRepo
              .getSubjects(grade: user.grade, stream: user.stream)
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('StudentHomeScreen: error loading subjects: $e');
        }

        List<ExamAttempt> history = [];
        try {
          history = await examRepo
              .getAttemptHistory(user.id)
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('StudentHomeScreen: error loading attempt history: $e');
        }

        if (mounted) {
          setState(() {
            _subjects = subs;
            _recentAttempt = history.isNotEmpty ? history.first : null;
          });
        }
      }
    } catch (e) {
      debugPrint('StudentHomeScreen: error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final coinBalance = ref.watch(coinLedgerProvider.notifier).balance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.brand),
        ),
      );
    }

    if (user == null) {
      if (userAsync.isLoading) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: AppTheme.brand),
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.brandStrong,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      fontSize: 19,
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
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),
      body: Row(
        children: [
          // 🖥️ Desktop Navigation Rail
          if (isDesktop)
            _buildDesktopNavRail(context, user, coinBalance, isDark),

          // 📱/🖥️ Main Content Canvas
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.brand,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40.0 : (isTablet ? 24.0 : 16.0),
                  vertical: isDesktop ? 32.0 : 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Desktop Header
                        if (isDesktop) ...[
                          _buildDesktopHeader(
                              context, user, coinBalance, isAmharic, isDark),
                          const SizedBox(height: 24),
                        ],

                        // Modern Mission Control Hero Banner
                        _buildMissionControlHero(
                            context, user, isAmharic, isDark),
                        const SizedBox(height: 24),

                        // 4-Stat Metric Row
                        _buildMetricCards(context, coinBalance, isDesktop),
                        const SizedBox(height: 32),

                        // Multi-Column Desktop Layout vs Single-Column Mobile
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Subject Packages & Quick Actions (60%)
                              Expanded(
                                flex: 60,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSubjectSection(
                                        context, isAmharic, isDark),
                                    const SizedBox(height: 32),
                                    _buildQuickActions(context, isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),

                              // Right: Focus Areas & Recent Attempts (40%)
                              Expanded(
                                flex: 40,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildFeaturedExamCard(context, isDark),
                                    const SizedBox(height: 24),
                                    _buildWeakTopicRadarCard(context, isDark),
                                    if (_recentAttempt != null) ...[
                                      const SizedBox(height: 24),
                                      _buildRecentPerformanceCard(
                                          context, isDark),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildFeaturedExamCard(context, isDark),
                          const SizedBox(height: 24),
                          _buildQuickActions(context, isDark),
                          const SizedBox(height: 28),
                          _buildSubjectSection(context, isAmharic, isDark),
                          const SizedBox(height: 28),
                          _buildWeakTopicRadarCard(context, isDark),
                          if (_recentAttempt != null) ...[
                            const SizedBox(height: 24),
                            _buildRecentPerformanceCard(context, isDark),
                          ],
                        ],
                        const SizedBox(height: 40),
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
          : NavigationBar(
              selectedIndex: 0,
              backgroundColor:
                  isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              indicatorColor: isDark
                  ? AppTheme.brand.withValues(alpha: 0.25)
                  : AppTheme.brandSubtle,
              elevation: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon:
                      Icon(Icons.dashboard_rounded, color: AppTheme.brand),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon:
                      Icon(Icons.menu_book_rounded, color: AppTheme.brand),
                  label: 'Practice',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon:
                      Icon(Icons.insights_rounded, color: AppTheme.brand),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.military_tech_outlined),
                  selectedIcon:
                      Icon(Icons.military_tech_rounded, color: AppTheme.brand),
                  label: 'Rewards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon:
                      Icon(Icons.person_rounded, color: AppTheme.brand),
                  label: 'Profile',
                ),
              ],
              onDestinationSelected: (int index) {
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
  Widget _buildDesktopNavRail(
    BuildContext context,
    UserProfile user,
    int coinBalance,
    bool isDark,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.brandStrong,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FidelLearn',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                    Text(
                      'National Exam Prep',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildNavRailItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: true,
            isDark: isDark,
            onTap: () {},
          ),
          _buildNavRailItem(
            icon: Icons.tune_rounded,
            label: 'Exam Builder',
            isDark: isDark,
            onTap: () => context.push('/exam_builder'),
          ),
          _buildNavRailItem(
            icon: Icons.history_edu_rounded,
            label: 'Mistake Notebook',
            isDark: isDark,
            onTap: () => context.push('/mistakes'),
          ),
          _buildNavRailItem(
            icon: Icons.bookmark_outline_rounded,
            label: 'Saved Bookmarks',
            isDark: isDark,
            onTap: () => context.push('/bookmarks'),
          ),
          _buildNavRailItem(
            icon: Icons.emoji_events_outlined,
            label: 'Championship Duels',
            isDark: isDark,
            onTap: () => context.push('/challenges'),
          ),
          _buildNavRailItem(
            icon: Icons.phone_android_rounded,
            label: 'Airtime Store',
            isDark: isDark,
            onTap: () => context.push('/airtime_store'),
          ),
          _buildNavRailItem(
            icon: Icons.wifi_tethering_rounded,
            label: 'P2P Offline Share',
            isDark: isDark,
            onTap: () => context.push('/p2p_share'),
          ),
          _buildNavRailItem(
            icon: Icons.insights_rounded,
            label: 'Weak Topics & IRT',
            isDark: isDark,
            onTap: () => context.push('/progress'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x26334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.brandStrong,
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0] : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color:
                              isDark ? AppTheme.darkText : AppTheme.lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Grade ${user.grade} • ${user.stream.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  onPressed: () => context.push('/profile'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? AppTheme.brand.withValues(alpha: 0.16)
                      : AppTheme.brandSubtle)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isActive
                      ? AppTheme.brand
                      : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : AppTheme.brandStrong)
                          : (isDark
                              ? AppTheme.darkTextSoft
                              : AppTheme.lightTextSoft),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🖥️ TOP DESKTOP HEADER
  // ==========================================
  Widget _buildDesktopHeader(
    BuildContext context,
    UserProfile user,
    int coinBalance,
    bool isAmharic,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAmharic
                    ? 'ሰላም, ${user.displayName} 👋'
                    : 'Welcome back, ${user.displayName} 👋',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'Grade ${user.grade} National Exam Curriculum • ${user.stream.toUpperCase()} Stream',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SyncIndicatorWidget(isCompact: true),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.push('/rewards'),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x26F59E0B)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppTheme.accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$coinBalance Coins',
                      style: const TextStyle(
                        color: AppTheme.accentDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
  // 🎯 MISSION CONTROL HERO BANNER
  // ==========================================
  Widget _buildMissionControlHero(
    BuildContext context,
    UserProfile user,
    bool isAmharic,
    bool isDark,
  ) {
    return FidelCard(
      padding: const EdgeInsets.all(22),
      backgroundColor:
          isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
      borderColor: isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FidelBadge(
                      text: 'ESSLCE / PSLCE 2026',
                      icon: Icons.school_rounded,
                      variant: FidelBadgeVariant.primary,
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                    FidelBadge(
                      text: 'GRADE ${user.grade} ${user.stream.toUpperCase()}',
                      variant: FidelBadgeVariant.neutral,
                      isSmall: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isAmharic
                      ? 'የፈተና ዝግጁነትዎን ያረጋግጡ'
                      : 'Master Your National Exam Score',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAmharic
                      ? 'የተረጋገጡ የፈተና ጥያቄዎች ከደረጃ-በ-ደረጃ ማብራሪያዎች ጋር፣ ያለ ኢንተርኔት ይለማመዱ።'
                      : 'Verified syllabus questions with step-by-step solutions, offline diagnostics, and Exam Ghost.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color:
                        isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
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
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/challenges'),
                      icon: const Icon(Icons.flash_on_rounded,
                          size: 18, color: AppTheme.accent),
                      label: const Text('Exam Ghost Duels'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Clean Circular Readiness Gauge
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.green.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.green.withValues(alpha: 0.12),
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
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'READINESS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 4-STAT METRIC ROW
  // ==========================================
  Widget _buildMetricCards(
      BuildContext context, int coinBalance, bool isDesktop) {
    final cards = [
      FidelStatCard(
        title: 'Study Coins',
        value: '$coinBalance 🪙',
        subtitle: '10 Coins = 1 ETB (Telebirr)',
        icon: Icons.monetization_on_rounded,
        accentColor: AppTheme.accent,
        onTap: () => context.push('/rewards'),
      ),
      FidelStatCard(
        title: 'Daily Streak',
        value: '5 Days 🔥',
        subtitle: 'Freeze Shield Active',
        icon: Icons.local_fire_department_rounded,
        accentColor: AppTheme.pink,
        onTap: () => context.push('/rewards'),
      ),
      FidelStatCard(
        title: 'Exam Accuracy',
        value: '88.4%',
        subtitle: '100+ Questions Solved',
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppTheme.green,
        onTap: () => context.push('/progress'),
      ),
      FidelStatCard(
        title: 'Avg Pace',
        value: '42s / Q',
        subtitle: 'Top 5% National Speed',
        icon: Icons.speed_rounded,
        accentColor: AppTheme.brand,
        onTap: () => context.push('/progress'),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 520 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: cards,
        );
      },
    );
  }

  // ==========================================
  // 📚 SUBJECT PACKAGE SECTION
  // ==========================================
  Widget _buildSubjectSection(
      BuildContext context, bool isAmharic, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FidelSectionHeader(
          title: 'National Exam Subjects',
          subtitle: 'Choose a subject to practice syllabus units & mock exams',
          trailing: TextButton.icon(
            onPressed: () => context.push('/subjects'),
            icon: const Icon(Icons.folder_zip_outlined, size: 16),
            label: const Text('Manage Packages'),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: 136,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final sub = _subjects[index];
            return FidelCard(
              padding: const EdgeInsets.all(15),
              onTap: () => context.push('/exam_builder?subjectId=${sub.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Center(
                          child: Text(
                            sub.nameEn.isNotEmpty ? sub.nameEn[0] : 'S',
                            style: const TextStyle(
                              color: AppTheme.brand,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAmharic ? sub.nameAm : sub.nameEn,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color:
                                isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const FidelBadge(
                        text: 'OFFLINE',
                        variant: FidelBadgeVariant.success,
                        isSmall: true,
                      ),
                    ],
                  ),
                  Text(
                    '${sub.code} • Verified Questions & Diagrams',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Practice Subject →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brand,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppTheme.brand.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ],
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
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FidelSectionHeader(
          title: 'Quick Actions',
          subtitle: 'Instant shortcuts for focused study sessions',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.tune_rounded,
                title: 'Custom Exam',
                subtitle: 'Filter by year & topic',
                color: AppTheme.brand,
                isDark: isDark,
                onTap: () => context.push('/exam_builder'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.timer_outlined,
                title: 'Timed Mock',
                subtitle: 'Simulate national rules',
                color: AppTheme.accent,
                isDark: isDark,
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
                isDark: isDark,
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
                isDark: isDark,
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return FidelCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      backgroundColor: isDark
          ? color.withValues(alpha: 0.08)
          : color.withValues(alpha: 0.04),
      borderColor: color.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🧬 FEATURED BIOLOGY EXAM CARD
  // ==========================================
  Widget _buildFeaturedExamCard(BuildContext context, bool isDark) {
    return FidelCard(
      padding: const EdgeInsets.all(18),
      backgroundColor:
          isDark ? const Color(0xFF0D2523) : const Color(0xFFF0FDF4),
      borderColor: AppTheme.green.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FidelBadge(
                text: 'OFFICIAL EXAM',
                variant: FidelBadgeVariant.success,
                isSmall: true,
              ),
              Flexible(
                child: Text(
                  '2013 E.C. (2021 G.C.)',
                  style: TextStyle(color: AppTheme.darkMuted, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ESSLCE Biology (100 Questions)',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official National Exam with vector diagrams, bacteriophage models, & complete solutions.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () =>
                context.push('/exam_builder?subjectId=biology_g12'),
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: const Text('Start 100-Question Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenDark,
              foregroundColor: Colors.white,
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
  Widget _buildWeakTopicRadarCard(BuildContext context, bool isDark) {
    return FidelCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Priority Weak Topics',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.radar_rounded, color: AppTheme.danger, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          _buildWeakTopicRow('Cellular Respiration & Krebs Cycle',
              'Biology (Grade 12)', 0.45, isDark),
          const SizedBox(height: 12),
          _buildWeakTopicRow('Arithmetic & Geometric Sequences',
              'Math (Grade 12)', 0.58, isDark),
          const SizedBox(height: 12),
          _buildWeakTopicRow(
              'Battle of Adwa Treaties', 'History (Grade 12)', 0.62, isDark),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.push('/progress'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
            ),
            child: const Text('View Full Weak Topic Analytics'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakTopicRow(
      String title, String subject, double accuracy, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(accuracy * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: accuracy,
            backgroundColor:
                isDark ? const Color(0x33334155) : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.danger),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🏆 RECENT PERFORMANCE CARD
  // ==========================================
  Widget _buildRecentPerformanceCard(BuildContext context, bool isDark) {
    final attempt = _recentAttempt!;
    final isGoodScore = attempt.percentage >= 70.0;

    return FidelCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FidelBadge(
                text: '${attempt.percentage.toStringAsFixed(0)}%',
                variant: isGoodScore
                    ? FidelBadgeVariant.success
                    : FidelBadgeVariant.warning,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            attempt.examTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: ${attempt.score}/${attempt.totalQuestions} questions • Time: ${attempt.durationSeconds}s',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
            ),
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
                  onPressed: () =>
                      context.push('/exam_ghost/${attempt.examId}'),
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
