import 'dart:ui' show PointerDeviceKind;

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
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
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
  List<Subject> _subjects = _getDefaultNationalSubjects(12, 'natural');
  ExamAttempt? _recentAttempt;
  List<WeakTopicRecommendation> _weakTopics = [];
  double _readinessScore = 0.0;
  bool _isLoading = true;

  static List<Subject> _getDefaultNationalSubjects(int grade, String stream) {
    final isNatural = stream.toLowerCase() != 'social';
    final mathVariants = [
      SubjectExamVariant(
        variantId: 'math_g${grade}_natural',
        subjectId: 'math_g$grade',
        variantCode: ExamVariantCode.naturalScience,
        nameEn: 'Mathematics (Natural Science)',
        nameAm: 'ሒሳብ (የተፈጥሮ ሳይንስ)',
        streamEligibility: 'natural',
        assessmentStructure: AssessmentStructure.curriculum,
      ),
      SubjectExamVariant(
        variantId: 'math_g${grade}_social',
        subjectId: 'math_g$grade',
        variantCode: ExamVariantCode.socialScience,
        nameEn: 'Mathematics (Social Science)',
        nameAm: 'ሒሳብ (የማህበራዊ ሳይንስ)',
        streamEligibility: 'social',
        assessmentStructure: AssessmentStructure.curriculum,
      ),
    ];

    if (isNatural) {
      return [
        Subject(
          id: 'english_g$grade',
          code: 'ENG$grade',
          nameEn: 'English',
          nameAm: 'እንግሊዝኛ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.mixed,
          sortOrder: 1,
        ),
        Subject(
          id: 'math_g$grade',
          code: 'MATH$grade',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          availableVariants: mathVariants,
          sortOrder: 2,
        ),
        Subject(
          id: 'aptitude_g$grade',
          code: 'APT$grade',
          nameEn: 'Scholastic Aptitude',
          nameAm: 'የተፈጥሮ ተሰጥኦ (አፕቲትዩድ)',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.skillBased,
          sortOrder: 3,
        ),
        Subject(
          id: 'physics_g$grade',
          code: 'PHYS$grade',
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
          grade: grade,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          sortOrder: 4,
        ),
        Subject(
          id: 'chemistry_g$grade',
          code: 'CHEM$grade',
          nameEn: 'Chemistry',
          nameAm: 'ኬሚስትሪ',
          grade: grade,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          sortOrder: 5,
        ),
        Subject(
          id: 'biology_g$grade',
          code: 'BIO$grade',
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
          grade: grade,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          sortOrder: 6,
        ),
        Subject(
          id: 'civics_g$grade',
          code: 'CIV$grade',
          nameEn: 'Civics',
          nameAm: 'ስነ-ዜጋ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.curriculumOnly,
          sortOrder: 7,
        ),
      ];
    } else {
      return [
        Subject(
          id: 'english_g$grade',
          code: 'ENG$grade',
          nameEn: 'English',
          nameAm: 'እንግሊዝኛ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.mixed,
          sortOrder: 1,
        ),
        Subject(
          id: 'math_g$grade',
          code: 'MATH$grade',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          availableVariants: mathVariants,
          sortOrder: 2,
        ),
        Subject(
          id: 'aptitude_g$grade',
          code: 'APT$grade',
          nameEn: 'Scholastic Aptitude',
          nameAm: 'የተፈጥሮ ተሰጥኦ (አፕቲትዩድ)',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.skillBased,
          sortOrder: 3,
        ),
        Subject(
          id: 'history_g$grade',
          code: 'HIST$grade',
          nameEn: 'History',
          nameAm: 'ታሪክ',
          grade: grade,
          stream: 'social',
          scope: SubjectScope.streamExam,
          sortOrder: 4,
        ),
        Subject(
          id: 'geography_g$grade',
          code: 'GEO$grade',
          nameEn: 'Geography',
          nameAm: 'ጂኦግራፊ',
          grade: grade,
          stream: 'social',
          scope: SubjectScope.streamExam,
          sortOrder: 5,
        ),
        Subject(
          id: 'economics_g$grade',
          code: 'ECON$grade',
          nameEn: 'Economics',
          nameAm: 'ኢኮኖሚክስ',
          grade: grade,
          stream: 'social',
          scope: SubjectScope.streamExam,
          sortOrder: 6,
        ),
        Subject(
          id: 'civics_g$grade',
          code: 'CIV$grade',
          nameEn: 'Civics',
          nameAm: 'ስነ-ዜጋ',
          grade: grade,
          stream: 'common',
          scope: SubjectScope.curriculumOnly,
          sortOrder: 7,
        ),
      ];
    }
  }

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

        final defaultSubjects =
            _getDefaultNationalSubjects(user.grade, user.stream);
        if (subs.isEmpty) {
          subs = defaultSubjects;
        } else {
          final existingIds = subs.map((s) => s.id.toLowerCase()).toSet();
          final existingNames = subs.map((s) => s.nameEn.toLowerCase()).toSet();
          for (final def in defaultSubjects) {
            if (!existingIds.contains(def.id.toLowerCase()) &&
                !existingNames.contains(def.nameEn.toLowerCase())) {
              subs.add(def);
            }
          }
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

  Future<void> _startFullOfficialExam(int tabIndex) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final contentRepo = ref.read(contentRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    final String subjectId;
    final int examYear;
    final String title;
    final int timeLimitMinutes;

    if (tabIndex == 0) {
      subjectId = 'physics_g12';
      examYear = 2014;
      title = 'ESSLCE Physics 2014 E.C. (Natural Science, 32 Questions)';
      timeLimitMinutes = 120;
    } else if (tabIndex == 1) {
      subjectId = 'biology_g12';
      examYear = 2013;
      title = 'ESSLCE Biology 2013 E.C. (Natural Science, 100 Questions)';
      timeLimitMinutes = 150;
    } else {
      subjectId = 'civics_g12';
      examYear = 2015;
      title = 'ESSLCE Civics 2015 E.C. (Social/Natural Science, 100 Questions)';
      timeLimitMinutes = 150;
    }

    final questions = await contentRepo.getQuestions(
      grade: 12,
      subjectId: subjectId,
      examYear: examYear,
    );

    if (questions.isEmpty) {
      if (mounted) {
        await context.push('/subject_exams/$subjectId');
      }
      return;
    }

    final sortedQuestions = List<Question>.from(questions)
      ..sort((a, b) {
        if (a.sourcePage != null &&
            b.sourcePage != null &&
            a.sourcePage != b.sourcePage) {
          return a.sourcePage!.compareTo(b.sourcePage!);
        }
        return a.id.compareTo(b.id);
      });

    final exam = Exam(
      id: 'exam_${subjectId}_${examYear}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      examType: ExamType.practice,
      grade: 12,
      stream: tabIndex == 2 ? 'common' : 'natural',
      subjectId: subjectId,
      timeLimitMinutes: timeLimitMinutes,
      totalQuestions: sortedQuestions.length,
      questions: sortedQuestions,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

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
      // No top header AppBar - Hero card starts edge-to-edge from the very top
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
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🚀 Section 1: Full-Width Hero Card (Zero Side Paddings)
                    _buildMissionControlHero(context, user, isAmharic, isDark),

                    // Content Container with Responsive Margins Below Hero Card
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40.0 : (isTablet ? 24.0 : 16.0),
                        vertical: 28.0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 📚 Section 2: National Exam Subjects
                              _buildSubjectSection(
                                  context, user, isAmharic, isDark),
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
                                          _buildFeaturedExamCard(
                                              context, isDark, isAmharic),
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
                                          _buildReadinessGaugeCard(
                                              context, isDark),
                                          const SizedBox(height: 24),
                                          _buildWeakTopicRadarCard(
                                              context, isDark),
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
                                _buildFeaturedExamCard(
                                    context, isDark, isAmharic),
                                const SizedBox(height: 24),
                                _buildReadinessGaugeCard(context, isDark),
                                const SizedBox(height: 28),
                                _buildWeakTopicRadarCard(context, isDark),
                                if (_recentAttempt != null) ...[
                                  const SizedBox(height: 24),
                                  _buildRecentPerformanceCard(context, isDark),
                                ],
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
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
        boxShadow: [
          BoxShadow(
            color: Color(0x4D042F2E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
              padding: EdgeInsets.only(
                top: topPadding > 0 ? topPadding + 14 : 22,
                left: 20,
                right: 20,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Badges Row: Grade, Alignment, Sync, Streak
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

                      // Right: Sync Indicator + Streak Counter
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SyncIndicatorWidget(isCompact: true),
                          SizedBox(width: 10),
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
                                  isAmharic ? 'የፈተና ውድድሮች' : 'Exam Ghost Duels',
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
  // 📚 SECTION 2: NATIONAL EXAM SUBJECTS
  // ==========================================
  Widget _buildSubjectSection(
    BuildContext context,
    UserProfile user,
    bool isAmharic,
    bool isDark,
  ) {
    // Dynamic stream and grade label (e.g. "Grade 12 Natural Science")
    final streamLabel = user.stream.toLowerCase() == 'natural'
        ? (isAmharic ? 'የተፈጥሮ ሳይንስ' : 'Natural Science')
        : (user.stream.toLowerCase() == 'social'
            ? (isAmharic ? 'የማህበራዊ ሳይንስ' : 'Social Science')
            : user.stream.toUpperCase());

    final gradeSubtitle = isAmharic
        ? '${user.grade}ኛ ክፍል $streamLabel'
        : 'Grade ${user.grade} $streamLabel';

    // Ensure all national exam subjects are always present
    final defaultSubjects =
        _getDefaultNationalSubjects(user.grade, user.stream);
    List<Subject> effectiveSubjects = List<Subject>.from(_subjects);
    if (effectiveSubjects.isEmpty) {
      effectiveSubjects = defaultSubjects;
    } else {
      final existingIds =
          effectiveSubjects.map((s) => s.id.toLowerCase()).toSet();
      final existingNames =
          effectiveSubjects.map((s) => s.nameEn.toLowerCase()).toSet();
      for (final def in defaultSubjects) {
        if (!existingIds.contains(def.id.toLowerCase()) &&
            !existingNames.contains(def.nameEn.toLowerCase())) {
          effectiveSubjects.add(def);
        }
      }
    }

    // Sort subjects by curriculum sequence (Math 1, Biology 2, Physics 3, Chemistry 4, English 5, Civics 6)
    effectiveSubjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final topSubjects = effectiveSubjects.take(2).toList();
    final carouselSubjects = effectiveSubjects.skip(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header: Title, Subtitle, and "Manage >" action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAmharic
                        ? 'የብሔራዊ ፈተና የትምህርት አይነቶች'
                        : 'National Exam Subjects',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gradeSubtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/subjects'),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAmharic ? 'አስተዳድር' : 'Manage',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Layout: Responsive cards layout across wide desktop, tablet/medium, and mobile
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isWideDesktop = screenWidth >= 1050;
            final isMediumWidth = screenWidth >= 640 && screenWidth < 1050;

            if (isWideDesktop) {
              return Row(
                children: [
                  for (int i = 0; i < effectiveSubjects.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _buildRedesignedSubjectCard(
                        context: context,
                        subject: effectiveSubjects[i],
                        isAmharic: isAmharic,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              );
            }

            if (isMediumWidth) {
              final row1 = effectiveSubjects.take(3).toList();
              final row2 = effectiveSubjects.skip(3).toList();
              return Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < row1.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _buildRedesignedSubjectCard(
                            context: context,
                            subject: row1[i],
                            isAmharic: isAmharic,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (row2.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (int i = 0; i < row2.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _buildRedesignedSubjectCard(
                              context: context,
                              subject: row2[i],
                              isAmharic: isAmharic,
                              isDark: isDark,
                            ),
                          ),
                        ],
                        for (int i = 0;
                            i < (row1.length - row2.length);
                            i++) ...[
                          const SizedBox(width: 12),
                          const Spacer(),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            }

            final carouselCardWidth = (screenWidth * 0.46).clamp(152.0, 185.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top 2-Column Grid Row (Mathematics, Biology / History)
                Row(
                  children: [
                    for (int i = 0; i < topSubjects.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _buildRedesignedSubjectCard(
                          context: context,
                          subject: topSubjects[i],
                          isAmharic: isAmharic,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),

                // Carousel Row for Remaining Subjects (Physics, Chemistry, English, Civics, ...)
                if (carouselSubjects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (int i = 0; i < carouselSubjects.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            _buildRedesignedSubjectCard(
                              context: context,
                              subject: carouselSubjects[i],
                              isAmharic: isAmharic,
                              isDark: isDark,
                              width: carouselCardWidth,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRedesignedSubjectCard({
    required BuildContext context,
    required Subject subject,
    required bool isAmharic,
    required bool isDark,
    double? width,
  }) {
    final theme = _getSubjectDesignTheme(subject);
    final rawTitle = isAmharic && subject.nameAm.isNotEmpty
        ? subject.nameAm
        : subject.nameEn;
    final subjectTitle = rawTitle.toLowerCase().contains('civic')
        ? (isAmharic ? 'ስነ-ዜጋ' : 'Civics')
        : rawTitle;

    return Container(
      width: width,
      height: 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -0.9),
          end: const Alignment(0.9, 0.9),
          stops: const [0.3, 1.0],
          colors: isDark
              ? [theme.darkBgStart, theme.darkBgEnd]
              : [theme.lightBgStart, theme.lightBgEnd],
        ),
        border: Border.all(
          color: isDark ? theme.darkBorder : theme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color:
                const Color(0xFF0F172A).withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/subject_exams/${subject.id}'),
          borderRadius: BorderRadius.circular(16),
          splashColor: theme.primaryColor.withValues(alpha: 0.12),
          highlightColor: theme.primaryColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon Container + "Saved" Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // w-9 h-9 (36x36) rounded-xl Icon Container
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? theme.iconBgDark : theme.iconBgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? theme.darkBorder
                              : theme.primaryColor.withValues(alpha: 0.20),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(child: theme.iconWidget),
                    ),

                    // "Saved" Badge with Pulsing Emerald Dot
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF064E3B).withValues(alpha: 0.70)
                            : Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF059669).withValues(alpha: 0.60)
                              : const Color(0xCCA7F3D0),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.60),
                                  blurRadius: 3,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAmharic ? 'ተቀምጧል' : 'Saved',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF065F46),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Section: Subject Name & (Grade + Circle Arrow Button)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subjectTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: (subject.id.contains('physics') ||
                                  subject.code.contains('PHYS'))
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.45),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isAmharic
                                        ? '2014 ፈተና (32 Qs)'
                                        : '2014 Exam (32 Qs)',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD97706),
                                      height: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : (subject.id.contains('biology') ||
                                      subject.code.contains('BIO'))
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.45),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isAmharic
                                            ? '2013 ፈተና (100 Qs)'
                                            : '2013 Exam (100 Qs)',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF059669),
                                          height: 1.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : (subject.id.contains('chemistry') ||
                                          subject.code.contains('CHEM'))
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9333EA)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                              color: const Color(0xFF9333EA)
                                                  .withValues(alpha: 0.45),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            isAmharic
                                                ? '2013-17 ፈተና (386 Qs)'
                                                : '2013-17 Exam (386 Qs)',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF7E22CE),
                                              height: 1.0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      : (subject.id.contains('civic') ||
                                              subject.code.contains('CIV'))
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D9488)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: const Color(0xFF0D9488)
                                                      .withValues(alpha: 0.45),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                isAmharic
                                                    ? '2013-15 ፈተና (300 Qs)'
                                                    : '2013-15 Exam (300 Qs)',
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0D9488),
                                                  height: 1.0,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          : Text(
                                              isAmharic
                                                  ? '${subject.grade}ኛ ክፍል'
                                                  : 'Grade ${subject.grade}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? AppTheme.darkMuted
                                                    : const Color(0xFF64748B),
                                                height: 1.0,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? theme.arrowBorderColor
                                      .withValues(alpha: 0.4)
                                  : theme.arrowBorderColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: theme.arrowTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SubjectDesignTheme _getSubjectDesignTheme(Subject subject) {
    final key = '${subject.id} ${subject.code} ${subject.nameEn}'.toLowerCase();

    if (key.contains('math')) {
      return const _SubjectDesignTheme(
        iconWidget: Text(
          '∑',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6366F1),
            height: 1.0,
          ),
        ),
        primaryColor: Color(0xFF6366F1),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFEFF4FC),
        lightBorder: Color(0xCCE0E7FF),
        darkBgStart: Color(0xFF1E1E2E),
        darkBgEnd: Color(0xFF1E1B4B),
        darkBorder: Color(0xFF312E81),
        iconBgLight: Color(0xFFEEF2FF),
        iconBgDark: Color(0x336366F1),
        arrowBorderColor: Color(0xFFE0E7FF),
        arrowTextColor: Color(0xFF6366F1),
      );
    } else if (key.contains('bio')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.biotech,
          size: 18,
          color: Color(0xFF047857),
        ),
        primaryColor: Color(0xFF059669),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFECFDF5),
        lightBorder: Color(0xB3A7F3D0),
        darkBgStart: Color(0xFF0F2922),
        darkBgEnd: Color(0xFF064E3B),
        darkBorder: Color(0xFF065F46),
        iconBgLight: Color(0xFFECFDF5),
        iconBgDark: Color(0x33059669),
        arrowBorderColor: Color(0xFFA7F3D0),
        arrowTextColor: Color(0xFF047857),
      );
    } else if (key.contains('phys')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.bolt,
          size: 18,
          color: Color(0xFF1D4ED8),
        ),
        primaryColor: Color(0xFF2563EB),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFEFF6FF),
        lightBorder: Color(0xFFDBEAFE),
        darkBgStart: Color(0xFF13203E),
        darkBgEnd: Color(0xFF1E3A8A),
        darkBorder: Color(0xFF1E40AF),
        iconBgLight: Color(0xFFEFF6FF),
        iconBgDark: Color(0x332563EB),
        arrowBorderColor: Color(0xFFDBEAFE),
        arrowTextColor: Color(0xFF1D4ED8),
      );
    } else if (key.contains('chem')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.science,
          size: 18,
          color: Color(0xFF7E22CE),
        ),
        primaryColor: Color(0xFF9333EA),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFFAF5FF),
        lightBorder: Color(0xFFF3E8FF),
        darkBgStart: Color(0xFF231438),
        darkBgEnd: Color(0xFF3B0764),
        darkBorder: Color(0xFF581C87),
        iconBgLight: Color(0xFFFAF5FF),
        iconBgDark: Color(0x339333EA),
        arrowBorderColor: Color(0xFFF3E8FF),
        arrowTextColor: Color(0xFF7E22CE),
      );
    } else if (key.contains('eng')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.menu_book,
          size: 18,
          color: Color(0xFFB45309),
        ),
        primaryColor: Color(0xFFD97706),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFFEF3C7),
        lightBorder: Color(0xFFFEF3C7),
        darkBgStart: Color(0xFF2D1F0E),
        darkBgEnd: Color(0xFF78350F),
        darkBorder: Color(0xFF92400E),
        iconBgLight: Color(0xFFFEF3C7),
        iconBgDark: Color(0x33D97706),
        arrowBorderColor: Color(0xFFFEF3C7),
        arrowTextColor: Color(0xFFB45309),
      );
    } else if (key.contains('hist')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.history_edu,
          size: 18,
          color: Color(0xFFC2410C),
        ),
        primaryColor: Color(0xFFEA580C),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFFFEDD5),
        lightBorder: Color(0xFFFED7AA),
        darkBgStart: Color(0xFF2E190E),
        darkBgEnd: Color(0xFF7C2D12),
        darkBorder: Color(0xFF9A3412),
        iconBgLight: Color(0xFFFFF7ED),
        iconBgDark: Color(0x33EA580C),
        arrowBorderColor: Color(0xFFFED7AA),
        arrowTextColor: Color(0xFFC2410C),
      );
    } else if (key.contains('geo')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.public,
          size: 18,
          color: Color(0xFF0F766E),
        ),
        primaryColor: Color(0xFF0D9488),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFF0FDFA),
        lightBorder: Color(0xFF99F6E4),
        darkBgStart: Color(0xFF0D2523),
        darkBgEnd: Color(0xFF134E4A),
        darkBorder: Color(0xFF115E59),
        iconBgLight: Color(0xFFCCFBF1),
        iconBgDark: Color(0x330D9488),
        arrowBorderColor: Color(0xFF99F6E4),
        arrowTextColor: Color(0xFF0F766E),
      );
    } else if (key.contains('civ')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.balance_rounded,
          size: 18,
          color: Color(0xFF0D9488),
        ),
        primaryColor: Color(0xFF0D9488),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFF0FDFA),
        lightBorder: Color(0xFF99F6E4),
        darkBgStart: Color(0xFF0D2523),
        darkBgEnd: Color(0xFF134E4A),
        darkBorder: Color(0xFF115E59),
        iconBgLight: Color(0xFFCCFBF1),
        iconBgDark: Color(0x330D9488),
        arrowBorderColor: Color(0xFF99F6E4),
        arrowTextColor: Color(0xFF0D9488),
      );
    } else if (key.contains('econ')) {
      return const _SubjectDesignTheme(
        iconWidget: Icon(
          Icons.balance,
          size: 18,
          color: Color(0xFF334155),
        ),
        primaryColor: Color(0xFF475569),
        lightBgStart: Color(0xFFFFFFFF),
        lightBgEnd: Color(0xFFF1F5F9),
        lightBorder: Color(0xFFCBD5E1),
        darkBgStart: Color(0xFF1E293B),
        darkBgEnd: Color(0xFF334155),
        darkBorder: Color(0xFF475569),
        iconBgLight: Color(0xFFF1F5F9),
        iconBgDark: Color(0x33475569),
        arrowBorderColor: Color(0xFFCBD5E1),
        arrowTextColor: Color(0xFF334155),
      );
    } else {
      return _SubjectDesignTheme(
        iconWidget: Text(
          subject.nameEn.isNotEmpty ? subject.nameEn[0] : 'S',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.brand,
          ),
        ),
        primaryColor: AppTheme.brand,
        lightBgStart: Colors.white,
        lightBgEnd: const Color(0xFFF8FAFC),
        lightBorder: const Color(0xFFE2E8F0),
        darkBgStart: AppTheme.darkSurface,
        darkBgEnd: const Color(0xFF1E293B),
        darkBorder: AppTheme.darkBorder,
        iconBgLight: const Color(0xFFEEF2FF),
        iconBgDark: const Color(0x336366F1),
        arrowBorderColor: const Color(0xFFE2E8F0),
        arrowTextColor: AppTheme.brand,
      );
    }
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
  // ⚡ / 🧬 / ⚖️ FEATURED OFFICIAL EXAM CARD (Physics 2014, Biology 2013, & Civics 2015)
  // ==========================================
  int _featuredExamTab = 0; // 0: Physics 2014, 1: Biology 2013, 2: Civics 2015

  Widget _buildFeaturedExamCard(
    BuildContext context,
    bool isDark,
    bool isAmharic,
  ) {
    final isPhysics = _featuredExamTab == 0;
    final isBiology = _featuredExamTab == 1;
    final isCivics = _featuredExamTab == 2;

    final accentColor = isPhysics
        ? const Color(0xFFD97706)
        : (isBiology ? AppTheme.greenDark : const Color(0xFF0D9488));
    final borderColor = isPhysics
        ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
        : (isBiology
            ? AppTheme.green.withValues(alpha: 0.35)
            : const Color(0xFF0D9488).withValues(alpha: 0.40));
    final bgColor = isPhysics
        ? (isDark ? const Color(0xFF261D0B) : const Color(0xFFFFFBEB))
        : (isBiology
            ? (isDark ? const Color(0xFF0D2523) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDFA)));

    return FidelCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: bgColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector tabs: Physics 2014 vs Biology 2013 vs Civics 2015
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeaturedTabPill(
                title: isAmharic
                    ? '⚡ ፊዚክስ 2014 (32 ጥያቄ)'
                    : '⚡ Physics 2014 (32 Qs)',
                isActive: isPhysics,
                activeColor: const Color(0xFFD97706),
                isDark: isDark,
                onTap: () => setState(() => _featuredExamTab = 0),
              ),
              _buildFeaturedTabPill(
                title: isAmharic
                    ? '🧬 ባዮሎጂ 2013 (100 ጥያቄ)'
                    : '🧬 Biology 2013 (100 Qs)',
                isActive: isBiology,
                activeColor: const Color(0xFF059669),
                isDark: isDark,
                onTap: () => setState(() => _featuredExamTab = 1),
              ),
              _buildFeaturedTabPill(
                title: isAmharic
                    ? '⚖️ ስነ-ዜጋ 2015 (100 ጥያቄ)'
                    : '⚖️ Civics 2015 (100 Qs)',
                isActive: isCivics,
                activeColor: const Color(0xFF0D9488),
                isDark: isDark,
                onTap: () => setState(() => _featuredExamTab = 2),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Top Info Row: Badge + Year Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isPhysics
                          ? const Color(0xFFF59E0B)
                          : (isBiology
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0D9488)))
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isPhysics
                            ? const Color(0xFFF59E0B)
                            : (isBiology
                                ? const Color(0xFF10B981)
                                : const Color(0xFF0D9488)))
                        .withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: isPhysics
                          ? const Color(0xFFD97706)
                          : (isBiology
                              ? const Color(0xFF059669)
                              : const Color(0xFF0D9488)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPhysics
                          ? (isAmharic
                              ? 'የተረጋገጠ ፈተና • 32 ጥያቄ'
                              : 'OFFICIAL EXAM • 32 Qs')
                          : (isAmharic
                              ? 'የተረጋገጠ ፈተና • 100 ጥያቄ'
                              : 'OFFICIAL EXAM • 100 Qs'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPhysics
                            ? const Color(0xFFD97706)
                            : (isBiology
                                ? const Color(0xFF059669)
                                : const Color(0xFF0D9488)),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  isPhysics
                      ? (isAmharic
                          ? '2014 ዓ.ም. (2022) • ቡክሌት 11'
                          : '2014 E.C. (2022 G.C.) • Booklet 11')
                      : (isBiology
                          ? (isAmharic
                              ? '2013 ዓ.ም. (2021) • ቡክሌት 12'
                              : '2013 E.C. (2021 G.C.) • Booklet 12')
                          : (isAmharic
                              ? '2015 ዓ.ም. (2023) • ቡክሌት 653'
                              : '2015 E.C. (2023 G.C.) • Booklet 653')),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            isPhysics
                ? (isAmharic
                    ? 'የ2014 የፊዚክስ ብሔራዊ ፈተና (32 ጥያቄዎች)'
                    : 'ESSLCE Physics 2014 (32 Questions)')
                : (isBiology
                    ? (isAmharic
                        ? 'የ2013 የባዮሎጂ ብሔራዊ ፈተና (100 ጥያቄዎች)'
                        : 'ESSLCE Biology 2013 (100 Questions)')
                    : (isAmharic
                        ? 'የ2015 የሲቪክስ ብሔራዊ ፈተና (100 ጥያቄዎች)'
                        : 'ESSLCE Civics 2015 (100 Questions)')),
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            isPhysics
                ? (isAmharic
                    ? 'ከነሙሉ ማብራሪያ፣ የስዕልና ዲያግራም ምስሎች፣ እና ደረጃ በደረጃ የሂሳብ አሰራር ጋር የተዘጋጀ ይፋዊ ፈተና።'
                    : 'Official National Exam with vector mechanics, circuits, wave optics, & complete step-by-step solutions.')
                : (isBiology
                    ? (isAmharic
                        ? 'ከነሙሉ ማብራሪያ፣ የቬክተር ዲያግራም እና የባክቴሪዮፋጅ ምስሎች ጋር የተዘጋጀ ይፋዊ ፈተና።'
                        : 'Official National Exam with vector diagrams, bacteriophage models, & complete solutions.')
                    : (isAmharic
                        ? 'ከነሙሉ ማብራሪያ፣ ሕገ-መንግሥታዊ ዴሞክራሲ፣ የሰብዓዊ መብቶች እና የሕግ የበላይነት ጋር የተዘጋጀ ይፋዊ ፈተና።'
                        : 'Official National Exam with constitutional democracy, human rights, rule of law, & complete solutions.')),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _startFullOfficialExam(_featuredExamTab),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: Text(
                  isPhysics
                      ? (isAmharic
                          ? 'የ32ቱን ጥያቄ ይፋዊ ፈተና ጀምር'
                          : 'Start Official 32-Question Exam')
                      : (isAmharic
                          ? 'የ100ውን ጥያቄ ይፋዊ ፈተና ጀምር'
                          : 'Start Official 100-Question Exam'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (isPhysics) {
                    context.push('/exam_builder?subjectId=physics_g12');
                  } else if (isBiology) {
                    context.push('/exam_builder?subjectId=biology_g12');
                  } else {
                    context.push('/exam_builder?subjectId=civics_g12');
                  }
                },
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(
                  isAmharic ? 'ብጁ ልምምድ' : 'Custom Practice',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white70 : const Color(0xFF334155),
                  side: BorderSide(
                    color:
                        isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (isPhysics) {
                    context.push('/subject_exams/physics_g12');
                  } else if (isBiology) {
                    context.push('/subject_exams/biology_g12');
                  } else {
                    context.push('/subject_exams/civics_g12');
                  }
                },
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(
                  isAmharic ? 'ሁሉንም ዓመታት እይ' : 'View All Years',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white70 : const Color(0xFF334155),
                  side: BorderSide(
                    color:
                        isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTabPill({
    required String title,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: isActive ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? activeColor
                : (isDark ? AppTheme.darkMuted : const Color(0xFF64748B)),
          ),
        ),
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

class _SubjectDesignTheme {
  final Widget iconWidget;
  final Color primaryColor;
  final Color lightBgStart;
  final Color lightBgEnd;
  final Color lightBorder;
  final Color darkBgStart;
  final Color darkBgEnd;
  final Color darkBorder;
  final Color iconBgLight;
  final Color iconBgDark;
  final Color arrowBorderColor;
  final Color arrowTextColor;

  const _SubjectDesignTheme({
    required this.iconWidget,
    required this.primaryColor,
    required this.lightBgStart,
    required this.lightBgEnd,
    required this.lightBorder,
    required this.darkBgStart,
    required this.darkBgEnd,
    required this.darkBorder,
    required this.iconBgLight,
    required this.iconBgDark,
    required this.arrowBorderColor,
    required this.arrowTextColor,
  });
}
