import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/utilitarios/formatadores_agenda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServicePatientsPage extends ConsumerStatefulWidget {
  final Service service;

  const ServicePatientsPage({super.key, required this.service});

  @override
  ConsumerState<ServicePatientsPage> createState() => _ServicePatientsPageState();
}

class _ServicePatientsPageState extends ConsumerState<ServicePatientsPage> {
  final Set<String> _locallyCancelledIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(professionalAppointmentsProvider);
    final now =
        ref.watch(appointmentsNowTickerProvider).value ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Próximos Pacientes')),
      body: appointmentsAsync.when(
        data: (appointments) {
          final upcoming =
              appointments
                  .where(
                    (a) =>
                        a.serviceId == widget.service.id &&
                        a.status == AppointmentStatus.scheduled &&
                        a.startsAt.isAfter(now) &&
                        !_locallyCancelledIds.contains(a.id),
                  )
                  .toList()
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

          if (upcoming.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não há próximos pacientes para este serviço.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final appointment = upcoming[index];
              final avatarUrl = appointment.communityUserPhotoUrl?.trim();
              final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              backgroundImage: hasAvatar
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: hasAvatar
                                  ? null
                                  : Text(
                                      _initialsFromName(
                                        appointment.communityUserName,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.communityUserName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Paciente agendado',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Data e horário: ${formatDateTime(appointment.startsAt)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(schedulingRepositoryProvider)
                                      .updateAppointmentStatus(
                                        appointmentId: appointment.id,
                                        status: AppointmentStatus.completed,
                                      );

                                  // Hide locally only after server confirms
                                  setState(() {
                                    _locallyCancelledIds.add(appointment.id);
                                  });

                                  ref.invalidate(communityAppointmentsProvider);
                                  ref.invalidate(
                                    professionalAppointmentsProvider,
                                  );
                                  ref.invalidate(
                                    professionalTodayAppointmentsProvider,
                                  );
                                  ref.invalidate(allAppointmentsProvider);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Presença confirmada com sucesso.',
                                      ),
                                    ),
                                  );
                                } catch (error, stack) {
                                  // debug
                                  // ignore: avoid_print
                                  print('Erro ao confirmar presença: $error');
                                  // ignore: avoid_print
                                  print(stack);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao confirmar presença: ${error.toString()}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Confirmar presença'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancelar agendamento'),
                                    content: const Text(
                                      'Deseja cancelar este agendamento por imprevisto?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Não'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Sim, cancelar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) {
                                  return;
                                }

                                try {
                                  await ref
                                      .read(schedulingRepositoryProvider)
                                      .cancelAppointment(appointment.id);

                                  // Hide locally only after server confirms
                                  setState(() {
                                    _locallyCancelledIds.add(appointment.id);
                                  });

                                  ref.invalidate(communityAppointmentsProvider);
                                  ref.invalidate(
                                    professionalAppointmentsProvider,
                                  );
                                  ref.invalidate(
                                    professionalTodayAppointmentsProvider,
                                  );
                                  ref.invalidate(allAppointmentsProvider);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Agendamento cancelado com sucesso.',
                                      ),
                                    ),
                                  );
                                } catch (error, stack) {
                                  // debug
                                  // ignore: avoid_print
                                  print('Erro ao cancelar agendamento: $error');
                                  // ignore: avoid_print
                                  print(stack);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao cancelar agendamento: ${error.toString()}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancelar agendamento'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao carregar próximos pacientes: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
