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
              Icon(Icons.info_outline_rounded, color: AppTheme.accent),
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
          backgroundColor: AppTheme.danger,
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
            Icon(Icons.check_circle_rounded, color: AppTheme.green),
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
              style: const TextStyle(fontSize: 13, color: AppTheme.darkMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voucher PIN Code (14 Digits):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.brand),
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
                      color: AppTheme.brand,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
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
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandStrong),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final ledger = ref.watch(coinLedgerProvider);
    final balance = CoinLedgerService.calculateBalance(ledger);
    final service = ref.watch(airtimeRedemptionServiceProvider);
    final allPackages = service.getCatalog();

    final filteredPackages = _selectedProvider == null
        ? allPackages
        : allPackages.where((p) => p.provider == _selectedProvider).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telecom Airtime & Data Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 20.0,
          vertical: 28.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Coin Balance Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF78350F), AppTheme.darkSurfaceStrong],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Study Coins Balance', style: TextStyle(fontSize: 13, color: AppTheme.darkMuted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: AppTheme.accent, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                '$balance Coins',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.accent),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.green.withOpacity(0.4)),
                        ),
                        child: Text(
                          '≈ ${(balance / 10).toStringAsFixed(0)} ETB RECHARGE POWER',
                          style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Provider Filters
                Row(
                  children: [
                    _buildProviderFilterChip('All Telecom Providers', null),
                    const SizedBox(width: 10),
                    _buildProviderFilterChip('Ethio Telecom 🇪🇹', TelecomProvider.ethioTelecom),
                    const SizedBox(width: 10),
                    _buildProviderFilterChip('Safaricom Ethiopia 🟢', TelecomProvider.safaricom),
                  ],
                ),
                const SizedBox(height: 20),

                // Package Cards Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isDesktop ? 380 : 500,
                    mainAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = filteredPackages[index];
                    final canAfford = balance >= pkg.coinCost;
                    final isEthio = pkg.provider == TelecomProvider.ethioTelecom;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isEthio ? AppTheme.brand.withOpacity(0.3) : AppTheme.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isEthio ? AppTheme.brand : AppTheme.green).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isEthio ? 'ETHIO TELECOM' : 'SAFARICOM',
                                  style: TextStyle(
                                    color: isEthio ? AppTheme.brand : AppTheme.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${pkg.birrAmount} ETB Airtime',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            pkg.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            pkg.description,
                            style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pkg.coinCost} Coins',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 15),
                              ),
                              ElevatedButton(
                                onPressed: () => _redeemPackage(pkg),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford ? AppTheme.brandStrong : const Color(0x1FFFFFFF),
                                  foregroundColor: canAfford ? Colors.white : AppTheme.darkMuted,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: Text(canAfford ? 'Redeem PIN' : 'Need Coins'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderFilterChip(String label, TelecomProvider? provider) {
    final isSelected = _selectedProvider == provider;
    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandStrong.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: isSelected ? AppTheme.brand : AppTheme.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.brand : AppTheme.darkTextSoft,
          ),
        ),
      ),
    );
  }
}
