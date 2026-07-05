import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/telas/pagina_portal_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/telas/tela_login.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('LoginScreen', () {
    testWidgets('renderiza sem erros e exibe a ação de entrar', (tester) async {
      await montarTela(tester, const LoginScreen());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Google', findRichText: true), findsWidgets);

      await desmontarTela(tester);
    });
  });

  group('AuthGatePage', () {
    testWidgets('sem sessão ativa, direciona para a tela de login',
        (tester) async {
      await montarTela(tester, const AuthGatePage());

      expect(find.byType(LoginScreen), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
