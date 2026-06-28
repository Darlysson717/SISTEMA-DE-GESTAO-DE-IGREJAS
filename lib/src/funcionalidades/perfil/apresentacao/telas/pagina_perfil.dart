import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/telas/pagina_painel_admin.dart';
import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_acesso_publicar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_anunciar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_meus_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/componentes/tile_acao_perfil.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_meus_servicos.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_acesso_publicar_servico.dart';
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

    // Ajustes responsivos
    final headerPadding = isSmallScreen
        ? const EdgeInsets.fromLTRB(20, 20, 20, 32)
        : const EdgeInsets.fromLTRB(32, 32, 32, 48);

    final contentPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 32);

    final titleFontSize = isSmallScreen ? 24.0 : (isMediumScreen ? 28.0 : 32.0);
    final subtitleFontSize = isSmallScreen ? 16.0 : 18.0;
    final sectionTitleFontSize = isSmallScreen ? 18.0 : 20.0;
    final hasValidChipOffset = chipsScrollOffset >= 0;

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
        child: CustomScrollView(
          slivers: [
            // Header atrativo para Perfil
            SliverToBoxAdapter(
              child: Container(
                padding: headerPadding,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7C3AED), // Purple
                      Color(0xFF6366F1), // Indigo
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
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: isSmallScreen ? 28 : 32,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 20),
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
                              SizedBox(height: isSmallScreen ? 4 : 8),
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
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: isSmallScreen ? 24 : 28,
                          ),
                          SizedBox(width: isSmallScreen ? 16 : 20),
                          Expanded(
                            child: Text(
                              'Aqui você pode gerenciar seus dados, anúncios e acompanhar suas atividades no centro social.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 14 : 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navegação por chips (se habilitado)
            if (showNavigationChips && hasValidChipOffset) ...[
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis == Axis.horizontal) {
                            onChipsScroll?.call(notification.metrics.pixels);
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: chipsScrollController,
                          child: Row(
                            children: [
                              _NavigationChip(
                                label: 'Inicio',
                                icon: Icons.home_outlined,
                                isSelected: currentIndex == 0,
                                onTap: onNavigateToInicio ?? () {},
                              ),
                              const SizedBox(width: 12),
                              _NavigationChip(
                                label: 'Agendamentos',
                                icon: Icons.event_note_outlined,
                                isSelected: currentIndex == 1,
                                onTap: onNavigateToAgendamentos ?? () {},
                              ),
                              const SizedBox(width: 12),
                              _NavigationChip(
                                label: 'Perfil',
                                icon: Icons.person_outline,
                                isSelected: currentIndex == 2,
                                onTap: onNavigateToPerfil ?? () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Indicadores de scroll com setas
                      Positioned(
                        left: -12,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -12,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Conteúdo do perfil
            SliverPadding(
              padding: contentPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Card do perfil do usuário
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
                          backgroundColor: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.1),
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 40 : 48,
                                  color: const Color(0xFF7C3AED),
                                )
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

                  // Seção de Ações Rápidas
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

                  // Grid de ações
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 700 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: actions.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isSmallScreen ? 12 : 16,
                          mainAxisSpacing: isSmallScreen ? 12 : 16,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) => actions[index],
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'Developed by Darlison de Sousa / DS TECH',
                        style: TextStyle(
                          color: const Color(0xFF64748B).withValues(alpha: 0.85),
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Espaço final
                  SizedBox(
                    height: (isSmallScreen ? 32 : 48) + bottomPadding + 80,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    bool isAdmin,
  ) {
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

class _NavigationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      onSelected: (_) => onTap(),
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