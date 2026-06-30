import 'package:centro_social_app/src/app.dart';
import 'package:centro_social_app/src/nucleo/configuracao/configuracao_app.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponto de entrada do aplicativo Centro Social da Igreja.
///
/// Inicializa os serviços essenciais antes de renderizar o app:
/// - Configura orientação de tela para retrato
/// - Inicializa localização para datas em português brasileiro
/// - Conecta ao Supabase (URL, anon key e fluxo de autenticação PKCE)
/// - Inicia o sistema de injeção de dependência com Riverpod
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('pt_BR', null);

  // Inicializa Firebase (Core + Messaging + Analytics)
  await Firebase.initializeApp();
  
  // Inicializa Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  
  if (kDebugMode) {
    print('✅ Firebase Analytics inicializado');
  }

  // Inicializa Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Inicializa serviço de notificações
  await ServicoNotificacoes().inicializar();

  runApp(const ProviderScope(child: CentroSocialApp()));
}