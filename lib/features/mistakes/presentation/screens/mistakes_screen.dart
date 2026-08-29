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
      title: 'Mistake Notebook Retry Practice',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Notebook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mistakes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 64,
                    color: AppTheme.successGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Zero Unresolved Mistakes! 🎉',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Whenever you miss a question on practice exams, it will automatically appear here for mastery.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.errorRed.withOpacity(0.06),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.errorRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${_mistakes.length} questions to master. Retrying mistakes improves your retention by 70%.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _mistakes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final m = _mistakes[index];
                      final q = _questions[m.questionId];
                      if (q == null) return const SizedBox.shrink();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withOpacity(
                                        0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Missed ${m.mistakeCount}x',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    q.subjectId.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                q.questionTextEn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Key Pitfall: ${q.explanation.commonPitfall ?? "Review fundamental formula."}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _startMistakeRetryExam,
                    icon: const Icon(Icons.replay),
                    label: Text('Retry All ${_mistakes.length} Mistakes Now'),
                  ),
                ),
              ],
            ),
    );
  }
}
