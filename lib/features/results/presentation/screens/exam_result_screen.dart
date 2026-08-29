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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        title: const Text('Examination Results'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Overall Score Hero Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPass
                      ? [AppTheme.primaryGreen, AppTheme.primaryGreenLight]
                      : [AppTheme.accentGoldDark, AppTheme.accentGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isPass ? AppTheme.primaryGreen : AppTheme.accentGold)
                            .withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _attempt!.examTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_attempt!.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_attempt!.score} of ${_attempt!.totalQuestions} Correct',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPass
                          ? '✨ Great Mastery!'
                          : '💪 Keep Practicing & Reviewing!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.check_circle,
                    label: 'Correct',
                    value: '${_attempt!.correctCount}',
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.cancel,
                    label: 'Incorrect',
                    value: '${_attempt!.incorrectCount}',
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.timer,
                    label: 'Avg Time/Q',
                    value: '${avgTimePerQ}s',
                    color: AppTheme.infoBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/solutions',
                  extra: {'questions': _questions, 'attempt': _attempt},
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Review Step-by-Step Solutions'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                context.push('/exam_ghost/${_attempt!.examId}');
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Challenge with Exam Ghost'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Return to Home Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
