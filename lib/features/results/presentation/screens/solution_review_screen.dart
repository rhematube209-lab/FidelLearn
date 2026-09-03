import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../../core/widgets/fidel_card.dart';
import '../../../../core/widgets/fidel_option_card.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../question_bank/domain/models/audio_explanation_models.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../question_bank/presentation/widgets/svg_diagram_viewer.dart';
import '../widgets/audio_player_card.dart';

class SolutionReviewScreen extends ConsumerStatefulWidget {
  final List<Question> questions;
  final ExamAttempt attempt;

  const SolutionReviewScreen({
    super.key,
    required this.questions,
    required this.attempt,
  });

  @override
  ConsumerState<SolutionReviewScreen> createState() =>
      _SolutionReviewScreenState();
}

class _SolutionReviewScreenState extends ConsumerState<SolutionReviewScreen> {
  int _currentIndex = 0;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _checkInitialBookmarks();
  }

  Future<void> _checkInitialBookmarks() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final bookmarkRepo = ref.read(bookmarkRepositoryProvider);

    for (final q in widget.questions) {
      final isBm = await bookmarkRepo.isBookmarked(
        userId: user.id,
        questionId: q.id,
      );
      if (isBm && mounted) {
        setState(() => _bookmarkedIds.add(q.id));
      }
    }
  }

  Future<void> _toggleBookmark(Question q) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final bookmarkRepo = ref.read(bookmarkRepositoryProvider);

    await bookmarkRepo.toggleBookmark(
      userId: user.id,
      questionId: q.id,
      subjectId: q.subjectId,
      topicId: q.topicId,
    );

    setState(() {
      if (_bookmarkedIds.contains(q.id)) {
        _bookmarkedIds.remove(q.id);
      } else {
        _bookmarkedIds.add(q.id);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            _bookmarkedIds.contains(q.id)
                ? 'Question saved to offline bookmarks!'
                : 'Bookmark removed.',
          ),
        ),
      );
    }
  }

  void _reportContent(Question q) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Question Issue', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Thank you for maintaining exam content quality. Our curriculum team will review this question and verify syllabus accuracy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solutions Review')),
        body: const Center(child: Text('No questions available for review.')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = widget.questions[_currentIndex];
    final resp = widget.attempt.responses[currentQ.id];
    final isCorrect = resp?.isCorrect ?? false;
    final isBookmarked = _bookmarkedIds.contains(currentQ.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Solution Review: Q ${_currentIndex + 1}/${widget.questions.length}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppTheme.accent : null,
            ),
            tooltip: 'Bookmark question',
            onPressed: () => _toggleBookmark(currentQ),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report issue',
            onPressed: () => _reportContent(currentQ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Question Navigator Drawer on Desktop
                        Container(
                          width: 290,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            border: Border(
                              right: BorderSide(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exam Questions',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: widget.questions.length,
                                  itemBuilder: (context, index) {
                                    final q = widget.questions[index];
                                    final r = widget.attempt.responses[q.id];
                                    final corr = r?.isCorrect ?? false;
                                    final isSelected = index == _currentIndex;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        child: InkWell(
                                          onTap: () => setState(() => _currentIndex = index),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isDark
                                                      ? AppTheme.brand.withValues(alpha: 0.16)
                                                      : AppTheme.brandSubtle)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                              border: Border.all(
                                                color: isSelected ? AppTheme.brand : Colors.transparent,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  corr ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                  color: corr ? AppTheme.green : AppTheme.danger,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Question ${index + 1}',
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    fontSize: 13,
                                                    color: isSelected
                                                        ? (isDark ? Colors.white : AppTheme.brandStrong)
                                                        : (isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center Solution Inspector
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 820),
                                child: _buildSolutionContent(currentQ, resp, isCorrect, isDark),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18.0),
                      child: _buildSolutionContent(currentQ, resp, isCorrect, isDark),
                    ),
            ),

            // Bottom Navigation Dock
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
                    label: const Text('Previous Item'),
                  ),
                  if (_currentIndex < widget.questions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex++),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Next Solution'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandStrong,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.dashboard_rounded, size: 16),
                      label: const Text('Done Reviewing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionContent(
    Question currentQ,
    UserResponse? resp,
    bool isCorrect,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Answer Outcome Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCorrect
                ? (isDark ? const Color(0x2610B981) : const Color(0xFFECFDF5))
                : (isDark ? const Color(0x26EF4444) : const Color(0xFFFEF2F2)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isCorrect
                  ? AppTheme.green.withValues(alpha: 0.4)
                  : AppTheme.danger.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppTheme.green : AppTheme.danger,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'Your answer was correct!'
                      : (resp?.selectedChoiceId == null
                          ? 'You skipped this question during the exam session.'
                          : 'Your answer was incorrect.'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? AppTheme.greenDark : AppTheme.dangerDark,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

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

        // Choices with verified state
        Text(
          'Answer Verification & Choices:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
          ),
        ),
        const SizedBox(height: 12),

        ...currentQ.choices.map((choice) {
          final isStudentChoice = resp?.selectedChoiceId == choice.id;
          final isThisCorrect = choice.isCorrect;

          FidelOptionState optionState;
          if (isThisCorrect) {
            optionState = FidelOptionState.correct;
          } else if (isStudentChoice && !isThisCorrect) {
            optionState = FidelOptionState.incorrect;
          } else {
            optionState = FidelOptionState.unselected;
          }

          return FidelOptionCard(
            label: choice.label,
            textEn: choice.textEn,
            textAm: choice.textAm,
            state: optionState,
          );
        }),
        const SizedBox(height: 16),

        // Step-by-Step Educational Explanation Card
        FidelCard(
          padding: const EdgeInsets.all(22),
          backgroundColor: isDark
              ? AppTheme.brand.withValues(alpha: 0.08)
              : AppTheme.brandSubtle,
          borderColor: AppTheme.brand.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Step-by-Step Explanation',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentQ.explanation.solutionTextEn,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              if (currentQ.explanation.simplerExplanationEn != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x1A000000) : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Quick Concept Summary:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppTheme.accentDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentQ.explanation.simplerExplanationEn!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audio Explanation Player Card
        AudioPlayerCard(
          audioOptions: [
            AudioExplanation(
              id: 'audio_${currentQ.id}',
              questionId: currentQ.id,
              audioUrl: 'assets/audio/${currentQ.id}.mp3',
              durationSeconds: 45,
              language: 'en',
              narratorName: 'Teacher Abebe',
              fileSizeBytes: 0,
              transcription: '',
            ),
          ],
        ),
      ],
    );
  }
}
