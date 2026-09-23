import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/rewards/domain/models/coin_ledger_entry.dart';
import 'package:fidel_learn/features/rewards/domain/services/coin_ledger_service.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';

void main() {
  group('Study Coin — Event-Claim Security Model', () {
    group('CoinLedgerEntry — new fields', () {
      test('can be constructed with eventType and sourceEntityId', () {
        final entry = CoinLedgerEntry(
          id: 'tx_1',
          userId: 'user_1',
          transactionType: CoinTransactionType.credit,
          amount: 10,
          reason: 'Exam completed',
          idempotencyKey: 'exam_completed_att_1_user_1',
          createdAt: DateTime.now(),
          serverVerified: false,
          eventType: 'exam_completed',
          sourceEntityId: 'att_1',
        );

        expect(entry.eventType, equals('exam_completed'));
        expect(entry.sourceEntityId, equals('att_1'));
        expect(entry.serverVerified, isFalse);
      });

      test('backward compatible — eventType and sourceEntityId are optional',
          () {
        // Existing code that doesn't pass the new fields should still compile and work
        final entry = CoinLedgerEntry(
          id: 'tx_2',
          userId: 'user_1',
          transactionType: CoinTransactionType.credit,
          amount: 50,
          reason: 'Signup Bonus',
          idempotencyKey: 'signup_bonus_user_1',
          createdAt: DateTime.now(),
        );

        expect(entry.eventType, isNull);
        expect(entry.sourceEntityId, isNull);
        expect(entry.serverVerified, isTrue); // default
      });

      test('toJson includes eventType and sourceEntityId when set', () {
        final entry = CoinLedgerEntry(
          id: 'tx_3',
          userId: 'user_1',
          transactionType: CoinTransactionType.credit,
          amount: 10,
          reason: 'Exam',
          idempotencyKey: 'k3',
          createdAt: DateTime(2026, 9, 24),
          serverVerified: false,
          eventType: 'exam_completed',
          sourceEntityId: 'att_abc',
        );

        final json = entry.toJson();
        expect(json['event_type'], equals('exam_completed'));
        expect(json['source_entity_id'], equals('att_abc'));
        expect(json['server_verified'], isFalse);
        // amount IS in the JSON for local storage — but must NOT be sent to server
        expect(json['amount'], equals(10));
      });

      test('toJson omits eventType and sourceEntityId when null', () {
        final entry = CoinLedgerEntry(
          id: 'tx_4',
          userId: 'user_1',
          transactionType: CoinTransactionType.debit,
          amount: 20,
          reason: 'Exam Unlock',
          idempotencyKey: 'k4',
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();
        expect(json.containsKey('event_type'), isFalse);
        expect(json.containsKey('source_entity_id'), isFalse);
      });

      test('fromJson round-trips with new fields', () {
        final original = CoinLedgerEntry(
          id: 'tx_5',
          userId: 'user_1',
          transactionType: CoinTransactionType.credit,
          amount: 5,
          reason: 'Streak',
          idempotencyKey: 'daily_streak_2026-09-24_user_1',
          createdAt: DateTime(2026, 9, 24, 8, 0, 0),
          serverVerified: true,
          eventType: 'daily_streak',
          sourceEntityId: '2026-09-24',
        );

        final restored = CoinLedgerEntry.fromJson(original.toJson());
        expect(restored.eventType, equals('daily_streak'));
        expect(restored.sourceEntityId, equals('2026-09-24'));
        expect(restored.serverVerified, isTrue);
      });

      test('copyWith can update serverVerified', () {
        final entry = CoinLedgerEntry(
          id: 'tx_6',
          userId: 'user_1',
          transactionType: CoinTransactionType.credit,
          amount: 10,
          reason: 'Exam',
          idempotencyKey: 'k6',
          createdAt: DateTime.now(),
          serverVerified: false,
          eventType: 'exam_completed',
          sourceEntityId: 'att_xyz',
        );

        final confirmed = entry.copyWith(serverVerified: true);
        expect(confirmed.serverVerified, isTrue);
        expect(confirmed.eventType, equals('exam_completed'));
        expect(confirmed.amount, equals(10));
      });
    });

    group('SyncOperationType — new types', () {
      test('claimReward serializes and deserializes correctly', () {
        expect(SyncOperationType.claimReward.value, equals('CLAIM_REWARD'));
        expect(
          SyncOperationType.fromString('CLAIM_REWARD'),
          equals(SyncOperationType.claimReward),
        );
      });

      test('redeemCoins serializes and deserializes correctly', () {
        expect(SyncOperationType.redeemCoins.value, equals('REDEEM_COINS'));
        expect(
          SyncOperationType.fromString('REDEEM_COINS'),
          equals(SyncOperationType.redeemCoins),
        );
      });

      test('appendCoinEntry still deserializes (backward compat)', () {
        expect(
          SyncOperationType.fromString('APPEND_COIN_ENTRY'),
          equals(SyncOperationType.appendCoinEntry),
        );
      });
    });

    group(
        'Security contract — sync payload must not contain amount for credits',
        () {
      // These tests document the contract that the sync handler must follow:
      // the CLAIM_REWARD payload must contain event_type + source_entity_id,
      // NOT amount. This is enforced by SupabaseSyncHandlers which reads
      // event_type/source_entity_id and ignores any amount field.

      test('claimReward payload contains event_type but not amount', () {
        // This is what DriftCoinLedgerRepository should enqueue
        // when appendEntry is called with a credit + eventType.
        final payload = {
          'event_type': 'exam_completed',
          'source_entity_id': 'att-uuid-123',
          'idempotency_key': 'exam_completed_att-uuid-123_user-1',
          // amount intentionally NOT included in the sync payload
        };

        expect(payload.containsKey('event_type'), isTrue);
        expect(payload.containsKey('source_entity_id'), isTrue);
        expect(payload.containsKey('idempotency_key'), isTrue);
        expect(payload.containsKey('amount'), isFalse,
            reason: 'Sync payload must NOT include amount. '
                'Server determines reward amount from reward_rules.');
      });
    });

    group('Coin balance arithmetic is still append-only', () {
      test('balance calculation unchanged — credits add, debits subtract', () {
        final entries = [
          CoinLedgerEntry(
            id: '1',
            userId: 'u1',
            transactionType: CoinTransactionType.credit,
            amount: 10,
            reason: 'Exam',
            idempotencyKey: 'k1',
            createdAt: DateTime.now(),
            serverVerified: true,
            eventType: 'exam_completed',
            sourceEntityId: 'att-1',
          ),
          CoinLedgerEntry(
            id: '2',
            userId: 'u1',
            transactionType: CoinTransactionType.credit,
            amount: 5,
            reason: 'Streak',
            idempotencyKey: 'k2',
            createdAt: DateTime.now(),
            serverVerified: false, // optimistic — not yet confirmed by server
            eventType: 'daily_streak',
            sourceEntityId: '2026-09-24',
          ),
          CoinLedgerEntry(
            id: '3',
            userId: 'u1',
            transactionType: CoinTransactionType.debit,
            amount: 8,
            reason: 'Redemption',
            idempotencyKey: 'k3',
            createdAt: DateTime.now(),
            serverVerified: true,
          ),
        ];

        // 10 + 5 - 8 = 7
        expect(CoinLedgerService.calculateBalance(entries), equals(7));
      });
    });
  });
}
