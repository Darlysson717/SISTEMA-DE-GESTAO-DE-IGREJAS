import 'package:centro_social_app/firebase_options.dart';
import 'package:centro_social_app/src/app.dart';
import 'package:centro_social_app/src/nucleo/configuracao/configuracao_app.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponto de entrada do aplicativo Centro Social da Igreja.
///
/// Inicializa os serviços essenciais antes de renderizar o app:
/// - Configura orientação de tela para retrato (mobile)
/// - Inicializa localização para datas em português brasileiro
/// - Inicializa Firebase (Core + Messaging + Analytics) — tolerante a falhas
/// - Conecta ao Supabase (URL, anon key e fluxo de autenticação PKCE)
/// - Inicia o sistema de injeção de dependência com Riverpod
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  await initializeDateFormatting('pt_BR', null);

  // Inicializa Firebase (Core + Messaging + Analytics).
  // Uma falha aqui (ex.: Web App do Firebase ainda não configurado em
  // firebase_options.dart) não pode impedir o app de abrir — o restante
  // do sistema funciona via Supabase; apenas push/analytics ficam fora.
  var firebaseDisponivel = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseDisponivel = true;

    if (!kIsWeb) {
      // Handler de mensagens em background (Android/iOS). Na web quem faz
      // esse papel é o service worker web/firebase-messaging-sw.js.
      FirebaseMessaging.onBackgroundMessage(
        ServicoNotificacoes.manipularMensagemBackground,
      );
    }

    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    if (kDebugMode) {
      print('✅ Firebase inicializado (Core + Analytics)');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase indisponível, seguindo sem push/analytics: $e');
    }
  }

  // Inicializa Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Inicializa serviço de notificações (depende do Firebase e do Supabase)
  if (firebaseDisponivel) {
    await ServicoNotificacoes().inicializar();
  }

  runApp(const ProviderScope(child: CentroSocialApp()));
}
