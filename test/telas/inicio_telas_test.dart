import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/pagina_inicio.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/pagina_inicio_comunidade.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/pagina_inicio_voluntario.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/shell_inicio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('HomePage', () {
    testWidgets('renderiza a tela principal sem erros', (tester) async {
      await montarTela(
        tester,
        HomePage(currentUser: usuarioTeste()),
        usuario: usuarioTeste(),
      );

      expect(find.byType(HomePage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('CommunityHomePage', () {
    testWidgets('renderiza com usuário da comunidade', (tester) async {
      await montarTela(tester, CommunityHomePage(user: usuarioTeste()));

      expect(find.byType(CommunityHomePage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('VolunteerHomePage', () {
    testWidgets('renderiza com usuário voluntário', (tester) async {
      await montarTela(tester, VolunteerHomePage(user: usuarioTeste()));

      expect(find.byType(VolunteerHomePage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('HomeShell', () {
    testWidgets('renderiza título e ações informados', (tester) async {
      await montarTela(
        tester,
        HomeShell(
          user: usuarioTeste(),
          titulo: 'Título de Teste',
          actions: [HomeAction(label: 'Ação de Teste', onTap: () {})],
        ),
      );

      expect(find.text('Título de Teste'), findsOneWidget);
      expect(find.text('Ação de Teste'), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
