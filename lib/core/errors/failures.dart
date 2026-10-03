import 'package:equatable/equatable.dart';

/// Base typed domain failure
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection available.',
    super.code,
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server returned an error. Please try again.',
    super.code,
  ]);
}

class PackageDownloadFailure extends Failure {
  const PackageDownloadFailure(super.message, [super.code]);
}

class InvalidPackageFailure extends Failure {
  const InvalidPackageFailure([
    super.message = 'The content package is corrupted or invalid.',
    super.code,
  ]);
}

class PackageActivationFailure extends Failure {
  const PackageActivationFailure([
    super.message =
        'Package activation blocked due to missing or corrupt scientific assets.',
    super.code,
  ]);
}

class InsufficientQuestionsFailure extends Failure {
  final int requested;
  final int available;

  const InsufficientQuestionsFailure(this.requested, this.available)
      : super(
          'Requested $requested questions, but only $available matching questions are available.',
        );

  @override
  List<Object?> get props => [message, code, requested, available];
}

class ExamRecoveryFailure extends Failure {
  const ExamRecoveryFailure([
    super.message = 'Failed to recover the active exam session.',
    super.code,
  ]);
}

class DuplicateSubmissionFailure extends Failure {
  const DuplicateSubmissionFailure([
    super.message = 'This exam attempt has already been submitted.',
    super.code,
  ]);
}

class InsufficientCoinsFailure extends Failure {
  final int requiredCoins;
  final int availableCoins;

  const InsufficientCoinsFailure(this.requiredCoins, this.availableCoins)
      : super(
          'Requires $requiredCoins Study Coins, but you have $availableCoins.',
        );

  @override
  List<Object?> get props => [message, code, requiredCoins, availableCoins];
}

class DuplicateRewardClaimFailure extends Failure {
  const DuplicateRewardClaimFailure([
    super.message = 'Reward for this activity has already been claimed.',
    super.code,
  ]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.code]);
}

class SimulationSufficiencyFailure extends Failure {
  final String subjectId;
  final String partitionName;
  final int requiredCount;
  final int availableCount;

  const SimulationSufficiencyFailure({
    required this.subjectId,
    required this.partitionName,
    required this.requiredCount,
    required this.availableCount,
  }) : super(
          'Insufficient verified questions for simulation "$subjectId" partition "$partitionName": '
          'required $requiredCount, available $availableCount.',
        );

  @override
  List<Object?> get props => [
        message,
        code,
        subjectId,
        partitionName,
        requiredCount,
        availableCount,
      ];
}

class HistoricalIncompleteFailure extends Failure {
  final String paperTitle;
  final int expectedCount;
  final int verifiedCount;

  const HistoricalIncompleteFailure({
    required this.paperTitle,
    required this.expectedCount,
    required this.verifiedCount,
  }) : super(
          'Historical paper "$paperTitle" is incomplete: '
          'expected $expectedCount questions, but only $verifiedCount are verified. '
          'Cannot be launched as a strict full national exam.',
        );

  @override
  List<Object?> get props =>
      [message, code, paperTitle, expectedCount, verifiedCount];
}

// =============================================================================
// P6 Institutional & Multi-Tenant Failures
// =============================================================================

class SchoolNotFoundFailure extends Failure {
  final String schoolId;

  const SchoolNotFoundFailure(this.schoolId)
      : super('School with ID "$schoolId" was not found.', 'SCHOOL_NOT_FOUND');

  @override
  List<Object?> get props => [message, code, schoolId];
}

class MembershipNotFoundFailure extends Failure {
  final String? schoolId;
  final String? userId;

  const MembershipNotFoundFailure([this.schoolId, this.userId])
      : super(
          'No institutional membership found${schoolId != null ? ' for school "$schoolId"' : ''}.',
          'MEMBERSHIP_NOT_FOUND',
        );

  @override
  List<Object?> get props => [message, code, schoolId, userId];
}

class MembershipInactiveFailure extends Failure {
  final String? schoolId;
  final String status;

  const MembershipInactiveFailure(this.status, [this.schoolId])
      : super(
          'Institutional membership is not active (status: $status).',
          'MEMBERSHIP_INACTIVE',
        );

  @override
  List<Object?> get props => [message, code, status, schoolId];
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([
    super.message = 'You do not have permission to perform this action.',
    super.code = 'PERMISSION_DENIED',
  ]);
}

class InvitationExpiredFailure extends Failure {
  const InvitationExpiredFailure([
    super.message = 'This school invitation code has expired.',
    super.code = 'INVITATION_EXPIRED',
  ]);
}

class InvitationInvalidFailure extends Failure {
  const InvitationInvalidFailure([
    super.message =
        'The school invitation code is invalid or has already been used.',
    super.code = 'INVITATION_INVALID',
  ]);
}

class TenantValidationFailure extends Failure {
  const TenantValidationFailure(
    super.message, [
    super.code = 'TENANT_VALIDATION_ERROR',
  ]);
}
