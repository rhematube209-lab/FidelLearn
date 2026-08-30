import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
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
        backgroundColor: AppTheme.accent,
        content: Text('Time has expired! Submitting examination.'),
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
        title: const Text('Submit Examination?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have answered ${_attempt.responses.length} of ${widget.exam.totalQuestions} questions.'),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ $unansweredCount questions are still unanswered!',
                style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Once submitted, your final score and step-by-step solutions will be generated.'),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Question Palette',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaletteGrid(),
            const SizedBox(height: 20),
            _buildPaletteLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: widget.exam.questions.length,
      itemBuilder: (context, index) {
        final q = widget.exam.questions[index];
        final resp = _attempt.responses[q.id];
        final isCurrent = index == _currentIndex;
        final isAnswered = resp != null && resp.selectedChoiceId != null;
        final isFlagged = resp?.isFlagged == true;

        Color bgColor = AppTheme.darkSurfaceStrong;
        Color borderColor = AppTheme.darkBorder;
        Color textColor = AppTheme.darkTextSoft;

        if (isCurrent) {
          bgColor = AppTheme.brandStrong;
          borderColor = AppTheme.brand;
          textColor = Colors.white;
        } else if (isFlagged) {
          bgColor = AppTheme.accent.withOpacity(0.2);
          borderColor = AppTheme.accent;
          textColor = AppTheme.accent;
        } else if (isAnswered) {
          bgColor = AppTheme.green.withOpacity(0.2);
          borderColor = AppTheme.green;
          textColor = AppTheme.green;
        }

        return InkWell(
          onTap: () {
            setState(() => _currentIndex = index);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaletteLegend() {
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
    final currentQ = widget.exam.questions[_currentIndex];
    final currentResp = _attempt.responses[currentQ.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.exam.title} • Q ${_currentIndex + 1}/${widget.exam.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          // Timer HUD
          if (widget.exam.isTimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 120
                    ? AppTheme.danger.withOpacity(0.2)
                    : AppTheme.brandStrong.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _remainingSeconds < 120 ? AppTheme.danger : AppTheme.brand,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _remainingSeconds < 120 ? AppTheme.danger : AppTheme.brand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _remainingSeconds < 120 ? AppTheme.danger : AppTheme.brand,
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
            tooltip: 'Flag for review',
            onPressed: _handleToggleFlag,
          ),

          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Palette',
              onPressed: _showMobileQuestionPalette,
            ),

          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: ElevatedButton(
              onPressed: _confirmAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandStrong,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('Finish Exam'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.exam.totalQuestions,
              backgroundColor: const Color(0x1AFFFFFF),
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
                            color: Theme.of(context).cardTheme.color,
                            border: const Border(right: BorderSide(color: AppTheme.darkBorder)),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Exam Question Grid',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 14),
                                _buildPaletteGrid(),
                                const SizedBox(height: 20),
                                _buildPaletteLegend(),
                              ],
                            ),
                          ),
                        ),

                        // Center Question Cockpit
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 850),
                                child: _buildQuestionContent(currentQ, currentResp),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildQuestionContent(currentQ, currentResp),
                    ),
            ),

            // Bottom Navigation Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: const Border(top: BorderSide(color: AppTheme.darkBorder)),
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
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkMuted),
                      ),
                      const SizedBox(width: 16),
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
                            foregroundColor: Colors.black,
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

  Widget _buildQuestionContent(Question currentQ, UserResponse? currentResp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Statement Card
        Container(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DIFFICULTY: ${currentQ.difficulty.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                  if (currentQ.examYear != null)
                    Text(
                      'ESSLCE ${currentQ.examYear} E.C.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentQ.questionTextEn,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              if (currentQ.questionTextAm != null) ...[
                const SizedBox(height: 10),
                Text(
                  currentQ.questionTextAm!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.darkTextSoft,
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
        const Text(
          'Select Single Best Choice:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),

        ...currentQ.choices.map((choice) {
          final isSelected = currentResp?.selectedChoiceId == choice.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => _handleSelectChoice(choice.id),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.brandStrong.withOpacity(0.18)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppTheme.brand : AppTheme.darkBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppTheme.brandGlow : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.brandStrong : const Color(0x1AFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          choice.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        choice.textEn,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.darkText : AppTheme.darkTextSoft,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
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
