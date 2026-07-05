import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_acesso_publicar_servico.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_meus_servicos.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_oferecer_servico.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_pacientes_servico.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('OfferServicePage', () {
    testWidgets('renderiza o formulário de oferta de serviço', (tester) async {
      await montarTela(tester, const OfferServicePage());

      expect(find.byType(OfferServicePage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('MyServicesPage', () {
    testWidgets('renderiza com lista vazia de serviços', (tester) async {
      await montarTela(tester, const MyServicesPage());

      expect(find.byType(MyServicesPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('ServicePatientsPage', () {
    testWidgets('renderiza a agenda de pacientes do serviço', (tester) async {
      await montarTela(tester, ServicePatientsPage(service: servicoTeste()));

      expect(find.text('Próximos Pacientes'), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('PublishServiceAccessPage', () {
    testWidgets('renderiza a tela de solicitação de acesso', (tester) async {
      await montarTela(tester, const PublishServiceAccessPage());

      expect(find.text('Publicar Serviço'), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
