import 'dart:async';
import 'package:centro_social_app/src/funcionalidades/administracao/dados/repositorio_admin.dart';
import 'package:centro_social_app/src/funcionalidades/administracao/apresentacao/provedores/provedores_admin.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_anunciar_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublishEventAccessPage extends ConsumerStatefulWidget {
  const PublishEventAccessPage({super.key});

  @override
  ConsumerState<PublishEventAccessPage> createState() =>
      _PublishEventAccessPageState();
}

class _PublishEventAccessPageState
    extends ConsumerState<PublishEventAccessPage> {
  static const _approvedGateSeenKeyPrefix =
      'event_publish_approved_gate_seen_user_';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _eventController = TextEditingController();
  bool _isSubmitting = false;
  Future<bool>? _showApprovedGateFuture;
  String? _showApprovedGateUserId;
  bool _isAutoNavigating = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _nameController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      ref.invalidate(eventPublishAccessStateProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(eventPublishAccessStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Anunciar Evento')),
      body: accessAsync.when(
        data: (state) {
          if (state.canPublish) {
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid == null) {
              return _buildAuthorizedState(
                context,
                onOpenPublication: _openPublicationForm,
              );
            }

            _ensureApprovedGateFuture(uid);

            return FutureBuilder<bool>(
              future: _showApprovedGateFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final shouldShowGate = snapshot.data ?? true;
                if (shouldShowGate) {
                  return _buildAuthorizedState(
                    context,
                    onOpenPublication: () async {
                      await _markApprovedGateSeen(uid);
                      if (!mounted) return;
                      _openPublicationForm();
                    },
                  );
                }

                if (!_isAutoNavigating) {
                  _isAutoNavigating = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnnounceEventPage(),
                      ),
                    ).then((_) {
                      _isAutoNavigating = false;
                    });
                  });
                }

                return const Center(child: CircularProgressIndicator());
              },
            );
          }

          _prefillNameIfNeeded();

          return _buildRequestState(context, state);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao verificar permissão: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorizedState(
    BuildContext context, {
    required VoidCallback onOpenPublication,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, size: 56, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'Você está autorizado a publicar eventos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenPublication,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.event_outlined, size: 22),
              label: const Text('Acessar tela de criação de evento'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPublicationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnounceEventPage()),
    );
  }

  void _ensureApprovedGateFuture(String uid) {
    if (_showApprovedGateUserId == uid && _showApprovedGateFuture != null) {
      return;
    }
    _showApprovedGateUserId = uid;
    _showApprovedGateFuture = _shouldShowApprovedGate(uid);
  }

  Future<bool> _shouldShowApprovedGate(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_approvedGateSeenKeyPrefix$uid') ?? false);
  }

  Future<void> _markApprovedGateSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_approvedGateSeenKeyPrefix$uid', true);
    _showApprovedGateFuture = Future<bool>.value(false);
  }

  Widget _buildRequestState(
    BuildContext context,
    EventPublishAccessState state,
  ) {
    final latestRequest = state.latestRequest;
    final showRevokedNotice =
        state.wasRevoked && latestRequest?.status == PublishRequestStatus.approved;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitação para publicar evento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Antes do primeiro anúncio, envie uma solicitação para análise dos administradores.',
                ),
                if (latestRequest != null) ...[
                  const SizedBox(height: 16),
                  _StatusChip(status: latestRequest.status),
                  const SizedBox(height: 8),
                  Text(
                    'Última solicitação: ${latestRequest.requesterName} • ${latestRequest.eventName}',
                  ),
                ],
                if (showRevokedNotice) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sua solicitação havia sido aprovada, mas sua permissão de publicação foi revogada por um administrador. Envie uma nova solicitação para voltar a publicar.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Seu nome'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eventController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do evento',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe o nome do evento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Enviar solicitação'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .submitEventPublishRequest(
            requesterName: _nameController.text,
            eventName: _eventController.text,
          );

      ref.invalidate(eventPublishAccessStateProvider);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar solicitação: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _prefillNameIfNeeded() {
    if (_nameController.text.trim().isNotEmpty) {
      return;
    }

    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final fallbackName = user?.nome?.trim();
    if (fallbackName != null && fallbackName.isNotEmpty) {
      _nameController.text = fallbackName;
      return;
    }

    final authName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']
            as String?;
    if ((authName ?? '').trim().isNotEmpty) {
      _nameController.text = authName!.trim();
    }
  }
}

class _StatusChip extends StatelessWidget {
  final PublishRequestStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (status) {
      case PublishRequestStatus.approved:
        color = Colors.green;
        label = 'Aprovado';
        break;
      case PublishRequestStatus.rejected:
        color = Colors.red;
        label = 'Reprovado';
        break;
      case PublishRequestStatus.pending:
        color = Colors.orange;
        label = 'Pendente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}