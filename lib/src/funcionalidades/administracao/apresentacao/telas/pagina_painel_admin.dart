import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  final _emailController = TextEditingController();
  bool _isSavingAdmin = false;
  bool _isCleaningStorage = false;
  bool _isExportingServices = false;
  bool _isExportingEventsSummary = false;
  String? _reviewingRequestId;
  String? _revokingUserId;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isCurrentUserAdminProvider);
    final isSuperAdmin = ref.watch(isCurrentUserSuperAdminProvider);
    final adminsAsync = ref.watch(adminUsersProvider);
    final authenticatedUsersCountAsync = ref.watch(
      authenticatedUsersCountProvider,
    );
    final pendingRequestsAsync = ref.watch(pendingPublishRequestsProvider);
    final authorizedPublishersAsync = ref.watch(authorizedPublishersProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        toolbarTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFFF8FAFC)],
                  stops: [0.0, 0.28],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _AdminHeroCard(
                    title: 'Acesso restrito',
                    subtitle:
                        'Somente administradores podem visualizar esta área.',
                    icon: Icons.lock_outline,
                    accentColor: const Color(0xFFEA580C),
                  ),
                ),
              ),
            );
          }

          final dashboardBackground = const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFFF8FAFC)],
              stops: [0.0, 0.26],
            ),
          );

          return Container(
            decoration: dashboardBackground,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(isCurrentUserAdminProvider);
                ref.invalidate(adminUsersProvider);
                ref.invalidate(authenticatedUsersCountProvider);
                ref.invalidate(pendingPublishRequestsProvider);
                ref.invalidate(authorizedPublishersProvider);
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
                children: [
                  _AdminHeroCard(
                    title: 'Painel do administrador',
                    subtitle: isSuperAdmin
                        ? 'Você está no modo super admin, com acesso total às ferramentas de gestão.'
                        : 'Você está no modo administrador, com foco em aprovações e acompanhamento.',
                    icon: Icons.admin_panel_settings_outlined,
                    accentColor: const Color(0xFF6366F1),
                    chipText: isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          label: 'Admins',
                          value: adminsAsync.maybeWhen(
                            data: (admins) => admins.length.toString(),
                            orElse: () => '...',
                          ),
                          icon: Icons.shield_outlined,
                          accentColor: const Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminStatCard(
                          label: 'Pedidos pendentes',
                          value: pendingRequestsAsync.maybeWhen(
                            data: (requests) => requests.length.toString(),
                            orElse: () => '...',
                          ),
                          icon: Icons.pending_actions_outlined,
                          accentColor: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          label: 'Autorizados',
                          value: authorizedPublishersAsync.maybeWhen(
                            data: (publishers) => publishers.length.toString(),
                            orElse: () => '...',
                          ),
                          icon: Icons.verified_user_outlined,
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminStatCard(
                          label: 'Acesso',
                          value: isSuperAdmin ? 'Total' : 'Limitado',
                          icon: Icons.lock_open_outlined,
                          accentColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AdminStatCard(
                    label: 'Usuários autenticados',
                    value: authenticatedUsersCountAsync.maybeWhen(
                      data: (count) => count.toString(),
                      orElse: () => '...',
                    ),
                    icon: Icons.people_alt_outlined,
                    accentColor: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestão de Administradores',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSuperAdmin
                              ? 'Você é SUPER ADMIN e pode adicionar/remover administradores.'
                              : 'Você é administrador.',
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                        if (isSuperAdmin) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail para promover a administrador',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isSavingAdmin ? null : _handleAddAdmin,
                            icon: _isSavingAdmin
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1),
                            label: const Text('Adicionar administrador'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autorizados a publicar serviços',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lista de pessoas com permissão ativa para publicar serviços.',
                            style: TextStyle(color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),
                          authorizedPublishersAsync.when(
                            data: (publishers) {
                              if (publishers.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Nenhuma pessoa autorizada no momento.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                );
                              }

                              return Column(
                                children: publishers
                                    .map(
                                      (publisher) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.verified_user_outlined,
                                          color: Color(0xFF2563EB),
                                        ),
                                        title: Text(
                                          publisher.fullName
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? publisher.fullName!
                                              : publisher.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          publisher.email,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        trailing: OutlinedButton.icon(
                                          onPressed:
                                              _revokingUserId ==
                                                      publisher.userId ||
                                                  publisher.isSuperAdmin
                                              ? null
                                              : () =>
                                                    _handleRevokePublishPermission(
                                                      publisher.userId,
                                                      publisher.email,
                                                    ),
                                          icon:
                                              _revokingUserId ==
                                                  publisher.userId
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.block_outlined,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            publisher.isSuperAdmin
                                                ? 'Protegido'
                                                : 'Revogar',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) =>
                                Text('Erro ao carregar autorizados: $error'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitações de publicação',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Aprove ou reprove solicitações para primeira publicação de serviços.',
                            style: TextStyle(color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),
                          pendingRequestsAsync.when(
                            data: (requests) {
                              if (requests.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Nenhuma solicitação pendente no momento.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                );
                              }

                              return Column(
                                children: requests
                                    .map(
                                      (request) => Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        color: const Color(0xFFF8FAFC),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                request.requesterName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              if ((request.requesterEmail ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                                Text(
                                                  request.requesterEmail!,
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Serviço: ${request.serviceName}',
                                                style: const TextStyle(
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  FilledButton.icon(
                                                    onPressed:
                                                        _reviewingRequestId ==
                                                            request.id
                                                        ? null
                                                        : () => _reviewRequest(
                                                            request.id,
                                                            approved: true,
                                                          ),
                                                    icon:
                                                        _reviewingRequestId ==
                                                            request.id
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .check_circle_outline,
                                                          ),
                                                    label: const Text(
                                                      'Aprovar',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  OutlinedButton.icon(
                                                    onPressed:
                                                        _reviewingRequestId ==
                                                            request.id
                                                        ? null
                                                        : () => _reviewRequest(
                                                            request.id,
                                                            approved: false,
                                                          ),
                                                    icon: const Icon(
                                                      Icons.cancel_outlined,
                                                    ),
                                                    label: const Text(
                                                      'Reprovar',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) =>
                                Text('Erro ao carregar solicitações: $error'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administradores ativos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 12),
                          adminsAsync.when(
                            data: (admins) {
                              if (admins.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Nenhum administrador cadastrado.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                );
                              }

                              return Column(
                                children: admins
                                    .map(
                                      (admin) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.admin_panel_settings_outlined,
                                          color: Color(0xFF7C3AED),
                                        ),
                                        title: Text(
                                          admin.fullName?.trim().isNotEmpty ==
                                                  true
                                              ? admin.fullName!
                                              : admin.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          admin.email,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        trailing: isSuperAdmin
                                            ? IconButton(
                                                onPressed:
                                                    admin.email
                                                            .trim()
                                                            .toLowerCase() ==
                                                        'darlison.pires.corporativo@gmail.com'
                                                    ? null
                                                    : () => _handleRemoveAdmin(
                                                        admin.userId,
                                                        admin.email,
                                                      ),
                                                icon: const Icon(
                                                  Icons.person_remove_outlined,
                                                ),
                                                tooltip:
                                                    'Remover administrador',
                                              )
                                            : null,
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) =>
                                Text('Erro ao carregar admins: $error'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exportar Relatórios',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gere e exporte relatórios em formato CSV para análise.',
                            style: TextStyle(color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: _isExportingServices
                                    ? null
                                    : _handleExportAppointments,
                                icon: _isExportingServices
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.download_outlined),
                                label: const Text('Exportar Agendamentos'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isExportingEventsSummary
                                    ? null
                                    : _handleExportEventsSummary,
                                icon: _isExportingEventsSummary
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF0F172A),
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.download_outlined),
                                label: const Text('Exportar Eventos (Resumo)'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Remove imagens órfãs do bucket servicos_images.',
                            style: TextStyle(color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isCleaningStorage
                                ? null
                                : _handleCleanupOrphans,
                            icon: _isCleaningStorage
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cleaning_services_outlined),
                            label: const Text('Limpar imagens órfãs'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao validar acesso admin: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe um e-mail.')));
      return;
    }

    setState(() => _isSavingAdmin = true);
    try {
      await ref.read(adminRepositoryProvider).addAdminByEmail(email);
      _emailController.clear();
      ref.invalidate(adminUsersProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador adicionado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar administrador: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAdmin = false);
      }
    }
  }

  Future<void> _handleRemoveAdmin(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover administrador'),
        content: Text('Deseja remover $email da administração?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).removeAdmin(userId);
      ref.invalidate(adminUsersProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador removido com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover administrador: $error')),
      );
    }
  }

  Future<void> _reviewRequest(
    String requestId, {
    required bool approved,
  }) async {
    setState(() => _reviewingRequestId = requestId);
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewPublishRequest(requestId: requestId, approved: approved);

      ref.invalidate(pendingPublishRequestsProvider);
      ref.invalidate(authorizedPublishersProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Solicitação aprovada com sucesso.'
                : 'Solicitação reprovada com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao revisar solicitação: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _reviewingRequestId = null);
      }
    }
  }

  Future<void> _handleRevokePublishPermission(
    String userId,
    String email,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revogar permissão'),
        content: Text('Deseja revogar a permissão de publicação para $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _revokingUserId = userId);
    try {
      await ref.read(adminRepositoryProvider).revokePublishPermission(userId);
      ref.invalidate(authorizedPublishersProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de publicação revogada com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao revogar permissão: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _revokingUserId = null);
      }
    }
  }

  Future<void> _handleCleanupOrphans() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar imagens órfãs'),
        content: const Text(
          'Essa ação remove arquivos do storage que não estão vinculados a anúncios. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isCleaningStorage = true);
    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .cleanupOrphanServiceImages();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limpeza concluída. Arquivos: ${result.totalFiles}, órfãs: ${result.orphanFiles}, removidas: ${result.deletedFiles}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao limpar órfãs: $error')));
    } finally {
      if (mounted) {
        setState(() => _isCleaningStorage = false);
      }
    }
  }

  Future<void> _handleExportAppointments() async {
    setState(() => _isExportingServices = true);
    try {
      final csvContent = await ref
          .read(adminRepositoryProvider)
          .exportAppointmentsReport();

      if (!mounted) {
        return;
      }

      final shareResult = await _shareCsvReport(csvContent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shareResult.status == ShareResultStatus.success
                ? 'Compartilhamento do relatório aberto com sucesso.'
                : 'Compartilhamento do relatório cancelado.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar relatório: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingServices = false);
      }
    }
  }

  Future<ShareResult> _shareCsvReport(String csvContent) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'relatorio_agendamentos_$timestamp.csv';
    final csvWithBom = '${String.fromCharCode(0xFEFF)}$csvContent';

    return Share.shareXFiles(
      [XFile.fromData(utf8.encode(csvWithBom), mimeType: 'text/csv')],
      text: 'Relatório de agendamentos',
      fileNameOverrides: [fileName],
    );
  }

  Future<ShareResult> _shareXlsxReport(Uint8List bytes) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'relatorio_eventos_resumo_$timestamp.xlsx';

    return Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      text: 'Relatório de eventos (Resumo)',
      fileNameOverrides: [fileName],
    );
  }

  Future<void> _handleExportEventsSummary() async {
    setState(() => _isExportingEventsSummary = true);
    try {
      final bytes = await ref
          .read(adminRepositoryProvider)
          .exportEventsSummaryXlsx();

      if (!mounted) return;

      final shareResult = await _shareXlsxReport(Uint8List.fromList(bytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shareResult.status == ShareResultStatus.success
                ? 'Compartilhamento do relatório aberto com sucesso.'
                : 'Compartilhamento do relatório cancelado.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar relatório: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExportingEventsSummary = false);
    }
  }
}

class _SectionSurface extends StatelessWidget {
  final Widget child;

  const _SectionSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? chipText;

  const _AdminHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              if (chipText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    chipText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
