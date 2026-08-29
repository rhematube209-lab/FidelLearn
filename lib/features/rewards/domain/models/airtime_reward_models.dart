import 'package:equatable/equatable.dart';

enum TelecomProvider {
  ethioTelecom,
  safaricom;

  String get displayName {
    switch (this) {
      case TelecomProvider.ethioTelecom:
        return 'Ethio Telecom';
      case TelecomProvider.safaricom:
        return 'Safaricom Ethiopia';
    }
  }
}

enum RewardBundleType {
  airtime,
  dailyDataBundle,
  weeklyDataBundle,
  monthlyDataBundle;

  String get displayName {
    switch (this) {
      case RewardBundleType.airtime:
        return 'Airtime Recharge';
      case RewardBundleType.dailyDataBundle:
        return '1-Day Study Data';
      case RewardBundleType.weeklyDataBundle:
        return '7-Day STEM Data';
      case RewardBundleType.monthlyDataBundle:
        return '30-Day Exam Pass';
    }
  }
}

class AirtimeRewardPackage extends Equatable {
  final String id;
  final String title;
  final TelecomProvider provider;
  final RewardBundleType bundleType;
  final int coinCost;
  final double valueEtb;
  final int? dataVolumeMb;
  final int validityDays;

  const AirtimeRewardPackage({
    required this.id,
    required this.title,
    required this.provider,
    required this.bundleType,
    required this.coinCost,
    required this.valueEtb,
    this.dataVolumeMb,
    required this.validityDays,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        provider,
        bundleType,
        coinCost,
        valueEtb,
        dataVolumeMb,
        validityDays,
      ];
}

class RedemptionReceipt extends Equatable {
  final String id;
  final String packageId;
  final String packageTitle;
  final String recipientPhone;
  final String voucherPinCode;
  final int coinsSpent;
  final DateTime redeemedAt;
  final String ussdDialCode;

  const RedemptionReceipt({
    required this.id,
    required this.packageId,
    required this.packageTitle,
    required this.recipientPhone,
    required this.voucherPinCode,
    required this.coinsSpent,
    required this.redeemedAt,
    required this.ussdDialCode,
  });

  @override
  List<Object?> get props => [
        id,
        packageId,
        packageTitle,
        recipientPhone,
        voucherPinCode,
        coinsSpent,
        redeemedAt,
        ussdDialCode,
      ];
}
