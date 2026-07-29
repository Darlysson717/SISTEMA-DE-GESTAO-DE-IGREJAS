import 'package:centro_social_app/src/funcionalidades/notificacoes/apresentacao/provedores/provedores_notificacoes.dart';
import 'package:centro_social_app/src/funcionalidades/notificacoes/dominio/entidades/notificacao_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BotaoNotificacoes extends ConsumerWidget {
  const BotaoNotificacoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoLidasAsync = ref.watch(notificacoesNaoLidasProvider);

    return naoLidasAsync.when(
      data: (quantidade) => _IconeNotificacao(
        quantidade: quantidade,
        onTap: () => _abrirModal(context),
      ),
      loading: () => const _IconeNotificacao(quantidade: 0),
      error: (_, __) => const _IconeNotificacao(quantidade: 0),
    );
  }

  void _abrirModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModalNotificacoes(),
    );
  }
}

class _IconeNotificacao extends StatelessWidget {
  final int quantidade;
  final VoidCallback? onTap;

  const _IconeNotificacao({
    required this.quantidade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: onTap,
          tooltip: 'Notificações',
        ),
        if (quantidade > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                quantidade > 99 ? '99+' : quantidade.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ModalNotificacoes extends ConsumerStatefulWidget {
  const ModalNotificacoes();

  @override
  ConsumerState<ModalNotificacoes> createState() => ModalNotificacoesState();
}

class ModalNotificacoesState extends ConsumerState<ModalNotificacoes> {
  @override
  void initState() {
    super.initState();
    // Marca todas as notificações como lidas ao abrir o modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(notificacoesControllerProvider).marcarTodasComoLidas();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificacoesAsync = ref.watch(ultimasNotificacoesProvider);
    final naoLidasAsync = ref.watch(notificacoesNaoLidasProvider);
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.75;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrasto
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header do modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.grey[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Notificações',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Spacer(),
                // Botão limpar todas
                naoLidasAsync.when(
                  data: (qtd) => qtd > 0
                      ? TextButton.icon(
                          onPressed: _limparTodas,
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Limpar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[400],
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de notificações (máximo 5)
          Flexible(
            child: notificacoesAsync.when(
              data: (notificacoes) {
                if (notificacoes.isEmpty) {
                  return _buildEmptyState();
                }
                // Mostra no máximo as 5 últimas notificações
                final ultimas5 = notificacoes.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 8 + bottomPadding,
                  ),
                  itemCount: ultimas5.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    return _buildNotificacaoItem(ultimas5[index]);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Erro ao carregar: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação',
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem notificações no momento.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacaoItem(NotificacaoApp notificacao) {
    return InkWell(
      onTap: () => _marcarComoLida(notificacao),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de não lida
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notificacao.lida
                    ? Colors.transparent
                    : const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),

            // Ícone baseado no tipo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCorTipo(notificacao.tipo).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconeTipo(notificacao.tipo),
                color: _getCorTipo(notificacao.tipo),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacao.titulo,
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: notificacao.lida
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notificacao.corpo,
                    style: TextStyle(
                      fontSize: 13,
                      color: notificacao.lida
                          ? Colors.grey[500]
                          : Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarData(notificacao.criadaEm),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconeTipo(String? tipo) {
    switch (tipo) {
      case 'agendamento':
        return Icons.calendar_today;
      case 'evento':
        return Icons.event;
      case 'sistema':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getCorTipo(String? tipo) {
    switch (tipo) {
      case 'agendamento':
        return const Color(0xFF059669);
      case 'evento':
        return const Color(0xFF6366F1);
      case 'sistema':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diferenca.inHours < 1) {
      return 'Há ${diferenca.inMinutes} min';
    } else if (diferenca.inDays < 1) {
      return 'Há ${diferenca.inHours}h';
    } else if (diferenca.inDays < 7) {
      return 'Há ${diferenca.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(data);
    }
  }

  Future<void> _marcarComoLida(NotificacaoApp notificacao) async {
    if (!notificacao.lida) {
      await ref
          .read(notificacoesControllerProvider)
          .marcarComoLida(notificacao.id);
    }
  }

  Future<void> _limparTodas() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar notificações?'),
        content:
            const Text('Todas as notificações serão removidas permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      await ref.read(notificacoesControllerProvider).limparTodas();
    }
  }
}