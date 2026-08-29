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
