/// Representa um serviço comunitário oferecido por um profissional voluntário.
///
/// Cada [Service] contém todas as informações necessárias para que membros
/// da comunidade possam encontrar e agendar atendimentos, incluindo dados
/// do profissional, horários disponíveis, tipo de atendimento e contato.
class Service {
  /// Identificador único do serviço no Supabase.
  final String id;

  /// ID do usuário (profissional) que criou o serviço.
  final String userId;

  /// Nome do serviço (ex: "Aconselhamento Psicológico").
  final String nome;

  /// Categoria/especialidade do serviço (ex: "Psicologia", "Jurídico").
  final String categoria;

  /// Nome do profissional para exibição pública.
  final String nomeProfissional;

  /// URL da imagem de perfil do profissional (opcional).
  final String? imagemProfissional;

  /// Descrição detalhada do serviço oferecido.
  final String descricao;

  /// Dias da semana disponíveis (ex: ["segunda", "quarta"]).
  final List<String> diasDisponiveis;

  /// Horários disponíveis no formato 'HH:mm' (ex: ["08:00", "09:00"]).
  final List<String> horarios;

  /// Duração de cada atendimento em minutos (padrão: 60).
  final int? duracaoAtendimento;

  /// Tipo de atendimento: 'online' ou 'presencial'.
  final String tipoAtendimento;

  /// Local do atendimento presencial (endereço, sala, etc.).
  final String? local;

  /// Telefone para contato do profissional.
  final String telefone;

  /// Observações adicionais sobre o serviço.
  final String? observacoes;

  /// Status do serviço: 'ativo', 'inativo', 'pendente'.
  final String status;

  /// Cria um [Service] com todos os campos obrigatórios.
  const Service({
    required this.id,
    required this.userId,
    required this.nome,
    required this.categoria,
    required this.nomeProfissional,
    this.imagemProfissional,
    required this.descricao,
    required this.diasDisponiveis,
    required this.horarios,
    this.duracaoAtendimento,
    required this.tipoAtendimento,
    this.local,
    required this.telefone,
    this.observacoes,
    required this.status,
  });

  /// Converte um mapa JSON do Supabase para um [Service].
  ///
  /// Usado ao receber dados da tabela 'servicos' no banco de dados.
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nome: json['nome'] as String,
      categoria: json['categoria'] as String,
      nomeProfissional: json['nome_profissional'] as String,
      imagemProfissional: json['imagem_profissional'] as String?,
      descricao: json['descricao'] as String,
      diasDisponiveis: List<String>.from(json['dias_disponiveis'] as List),
      horarios: List<String>.from(json['horarios'] as List),
      duracaoAtendimento: json['duracao_atendimento'] as int?,
      tipoAtendimento: json['tipo_atendimento'] as String,
      local: json['local'] as String?,
      telefone: json['telefone'] as String,
      observacoes: json['observacoes'] as String?,
      status: json['status'] as String,
    );
  }
}