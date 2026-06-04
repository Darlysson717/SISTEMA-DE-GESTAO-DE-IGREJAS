import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

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

    const corTextoPrincipal = Color(0xFF17394A);
    const corTextoSecundario = Color(0xFF5E6A63);
    const corBotaoPrincipal = Color(0xFF13475E);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EB),
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 2),
                      const _LoginEmblem(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    corTextoPrincipal.withValues(alpha: 0.0),
                                    corTextoPrincipal.withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: corBotaoPrincipal,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    corTextoPrincipal.withValues(alpha: 0.18),
                                    corTextoPrincipal.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '“Cada um contribua\nsegundo tiver proposto em\nseu coração, não com tristeza\nou por necessidade; porque\nDeus ama quem dá\ncom alegria.”',
                        style: GoogleFonts.cormorantGaramond(
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: corTextoPrincipal,
                                fontSize: 20,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '2 CORÍNTIOS 9:7',
                        style: GoogleFonts.bodoniModa(
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: corTextoPrincipal.withValues(alpha: 0.72),
                                letterSpacing: 3.6,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Seja bem-vindo!',
                        style: GoogleFonts.playfairDisplay(
                          textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: corTextoPrincipal,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Que bom ter você aqui.\nFaça login para continuar.',
                        style: GoogleFonts.montserrat(
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: corTextoSecundario,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B1B1B),
                            elevation: 8,
                            shadowColor: const Color(0xFF8A8070).withValues(alpha: 0.22),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                            minimumSize: const Size(200, 48),
                            shape: const StadiumBorder(),
                            side: const BorderSide(color: Color(0xFFE8E1D2), width: 1.3),
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
                                    color: corBotaoPrincipal,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6E6255).withValues(alpha: 0.10),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Image.network(
                                          'https://developers.google.com/static/identity/images/g-logo.png',
                                          height: 20,
                                          width: 20,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Entrar com o Google',
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Acesso rápido, seguro e restrito.',
                        style: GoogleFonts.montserrat(
                          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: corTextoPrincipal.withValues(alpha: 0.58),
                                fontSize: 11,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5DFD2),
              Color(0xFFEFEBE0),
              Color(0xFFF6F3EB),
              Color(0xFFEFEBE0),
              Color(0xFFE5DFD2),
            ],
            stops: [0.0, 0.18, 0.5, 0.83, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -88,
              bottom: -56,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5DFD2).withValues(alpha: 0.68),
                ),
              ),
            ),
            Positioned(
              right: -72,
              top: -60,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFEBE0).withValues(alpha: 0.72),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: -8,
              child: IgnorePointer(
                child: Image.asset(
                  'Imagens/direita folhas.png',
                  width: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: 8,
              child: IgnorePointer(
                child: Image.asset(
                  'Imagens/esquerda folhas.png',
                  width: 168,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 24,
              child: Container(
                width: 210,
                height: 170,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5DFD2).withValues(alpha: 0.0),
                      const Color(0xFFE5DFD2).withValues(alpha: 0.52),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.08),
                      radius: 0.9,
                      colors: [
                        const Color(0xFFF6F3EB).withValues(alpha: 0.72),
                        const Color(0xFFF6F3EB).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginEmblem extends StatelessWidget {
  const _LoginEmblem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 248,
        child: Image.asset(
          'Imagens/LOGO DEPARTAMENTO.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
