import 'package:centro_social_app/src/nucleo/navegacao/observador_rotas.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/telas/pagina_portal_autenticacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CentroSocialApp extends StatelessWidget {
  const CentroSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Centro Social da Igreja',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: base.appBarTheme.copyWith(
          centerTitle: false,
          titleTextStyle: base.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          toolbarTextStyle: base.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4F46E5), width: 1.2),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
      navigatorObservers: [routeObserver],
      home: const AuthGatePage(),
    );
  }
}
