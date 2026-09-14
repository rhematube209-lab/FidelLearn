import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../../../core/widgets/fidel_section_header.dart';
import '../../../../core/widgets/sync_indicator_widget.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../progress/domain/models/progress_models.dart';
import '../../../progress/domain/services/remedial_drill_service.dart';
import '../../../progress/domain/services/weak_topic_detector.dart';
import '../../../subjects/domain/models/subject_models.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  List<Subject> _subjects = [];
  ExamAttempt? _recentAttempt;
  List<WeakTopicRecommendation> _weakTopics = [];
  double _readinessScore = 0.0;
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

        // Evaluate dynamic weak-topics and national exam readiness
        List<WeakTopicRecommendation> detected = [];
        double readiness = 0.0;
        try {
          final sampleQuestions = await contentRepo.getQuestions(
            grade: user.grade,
            subjectId: subs.isNotEmpty ? subs.first.id : 'biology_g12',
            limit: 50,
          );

          final qMap = {for (final q in sampleQuestions) q.id: q};
          final topicMap = <String, String>{};
          for (final q in sampleQuestions) {
            topicMap[q.topicId] = q.topicId.replaceAll('_', ' ').toUpperCase();
          }

          const detector = WeakTopicDetector(
            minAttemptsThreshold: 1,
            weakAccuracyThreshold: 60.0,
          );

          detected = detector.detectWeakTopics(
            completedAttempts: history,
            questionMap: qMap,
            topicTitleMap: topicMap,
          );

          final avgScore = history.isNotEmpty
              ? (history.map((e) => e.percentage).reduce((a, b) => a + b) /
                  history.length)
              : 0.0;

          readiness = WeakTopicDetector.calculateReadinessScore(
            totalExamsCompleted: history.length,
            averageScorePercentage: avgScore,
            weakTopicCount: detected.length,
            studyStreakDays: 5,
          );
        } catch (_) {}

        if (mounted) {
          setState(() {
            _subjects = subs;
            _recentAttempt = history.isNotEmpty ? history.first : null;
            _weakTopics = detected;
            _readinessScore = readiness;
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

  Future<void> _startRemedialDrill([WeakTopicRecommendation? topic]) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final contentRepo = ref.read(contentRepositoryProvider);

    final targetTopic = topic ??
        (_weakTopics.isNotEmpty
            ? _weakTopics.first
            : const WeakTopicRecommendation(
                topicId: 'bio_t3_1',
                topicTitleEn: 'Cellular Respiration & Krebs Cycle',
                subjectId: 'biology_g12',
                accuracyPercentage: 45.0,
                totalAttempts: 5,
                mistakeCount: 3,
                urgencyLevel: 'high',
                recommendationReason:
                    'Targeted drill on highest mistake density',
              ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Building 10-question targeted drill for ${targetTopic.topicTitleEn}...',
        ),
      ),
    );

    final exam = await RemedialDrillService.createRemedialExam(
      contentRepo: contentRepo,
      weakTopic: targetTopic,
      userId: user.id,
      grade: user.grade,
      stream: user.stream,
    );

    final attempt = RemedialDrillService.createInitialAttempt(
      exam: exam,
      userId: user.id,
    );

    if (mounted) {
      await context
          .push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
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

                        // 🚀 Section 1: Modern Mission Control Hero Banner
                        _buildMissionControlHero(
                            context, user, isAmharic, isDark),
                        const SizedBox(height: 32),

                        // 📚 Section 2: National Exam Subjects
                        _buildSubjectSection(context, isAmharic, isDark),
                        const SizedBox(height: 32),

                        // Multi-Column Desktop Layout vs Single-Column Mobile for Remaining Tools & Intelligence
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Quick Actions & Featured Mock Exam (55%)
                              Expanded(
                                flex: 55,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildQuickActions(context, isDark),
                                    const SizedBox(height: 24),
                                    _buildFeaturedExamCard(context, isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),

                              // Right: Readiness Gauge, Weak Topics & Recent Attempts (45%)
                              Expanded(
                                flex: 45,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildReadinessGaugeCard(context, isDark),
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
                          // Mobile: Quick Actions & Intelligence Cards
                          _buildQuickActions(context, isDark),
                          const SizedBox(height: 24),
                          _buildFeaturedExamCard(context, isDark),
                          const SizedBox(height: 24),
                          _buildReadinessGaugeCard(context, isDark),
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
  // ==========================================
  // 🎯 SECTION 1: MASTER YOUR NATIONAL EXAM SCORE HERO
  // ==========================================
  Widget _buildMissionControlHero(
    BuildContext context,
    UserProfile user,
    bool isAmharic,
    bool isDark,
  ) {
    final readinessPercent = _readinessScore > 0
        ? (_readinessScore * 100).clamp(0, 100).toInt()
        : 84;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D3B43),
            Color(0xFF064E3B),
            Color(0xFF0D5C4B),
            Color(0xFF0A3D34),
          ],
          stops: [0.0, 0.45, 0.80, 1.0],
        ),
        border: Border.all(color: const Color(0x3310B981)), // emerald-500/20
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D042F2E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top-left ambient glow
            Positioned(
              left: -35,
              top: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5EEAD4).withValues(alpha: 0.10),
                ),
              ),
            ),
            // Bottom-right ambient glow
            Positioned(
              right: -35,
              bottom: -35,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                ),
              ),
            ),

            // Main Content Layer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Tags: Grade/Stream + MoE Aligned
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xB3052E25),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                              border: Border.all(
                                color: const Color(0x6610B981),
                              ),
                            ),
                            child: Text(
                              'GRADE ${user.grade} ${user.stream.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: Color(0xFF34D399),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAmharic ? 'ሚኒስቴር-ተስማሚ' : 'MoE Aligned',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xE66EE7B7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Right: Streak Counter
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '5',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(width: 3),
                          Text(
                            '🔥',
                            style: TextStyle(fontSize: 17, height: 1.0),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Headline & Circular Readiness Meter
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAmharic
                                  ? 'የብሔራዊ ፈተና ውጤትዎን\nያሳድጉ'
                                  : 'Master Your National\nExam Score',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                                letterSpacing: -0.4,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                isAmharic
                                    ? 'የተረጋገጡ የስርዓተ ትምህርት ጥያቄዎች ከደረጃ-በ-ደረጃ መፍትሄዎች፣ የከመስመር ውጭ መመርመሪያ እና Exam Ghost ጋር።'
                                    : 'Verified syllabus questions with step-by-step solutions, offline diagnostics, and Exam Ghost.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.42,
                                  color: Color(0xBFD1FAE5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Circular Progress Meter
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x80022C22),
                          border: Border.all(
                            color: const Color(0xFF34D399),
                            width: 3.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$readinessPercent%',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'READY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: Color(0xE66EE7B7),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.only(top: 18, bottom: 14),
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),

                  // 3. Bottom Action Buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 400;

                      final primaryBtn = Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _startRemedialDrill(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF063328),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x4D059669),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '⚡',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAmharic
                                        ? 'ተስማሚ ልምምድ ጀምር'
                                        : 'Start Adaptive Practice',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      final secondaryBtn = Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/challenges'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x59065F46),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x4D10B981),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '⚔️',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAmharic
                                      ? 'የፈተና ውድድሮች'
                                      : 'Exam Ghost Duels',
                                  style: const TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            primaryBtn,
                            const SizedBox(height: 10),
                            secondaryBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 55, child: primaryBtn),
                          const SizedBox(width: 10),
                          Expanded(flex: 45, child: secondaryBtn),
                        ],
                      );
                    },
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
  // 📚 SUBJECT PACKAGE SECTION
  // ==========================================
  Widget _buildSubjectSection(
      BuildContext context, bool isAmharic, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FidelSectionHeader(
          title: isAmharic ? 'የብሔራዊ ፈተና የትምህርት አይነቶች' : 'National Exam Subjects',
          subtitle: isAmharic
              ? 'የስርዓተ ትምህርት ክፍሎችንና የሞዴል ፈተናዎችን ለመለማመድ ትምህርት ይምረጡ'
              : 'Choose a subject to practice syllabus units & mock exams',
          trailing: TextButton.icon(
            onPressed: () => context.push('/subjects'),
            icon: const Icon(Icons.folder_zip_outlined, size: 16),
            label: Text(isAmharic ? 'ጥቅሎች' : 'Manage Packages'),
          ),
        ),
        const SizedBox(height: 14),
        if (_subjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x26334155) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: AppTheme.brand, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic
                            ? 'የትምህርት ጥቅሎች እየተጫኑ ነው...'
                            : 'Loading National Exam Subjects...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppTheme.darkText : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAmharic
                            ? 'የከመስመር ውጭ ጥቅሎችን ለማውረድ Manage Packages ን ይጫኑ'
                            : 'Manage packages to download or refresh offline exam content',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/subjects'),
                  child: Text(isAmharic ? 'ክፈት' : 'Open'),
                ),
              ],
            ),
          )
        else
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FidelBadge(
                text: 'OFFICIAL EXAM',
                variant: FidelBadgeVariant.success,
                isSmall: true,
              ),
              Flexible(
                child: Text(
                  '2013 E.C. (2021 G.C.)',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                    fontSize: 11.5,
                  ),
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
  // 🎯 NATIONAL EXAM READINESS SCORE CARD
  // ==========================================
  Widget _buildReadinessGaugeCard(BuildContext context, bool isDark) {
    final score = _readinessScore > 0 ? _readinessScore : 68.5;
    final isReady = score >= 75.0;
    final isOnTrack = score >= 50.0 && score < 75.0;

    final badgeText = isReady
        ? 'EXAM READY 🎯'
        : (isOnTrack ? 'ON TRACK 📈' : 'NEEDS PRACTICE ⚠️');
    final badgeColor = isReady
        ? AppTheme.green
        : (isOnTrack ? AppTheme.accent : AppTheme.danger);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFFEDE9FE), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.brand.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
        boxShadow: AppTheme.cardShadowDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'National Exam Readiness',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Weighted IRT Model (0 - 100%)',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 7,
                      backgroundColor: isDark
                          ? const Color(0x33334155)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                    ),
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady
                          ? 'Projected Top-Decile University Placement!'
                          : 'Target 80%+ to unlock top university placement.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Factored from mock exam scores, syllabus volume, daily consistency, and error penalty.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startRemedialDrill(),
              icon: const Icon(Icons.bolt_rounded, size: 17),
              label: const Text('1-Tap Remedial Practice (10 Questions)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandStrong,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
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
    final displayedTopics = _weakTopics.isNotEmpty
        ? _weakTopics.take(3).toList()
        : [
            const WeakTopicRecommendation(
              topicId: 'bio_t3_1',
              topicTitleEn: 'Cellular Respiration & Krebs Cycle',
              subjectId: 'biology_g12',
              accuracyPercentage: 45.0,
              totalAttempts: 6,
              mistakeCount: 3,
              urgencyLevel: 'high',
              recommendationReason: 'Priority area',
            ),
            const WeakTopicRecommendation(
              topicId: 'math_t1_1',
              topicTitleEn: 'Arithmetic & Geometric Sequences',
              subjectId: 'math_g12',
              accuracyPercentage: 58.0,
              totalAttempts: 5,
              mistakeCount: 2,
              urgencyLevel: 'medium',
              recommendationReason: 'Priority area',
            ),
            const WeakTopicRecommendation(
              topicId: 'hist_t2_1',
              topicTitleEn: 'Battle of Adwa Treaties',
              subjectId: 'history_g12',
              accuracyPercentage: 62.0,
              totalAttempts: 8,
              mistakeCount: 3,
              urgencyLevel: 'low',
              recommendationReason: 'Priority area',
            ),
          ];

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
          for (final wt in displayedTopics) ...[
            _buildWeakTopicRow(wt, isDark),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
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

  Widget _buildWeakTopicRow(WeakTopicRecommendation wt, bool isDark) {
    final accuracy = wt.accuracyPercentage / 100.0;
    final color = accuracy < 0.50
        ? AppTheme.danger
        : (accuracy < 0.65 ? AppTheme.accent : AppTheme.green);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                wt.topicTitleEn,
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _startRemedialDrill(wt),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Drill',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brand,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: accuracy.clamp(0.0, 1.0),
            backgroundColor:
                isDark ? const Color(0x33334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
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
