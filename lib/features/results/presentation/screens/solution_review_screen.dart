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
                ? 'Question bookmarked!'
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
          'Thank you for helping us maintain verified quality. Our content reviewers will inspect this item.',
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
        appBar: AppBar(title: const Text('Solutions')),
        body: const Center(child: Text('No questions available for review.')),
      );
    }

    final currentQ = widget.questions[_currentIndex];
    final resp = widget.attempt.responses[currentQ.id];
    final isCorrect = resp?.isCorrect ?? false;
    final isBookmarked = _bookmarkedIds.contains(currentQ.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Solution ${_currentIndex + 1} of ${widget.questions.length}',
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppTheme.accentGold : null,
            ),
            tooltip: 'Bookmark Question',
            onPressed: () => _toggleBookmark(currentQ),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report Content Issue',
            onPressed: () => _reportContent(currentQ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCorrect
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCorrect
                                ? 'Your Answer is Correct'
                                : (resp?.selectedChoiceId == null
                                      ? 'You Skipped This Question'
                                      : 'Your Answer was Incorrect'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question Text Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentQ.questionTextEn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            if (currentQ.questionTextAm != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                currentQ.questionTextAm!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (currentQ.vectorDiagram != null) ...[
                      SvgDiagramViewer(diagram: currentQ.vectorDiagram!),
                      const SizedBox(height: 16),
                    ],

                    // Choices list with correct/student indicators
                    const Text(
                      'Choices:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currentQ.choices.map((choice) {
                      final isStudentChoice =
                          resp?.selectedChoiceId == choice.id;
                      final isThisCorrect = choice.isCorrect;

                      Color bg = Colors.white;
                      Color border = const Color(0xFFE2E8F0);
                      Color text = AppTheme.textDark;

                      if (isThisCorrect) {
                        bg = AppTheme.successGreen.withOpacity(0.12);
                        border = AppTheme.successGreen;
                        text = AppTheme.successGreen;
                      } else if (isStudentChoice && !isThisCorrect) {
                        bg = AppTheme.errorRed.withOpacity(0.12);
                        border = AppTheme.errorRed;
                        text = AppTheme.errorRed;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: border,
                            width: isThisCorrect || isStudentChoice ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${choice.label}.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: text,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                choice.textEn,
                                style: TextStyle(
                                  color: text,
                                  fontWeight: isThisCorrect
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isThisCorrect)
                              const Icon(
                                Icons.check,
                                color: AppTheme.successGreen,
                                size: 20,
                              )
                            else if (isStudentChoice)
                              const Icon(
                                Icons.close,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Low-Bandwidth Voiceover Solution Player
                    AudioPlayerCard(
                      audioOptions: [
                        AudioExplanation(
                          id: 'aud_${currentQ.id}_en',
                          questionId: currentQ.id,
                          language: 'en',
                          durationSeconds: 42,
                          audioUrl:
                              'https://cdn.fidellearn.et/audio/${currentQ.id}_en.opus',
                          fileSizeBytes: 14500,
                          narratorName: 'Dr. Abebe (Senior Educator)',
                          transcription: currentQ.explanation.solutionTextEn,
                        ),
                        if (currentQ.explanation.solutionTextAm != null)
                          AudioExplanation(
                            id: 'aud_${currentQ.id}_am',
                            questionId: currentQ.id,
                            language: 'am',
                            durationSeconds: 48,
                            audioUrl:
                                'https://cdn.fidellearn.et/audio/${currentQ.id}_am.opus',
                            fileSizeBytes: 15800,
                            narratorName: 'ወ/ሮ ትዕግስት (የሂሳብ መምህርት)',
                            transcription: currentQ.explanation.solutionTextAm!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descriptive Solution Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: AppTheme.accentGold,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Step-by-Step Descriptive Solution',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentQ.explanation.solutionTextEn,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          if (currentQ.explanation.simplerExplanationEn !=
                              null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.infoBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡 Simpler Explanation:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.infoBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentQ.explanation.simplerExplanationEn!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (currentQ.explanation.keyConcept != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '📌 Key Concept: ${currentQ.explanation.keyConcept!}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                          if (currentQ.explanation.commonPitfall != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '⚠️ Common Pitfall: ${currentQ.explanation.commonPitfall!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.warningOrange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
                  Text(
                    '${_currentIndex + 1} / ${widget.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _currentIndex < widget.questions.length - 1
                        ? () => setState(() => _currentIndex++)
                        : () => context.pop(),
                    child: Text(
                      _currentIndex < widget.questions.length - 1
                          ? 'Next'
                          : 'Done',
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
}
