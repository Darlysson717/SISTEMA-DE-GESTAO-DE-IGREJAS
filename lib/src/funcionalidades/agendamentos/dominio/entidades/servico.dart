class Service {
  final String id;
  final String userId;
  final String nome;
  final String categoria;
  final String nomeProfissional;
  final String? imagemProfissional;
  final String descricao;
  final List<String> diasDisponiveis;
  final List<String> horarios;
  final int? duracaoAtendimento;
  final String tipoAtendimento;
  final String? local;
  final String telefone;
  final String? observacoes;
  final String status;

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