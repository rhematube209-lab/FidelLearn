import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/licensing_onboarding_models.dart';
import '../providers/licensing_onboarding_providers.dart';

class SchoolOnboardingScreen extends ConsumerStatefulWidget {
  final String schoolId;

  const SchoolOnboardingScreen({
    super.key,
    required this.schoolId,
  });

  @override
  ConsumerState<SchoolOnboardingScreen> createState() =>
      _SchoolOnboardingScreenState();
}

class _SchoolOnboardingScreenState
    extends ConsumerState<SchoolOnboardingScreen> {
  bool _isValidating = false;
  bool _isActivating = false;
  Map<String, dynamic>? _validationResult;
  String? _errorMessage;

  Future<void> _handleValidate() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(licensingOnboardingRepositoryProvider);
      final res = await repo.validateSchoolActivation(widget.schoolId);
      setState(() {
        _validationResult = res;
      });
      ref.invalidate(schoolOnboardingFamilyProvider(widget.schoolId));
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _handleActivate() async {
    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(licensingOnboardingRepositoryProvider);
      await repo.activateSchool(widget.schoolId);
      ref.invalidate(schoolOnboardingFamilyProvider(widget.schoolId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isActivating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync =
        ref.watch(schoolOnboardingFamilyProvider(widget.schoolId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Onboarding Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(schoolOnboardingFamilyProvider(widget.schoolId));
            },
          ),
        ],
      ),
      body: onboardingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) {
          final isCompleted = state.status == OnboardingStatus.completed;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Progress Header
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Onboarding Progress',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _OnboardingStatusBadge(status: state.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: state.progressPct / 100.0,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.completedStepsCount} of 10 steps completed (${state.progressPct.toInt()}%)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_validationResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_validationResult!['ready_for_activation'] == true)
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (_validationResult!['ready_for_activation'] == true)
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (_validationResult!['ready_for_activation'] == true)
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color:
                                (_validationResult!['ready_for_activation'] ==
                                        true)
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (_validationResult!['ready_for_activation'] == true)
                                ? 'Activation Validation Passed'
                                : 'Activation Incomplete',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  (_validationResult!['ready_for_activation'] ==
                                          true)
                                      ? Colors.green
                                      : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      if (_validationResult!['blocking_reasons'] is List) ...[
                        const SizedBox(height: 6),
                        ...(_validationResult!['blocking_reasons'] as List).map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(left: 28, top: 2),
                            child: Text(
                              '• $reason',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Checklist Items
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foundation Setup Checklist',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StepTile(
                        stepNumber: 1,
                        title: 'School Profile Created',
                        completed: state.schoolCreated,
                        description:
                            'Institution identity and metadata registered',
                      ),
                      _StepTile(
                        stepNumber: 2,
                        title: 'Commercial License / Trial',
                        completed: state.licenseConfigured,
                        description:
                            'Active license and student seat limit assigned',
                      ),
                      _StepTile(
                        stepNumber: 3,
                        title: 'Academic Year Configured',
                        completed: state.academicYearConfigured,
                        description:
                            'Current Ethiopian academic calendar established',
                      ),
                      _StepTile(
                        stepNumber: 4,
                        title: 'Classrooms & Sections',
                        completed: state.classesConfigured,
                        description:
                            'Sections configured for Natural / Social streams',
                      ),
                      _StepTile(
                        stepNumber: 5,
                        title: 'School Administrator',
                        completed: state.adminConfigured,
                        description:
                            'Lead institutional administrator assigned',
                      ),
                      _StepTile(
                        stepNumber: 6,
                        title: 'Teaching Staff',
                        completed: state.teachersConfigured,
                        description:
                            'Teachers onboarded with active school roles',
                      ),
                      _StepTile(
                        stepNumber: 7,
                        title: 'Teacher-Subject Assignments',
                        completed: state.teacherAssignmentsConfigured,
                        description:
                            'Teachers mapped to classroom subject slots',
                      ),
                      _StepTile(
                        stepNumber: 8,
                        title: 'Student Enrollments',
                        completed: state.studentsConfigured,
                        description:
                            'Students imported and enrolled into sections',
                      ),
                      _StepTile(
                        stepNumber: 9,
                        title: 'Curriculum Coverage Validation',
                        completed: state.coverageValidated,
                        description:
                            'Verified canonical subject requirements satisfied',
                      ),
                      _StepTile(
                        stepNumber: 10,
                        title: 'Activation Ready',
                        completed: state.activationReady,
                        description:
                            'All system checks pass for operational launch',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: _isValidating ? null : _handleValidate,
                  icon: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Validate Readiness'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (state.activationReady && !_isActivating)
                      ? _handleActivate
                      : null,
                  icon: _isActivating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rocket_launch),
                  label: const Text('Activate School Institution'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'School Fully Operational',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'All onboarding stages completed. Institution is active.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingStatusBadge extends StatelessWidget {
  final OnboardingStatus status;

  const _OnboardingStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case OnboardingStatus.completed:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'COMPLETED';
        break;
      case OnboardingStatus.readyForActivation:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'READY';
        break;
      case OnboardingStatus.inProgress:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'IN PROGRESS';
        break;
      case OnboardingStatus.blocked:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = 'BLOCKED';
        break;
      case OnboardingStatus.notStarted:
      case OnboardingStatus.unknown:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = 'NOT STARTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final bool completed;
  final String description;

  const _StepTile({
    required this.stepNumber,
    required this.title,
    required this.completed,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: completed ? Colors.green : Colors.grey.shade300,
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: completed ? null : Colors.grey.shade700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
