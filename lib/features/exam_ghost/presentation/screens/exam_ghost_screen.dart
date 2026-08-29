import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/exam_ghost_models.dart';
import '../../domain/services/exam_ghost_comparator.dart';

class ExamGhostScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamGhostScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamGhostScreen> createState() => _ExamGhostScreenState();
}

class _ExamGhostScreenState extends ConsumerState<ExamGhostScreen> {
  ExamAttempt? _bestAttempt;
  ExamGhostComparison? _latestComparison;
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
        // Sort by best score, then shortest duration
        final sorted = List<ExamAttempt>.from(examAttempts)
          ..sort((a, b) {
            final scoreComp = b.score.compareTo(a.score);
            if (scoreComp != 0) return scoreComp;
            return a.durationSeconds.compareTo(b.durationSeconds);
          });

        _bestAttempt = sorted.first;

        // If at least 2 attempts exist, compare latest with previous best
        if (examAttempts.length >= 2) {
          final latest = examAttempts.first;
          final previousBest = sorted[1];
          _latestComparison = ExamGhostComparator.compare(
            currentScore: latest.score,
            currentDurationSeconds: latest.durationSeconds,
            previousBestScore: previousBest.score,
            previousBestDurationSeconds: previousBest.durationSeconds,
          );
        }

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
    final examRepo = ref.read(examRepositoryProvider);
    if (user == null || _bestAttempt == null || _examQuestions.isEmpty) return;

    final exam = Exam(
      id: _bestAttempt!.examId,
      title: '${_bestAttempt!.examTitle} (Ghost Challenge)',
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
      await context.push(
        '/exam_runner',
        extra: {'exam': exam, 'attempt': attempt},
      );
      await _loadGhostData();
    }
  }

  void _exportGhostQr() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (_bestAttempt == null || user == null) return;

    final qrService = ref.read(offlineChallengeQrServiceProvider);
    final qrPayload = qrService.encodeAttemptToQrPayload(
      attempt: _bestAttempt!,
      studentDisplayName: user.displayName,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Export Ghost QR Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this offline challenge code with your friends in class:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: SelectableText(
                qrPayload,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Benchmark: ${_bestAttempt!.score}/${_bestAttempt!.totalQuestions} pts in ${_bestAttempt!.durationSeconds}s (${_bestAttempt!.percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importPeerGhostQr() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppTheme.accentGoldDark),
            SizedBox(width: 8),
            Text('Import Peer Challenge QR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the FIDEL_GHOST QR code payload from your classmate:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'FIDEL_GHOST:v1:...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrService = ref.read(offlineChallengeQrServiceProvider);
              final decoded =
                  qrService.decodeQrPayloadToGhost(controller.text.trim());

              if (decoded != null) {
                Navigator.pop(ctx);
                setState(() {
                  _bestAttempt = decoded.toExamAttempt();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.successGreen,
                    content: Text(
                      'Imported ${decoded.studentDisplayName}\'s ghost benchmark! (${decoded.score} pts in ${decoded.durationSeconds}s)',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.errorRed,
                    content: Text('Invalid QR challenge payload format.'),
                  ),
                );
              }
            },
            child: const Text('Import & Race'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Ghost Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Import Peer Ghost',
            onPressed: _importPeerGhostQr,
          ),
          if (_bestAttempt != null)
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Export Ghost QR',
              onPressed: _exportGhostQr,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bestAttempt == null
          ? const Center(
              child: Text('No previous attempt found for this exam.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Ghost Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: AppTheme.accentGold,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Personal-Best Ghost',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Best Score',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_bestAttempt!.score}/${_bestAttempt!.totalQuestions}',
                                  style: const TextStyle(
                                    color: AppTheme.accentGold,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_bestAttempt!.percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF334155),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Best Time',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_bestAttempt!.durationSeconds}s',
                                  style: const TextStyle(
                                    color: AppTheme.infoBlue,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(_bestAttempt!.durationSeconds / _bestAttempt!.totalQuestions).round()}s / question',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Ghost Comparison if available
                  if (_latestComparison != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _latestComparison!.isNewPersonalBest
                            ? AppTheme.successGreen.withOpacity(0.12)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _latestComparison!.isNewPersonalBest
                              ? AppTheme.successGreen
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _latestComparison!.headline,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _latestComparison!.isNewPersonalBest
                                  ? AppTheme.successGreen
                                  : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Score delta: ${_latestComparison!.scoreDelta >= 0 ? "+" : ""}${_latestComparison!.scoreDelta} pts • Speed delta: ${_latestComparison!.speedDeltaSeconds >= 0 ? "+" : ""}${_latestComparison!.speedDeltaSeconds}s',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Challenge Explanation
                  const Text(
                    'How Exam Ghost Works',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exam Ghost replays the exact question set against your historical personal best. Beat your Ghost by achieving a higher score or a faster completion time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _launchGhostRetake,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Start Ghost Challenge Retake'),
                  ),
                ],
              ),
            ),
    );
  }
}
