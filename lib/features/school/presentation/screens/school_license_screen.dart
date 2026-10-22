import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
          if (license == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Institutional License',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This school does not currently have an active license recorded. Please contact your administrator or support to activate school licensing.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return seatsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading seats: $err')),
            data: (seats) {
              if (seats == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Seat information unavailable for this school.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              }
              return _LicenseContent(
                license: license,
                seats: seats,
              );
            },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242C51) : const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF384878) : const Color(0xFFDFE5FF),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.protoBrand),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commercial License & Entitlements · Academic Year 2026/27. Seat usage and payment records are kept strictly isolated from student academic profiles.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFBAC6F1) : const Color(0xFF5B66A8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Status & Seat Capacity Cards (2 columns on wide screens)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final leftCol = _buildSeatAllocationCard(context, isDark);
              final rightCol = _buildLicensePlanCard(context, isDark);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftCol),
                    const SizedBox(width: 18),
                    Expanded(child: rightCol),
                  ],
                );
              } else {
                return Column(
                  children: [
                    leftCol,
                    const SizedBox(height: 18),
                    rightCol,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // 3. Feature Entitlements Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.protoSurface(context),
              borderRadius: BorderRadius.circular(AppTheme.protoRadius),
              border: Border.all(color: AppTheme.protoLine(context)),
              boxShadow: AppTheme.protoCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enabled Feature Entitlements',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Capabilities authorized by this active institutional license',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.protoMuted(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.protoGoodLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Verified License',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.protoGood,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _EntitlementTile(
                  title: 'Student Learning Platform',
                  enabled: license.hasEntitlement('student_learning'),
                  description: 'Access to Grade 12 curriculum and practice',
                ),
                _EntitlementTile(
                  title: 'Teacher Portal (P7)',
                  enabled: license.hasEntitlement('teacher_portal'),
                  description: 'Class assignments, monitoring, and focus topics',
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
                  description: 'Formal executive, subject, and coverage reports',
                ),
                _EntitlementTile(
                  title: 'ESSLCE National Exam Simulation (P5)',
                  enabled: license.hasEntitlement('national_exam_simulation'),
                  description: 'Official historical papers and timed mock exams',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Payment Rails & Billing Options
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.protoSurface(context),
              borderRadius: BorderRadius.circular(AppTheme.protoRadius),
              border: Border.all(color: AppTheme.protoLine(context)),
              boxShadow: AppTheme.protoCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institutional Billing & Payment Rail Integrations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported payment rails for institutional contract renewals and seat additions.',
                  style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildPaymentPill('Telebirr', context, isDark),
                    _buildPaymentPill('Chapa', context, isDark),
                    _buildPaymentPill('CBE Bank Transfer', context, isDark),
                    _buildPaymentPill('Manual Invoice', context, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatAllocationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.protoRadius),
        border: Border.all(color: AppTheme.protoLine(context)),
        boxShadow: AppTheme.protoCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Seat Allocation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: seats.isOverCapacity ? AppTheme.protoBadLight : AppTheme.protoGoodLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  seats.isOverCapacity ? 'Capacity Alert' : 'Seats Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: seats.isOverCapacity ? AppTheme.protoBad : AppTheme.protoGood,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Ring Chart Visual
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      seats.isOverCapacity ? AppTheme.protoBad : AppTheme.protoBrand,
                      isDark ? const Color(0xFF233452) : const Color(0xFFE9EDFB),
                    ],
                    stops: [
                      (seats.seatUtilizationPct / 100.0).clamp(0.0, 1.0),
                      (seats.seatUtilizationPct / 100.0).clamp(0.0, 1.0),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.protoSurface(context),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${seats.seatUtilizationPct.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'used',
                        style: TextStyle(fontSize: 9, color: AppTheme.protoMuted(context)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENROLLED SEATS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.protoMuted(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${seats.occupiedSeats} / ${seats.studentSeatLimit} seats',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: seats.isOverCapacity ? AppTheme.protoBad : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${seats.seatUtilizationPct.toStringAsFixed(1)}% used',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available Seats: ${seats.availableSeats}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: seats.availableSeats <= 0 ? AppTheme.protoBad : AppTheme.protoGood,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (seats.seatUtilizationPct / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF233452) : const Color(0xFFEEF2F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                seats.isOverCapacity
                    ? AppTheme.protoBad
                    : seats.warningLevel == 'warning_90'
                        ? AppTheme.protoWarn
                        : AppTheme.protoBrand,
              ),
            ),
          ),
          if (seats.isOverCapacity) ...[
            const SizedBox(height: 10),
            const Text(
              'OVER CAPACITY',
              style: TextStyle(color: AppTheme.protoBad, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
          if (seats.warningLevel == 'critical_100') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.protoBadLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.protoBad.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.protoBad, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student seat limit reached. New student enrollments are blocked until seats are increased or inactive students are removed.',
                      style: TextStyle(color: AppTheme.protoBad, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLicensePlanCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.protoRadius),
        border: Border.all(color: AppTheme.protoLine(context)),
        boxShadow: AppTheme.protoCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'License Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.protoMuted(context),
                ),
              ),
              _StatusBadge(status: license.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            license.planCode.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Source: ${license.source.replaceAll('_', ' ').toUpperCase()}',
            style: TextStyle(fontSize: 12, color: AppTheme.protoMuted(context)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _DateRow(
            label: 'Contract Starts',
            date: license.startsAt,
          ),
          if (license.endsAt != null) ...[
            const SizedBox(height: 8),
            _DateRow(
              label: 'Contract Ends',
              date: license.endsAt!,
            ),
          ],
          if (license.graceEndsAt != null) ...[
            const SizedBox(height: 8),
            _DateRow(
              label: 'Grace Period Ends',
              date: license.graceEndsAt!,
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentPill(String name, BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF233452) : const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.protoLine(context)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFBAC6F1) : const Color(0xFF53617D),
        ),
      ),
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
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isWarning ? Colors.orange.shade800 : null,
              fontWeight: isWarning ? FontWeight.bold : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
