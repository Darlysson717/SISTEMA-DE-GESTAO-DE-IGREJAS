import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_acesso_publicar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_anunciar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_detalhes_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_meus_eventos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('AnnounceEventPage', () {
    testWidgets('renderiza a primeira etapa do fluxo de publicação',
        (tester) async {
      await montarTela(tester, const AnnounceEventPage());

      expect(find.byType(AnnounceEventPage), findsOneWidget);
      expect(find.textContaining('Etapa 1'), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('EventDetailsPage', () {
    testWidgets('exibe as informações do evento recebido', (tester) async {
      final evento = eventoTeste();

      await montarTela(tester, EventDetailsPage(event: evento));

      expect(find.byType(EventDetailsPage), findsOneWidget);
      expect(find.textContaining(evento.nome, findRichText: true), findsWidgets);

      await desmontarTela(tester);
    });
  });

  group('MyEventsPage', () {
    testWidgets('renderiza com lista vazia de eventos', (tester) async {
      await montarTela(tester, const MyEventsPage());

      expect(find.text('Meus Eventos'), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('PublishEventAccessPage', () {
    testWidgets('renderiza a tela de solicitação de acesso', (tester) async {
      await montarTela(tester, const PublishEventAccessPage());

      expect(find.byType(PublishEventAccessPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
