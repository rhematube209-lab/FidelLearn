import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';

class ExamGhostScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamGhostScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamGhostScreen> createState() => _ExamGhostScreenState();
}

class _ExamGhostScreenState extends ConsumerState<ExamGhostScreen> {
  ExamAttempt? _bestAttempt;
  List<Question> _examQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGhostData();
  }

  Future<void> _loadGhostData() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final examRepo = ref.read(examRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);

    if (user != null) {
      final allHistory = await examRepo.getAttemptHistory(user.id);
      final examAttempts = allHistory
          .where((a) => a.examId == widget.examId || a.id == widget.examId)
          .toList();

      if (examAttempts.isNotEmpty) {
        final sorted = List<ExamAttempt>.from(examAttempts)
          ..sort((a, b) {
            final scoreComp = b.score.compareTo(a.score);
            if (scoreComp != 0) return scoreComp;
            return a.durationSeconds.compareTo(b.durationSeconds);
          });

        _bestAttempt = sorted.first;

        final qs = await contentRepo.getQuestions(
          grade: user.grade,
          subjectId: _bestAttempt!.subjectId,
        );
        _examQuestions = qs.take(_bestAttempt!.totalQuestions).toList();
      }

      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchGhostRetake() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _bestAttempt == null || _examQuestions.isEmpty) return;

    final examRepo = ref.read(examRepositoryProvider);

    final exam = Exam(
      id: 'ghost_${_bestAttempt!.examId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '👻 Ghost Match: ${_bestAttempt!.examTitle}',
      examType: ExamType.practice,
      grade: user.grade,
      stream: user.stream,
      subjectId: _bestAttempt!.subjectId,
      timeLimitMinutes: 0,
      totalQuestions: _examQuestions.length,
      questions: _examQuestions,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_ghost_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

    if (mounted) {
      await context
          .push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
      if (mounted) await _loadGhostData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal-Best Exam Ghost Cockpit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brand))
          : _bestAttempt == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on_rounded,
                            size: 64, color: AppTheme.brand),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Ghost Telemetry Recorded',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Complete this exam at least once to create your personal best "Ghost" pacing benchmark.',
                        style:
                            TextStyle(color: AppTheme.darkMuted, fontSize: 13),
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
                          // Ghost Telemetry Header Banner
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF3B0764),
                                  AppTheme.darkSurfaceStrong
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(
                                  color: AppTheme.brand.withOpacity(0.4)),
                              boxShadow: AppTheme.cardShadowDark,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.brand.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'OFFLINE PACING TELEMETRY',
                                          style: TextStyle(
                                              color: AppTheme.brand,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Target: ${_bestAttempt!.examTitle}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Race against your historical peak speed and choice answers with zero cloud sync required.',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.darkTextSoft),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 24),
                                  ElevatedButton.icon(
                                    onPressed: _launchGhostRetake,
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 22),
                                    label: const Text('Race Your Ghost Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brandStrong,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 22, vertical: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Benchmark Telemetry Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildGhostStat(
                                  'Personal Best Score',
                                  '${_bestAttempt!.score} / ${_bestAttempt!.totalQuestions}',
                                  '${_bestAttempt!.percentage.toStringAsFixed(0)}% Accuracy',
                                  AppTheme.green,
                                  Icons.emoji_events_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildGhostStat(
                                  'Pacing Lap Time',
                                  '${_bestAttempt!.durationSeconds}s',
                                  '${(_bestAttempt!.durationSeconds / _bestAttempt!.totalQuestions).round()}s / question',
                                  AppTheme.brand,
                                  Icons.speed_rounded,
                                ),
                              ),
                            ],
                          ),

                          if (!isDesktop) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _launchGhostRetake,
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 22),
                              label: const Text('Race Your Ghost Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandStrong,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildGhostStat(
      String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkMuted,
                      fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted)),
        ],
      ),
    );
  }
}
