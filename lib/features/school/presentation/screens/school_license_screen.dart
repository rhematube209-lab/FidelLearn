import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/licensing_onboarding_models.dart';
import '../providers/licensing_onboarding_providers.dart';

class SchoolLicenseScreen extends ConsumerWidget {
  final String schoolId;

  const SchoolLicenseScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(schoolLicenseFamilyProvider(schoolId));
    final seatsAsync = ref.watch(schoolSeatUsageFamilyProvider(schoolId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School License & Seats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(schoolLicenseFamilyProvider(schoolId));
              ref.invalidate(schoolSeatUsageFamilyProvider(schoolId));
            },
          ),
        ],
      ),
      body: licenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Commercial License Access Restricted',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        data: (license) {
          return seatsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading seats: $err')),
            data: (seats) => _LicenseContent(
              license: license,
              seats: seats,
            ),
          );
        },
      ),
    );
  }
}

class _LicenseContent extends StatelessWidget {
  final SchoolLicense license;
  final SchoolSeatUsage seats;

  const _LicenseContent({
    required this.license,
    required this.seats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Status & Plan Header Card
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
                      'License Status',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    _StatusBadge(status: license.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  license.planCode.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${license.source.replaceAll('_', ' ').toUpperCase()}',
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 24),
                _DateRow(
                  label: 'Contract Starts',
                  date: license.startsAt,
                ),
                if (license.endsAt != null) ...[
                  const SizedBox(height: 6),
                  _DateRow(
                    label: 'Contract Ends',
                    date: license.endsAt!,
                  ),
                ],
                if (license.graceEndsAt != null) ...[
                  const SizedBox(height: 6),
                  _DateRow(
                    label: 'Grace Period Ends',
                    date: license.graceEndsAt!,
                    isWarning: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Seat Management Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Seat Allocation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${seats.occupiedSeats} / ${seats.studentSeatLimit} seats',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: seats.isOverCapacity ? Colors.red : null,
                      ),
                    ),
                    Text(
                      '${seats.seatUtilizationPct.toStringAsFixed(1)}% used',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (seats.seatUtilizationPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      seats.isOverCapacity
                          ? Colors.red
                          : seats.warningLevel == 'warning_90'
                              ? Colors.orange
                              : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Seats: ${seats.availableSeats}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: seats.availableSeats <= 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (seats.isOverCapacity)
                      const Text(
                        'OVER CAPACITY',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                if (seats.warningLevel == 'critical_100') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student seat limit reached. New student enrollments are blocked until seats are increased or inactive students are removed.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Feature Entitlements Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enabled Feature Entitlements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _EntitlementTile(
                  title: 'Student Learning Platform',
                  enabled: license.hasEntitlement('student_learning'),
                  description: 'Access to Grade 12 curriculum and practice',
                ),
                _EntitlementTile(
                  title: 'Teacher Portal (P7)',
                  enabled: license.hasEntitlement('teacher_portal'),
                  description:
                      'Class assignments, monitoring, and focus topics',
                ),
                _EntitlementTile(
                  title: 'Leadership Dashboard (P8)',
                  enabled: license.hasEntitlement('leadership_dashboard'),
                  description: 'School admin metrics and teacher roster',
                ),
                _EntitlementTile(
                  title: 'Assignments & Interventions (P9)',
                  enabled: license.hasEntitlement('assignments_interventions'),
                  description: 'Targeted drills and remediation tasks',
                ),
                _EntitlementTile(
                  title: 'Institutional Analytics & Reporting (P10)',
                  enabled: license.hasEntitlement('institutional_reporting'),
                  description:
                      'Formal executive, subject, and coverage reports',
                ),
                _EntitlementTile(
                  title: 'ESSLCE National Exam Simulation (P5)',
                  enabled: license.hasEntitlement('national_exam_simulation'),
                  description:
                      'Official historical papers and timed mock exams',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LicenseStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case LicenseStatus.active:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case LicenseStatus.trial:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case LicenseStatus.grace:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case LicenseStatus.suspended:
      case LicenseStatus.cancelled:
      case LicenseStatus.expired:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      case LicenseStatus.unknown:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isWarning;

  const _DateRow({
    required this.label,
    required this.date,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final str =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isWarning ? Colors.orange.shade800 : null,
            fontWeight: isWarning ? FontWeight.bold : null,
          ),
        ),
        Text(
          str,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.orange.shade800 : null,
          ),
        ),
      ],
    );
  }
}

class _EntitlementTile extends StatelessWidget {
  final String title;
  final bool enabled;
  final String description;

  const _EntitlementTile({
    required this.title,
    required this.enabled,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel_outlined,
            color: enabled ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : Colors.grey,
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
