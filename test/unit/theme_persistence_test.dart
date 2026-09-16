import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Persistence & Default Selection Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'defaults to Lavender (ThemeMode.light) when no saved preference exists',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final theme = container.read(themeModeProvider);
      expect(theme, ThemeMode.light,
          reason: 'Default theme must be Lavender (ThemeMode.light)');
    });

    test(
        'persists user selection of Cosmic (ThemeMode.dark) to SharedPreferences',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Initially Lavender
      expect(container.read(themeModeProvider), ThemeMode.light);

      // User selects Cosmic
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(ThemeModeNotifier.prefKey), 'dark');
    });

    test(
        'restores Cosmic (ThemeMode.dark) upon hard refresh when previously selected',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ThemeModeNotifier.prefKey, 'dark');

      // Simulates app restart / browser hard refresh
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final theme = container.read(themeModeProvider);
      expect(theme, ThemeMode.dark,
          reason:
              'Must restore Cosmic (ThemeMode.dark) from persistent storage');
    });

    test(
        'restores Lavender (ThemeMode.light) upon hard refresh when previously selected',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ThemeModeNotifier.prefKey, 'light');

      // Simulates app restart / browser hard refresh
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final theme = container.read(themeModeProvider);
      expect(theme, ThemeMode.light,
          reason:
              'Must restore Lavender (ThemeMode.light) from persistent storage');
    });
  });
}
