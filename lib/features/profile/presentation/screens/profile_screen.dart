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
        title: const Text('Student Profile & Settings'),
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
            // User Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0] : 'S',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber.isEmpty
                                ? 'Offline Guest'
                                : user.phoneNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Grade ${user.grade} • ${user.stream.toUpperCase()} • Role: ${user.role.name.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cloud & Offline Sync Section
            const Text(
              'Cloud & Offline Sync',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const SyncIndicatorWidget(isCompact: false),
            const SizedBox(height: 24),

            // Language & Theme Preferences
            const Text(
              'Preferences',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('App Language'),
                    subtitle: Text(
                      user.preferredLanguage == 'am'
                          ? 'አማርኛ (Amharic)'
                          : 'English',
                    ),
                    trailing: DropdownButton<String>(
                      value: user.preferredLanguage,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'am', child: Text('አማርኛ')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(currentUserProvider.notifier)
                              .updateProfile(
                                user.copyWith(preferredLanguage: val),
                              );
                          ref.read(localeProvider.notifier).state = Locale(val);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme Mode'),
                    subtitle: Text(
                      currentTheme == ThemeMode.dark
                          ? 'Dark Mode'
                          : 'Light Mode',
                    ),
                    trailing: Switch(
                      value: currentTheme == ThemeMode.dark,
                      activeTrackColor: AppTheme.primaryGreenLight,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Target Grade Level'),
                    subtitle: Text('Grade ${user.grade}'),
                    trailing: DropdownButton<int>(
                      value: user.grade,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 6,
                          child: Text('Grade 6 (PSLCE)'),
                        ),
                        DropdownMenuItem(
                          value: 8,
                          child: Text('Grade 8 (Ministry)'),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child: Text('Grade 12 (National)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          final stream = val == 12 ? (user.stream == 'general' ? 'natural' : user.stream) : 'general';
                          ref.read(currentUserProvider.notifier).updateProfile(
                                user.copyWith(grade: val, stream: stream),
                              );
                        }
                      },
                    ),
                  ),
                  if (user.grade == 12) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Grade 12 Stream'),
                      subtitle: Text(
                        user.stream == 'social'
                            ? 'Social Science (History, Geo, Econ)'
                            : 'Natural Science (Math, Phys, Chem, Bio)',
                      ),
                      trailing: DropdownButton<String>(
                        value: user.stream == 'social' ? 'social' : 'natural',
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'natural',
                            child: Text('Natural Science'),
                          ),
                          DropdownMenuItem(
                            value: 'social',
                            child: Text('Social Science'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(currentUserProvider.notifier).updateProfile(
                                  user.copyWith(stream: val),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Switcher for Testing (Teacher / School / Admin portals preview)
            const Text(
              'Role Mode (For Review & Testing)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Switch persona to preview role-based views:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Student'),
                          selected: user.role == UserRole.student,
                          onSelected: (_) {
                            ref
                                .read(currentUserProvider.notifier)
                                .updateProfile(
                                  user.copyWith(role: UserRole.student),
                                );
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Teacher'),
                          selected: user.role == UserRole.teacher,
                          onSelected: (_) {
                            ref
                                .read(currentUserProvider.notifier)
                                .updateProfile(
                                  user.copyWith(role: UserRole.teacher),
                                );
                          },
                        ),
                        ChoiceChip(
                          label: const Text('School Admin'),
                          selected: user.role == UserRole.schoolAdmin,
                          onSelected: (_) {
                            ref
                                .read(currentUserProvider.notifier)
                                .updateProfile(
                                  user.copyWith(role: UserRole.schoolAdmin),
                                );
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Platform Admin'),
                          selected: user.role == UserRole.platformAdmin,
                          onSelected: (_) {
                            ref
                                .read(currentUserProvider.notifier)
                                .updateProfile(
                                  user.copyWith(role: UserRole.platformAdmin),
                                );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Direct Portal Previews:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/teacher'),
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('Teacher Portal'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/school'),
                          icon: const Icon(Icons.account_balance, size: 16),
                          label: const Text('School Admin'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/admin'),
                          icon: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('Platform CMS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Log Out Button
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(currentUserProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/onboarding');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out & Clear Session'),
            ),
          ],
        ),
      ),
    );
  }
}
