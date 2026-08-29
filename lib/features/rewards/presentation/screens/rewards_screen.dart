import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../payments/presentation/widgets/telebirr_checkout_modal.dart';
import '../../domain/models/coin_ledger_entry.dart';

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
        builder: (ctx) => AlertDialog(
          title: const Text('Voluntary Sponsor Reward'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ondemand_video_rounded, size: 48, color: AppTheme.accent),
              SizedBox(height: 16),
              Text(
                'Simulating Voluntary Sponsor Video...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Zero ads during exam sessions. Rewarded videos are 100% voluntary.',
                style: TextStyle(fontSize: 12, color: AppTheme.darkMuted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pop(context);
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        final key = 'ad_reward_${DateTime.now().millisecondsSinceEpoch}';
        ref.read(coinLedgerProvider.notifier).awardCoins(
              userId: user.id,
              amount: 10,
              reason: 'Simulated Rewarded Sponsor Video',
              idempotencyKey: key,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.green,
            content: Text('🎉 +10 Study Coins credited to your immutable ledger!'),
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
      ref.read(coinLedgerProvider.notifier).spendCoins(
            userId: user.id,
            amount: 20,
            reason: 'Unlocked 1x Premium Mock Exam Simulation',
            idempotencyKey: key,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.green,
          content: Text('Unlocked 1x Full National Exam Simulation!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.danger, content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final ledger = ref.watch(coinLedgerProvider);
    final coinBalance = ref.watch(coinLedgerProvider.notifier).balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Coins & Rewards Vault', style: TextStyle(fontWeight: FontWeight.bold)),
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
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Vault Balance Card & Ledger (48%)
                      Expanded(
                        flex: 48,
                        child: Column(
                          children: [
                            _buildVaultCard(coinBalance),
                            const SizedBox(height: 24),
                            _buildTransactionLedgerCard(ledger),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),

                      // Right Column: Airtime Store & Daily Quests (52%)
                      Expanded(
                        flex: 52,
                        child: Column(
                          children: [
                            _buildAirtimeStoreBanner(context),
                            const SizedBox(height: 24),
                            _buildDailyQuestsCard(),
                            const SizedBox(height: 24),
                            _buildVoluntarySponsorCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildVaultCard(coinBalance),
                  const SizedBox(height: 20),
                  _buildAirtimeStoreBanner(context),
                  const SizedBox(height: 20),
                  _buildDailyQuestsCard(),
                  const SizedBox(height: 20),
                  _buildVoluntarySponsorCard(),
                  const SizedBox(height: 20),
                  _buildTransactionLedgerCard(ledger),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaultCard(int coinBalance) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78350F), AppTheme.darkSurfaceStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
        boxShadow: AppTheme.cardShadowDark,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified Balance', style: TextStyle(fontSize: 13, color: AppTheme.darkMuted)),
                  Text('Study Coin Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                ),
                child: const Text(
                  'APPEND-ONLY LEDGER',
                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded, size: 44, color: AppTheme.accent),
              const SizedBox(width: 12),
              Text(
                '$coinBalance',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ${(coinBalance / 10).toStringAsFixed(1)} ETB Airtime / Telebirr Value',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/airtime_store'),
                  icon: const Icon(Icons.phone_android_rounded, size: 18),
                  label: const Text('Redeem Airtime'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const TelebirrCheckoutModal(
                        packageId: 'pkg_coins_100',
                        packageName: '100 Study Coins Booster',
                        priceEtb: 10.0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('Telebirr Top-Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAirtimeStoreBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), AppTheme.darkSurfaceStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.green.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ETHIO TELECOM & SAFARICOM', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(height: 8),
                const Text('Instant Mobile Recharge Vouchers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Redeem 10 ETB, 25 ETB, and 50 ETB vouchers directly into your phone with 0 delay.', style: TextStyle(fontSize: 12, color: AppTheme.darkTextSoft)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => context.push('/airtime_store'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green, foregroundColor: Colors.black),
            child: const Text('Open Store →'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Goal & Streak Quests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildQuestRow('Complete 20 Exam Questions', '15 / 20 items', 0.75, '+10 Coins'),
          const SizedBox(height: 14),
          _buildQuestRow('Score ≥ 80% on a Mock Exam', 'Completed ✅', 1.0, '+25 Coins'),
          const SizedBox(height: 14),
          _buildQuestRow('Maintain 5-Day Study Streak', '5 / 5 Days 🔥', 1.0, '+50 Coins'),
        ],
      ),
    );
  }

  Widget _buildQuestRow(String title, String progressText, double progress, String reward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(reward, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0x1AFFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppTheme.green : AppTheme.brand),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildVoluntarySponsorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voluntary Sponsor Boost', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Watch a 15s educational partner video for +10 Coins.', style: TextStyle(fontSize: 12, color: AppTheme.darkMuted)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isWatchingAd ? null : _simulateRewardedAd,
            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
            label: const Text('+10 Coins'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandStrong),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionLedgerCard(List<CoinLedgerEntry> ledger) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Immutable Ledger Audit Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (ledger.isEmpty)
            const Text('No transactions recorded yet.', style: TextStyle(fontSize: 12, color: AppTheme.darkMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ledger.length > 5 ? 5 : ledger.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 16),
              itemBuilder: (context, index) {
                final entry = ledger[index];
                final isCredit = entry.amount > 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, "0")} • TX ID: ${entry.id.substring(0, 8)}...', style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
                      ],
                    ),
                    Text(
                      '${isCredit ? "+" : ""}${entry.amount} 🪙',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCredit ? AppTheme.green : AppTheme.danger,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
