import 'package:flutter/material.dart';

class PolicySection {
  final IconData icon;
  final String title;
  final String content;

  const PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String version = "1.0.0";
  static const String lastUpdate = "21/07/2026";

  static const List<PolicySection> sections = [
    PolicySection(
      icon: Icons.info_outline,
      title: "1. Introdução",
      content:
          "Esta Política de Privacidade descreve como o aplicativo DESIADET, do Departamento Social da Igreja, coleta, usa, armazena, compartilha e protege os dados pessoais dos usuários, em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 - LGPD). Ao utilizar o aplicativo, o usuário declara que leu e compreendeu esta Política.",
    ),
    PolicySection(
      icon: Icons.assignment_outlined,
      title: "2. Dados Coletados",
      content:
          "O DESIADET coleta os seguintes dados pessoais dos usuários:\n\n"
          "a) Dados de identificação: Nome completo, e-mail, telefone, foto do perfil (via Google Sign-In).\n"
          "b) Dados de serviços: Histórico de agendamentos, serviços solicitados, preferências de horário.\n"
          "c) Dados de eventos: Participação em eventos, confirmações de presença.\n"
          "d) Dados de voluntariado: Interesse em atividades voluntárias, habilidades informadas.\n"
          "e) Dados sensíveis (mediante consentimento específico): Crença religiosa, dados de saúde necessários para atendimentos.\n"
          "f) Dados de imagem: Fotos e vídeos institucionais (mediante autorização específica).\n"
          "g) Dados técnicos: Endereço IP, tipo de dispositivo, versão do sistema operacional, registro de acesso (logs).",
    ),
    PolicySection(
      icon: Icons.flag_outlined,
      title: "3. Finalidades do Tratamento",
      content:
          "Os dados coletados são utilizados para as seguintes finalidades:\n\n"
          "a) Identificação e autenticação do usuário no aplicativo.\n"
          "b) Gerenciamento de agendamentos de serviços.\n"
          "c) Divulgação e gestão de eventos.\n"
          "d) Cadastro e comunicação com voluntários.\n"
          "e) Comunicações institucionais, lembretes e notificações.\n"
          "f) Melhoria contínua dos serviços oferecidos.\n"
          "g) Cumprimento de obrigações legais e regulatórias.\n"
          "h) Segurança e auditoria do sistema.\n"
          "i) Divulgação institucional (mediante autorização de uso de imagem).",
    ),
    PolicySection(
      icon: Icons.share_outlined,
      title: "4. Compartilhamento de Dados",
      content:
          "O DESIADET poderá compartilhar dados dos usuários com:\n\n"
          "a) Google: Autenticação via Google Sign-In (nome, e-mail, foto do perfil). O Google possui sua própria política de privacidade.\n"
          "b) Supabase: Plataforma de banco de dados e autenticação onde os dados são armazenados de forma segura e criptografada.\n"
          "c) Firebase (Google): Notificações push e analytics. Os dados são tratados conforme as políticas do Google.\n"
          "d) Profissionais e voluntários da igreja: Informações estritamente necessárias para a prestação dos serviços.\n"
          "e) Autoridades competentes: Quando exigido por lei, ordem judicial ou solicitação da ANPD.\n\n"
          "O aplicativo NÃO vende dados pessoais para terceiros.",
    ),
    PolicySection(
      icon: Icons.timer_outlined,
      title: "5. Retenção dos Dados",
      content:
          "Os prazos de retenção dos dados são:\n\n"
          "a) Conta ativa: Os dados são mantidos enquanto o usuário mantiver sua conta ativa no aplicativo.\n"
          "b) Exclusão da conta: Após solicitação de exclusão, os dados serão removidos em até 30 dias.\n"
          "c) Obrigação legal: Dados fiscais e registros de atendimentos serão mantidos por 5 anos para cumprimento de obrigações legais.\n"
          "d) Dados de saúde: Serão mantidos pelo período necessário à prestação dos serviços e conforme prazos legais aplicáveis.\n"
          "e) Logs de acesso: Mantidos por 6 meses conforme art. 12 do Marco Civil da Internet.\n"
          "f) Solicitação de exclusão antecipada: O usuário pode solicitar a exclusão antecipada de seus dados a qualquer momento, exceto quando houver obrigação legal de retenção.",
    ),
    PolicySection(
      icon: Icons.gpp_good_outlined,
      title: "6. Direitos do Titular dos Dados",
      content:
          "Nos termos da LGPD, o usuário possui os seguintes direitos, que podem ser exercidos através do e-mail dpo@desiadet.com:\n\n"
          "a) Confirmação da existência de tratamento de dados.\n"
          "b) Acesso aos dados pessoais tratados.\n"
          "c) Correção de dados incompletos, inexatos ou desatualizados.\n"
          "d) Anonimização, bloqueio ou eliminação de dados desnecessários.\n"
          "e) Portabilidade dos dados a outro fornecedor de serviço.\n"
          "f) Eliminação dos dados tratados com consentimento.\n"
          "g) Informação sobre compartilhamento de dados.\n"
          "h) Revogação do consentimento a qualquer momento.\n"
          "i) Oposição ao tratamento, quando aplicável.\n"
          "j) Revisão de decisões automatizadas.",
    ),
    PolicySection(
      icon: Icons.security_outlined,
      title: "7. Segurança dos Dados",
      content:
          "O DESIADET adota medidas técnicas e administrativas para proteger os dados pessoais, incluindo:\n\n"
          "a) Comunicação criptografada via HTTPS/TLS.\n"
          "b) Autenticação segura via Google Sign-In.\n"
          "c) Controle de acesso baseado em papéis (RBAC).\n"
          "d) Registros de auditoria (logs).\n"
          "e) Backups periódicos.\n"
          "f) Monitoramento de segurança.\n"
          "g) Criptografia em repouso dos dados sensíveis.\n\n"
          "Embora adotemos as melhores práticas de segurança, nenhum sistema é absolutamente seguro contra todos os tipos de ameaças.",
    ),
    PolicySection(
      icon: Icons.people_outline,
      title: "8. Dados de Menores",
      content:
          "Menores de 18 anos somente podem utilizar o aplicativo com autorização expressa de seus pais ou responsáveis legais, nos termos do Estatuto da Criança e do Adolescente (Lei nº 8.069/90). O responsável legal responde por todas as informações fornecidas e pela utilização da plataforma.",
    ),
    PolicySection(
      icon: Icons.contact_mail_outlined,
      title: "9. Encarregado (DPO)",
      content:
          "O Encarregado pelo tratamento de dados pessoais (Data Protection Officer - DPO) pode ser contatado para esclarecimentos, solicitações ou exercício dos direitos do titular:\n\n"
          "E-mail: dpo@desiadet.com\n\n"
          "O DPO é responsável por receber reclamações, solicitações e fornecer informações sobre o tratamento de dados.",
    ),
    PolicySection(
      icon: Icons.update_outlined,
      title: "10. Atualizações desta Política",
      content:
          "Esta Política de Privacidade poderá ser atualizada a qualquer momento para refletir mudanças na legislação, nos serviços oferecidos ou nas práticas de tratamento de dados. Quando houver alterações relevantes, os usuários serão notificados. Recomenda-se a revisão periódica desta política.",
    ),
    PolicySection(
      icon: Icons.gavel_outlined,
      title: "11. Legislação Aplicável e Foro",
      content:
          "Esta Política de Privacidade é regida pela Lei Geral de Proteção de Dados (Lei nº 13.709/2018), pelo Marco Civil da Internet (Lei nº 12.965/2014) e demais normas aplicáveis. Fica eleito o foro da comarca da sede da Igreja para dirimir eventuais controvérsias, ressalvadas as hipóteses previstas em lei.",
    ),
    PolicySection(
      icon: Icons.contact_support_outlined,
      title: "12. Contato",
      content:
          "Para dúvidas, solicitações ou exercício dos direitos do titular, entre em contato conosco:\n\n"
          "E-mail do DPO: dpo@desiadet.com\n\n"
          "Estamos à disposição para esclarecer qualquer questão relacionada à privacidade e proteção de dados.",
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
                                'Política de Privacidade',
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
                    'DESIADET - Departamento Social IADET\n© 2026 - Todos os direitos reservados',
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

  Widget _buildSectionCard(PolicySection section, bool isSmallScreen) {
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