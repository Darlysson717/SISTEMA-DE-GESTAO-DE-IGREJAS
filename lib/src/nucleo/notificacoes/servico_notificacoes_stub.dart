// Stub para plataformas não-web (Android, iOS, etc.)
// Esta implementação é substituída pela versão web quando compilando para web

/// Exibe notificação via Web Notification API (stub - não faz nada em não-web)
void exibirNotificacaoWeb(
  String titulo,
  String corpo,
  Map<String, dynamic>? dados,
  void Function(Map<String, dynamic>?) aoClicar,
) {
  // No-op em plataformas não-web
}