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
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/telas/pagina_termos_servico.dart';
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/telas/pagina_politica_privacidade.dart';
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

    final topInset = MediaQuery.of(context).padding.top;
    final headerPadding = isSmallScreen
      ? EdgeInsets.fromLTRB(20, topInset + 20, 20, 32)
      : EdgeInsets.fromLTRB(32, topInset + 32, 32, 48);

    final contentPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 24);

    final extraBottomGap = showNavigationChips ? 16.0 : 0.0;
    final bottomSpacing = bottomPadding + (isSmallScreen ? extraBottomGap : 0.0);

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

                // Chips de navegação (aparecem em PWA mobile e Android)
                if (showNavigationChips)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: SizedBox(
                        height: 56,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.axis == Axis.horizontal) {
                              onChipsScroll?.call(notification.metrics.pixels);
                            }
                            return false;
                          },
                          child: ListView(
                            controller: chipsScrollController,
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildNavChip('Início', Icons.home_outlined),
                              const SizedBox(width: 12),
                              _buildNavChip('Agendamentos', Icons.event_note_outlined),
                              const SizedBox(width: 12),
                              _buildNavChip('Perfil', Icons.person_outline),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isSmallScreen ? 12 : 16,
                          ),
                          child: actions[index],
                        );
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
                      height: (isSmallScreen ? 32 : 48) + bottomSpacing + 80,
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
      // ===== LGPD SECTION =====
      ProfileActionTile(
        icon: Icons.description_outlined,
        label: 'Termos de Uso',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
          );
        },
      ),
      ProfileActionTile(
        icon: Icons.privacy_tip_outlined,
        label: 'Política de Privacidade',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
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

  Widget _buildNavChip(String label, IconData icon) {
    final isSelected = currentIndex == (label == 'Início' ? 0 : label == 'Agendamentos' ? 1 : 2);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        if (label == 'Início') {
          onNavigateToInicio?.call();
        } else if (label == 'Agendamentos') {
          onNavigateToAgendamentos?.call();
        } else if (label == 'Perfil') {
          onNavigateToPerfil?.call();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF6366F1),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
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

