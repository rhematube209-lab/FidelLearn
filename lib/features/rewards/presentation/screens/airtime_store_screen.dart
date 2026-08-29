import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/airtime_reward_models.dart';
import '../../domain/services/airtime_redemption_service.dart';
import '../../domain/services/coin_ledger_service.dart';

final airtimeRedemptionServiceProvider = Provider((ref) {
  return AirtimeRedemptionService();
});

class AirtimeStoreScreen extends ConsumerStatefulWidget {
  const AirtimeStoreScreen({super.key});

  @override
  ConsumerState<AirtimeStoreScreen> createState() => _AirtimeStoreScreenState();
}

class _AirtimeStoreScreenState extends ConsumerState<AirtimeStoreScreen> {
  TelecomProvider? _selectedProvider;

  void _redeemPackage(AirtimeRewardPackage pkg) {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final ledger = ref.read(coinLedgerProvider);
    final balance = CoinLedgerService.calculateBalance(ledger);

    if (balance < pkg.coinCost) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningOrange),
              SizedBox(width: 8),
              Text('Insufficient Study Coins'),
            ],
          ),
          content: Text(
            'You need ${pkg.coinCost} Study Coins to redeem ${pkg.title}. You currently have $balance coins.\n\nPractice exams with >80% accuracy to earn more coins!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Practicing'),
            ),
          ],
        ),
      );
      return;
    }

    final key = 'airtime_redeem_${pkg.id}_${DateTime.now().millisecondsSinceEpoch}';
    final service = ref.read(airtimeRedemptionServiceProvider);

    try {
      final receipt = service.redeemPackage(
        userId: user.id,
        phoneNumber: user.phoneNumber.isNotEmpty ? user.phoneNumber : '0911223344',
        package: pkg,
        currentLedger: ledger,
        idempotencyKey: key,
      );

      // Debit coins from ledger
      ref.read(coinLedgerProvider.notifier).spendCoins(
            userId: user.id,
            amount: pkg.coinCost,
            reason: 'Redeemed: ${pkg.title}',
            idempotencyKey: key,
          );

      _showReceiptDialog(receipt);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text('Redemption failed: $e'),
        ),
      );
    }
  }

  void _showReceiptDialog(RedemptionReceipt receipt) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen),
            SizedBox(width: 8),
            Text('Recharge Voucher Ready! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receipt.packageTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Coins Deducted: ${receipt.coinsSpent} Study Coins',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voucher PIN Code (14 Digits):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    receipt.voucherPinCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: receipt.voucherPinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voucher PIN copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quick Dial: ${receipt.ussdDialCode}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.infoBlue,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(coinLedgerProvider);
    final balance = CoinLedgerService.calculateBalance(ledger);
    final service = ref.watch(airtimeRedemptionServiceProvider);
    final allPackages = service.getCatalog();

    final filteredPackages = _selectedProvider == null
        ? allPackages
        : allPackages.where((p) => p.provider == _selectedProvider).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airtime & Data Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coin Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGold, AppTheme.accentGoldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$balance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Coins',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '10 Coins = 1 ETB',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Provider Filter Chips
            Row(
              children: [
                FilterChip(
                  label: const Text('All Providers'),
                  selected: _selectedProvider == null,
                  onSelected: (_) => setState(() => _selectedProvider = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ethio Telecom'),
                  selected: _selectedProvider == TelecomProvider.ethioTelecom,
                  onSelected: (_) => setState(
                    () => _selectedProvider = TelecomProvider.ethioTelecom,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Safaricom'),
                  selected: _selectedProvider == TelecomProvider.safaricom,
                  onSelected: (_) => setState(
                    () => _selectedProvider = TelecomProvider.safaricom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Reward Package:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Packages List
            ...filteredPackages.map((pkg) {
              final canAfford = balance >= pkg.coinCost;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pkg.provider == TelecomProvider.ethioTelecom
                              ? AppTheme.primaryGreen.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          pkg.bundleType == RewardBundleType.airtime
                              ? Icons.phone_android
                              : Icons.wifi,
                          color: pkg.provider == TelecomProvider.ethioTelecom
                              ? AppTheme.primaryGreen
                              : Colors.red,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${pkg.provider.displayName} • ${pkg.validityDays} Day${pkg.validityDays > 1 ? "s" : ""} Validity',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pkg.coinCost} Coins',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGoldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _redeemPackage(pkg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canAfford ? AppTheme.primaryGreen : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Redeem'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
