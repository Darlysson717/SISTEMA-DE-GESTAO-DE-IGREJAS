import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/telas/pagina_painel_admin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('AdminPanelPage', () {
    testWidgets('renderiza o painel administrativo para admin', (tester) async {
      await montarTela(tester, const AdminPanelPage(), usuario: usuarioTeste());

      expect(find.byType(AdminPanelPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
