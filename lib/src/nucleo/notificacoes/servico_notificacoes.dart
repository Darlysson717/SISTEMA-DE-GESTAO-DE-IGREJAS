import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Canal de notificações para Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID do canal
  'Notificações Importantes', // Nome do canal
  description: 'Canal para notificações importantes do app',
  importance: Importance.high,
);

/// Serviço responsável pelo gerenciamento de notificações push via Firebase.
///
/// Funcionalidades:
/// - Inicialização do Firebase Messaging
/// - Solicitação de permissão de notificações
/// - Obtenção e registro do token FCM
/// - Manipulação de notificações em foreground/background/terminated
/// - Notificações locais para garantir exibição em todos os estados
class ServicoNotificacoes {
  static final ServicoNotificacoes _instance = ServicoNotificacoes._internal();
  factory ServicoNotificacoes() => _instance;
  ServicoNotificacoes._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Inicializa o serviço de notificações.
  ///
  /// Deve ser chamado após a inicialização do Firebase e Supabase.
  Future<void> inicializar() async {
    try {
      // Inicializa notificações locais
      await _inicializarNotificacoesLocais();

      // Configura handler para mensagens em foreground
      FirebaseMessaging.onMessage.listen(_manipularMensagemForeground);

      // Configura handler para quando o usuário toca na notificação
      FirebaseMessaging.onMessageOpenedApp.listen(_manipularAberturaNotificacao);

      // Verifica se o app foi aberto por uma notificação (estado terminated)
      final mensagemInicial = await FirebaseMessaging.instance.getInitialMessage();
      if (mensagemInicial != null) {
        _manipularAberturaNotificacao(mensagemInicial);
      }

      // Solicita permissão
      await _solicitarPermissao();

      // Se já estiver logado, registra o token
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario != null) {
        await _obterESalvarTokenFCM();
      }

      if (kDebugMode) {
        print('✅ Serviço de notificações inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar notificações: $e');
      }
    }
  }

  /// Registra o token FCM para o usuário logado.
  /// Deve ser chamado após o login do usuário.
  Future<void> registrarToken() async {
    try {
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) {
        if (kDebugMode) {
          print('⚠️ Usuário não logado, token não registrado');
        }
        return;
      }

      await _obterESalvarTokenFCM();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao registrar token: $e');
      }
    }
  }

  /// Inicializa notificações locais para exibir quando app está em background/terminated
  Future<void> _inicializarNotificacoesLocais() async {
    try {
      // Configurações de inicialização para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurações de inicialização para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configurações gerais de inicialização
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializa o plugin
      await _localNotifications.initialize(initializationSettings);

      // Cria o canal de notificações para Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      if (kDebugMode) {
        print('✅ Notificações locais inicializadas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar notificações locais: $e');
      }
    }
  }

  /// Solicita permissão de notificações.
  Future<void> _solicitarPermissao() async {
    try {
      // Solicita permissão (iOS e Android 13+)
      NotificationSettings configuracoes = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('📱 Permissão de notificações: ${configuracoes.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao solicitar permissão: $e');
      }
    }
  }

  /// Obtém o token FCM e salva no Supabase.
  Future<void> _obterESalvarTokenFCM() async {
    try {
      // Obtém token FCM
      String? token = await _messaging.getToken();

      if (token == null) {
        if (kDebugMode) {
          print('⚠️ Token FCM não disponível');
        }
        return;
      }

      if (kDebugMode) {
        print('🔑 Token FCM obtido: ${token.substring(0, 20)}...');
      }

      // Obtém usuário logado
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) {
        if (kDebugMode) {
          print('⚠️ Usuário não logado, token não salvo');
        }
        return;
      }

      // Salva token na tabela de perfis
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', usuario.id);

      if (kDebugMode) {
        print('✅ Token FCM salvo no Supabase para usuário ${usuario.id}');
      }

      // Escuta atualizações do token (pode mudar a qualquer momento)
      _messaging.onTokenRefresh.listen((novoToken) async {
        if (kDebugMode) {
          print('🔄 Token FCM atualizado');
        }

        final usuarioAtual = Supabase.instance.client.auth.currentUser;
        if (usuarioAtual != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'fcm_token': novoToken})
              .eq('id', usuarioAtual.id);

          if (kDebugMode) {
            print('✅ Novo token FCM salvo no Supabase');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar token FCM: $e');
      }
    }
  }

  /// Manipula notificações recebidas em foreground.
  Future<void> _manipularMensagemForeground(RemoteMessage mensagem) async {
    if (kDebugMode) {
      print('📬 Notificação recebida (foreground):');
      print('   Título: ${mensagem.notification?.title}');
      print('   Corpo: ${mensagem.notification?.body}');
      print('   Dados: ${mensagem.data}');
    }

    // Exibe notificação local mesmo em foreground
    await _exibirNotificacaoLocal(
      titulo: mensagem.notification?.title ?? 'Nova notificação',
      corpo: mensagem.notification?.body ?? '',
      dados: mensagem.data,
    );
  }

  /// Exibe uma notificação local
  Future<void> _exibirNotificacaoLocal({
    required String titulo,
    required String corpo,
    Map<String, dynamic>? dados,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'Notificações Importantes',
        channelDescription: 'Canal para notificações importantes do app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        corpo,
        platformChannelSpecifics,
        payload: dados?.toString(),
      );

      if (kDebugMode) {
        print('🔔 Notificação local exibida');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao exibir notificação local: $e');
      }
    }
  }

  /// Manipula abertura do app por toque em notificação.
  void _manipularAberturaNotificacao(RemoteMessage mensagem) {
    if (kDebugMode) {
      print('🔔 App aberto por notificação:');
      print('   Título: ${mensagem.notification?.title}');
      print('   Dados: ${mensagem.data}');
    }

    // Aqui você pode navegar para uma tela específica baseada nos dados
    // Exemplo: se dados['tipo'] == 'agendamento', navegar para detalhes
  }

  /// Manipula mensagens recebidas quando o app está em background/terminated
  /// Esta função é chamada automaticamente pelo Firebase
  static Future<void> manipularMensagemBackground(RemoteMessage mensagem) async {
    if (kDebugMode) {
      print('📨 Notificação recebida (background/terminated):');
      print('   Título: ${mensagem.notification?.title}');
      print('   Corpo: ${mensagem.notification?.body}');
    }
    
    // Quando o app está em background/terminated, o Firebase exibe a notificação
    // automaticamente na barra de notificações do sistema
    // Esta função é chamada apenas se o app tem lógica customizada para processar
    // a notificação antes de exibi-la
  }

  /// Remove o token FCM do usuário (útil no logout).
  Future<void> removerToken() async {
    try {
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', usuario.id);

      if (kDebugMode) {
        print('✅ Token FCM removido do usuário ${usuario.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao remover token FCM: $e');
      }
    }
  }

  /// Verifica se as notificações estão habilitadas.
  Future<bool> estaoHabilitadas() async {
    try {
      final configuracoes = await _messaging.getNotificationSettings();
      return configuracoes.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }
}