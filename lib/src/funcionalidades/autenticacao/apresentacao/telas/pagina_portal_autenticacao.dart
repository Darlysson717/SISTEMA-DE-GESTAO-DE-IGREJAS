import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/telas/tela_login.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/pagina_inicio.dart';
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/telas/pagina_consentimento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (state) {
        if (state.session == null) {
          return const LoginScreen();
        }

        final userAsync = ref.watch(currentAppUserProvider);
        return userAsync.when(
          data: (user) {
            if (user == null) {
              return const LoginScreen();
            }
            return FutureBuilder<bool>(
              future: _checkConsent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingView(message: 'Carregando...');
                }
                final hasConsented = snapshot.data ?? false;
                if (!hasConsented) {
                  return FirstTimeConsentPage(
                    onAccepted: () {
                      setState(() {});
                    },
                  );
                }
                return HomePage(currentUser: user);
              },
            );
          },
          loading: () => const _LoadingView(message: 'Carregando perfil...'),
          error: (error, _) =>
              _ErrorView(message: 'Falha ao carregar perfil: $error'),
        );
      },
      loading: () => const _LoadingView(message: 'Verificando sessão...'),
      error: (error, _) =>
          _ErrorView(message: 'Falha ao verificar autenticação: $error'),
    );
  }

  /// Verifica se o usuário já aceitou os termos na versão atual.
  /// Retorna false nos casos:
  /// 1. Nunca aceitou (consent_accepted = false ou null)
  /// 2. Aceitou em uma versão anterior (consent_terms_version != kCurrentTermsVersion)
  Future<bool> _checkConsent() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('consent_accepted, consent_terms_version')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;
      if (response['consent_accepted'] != true) return false;

      // Verifica se a versão aceita é a mesma da versão atual dos termos
      final acceptedVersion = response['consent_terms_version'] as String?;
      return acceptedVersion == kCurrentTermsVersion;
    } catch (_) {
      return false;
    }
  }
}

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}