class AppEvent {
  final String id;
  final String userId;
  final String nome;
  final String categoria;
  final List<String> publicoAlvo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? horaInicio;
  final String? horaFim;
  final bool diaInteiro;
  final String repeticao;
  final String tipoLocal;
  final String? endereco;
  final String? linkTransmissao;
  final String resumoCurto;
  final String descricao;
  final String? imagemCapaUrl;
  final List<String> galeriaImagensUrls;
  final bool eventoPago;
  final int? limiteVagas;
  final bool requerInscricao;
  final String? linkInscricao;
  final bool permitirVoluntarios;
  final int? quantidadeVoluntarios;
  final String? atividadesVoluntarios;
  final String? acessibilidade;
  final String contatoNome;
  final String contatoTelefone;
  final String? contatoEmail;
  final bool agendarPublicacao;
  final DateTime? publicadoEm;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppEvent({
    required this.id,
    required this.userId,
    required this.nome,
    required this.categoria,
    required this.publicoAlvo,
    required this.dataInicio,
    required this.dataFim,
    required this.horaInicio,
    required this.horaFim,
    required this.diaInteiro,
    required this.repeticao,
    required this.tipoLocal,
    required this.endereco,
    required this.linkTransmissao,
    required this.resumoCurto,
    required this.descricao,
    required this.imagemCapaUrl,
    required this.galeriaImagensUrls,
    required this.eventoPago,
    required this.limiteVagas,
    required this.requerInscricao,
    required this.linkInscricao,
    required this.permitirVoluntarios,
    required this.quantidadeVoluntarios,
    required this.atividadesVoluntarios,
    required this.acessibilidade,
    required this.contatoNome,
    required this.contatoTelefone,
    required this.contatoEmail,
    required this.agendarPublicacao,
    required this.publicadoEm,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nome: (json['nome'] as String?) ?? '',
      categoria: (json['categoria'] as String?) ?? '',
      publicoAlvo: ((json['publico_alvo'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      dataFim: DateTime.parse(json['data_fim'] as String),
      horaInicio: json['hora_inicio'] as String?,
      horaFim: json['hora_fim'] as String?,
      diaInteiro: (json['dia_inteiro'] as bool?) ?? false,
      repeticao: (json['repeticao'] as String?) ?? 'sem_repeticao',
      tipoLocal: (json['tipo_local'] as String?) ?? 'presencial',
      endereco: json['endereco'] as String?,
      linkTransmissao: json['link_transmissao'] as String?,
      resumoCurto: (json['resumo_curto'] as String?) ?? '',
      descricao: (json['descricao'] as String?) ?? '',
      imagemCapaUrl: json['imagem_capa_url'] as String?,
      galeriaImagensUrls:
          ((json['galeria_imagens_urls'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      eventoPago: (json['evento_pago'] as bool?) ?? false,
      limiteVagas: json['limite_vagas'] as int?,
      requerInscricao: (json['requer_inscricao'] as bool?) ?? false,
      linkInscricao: json['link_inscricao'] as String?,
      permitirVoluntarios: (json['permitir_voluntarios'] as bool?) ?? false,
      quantidadeVoluntarios: json['quantidade_voluntarios'] as int?,
      atividadesVoluntarios: json['atividades_voluntarios'] as String?,
      acessibilidade: json['acessibilidade'] as String?,
      contatoNome: (json['contato_nome'] as String?) ?? '',
      contatoTelefone: (json['contato_telefone'] as String?) ?? '',
      contatoEmail: json['contato_email'] as String?,
      agendarPublicacao: (json['agendar_publicacao'] as bool?) ?? false,
      publicadoEm: json['publicado_em'] == null
          ? null
          : DateTime.parse(json['publicado_em'] as String),
      status: (json['status'] as String?) ?? 'publicado',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get dataTexto {
    final di = _formatDate(dataInicio);
    final df = _formatDate(dataFim);
    if (di == df) {
      if (diaInteiro || horaInicio == null) return di;
      return '$di - ${_formatTime(horaInicio!)}';
    }

    return '$di ate $df';
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0]}:${parts[1]}';
  }

  String? get imagemCapaUrlVersionada =>
      _appendVersionToken(imagemCapaUrl, updatedAt.millisecondsSinceEpoch);

  static String? _appendVersionToken(String? url, int version) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final separator = value.contains('?') ? '&' : '?';
    return '$value${separator}v=$version';
  }
}
