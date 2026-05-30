import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/repositorios/repositorio_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/utilitarios/formatadores_agenda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class UserAppointmentsPage extends ConsumerStatefulWidget {
  const UserAppointmentsPage({super.key});

  @override
  ConsumerState<UserAppointmentsPage> createState() =>
      _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends ConsumerState<UserAppointmentsPage> {
  final Set<String> _locallyCancelledIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(communityAppointmentsProvider);
    final cancellationMessagesAsync = ref.watch(cancellationMessagesProvider);
    final now =
        ref.watch(appointmentsNowTickerProvider).value ?? DateTime.now();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      body: appointmentsAsync.when(
        data: (appointments) {
          final cancellationMessages =
              cancellationMessagesAsync.valueOrNull ??
              const <CancellationNotice>[];

          if (appointments.isEmpty) {
            if (cancellationMessages.isNotEmpty) {
              return _buildCancellationNoticesList(
                context,
                cancellationMessages,
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você ainda não possui agendamentos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agende um serviço para começar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final scheduledAppointments =
              appointments
                  .where(
                    (a) =>
                        a.status == AppointmentStatus.scheduled &&
                        a.startsAt.isAfter(now) &&
                        !_locallyCancelledIds.contains(a.id),
                  )
                  .toList()
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

          final pastAppointments =
              appointments
                  .where(
                    (a) =>
                        a.status != AppointmentStatus.scheduled ||
                        !a.startsAt.isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Agendados'),
                    Tab(text: 'Histórico'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAppointmentsList(
                        scheduledAppointments,
                        isScheduled: true,
                        now: now,
                        bottomPadding: bottomPadding,
                      ),
                      _buildAppointmentsList(
                        pastAppointments,
                        isScheduled: false,
                        now: now,
                        notices: cancellationMessages,
                        bottomPadding: bottomPadding,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar agendamentos',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> appointments, {
    required bool isScheduled,
    required DateTime now,
    required double bottomPadding,
    List<CancellationNotice> notices = const [],
  }) {
    if (appointments.isEmpty && notices.isEmpty) {
      if (isScheduled) {
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
          children: [
            _buildScheduledReminderCard(),
            const SizedBox(height: 16),
            _buildEmptyScheduledState(),
          ],
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isScheduled ? Icons.calendar_today_outlined : Icons.history,
                size: 64,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isScheduled
                  ? 'Nenhum agendamento futuro'
                  : 'Nenhum agendamento passado',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isScheduled
                  ? 'Explore nossos serviços e agende seu primeiro atendimento'
                  : 'Seus agendamentos anteriores aparecerão aqui',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isScheduled && appointments.isEmpty && notices.isNotEmpty) {
      return _buildCancellationNoticesList(context, notices);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
      itemCount: appointments.length + (isScheduled ? 1 : notices.length),
      itemBuilder: (context, index) {
        if (isScheduled && index == 0) {
          return _buildScheduledReminderCard();
        }

        if (!isScheduled && index < notices.length) {
          final notice = notices[index];
          return _buildCancellationNoticeCard(notice);
        }

        final appointmentIndex = isScheduled
            ? index - 1
            : index - notices.length;
        final appointment = appointments[appointmentIndex];
        final canCancel =
            isScheduled &&
            appointment.status == AppointmentStatus.scheduled &&
            appointment.startsAt.isAfter(now);
        final statusColor = _getStatusColor(appointment.status);
        final scheduledDate = formatDate(appointment.startsAt);
        final scheduledTime =
            '${appointment.startsAt.hour.toString().padLeft(2, '0')}:${appointment.startsAt.minute.toString().padLeft(2, '0')}';
        final serviceTypeLabel = appointment.serviceType == 'online'
            ? 'Online'
            : 'Presencial';
        final hasPhone = (appointment.phone ?? '').trim().isNotEmpty;
        final locationLabel = appointment.serviceType == 'online'
            ? 'Atendimento online'
            : (appointment.location?.isNotEmpty == true
                  ? appointment.location!
                  : 'Local não informado');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        child: Icon(
                          _getStatusIcon(appointment.status),
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${appointment.professionalName} • ${appointment.specialty}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(statusLabel(appointment.status)),
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Data: $scheduledDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Horário: $scheduledTime',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.laptop_mac_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tipo: $serviceTypeLabel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Local: $locationLabel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment.phone != null &&
                      appointment.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          appointment.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue[100]!.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Observações',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (canCancel || hasPhone) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (hasPhone)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _openWhatsApp(context, appointment.phone!),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                        if (hasPhone && canCancel) const SizedBox(width: 8),
                        if (canCancel)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancelar agendamento'),
                                    content: const Text(
                                      'Deseja realmente cancelar este agendamento?',
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

                                setState(() {
                                  _locallyCancelledIds.add(appointment.id);
                                });

                                try {
                                  await ref
                                      .read(schedulingRepositoryProvider)
                                      .cancelAppointment(appointment.id);

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
                                } catch (error) {
                                  if (!mounted) return;
                                  setState(() {
                                    _locallyCancelledIds.remove(appointment.id);
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao cancelar agendamento: $error',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancelar agendamento'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduledReminderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFF59E0B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Confira antes de sair de casa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Antes de se deslocar, confirme se o agendamento continua ativo. Se o profissional cancelar, você evita a viagem perdida.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum agendamento futuro',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore nossos serviços e agende seu primeiro atendimento',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _normalizePhoneForWhatsApp(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }

    if (digits.startsWith('55')) {
      return digits;
    }

    if (digits.length == 10 || digits.length == 11) {
      return '55$digits';
    }

    return digits;
  }

  Future<void> _openWhatsApp(BuildContext context, String rawPhone) async {
    final phone = _normalizePhoneForWhatsApp(rawPhone);
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de telefone inválido.')),
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/$phone');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Widget _buildCancellationNoticesList(
    BuildContext context,
    List<CancellationNotice> notices,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: notices.length,
      itemBuilder: (context, index) =>
          _buildCancellationNoticeCard(notices[index]),
    );
  }

  Widget _buildCancellationNoticeCard(CancellationNotice notice) {
    final scheduledAt = notice.scheduledAt;
    final dateLabel = scheduledAt == null
        ? null
        : '${formatDate(scheduledAt)} • ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Agendamento cancelado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notice.message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (notice.professionalName != null &&
                notice.professionalName!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Profissional: ${notice.professionalName!}'),
            ],
            if (notice.specialty != null &&
                notice.specialty!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Serviço: ${notice.specialty!}'),
            ],
            if (dateLabel != null) ...[
              const SizedBox(height: 4),
              Text('Data e horário: $dateLabel'),
            ],
            if (notice.location != null &&
                notice.location!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Local: ${notice.location!}'),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.orange;
      case AppointmentStatus.noShow:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.error;
    }
  }
}
