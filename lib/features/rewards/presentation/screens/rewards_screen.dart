import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/coin_ledger_entry.dart';
import '../../../payments/presentation/widgets/telebirr_checkout_modal.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _isWatchingAd = false;

  Future<void> _simulateRewardedAd() async {
    setState(() => _isWatchingAd = true);

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.ondemand_video,
                size: 48,
                color: AppTheme.accentGold,
              ),
              SizedBox(height: 16),
              Text(
                'Simulating Optional Rewarded Ad...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Zero intrusive ads during exams. Ads are 100% voluntary.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(color: AppTheme.accentGold),
            ],
          ),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pop(context); // close dialog
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        final key = 'ad_reward_${DateTime.now().millisecondsSinceEpoch}';
        ref
            .read(coinLedgerProvider.notifier)
            .awardCoins(
              userId: user.id,
              amount: 10,
              reason: 'Simulated Rewarded Sponsor Video',
              idempotencyKey: key,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('🎉 +10 Study Coins added to your ledger!'),
          ),
        );
      }
      setState(() => _isWatchingAd = false);
    }
  }

  void _spendOnBonusExam() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final key = 'bonus_exam_${DateTime.now().millisecondsSinceEpoch}';
      ref
          .read(coinLedgerProvider.notifier)
          .spendCoins(
            userId: user.id,
            amount: 20,
            reason: 'Unlocked 1x Premium Mock Exam Simulation',
            idempotencyKey: key,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('Unlocked bonus mock exam with 20 coins!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text(
            e
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Failure: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(coinLedgerProvider);
    final balance = ref.watch(coinLedgerProvider.notifier).balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Coins & Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Balance Hero Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGoldDark, AppTheme.accentGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Study Coins Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Append-Only Verified Ledger',
                    style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Earn Coins Section
            const Text(
              'Earn Study Coins',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentGold.withOpacity(0.12),
                  child: const Icon(
                    Icons.ondemand_video,
                    color: AppTheme.accentGold,
                  ),
                ),
                title: const Text(
                  'Optional Sponsored Video',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Earn +10 Coins (Simulated Gateway)'),
                trailing: ElevatedButton(
                  onPressed: _isWatchingAd ? null : _simulateRewardedAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGoldDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('Watch'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.warningOrange.withOpacity(0.12),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: AppTheme.warningOrange,
                  ),
                ),
                title: const Text(
                  'Maintain 7-Day Streak',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Reward: +50 Coins (2 days remaining)'),
                trailing: const Text(
                  '5/7',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Spend Coins Section
            const Text(
              'Spend Study Coins & Telecom Rewards',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppTheme.accentGold.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.accentGoldDark,
                  child: Icon(Icons.phone_android, color: Colors.white),
                ),
                title: const Text(
                  'Redeem Airtime & Data Vouchers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Ethio Telecom & Safaricom top-ups (25–100 ETB)',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: ElevatedButton(
                  onPressed: () => context.push('/airtime_store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGoldDark,
                  ),
                  child: const Text('Store'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                  child: const Icon(Icons.quiz, color: AppTheme.primaryGreen),
                ),
                title: const Text(
                  'Unlock Bonus Mock Exam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Cost: 20 Coins'),
                trailing: OutlinedButton(
                  onPressed: balance >= 20 ? _spendOnBonusExam : null,
                  child: const Text('Unlock'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.infoBlue.withOpacity(0.12),
                  child: const Icon(Icons.payment, color: AppTheme.infoBlue),
                ),
                title: const Text(
                  'Telebirr & CBE Birr Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Purchase Premium Offline Subject Pack (50 ETB)'),
                trailing: OutlinedButton(
                  onPressed: () {
                    TelebirrCheckoutModal.show(
                      context: context,
                      amountEtb: 50.0,
                      itemDescription: 'Grade 12 Complete STEM Subject Package',
                      onPaymentSuccess: () {
                        final user = ref.read(currentUserProvider).valueOrNull;
                        if (user != null) {
                          ref.read(coinLedgerProvider.notifier).awardCoins(
                                userId: user.id,
                                amount: 100,
                                reason: 'Telebirr Purchase Bonus: 100 Study Coins',
                                idempotencyKey: 'bonus_${DateTime.now().millisecondsSinceEpoch}',
                              );
                        }
                      },
                    );
                  },
                  child: const Text('Buy'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Ledger History
            const Text(
              'Transaction Ledger History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ledger.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = ledger[ledger.length - 1 - index];
                final isCredit =
                    entry.transactionType == CoinTransactionType.credit;
                return ListTile(
                  tileColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: Icon(
                    isCredit ? Icons.add_circle : Icons.remove_circle,
                    color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                  title: Text(
                    entry.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${entry.idempotencyKey.substring(0, 14)}...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  trailing: Text(
                    '${isCredit ? "+" : "-"}${entry.amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCredit
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
