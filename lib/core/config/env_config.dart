class EnvConfig {
  EnvConfig._();

  /// Supabase Project URL provided via --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dcaeknnpskynhgkdsfgb.supabase.co',
  );

  /// Supabase Public/Anon API key provided via --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjYWVrbm5wc2t5bmhna2RzZmdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwNzAxMzIsImV4cCI6MjEwMzY0NjEzMn0.2lkekdRRYW1IkasFNEQT5IQ2x85qY3rY9LgoXp2szOM',
  );

  /// Whether Supabase credentials have been configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
