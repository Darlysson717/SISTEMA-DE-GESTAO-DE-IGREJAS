import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agenda_diaria_voluntario.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agendamentos_admin.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agendamentos_usuario.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_detalhes_servico.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes/ajudantes_teste.dart';

void main() {
  setUpAll(inicializarSupabaseDeTeste);

  group('UserAppointmentsPage', () {
    testWidgets('renderiza sem agendamentos', (tester) async {
      await montarTela(tester, const UserAppointmentsPage());

      expect(find.byType(UserAppointmentsPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('AdminAppointmentsPage', () {
    testWidgets('renderiza o painel de agendamentos do admin', (tester) async {
      await montarTela(tester, const AdminAppointmentsPage());

      expect(find.byType(AdminAppointmentsPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });

  group('ServiceDetailsPage', () {
    testWidgets('exibe os detalhes do serviço recebido', (tester) async {
      final servico = servicoTeste();

      await montarTela(tester, ServiceDetailsPage(service: servico));

      expect(find.byType(ServiceDetailsPage), findsOneWidget);
      expect(
        find.textContaining(servico.nome, findRichText: true),
        findsWidgets,
      );

      await desmontarTela(tester);
    });
  });

  group('VolunteerDayAgendaPage', () {
    testWidgets('renderiza a agenda diária vazia', (tester) async {
      await montarTela(tester, const VolunteerDayAgendaPage());

      expect(find.byType(VolunteerDayAgendaPage), findsOneWidget);

      await desmontarTela(tester);
    });
  });
}
