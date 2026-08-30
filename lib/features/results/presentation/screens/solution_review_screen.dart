import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
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
                ? 'Question bookmarked to offline study list!'
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
        title: const Text('Report Question Issue'),
        content: const Text(
          'Thank you for helping us maintain verified quality. Our content reviewers will inspect this question.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
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
    final currentQ = widget.questions[_currentIndex];
    final resp = widget.attempt.responses[currentQ.id];
    final isCorrect = resp?.isCorrect ?? false;
    final isBookmarked = _bookmarkedIds.contains(currentQ.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Solution Review: Q ${_currentIndex + 1} of ${widget.questions.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppTheme.accent : null,
            ),
            tooltip: 'Bookmark Question',
            onPressed: () => _toggleBookmark(currentQ),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report Issue',
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
                            color: Theme.of(context).cardTheme.color,
                            border: const Border(right: BorderSide(color: AppTheme.darkBorder)),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exam Items & Solutions',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: InkWell(
                                        onTap: () => setState(() => _currentIndex = index),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.brandStrong.withOpacity(0.18)
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
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                  color: isSelected ? AppTheme.darkText : AppTheme.darkTextSoft,
                                                ),
                                              ),
                                            ],
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
                                constraints: const BoxConstraints(maxWidth: 850),
                                child: _buildSolutionContent(currentQ, resp, isCorrect),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildSolutionContent(currentQ, resp, isCorrect),
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
                        foregroundColor: Colors.black,
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

  Widget _buildSolutionContent(Question currentQ, UserResponse? resp, bool isCorrect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Answer Outcome Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppTheme.green.withOpacity(0.12)
                : AppTheme.danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isCorrect ? AppTheme.green : AppTheme.danger,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppTheme.green : AppTheme.danger,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'Your answer was correct!'
                      : (resp?.selectedChoiceId == null
                          ? 'You skipped this question during the exam.'
                          : 'Your answer was incorrect.'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppTheme.green : AppTheme.danger,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
              Text(
                currentQ.questionTextEn,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
              if (currentQ.questionTextAm != null) ...[
                const SizedBox(height: 10),
                Text(
                  currentQ.questionTextAm!,
                  style: const TextStyle(
                    fontSize: 14,
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
        const Text('Choices Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),

        ...currentQ.choices.map((choice) {
          final isStudentChoice = resp?.selectedChoiceId == choice.id;
          final isThisCorrect = choice.isCorrect;

          Color bg = Theme.of(context).cardTheme.color!;
          Color border = AppTheme.darkBorder;

          if (isThisCorrect) {
            bg = AppTheme.green.withOpacity(0.15);
            border = AppTheme.green;
          } else if (isStudentChoice && !isThisCorrect) {
            bg = AppTheme.danger.withOpacity(0.15);
            border = AppTheme.danger;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: border, width: isThisCorrect || isStudentChoice ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isThisCorrect
                          ? AppTheme.green
                          : (isStudentChoice ? AppTheme.danger : const Color(0x1AFFFFFF)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        choice.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isThisCorrect || isStudentChoice ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      choice.textEn,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isThisCorrect || isStudentChoice ? FontWeight.bold : FontWeight.normal,
                        color: isThisCorrect ? AppTheme.green : (isStudentChoice ? AppTheme.danger : AppTheme.darkText),
                      ),
                    ),
                  ),
                  if (isThisCorrect)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 20),
                  if (isStudentChoice && !isThisCorrect)
                    const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Step-by-Step Educational Explanation Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.brandStrong.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Step-by-Step Explanation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentQ.explanation.solutionTextEn,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.darkText),
              ),
              if (currentQ.explanation.simplerExplanationEn != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Simpler Concept Summary:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentQ.explanation.simplerExplanationEn!,
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
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
