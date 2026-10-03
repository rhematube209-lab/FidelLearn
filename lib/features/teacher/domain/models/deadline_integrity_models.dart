import 'package:equatable/equatable.dart';

import 'assignment_models.dart';

/// Trust levels for offline/online assignment deadline verification.
enum DeadlineIntegrityLevel {
  verified,
  unverified,
  anomaly;

  static DeadlineIntegrityLevel fromString(String? val) {
    if (val == null) return DeadlineIntegrityLevel.verified;
    switch (val.toLowerCase().trim()) {
      case 'unverified':
      case 'timing_unverified':
        return DeadlineIntegrityLevel.unverified;
      case 'anomaly':
      case 'clock_anomaly':
        return DeadlineIntegrityLevel.anomaly;
      case 'verified':
      default:
        return DeadlineIntegrityLevel.verified;
    }
  }

  String get dbValue => name;

  String get labelEn {
    switch (this) {
      case DeadlineIntegrityLevel.verified:
        return 'Verified';
      case DeadlineIntegrityLevel.unverified:
        return 'Timing Unverified';
      case DeadlineIntegrityLevel.anomaly:
        return 'Clock Anomaly';
    }
  }

  String get labelAm {
    switch (this) {
      case DeadlineIntegrityLevel.verified:
        return 'የተረጋገጠ';
      case DeadlineIntegrityLevel.unverified:
        return 'ያልተረጋገጠ ሰዓት';
      case DeadlineIntegrityLevel.anomaly:
        return 'የሰዓት መዛባት';
    }
  }
}

/// The immutable outcome of adjudicating assignment deadline compliance.
class DeadlineAdjudicationResult extends Equatable {
  final DeadlineIntegrityLevel integrityLevel;
  final bool? isLate; // null when timing is unverified or an anomaly
  final AssignmentRecipientStatus recipientStatus;
  final bool reviewRequired;
  final bool submissionAccepted;
  final String statusLabelEn;
  final String statusLabelAm;
  final DateTime? estimatedCompletionUtc;
  final String? reasonMessage;

  const DeadlineAdjudicationResult({
    required this.integrityLevel,
    required this.isLate,
    required this.recipientStatus,
    required this.reviewRequired,
    required this.submissionAccepted,
    required this.statusLabelEn,
    required this.statusLabelAm,
    this.estimatedCompletionUtc,
    this.reasonMessage,
  });

  @override
  List<Object?> get props => [
        integrityLevel,
        isLate,
        recipientStatus,
        reviewRequired,
        submissionAccepted,
        statusLabelEn,
        statusLabelAm,
        estimatedCompletionUtc,
        reasonMessage,
      ];
}

