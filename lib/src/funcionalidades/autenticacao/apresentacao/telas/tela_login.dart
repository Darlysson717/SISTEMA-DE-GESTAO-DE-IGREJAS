import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;

    // Escuta erros de autenticação
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha no login: $error')),
          );
        },
      );
    });

    const corTemaRoxo = Color(0xFF6A5AE0); // Roxo principal da identidade

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5A4EE3), // Roxo Indigo
              Color(0xFF9652F4), // Violeta Vibrante
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- LOGO DO SEU APP ---
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 85,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.church, size: 56, color: corTemaRoxo);
                            },
                          ),
                        ),
                        
                        Text(
                          'Centro Social',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: corTemaRoxo,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'DA IGREJA',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: corTemaRoxo.withOpacity(0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        // Um espaçamento elegante antes do botão único
                        const SizedBox(height: 48),

                        // --- NOVO BOTÃO DO GOOGLE (ESTILO PÍLULA DESTACADO) ---
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,       // Botão branco igual ao padrão oficial
                            foregroundColor: Colors.black87,     // Cor do texto interno
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),        // Formato pílula arredondado
                            side: BorderSide(color: Colors.grey.shade200, width: 1.5), // Borda suave
                          ),
                          onPressed: loading
                              ? null
                              : () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: corTemaRoxo,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Logozinha oficial do Google carregada direto da CDN de desenvolvedores deles
                                    Image.network(
                                      'https://developers.google.com/static/identity/images/g-logo.png',
                                      height: 22,
                                      width: 22,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.g_mobiledata, size: 26, color: Colors.blue);
                                      },
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Entrar com o Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Acesso rápido, seguro e restrito.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}