import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/telas/pagina_perfil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('ProfilePage', () {
    testWidgets('renderiza os dados do usuário', (tester) async {
      final usuario = usuarioTeste();

      await montarTela(
        tester,
        ProfilePage(user: usuario),
        usuario: usuario,
      );

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(
        find.textContaining(usuario.nome!, findRichText: true),
        findsWidgets,
      );

      await desmontarTela(tester);
    });
  });
}
