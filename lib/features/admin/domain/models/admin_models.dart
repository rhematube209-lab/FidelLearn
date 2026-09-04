import 'package:equatable/equatable.dart';

class ContentAuditLog extends Equatable {
  final String id;
  final String actorUserId;
  final String actorRole;
  final String actionType;
  final String targetEntityType;
  final String targetEntityId;
  final String detail;
  final DateTime timestamp;

  const ContentAuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorRole,
    required this.actionType,
    required this.targetEntityType,
    required this.targetEntityId,
    required this.detail,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        actorUserId,
        actorRole,
        actionType,
        targetEntityType,
        targetEntityId,
        detail,
        timestamp,
      ];
}

class AdminContentOverview extends Equatable {
  final int totalQuestions;
  final int publishedQuestions;
  final int pendingVerificationQuestions;
  final int draftQuestions;
  final int totalPackages;

  const AdminContentOverview({
    required this.totalQuestions,
    required this.publishedQuestions,
    required this.pendingVerificationQuestions,
    required this.draftQuestions,
    required this.totalPackages,
  });

  @override
  List<Object?> get props => [
        totalQuestions,
        publishedQuestions,
        pendingVerificationQuestions,
        draftQuestions,
        totalPackages,
      ];
}
