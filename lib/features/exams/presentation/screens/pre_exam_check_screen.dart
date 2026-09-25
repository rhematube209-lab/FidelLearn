import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_engine.dart';

/// Dedicated pre-exam check and confirmation screen for National Exam Simulations
/// and Official Historical Papers.
class PreExamCheckScreen extends ConsumerStatefulWidget {
  final Exam exam;
  final NationalExamPolicy? policy;

  const PreExamCheckScreen({
    super.key,
    required this.exam,
    this.policy,
  });

  @override
  ConsumerState<PreExamCheckScreen> createState() => _PreExamCheckScreenState();
}

class _PreExamCheckScreenState extends ConsumerState<PreExamCheckScreen> {
  bool _isLaunching = false;

  late final NationalExamPolicy _policy =
      widget.policy ?? NationalExamPolicy.fromMode(widget.exam.examMode);

  Future<void> _handleConfirmStart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.brand, size: 24),
            SizedBox(width: 8),
            Text(
              'Begin National Exam?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to start "${widget.exam.title}".',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.brand.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Total Questions: ${widget.exam.totalQuestions}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '• Duration: ${widget.exam.timeLimitMinutes} Minutes',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The timer starts immediately upon confirmation. Backgrounding the app does not pause the exam clock.',
                    style: TextStyle(fontSize: 12, color: AppTheme.darkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandStrong,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('I am Ready — Begin'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLaunching = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final userId = user?.id ?? 'guest_student';

      final attempt = ExamEngine.startAttempt(
        attemptId:
            'att_${widget.exam.examMode.toDbString()}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        exam: widget.exam,
      );

      final examRepo = ref.read(examRepositoryProvider);
      await examRepo.saveActiveAttempt(attempt);

      if (mounted) {
        context.pushReplacement('/exam_runner', extra: {
          'exam': widget.exam,
          'attempt': attempt,
          'policy': _policy,
          'showInstantFeedback': !_policy.hideInstantFeedback,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch exam session: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        setState(() => _isLaunching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exam = widget.exam;

    final isHistorical = exam.examMode == ExamMode.historicalPaper ||
        exam.sourceType == ExamSourceType.officialHistoricalPaper;

    final modeLabel =
        isHistorical ? 'Official Past Paper' : 'FidelLearn ESSLCE Simulation';
    final provenanceLabel = isHistorical
        ? (exam.historicalYear != null
            ? '${exam.historicalYear} E.C. Official NEAEA Exam Paper'
            : 'Official NEAEA Archive Paper')
        : (exam.blueprintVersion != null
            ? 'FidelLearn Simulation Blueprint (${exam.blueprintVersion})'
            : 'FidelLearn Verified Exam Blueprint');

    final variantStr = exam.examVariant == ExamVariantCode.naturalScience
        ? 'Natural Science Track'
        : (exam.examVariant == ExamVariantCode.socialScience
            ? 'Social Science Track'
            : exam.stream.toUpperCase());

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          modeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FidelBadge(
                          text: modeLabel.toUpperCase(),
                          variant: isHistorical
                              ? FidelBadgeVariant.gold
                              : FidelBadgeVariant.primary,
                          isSmall: true,
                        ),
                        const SizedBox(width: 8),
                        FidelBadge(
                          text: variantStr,
                          variant: FidelBadgeVariant.neutral,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 16, color: AppTheme.accentGold),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provenanceLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : AppTheme.lightMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Exam Specifications Matrix
              const Text(
                'Examination Specifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecCard(
                      icon: Icons.quiz_outlined,
                      label: 'Questions',
                      value: '${exam.totalQuestions} Items',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecCard(
                      icon: Icons.schedule_rounded,
                      label: 'Time Limit',
                      value: exam.timeLimitMinutes > 0
                          ? '${exam.timeLimitMinutes} Min'
                          : 'Untimed',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecCard(
                      icon: Icons.translate_rounded,
                      label: 'Language',
                      value: 'English',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecCard(
                      icon: Icons.offline_pin_rounded,
                      label: 'Offline Mode',
                      value: '100% Ready',
                      color: AppTheme.green,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              // Sections if present
              if (exam.sections != null && exam.sections!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Examination Sections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...exam.sections!.map(
                  (sec) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.segment_rounded,
                            size: 18, color: AppTheme.brand),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.titleEn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                '${sec.questionCount} Questions (Q${sec.startIndex + 1}–Q${sec.startIndex + sec.questionCount})',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppTheme.darkMuted
                                      : AppTheme.lightMuted,
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

              const SizedBox(height: 20),

              // Examination Rules
              const Text(
                'Examination Rules & Integrity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildRuleRow(
                      icon: Icons.timer_outlined,
                      text:
                          'Strict Wall-Clock Timer: The clock starts when you confirm. Closing or backgrounding the app does NOT pause the exam duration.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildRuleRow(
                      icon: Icons.visibility_off_outlined,
                      text:
                          'Hidden Explanations: Correct answers and explanations remain hidden until your final submission.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildRuleRow(
                      icon: Icons.save_outlined,
                      text:
                          'Instant Local Autosave: All selected answers and review flags are saved immediately offline in SQLite.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildRuleRow(
                      icon: Icons.alarm_on_rounded,
                      text:
                          'Auto-Submit: When time reaches zero, the exam automatically finalizes and scores all saved answers.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildRuleRow(
                      icon: Icons.insights_rounded,
                      text:
                          'Post-Exam Analytics: Comprehensive score breakdown, weak-unit diagnostics, and mistake review are unlocked after submission.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // CTA Start Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLaunching ? null : _handleConfirmStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandStrong,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLaunching
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Start Examination',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.brand),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ),
      ],
    );
  }
}
