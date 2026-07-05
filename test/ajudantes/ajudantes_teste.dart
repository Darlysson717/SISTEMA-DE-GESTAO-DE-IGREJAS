import 'dart:convert';

import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'package:centro_social_app/src/funcionalidades/administracao/dados/repositorio_admin.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/repositorios/repositorio_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente HTTP falso: responde 200 com corpo vazio para qualquer requisição,
/// para que os repositórios reais (Postgrest) resolvam com listas vazias sem
/// tocar a rede.
class ClienteHttpFalso extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final corpo = request.url.path.contains('/rest/') ? '[]' : '{}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(corpo)),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}

bool _supabaseInicializado = false;

/// Inicializa o Supabase uma única vez com backend simulado.
///
/// Deve ser chamado no `setUpAll` de todo teste de tela, pois várias telas
/// acessam `Supabase.instance` diretamente.
Future<void> inicializarSupabaseDeTeste() async {
  if (_supabaseInicializado) {
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});
  GoogleFonts.config.allowRuntimeFetching = false;
  await Supabase.initialize(
    url: 'http://localhost:54321',
    anonKey: 'chave-anonima-de-teste',
    httpClient: ClienteHttpFalso(),
    debug: false,
  );
  _supabaseInicializado = true;
}

/// Usuário autenticado fictício para telas que recebem [AppUser].
AppUser usuarioTeste() => const AppUser(
      id: 'usuario-teste',
      email: 'teste@iadet.app',
      nome: 'Usuária de Teste',
    );

/// Serviço fictício para telas que recebem [Service].
Service servicoTeste() => const Service(
      id: 'servico-teste',
      userId: 'usuario-teste',
      nome: 'Aconselhamento Psicológico',
      categoria: 'Psicologia',
      nomeProfissional: 'Dra. Teste',
      descricao: 'Atendimento gratuito para a comunidade.',
      diasDisponiveis: ['segunda', 'quarta'],
      horarios: ['08:00', '09:00'],
      duracaoAtendimento: 60,
      tipoAtendimento: 'presencial',
      local: 'Sala 1',
      telefone: '98999990000',
      status: 'ativo',
    );

/// Evento fictício para telas que recebem [AppEvent].
AppEvent eventoTeste() => AppEvent(
      id: 'evento-teste',
      userId: 'usuario-teste',
      nome: 'Ação Social de Agosto',
      categoria: 'Ação Social',
      publicoAlvo: const ['Todos'],
      dataInicio: DateTime(2026, 8, 1),
      dataFim: DateTime(2026, 8, 1),
      horaInicio: '19:00',
      horaFim: '21:00',
      diaInteiro: false,
      repeticao: 'nenhuma',
      tipoLocal: 'presencial',
      endereco: 'Rua das Flores, 123',
      linkTransmissao: null,
      resumoCurto: 'Atendimentos gratuitos à comunidade.',
      descricao: 'Dia de atendimentos gratuitos com voluntários.',
      imagemCapaUrl: null,
      galeriaImagensUrls: const [],
      eventoPago: false,
      limiteVagas: null,
      requerInscricao: false,
      linkInscricao: null,
      permitirVoluntarios: true,
      quantidadeVoluntarios: 5,
      atividadesVoluntarios: null,
      acessibilidade: null,
      contatoNome: 'Equipe do Centro Social',
      contatoTelefone: '98999990000',
      contatoEmail: null,
      agendarPublicacao: false,
      publicadoEm: DateTime(2026, 7, 1),
      status: 'publicado',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

/// Overrides padrão: todos os providers que tocam rede/Realtime passam a
/// devolver dados vazios imediatamente, para que qualquer tela renderize
/// de forma determinística.
List<Override> sobrescritasPadrao({AppUser? usuario}) => [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(
          AuthState(AuthChangeEvent.initialSession, null),
        ),
      ),
      currentAppUserProvider.overrideWith((ref) async => usuario),
      // Agendamentos (evita conexões Realtime/websocket nos testes).
      professionalsProvider.overrideWith((ref) async => <Professional>[]),
      publishedServicesProvider.overrideWith((ref) async => <Service>[]),
      myServicesProvider.overrideWith((ref) async => <Service>[]),
      communityAppointmentsProvider
          .overrideWith((ref) => Stream.value(const <Appointment>[])),
      professionalTodayAppointmentsProvider
          .overrideWith((ref) => Stream.value(const <Appointment>[])),
      professionalAppointmentsProvider
          .overrideWith((ref) => Stream.value(const <Appointment>[])),
      allAppointmentsProvider
          .overrideWith((ref) => Stream.value(const <Appointment>[])),
      cancellationMessagesProvider
          .overrideWith((ref) async => <CancellationNotice>[]),
      // Ticker de minuto viraria timer pendente no teste; um valor único basta.
      appointmentsNowTickerProvider
          .overrideWith((ref) => Stream.value(DateTime(2026, 7, 1, 12))),
      // Eventos.
      myEventsProvider.overrideWith((ref) async => <AppEvent>[]),
      publishedEventsProvider.overrideWith((ref) async => <AppEvent>[]),
      eventRegistrationsProvider.overrideWith(
        (ref, eventId) async => <EventRegistrationEntry>[],
      ),
      eventRegistrationStatsProvider.overrideWith(
        (ref, eventId) async =>
            const EventRegistrationStats(participantes: 0, voluntarios: 0),
      ),
      // Administração.
      isCurrentUserAdminProvider.overrideWith((ref) async => true),
      isCurrentUserSuperAdminProvider.overrideWith((ref) => false),
      adminUsersProvider.overrideWith((ref) async => <AdminUser>[]),
      authenticatedUsersCountProvider.overrideWith((ref) async => 0),
      publishAccessStateProvider.overrideWith(
        (ref) async => const PublishAccessState(
          canPublish: false,
          latestRequest: null,
          wasRevoked: false,
          revokedAt: null,
        ),
      ),
      pendingPublishRequestsProvider
          .overrideWith((ref) async => <PublishRequest>[]),
      authorizedPublishersProvider
          .overrideWith((ref) async => <AuthorizedPublisher>[]),
      eventPublishAccessStateProvider.overrideWith(
        (ref) async => const EventPublishAccessState(
          canPublish: false,
          latestRequest: null,
          wasRevoked: false,
          revokedAt: null,
        ),
      ),
      pendingEventPublishRequestsProvider
          .overrideWith((ref) async => <EventPublishRequest>[]),
      eventAuthorizedPublishersProvider
          .overrideWith((ref) async => <EventAuthorizedPublisher>[]),
    ];

/// Monta [tela] dentro de `ProviderScope` + `MaterialApp` com os overrides
/// padrão, avança alguns frames (sem `pumpAndSettle`, que travaria com
/// timers de polling) e mantém as imagens de rede simuladas.
Future<void> montarTela(
  WidgetTester tester,
  Widget tela, {
  List<Override> extras = const [],
  AppUser? usuario,
}) async {
  await mockNetworkImagesFor(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...sobrescritasPadrao(usuario: usuario), ...extras],
        child: MaterialApp(home: tela),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}

/// Desmonta a árvore para liberar timers (polling) antes do fim do teste.
Future<void> desmontarTela(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}