/// Authoritative domain service for evaluating assignment deadline integrity.
class DeadlineAdjudicator {
  /// Evaluates deadline compliance and assigns trust levels according to trusted timing evidence.
  static DeadlineAdjudicationResult adjudicate({
    required bool isOnline,
    required DateTime serverReceivedAt,
    required DateTime? dueAt,
    required bool allowLateSubmission,
    required DateTime localCompletedAt,
    DateTime? trustedAnchorUtc,
    int? trustedAnchorMonotonicMs,
    int? completionMonotonicMs,
    bool timerIntegrityWarning = false,
    bool wallClockShiftDetected = false,
  }) {
    // Invariant: Student work is NEVER discarded or deleted
    const bool submissionAccepted = true;

    // 1. Explicit Anomaly Detected during attempt
    if (timerIntegrityWarning || wallClockShiftDetected) {
      return const DeadlineAdjudicationResult(
        integrityLevel: DeadlineIntegrityLevel.anomaly,
        isLate: null,
        recipientStatus: AssignmentRecipientStatus.submitted,
        reviewRequired: true,
        submissionAccepted: submissionAccepted,
        statusLabelEn: 'Submission Received — Clock Anomaly Detected',
        statusLabelAm: 'ስራው ደርሷል — የሰዓት መዛባት ተገኝቷል',
        reasonMessage:
            'A timer integrity warning or wall-clock backward shift was detected during the session. Student responses and score are preserved, but deadline timing cannot be certified.',
      );
    }

    // 2. Online Submission with Authoritative Server Timing
    if (isOnline) {
      final bool late = dueAt != null && serverReceivedAt.isAfter(dueAt);
      final AssignmentRecipientStatus status = late
          ? (allowLateSubmission
              ? AssignmentRecipientStatus.late
              : AssignmentRecipientStatus.submitted)
          : AssignmentRecipientStatus.submitted;

      return DeadlineAdjudicationResult(
        integrityLevel: DeadlineIntegrityLevel.verified,
        isLate: late,
        recipientStatus: status,
        reviewRequired: late && !allowLateSubmission,
        submissionAccepted: submissionAccepted,
        statusLabelEn: late
            ? (allowLateSubmission
                ? 'Late Submission'
                : 'Deadline Review Required')
            : 'On Time',
        statusLabelAm: late
            ? (allowLateSubmission ? 'ዘግይቶ የቀረበ' : 'የቀነ-ገደብ ክለሳ ያስፈልጋል')
            : 'በሰዓቱ የቀረበ',
        estimatedCompletionUtc: serverReceivedAt,
      );
    }

    // 3. Offline Submission with Trusted Server-Time Anchor & Monotonic Continuity
    if (trustedAnchorUtc != null &&
        trustedAnchorMonotonicMs != null &&
        completionMonotonicMs != null) {
      final int monotonicElapsedMs =
          completionMonotonicMs - trustedAnchorMonotonicMs;

      // Fail-safe validation of monotonic continuity
      final bool continuityValid = monotonicElapsedMs >= 0 &&
          monotonicElapsedMs < 30 * 24 * 3600 * 1000; // < 30 days sanity cap

      if (continuityValid) {
        final estimatedUtc =
            trustedAnchorUtc.add(Duration(milliseconds: monotonicElapsedMs));
        final bool late = dueAt != null && estimatedUtc.isAfter(dueAt);
        final AssignmentRecipientStatus status = late
            ? (allowLateSubmission
                ? AssignmentRecipientStatus.late
                : AssignmentRecipientStatus.submitted)
            : AssignmentRecipientStatus.submitted;

        return DeadlineAdjudicationResult(
          integrityLevel: DeadlineIntegrityLevel.verified,
          isLate: late,
          recipientStatus: status,
          reviewRequired: late && !allowLateSubmission,
          submissionAccepted: submissionAccepted,
          statusLabelEn: late
              ? (allowLateSubmission
                  ? 'Late Submission'
                  : 'Deadline Review Required')
              : 'On Time',
          statusLabelAm: late
              ? (allowLateSubmission ? 'ዘግይቶ የቀረበ' : 'የቀነ-ገደብ ክለሳ ያስፈልጋል')
              : 'በሰዓቱ የቀረበ',
          estimatedCompletionUtc: estimatedUtc,
        );
      }
      // If continuity was broken (e.g. counter reset / reboot), fall through to unverified
    }

    // 4. Offline Submission without Trusted Anchor
    // (Includes pre-shifted clock before attempt where monotonic timer detected no change during session)
    return DeadlineAdjudicationResult(
      integrityLevel: DeadlineIntegrityLevel.unverified,
      isLate: null,
      recipientStatus: AssignmentRecipientStatus.submitted,
      reviewRequired: !allowLateSubmission,
      submissionAccepted: submissionAccepted,
      statusLabelEn: allowLateSubmission
          ? 'Submission Received — Deadline Timing Unverified'
          : 'Deadline Review Required',
      statusLabelAm: allowLateSubmission
          ? 'ስራው ደርሷል — የቀነ-ገደብ ሰዓት አልተረጋገጠም'
          : 'የቀነ-ገደብ ክለሳ ያስፈልጋል',
      reasonMessage:
          'Submission was completed offline without an authoritative server UTC anchor. Absolute completion time cannot be certified. Student responses and score are fully preserved.',
    );
  }
}
