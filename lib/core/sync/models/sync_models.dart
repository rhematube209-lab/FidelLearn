import 'dart:convert';
import 'package:equatable/equatable.dart';

enum SyncOperationType {
  submitAttempt,
  toggleBookmark,
  recordMistake,
  appendCoinEntry,
  updateProfile;

  String get value {
    switch (this) {
      case SyncOperationType.submitAttempt:
        return 'SUBMIT_ATTEMPT';
      case SyncOperationType.toggleBookmark:
        return 'TOGGLE_BOOKMARK';
      case SyncOperationType.recordMistake:
        return 'RECORD_MISTAKE';
      case SyncOperationType.appendCoinEntry:
        return 'APPEND_COIN_ENTRY';
      case SyncOperationType.updateProfile:
        return 'UPDATE_PROFILE';
    }
  }

  static SyncOperationType fromString(String val) {
    switch (val) {
      case 'SUBMIT_ATTEMPT':
        return SyncOperationType.submitAttempt;
      case 'TOGGLE_BOOKMARK':
        return SyncOperationType.toggleBookmark;
      case 'RECORD_MISTAKE':
        return SyncOperationType.recordMistake;
      case 'APPEND_COIN_ENTRY':
        return SyncOperationType.appendCoinEntry;
      case 'UPDATE_PROFILE':
        return SyncOperationType.updateProfile;
      default:
        return SyncOperationType.submitAttempt;
    }
  }
}

enum SyncStatus {
  synced,
  syncing,
  offline,
  pending,
  error;

  String get labelEn {
    switch (this) {
      case SyncStatus.synced:
        return 'All changes synced';
      case SyncStatus.syncing:
        return 'Syncing changes...';
      case SyncStatus.offline:
        return 'Offline - Saved locally';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.error:
        return 'Sync error - Will retry';
    }
  }

  String get labelAm {
    switch (this) {
      case SyncStatus.synced:
        return 'ሁሉም መረጃዎች ተመሳስለዋል';
      case SyncStatus.syncing:
        return 'እየተመሳሰለ ነው...';
      case SyncStatus.offline:
        return 'ከመስመር ውጭ - በስልክዎ ተቀምጧል';
      case SyncStatus.pending:
        return 'ማመሳሰል ይጠበቃል';
      case SyncStatus.error:
        return 'የማመሳሰል ችግር - እንደገና ይሞከራል';
    }
  }
}

class SyncOperation extends Equatable {
  final String id;
  final SyncOperationType operationType;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final int retryCount;
  final DateTime nextRetryAt;
  final String? lastError;
  final DateTime createdAt;

  const SyncOperation({
    required this.id,
    required this.operationType,
    required this.payload,
    required this.idempotencyKey,
    this.retryCount = 0,
    required this.nextRetryAt,
    this.lastError,
    required this.createdAt,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      operationType: SyncOperationType.fromString(
        json['operation_type'] as String,
      ),
      payload: json['payload'] is String
          ? jsonDecode(json['payload'] as String) as Map<String, dynamic>
          : json['payload'] as Map<String, dynamic>,
      idempotencyKey: json['idempotency_key'] as String,
      retryCount: json['retry_count'] as int? ?? 0,
      nextRetryAt: DateTime.parse(json['next_retry_at'] as String),
      lastError: json['last_error'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType.value,
      'payload': payload,
      'idempotency_key': idempotencyKey,
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt.toIso8601String(),
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SyncOperation copyWith({
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastError,
  }) {
    return SyncOperation(
      id: id,
      operationType: operationType,
      payload: payload,
      idempotencyKey: idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operationType,
        payload,
        idempotencyKey,
        retryCount,
        nextRetryAt,
        lastError,
        createdAt,
      ];
}
