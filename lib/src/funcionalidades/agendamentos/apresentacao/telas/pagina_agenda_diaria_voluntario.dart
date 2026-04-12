import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/utilitarios/formatadores_agenda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VolunteerDayAgendaPage extends ConsumerWidget {
  const VolunteerDayAgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(professionalTodayAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda do Dia')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(professionalTodayAppointmentsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: appointmentsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum atendimento para hoje.')),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.today_outlined),
                    title: const Text('Resumo de hoje'),
                    subtitle: Text('${items.length} atendimento(s) programado(s).'),
                  ),
                ),
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text('${item.communityUserName} • ${item.specialty}'),
                      subtitle: Text(
                        '${formatDateTime(item.startsAt)} - ${formatDateTime(item.endsAt)}',
                      ),
                      trailing: _StatusMenu(appointment: item),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erro ao carregar agenda: $error'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMenu extends ConsumerWidget {
  final Appointment appointment;

  const _StatusMenu({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<AppointmentStatus>(
      initialValue: appointment.status,
      tooltip: appointment.status.label,
      onSelected: (status) async {
        await ref.read(schedulingRepositoryProvider).updateAppointmentStatus(
          appointmentId: appointment.id,
          status: status,
        );
        ref.invalidate(professionalTodayAppointmentsProvider);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: AppointmentStatus.scheduled,
          child: Text('Agendado'),
        ),
        PopupMenuItem(
          value: AppointmentStatus.completed,
          child: Text('Concluído'),
        ),
        PopupMenuItem(
          value: AppointmentStatus.cancelled,
          child: Text('Cancelado'),
        ),
        PopupMenuItem(value: AppointmentStatus.noShow, child: Text('Faltou')),
      ],
      child: Chip(label: Text(statusLabel(appointment.status))),
    );
  }
}
