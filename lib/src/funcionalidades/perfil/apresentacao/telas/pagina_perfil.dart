import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/telas/pagina_painel_admin.dart';
import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_acesso_publicar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_meus_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/componentes/tile_acao_perfil.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_meus_servicos.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_acesso_publicar_servico.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/provedores/provedores_atualizacao.dart';
import 'package:centro_social_app/src/nucleo/utilitarios/layout_responsivo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerWidget {
  final AppUser user;
  final int commitmentsCount;
  final String? photoUrl;
  final bool showNavigationChips;
  final VoidCallback? onNavigateToInicio;
  final VoidCallback? onNavigateToAgendamentos;
  final VoidCallback? onNavigateToPerfil;
  final VoidCallback? onLogout;
  final int currentIndex;
  final ScrollController? chipsScrollController;
  final ValueChanged<double>? onChipsScroll;
  final double chipsScrollOffset;

  const ProfilePage({
    super.key,
    required this.user,
    this.commitmentsCount = 0,
    this.photoUrl,
    this.showNavigationChips = false,
    this.onNavigateToInicio,
    this.onNavigateToAgendamentos,
    this.onNavigateToPerfil,
    this.onLogout,
    this.currentIndex = 0,
    this.chipsScrollController,
    this.onChipsScroll,
    this.chipsScrollOffset = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;

    final headerPadding = isSmallScreen
        ? const EdgeInsets.fromLTRB(16, 12, 16, 16)
        : const EdgeInsets.fromLTRB(24, 16, 24, 20);

    final contentPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 24);

    final titleFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
    final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final sectionTitleFontSize = isSmallScreen ? 16.0 : 18.0;

    final isAdmin = ref
        .watch(isCurrentUserAdminProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);

    final actions = _buildActions(context, ref, isAdmin);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(isCurrentUserAdminProvider);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ResponsiveLayout(
          padding: EdgeInsets.zero,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: headerPadding,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF6366F1),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: isSmallScreen ? 22 : 26,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meu Perfil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  'Gerencie sua conta e atividades',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w300,
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

              // Chips de navegação removidos - agora usa sidebar no desktop

              SliverPadding(
                padding: contentPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: isSmallScreen ? 32 : 48),

                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: isSmallScreen ? 40 : 48,
                            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                            child: photoUrl == null
                                ? Icon(Icons.person, size: isSmallScreen ? 40 : 48, color: const Color(0xFF7C3AED))
                                : null,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Text(
                            user.nome ?? 'Usuário',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 32 : 48),

                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bolt,
                            color: const Color(0xFF7C3AED),
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Text(
                          'Ações rápidas',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: isSmallScreen ? 8 : 12,
                        mainAxisSpacing: isSmallScreen ? 8 : 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: actions.length,
                      itemBuilder: (context, index) {
                        return actions[index];
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Developed by Darlison de Sousa',
                              style: TextStyle(
                                color: const Color(0xFF64748B).withValues(alpha: 0.85),
                                fontSize: isSmallScreen ? 12 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const _AppVersionBadge(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: (isSmallScreen ? 32 : 48) + bottomPadding + 80,
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

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, bool isAdmin) {
    final actions = <Widget>[
      ProfileActionTile(
        icon: Icons.medical_services_outlined,
        label: 'Anunciar Serviço',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublishServiceAccessPage()),
          );
        },
      ),
      ProfileActionTile(
        icon: Icons.campaign_outlined,
        label: 'Anunciar Evento',
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublishEventAccessPage()),
          );
          ref.invalidate(myEventsProvider);
          ref.invalidate(publishedEventsProvider);
        },
      ),
      ProfileActionTile(
        icon: Icons.event_note_outlined,
        label: 'Meus Eventos',
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyEventsPage()),
          );
          ref.invalidate(myEventsProvider);
          ref.invalidate(publishedEventsProvider);
        },
      ),
      ProfileActionTile(
        icon: Icons.work_outline,
        label: 'Meus Serviços',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyServicesPage()),
          );
        },
      ),
      ProfileActionTile(
        icon: Icons.logout_outlined,
        label: 'Sair',
        onTap: onLogout ?? () {},
      ),
    ];

    if (isAdmin) {
      actions.insert(
        actions.length - 1,
        ProfileActionTile(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Administrador',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanelPage()),
            );
          },
        ),
      );
    }

    return actions;
  }
}

class _AppVersionBadge extends ConsumerWidget {
  const _AppVersionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(packageInfoProvider);

    return packageAsync.when(
      data: (info) {
        final versionStr = '${info.version}+${info.buildNumber}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'v$versionStr',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF6366F1).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

