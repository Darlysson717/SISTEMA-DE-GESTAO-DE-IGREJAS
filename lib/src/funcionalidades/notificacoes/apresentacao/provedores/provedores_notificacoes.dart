import 'dart:async';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dados/repositorio_notificacoes_impl.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/entidades/notificacao_app.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/repositorios/repositorio_notificacoes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final repositorioNotificacoesProvider = Provider<RepositorioNotificacoes>((ref) {
  return RepositorioNotificacoesImpl(Supabase.instance.client);
});

/// Provider que escuta em tempo real as notificações do usuário logado.
/// Usa o Supabase Realtime para atualizar automaticamente a lista.
final ultimasNotificacoesProvider = StreamProvider<List<NotificacaoApp>>((ref) {
  final supabase = Supabase.instance.client;
  final usuarioId = supabase.auth.currentUser?.id;

  if (usuarioId == null) {
    return Stream.value([]);
  }

  // Cria um StreamController para gerenciar os eventos
  final controller = StreamController<List<NotificacaoApp>>.broadcast();

  // Carrega dados iniciais
  _carregarNotificacoes(supabase, usuarioId).then((notificacoes) {
    if (!controller.isClosed) {
      controller.add(notificacoes);
    }
  });

  // Escuta mudanças em tempo real na tabela app_notifications
  late StreamSubscription subscription;
  try {
    subscription = supabase
        .from('app_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', usuarioId)
        .order('created_at', ascending: false)
        .limit(50)
        .listen((rows) {
          final notificacoes = (rows as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((map) => NotificacaoApp.fromMap(map))
              .toList();
          if (!controller.isClosed) {
            controller.add(notificacoes);
          }
        }, onError: (error) {
          if (kDebugMode) {
            print('⚠️ Erro no stream de notificações: $error');
          }
          // Fallback: usa polling manual a cada 30 segundos
          _iniciarPolling(supabase, usuarioId, controller);
        });
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Realtime não disponível, usando polling: $e');
    }
    // Se Realtime não estiver habilitado, usa polling
    _iniciarPolling(supabase, usuarioId, controller);
  }

  ref.onDispose(() {
    controller.close();
    try {
      subscription.cancel();
    } catch (_) {}
  });

  return controller.stream;
});

/// Provider que escuta em tempo real a contagem de notificações não lidas.
final notificacoesNaoLidasProvider = StreamProvider<int>((ref) {
  final notificacoesAsync = ref.watch(ultimasNotificacoesProvider);

  return notificacoesAsync.when(
    data: (notificacoes) => Stream.value(notificacoes.where((n) => !n.lida).length),
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Inicia polling manual a cada 30 segundos como fallback do Realtime
void _iniciarPolling(
  SupabaseClient supabase,
  String usuarioId,
  StreamController<List<NotificacaoApp>> controller,
) {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (controller.isClosed) {
      timer.cancel();
      return;
    }
    final notificacoes = await _carregarNotificacoes(supabase, usuarioId);
    controller.add(notificacoes);
  });
}

/// Carrega as notificações do banco de dados
Future<List<NotificacaoApp>> _carregarNotificacoes(
  SupabaseClient supabase,
  String usuarioId,
) async {
  try {
    final response = await supabase
        .from('app_notifications')
        .select()
        .eq('user_id', usuarioId)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map((map) => NotificacaoApp.fromMap(map)).toList();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erro ao carregar notificações: $e');
    }
    return [];
  }
}

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
