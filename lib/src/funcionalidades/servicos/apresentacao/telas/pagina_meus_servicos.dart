import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_oferecer_servico.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/telas/pagina_pacientes_servico.dart';

class MyServicesPage extends ConsumerWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(myServicesProvider);
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Serviços')),
      body: servicesAsync.when(
        data: (services) =>
            _buildContent(context, ref, services, isSmallScreen, bottomPadding),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            child: Text(
              'Erro ao carregar servicos: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Service> services,
    bool isSmallScreen,
    double bottomPadding,
  ) {
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 20 : 24,
            isSmallScreen ? 20 : 24,
            isSmallScreen ? 20 : 24,
            bottomPadding + (isSmallScreen ? 20 : 24),
          ),
          child: const Text(
            'Voce ainda nao possui servicos cadastrados.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 20 : 24,
        isSmallScreen ? 20 : 24,
        isSmallScreen ? 20 : 24,
        bottomPadding + (isSmallScreen ? 20 : 24),
      ),
      itemCount: services.length,
      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 12 : 16),
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceCard(
          service: service,
          isSmallScreen: isSmallScreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServicePatientsPage(service: service),
              ),
            );
          },
          onEdit: () async {
            final updatedService = await Navigator.push<Service?>(
              context,
              MaterialPageRoute(
                builder: (_) => OfferServicePage(initialService: service),
              ),
            );
            if (updatedService != null) {
              ref.invalidate(myServicesProvider);
              ref.invalidate(publishedServicesProvider);
            }
          },
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Excluir servico'),
                content: const Text('Deseja excluir este servico?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;

            final repository = ref.read(schedulingRepositoryProvider);
            try {
              await repository.deleteService(service.id);

              ref.invalidate(myServicesProvider);
              ref.invalidate(publishedServicesProvider);
              ref.invalidate(communityAppointmentsProvider);
              ref.invalidate(professionalTodayAppointmentsProvider);
              ref.invalidate(professionalAppointmentsProvider);
              ref.invalidate(allAppointmentsProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servico excluido com sucesso.'),
                  ),
                );
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir servico: $error')),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isSmallScreen;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.isSmallScreen,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.nome,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              service.categoria,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF64748B),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFEF4444),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF94A3B8),
                  size: isSmallScreen ? 20 : 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
