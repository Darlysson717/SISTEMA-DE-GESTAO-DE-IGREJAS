import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/telas/tela_login.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/pagina_inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    // Escuta mudanças no auth state para salvar termos pendentes
    ref.listen(authStateChangesProvider, (_, next) {
      next.whenOrNull(data: (state) {
        if (state.session != null) {
          ref.read(authControllerProvider.notifier).onAuthStateChanged(state);
        }
      });
    });

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
            return HomePage(currentUser: user);
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
