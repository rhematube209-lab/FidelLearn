import 'package:equatable/equatable.dart';

enum CoinTransactionType {
  credit,
  debit;

  static CoinTransactionType fromString(String val) {
    return val.toUpperCase() == 'DEBIT'
        ? CoinTransactionType.debit
        : CoinTransactionType.credit;
  }

  String toDbString() =>
      this == CoinTransactionType.credit ? 'CREDIT' : 'DEBIT';
}

/// An entry in the append-only Study Coin ledger.
///
/// **Important — Security Model:**
/// The [amount] field is used for local display and optimistic state only.
/// When a credit entry is synced to the server, only [eventType] and
/// [sourceEntityId] are sent to the `claim-reward` Edge Function.
/// The server determines the authoritative amount from server-controlled
/// reward rules. The client must never determine its own reward amount.
///
/// [serverVerified] is `false` for locally-created credit entries until the
/// server confirms the claim. It is always `true` for debit entries that
/// completed the `redeem-coins` Edge Function successfully.
class CoinLedgerEntry extends Equatable {
  final String id;
  final String userId;
  final CoinTransactionType transactionType;
  final int
      amount; // strictly positive integer; for credits, may be optimistic until serverVerified
  final String reason;
  final String? relatedEntityId;
  final String idempotencyKey;
  final DateTime createdAt;
  final bool serverVerified;

  /// For credit entries: the event type used to claim the reward server-side.
  /// Must match a key in the server's `reward_rules` table.
  /// Examples: 'exam_completed', 'daily_streak', 'challenge_completed'
  final String? eventType;

  /// For credit entries: the ID of the source entity (attempt UUID, date string, etc.)
  /// The server verifies this entity exists and belongs to the user before awarding.
  final String? sourceEntityId;

  const CoinLedgerEntry({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.reason,
    this.relatedEntityId,
    required this.idempotencyKey,
    required this.createdAt,
    this.serverVerified = true,
    this.eventType,
    this.sourceEntityId,
  }) : assert(
          amount > 0,
          'Ledger transaction amount must be strictly positive',
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_type': transactionType.toDbString(),
      'amount': amount,
      'reason': reason,
      'related_entity_id': relatedEntityId,
      'idempotency_key': idempotencyKey,
      'created_at': createdAt.toIso8601String(),
      'server_verified': serverVerified,
      if (eventType != null) 'event_type': eventType,
      if (sourceEntityId != null) 'source_entity_id': sourceEntityId,
    };
  }

  factory CoinLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CoinLedgerEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionType: CoinTransactionType.fromString(
        json['transaction_type'] as String,
      ),
      amount: json['amount'] as int,
      reason: json['reason'] as String,
      relatedEntityId: json['related_entity_id'] as String?,
      idempotencyKey: json['idempotency_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      serverVerified: json['server_verified'] as bool? ?? true,
      eventType: json['event_type'] as String?,
      sourceEntityId: json['source_entity_id'] as String?,
    );
  }

  CoinLedgerEntry copyWith({
    bool? serverVerified,
    int? amount,
  }) {
    return CoinLedgerEntry(
      id: id,
      userId: userId,
      transactionType: transactionType,
      amount: amount ?? this.amount,
      reason: reason,
      relatedEntityId: relatedEntityId,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      serverVerified: serverVerified ?? this.serverVerified,
      eventType: eventType,
      sourceEntityId: sourceEntityId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        transactionType,
        amount,
        reason,
        relatedEntityId,
        idempotencyKey,
        createdAt,
        serverVerified,
        eventType,
        sourceEntityId,
      ];
}
