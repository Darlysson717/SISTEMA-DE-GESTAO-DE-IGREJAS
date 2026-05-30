import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agendamentos_usuario.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/imagem_evento_adaptativa.dart';

class ServiceDetailsPage extends ConsumerStatefulWidget {
  final Service service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  ConsumerState<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends ConsumerState<ServiceDetailsPage> {
  DateTime? _selectedDate;
  _TimeSlot? _selectedSlot;
  bool _isBooking = false;
  List<Appointment> _appointmentsCache = const [];
  List<_TimeSlot> _timeSlotsCache = const [];
  DateTime _focusedDay = DateTime.now();
  ProviderSubscription<AsyncValue<List<Appointment>>>? _appointmentsSub;
  @override
  void initState() {
    super.initState();
    _appointmentsSub = ref.listenManual<AsyncValue<List<Appointment>>>(
      allAppointmentsProvider,
      (_, next) {
        next.whenData((data) {
          _appointmentsCache = data;
        });
      },
    );
  }

  @override
  void dispose() {
    _appointmentsSub?.close();
    super.dispose();
  }

  int? _weekdayFromLabel(String label) {
    final normalized = label.toLowerCase().trim();
    final numeric = int.tryParse(normalized);
    if (numeric != null && numeric >= 1 && numeric <= 7) {
      return numeric;
    }
    if (normalized.startsWith('seg')) return DateTime.monday;
    if (normalized.startsWith('ter')) return DateTime.tuesday;
    if (normalized.startsWith('qua')) return DateTime.wednesday;
    if (normalized.startsWith('qui')) return DateTime.thursday;
    if (normalized.startsWith('sex')) return DateTime.friday;
    if (normalized.startsWith('sab') || normalized.startsWith('sáb')) {
      return DateTime.saturday;
    }
    if (normalized.startsWith('dom')) return DateTime.sunday;
    if (normalized.contains('segunda')) return DateTime.monday;
    if (normalized.contains('terça') || normalized.contains('terca')) {
      return DateTime.tuesday;
    }
    if (normalized.contains('quarta')) return DateTime.wednesday;
    if (normalized.contains('quinta')) return DateTime.thursday;
    if (normalized.contains('sexta')) return DateTime.friday;
    if (normalized.contains('sábado') || normalized.contains('sabado')) {
      return DateTime.saturday;
    }
    if (normalized.contains('domingo')) return DateTime.sunday;
    return null;
  }

  TimeOfDay? _parseTime(String raw) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$',
    ).firstMatch(raw.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final ampm = match.group(3)?.toLowerCase();
    if (ampm != null) {
      final isPm = ampm == 'pm';
      if (hour == 12) {
        hour = isPm ? 12 : 0;
      } else if (isPm) {
        hour += 12;
      }
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  List<_TimeSlot> _expandSlotsFromRange(
    TimeOfDay start,
    TimeOfDay end,
    int durationMinutes,
  ) {
    final slots = <_TimeSlot>[];
    var startTotal = start.hour * 60 + start.minute;
    var endTotal = end.hour * 60 + end.minute;

    if (endTotal <= startTotal) {
      endTotal += 24 * 60;
    }

    while (startTotal + durationMinutes <= endTotal) {
      final slotStart = TimeOfDay(
        hour: (startTotal ~/ 60) % 24,
        minute: startTotal % 60,
      );
      final slotEndTotal = startTotal + durationMinutes;
      final slotEnd = TimeOfDay(
        hour: (slotEndTotal ~/ 60) % 24,
        minute: slotEndTotal % 60,
      );
      final label = '${slotStart.format(context)}-${slotEnd.format(context)}';
      slots.add(_TimeSlot(start: slotStart, end: slotEnd, label: label));
      startTotal += durationMinutes;
    }

    return slots;
  }

  List<_TimeSlot> _buildTimeSlots(List<String> horarios, int? durationMinutes) {
    final slots = <_TimeSlot>[];
    final duration = durationMinutes ?? 60;

    for (final raw in horarios) {
      final trimmed = raw.trim();
      final parts = trimmed.split('-');
      if (parts.length == 2) {
        final start = _parseTime(parts[0]);
        final end = _parseTime(parts[1]);
        if (start != null && end != null) {
          slots.addAll(_expandSlotsFromRange(start, end, duration));
          continue;
        }
      }

      final start = _parseTime(trimmed);
      if (start == null) {
        slots.add(
          _TimeSlot(
            start: const TimeOfDay(hour: 0, minute: 0),
            end: const TimeOfDay(hour: 0, minute: 0),
            label: trimmed,
            isValid: false,
          ),
        );
        continue;
      }

      final startTotal = start.hour * 60 + start.minute;
      final endTotal = (startTotal + duration) % (24 * 60);
      final end = TimeOfDay(hour: endTotal ~/ 60, minute: endTotal % 60);
      slots.add(_TimeSlot(start: start, end: end, label: trimmed));
    }

    return slots;
  }

  String _formatHorarioLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 2) {
        return '${parts[0].trim()} às ${parts[1].trim()}';
      }
    }
    return trimmed;
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _sameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm', 'pt_BR').format(time);
  }

  String _toHourMinute(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _onTimeSlotSelected(_TimeSlot slot) async {
    setState(() => _selectedSlot = slot);
    Navigator.of(context).pop();

    // Mostrar confirmação após selecionar horário
    final startsAt = _combineDateAndTime(_selectedDate!, _selectedSlot!.start);
    var endsAt = _combineDateAndTime(_selectedDate!, _selectedSlot!.end);
    if (endsAt.isBefore(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }

    final confirmed = await _showConfirmationDialog(
      context,
      widget.service,
      startsAt,
      endsAt,
    );

    if (!confirmed) {
      // Reset selection
      setState(() {
        _selectedDate = null;
        _selectedSlot = null;
      });
      return;
    }

    // Fazer o agendamento
    setState(() => _isBooking = true);
    try {
      final repository = ref.read(schedulingRepositoryProvider);
      await repository.createAppointment(
        startsAt: startsAt,
        serviceId: widget.service.id,
      );
      ref.invalidate(communityAppointmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento realizado com sucesso.')),
      );
      // Reset selection after successful booking
      setState(() {
        _selectedDate = null;
        _selectedSlot = null;
      });
    } catch (error) {
      if (!mounted) return;

      // Verificar conflitos de agendamento
      final errorMessage = error.toString();
      String? friendlyMessage;
      String? helperMessage;
      if (errorMessage.contains('mesmo horário')) {
        friendlyMessage = 'Você já possui um agendamento neste mesmo horário.';
        helperMessage = 'Escolha outro horário para evitar conflito.';
      } else if (errorMessage.contains('este serviço neste dia')) {
        friendlyMessage =
            'Você já possui um agendamento para este serviço neste dia.';
        helperMessage = 'Para agendar novamente, escolha outro dia.';
      } else if (errorMessage.contains('já está indisponível')) {
        friendlyMessage =
            'Este horário acabou de ser ocupado por outra pessoa.';
        helperMessage = 'Atualize e escolha outro horário disponível.';
      } else if (errorMessage.contains(
            'appointments_one_per_service_per_day',
          ) ||
          errorMessage.contains(
            'duplicate key value violates unique constraint',
          )) {
        friendlyMessage = 'Este horário já foi ocupado por outra pessoa.';
        helperMessage = 'Selecione outro horário disponível.';
      }

      if (friendlyMessage != null) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            title: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange[600], size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Agendamento não permitido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendlyMessage ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            helperMessage ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'Entendi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserAppointmentsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Ver agendamentos',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao agendar: ${errorMessage.replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    Service service,
    DateTime startsAt,
    DateTime endsAt,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirmar Agendamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serviço: ${service.nome}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Profissional: ${service.nomeProfissional}'),
                  const SizedBox(height: 8),
                  Text('Especialidade: ${service.categoria}'),
                  const SizedBox(height: 8),
                  Text('Data: ${_formatDate(startsAt)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Horário: ${_formatTime(startsAt)} - ${_formatTime(endsAt)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deseja confirmar este agendamento?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _pickAvailableDate(
    List<int> availableWeekdays,
    List<_TimeSlot> timeSlots,
  ) async {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final lastDay = DateTime(today.year + 1, 12, 31);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha um dia'),
          content: SizedBox(
            width: 360,
            child: TableCalendar(
              locale: 'pt_BR',
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              daysOfWeekHeight: 32,
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (day, locale) {
                  switch (day.weekday) {
                    case DateTime.monday:
                      return 'Seg';
                    case DateTime.tuesday:
                      return 'Ter';
                    case DateTime.wednesday:
                      return 'Qua';
                    case DateTime.thursday:
                      return 'Qui';
                    case DateTime.friday:
                      return 'Sex';
                    case DateTime.saturday:
                      return 'Sab';
                    case DateTime.sunday:
                      return 'Dom';
                  }
                  return '';
                },
              ),
              enabledDayPredicate: (day) {
                return availableWeekdays.contains(day.weekday);
              },
              selectedDayPredicate: (day) {
                return _selectedDate != null && isSameDay(_selectedDate, day);
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white),
                disabledTextStyle: const TextStyle(color: Color(0xFF94A3B8)),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF0D9488),
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                weekendDecoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!availableWeekdays.contains(selectedDay.weekday)) {
                  return;
                }
                setState(() {
                  _selectedDate = selectedDay;
                  _selectedSlot = null;
                  _focusedDay = focusedDay;
                });
                Navigator.of(context).pop();
                _showAvailableTimes(selectedDay, timeSlots);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAvailableTimes(
    DateTime date,
    List<_TimeSlot> timeSlots,
  ) async {
    final repository = ref.read(schedulingRepositoryProvider);
    Set<String> bookedTimesFromBackend = <String>{};
    try {
      bookedTimesFromBackend = await repository.listBookedTimesForServiceOnDate(
        serviceId: widget.service.id,
        date: date,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
        final maxHeight = MediaQuery.of(context).size.height * 0.78;
        final now = DateTime.now();
        final bookedAppointments = _appointmentsCache.where((appointment) {
          return appointment.serviceId == widget.service.id &&
              appointment.status == AppointmentStatus.scheduled;
        }).toList();

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horarios disponiveis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (timeSlots.isEmpty)
                    const Text('Nenhum horario disponivel para este dia.')
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: isSmallScreen ? 10 : 12,
                          runSpacing: isSmallScreen ? 10 : 12,
                          children: timeSlots.map((slot) {
                            var isPast = false;
                            var isBooked = false;
                            if (slot.isValid) {
                              final slotStartLocal = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                slot.start.hour,
                                slot.start.minute,
                              );
                              final slotStartUtc = slotStartLocal.toUtc();
                              isPast = slotStartLocal.isBefore(now);
                              final slotTimeKey = _toHourMinute(slotStartLocal);
                              isBooked =
                                  bookedAppointments.any(
                                    (appointment) =>
                                        _sameMinute(
                                          appointment.startsAt,
                                          slotStartLocal,
                                        ) ||
                                        _sameMinute(
                                          appointment.startsAt,
                                          slotStartUtc,
                                        ),
                                  ) ||
                                  bookedTimesFromBackend.contains(slotTimeKey);
                            }
                            final isDisabled =
                                !slot.isValid || isPast || isBooked;
                            final availableColor = const Color(0xFF059669);
                            final unavailableColor = const Color(0xFFDC2626);
                            return ChoiceChip(
                              label: Text(_formatHorarioLabel(slot.label)),
                              selected: _selectedSlot?.label == slot.label,
                              onSelected: isDisabled
                                  ? null
                                  : (bool selected) {
                                      if (selected) {
                                        _onTimeSlotSelected(slot);
                                      }
                                    },
                              selectedColor: availableColor,
                              backgroundColor: isDisabled
                                  ? unavailableColor.withValues(alpha: 0.12)
                                  : availableColor.withValues(alpha: 0.12),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 20,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              labelPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                              ),
                              labelStyle: TextStyle(
                                color: isDisabled
                                    ? unavailableColor
                                    : availableColor,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 16 : 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final service = widget.service;
    final weekdays = service.diasDisponiveis
        .map(_weekdayFromLabel)
        .whereType<int>()
        .toSet()
        .toList();
    final effectiveWeekdays = weekdays;
    final timeSlots = _buildTimeSlots(
      service.horarios,
      service.duracaoAtendimento,
    );
    _timeSlotsCache = timeSlots;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Detalhes do Serviço'),
            ),

            SliverToBoxAdapter(
              child: Stack(
                children: [
                  AdaptiveEventImage(
                    imageUrl: service.imagemProfissional,
                    defaultAspectRatio: isSmallScreen ? 4 / 3 : 16 / 9,
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: isSmallScreen ? 14 : 18,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 20 : 24,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          service.nomeProfissional,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo principal
            SliverPadding(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Título e categoria
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.nome,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            service.categoria,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Descrição
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: const Color(0xFF6366F1),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Text(
                              'Sobre o Serviço',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        Text(
                          service.descricao,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            color: const Color(0xFF64748B),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Detalhes do atendimento
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: const Color(0xFFF59E0B),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Text(
                              'Detalhes do Atendimento',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildDetailItem(
                          icon: Icons.access_time,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Duração',
                          value: '${service.duracaoAtendimento ?? 60} minutos',
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        _buildDetailItem(
                          icon: service.tipoAtendimento == 'presencial'
                              ? Icons.location_on
                              : Icons.videocam,
                          iconColor: service.tipoAtendimento == 'presencial'
                              ? const Color(0xFF059669)
                              : const Color(0xFF6366F1),
                          title: 'Tipo de Atendimento',
                          value: service.tipoAtendimento == 'presencial'
                              ? 'Presencial'
                              : 'Online',
                          isSmallScreen: isSmallScreen,
                        ),
                        if (service.local != null &&
                            service.tipoAtendimento == 'presencial') ...[
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _buildDetailItem(
                            icon: Icons.place,
                            iconColor: const Color(0xFFEF4444),
                            title: 'Local',
                            value: service.local!,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        _buildDetailItem(
                          icon: Icons.phone,
                          iconColor: const Color(0xFF059669),
                          title: 'Telefone',
                          value: service.telefone,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Dias disponíveis
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_view_week,
                                color: const Color(0xFF8B5CF6),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Text(
                              'Dias Disponíveis',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        Wrap(
                          spacing: isSmallScreen ? 8 : 12,
                          runSpacing: isSmallScreen ? 8 : 12,
                          children: service.diasDisponiveis.map((dia) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                dia,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: const Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Horarios cadastrados
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF059669,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.schedule,
                                color: const Color(0xFF059669),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Text(
                              'Horarios cadastrados',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        if (service.horarios.isEmpty)
                          Text(
                            'Nenhum horario cadastrado.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF64748B),
                            ),
                          )
                        else
                          Wrap(
                            spacing: isSmallScreen ? 8 : 12,
                            runSpacing: isSmallScreen ? 8 : 12,
                            children: service.horarios.map((horario) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF059669,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF059669,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  _formatHorarioLabel(horario),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Observações (se houver)
                  if (service.observacoes != null &&
                      service.observacoes!.isNotEmpty) ...[
                    SizedBox(height: isSmallScreen ? 20 : 24),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF64748B,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.notes,
                                  color: const Color(0xFF64748B),
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Text(
                                'Observações',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Text(
                            service.observacoes!,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: const Color(0xFF64748B),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  Container(
                    width: double.infinity,
                    height: isSmallScreen ? 56 : 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isBooking
                          ? null
                          : () async {
                              if (effectiveWeekdays.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nao ha dias disponiveis cadastrados.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await _pickAvailableDate(
                                effectiveWeekdays,
                                _timeSlotsCache,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isBooking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Agendar Serviço',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(
                    height:
                        (isSmallScreen ? 32 : 48) +
                        MediaQuery.of(context).padding.bottom,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: isSmallScreen ? 20 : 24),
        ),
        SizedBox(width: isSmallScreen ? 16 : 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  final String label;
  final bool isValid;

  const _TimeSlot({
    required this.start,
    required this.end,
    required this.label,
    this.isValid = true,
  });
}
