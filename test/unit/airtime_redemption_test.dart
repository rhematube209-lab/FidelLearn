import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/errors/failures.dart';
import 'package:fidel_learn/features/rewards/domain/models/airtime_reward_models.dart';
import 'package:fidel_learn/features/rewards/domain/models/coin_ledger_entry.dart';
import 'package:fidel_learn/features/rewards/domain/services/airtime_redemption_service.dart';

void main() {
  group('AirtimeRedemptionService Tests', () {
    late AirtimeRedemptionService service;

    setUp(() {
      service = AirtimeRedemptionService();
    });

    const testPackage = AirtimeRewardPackage(
      id: 'pkg_ethio_airtime_25',
      title: '25 ETB Airtime Recharge',
      provider: TelecomProvider.ethioTelecom,
      bundleType: RewardBundleType.airtime,
      coinCost: 250,
      valueEtb: 25.0,
      validityDays: 30,
    );

    final sufficientLedger = [
      CoinLedgerEntry(
        id: 'tx_1',
        userId: 'usr_student_1',
        transactionType: CoinTransactionType.credit,
        amount: 500,
        reason: 'Exam Master Reward',
        idempotencyKey: 'key_1',
        createdAt: DateTime.now(),
      ),
    ];

    final insufficientLedger = [
      CoinLedgerEntry(
        id: 'tx_1',
        userId: 'usr_student_1',
        transactionType: CoinTransactionType.credit,
        amount: 100, // < 250 cost
        reason: 'Daily Practice',
        idempotencyKey: 'key_1',
        createdAt: DateTime.now(),
      ),
    ];

    test('retrieves available telecom reward packages from catalog', () {
      final catalog = service.getCatalog();
      expect(catalog.isNotEmpty, isTrue);
      expect(catalog.any((p) => p.provider == TelecomProvider.ethioTelecom), isTrue);
      expect(catalog.any((p) => p.provider == TelecomProvider.safaricom), isTrue);
    });

    test('throws InsufficientCoinsFailure if user coin balance is less than package cost', () {
      expect(
        () => service.redeemPackage(
          userId: 'usr_student_1',
          phoneNumber: '0911223344',
          package: testPackage,
          currentLedger: insufficientLedger,
          idempotencyKey: 'redeem_tx_1',
        ),
        throwsA(isA<InsufficientCoinsFailure>()),
      );
    });

    test('throws DuplicateRewardClaimFailure if idempotency key already exists in ledger', () {
      final ledgerWithDuplicate = [
        ...sufficientLedger,
        CoinLedgerEntry(
          id: 'tx_2',
          userId: 'usr_student_1',
          transactionType: CoinTransactionType.debit,
          amount: 250,
          reason: 'Airtime',
          idempotencyKey: 'existing_key_123',
          createdAt: DateTime.now(),
        ),
      ];

      expect(
        () => service.redeemPackage(
          userId: 'usr_student_1',
          phoneNumber: '0911223344',
          package: testPackage,
          currentLedger: ledgerWithDuplicate,
          idempotencyKey: 'existing_key_123',
        ),
        throwsA(isA<DuplicateRewardClaimFailure>()),
      );
    });

    test('successfully processes redemption and generates 14-digit voucher with USSD dial string', () {
      final receipt = service.redeemPackage(
        userId: 'usr_student_1',
        phoneNumber: '0911223344',
        package: testPackage,
        currentLedger: sufficientLedger,
        idempotencyKey: 'unique_redeem_key_1',
      );

      expect(receipt.packageId, testPackage.id);
      expect(receipt.coinsSpent, 250);
      expect(receipt.voucherPinCode.length, 14);
      expect(int.tryParse(receipt.voucherPinCode), isNotNull);
      expect(receipt.ussdDialCode, startsWith('*805*'));
      expect(receipt.ussdDialCode, endsWith('#'));
    });
  });
}
