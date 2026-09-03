import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../../../core/widgets/fidel_option_card.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../question_bank/presentation/widgets/svg_diagram_viewer.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';

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
        backgroundColor: AppTheme.danger,
        content: Text('Time has expired! Submitting your examination answers.'),
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
    final unansweredCount =
        widget.exam.totalQuestions - _attempt.responses.length;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Examination?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have answered ${_attempt.responses.length} of ${widget.exam.totalQuestions} questions.',
              style: const TextStyle(fontSize: 14),
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unansweredCount questions are unanswered!',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Once submitted, your final score, readiness analytics, and step-by-step solutions will be generated.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.darkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue Test'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandStrong),
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

    try {
      final finishedAttempt = ExamEngine.submitAttempt(
        currentAttempt: _attempt,
        questions: widget.exam.questions,
        totalDurationSeconds: _elapsedSeconds,
      );

      final examRepo = ref.read(examRepositoryProvider);
      await examRepo.saveCompletedAttempt(finishedAttempt);

      // Award Study Coins for completed exam
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        final earnedCoins = (finishedAttempt.score * 2).clamp(5, 50);
        ref.read(coinLedgerProvider.notifier).awardCoins(
          userId: user.id,
          amount: earnedCoins,
          reason: 'Completed exam: ${widget.exam.title}',
          idempotencyKey: 'exam_${finishedAttempt.id}',
          relatedEntityId: finishedAttempt.id,
        );
      }

      if (mounted) {
        context.go('/results/${finishedAttempt.id}', extra: {
          'exam': widget.exam,
          'attempt': finishedAttempt,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMobileQuestionPalette() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Question Palette',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_attempt.responses.length}/${widget.exam.totalQuestions} Answered',
                  style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaletteGrid(isDark),
            const SizedBox(height: 20),
            _buildPaletteLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: widget.exam.questions.length,
      itemBuilder: (context, index) {
        final q = widget.exam.questions[index];
        final resp = _attempt.responses[q.id];
        final isCurrent = index == _currentIndex;
        final isAnswered = resp != null && resp.selectedChoiceId != null;
        final isFlagged = resp?.isFlagged == true;

        Color bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        Color borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        Color textColor = isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft;

        if (isCurrent) {
          bgColor = AppTheme.brandStrong;
          borderColor = AppTheme.brandStrong;
          textColor = Colors.white;
        } else if (isFlagged) {
          bgColor = isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7);
          borderColor = AppTheme.accent;
          textColor = AppTheme.accentDark;
        } else if (isAnswered) {
          bgColor = isDark ? const Color(0x3310B981) : const Color(0xFFD1FAE5);
          borderColor = AppTheme.green;
          textColor = isDark ? const Color(0xFF6EE7B7) : AppTheme.greenDark;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _currentIndex = index);
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: borderColor,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaletteLegend(bool isDark) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppTheme.green, label: 'Answered'),
        _LegendItem(color: AppTheme.accent, label: 'Flagged'),
        _LegendItem(color: AppTheme.brandStrong, label: 'Current'),
        _LegendItem(color: AppTheme.darkMuted, label: 'Unanswered'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = widget.exam.questions[_currentIndex];
    final currentResp = _attempt.responses[currentQ.id];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.exam.title} • Q ${_currentIndex + 1}/${widget.exam.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          // Urgency Color-Shifting Timer HUD
          if (widget.exam.isTimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 120
                    ? AppTheme.danger.withValues(alpha: 0.15)
                    : (_remainingSeconds < 300
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.brandStrong.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: _remainingSeconds < 120
                      ? AppTheme.danger
                      : (_remainingSeconds < 300 ? AppTheme.accent : AppTheme.brand),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: _remainingSeconds < 120
                        ? AppTheme.danger
                        : (_remainingSeconds < 300 ? AppTheme.accent : AppTheme.brand),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: _remainingSeconds < 120
                          ? AppTheme.danger
                          : (_remainingSeconds < 300 ? AppTheme.accentDark : AppTheme.brand),
                    ),
                  ),
                ],
              ),
            ),

          IconButton(
            icon: Icon(
              currentResp?.isFlagged == true ? Icons.flag_rounded : Icons.flag_outlined,
              color: currentResp?.isFlagged == true ? AppTheme.accent : null,
            ),
            tooltip: 'Flag question for review',
            onPressed: _handleToggleFlag,
          ),

          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Question palette',
              onPressed: _showMobileQuestionPalette,
            ),

          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: ElevatedButton(
              onPressed: _confirmAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandStrong,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Finish Exam'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Smooth Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.exam.totalQuestions,
              backgroundColor: isDark ? const Color(0x33334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brand),
              minHeight: 4,
            ),

            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Fixed Palette on Desktop
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            border: Border(
                              right: BorderSide(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Exam Question Grid',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 14),
                                _buildPaletteGrid(isDark),
                                const SizedBox(height: 20),
                                _buildPaletteLegend(isDark),
                              ],
                            ),
                          ),
                        ),

                        // Center Focused Question Runner
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 820),
                                child: _buildQuestionContent(currentQ, currentResp, isDark),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18.0),
                      child: _buildQuestionContent(currentQ, currentResp, isDark),
                    ),
            ),

            // Bottom Sticky Navigation Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous'),
                  ),
                  Row(
                    children: [
                      Text(
                        'Answered: ${_attempt.responses.length}/${widget.exam.totalQuestions}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      if (_currentIndex < widget.exam.questions.length - 1)
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _currentIndex++),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Next Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandStrong,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _confirmAndSubmit,
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Submit Final Exam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(
    Question currentQ,
    UserResponse? currentResp,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Statement Card
        FidelCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FidelBadge(
                    text: 'DIFFICULTY: ${currentQ.difficulty.toUpperCase()}',
                    variant: currentQ.difficulty == 'hard'
                        ? FidelBadgeVariant.danger
                        : (currentQ.difficulty == 'medium'
                            ? FidelBadgeVariant.warning
                            : FidelBadgeVariant.primary),
                    isSmall: true,
                  ),
                  if (currentQ.examYear != null)
                    FidelBadge(
                      text: 'ESSLCE ${currentQ.examYear} E.C.',
                      variant: FidelBadgeVariant.neutral,
                      isSmall: true,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentQ.questionTextEn,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              if (currentQ.questionTextAm != null && currentQ.questionTextAm!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  currentQ.questionTextAm!,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Vector Diagram (if present)
        if (currentQ.vectorDiagram != null) ...[
          SvgDiagramViewer(diagram: currentQ.vectorDiagram!),
          const SizedBox(height: 20),
        ],

        // Choices
        Text(
          'Select the single best answer:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
          ),
        ),
        const SizedBox(height: 12),

        ...currentQ.choices.map((choice) {
          final isSelected = currentResp?.selectedChoiceId == choice.id;
          return FidelOptionCard(
            label: choice.label,
            textEn: choice.textEn,
            textAm: choice.textAm,
            state: isSelected ? FidelOptionState.selected : FidelOptionState.unselected,
            onTap: () => _handleSelectChoice(choice.id),
          );
        }),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
        ),
      ],
    );
  }
}
