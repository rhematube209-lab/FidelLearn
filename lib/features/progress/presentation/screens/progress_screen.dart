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

      final Map<String, Question> qMap = {
        for (final q in [...allQuestions, ...allAptQuestions]) q.id: q,
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
    int totalQuestionsAnswered = _attempts.fold(
      0,
      (acc, a) => acc + a.totalQuestions,
    );
    double avgPercentage = _attempts.isNotEmpty
        ? _attempts.fold(0.0, (acc, a) => acc + a.percentage) / _attempts.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Readiness'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. National Exam Readiness Gauge Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: CircularProgressIndicator(
                                value: _readinessScore / 100.0,
                                strokeWidth: 8,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _readinessScore >= 70
                                      ? AppTheme.successGreen
                                      : (_readinessScore >= 50
                                            ? AppTheme.accentGold
                                            : AppTheme.errorRed),
                                ),
                              ),
                            ),
                            Text(
                              '${_readinessScore.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exam Readiness Score',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _readinessScore >= 70
                                    ? 'Targeting University Distinction! Keep sharpening weak topics.'
                                    : 'Solve more custom mock exams and retry mistakes to boost your readiness.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. High-level Statistics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          'Exams Completed',
                          '${_attempts.length}',
                          Icons.assignment_turned_in,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          'Questions Solved',
                          '$totalQuestionsAnswered',
                          Icons.quiz,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          'Average Score',
                          '${avgPercentage.toStringAsFixed(0)}%',
                          Icons.show_chart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Weak-Topic Recommendations (Rule-based diagnostics)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weak-Topic Diagnostics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _weakTopics.isNotEmpty
                              ? AppTheme.errorRed.withOpacity(0.1)
                              : AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _weakTopics.isNotEmpty
                              ? '${_weakTopics.length} Focus Areas'
                              : 'All Clear',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _weakTopics.isNotEmpty
                                ? AppTheme.errorRed
                                : AppTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_weakTopics.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.successGreen),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No critical weak topics detected. Take more exams to generate targeted diagnostics.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _weakTopics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final wt = _weakTopics[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      wt.topicTitleEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Accuracy: ${wt.accuracyPercentage}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  wt.recommendationReason,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => context.push(
                                      '/exam_builder?subjectId=${wt.subjectId}',
                                    ),
                                    icon: const Icon(Icons.bolt, size: 16),
                                    label: const Text('Targeted Practice'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // 4. Attempt History
                  const Text(
                    'Attempt History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (_attempts.isEmpty)
                    const Text(
                      'No completed attempts yet.',
                      style: TextStyle(color: AppTheme.textMuted),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attempts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final att = _attempts[index];
                        return ListTile(
                          tileColor: Theme.of(context).cardTheme.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          title: Text(
                            att.examTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${att.score}/${att.totalQuestions} • Duration: ${att.durationSeconds}s',
                          ),
                          trailing: Text(
                            '${att.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: att.percentage >= 60
                                  ? AppTheme.successGreen
                                  : AppTheme.warningOrange,
                            ),
                          ),
                          onTap: () => context.push('/results/${att.id}'),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
