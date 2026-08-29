import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_indicator_widget.dart';
import '../../../auth/domain/models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final currentTheme = ref.watch(themeModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

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
        title: const Text('Student Profile & Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          user.displayName.isNotEmpty ? user.displayName[0] : 'S',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.phoneNumber.isEmpty ? 'Offline Student Mode' : user.phoneNumber,
                              style: const TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brand.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                border: Border.all(color: AppTheme.brand.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Grade ${user.grade} • ${user.stream.toUpperCase()} STREAM • ${user.role.name.toUpperCase()}',
                                style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                            _buildAppAppearanceCard(ref, currentTheme),
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
                  _buildAppAppearanceCard(ref, currentTheme),
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

  Widget _buildCurriculumSettings(BuildContext context, WidgetRef ref, UserProfile user) {
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
          const Text('National Examination Stream', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.school_rounded, color: AppTheme.brand),
            title: const Text('Grade Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  ref.read(authRepositoryProvider).updateProfile(user.copyWith(grade: val));
                }
              },
            ),
          ),
          const Divider(color: AppTheme.darkBorder),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.science_rounded, color: AppTheme.accent),
            title: const Text('Academic Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(user.stream == 'natural' ? 'Natural Science' : 'Social Science'),
            trailing: DropdownButton<String>(
              value: user.stream,
              items: const [
                DropdownMenuItem(value: 'natural', child: Text('Natural Science')),
                DropdownMenuItem(value: 'social', child: Text('Social Science')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(authRepositoryProvider).updateProfile(user.copyWith(stream: val));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppAppearanceCard(WidgetRef ref, ThemeMode currentTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceStrong,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme & Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_rounded, color: AppTheme.pink),
                  SizedBox(width: 12),
                  Text('Color Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.dark, label: Text('Cosmic')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Lavender')),
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
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cloud Sync Diagnostics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SyncIndicatorWidget(isCompact: false),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'All exam attempts, mistake notes, and coin ledgers are preserved offline and automatically synced to Supabase PostgreSQL when internet connectivity is detected.',
            style: TextStyle(fontSize: 12, color: AppTheme.darkMuted, height: 1.4),
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
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.danger),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}
