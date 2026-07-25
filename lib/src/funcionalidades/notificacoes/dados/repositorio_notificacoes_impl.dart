import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/entidades/notificacao_app.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/repositorios/repositorio_notificacoes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RepositorioNotificacoesImpl implements RepositorioNotificacoes {
  final SupabaseClient _client;

  RepositorioNotificacoesImpl(this._client);

  String? get _usuarioId => _client.auth.currentUser?.id;

  @override
  Future<List<NotificacaoApp>> buscarUltimas({int limite = 5}) async {
    if (_usuarioId == null) return [];

    final response = await _client
        .from('app_notifications')
        .select()
        .eq('user_id', _usuarioId!)
        .order('created_at', ascending: false)
        .limit(limite);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map((map) => NotificacaoApp.fromMap(map)).toList();
  }

  @override
  Future<int> contarNaoLidas() async {
    if (_usuarioId == null) return 0;

    final response = await _client
        .from('app_notifications')
        .select('id')
        .eq('user_id', _usuarioId!)
        .eq('lida', false);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.length;
  }

  @override
  Future<void> marcarComoLida(String notificacaoId) async {
    if (_usuarioId == null) return;

    await _client
        .from('app_notifications')
        .update({'lida': true})
        .eq('id', notificacaoId)
        .eq('user_id', _usuarioId!);
  }

  @override
  Future<void> marcarTodasComoLidas() async {
    if (_usuarioId == null) return;

    await _client
        .from('app_notifications')
        .update({'lida': true})
        .eq('user_id', _usuarioId!)
        .eq('lida', false);
  }

  @override
  Future<void> limparTodas() async {
    if (_usuarioId == null) return;

    await _client
        .from('app_notifications')
        .delete()
        .eq('user_id', _usuarioId!);
  }
}