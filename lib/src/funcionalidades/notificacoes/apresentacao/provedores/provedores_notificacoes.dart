import 'package:centro_social_app/src/funcionalidades/notificacoes/dados/repositorio_notificacoes_impl.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/entidades/notificacao_app.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/repositorios/repositorio_notificacoes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final repositorioNotificacoesProvider = Provider<RepositorioNotificacoes>((ref) {
  return RepositorioNotificacoesImpl(Supabase.instance.client);
});

final ultimasNotificacoesProvider = FutureProvider<List<NotificacaoApp>>((ref) async {
  final repo = ref.watch(repositorioNotificacoesProvider);
  return repo.buscarUltimas();
});

final notificacoesNaoLidasProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(repositorioNotificacoesProvider);
  return repo.contarNaoLidas();
});

final notificacoesControllerProvider = Provider<NotificacoesController>((ref) {
  return NotificacoesController(ref);
});

class NotificacoesController {
  final Ref _ref;

  NotificacoesController(this._ref);

  Future<void> marcarComoLida(String notificacaoId) async {
    final repo = _ref.read(repositorioNotificacoesProvider);
    await repo.marcarComoLida(notificacaoId);
    _invalidar();
  }

  Future<void> marcarTodasComoLidas() async {
    final repo = _ref.read(repositorioNotificacoesProvider);
    await repo.marcarTodasComoLidas();
    _invalidar();
  }

  Future<void> limparTodas() async {
    final repo = _ref.read(repositorioNotificacoesProvider);
    await repo.limparTodas();
    _invalidar();
  }

  void _invalidar() {
    _ref.invalidate(ultimasNotificacoesProvider);
    _ref.invalidate(notificacoesNaoLidasProvider);
  }
}