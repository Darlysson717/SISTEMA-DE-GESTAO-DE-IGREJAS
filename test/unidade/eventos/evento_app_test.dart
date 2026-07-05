import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON apenas com os campos obrigatórios (não anuláveis no banco).
Map<String, dynamic> _jsonMinimo() => {
      'id': 'evento-1',
      'user_id': 'usuario-1',
      'data_inicio': '2026-08-01',
      'data_fim': '2026-08-01',
      'created_at': '2026-07-01T10:00:00.000Z',
      'updated_at': '2026-07-01T10:00:00.000Z',
    };

AppEvent _eventoDe(Map<String, dynamic> json) => AppEvent.fromJson(json);

void main() {
  group('AppEvent.fromJson', () {
    test('aplica os valores padrão quando os campos estão ausentes', () {
      final evento = _eventoDe(_jsonMinimo());

      expect(evento.id, 'evento-1');
      expect(evento.userId, 'usuario-1');
      expect(evento.nome, '');
      expect(evento.categoria, '');
      expect(evento.publicoAlvo, isEmpty);
      expect(evento.dataInicio, DateTime(2026, 8, 1));
      expect(evento.dataFim, DateTime(2026, 8, 1));
      expect(evento.horaInicio, isNull);
      expect(evento.horaFim, isNull);
      expect(evento.diaInteiro, isFalse);
      expect(evento.repeticao, 'sem_repeticao');
      expect(evento.tipoLocal, 'presencial');
      expect(evento.endereco, isNull);
      expect(evento.linkTransmissao, isNull);
      expect(evento.resumoCurto, '');
      expect(evento.descricao, '');
      expect(evento.imagemCapaUrl, isNull);
      expect(evento.galeriaImagensUrls, isEmpty);
      expect(evento.eventoPago, isFalse);
      expect(evento.limiteVagas, isNull);
      expect(evento.requerInscricao, isFalse);
      expect(evento.linkInscricao, isNull);
      expect(evento.permitirVoluntarios, isFalse);
      expect(evento.quantidadeVoluntarios, isNull);
      expect(evento.atividadesVoluntarios, isNull);
      expect(evento.acessibilidade, isNull);
      expect(evento.contatoNome, '');
      expect(evento.contatoTelefone, '');
      expect(evento.contatoEmail, isNull);
      expect(evento.agendarPublicacao, isFalse);
      expect(evento.publicadoEm, isNull);
      expect(evento.status, 'publicado');
      expect(evento.createdAt, DateTime.parse('2026-07-01T10:00:00.000Z'));
      expect(evento.updatedAt, DateTime.parse('2026-07-01T10:00:00.000Z'));
    });

    test('mapeia todos os campos preenchidos', () {
      final json = _jsonMinimo()
        ..addAll({
          'nome': 'Ação Social de Agosto',
          'categoria': 'Ação Social',
          'publico_alvo': <dynamic>['Todos', 'Jovens'],
          'data_fim': '2026-08-03',
          'hora_inicio': '19:00:00',
          'hora_fim': '21:00:00',
          'dia_inteiro': true,
          'repeticao': 'semanal',
          'tipo_local': 'online',
          'endereco': 'Rua das Flores, 123',
          'link_transmissao': 'https://youtube.com/live/abc',
          'resumo_curto': 'Resumo cadastrado.',
          'descricao': 'Dia de atendimentos gratuitos.',
          'imagem_capa_url': 'https://cdn.exemplo.com/capa.png',
          'galeria_imagens_urls': <dynamic>['https://cdn.exemplo.com/1.png'],
          'evento_pago': true,
          'limite_vagas': 100,
          'requer_inscricao': true,
          'link_inscricao': 'https://forms.exemplo.com',
          'permitir_voluntarios': true,
          'quantidade_voluntarios': 5,
          'atividades_voluntarios': 'Recepção e organização',
          'acessibilidade': 'Rampa de acesso',
          'contato_nome': 'Equipe do Centro Social',
          'contato_telefone': '98999990000',
          'contato_email': 'contato@iadet.app',
          'agendar_publicacao': true,
          'publicado_em': '2026-07-15T12:00:00.000Z',
          'status': 'rascunho',
        });

      final evento = _eventoDe(json);

      expect(evento.nome, 'Ação Social de Agosto');
      expect(evento.categoria, 'Ação Social');
      expect(evento.publicoAlvo, ['Todos', 'Jovens']);
      expect(evento.dataFim, DateTime(2026, 8, 3));
      expect(evento.horaInicio, '19:00:00');
      expect(evento.horaFim, '21:00:00');
      expect(evento.diaInteiro, isTrue);
      expect(evento.repeticao, 'semanal');
      expect(evento.tipoLocal, 'online');
      expect(evento.endereco, 'Rua das Flores, 123');
      expect(evento.linkTransmissao, 'https://youtube.com/live/abc');
      expect(evento.resumoCurto, 'Resumo cadastrado.');
      expect(evento.descricao, 'Dia de atendimentos gratuitos.');
      expect(evento.imagemCapaUrl, 'https://cdn.exemplo.com/capa.png');
      expect(evento.galeriaImagensUrls, ['https://cdn.exemplo.com/1.png']);
      expect(evento.eventoPago, isTrue);
      expect(evento.limiteVagas, 100);
      expect(evento.requerInscricao, isTrue);
      expect(evento.linkInscricao, 'https://forms.exemplo.com');
      expect(evento.permitirVoluntarios, isTrue);
      expect(evento.quantidadeVoluntarios, 5);
      expect(evento.atividadesVoluntarios, 'Recepção e organização');
      expect(evento.acessibilidade, 'Rampa de acesso');
      expect(evento.contatoNome, 'Equipe do Centro Social');
      expect(evento.contatoTelefone, '98999990000');
      expect(evento.contatoEmail, 'contato@iadet.app');
      expect(evento.agendarPublicacao, isTrue);
      expect(evento.publicadoEm, DateTime.parse('2026-07-15T12:00:00.000Z'));
      expect(evento.status, 'rascunho');
    });
  });

  group('AppEvent.resumoCurto', () {
    test('prioriza o resumo legado quando preenchido, aparando espaços', () {
      final json = _jsonMinimo()
        ..['resumo_curto'] = '  Resumo legado  '
        ..['descricao'] = 'Descrição completa do evento.';

      expect(_eventoDe(json).resumoCurto, 'Resumo legado');
    });

    test('deriva da descrição quando o resumo legado está vazio', () {
      final json = _jsonMinimo()
        ..['resumo_curto'] = '   '
        ..['descricao'] = '  Descrição completa do evento.  ';

      expect(_eventoDe(json).resumoCurto, 'Descrição completa do evento.');
    });

    test('fica vazio quando resumo e descrição estão vazios', () {
      final json = _jsonMinimo()
        ..['resumo_curto'] = null
        ..['descricao'] = '   ';

      expect(_eventoDe(json).resumoCurto, '');
    });

    test('mantém descrição com exatamente 120 caracteres sem truncar', () {
      final descricao = 'a' * 120;
      final json = _jsonMinimo()..['descricao'] = descricao;

      expect(_eventoDe(json).resumoCurto, descricao);
    });

    test('trunca descrições longas em 119 caracteres com reticências', () {
      final json = _jsonMinimo()..['descricao'] = 'a' * 121;

      expect(_eventoDe(json).resumoCurto, '${'a' * 119}...');
    });

    test('apara espaços no ponto de corte antes das reticências', () {
      final json = _jsonMinimo()
        ..['descricao'] = '${'x' * 110}${' ' * 9}${'y' * 20}';

      expect(_eventoDe(json).resumoCurto, '${'x' * 110}...');
    });
  });

  group('AppEvent.dataTexto', () {
    test('evento de um dia inteiro exibe apenas a data', () {
      final json = _jsonMinimo()
        ..['dia_inteiro'] = true
        ..['hora_inicio'] = '19:00:00';

      expect(_eventoDe(json).dataTexto, '01/08');
    });

    test('evento de um dia sem horário exibe apenas a data', () {
      expect(_eventoDe(_jsonMinimo()).dataTexto, '01/08');
    });

    test('evento de um dia com horário exibe data e hora', () {
      final json = _jsonMinimo()..['hora_inicio'] = '19:00';

      expect(_eventoDe(json).dataTexto, '01/08 - 19:00');
    });

    test('descarta os segundos do horário vindo do banco', () {
      final json = _jsonMinimo()..['hora_inicio'] = '19:30:00';

      expect(_eventoDe(json).dataTexto, '01/08 - 19:30');
    });

    test('mantém horário malformado (sem minutos) como veio', () {
      final json = _jsonMinimo()..['hora_inicio'] = '19';

      expect(_eventoDe(json).dataTexto, '01/08 - 19');
    });

    test('evento de vários dias exibe o intervalo', () {
      final json = _jsonMinimo()..['data_fim'] = '2026-08-03';

      expect(_eventoDe(json).dataTexto, '01/08 ate 03/08');
    });

    test('aplica zero à esquerda em dia e mês', () {
      final json = _jsonMinimo()
        ..['data_inicio'] = '2026-03-05'
        ..['data_fim'] = '2026-03-05';

      expect(_eventoDe(json).dataTexto, '05/03');
    });
  });

  group('AppEvent.imagemCapaUrlVersionada', () {
    final versao =
        DateTime.parse('2026-07-01T10:00:00.000Z').millisecondsSinceEpoch;

    test('retorna null quando não há imagem de capa', () {
      expect(_eventoDe(_jsonMinimo()).imagemCapaUrlVersionada, isNull);
    });

    test('retorna null quando a URL é vazia ou só espaços', () {
      final json = _jsonMinimo()..['imagem_capa_url'] = '   ';

      expect(_eventoDe(json).imagemCapaUrlVersionada, isNull);
    });

    test('anexa a versão com ? quando a URL não tem query string', () {
      final json = _jsonMinimo()
        ..['imagem_capa_url'] = 'https://cdn.exemplo.com/capa.png';

      expect(
        _eventoDe(json).imagemCapaUrlVersionada,
        'https://cdn.exemplo.com/capa.png?v=$versao',
      );
    });

    test('anexa a versão com & quando a URL já tem query string', () {
      final json = _jsonMinimo()
        ..['imagem_capa_url'] = 'https://cdn.exemplo.com/capa.png?w=100';

      expect(
        _eventoDe(json).imagemCapaUrlVersionada,
        'https://cdn.exemplo.com/capa.png?w=100&v=$versao',
      );
    });

    test('apara espaços da URL antes de anexar a versão', () {
      final json = _jsonMinimo()
        ..['imagem_capa_url'] = '  https://cdn.exemplo.com/capa.png  ';

      expect(
        _eventoDe(json).imagemCapaUrlVersionada,
        'https://cdn.exemplo.com/capa.png?v=$versao',
      );
    });
  });
}
