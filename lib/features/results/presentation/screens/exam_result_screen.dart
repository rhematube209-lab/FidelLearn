import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../question_bank/domain/models/question_models.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  final String attemptId;
  final Exam? passedExam;
  final ExamAttempt? passedAttempt;

  const ExamResultScreen({
    super.key,
    required this.attemptId,
    this.passedExam,
    this.passedAttempt,
  });

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  ExamAttempt? _attempt;
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResultData();
  }

  Future<void> _loadResultData() async {
    if (widget.passedAttempt != null && widget.passedExam != null) {
      setState(() {
        _attempt = widget.passedAttempt;
        _questions = widget.passedExam!.questions;
        _isLoading = false;
      });
      return;
    }

    final examRepo = ref.read(examRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);
    final att = await examRepo.getAttemptById(widget.attemptId);

    if (att != null) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final qs = await contentRepo.getQuestions(
        grade: user?.grade ?? 12,
        subjectId: att.subjectId,
      );
      setState(() {
        _attempt = att;
        _questions = qs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.brand),
        ),
      );
    }

    if (_attempt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result Not Found')),
        body: const Center(child: Text('Could not load examination result.')),
      );
    }

    final isPass = _attempt!.percentage >= 50.0;
    final avgTimePerQ = _attempt!.totalQuestions > 0
        ? (_attempt!.durationSeconds / _attempt!.totalQuestions).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('National Exam Performance Report', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 20.0,
          vertical: 28.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Radial Score & Pass Indicator
                      Expanded(
                        flex: 45,
                        child: _buildGrandScoreCard(context, isPass),
                      ),
                      const SizedBox(width: 28),

                      // Right Column: Metric Breakdown & Action Deck
                      Expanded(
                        flex: 55,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPerformanceMetrics(avgTimePerQ),
                            const SizedBox(height: 24),
                            _buildActionDeck(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildGrandScoreCard(context, isPass),
                  const SizedBox(height: 20),
                  _buildPerformanceMetrics(avgTimePerQ),
                  const SizedBox(height: 24),
                  _buildActionDeck(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrandScoreCard(BuildContext context, bool isPass) {
    final percentage = _attempt!.percentage;
    final accentColor = isPass ? AppTheme.green : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPass
              ? [const Color(0xFF064E3B), AppTheme.darkSurfaceStrong]
              : [const Color(0xFF7C2D12), AppTheme.darkSurfaceStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accentColor.withOpacity(0.4)),
        boxShadow: AppTheme.cardShadowDark,
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkBg.withOpacity(0.7),
              border: Border.all(color: accentColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  const Text(
                    'SCORE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPass ? 'Outstanding Performance! 🎉' : 'Keep Practicing & Mastering! 📚',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${_attempt!.examTitle} • ESSLCE Standard',
            style: const TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '+${(_attempt!.score * 2)} Study Coins Earned',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(int avgTimePerQ) {
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
            'Examination Analytics Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Correct Items',
                  '${_attempt!.score} / ${_attempt!.totalQuestions}',
                  AppTheme.green,
                  Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Mistakes',
                  '${_attempt!.totalQuestions - _attempt!.score}',
                  AppTheme.danger,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Duration',
                  '${_attempt!.durationSeconds}s',
                  AppTheme.brand,
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Pace / Question',
                  '${avgTimePerQ}s',
                  AppTheme.accent,
                  Icons.speed_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionDeck(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            context.push('/solution_review', extra: {
              'questions': _questions,
              'attempt': _attempt!,
            });
          },
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('Review Step-by-Step Solutions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandStrong,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/exam_ghost/${_attempt!.examId}'),
          icon: const Icon(Icons.flash_on, color: AppTheme.accent),
          label: const Text('Race Personal-Best Exam Ghost'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Student Dashboard'),
        ),
      ],
    );
  }
}
