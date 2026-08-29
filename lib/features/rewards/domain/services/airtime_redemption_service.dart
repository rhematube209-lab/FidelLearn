import 'dart:math';

import '../models/airtime_reward_models.dart';
import '../models/coin_ledger_entry.dart';
import 'coin_ledger_service.dart';

class AirtimeRedemptionService {
  final List<AirtimeRewardPackage> _catalog = const [
    AirtimeRewardPackage(
      id: 'pkg_ethio_airtime_25',
      title: '25 ETB Airtime Recharge',
      provider: TelecomProvider.ethioTelecom,
      bundleType: RewardBundleType.airtime,
      coinCost: 250,
      valueEtb: 25.0,
      validityDays: 30,
    ),
    AirtimeRewardPackage(
      id: 'pkg_ethio_data_1gb',
      title: '1 GB STEM Study Data Pack',
      provider: TelecomProvider.ethioTelecom,
      bundleType: RewardBundleType.dailyDataBundle,
      coinCost: 400,
      valueEtb: 40.0,
      dataVolumeMb: 1024,
      validityDays: 1,
    ),
    AirtimeRewardPackage(
      id: 'pkg_ethio_airtime_50',
      title: '50 ETB Airtime Recharge',
      provider: TelecomProvider.ethioTelecom,
      bundleType: RewardBundleType.airtime,
      coinCost: 500,
      valueEtb: 50.0,
      validityDays: 60,
    ),
    AirtimeRewardPackage(
      id: 'pkg_safaricom_data_1gb',
      title: '1.5 GB Safaricom Exam Data',
      provider: TelecomProvider.safaricom,
      bundleType: RewardBundleType.dailyDataBundle,
      coinCost: 450,
      valueEtb: 45.0,
      dataVolumeMb: 1536,
      validityDays: 1,
    ),
    AirtimeRewardPackage(
      id: 'pkg_ethio_data_3gb_week',
      title: '3 GB Weekly High-Yield Pack',
      provider: TelecomProvider.ethioTelecom,
      bundleType: RewardBundleType.weeklyDataBundle,
      coinCost: 1000,
      valueEtb: 100.0,
      dataVolumeMb: 3072,
      validityDays: 7,
    ),
  ];

  List<AirtimeRewardPackage> getCatalog() => List.unmodifiable(_catalog);

  String _generateVoucherPin() {
    final rand = Random();
    final p1 = (1000 + rand.nextInt(9000)).toString();
    final p2 = (1000 + rand.nextInt(9000)).toString();
    final p3 = (1000 + rand.nextInt(9000)).toString();
    final p4 = (10 + rand.nextInt(90)).toString();
    return '$p1$p2$p3$p4'; // 14-digit voucher
  }

  RedemptionReceipt redeemPackage({
    required String userId,
    required String phoneNumber,
    required AirtimeRewardPackage package,
    required List<CoinLedgerEntry> currentLedger,
    required String idempotencyKey,
  }) {
    // 1. Validate balance & idempotency using ledger rules
    CoinLedgerService.validateDebitPermitted(
      currentLedger: currentLedger,
      debitAmount: package.coinCost,
    );
    CoinLedgerService.validateIdempotency(
      currentLedger: currentLedger,
      idempotencyKey: idempotencyKey,
    );

    final voucher = _generateVoucherPin();
    final ussd = package.provider == TelecomProvider.ethioTelecom
        ? '*805*$voucher#'
        : '*705*$voucher#';

    return RedemptionReceipt(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      packageId: package.id,
      packageTitle: package.title,
      recipientPhone: phoneNumber,
      voucherPinCode: voucher,
      coinsSpent: package.coinCost,
      redeemedAt: DateTime.now(),
      ussdDialCode: ussd,
    );
  }
}
