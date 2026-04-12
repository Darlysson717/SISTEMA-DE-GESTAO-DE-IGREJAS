import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  final _emailController = TextEditingController();
  bool _isSavingAdmin = false;
  bool _isCleaningStorage = false;
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
    final pendingRequestsAsync = ref.watch(pendingPublishRequestsProvider);
    final authorizedPublishersAsync = ref.watch(authorizedPublishersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ADMINISTRADOR')),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Acesso restrito a administradores.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(isCurrentUserAdminProvider);
              ref.invalidate(adminUsersProvider);
              ref.invalidate(pendingPublishRequestsProvider);
              ref.invalidate(authorizedPublishersProvider);
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestão de Administradores',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSuperAdmin
                              ? 'Você é SUPER ADMIN e pode adicionar/remover administradores.'
                              : 'Você é administrador.',
                        ),
                        if (isSuperAdmin) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail para promover a administrador',
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
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1),
                            label: const Text('Adicionar administrador'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autorizados a publicar serviços',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lista de pessoas com permissão ativa para publicar serviços.',
                        ),
                        const SizedBox(height: 12),
                        authorizedPublishersAsync.when(
                          data: (publishers) {
                            if (publishers.isEmpty) {
                              return const Text(
                                'Nenhuma pessoa autorizada no momento.',
                              );
                            }

                            return Column(
                              children: publishers
                                  .map(
                                    (publisher) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.verified_user_outlined,
                                      ),
                                      title: Text(
                                        publisher.fullName?.trim().isNotEmpty ==
                                                true
                                            ? publisher.fullName!
                                            : publisher.email,
                                      ),
                                      subtitle: Text(publisher.email),
                                      trailing: OutlinedButton.icon(
                                        onPressed:
                                            _revokingUserId == publisher.userId ||
                                                publisher.isSuperAdmin
                                            ? null
                                            : () =>
                                                  _handleRevokePublishPermission(
                                                    publisher.userId,
                                                    publisher.email,
                                                  ),
                                        icon:
                                            _revokingUserId == publisher.userId
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitações de publicação',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aprove ou reprove solicitações para primeira publicação de serviços.',
                        ),
                        const SizedBox(height: 12),
                        pendingRequestsAsync.when(
                          data: (requests) {
                            if (requests.isEmpty) {
                              return const Text(
                                'Nenhuma solicitação pendente no momento.',
                              );
                            }

                            return Column(
                              children: requests
                                  .map(
                                    (request) => Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              request.requesterName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if ((request.requesterEmail ?? '')
                                                .trim()
                                                .isNotEmpty)
                                              Text(request.requesterEmail!),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Serviço: ${request.serviceName}',
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
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                        ),
                                                  label: const Text('Aprovar'),
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
                                                  label: const Text('Reprovar'),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administradores ativos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        adminsAsync.when(
                          data: (admins) {
                            if (admins.isEmpty) {
                              return const Text(
                                'Nenhum administrador cadastrado.',
                              );
                            }

                            return Column(
                              children: admins
                                  .map(
                                    (admin) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.admin_panel_settings_outlined,
                                      ),
                                      title: Text(
                                        admin.fullName?.trim().isNotEmpty ==
                                                true
                                            ? admin.fullName!
                                            : admin.email,
                                      ),
                                      subtitle: Text(admin.email),
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
                                              tooltip: 'Remover administrador',
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Remove imagens órfãs do bucket servicos_images.',
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
}
