import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_button.dart';
import '../../../../core/widgets/fidel_card.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
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
    final isDistinction = _attempt!.percentage >= 80.0;
    final avgTimePerQ = _attempt!.totalQuestions > 0
        ? (_attempt!.durationSeconds / _attempt!.totalQuestions).round()
        : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Examination Performance Report',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close report',
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
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Grand Score Hero
                      Expanded(
                        flex: 48,
                        child: _buildGrandScoreCard(context, isPass, isDistinction, isDark),
                      ),
                      const SizedBox(width: 24),

                      // Right Column: Metric Breakdown & Action Deck
                      Expanded(
                        flex: 52,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPerformanceMetrics(avgTimePerQ, isDark),
                            const SizedBox(height: 20),
                            _buildActionDeck(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildGrandScoreCard(context, isPass, isDistinction, isDark),
                  const SizedBox(height: 20),
                  _buildPerformanceMetrics(avgTimePerQ, isDark),
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

  Widget _buildGrandScoreCard(
    BuildContext context,
    bool isPass,
    bool isDistinction,
    bool isDark,
  ) {
    final percentage = _attempt!.percentage;
    final scoreColor = isDistinction
        ? AppTheme.green
        : (isPass ? AppTheme.accentDark : AppTheme.danger);

    return FidelCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: isDark
          ? (isPass ? const Color(0xFF0F2420) : const Color(0xFF241515))
          : (isPass ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
      borderColor: scoreColor.withValues(alpha: 0.35),
      child: Column(
        children: [
          // Circular Score Gauge
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.darkSurface : Colors.white,
              border: Border.all(color: scoreColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.15),
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
                      color: scoreColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'FINAL SCORE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Headline Message
          Text(
            isDistinction
                ? 'Outstanding Mastery! 🏆'
                : (isPass ? 'Good Job, Exam Passed! 🎉' : 'Keep Practicing & Mastering! 📚'),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${_attempt!.examTitle} • Grade ${_attempt!.subjectId}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Study Coins Reward Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x26F59E0B) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '+${(_attempt!.score * 2).clamp(5, 50)} Study Coins Earned',
                  style: const TextStyle(
                    color: AppTheme.accentDark,
                    fontWeight: FontWeight.w700,
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

  Widget _buildPerformanceMetrics(int avgTimePerQ, bool isDark) {
    return FidelCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Correct Answers',
                  '${_attempt!.score} / ${_attempt!.totalQuestions}',
                  AppTheme.green,
                  Icons.check_circle_outline_rounded,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Incorrect Items',
                  '${_attempt!.totalQuestions - _attempt!.score}',
                  AppTheme.danger,
                  Icons.cancel_outlined,
                  isDark,
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
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Pace per Question',
                  '${avgTimePerQ}s',
                  AppTheme.accent,
                  Icons.speed_rounded,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDeck(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FidelButton(
          label: 'Review Step-by-Step Solutions',
          icon: Icons.menu_book_rounded,
          onPressed: () {
            context.push('/solutions', extra: {
              'questions': _questions,
              'attempt': _attempt!,
            });
          },
          isFullWidth: true,
          height: 48,
        ),
        const SizedBox(height: 12),
        FidelButton(
          label: 'Race Personal-Best Exam Ghost',
          icon: Icons.flash_on_rounded,
          variant: FidelButtonVariant.outline,
          onPressed: () => context.push('/exam_ghost/${_attempt!.examId}'),
          isFullWidth: true,
          height: 48,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Return to Student Dashboard'),
        ),
      ],
    );
  }
}
