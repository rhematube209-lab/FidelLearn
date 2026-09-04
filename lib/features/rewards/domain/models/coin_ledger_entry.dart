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

class CoinLedgerEntry extends Equatable {
  final String id;
  final String userId;
  final CoinTransactionType transactionType;
  final int amount; // strictly positive integer
  final String reason;
  final String? relatedEntityId;
  final String idempotencyKey;
  final DateTime createdAt;
  final bool serverVerified;

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
      ];
}
