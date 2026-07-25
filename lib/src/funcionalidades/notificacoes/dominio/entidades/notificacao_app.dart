class NotificacaoApp {
  final String id;
  final String usuarioId;
  final String titulo;
  final String corpo;
  final String? tipo;
  final String? dados;
  final bool lida;
  final DateTime criadaEm;

  const NotificacaoApp({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.corpo,
    this.tipo,
    this.dados,
    this.lida = false,
    required this.criadaEm,
  });

  factory NotificacaoApp.fromMap(Map<String, dynamic> map) {
    return NotificacaoApp(
      id: map['id'] as String,
      usuarioId: map['user_id'] as String,
      titulo: map['titulo'] as String,
      corpo: map['corpo'] as String,
      tipo: map['tipo'] as String?,
      dados: map['dados'] as String?,
      lida: map['lida'] as bool? ?? false,
      criadaEm: DateTime.parse(map['created_at'] as String),
    );
  }

  NotificacaoApp copyWith({bool? lida}) {
    return NotificacaoApp(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      corpo: corpo,
      tipo: tipo,
      dados: dados,
      lida: lida ?? this.lida,
      criadaEm: criadaEm,
    );
  }
}