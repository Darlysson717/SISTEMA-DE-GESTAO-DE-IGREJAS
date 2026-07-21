import 'package:flutter/material.dart';

class TermSection {
  final IconData icon;
  final String title;
  final String content;

  const TermSection({
    required this.icon,
    required this.title,
    required this.content,
  });
}

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  bool accepted = false;

  static const String version = "1.2.0";
  static const String lastUpdate = "21/07/2026";

  final List<TermSection> sections = const [

    // ===== BASE LEGAL (Tópico 2) =====
    TermSection(
      icon: Icons.gavel_outlined,
      title: "BASE LEGAL - LGPD",
      content:
          "O tratamento de dados pessoais no DESIADET tem como base legal:\n\n"
          "• Consentimento (Art. 7º, I): Nome, e-mail, telefone, agendamentos e demais dados necessários ao funcionamento do aplicativo.\n"
          "• Consentimento específico (Art. 11, II): Dados de religião e saúde, tratados como dados sensíveis com autorização expressa do titular.\n"
          "• Legítimo interesse (Art. 10): Comunicações institucionais, melhorias do serviço, segurança do sistema.\n"
          "• Obrigação legal (Art. 7º, II): Retenção fiscal de 5 anos e demais obrigações previstas em lei.",
    ),

    // ===== CONDIÇÃO DE MAIORIDADE =====
    TermSection(
      icon: Icons.verified_user_outlined,
      title: "CONDIÇÃO DE MAIORIDADE",
      content:
          "O DESIADET é destinado exclusivamente a maiores de 18 (dezoito) anos. Ao utilizar o aplicativo, o usuário declara, sob sua inteira responsabilidade, que possui 18 anos ou mais. Menores de 18 anos não estão autorizados a criar conta ou utilizar os serviços do aplicato, salvo com autorização expressa do responsável legal nos termos da cláusula 16 (Proteção de Menores - ECA).",
    ),

    TermSection(
      icon: Icons.handshake_rounded,
      title: "1. Aceitação dos Termos",
      content:
          "Ao utilizar o aplicativo DESIADET, o usuário declara que leu, compreendeu e concorda integralmente com estes Termos de Uso e com a Política de Privacidade. Caso não concorde com qualquer disposição, deverá interromper imediatamente a utilização do aplicativo.",
    ),

    TermSection(
      icon: Icons.church,
      title: "2. Finalidade do Aplicativo",
      content:
          "O DESIADET é um aplicativo destinado à gestão de atividades do departamento social da igreja, permitindo agendamentos de serviços, divulgação de eventos, comunicação institucional, cadastro de voluntários e gerenciamento administrativo.",
    ),

    TermSection(
      icon: Icons.account_circle_outlined,
      title: "3. Cadastro e Conta",
      content:
          "O usuário compromete-se a fornecer informações verdadeiras, completas e atualizadas. O uso de informações falsas poderá resultar na suspensão ou exclusão da conta.",
    ),

    TermSection(
      icon: Icons.login_rounded,
      title: "4. Login com Conta Google",
      content:
          "O acesso ao aplicativo ocorre exclusivamente através da autenticação oficial do Google (Google Sign-In). O aplicativo não coleta, armazena ou processa a senha da Conta Google do usuário.",
    ),

    TermSection(
      icon: Icons.security_rounded,
      title: "5. Segurança da Conta Google",
      content:
          "As credenciais da Conta Google permanecem exclusivamente sob responsabilidade do Google. Mesmo em caso de incidente envolvendo os servidores do aplicativo, as senhas das contas Google não ficam armazenadas no sistema.",
    ),

    TermSection(
      icon: Icons.verified_user_outlined,
      title: "6. Responsabilidade do Usuário",
      content:
          "O usuário é responsável pela segurança de sua Conta Google, por manter seu dispositivo protegido e por não compartilhar seu acesso com terceiros.",
    ),

    TermSection(
      icon: Icons.folder_shared_outlined,
      title: "7. Dados Coletados",
      content:
          "O aplicativo poderá coletar nome, e-mail, telefone, foto de perfil, histórico de agendamentos, participação em eventos e demais informações estritamente necessárias para funcionamento dos serviços oferecidos.",
    ),

    TermSection(
      icon: Icons.lock_outline,
      title: "8. Proteção dos Dados",
      content:
          "Os dados pessoais serão tratados conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), utilizando medidas técnicas e administrativas adequadas para reduzir riscos de acesso não autorizado.",
    ),

    // ===== DADOS RELIGIOSOS (Tópico 6A) =====
    TermSection(
      icon: Icons.auto_awesome,
      title: "9. Dados Religiosos",
      content:
          "O aplicativo é do Departamento Social da Igreja. A crença religiosa é tratada como dado sensível (Art. 11 LGPD), com consentimento específico e garantia de não discriminação. O usuário tem o direito de não informar sua crença religiosa sem qualquer prejuízo no acesso aos serviços.",
    ),

    TermSection(
      icon: Icons.medical_services_outlined,
      title: "10. Serviços de Saúde",
      content:
          "O DESIADET atua exclusivamente como ferramenta de agendamento e gerenciamento de atendimentos. O aplicativo não realiza diagnósticos, prescrições, orientações médicas ou qualquer atividade privativa de profissionais da saúde.",
    ),

    TermSection(
      icon: Icons.psychology_outlined,
      title: "11. Atendimento Psicológico",
      content:
          "Os atendimentos psicológicos são de inteira responsabilidade do profissional habilitado. O aplicativo apenas intermedeia o agendamento, preservando o sigilo profissional e a confidencialidade das informações conforme a legislação vigente.",
    ),

    TermSection(
      icon: Icons.calendar_month_outlined,
      title: "12. Agendamentos",
      content:
          "Os horários disponibilizados dependem da agenda de cada profissional ou serviço. Agendamentos poderão ser remarcados, cancelados ou alterados por motivos operacionais, administrativos ou de força maior, sempre que possível mediante aviso ao usuário.",
    ),

    TermSection(
      icon: Icons.event_available_outlined,
      title: "13. Eventos",
      content:
          "Eventos poderão possuir número limitado de vagas. A administração poderá alterar datas, horários, locais ou cancelar eventos por necessidade organizacional, segurança ou motivo de força maior.",
    ),

    // ===== LEI DO VOLUNTARIADO (Tópico 6B) =====
    TermSection(
      icon: Icons.volunteer_activism_outlined,
      title: "14. Cadastro de Voluntários (Lei 9.608/98)",
      content:
          "O cadastro de voluntário é regido pela Lei nº 9.608/98: atividade não remunerada, sem vínculo empregatício. O cadastro como voluntário representa apenas manifestação de interesse em colaborar com as atividades da igreja. A realização do cadastro não garante convocação, aprovação ou participação em projetos específicos.",
    ),

    // ===== PROTEÇÃO DE MENORES (Tópico 6D) =====
    TermSection(
      icon: Icons.child_care_outlined,
      title: "15. Proteção de Menores (ECA)",
      content:
          "Menores de 18 anos: autorização expressa do responsável, nos termos do ECA (Lei nº 8.069/90). O responsável legal deverá autorizar o tratamento de dados e responderá pelas informações fornecidas e pela utilização da plataforma.",
    ),

    TermSection(
      icon: Icons.notifications_active_outlined,
      title: "16. Comunicações e Notificações",
      content:
          "O usuário concorda em receber notificações relacionadas a confirmações de agendamentos, cancelamentos, lembretes, eventos, campanhas sociais, comunicados institucionais e demais informações necessárias ao funcionamento do aplicativo.",
    ),

    TermSection(
      icon: Icons.gpp_good_outlined,
      title: "17. Segurança da Informação",
      content:
          "O DESIADET adota medidas de segurança compatíveis com as boas práticas do mercado, incluindo comunicação criptografada (HTTPS), autenticação segura, controle de acesso, registros de auditoria, backups periódicos e monitoramento dos sistemas. Embora sejam empregados esforços para proteger os dados pessoais, nenhum sistema computacional pode garantir segurança absoluta contra todos os tipos de ataques.",
    ),

    TermSection(
      icon: Icons.admin_panel_settings_outlined,
      title: "18. Administradores e Controle de Acesso",
      content:
          "Os administradores do sistema possuem acesso apenas às informações necessárias para o desempenho de suas funções. Todas as ações administrativas poderão ser registradas em logs para fins de auditoria, segurança, rastreabilidade e prevenção de fraudes.",
    ),

    TermSection(
      icon: Icons.account_balance_outlined,
      title: "19. Direitos do Titular dos Dados",
      content:
          "Nos termos da Lei Geral de Proteção de Dados (LGPD), o usuário poderá solicitar, quando aplicável, acesso aos seus dados pessoais, correção de informações incorretas, atualização cadastral, exclusão de dados, revogação do consentimento, informações sobre o tratamento realizado e demais direitos previstos na legislação.",
    ),

    TermSection(
      icon: Icons.warning_amber_rounded,
      title: "20. Limitação de Responsabilidade",
      content:
          "O Departamento Social da Igreja não será responsável por prejuízos decorrentes de falhas de conexão com a internet, indisponibilidade temporária do Google, Supabase, Firebase ou demais serviços de terceiros, problemas no dispositivo do usuário, compartilhamento indevido da Conta Google, fornecimento de informações incorretas pelo próprio usuário, utilização inadequada do aplicativo ou situações de caso fortuito e força maior.",
    ),

    TermSection(
      icon: Icons.report_problem_outlined,
      title: "21. Incidentes de Segurança",
      content:
          "Caso ocorra incidente de segurança envolvendo dados pessoais, a instituição adotará as medidas técnicas e administrativas cabíveis para reduzir os impactos, observando a legislação aplicável, inclusive a comunicação aos titulares dos dados e à Autoridade Nacional de Proteção de Dados (ANPD), quando legalmente exigido.",
    ),

    // ===== RETENÇÃO DE DADOS (Tópico 4) =====
    TermSection(
      icon: Icons.timer_outlined,
      title: "22. Retenção de Dados",
      content:
          "**RETENÇÃO:**\n"
          "• Conta ativa: dados mantidos enquanto a conta estiver ativa.\n"
          "• Após exclusão da conta: excluídos em até 30 dias.\n"
          "• Obrigação legal: 5 anos (dados fiscais, atendimentos).\n"
          "• O usuário pode solicitar exclusão antecipada a qualquer momento, exceto quando houver obrigação legal de retenção.",
    ),

    // ===== USO DE IMAGEM (Tópico 6E) =====
    TermSection(
      icon: Icons.photo_camera_outlined,
      title: "23. Uso de Imagem",
      content:
          "O usuário autoriza o uso de sua imagem para divulgação institucional, podendo revogar a qualquer momento. A autorização é específica e separada dos demais consentimentos. O usuário pode solicitar a remoção de imagens a qualquer tempo através do e-mail dpo@desiadet.com.",
    ),

    // ===== DPO (Tópico 5) =====
    TermSection(
      icon: Icons.contact_mail_outlined,
      title: "24. Encarregado (DPO)",
      content:
          "**ENCARREGADO (DPO):**\n"
          "• Nome: [NOME DO DPO]\n"
          "• E-mail: dpo@desiadet.com\n"
          "• Telefone: (XX) XXXX-XXXX\n\n"
          "O Encarregado pelo tratamento de dados pessoais está disponível para esclarecer dúvidas, receber solicitações e garantir o exercício dos direitos dos titulares nos termos da LGPD.",
    ),

    TermSection(
      icon: Icons.edit_document,
      title: "25. Alterações dos Termos",
      content:
          "Os presentes Termos de Uso poderão ser alterados a qualquer momento para adequação à legislação, melhorias do aplicativo ou atualização dos serviços oferecidos. Quando houver alterações relevantes, os usuários serão comunicados e poderão ser solicitados a realizar uma nova aceitação antes de continuar utilizando o aplicativo.",
    ),

    TermSection(
      icon: Icons.gavel_outlined,
      title: "26. Foro e Legislação Aplicável",
      content:
          "Estes Termos de Uso são regidos pelas leis da República Federativa do Brasil, especialmente pela Lei Geral de Proteção de Dados (Lei nº 13.709/2018), pelo Código Civil e demais normas aplicáveis. Fica eleito o foro da comarca da sede da Igreja para dirimir eventuais controvérsias, ressalvadas as hipóteses previstas em lei.",
    ),

    TermSection(
      icon: Icons.info_outline,
      title: "27. Disposições Finais",
      content:
          "Ao utilizar o DESIADET, o usuário declara que leu, compreendeu e concorda com estes Termos de Uso e com a Política de Privacidade. Este documento representa a versão oficial dos Termos do aplicativo e poderá ser atualizado sempre que necessário. Recomenda-se sua revisão periódica.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 20 : 32,
                  topInset + (isSmallScreen ? 20 : 32),
                  isSmallScreen ? 20 : 32,
                  isSmallScreen ? 24 : 32,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Termos de Uso',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Versão $version | Atualizada em $lastUpdate',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = sections[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < sections.length - 1 ? 16 : 0,
                      ),
                      child: _buildSectionCard(section, isSmallScreen),
                    );
                  },
                  childCount: sections.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 16 : 24,
                  0,
                  isSmallScreen ? 16 : 24,
                  isSmallScreen ? 32 : 48,
                ),
                child: Center(
                  child: Text(
                    'DESIADET - Departamento Social IADET \n© 2026 - Todos os direitos reservados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF64748B).withValues(alpha: 0.7),
                      fontSize: isSmallScreen ? 11 : 12,
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

  Widget _buildSectionCard(TermSection section, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  section.icon,
                  color: const Color(0xFF7C3AED),
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            section.content,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}