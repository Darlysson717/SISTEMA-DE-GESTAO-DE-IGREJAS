import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_detalhes_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/dialogo_whatsapp_voluntario.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/card_feed_evento.dart';
import 'package:centro_social_app/src/funcionalidades/perfil/apresentacao/telas/pagina_perfil.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_detalhes_servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agendamentos_usuario.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/provedores/provedores_atualizacao.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const HomePage({
    super.key,
    this.currentUser = const AppUser(
      id: 'user-demo',
      email: 'usuario@iadet.app',
      nome: 'Usuario',
    ),
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  final List<ScrollController> _chipsControllers = List.generate(
    3,
    (_) => ScrollController(),
  );
  double _chipsScrollOffset = 0;

  @override
  void dispose() {
    for (final controller in _chipsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setCurrentIndex(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() => _currentIndex = index);
    _syncChipOffsetForIndex(index);
  }

  void _syncChipOffsetForIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final controller = _chipsControllers[index];
      if (!controller.hasClients) {
        return;
      }

      final target = _chipsScrollOffset.clamp(
        0.0,
        controller.position.maxScrollExtent,
      );

      if ((controller.offset - target).abs() < 1) {
        return;
      }

      controller.jumpTo(target);
    });
  }

  String? _resolveCurrentUserPhotoUrl() {
    final authUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final metadata = authUser?.userMetadata;

    final candidates = <String?>[
      metadata?['avatar_url'] as String?,
      metadata?['picture'] as String?,
      metadata?['photo_url'] as String?,
      metadata?['image'] as String?,
    ];

    for (final value in candidates) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }

  SliverToBoxAdapter _buildNavigationChips(int selectedIndex) {
    final controller = _chipsControllers[selectedIndex];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.horizontal) {
                  _chipsScrollOffset = notification.metrics.pixels;
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _NavigationChip(
                      label: 'Inicio',
                      icon: Icons.home_outlined,
                      isSelected: _currentIndex == 0,
                      onTap: () => _setCurrentIndex(0),
                    ),
                    const SizedBox(width: 12),
                    _NavigationChip(
                      label: 'Agendamentos',
                      icon: Icons.event_note_outlined,
                      isSelected: _currentIndex == 1,
                      onTap: () => _setCurrentIndex(1),
                    ),
                    const SizedBox(width: 12),
                    _NavigationChip(
                      label: 'Perfil',
                      icon: Icons.person_outline,
                      isSelected: _currentIndex == 2,
                      onTap: () => _setCurrentIndex(2),
                    ),
                  ],
                ),
              ),
            ),
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
                  child: const Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: Color(0xFF6366F1),
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
                  child: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final updateAsync = ref.watch(appUpdateProvider);

    return PopScope(
      canPop: _currentIndex == 0, // Permite fechar apenas na primeira aba
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex > 0) {
          setState(() => _currentIndex--);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Comunidade IADET')),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildInicioTab(context, eventsAsync, updateAsync),
            _buildAgendamentosTab(context),
            _buildPerfilTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInicioTab(
    BuildContext context,
    AsyncValue<List<AppEvent>> eventsAsync,
    AsyncValue<AppUpdateInfo?> updateAsync,
  ) {
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Header atrativo
          SliverToBoxAdapter(
            child: Container(
              padding: headerPadding,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1), // Indigo
                    Color(0xFF8B5CF6), // Purple
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
                          Icons.waving_hand,
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
                              'Olá, seja bem-vindo!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Comunidade IADET',
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
                            'Aqui você encontra eventos, atendimentos e serviços gratuitos da nossa comunidade.',
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

          _buildNavigationChips(0),

          updateAsync.when(
            data: (updateInfo) {
              if (updateInfo == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding.left,
                    20,
                    contentPadding.right,
                    0,
                  ),
                  child: _buildUpdateCard(
                    context,
                    updateInfo,
                    isSmallScreen,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Seção de Eventos
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left,
                isSmallScreen ? 32 : 48,
                contentPadding.right,
                isSmallScreen ? 16 : 20,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_available,
                      color: const Color(0xFF6366F1),
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Text(
                    'Eventos e ações em destaque',
                    style: TextStyle(
                      fontSize: sectionTitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: contentPadding,
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                      child: const Text(
                        'Nenhum evento publicado no momento.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: contentPadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final event = events[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == events.length - 1
                            ? 0
                            : (isSmallScreen ? 16 : 20),
                      ),
                      child: EventFeedCard(
                        event: event,
                        onCardTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsPage(event: event),
                            ),
                          );
                        },
                        onPrimaryAction: () => _registerEventInterest(
                          context,
                          event,
                          EventInterestType.participante,
                        ),
                        onVolunteerAction: event.permitirVoluntarios
                            ? () => _registerEventInterest(
                                context,
                                event,
                                EventInterestType.voluntario,
                              )
                            : null,
                      ),
                    );
                  }, childCount: events.length),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: contentPadding,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Erro ao carregar eventos: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Espaço final considerando bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: (isSmallScreen ? 32 : 48) + bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    AppUpdateInfo updateInfo,
    bool isSmallScreen,
  ) {
    final verticalPadding = isSmallScreen ? 18.0 : 22.0;
    final horizontalPadding = isSmallScreen ? 18.0 : 22.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.system_update_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            updateInfo.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nova versão: ${updateInfo.displayVersion}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  updateInfo.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: isSmallScreen ? 14 : 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openUpdateLink(updateInfo.link),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir atualização no GitHub'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpdateLink(String link) async {
    final uri = Uri.parse(link);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _registerEventInterest(
    BuildContext context,
    AppEvent event,
    EventInterestType interestType,
  ) async {
    final volunteerWhatsapp = interestType == EventInterestType.voluntario
        ? await _askVolunteerWhatsapp(context)
        : null;

    if (!context.mounted) return;
    if (interestType == EventInterestType.voluntario &&
        volunteerWhatsapp == null) {
      return;
    }

    try {
      await ref
          .read(eventsRepositoryProvider)
          .registerInterest(
            eventId: event.id,
            interestType: interestType,
            volunteerWhatsapp: volunteerWhatsapp,
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            interestType == EventInterestType.participante
                ? 'Participação registrada em "${event.nome}"'
                : 'Interesse em voluntariado registrado em "${event.nome}". Aguarde ser chamado pelo organizador do evento.',
          ),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nao foi possivel registrar: $error'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<String?> _askVolunteerWhatsapp(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const VolunteerWhatsappDialog(),
    );

    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  void _showServiceDetails(BuildContext context, Service service) {
    // Navegar para a tela de detalhes do serviço
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsPage(service: service),
      ),
    );
  }

  Widget _buildAgendamentosTab(BuildContext context) {
    final servicesAsync = ref.watch(publishedServicesProvider);
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Header atrativo para Agendamentos
          SliverToBoxAdapter(
            child: Container(
              padding: headerPadding,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF059669), // Green
                    Color(0xFF0D9488), // Teal
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
                          Icons.calendar_month,
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
                              'Meus Agendamentos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Gerencie seus compromissos',
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
                            'Aqui você pode visualizar seus agendamentos e encontrar novos serviços disponíveis.',
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

          _buildNavigationChips(1),

          // Conteúdo dos agendamentos
          SliverPadding(
            padding: contentPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: isSmallScreen ? 32 : 48),

                // Próximo atendimento
                InkWell(
                  onTap: () {
                    // Navegar para a tela de agendamentos do usuário
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserAppointmentsPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
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
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.pending_actions_outlined,
                            color: const Color(0xFFF59E0B),
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 20),
                        Expanded(
                          child: Text(
                            'Próximo atendimento',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: isSmallScreen ? 16 : 20,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 32 : 48),

                // Seção de Serviços Disponíveis
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: const Color(0xFF059669),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Text(
                      'Serviços disponíveis',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Lista de serviços
                servicesAsync.when(
                  data: (services) {
                    if (services.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
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
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.medical_services,
                                size: isSmallScreen ? 48 : 64,
                                color: const Color(0xFF94A3B8),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              Text(
                                'Nenhum serviço disponível no momento.',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: services
                          .map(
                            (service) => Padding(
                              padding: EdgeInsets.only(
                                bottom: isSmallScreen ? 16 : 20,
                              ),
                              child: _ServiceCard(
                                service: service,
                                onShowDetails: _showServiceDetails,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => Container(
                    padding: EdgeInsets.all(isSmallScreen ? 40 : 60),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => Container(
                    padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
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
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isSmallScreen ? 48 : 64,
                            color: const Color(0xFFEF4444),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Text(
                            'Erro ao carregar serviços',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Text(
                            error.toString(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
    );
  }

  Widget _buildPerfilTab(BuildContext context) {
    ref.watch(authStateChangesProvider);

    return ProfilePage(
      user: widget.currentUser,
      commitmentsCount: 3,
      photoUrl: _resolveCurrentUserPhotoUrl(),
      showNavigationChips: true,
      onNavigateToInicio: () => _setCurrentIndex(0),
      onNavigateToAgendamentos: () => _setCurrentIndex(1),
      onNavigateToPerfil: () => _setCurrentIndex(2),
      onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      currentIndex: _currentIndex,
      chipsScrollController: _chipsControllers[2],
      onChipsScroll: (offset) => _chipsScrollOffset = offset,
      chipsScrollOffset: _chipsScrollOffset,
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final void Function(BuildContext, Service) onShowDetails;

  const _ServiceCard({required this.service, required this.onShowDetails});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onShowDetails(context, service),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: service.imagemProfissional != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(
                              service.imagemProfissional!,
                            ),
                            radius: isSmallScreen ? 24 : 28,
                          )
                        : CircleAvatar(
                            radius: isSmallScreen ? 24 : 28,
                            backgroundColor: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              color: const Color(0xFF059669),
                              size: isSmallScreen ? 24 : 28,
                            ),
                          ),
                  ),
                  SizedBox(width: isSmallScreen ? 16 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.nome,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          service.nomeProfissional,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.categoria,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (service.descricao.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 16 : 20),
                Text(
                  service.descricao,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: isSmallScreen ? 16 : 20),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;

                    final durationInfo = _ServiceInfoBlock(
                      icon: Icons.access_time,
                      iconColor: const Color(0xFFF59E0B),
                      iconBackground: const Color(0xFFF59E0B),
                      title: 'Duração',
                      value: '${service.duracaoAtendimento ?? 60} min',
                      isSmallScreen: isSmallScreen,
                    );

                    final attendanceInfo = _ServiceInfoBlock(
                      icon: service.tipoAtendimento == 'presencial'
                          ? Icons.location_on
                          : Icons.videocam,
                      iconColor: service.tipoAtendimento == 'presencial'
                          ? const Color(0xFF059669)
                          : const Color(0xFF6366F1),
                      iconBackground: service.tipoAtendimento == 'presencial'
                          ? const Color(0xFF059669)
                          : const Color(0xFF6366F1),
                      title: 'Atendimento',
                      value: service.tipoAtendimento == 'presencial'
                          ? 'Presencial'
                          : 'Online',
                      isSmallScreen: isSmallScreen,
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          durationInfo,
                          const SizedBox(height: 12),
                          attendanceInfo,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: durationInfo),
                        SizedBox(width: isSmallScreen ? 16 : 20),
                        Expanded(child: attendanceInfo),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _ServiceInfoBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final bool isSmallScreen;

  const _ServiceInfoBlock({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: iconBackground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
