class AppConfig {
  static const String _defaultSupabaseUrl =
      'https://gtxamoukdklnudhxgjhc.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_9QiR4QbOFYojwurQ_RSi5w_dhLBsQyW';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );
  static const String oauthRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'io.supabase.flutter://login-callback',
  );

  static bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
