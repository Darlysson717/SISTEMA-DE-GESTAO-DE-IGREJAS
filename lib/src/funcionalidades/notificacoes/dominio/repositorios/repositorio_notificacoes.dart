import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/entidades/notificacao_app.dart';

abstract class RepositorioNotificacoes {
  Future<List<NotificacaoApp>> buscarUltimas({int limite = 5});
  Future<int> contarNaoLidas();
  Future<void> marcarComoLida(String notificacaoId);
  Future<void> marcarTodasComoLidas();
  Future<void> limparTodas();
}