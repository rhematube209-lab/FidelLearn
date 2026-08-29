import '../../../../core/errors/failures.dart';
import '../models/coin_ledger_entry.dart';

class CoinLedgerService {
  CoinLedgerService._();

  /// Computes authoritative balance strictly by summing append-only ledger entries
  static int calculateBalance(List<CoinLedgerEntry> entries) {
    int balance = 0;
    for (final entry in entries) {
      if (entry.transactionType == CoinTransactionType.credit) {
        balance += entry.amount;
      } else {
        balance -= entry.amount;
      }
    }
    return balance < 0 ? 0 : balance;
  }

  /// Verifies whether a debit transaction is permitted without producing a negative balance
  static void validateDebitPermitted({
    required List<CoinLedgerEntry> currentLedger,
    required int debitAmount,
  }) {
    final currentBalance = calculateBalance(currentLedger);
    if (currentBalance < debitAmount) {
      throw InsufficientCoinsFailure(debitAmount, currentBalance);
    }
  }

  /// Verifies that an idempotency key has not already been used in the ledger
  static void validateIdempotency({
    required List<CoinLedgerEntry> currentLedger,
    required String idempotencyKey,
  }) {
    final exists = currentLedger.any((e) => e.idempotencyKey == idempotencyKey);
    if (exists) {
      throw const DuplicateRewardClaimFailure();
    }
  }
}
