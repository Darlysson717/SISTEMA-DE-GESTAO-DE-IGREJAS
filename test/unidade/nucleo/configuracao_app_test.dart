import 'package:centro_social_app/src/nucleo/configuracao/configuracao_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('possui configuração padrão válida do Supabase', () {
      expect(AppConfig.hasValidSupabaseConfig, isTrue);
      expect(AppConfig.supabaseUrl, startsWith('https://'));
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
    });

    test('usa o esquema nativo como redirect padrão do OAuth', () {
      expect(
        AppConfig.oauthRedirectUrl,
        'io.supabase.flutter://login-callback',
      );
    });

    test('possui chave VAPID padrão para push na web', () {
      expect(AppConfig.fcmVapidKey, isNotEmpty);
    });
  });
}
