import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pagina_termos_servico.dart';
import 'pagina_politica_privacidade.dart';

/// Versão atual dos termos de uso.
/// Altere esta constante sempre que os Termos de Uso forem atualizados
/// para forçar que todos os usuários aceitem novamente.
const String kCurrentTermsVersion = '1.2.0';

class FirstTimeConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;

  const FirstTimeConsentPage({super.key, required this.onAccepted});

  @override
  State<FirstTimeConsentPage> createState() => _FirstTimeConsentPageState();
}

class _FirstTimeConsentPageState extends State<FirstTimeConsentPage> {
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;
  bool acceptedAge = false;
  bool _saving = false;

  Future<void> _saveConsent() async {
    setState(() => _saving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').update({
        'consent_accepted': true,
        'consent_accepted_at': DateTime.now().toUtc().toIso8601String(),
        'consent_terms_version': kCurrentTermsVersion,
      }).eq('id', userId);

      if (mounted) {
        widget.onAccepted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar consentimento: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final allAccepted = acceptedTerms && acceptedPrivacy && acceptedAge;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 24 : 32,
                    topInset + (isSmallScreen ? 40 : 48),
                    isSmallScreen ? 24 : 32,
                    isSmallScreen ? 32 : 40,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      Text(
                        'Bem-vindo ao DESIADET',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'Antes de começar, precisamos da sua autorização',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info card
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF16A34A),
                            size: isSmallScreen ? 20 : 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Seus dados pessoais são tratados conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 - LGPD). Leia os documentos abaixo e autorize o tratamento.',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: const Color(0xFF166534),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 28),

                    // Terms of Use checkbox
                    _buildConsentCard(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Termos de Uso',
                      subtitle:
                          'Li e concordo com os Termos de Uso do DESIADET, incluindo o tratamento dos meus dados pessoais, dados de saúde, crença religiosa e uso de imagem para fins institucionais.',
                      accepted: acceptedTerms,
                      onTap: () => _openTerms(context),
                      onCheck: () {
                        setState(() => acceptedTerms = !acceptedTerms);
                      },
                      isSmallScreen: isSmallScreen,
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Privacy Policy checkbox
                    _buildConsentCard(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Política de Privacidade',
                      subtitle:
                          'Li e concordo com a Política de Privacidade do DESIADET, incluindo a coleta, uso, armazenamento e compartilhamento dos meus dados conforme descrito no documento.',
                      accepted: acceptedPrivacy,
                      onTap: () => _openPrivacy(context),
                      onCheck: () {
                        setState(() => acceptedPrivacy = !acceptedPrivacy);
                      },
                      isSmallScreen: isSmallScreen,
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Age declaration checkbox
                    _buildConsentCard(
                      context,
                      icon: Icons.verified_user_outlined,
                      title: 'Maioridade (18+)',
                      subtitle:
                          'Declaro que tenho 18 anos ou mais e estou apto(a) a utilizar o aplicativo DESIADET e seus serviços.',
                      accepted: acceptedAge,
                      onTap: null,
                      onCheck: () {
                        setState(() => acceptedAge = !acceptedAge);
                      },
                      isSmallScreen: isSmallScreen,
                    ),

                    SizedBox(height: isSmallScreen ? 28 : 32),

                    // Accept button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (allAccepted && !_saving) ? _saveConsent : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF7C3AED).withValues(alpha: 0.4),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 18 : 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                allAccepted
                                    ? 'Aceitar e Continuar'
                                    : 'Aceite os dois documentos para continuar',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(
                      height: bottomInset + (isSmallScreen ? 32 : 48),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool accepted,
    VoidCallback? onTap,
    required VoidCallback onCheck,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accepted
              ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: accepted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onCheck,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7C3AED),
                    size: isSmallScreen ? 20 : 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onCheck,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accepted
                                  ? const Color(0xFF7C3AED)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accepted
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: accepted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onTap,
                        child: Row(
                          children: [
                            Text(
                              'Ler documento completo',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
    );
  }

  void _openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }
}