import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_stat_card.dart';
import '../../../../core/widgets/sync_indicator_widget.dart';
import '../../../auth/domain/models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final currentTheme = ref.watch(themeModeProvider);
    final coinBalance = ref.watch(coinLedgerProvider.notifier).balance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile & Preferences',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Profile Header Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B0764), AppTheme.darkSurfaceStrong],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.4)),
                    boxShadow: AppTheme.cardShadowDark,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.brandStrong,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0]
                              : 'S',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.phoneNumber.isEmpty
                                  ? 'Offline Student Mode'
                                  : user.phoneNumber,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.darkTextSoft),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildHeaderTag(
                                    'Grade ${user.grade}', AppTheme.brand),
                                _buildHeaderTag(
                                    '${user.stream.toUpperCase()} STREAM',
                                    AppTheme.accent),
                                _buildHeaderTag(user.role.name.toUpperCase(),
                                    AppTheme.green),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Performance Dashboard Section
                _buildPerformanceDashboard(
                    context, coinBalance, isDesktop, isDark),
                const SizedBox(height: 28),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Settings: Curriculum & Preferences (50%)
                      Expanded(
                        flex: 50,
                        child: Column(
                          children: [
                            _buildCurriculumSettings(context, ref, user),
                            const SizedBox(height: 24),
                            _buildAppAppearanceCard(context, ref, currentTheme),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),

                      // Right Settings: Sync Engine & Security (50%)
                      Expanded(
                        flex: 50,
                        child: Column(
                          children: [
                            _buildSyncDiagnosticsCard(context),
                            const SizedBox(height: 24),
                            _buildAccountSecurityCard(context, ref),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildCurriculumSettings(context, ref, user),
                  const SizedBox(height: 20),
                  _buildAppAppearanceCard(context, ref, currentTheme),
                  const SizedBox(height: 20),
                  _buildSyncDiagnosticsCard(context),
                  const SizedBox(height: 20),
                  _buildAccountSecurityCard(context, ref),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculumSettings(
      BuildContext context, WidgetRef ref, UserProfile user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('National Examination Stream',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.school_rounded, color: AppTheme.brand),
            title: const Text('Grade Level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Grade ${user.grade} (National Curriculum)'),
            trailing: DropdownButton<int>(
              value: user.grade,
              items: const [
                DropdownMenuItem(value: 6, child: Text('Grade 6 (PSLCE)')),
                DropdownMenuItem(value: 8, child: Text('Grade 8 (Ministry)')),
                DropdownMenuItem(value: 12, child: Text('Grade 12 (ESSLCE)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(authRepositoryProvider)
                      .updateProfile(user.copyWith(grade: val));
                }
              },
            ),
          ),
          Divider(color: AppTheme.adaptiveBorder(context)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.science_rounded, color: AppTheme.accent),
            title: const Text('Academic Stream',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(user.stream == 'natural'
                ? 'Natural Science'
                : 'Social Science'),
            trailing: DropdownButton<String>(
              value: user.stream,
              items: const [
                DropdownMenuItem(
                    value: 'natural', child: Text('Natural Science')),
                DropdownMenuItem(
                    value: 'social', child: Text('Social Science')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(authRepositoryProvider)
                      .updateProfile(user.copyWith(stream: val));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppAppearanceCard(
      BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme & Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_rounded, color: AppTheme.pink),
                  SizedBox(width: 12),
                  Text('Color Palette',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.dark, label: Text('Cosmic')),
                  ButtonSegment(
                      value: ThemeMode.light, label: Text('Lavender')),
                ],
                selected: {currentTheme},
                onSelectionChanged: (set) {
                  ref.read(themeModeProvider.notifier).state = set.first;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDiagnosticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cloud Sync Diagnostics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SyncIndicatorWidget(isCompact: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'All exam attempts, mistake notes, and coin ledgers are preserved offline and automatically synced to Supabase PostgreSQL when internet connectivity is detected.',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.adaptiveMuted(context),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: const Text('Sign Out',
                style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.danger),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ==========================================
  // 📊 PERFORMANCE DASHBOARD
  // ==========================================
  Widget _buildPerformanceDashboard(
      BuildContext context, int coinBalance, bool isDesktop, bool isDark) {
    final cards = [
      FidelStatCard(
        title: 'Study Coins',
        value: '$coinBalance 🪙',
        subtitle: '10 Coins = 1 ETB (Telebirr)',
        icon: Icons.monetization_on_rounded,
        accentColor: AppTheme.accent,
        onTap: () => context.push('/rewards'),
      ),
      FidelStatCard(
        title: 'Daily Streak',
        value: '5 Days 🔥',
        subtitle: 'Freeze Shield Active',
        icon: Icons.local_fire_department_rounded,
        accentColor: AppTheme.pink,
        onTap: () => context.push('/rewards'),
      ),
      FidelStatCard(
        title: 'Exam Accuracy',
        value: '88.4%',
        subtitle: '100+ Questions Solved',
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppTheme.green,
        onTap: () => context.push('/progress'),
      ),
      FidelStatCard(
        title: 'Avg Pace',
        value: '42s / Q',
        subtitle: 'Top 5% National Speed',
        icon: Icons.speed_rounded,
        accentColor: AppTheme.brand,
        onTap: () => context.push('/progress'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.brand.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: AppTheme.brand, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Performance Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isDesktop)
          Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: c,
                      ),
                    ))
                .toList(),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 520 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: constraints.maxWidth > 520 ? 1.45 : 1.22,
                children: cards,
              );
            },
          ),
      ],
    );
  }
}
