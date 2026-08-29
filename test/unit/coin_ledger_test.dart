import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/errors/failures.dart';
import 'package:fidel_learn/features/rewards/domain/models/coin_ledger_entry.dart';
import 'package:fidel_learn/features/rewards/domain/services/coin_ledger_service.dart';

void main() {
  group('Study Coin Append-Only Ledger Tests', () {
    test('calculateBalance correctly aggregates credits and debits', () {
      final entries = [
        CoinLedgerEntry(
          id: '1',
          userId: 'u1',
          transactionType: CoinTransactionType.credit,
          amount: 50,
          reason: 'Signup Bonus',
          idempotencyKey: 'k1',
          createdAt: DateTime.now(),
        ),
        CoinLedgerEntry(
          id: '2',
          userId: 'u1',
          transactionType: CoinTransactionType.credit,
          amount: 15,
          reason: 'Daily Goal',
          idempotencyKey: 'k2',
          createdAt: DateTime.now(),
        ),
        CoinLedgerEntry(
          id: '3',
          userId: 'u1',
          transactionType: CoinTransactionType.debit,
          amount: 20,
          reason: 'Exam Unlock',
          idempotencyKey: 'k3',
          createdAt: DateTime.now(),
        ),
      ];

      // 50 + 15 - 20 = 45
      expect(CoinLedgerService.calculateBalance(entries), 45);
    });

    test(
      'validateDebitPermitted throws InsufficientCoinsFailure on overdraft',
      () {
        final entries = [
          CoinLedgerEntry(
            id: '1',
            userId: 'u1',
            transactionType: CoinTransactionType.credit,
            amount: 10,
            reason: 'Bonus',
            idempotencyKey: 'k1',
            createdAt: DateTime.now(),
          ),
        ];

        expect(
          () => CoinLedgerService.validateDebitPermitted(
            currentLedger: entries,
            debitAmount: 25,
          ),
          throwsA(isA<InsufficientCoinsFailure>()),
        );
      },
    );

    test('validateIdempotency prevents duplicate reward claims', () {
      final entries = [
        CoinLedgerEntry(
          id: '1',
          userId: 'u1',
          transactionType: CoinTransactionType.credit,
          amount: 10,
          reason: 'Streak Reward',
          idempotencyKey: 'streak_2026_08_21_u1',
          createdAt: DateTime.now(),
        ),
      ];

      // Unique key passes
      expect(
        () => CoinLedgerService.validateIdempotency(
          currentLedger: entries,
          idempotencyKey: 'streak_2026_08_22_u1',
        ),
        returnsNormally,
      );

      // Duplicate key throws DuplicateRewardClaimFailure
      expect(
        () => CoinLedgerService.validateIdempotency(
          currentLedger: entries,
          idempotencyKey: 'streak_2026_08_21_u1',
        ),
        throwsA(isA<DuplicateRewardClaimFailure>()),
      );
    });
  });
}
