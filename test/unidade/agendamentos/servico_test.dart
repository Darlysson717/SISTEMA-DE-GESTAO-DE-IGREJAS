import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON completo no formato retornado pela tabela `servicos` do Supabase.
Map<String, dynamic> _jsonCompleto() => {
      'id': 'servico-1',
      'user_id': 'usuario-1',
      'nome': 'Aconselhamento Psicológico',
      'categoria': 'Psicologia',
      'nome_profissional': 'Dra. Ana',
      'imagem_profissional': 'https://cdn.exemplo.com/ana.png',
      'descricao': 'Atendimento gratuito para a comunidade.',
      'dias_disponiveis': <dynamic>['segunda', 'quarta'],
      'horarios': <dynamic>['08:00', '09:00'],
      'duracao_atendimento': 45,
      'tipo_atendimento': 'presencial',
      'local': 'Sala 2',
      'telefone': '98999990000',
      'observacoes': 'Trazer documento com foto.',
      'status': 'ativo',
    };

void main() {
  group('Service.fromJson', () {
    test('mapeia todos os campos preenchidos', () {
      final servico = Service.fromJson(_jsonCompleto());

      expect(servico.id, 'servico-1');
      expect(servico.userId, 'usuario-1');
      expect(servico.nome, 'Aconselhamento Psicológico');
      expect(servico.categoria, 'Psicologia');
      expect(servico.nomeProfissional, 'Dra. Ana');
      expect(servico.imagemProfissional, 'https://cdn.exemplo.com/ana.png');
      expect(servico.descricao, 'Atendimento gratuito para a comunidade.');
      expect(servico.diasDisponiveis, ['segunda', 'quarta']);
      expect(servico.horarios, ['08:00', '09:00']);
      expect(servico.duracaoAtendimento, 45);
      expect(servico.tipoAtendimento, 'presencial');
      expect(servico.local, 'Sala 2');
      expect(servico.telefone, '98999990000');
      expect(servico.observacoes, 'Trazer documento com foto.');
      expect(servico.status, 'ativo');
    });

    test('aceita campos opcionais ausentes', () {
      final json = _jsonCompleto()
        ..remove('imagem_profissional')
        ..remove('duracao_atendimento')
        ..remove('local')
        ..remove('observacoes');

      final servico = Service.fromJson(json);

      expect(servico.imagemProfissional, isNull);
      expect(servico.duracaoAtendimento, isNull);
      expect(servico.local, isNull);
      expect(servico.observacoes, isNull);
    });

    test('aceita campos opcionais explicitamente nulos', () {
      final json = _jsonCompleto()
        ..['imagem_profissional'] = null
        ..['duracao_atendimento'] = null
        ..['local'] = null
        ..['observacoes'] = null;

      final servico = Service.fromJson(json);

      expect(servico.imagemProfissional, isNull);
      expect(servico.duracaoAtendimento, isNull);
      expect(servico.local, isNull);
      expect(servico.observacoes, isNull);
    });

    test('converte listas dinâmicas do banco para List<String>', () {
      final json = _jsonCompleto()
        ..['dias_disponiveis'] = <dynamic>['sexta']
        ..['horarios'] = <dynamic>[];

      final servico = Service.fromJson(json);

      expect(servico.diasDisponiveis, isA<List<String>>());
      expect(servico.diasDisponiveis, ['sexta']);
      expect(servico.horarios, isEmpty);
    });
  });
}
