import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';
import '../../../question_bank/presentation/widgets/svg_diagram_viewer.dart';

class ExamRunnerScreen extends ConsumerStatefulWidget {
  final Exam exam;
  final ExamAttempt initialAttempt;

  const ExamRunnerScreen({
    super.key,
    required this.exam,
    required this.initialAttempt,
  });

  @override
  ConsumerState<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends ConsumerState<ExamRunnerScreen> {
  late ExamAttempt _attempt;
  int _currentIndex = 0;
  Timer? _timer;
  late int _remainingSeconds;
  int _elapsedSeconds = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _attempt = widget.initialAttempt;
    _remainingSeconds = widget.exam.isTimed
        ? widget.exam.timeLimitMinutes * 60
        : 0;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (widget.exam.isTimed) {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _autoSubmitOnTimeExpired();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _autoSubmitOnTimeExpired() async {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.warningOrange,
        content: Text('Time has expired! Automatically submitting your exam.'),
      ),
    );
    await _performSubmission();
  }

  Future<void> _handleSelectChoice(String choiceId) async {
    final currentQ = widget.exam.questions[_currentIndex];
    final updated = ExamEngine.answerQuestion(
      currentAttempt: _attempt,
      question: currentQ,
      choiceId: choiceId,
      timeSpentDeltaSeconds: 1,
    );

    setState(() => _attempt = updated);

    // Auto-save to local persistence
    final examRepo = ref.read(examRepositoryProvider);
    await examRepo.saveActiveAttempt(_attempt);
  }

  Future<void> _handleToggleFlag() async {
    final currentQ = widget.exam.questions[_currentIndex];
    final updated = ExamEngine.toggleFlag(
      currentAttempt: _attempt,
      questionId: currentQ.id,
    );

    setState(() => _attempt = updated);
    final examRepo = ref.read(examRepositoryProvider);
    await examRepo.saveActiveAttempt(_attempt);
  }

  Future<void> _confirmAndSubmit() async {
    int answeredCount = 0;
    int flaggedCount = 0;

    for (final q in widget.exam.questions) {
      final resp = _attempt.responses[q.id];
      if (resp?.selectedChoiceId != null) answeredCount++;
      if (resp?.isFlagged == true) flaggedCount++;
    }

    final unattempted = widget.exam.totalQuestions - answeredCount;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Examination?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Answered: $answeredCount of ${widget.exam.totalQuestions}'),
            if (unattempted > 0)
              Text(
                '• Unanswered: $unattempted',
                style: const TextStyle(
                  color: AppTheme.warningOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (flaggedCount > 0)
              Text(
                '• Flagged for review: $flaggedCount',
                style: const TextStyle(color: AppTheme.accentGoldDark),
              ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to finish and see your score and explanations?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Working'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      await _performSubmission();
    }
  }

  Future<void> _performSubmission() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final finalAttempt = ExamEngine.submitAttempt(
      currentAttempt: _attempt,
      questions: widget.exam.questions,
      totalDurationSeconds: _elapsedSeconds,
    );

    final examRepo = ref.read(examRepositoryProvider);
    final mistakeRepo = ref.read(mistakeRepositoryProvider);
    final user = ref.read(currentUserProvider).valueOrNull;

    // 1. Save completed attempt
    await examRepo.saveCompletedAttempt(finalAttempt);

    // 2. Automatically record mistakes for incorrect questions into Mistake Notebook
    if (user != null) {
      for (final q in widget.exam.questions) {
        final resp = finalAttempt.responses[q.id];
        if (resp != null && !resp.isCorrect) {
          await mistakeRepo.recordMistake(
            userId: user.id,
            questionId: q.id,
            subjectId: q.subjectId,
          );
        } else if (resp != null && resp.isCorrect) {
          // If was a mistake before, mark mastered
          await mistakeRepo.markMastered(userId: user.id, questionId: q.id);
        }
      }
    }

    if (mounted) {
      context.go(
        '/results/${finalAttempt.id}',
        extra: {'exam': widget.exam, 'attempt': finalAttempt},
      );
    }
  }

  void _showQuestionPalette() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Question Palette',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(widget.exam.questions.length, (idx) {
                  final q = widget.exam.questions[idx];
                  final resp = _attempt.responses[q.id];
                  final isAnswered = resp?.selectedChoiceId != null;
                  final isFlagged = resp?.isFlagged == true;
                  final isCurrent = idx == _currentIndex;

                  Color bg = Colors.white;
                  Color border = const Color(0xFFCBD5E1);
                  Color text = AppTheme.textDark;

                  if (isFlagged) {
                    bg = AppTheme.accentGold.withOpacity(0.15);
                    border = AppTheme.accentGold;
                    text = AppTheme.accentGoldDark;
                  } else if (isAnswered) {
                    bg = AppTheme.primaryGreen.withOpacity(0.15);
                    border = AppTheme.primaryGreen;
                    text = AppTheme.primaryGreen;
                  }

                  if (isCurrent) {
                    border = Colors.black;
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _currentIndex = idx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: border,
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: text,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegend(AppTheme.primaryGreen, 'Answered'),
                  _buildLegend(AppTheme.accentGold, 'Flagged'),
                  _buildLegend(const Color(0xFFCBD5E1), 'Unanswered'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = widget.exam.questions[_currentIndex];
    final currentResp = _attempt.responses[currentQ.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${_currentIndex + 1} of ${widget.exam.totalQuestions}',
        ),
        actions: [
          // Timer
          if (widget.exam.isTimed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 120
                    ? AppTheme.errorRed.withOpacity(0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _remainingSeconds < 120
                        ? AppTheme.errorRed
                        : AppTheme.textDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _remainingSeconds < 120
                          ? AppTheme.errorRed
                          : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              currentResp?.isFlagged == true ? Icons.flag : Icons.flag_outlined,
              color: currentResp?.isFlagged == true
                  ? AppTheme.accentGold
                  : null,
            ),
            tooltip: 'Flag for review',
            onPressed: _handleToggleFlag,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Question Palette',
            onPressed: _showQuestionPalette,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.exam.totalQuestions,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question text
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Difficulty: ${currentQ.difficulty.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                              if (currentQ.examYear != null)
                                Text(
                                  '${currentQ.examYear} E.C.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            currentQ.questionTextEn,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          if (currentQ.questionTextAm != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              currentQ.questionTextAm!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (currentQ.vectorDiagram != null) ...[
                      SvgDiagramViewer(diagram: currentQ.vectorDiagram!),
                      const SizedBox(height: 20),
                    ],

                    // Answer Choices
                    const Text(
                      'Select Your Answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...currentQ.choices.map((choice) {
                      final isSelected =
                          currentResp?.selectedChoiceId == choice.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () => _handleSelectChoice(choice.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFFCBD5E1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      choice.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    choice.textEn,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                    child: const Text('Previous'),
                  ),
                  if (_currentIndex < widget.exam.questions.length - 1)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex++),
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _confirmAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGoldDark,
                      ),
                      child: const Text('Submit Exam'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
