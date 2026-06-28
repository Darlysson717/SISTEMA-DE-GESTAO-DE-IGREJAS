/// Configurações do aplicativo Centro Social da Igreja.
///
/// Centraliza todas as constantes de configuração do sistema, incluindo:
/// - URL e chave anônima do Supabase
/// - URL de redirect para autenticação OAuth
///
/// As configurações podem ser sobrescritas via variáveis de ambiente
/// do compilador usando `--dart-define` no momento do build.
///
/// Exemplo de uso:
/// ```dart
/// flutter run --dart-define=SUPABASE_URL=nova_url
/// ```
class AppConfig {
  /// URL padrão do projeto Supabase.
  static const String _defaultSupabaseUrl =
      'https://gtxamoukdklnudhxgjhc.supabase.co';

  /// Chave anônima (publishable) padrão do Supabase.
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_9QiR4QbOFYojwurQ_RSi5w_dhLBsQyW';

  /// URL do backend Supabase (pode ser sobrescrita via --dart-define).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );

  /// Chave anônima do Supabase (pode ser sobrescrita via --dart-define).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );

  /// URL de callback para o fluxo de autenticação OAuth (PKCE).
  ///
  /// Deve corresponder ao esquema configurado no Supabase Dashboard
  /// em Authentication > URL Configuration > Redirect URLs.
  static const String oauthRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'io.supabase.flutter://login-callback',
  );

  /// Verifica se a configuração do Supabase é válida.
  ///
  /// Retorna `true` se ambas URL e chave anônima foram fornecidas.
  static bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}