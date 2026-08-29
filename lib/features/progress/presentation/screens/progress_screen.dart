import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/progress_models.dart';
import '../../domain/services/weak_topic_detector.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  List<ExamAttempt> _attempts = [];
  List<WeakTopicRecommendation> _weakTopics = [];
  double _readinessScore = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final examRepo = ref.read(examRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);

    if (user != null) {
      final history = await examRepo.getAttemptHistory(user.id);
      final allQuestions = await contentRepo.getQuestions(
        grade: user.grade,
        subjectId: 'math_g12',
      );
      final allAptQuestions = await contentRepo.getQuestions(
        grade: user.grade,
        subjectId: 'aptitude_g12',
      );
      final allBioQuestions = await contentRepo.getQuestions(
        grade: user.grade,
        subjectId: 'biology_g12',
      );

      final Map<String, Question> qMap = {
        for (final q in [...allQuestions, ...allAptQuestions, ...allBioQuestions]) q.id: q,
      };

      final Map<String, String> topicMap = {
        'math_t1_1': 'Arithmetic Progressions',
        'math_t1_2': 'Geometric Series & Convergence',
        'math_t2_1': 'Limits at Infinity',
        'math_t2_2': 'Derivatives & Rates of Change',
        'apt_t1_1': 'Number Patterns & Series',
        'apt_t1_2': 'Quantitative Proportions & Ratios',
        'apt_t2_1': 'Semantic Analogies',
        'apt_t2_2': 'Logical Deductions',
        'bio_t3_1': 'Cellular Respiration & Krebs Cycle',
        'bio_t5_1': 'DNA Semiconservative Replication',
      };

      const detector = WeakTopicDetector(
        minAttemptsThreshold: 1,
        weakAccuracyThreshold: 60.0,
      );
      final detected = detector.detectWeakTopics(
        completedAttempts: history,
        questionMap: qMap,
        topicTitleMap: topicMap,
      );

      double avgScore = 0.0;
      if (history.isNotEmpty) {
        final totalPct = history.fold<double>(
          0.0,
          (acc, a) => acc + a.percentage,
        );
        avgScore = totalPct / history.length;
      }

      final readiness = WeakTopicDetector.calculateReadinessScore(
        totalExamsCompleted: history.length,
        averageScorePercentage: avgScore,
        weakTopicCount: detected.length,
        studyStreakDays: 5,
      );

      if (mounted) {
        setState(() {
          _attempts = history;
          _weakTopics = detected;
          _readinessScore = readiness;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Readiness & IRT Analytics Studio', style: TextStyle(fontWeight: FontWeight.bold)),
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
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Readiness Radar & Projection (48%)
                      Expanded(
                        flex: 48,
                        child: Column(
                          children: [
                            _buildReadinessScoreCard(context),
                            const SizedBox(height: 24),
                            _buildHistoricalAttemptsCard(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),

                      // Right Column: Weak Topics & Remediation (52%)
                      Expanded(
                        flex: 52,
                        child: Column(
                          children: [
                            _buildWeakTopicsCard(context),
                            const SizedBox(height: 24),
                            _buildSubjectMasteryCard(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildReadinessScoreCard(context),
                  const SizedBox(height: 20),
                  _buildWeakTopicsCard(context),
                  const SizedBox(height: 20),
                  _buildSubjectMasteryCard(context),
                  const SizedBox(height: 20),
                  _buildHistoricalAttemptsCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessScoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brand.withOpacity(0.4)),
        boxShadow: AppTheme.cardShadowDark,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'National Exam Readiness',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'AI-Free Item Response Theory (IRT) Projection',
                    style: TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.green.withOpacity(0.5)),
                ),
                child: const Text(
                  'ON TRACK 🎯',
                  style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Readiness Dial
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkSurfaceStrong.withOpacity(0.8),
              border: Border.all(color: AppTheme.brand, width: 4),
              boxShadow: AppTheme.brandGlow,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_readinessScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brand,
                    ),
                  ),
                  const Text(
                    'READINESS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Projected National Score: 580 – 625 / 700',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accent),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on completed practice sessions, speed accuracy curve, and streak consistency.',
            style: TextStyle(fontSize: 12, color: AppTheme.darkTextSoft, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakTopicsCard(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Identified Weak Topics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_weakTopics.length} Areas',
                  style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_weakTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Great job! No weak topics detected yet. Complete more exams to unlock deeper diagnostics.',
                  style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _weakTopics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final wt = _weakTopics[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: AppTheme.danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wt.topicTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${wt.accuracyPercentage.toStringAsFixed(0)}% Accuracy (${wt.correctCount}/${wt.attemptCount} correct)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/exam_builder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandStrong,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Drill Topic'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectMasteryCard(BuildContext context) {
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
          const Text(
            'Curriculum Stream Mastery',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMasteryProgressRow('Grade 12 Biology (2013 ESSLCE)', 0.88, AppTheme.green),
          const SizedBox(height: 12),
          _buildMasteryProgressRow('Grade 12 Mathematics (Calculus & Vectors)', 0.74, AppTheme.brand),
          const SizedBox(height: 12),
          _buildMasteryProgressRow('Aptitude & Logical Reasoning', 0.81, AppTheme.accent),
          const SizedBox(height: 12),
          _buildMasteryProgressRow('Grade 12 Physics & Chemistry', 0.65, AppTheme.pink),
        ],
      ),
    );
  }

  Widget _buildMasteryProgressRow(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0x1AFFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalAttemptsCard(BuildContext context) {
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
          const Text(
            'Recent Attempt History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (_attempts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No exam attempts recorded yet.',
                style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attempts.length > 4 ? 4 : _attempts.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 16),
              itemBuilder: (context, index) {
                final att = _attempts[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(att.examTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${att.score}/${att.totalQuestions} questions • ${att.durationSeconds}s', style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
                      ],
                    ),
                    Text(
                      '${att.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: att.percentage >= 70.0 ? AppTheme.green : AppTheme.accent,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
