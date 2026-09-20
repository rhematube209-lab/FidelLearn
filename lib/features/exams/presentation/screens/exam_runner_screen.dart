import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_option_card.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../question_bank/presentation/widgets/question_diagram_viewer.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';

class ExamRunnerScreen extends ConsumerStatefulWidget {
  final Exam exam;
  final ExamAttempt initialAttempt;
  final bool showInstantFeedback;

  const ExamRunnerScreen({
    super.key,
    required this.exam,
    required this.initialAttempt,
    this.showInstantFeedback = false,
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
  bool _isAutoSaving = false;
  String _paletteFilter = 'all';

  @override
  void initState() {
    super.initState();
    _attempt = widget.initialAttempt;
    _remainingSeconds =
        widget.exam.isTimed ? widget.exam.timeLimitMinutes * 60 : 0;
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
      // 💾 Periodic 15-second Auto-Save Crash Resilience
      if (_elapsedSeconds % 15 == 0) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (_isAutoSaving || _isSubmitting) return;
    setState(() => _isAutoSaving = true);
    try {
      final examRepo = ref.read(examRepositoryProvider);
      await examRepo.saveActiveAttempt(_attempt);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isAutoSaving = false);
    }
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

    // Immediate persistence for instant feedback practice or mistake retry
    if (widget.showInstantFeedback ||
        widget.exam.examType == ExamType.mistakeRetry) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final userId = user?.id ?? 'guest_student';
      final selectedChoice = currentQ.choices.firstWhere(
        (c) => c.id == choiceId,
        orElse: () => currentQ.choices.first,
      );
      final isCorrect = currentQ.isScorable && selectedChoice.isCorrect;
      if (currentQ.isScorable) {
        try {
          final outcomeService = ref.read(mistakeOutcomeServiceProvider);
          await outcomeService.processQuestionOutcome(
            userId: userId,
            questionId: currentQ.id,
            subjectId: currentQ.subjectId,
            unitId: currentQ.unitId,
            topicId: currentQ.topicId,
            attemptId: _attempt.id,
            selectedChoiceId: choiceId,
            isCorrect: isCorrect,
            sessionType: widget.exam.examType,
          );
        } catch (_) {}
      }
    }
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
    final answeredCount = _attempt.responses.values
        .where((r) => r.selectedChoiceId != null)
        .length;
    final flaggedCount =
        _attempt.responses.values.where((r) => r.isFlagged).length;
    final unansweredCount = widget.exam.totalQuestions - answeredCount;

    int firstUnansweredIndex = -1;
    for (int i = 0; i < widget.exam.questions.length; i++) {
      final qId = widget.exam.questions[i].id;
      final resp = _attempt.responses[qId];
      if (resp == null || resp.selectedChoiceId == null) {
        firstUnansweredIndex = i;
        break;
      }
    }

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: AppTheme.brand),
            SizedBox(width: 8),
            Text('Submit Examination?',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please review your answer summary for ${widget.exam.title}:',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDialogStatCard(
                    'Answered',
                    '$answeredCount',
                    AppTheme.green,
                    Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDialogStatCard(
                    'Flagged',
                    '$flaggedCount',
                    AppTheme.accent,
                    Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDialogStatCard(
                    'Unanswered',
                    '$unansweredCount',
                    unansweredCount > 0
                        ? AppTheme.danger
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkMuted
                            : AppTheme.lightMuted),
                    Icons.help_outline_rounded,
                  ),
                ),
              ],
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border:
                      Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unansweredCount questions are unanswered and will be scored as 0.',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Once submitted, your final score, readiness analytics, and step-by-step solutions will be generated.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkMuted
                    : AppTheme.lightMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (unansweredCount > 0 && firstUnansweredIndex != -1)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx, false);
                setState(() => _currentIndex = firstUnansweredIndex);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: const Text('Review Unanswered'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Working'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandStrong,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Final'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      await _performSubmission();
    }
  }

  Widget _buildDialogStatCard(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

      // Process question outcomes (automatic mistake capture & mastery updates)
      final user = ref.read(currentUserProvider).valueOrNull;
      final userId = user?.id ?? 'guest_student';
      final outcomeService = ref.read(mistakeOutcomeServiceProvider);
      final qMap = {for (final q in widget.exam.questions) q.id: q};

      for (final resp in finishedAttempt.responses.values) {
        if (resp.selectedChoiceId == null) continue;
        final q = qMap[resp.questionId];
        if (q == null || !q.isScorable) continue;

        try {
          await outcomeService.processQuestionOutcome(
            userId: userId,
            questionId: q.id,
            subjectId: q.subjectId,
            unitId: q.unitId,
            topicId: q.topicId,
            attemptId: finishedAttempt.id,
            selectedChoiceId: resp.selectedChoiceId,
            isCorrect: resp.isCorrect,
            sessionType: widget.exam.examType,
          );
        } catch (_) {}
      }

      // Award Study Coins for completed exam
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

  Future<void> _handleExitOrPause() async {
    await _performAutoSave();
    if (!mounted) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline_rounded,
                color: AppTheme.brandStrong, size: 24),
            SizedBox(width: 8),
            Text('Pause & Exit Exam?'),
          ],
        ),
        content: const Text(
          'Your progress has been auto-saved to offline storage. You can resume this attempt anytime from your subject dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Working'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Now'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  Widget _buildPaletteGrid(bool isDark, {bool isDismissible = false}) {
    // Filter questions based on selected tab
    final eligibleIndices = <int>[];
    for (int i = 0; i < widget.exam.questions.length; i++) {
      final q = widget.exam.questions[i];
      final resp = _attempt.responses[q.id];
      final isAnswered = resp != null && resp.selectedChoiceId != null;
      final isFlagged = resp?.isFlagged == true;

      if (_paletteFilter == 'answered' && !isAnswered) continue;
      if (_paletteFilter == 'flagged' && !isFlagged) continue;
      if (_paletteFilter == 'unanswered' && isAnswered) continue;
      eligibleIndices.add(i);
    }

    if (eligibleIndices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'No $_paletteFilter questions',
            style: const TextStyle(color: AppTheme.darkMuted, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: eligibleIndices.length,
      itemBuilder: (context, gridIdx) {
        final index = eligibleIndices[gridIdx];
        final q = widget.exam.questions[index];
        final resp = _attempt.responses[q.id];
        final isCurrent = index == _currentIndex;
        final isAnswered = resp != null && resp.selectedChoiceId != null;
        final isFlagged = resp?.isFlagged == true;

        Color bgColor =
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        Color borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        Color textColor =
            isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft;

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
              if (isDismissible && Navigator.of(context).canPop()) {
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

  Widget _buildPaletteFilterTabs(
      {void Function(void Function())? updateState}) {
    final answeredCount = _attempt.responses.values
        .where((r) => r.selectedChoiceId != null)
        .length;
    final flaggedCount =
        _attempt.responses.values.where((r) => r.isFlagged).length;
    final unansweredCount = widget.exam.totalQuestions - answeredCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPaletteTab(
              'all', 'All (${widget.exam.totalQuestions})', updateState),
          const SizedBox(width: 6),
          _buildPaletteTab(
              'answered', 'Answered ($answeredCount)', updateState),
          const SizedBox(width: 6),
          _buildPaletteTab('flagged', 'Flagged ($flaggedCount)', updateState),
          const SizedBox(width: 6),
          _buildPaletteTab(
              'unanswered', 'Unanswered ($unansweredCount)', updateState),
        ],
      ),
    );
  }

  Widget _buildPaletteTab(String key, String label,
      [void Function(void Function())? updateState]) {
    final isSelected = _paletteFilter == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _paletteFilter = key);
          updateState?.call(() {});
        }
      },
      selectedColor: AppTheme.brand.withValues(alpha: 0.2),
    );
  }

  Widget _buildQuestionPaletteDrawer(bool isDark) {
    final answeredCount = _attempt.responses.values
        .where((r) => r.selectedChoiceId != null)
        .length;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Question Palette',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$answeredCount of ${widget.exam.totalQuestions} Answered',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.darkMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildPaletteFilterTabs(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaletteGrid(isDark, isDismissible: true),
                    const SizedBox(height: 16),
                    _buildPaletteLegend(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmAndSubmit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandStrong,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Finish Exam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionJumpPicker(bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final answeredCount = _attempt.responses.values
                .where((r) => r.selectedChoiceId != null)
                .length;
            final flaggedCount =
                _attempt.responses.values.where((r) => r.isFlagged).length;
            final unansweredCount = widget.exam.totalQuestions - answeredCount;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Question Navigator',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$answeredCount Answered • $flaggedCount Flagged • $unansweredCount Remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.darkMuted
                                        : AppTheme.lightMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildPaletteFilterTabs(
                        updateState: setModalState,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPaletteGrid(isDark, isDismissible: true),
                            const SizedBox(height: 16),
                            _buildPaletteLegend(isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

  void _showReferenceConstantsModal(bool isDark) {
    const constants = [
      ('g', '10 m/s²', 'Acceleration due to gravity'),
      ('M', '6 × 10²⁴ kg', 'Mass of the Earth'),
      ('e', '1.6 × 10⁻¹⁹ C', 'Charge of electron'),
      ('G', '6.67 × 10⁻¹¹ N·m²/kg²', 'Gravitational constant'),
      ('ρ', '1000 kg/m³', 'Density of water'),
      ('R', '8.314 J/mol·K', 'Molar gas constant'),
      ('ε₀', '8.85 × 10⁻¹² F/m', 'Permittivity of vacuum'),
      ('μ₀', '4π × 10⁻⁷ T·m/A', 'Magnetic permeability'),
      ('k', '9 × 10⁹ N·m²/C²', 'Coulomb’s constant'),
      ('c', '4200 J/kg·K (Water)', 'Specific heat of water'),
      ('c', '420 J/kg·K (Copper)', 'Specific heat of copper'),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.functions_rounded,
                              color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Official Reference Constants',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(builder: (cCtx, constraints) {
                          final isTwoCol = constraints.maxWidth >= 380;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: constants.map((c) {
                              final w = isTwoCol
                                  ? (constraints.maxWidth - 8) / 2
                                  : constraints.maxWidth;
                              return Container(
                                width: w,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        c.$3,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark
                                              ? AppTheme.darkMuted
                                              : const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${c.$1} = ',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          TextSpan(
                                            text: c.$2,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.calculate_outlined,
                                  size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Trigonometry: sin 30° = cos 60° = 0.5 • sin 60° = cos 30° = 0.87 • sin 0° = cos 90° = 0 • sin 90° = cos 0° = 1',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerBadge(bool isDark) {
    final timerText = widget.exam.isTimed
        ? '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
        : '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x336366F1) : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x666366F1) : const Color(0xFFC4B5FD),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 15,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 5),
          Text(
            timerText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = widget.exam.questions[_currentIndex];
    final currentResp = _attempt.responses[currentQ.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleExitOrPause();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        endDrawer: _buildQuestionPaletteDrawer(isDark),
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 175,
          leading: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Pause & exit exam',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _handleExitOrPause,
                ),
                const SizedBox(width: 4),
                _buildTimerBadge(isDark),
              ],
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            if (widget.exam.title.toLowerCase().contains('phys') ||
                (widget.exam.subjectId?.toLowerCase().contains('phys') ??
                    false))
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(
                  Icons.functions_rounded,
                  size: 21,
                  color: Color(0xFF2563EB),
                ),
                tooltip: 'Reference Constants',
                onPressed: () => _showReferenceConstantsModal(isDark),
              ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                currentResp?.isFlagged == true
                    ? Icons.flag_rounded
                    : Icons.outlined_flag,
                size: 22,
                color: currentResp?.isFlagged == true
                    ? AppTheme.accent
                    : (isDark
                        ? AppTheme.darkTextSoft
                        : const Color(0xFF475569)),
              ),
              tooltip: 'Flag question for review',
              onPressed: _handleToggleFlag,
            ),
            Builder(
              builder: (ctx) => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 21,
                  color:
                      isDark ? AppTheme.darkTextSoft : const Color(0xFF1E293B),
                ),
                tooltip: 'Question palette drawer',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ElevatedButton(
                onPressed: _confirmAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                child: const Text('Finish Exam'),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.5),
            child: LinearProgressIndicator(
              value: widget.exam.totalQuestions > 0
                  ? (_currentIndex + 1) / widget.exam.totalQuestions
                  : 0.0,
              backgroundColor:
                  isDark ? const Color(0x33334155) : const Color(0xFFEEF2F6),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 2.5,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Fixed Palette on Desktop
                          Container(
                            width: 280,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightSurface,
                              border: Border(
                                right: BorderSide(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.lightBorder,
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
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPaletteGrid(isDark,
                                      isDismissible: false),
                                  const SizedBox(height: 20),
                                  _buildPaletteLegend(isDark),
                                ],
                              ),
                            ),
                          ),

                          // Center Focused Question Runner
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 28),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 820),
                                  child: _buildQuestionContent(
                                      currentQ, currentResp, isDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(18.0),
                        child: _buildQuestionContent(
                            currentQ, currentResp, isDark),
                      ),
              ),

              // Bottom Navigation Footer with Working Question Number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorder
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Previous Button
                    Flexible(
                      child: OutlinedButton.icon(
                        onPressed: _currentIndex > 0
                            ? () => setState(() => _currentIndex--)
                            : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                        label: Text(
                          screenWidth < 360 ? 'Prev' : 'Previous',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: isDark
                              ? AppTheme.darkTextSoft
                              : const Color(0xFF64748B),
                          disabledForegroundColor: isDark
                              ? AppTheme.darkMuted
                              : const Color(0xFFCBD5E1),
                          side: BorderSide(
                            color: _currentIndex > 0
                                ? (isDark
                                    ? AppTheme.darkBorder
                                    : const Color(0xFFE2E8F0))
                                : (isDark
                                    ? AppTheme.darkBorderSubtle
                                    : const Color(0xFFF1F5F9)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 2. Centered Question Number (e.g. 1/100) - Tappable & Working!
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showQuestionJumpPicker(isDark),
                        borderRadius: BorderRadius.circular(8),
                        child: Tooltip(
                          message: 'Tap to jump to any question',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Text(
                              '${_currentIndex + 1}/${widget.exam.totalQuestions}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkText
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 3. Next Question / Finish Exam Button
                    Flexible(
                      child: _currentIndex < widget.exam.questions.length - 1
                          ? ElevatedButton.icon(
                              onPressed: () => setState(() => _currentIndex++),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 15),
                              label: Text(
                                screenWidth < 360 ? 'Next' : 'Next Question',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _confirmAndSubmit,
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 15),
                              label: const Text(
                                'Finish Exam',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        // Question Statement Card (Matching the Reference Design)
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isDark
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x336366F1)
                          : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DIFFICULTY: ${currentQ.difficulty.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF4F46E5),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x2664748B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ESSLCE ${currentQ.examYear ?? 2013} E.C.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : const Color(0xFF64748B),
                      ),
                    ),
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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (currentQ.questionTextAm != null &&
                  currentQ.questionTextAm!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  currentQ.questionTextAm!,
                  style: TextStyle(
                    fontSize: 14.5,
                    color:
                        isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Official Document Image / Vector Diagram (if present)
        QuestionDiagramViewer(question: currentQ),
        if ((currentQ.diagramAsset != null &&
                currentQ.diagramAsset!.isNotEmpty) ||
            currentQ.vectorDiagram != null)
          const SizedBox(height: 16),

        // Choices
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Select the single best answer:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: isDark ? AppTheme.darkTextSoft : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 12),

        ...currentQ.choices.map((choice) {
          final isSelected = currentResp?.selectedChoiceId == choice.id;
          FidelOptionState state = FidelOptionState.unselected;

          if (widget.showInstantFeedback &&
              currentResp?.selectedChoiceId != null) {
            if (choice.isCorrect) {
              state = FidelOptionState.correct;
            } else if (isSelected) {
              state = FidelOptionState.incorrect;
            }
          } else if (isSelected) {
            state = FidelOptionState.selected;
          }

          return FidelOptionCard(
            label: choice.label,
            textEn: choice.textEn,
            textAm: choice.textAm,
            state: state,
            onTap: () => _handleSelectChoice(choice.id),
          );
        }),

        // ⚡ Immediate Feedback Solution Card
        if (widget.showInstantFeedback &&
            currentResp?.selectedChoiceId != null) ...[
          const SizedBox(height: 18),
          _buildInstantExplanationCard(currentQ, currentResp!, isDark),
        ],
      ],
    );
  }

  Widget _buildInstantExplanationCard(
    Question question,
    UserResponse response,
    bool isDark,
  ) {
    final isCorrect = response.isCorrect;
    final correctLabels = question.choices
        .where((c) => c.isCorrect)
        .map((c) => c.label)
        .join(' / ');
    final isDefective = !question.isScorable;

    return Container(
      decoration: BoxDecoration(
        color: isDefective
            ? (isDark ? const Color(0x1FF59E0B) : const Color(0xFFFFFBEB))
            : (isCorrect
                ? (isDark ? const Color(0x1F10B981) : const Color(0xFFF0FDF4))
                : (isDark ? const Color(0x1FEF4444) : const Color(0xFFFEF2F2))),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefective
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (isCorrect
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : const Color(0xFFEF4444).withValues(alpha: 0.5)),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDefective
                    ? Icons.info_outline_rounded
                    : (isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded),
                color: isDefective
                    ? const Color(0xFFD97706)
                    : (isCorrect
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626)),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isDefective
                    ? 'Source Item Notice'
                    : (isCorrect ? 'Correct! Well done.' : 'Incorrect Choice'),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDefective
                      ? const Color(0xFFD97706)
                      : (isCorrect
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626)),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isDefective
                          ? const Color(0xFFD97706)
                          : (isCorrect
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626)))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDefective
                      ? (correctLabels.isNotEmpty
                          ? 'Valid: $correctLabels'
                          : 'No valid option')
                      : 'Correct: Choice $correctLabels',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDefective
                        ? const Color(0xFFD97706)
                        : (isCorrect
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
          if (question.reviewNote != null &&
              question.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0x33B45309) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0x55F59E0B)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined,
                      size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Review Note: ${question.reviewNote}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            question.explanation.solutionTextEn,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          if (question.explanation.keyConcept != null &&
              question.explanation.keyConcept!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: AppTheme.accentGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Key Concept: ${question.explanation.keyConcept}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (question.explanation.commonPitfall != null &&
              question.explanation.commonPitfall!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Common Pitfall: ${question.explanation.commonPitfall}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
