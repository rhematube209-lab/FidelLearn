import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/mistake_model.dart';

class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  List<MistakeRecord> _mistakes = [];
  Map<String, Question> _questions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final mistakeRepo = ref.read(mistakeRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);

    if (user != null) {
      final list = await mistakeRepo.getMistakes(user.id);
      final Map<String, Question> qMap = {};
      for (final m in list) {
        final q = await contentRepo.getQuestionById(m.questionId);
        if (q != null) qMap[m.questionId] = q;
      }

      if (mounted) {
        setState(() {
          _mistakes = list;
          _questions = qMap;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startMistakeRetryExam() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final examRepo = ref.read(examRepositoryProvider);
    if (user == null || _mistakes.isEmpty) return;

    final List<Question> retryQuestions = [];
    for (final m in _mistakes) {
      final q = _questions[m.questionId];
      if (q != null) retryQuestions.add(q);
    }

    if (retryQuestions.isEmpty) return;

    final exam = Exam(
      id: 'mistake_retry_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Mistake Notebook Targeted Remediation',
      examType: ExamType.practice,
      grade: user.grade,
      stream: user.stream,
      subjectId: retryQuestions.first.subjectId,
      timeLimitMinutes: 0,
      totalQuestions: retryQuestions.length,
      questions: retryQuestions,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_retry_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

    if (mounted) {
      await context.push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
      if (mounted) {
        await _loadMistakes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Notebook & Error Remediation', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : _mistakes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.green.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 64,
                          color: AppTheme.green,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mistake Notebook is Clean!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Any questions answered incorrectly during practice or mocks will appear here for targeted drills.',
                        style: TextStyle(color: AppTheme.darkMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                          // Header Banner
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF831843), AppTheme.darkSurfaceStrong],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(color: AppTheme.pink.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_mistakes.length} Unmastered Questions',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Re-testing errors is the fastest way to boost your national exam score.',
                                      style: TextStyle(fontSize: 12, color: AppTheme.darkTextSoft),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _startMistakeRetryExam,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Drill All Mistakes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandStrong,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mistakes Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: isDesktop ? 520 : 600,
                              mainAxisExtent: 180,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: _mistakes.length,
                            itemBuilder: (context, index) {
                              final m = _mistakes[index];
                              final q = _questions[m.questionId];

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(color: AppTheme.darkBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'FAILED ${m.incorrectCount}X',
                                            style: const TextStyle(
                                              color: AppTheme.danger,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          q?.subjectId ?? 'General',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      q?.questionTextEn ?? 'Question content...',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Difficulty: ${q?.difficulty.toUpperCase() ?? "MED"}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted),
                                        ),
                                        Text(
                                          'Mastery: ${m.mastered ? "100%" : "0%"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: m.mastered ? AppTheme.green : AppTheme.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
