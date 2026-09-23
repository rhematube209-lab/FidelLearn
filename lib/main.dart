import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences initialization failed: $e');
  }

  // requireSupabase:
  //   development → returns false if credentials missing (offline/mock mode)
  //   staging/production → throws StateError if credentials missing (fail closed)
  bool supabaseReady = false;
  try {
    supabaseReady = EnvConfig.requireSupabase;
  } on StateError catch (e) {
    // In staging/production this is unrecoverable — rethrow to crash loudly
    // so CI/CD and on-call teams see the misconfiguration immediately.
    debugPrint(e.message);
    rethrow;
  }

  if (supabaseReady) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabasePublishableKey,
      );
    } catch (e) {
      if (!EnvConfig.isDevelopment) {
        // Never silently swallow Supabase init failures in staging/production.
        debugPrint('Supabase initialization failed: $e');
        rethrow;
      }
      debugPrint('Supabase initialization failed (dev offline mode): $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FidelLearnApp(),
    ),
  );
}
