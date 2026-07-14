// Configurações do aplicativo Centro Social da Igreja.
//
// Centraliza todas as constantes de configuração do sistema, incluindo:
// - URL e chave anônima do Supabase
// - URL de redirect para autenticação OAuth
//
// As configurações podem ser sobrescritas via variáveis de ambiente
// do compilador usando `--dart-define` no momento do build.
//
// Exemplo de uso:
// flutter run --dart-define=SUPABASE_URL=nova_url

import 'package:flutter/foundation.dart';

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
  /// Pode ser sobrescrita com `--dart-define=SUPABASE_REDIRECT_URL=...`.
  /// Na web, quando não houver override, usa a origem atual do navegador.
  /// Em mobile, mantém o deep link padrão do app.
  static String get oauthRedirectUrl {
    const override = String.fromEnvironment(
      'SUPABASE_REDIRECT_URL',
      defaultValue: '',
    );

    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return Uri.base.origin;
    }

    return 'io.supabase.flutter://login-callback';
  }

  /// Chave pública VAPID (Web Push certificates) do Firebase Cloud Messaging.
  ///
  /// Usada apenas na web para obter o token FCM. É informação pública,
  /// como a chave anônima do Supabase. Gere/copie em:
  /// Firebase Console > Project settings > Cloud Messaging >
  /// Web Push certificates > Generate key pair.
  static const String fcmVapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue:
        'BKt86SBAX7N7cgfybQi_Ro1tYOOaTDa7pZ_sHqLq_bifBok32FtTlgplQ3NfqlcdaJYoHkg_UxK8PB0XKZxb5cE',
  );

  /// Verifica se a configuração do Supabase é válida.
  ///
  /// Retorna `true` se ambas URL e chave anônima foram fornecidas.
  static bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}