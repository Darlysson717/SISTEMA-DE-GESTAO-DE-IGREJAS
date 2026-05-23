import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/imagem_evento_adaptativa.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/dialogo_whatsapp_voluntario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final AppEvent event;

  const EventDetailsPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  bool _isRegisteringInterest = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final repository = ref.watch(eventsRepositoryProvider);
    final registrationsAsync = ref.watch(eventRegistrationsProvider(event.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do evento')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveEventImage(
              imageUrl: event.imagemCapaUrlVersionada,
              defaultAspectRatio: 16 / 9,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.nome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(Icons.category_outlined, event.categoria),
                      _chip(Icons.schedule_outlined, event.dataTexto),
                      _chip(
                        Icons.place_outlined,
                        _locationLabel(event.tipoLocal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.resumoCurto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('Responsável: ${event.contatoNome}'),
                  Text('Telefone: ${event.contatoTelefone}'),
                  if ((event.contatoEmail ?? '').trim().isNotEmpty)
                    Text('E-mail: ${event.contatoEmail}'),
                  if ((event.endereco ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Endereço: ${event.endereco}'),
                  ],
                  if ((event.linkTransmissao ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Transmissão: ${event.linkTransmissao}'),
                  ],
                  const SizedBox(height: 24),
                  _buildRegistrationSection(
                    registrationsAsync: registrationsAsync,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRegisteringInterest
                          ? null
                          : () => _registerInterest(
                              repository,
                              EventInterestType.participante,
                            ),
                      icon: const Icon(Icons.event_available_outlined),
                      label: const Text('Participar'),
                    ),
                  ),
                  if (event.permitirVoluntarios) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRegisteringInterest
                            ? null
                            : () => _registerInterest(
                                repository,
                                EventInterestType.voluntario,
                              ),
                        icon: const Icon(Icons.volunteer_activism_outlined),
                        label: const Text('Quero ser voluntário'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerInterest(
    EventsRepository repository,
    EventInterestType type,
  ) async {
    final eventId = widget.event.id;
    final volunteerWhatsapp = type == EventInterestType.voluntario
        ? await _askVolunteerWhatsapp()
        : null;

    if (!mounted) return;
    if (type == EventInterestType.voluntario && volunteerWhatsapp == null) {
      return;
    }

    if (_isRegisteringInterest) {
      return;
    }

    _isRegisteringInterest = true;

    try {
      await repository.registerInterest(
        eventId: eventId,
        interestType: type,
        volunteerWhatsapp: volunteerWhatsapp,
      );

      ref.invalidate(eventRegistrationsProvider(eventId));
      ref.invalidate(eventRegistrationStatsProvider(eventId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == EventInterestType.participante
                ? 'Sua participação foi registrada.'
                : 'Seu interesse em voluntariado foi registrado. Aguarde ser chamado pelo organizador do evento.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel registrar: $error')),
      );
    } finally {
      _isRegisteringInterest = false;
    }
  }

  Widget _buildRegistrationSection({
    required AsyncValue<List<EventRegistrationEntry>> registrationsAsync,
  }) {
    return registrationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inscrições',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Nao foi possivel carregar: $error'),
        ],
      ),
      data: (registrations) {
        final participants = registrations
            .where(
              (item) => item.interestType == EventInterestType.participante,
            )
            .toList();
        final volunteers = registrations
            .where((item) => item.interestType == EventInterestType.voluntario)
            .toList();

        final stats = EventRegistrationStats(
          participantes: participants.length,
          voluntarios: volunteers.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inscrições',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  Icons.people_outline,
                  'Participantes: ${stats.participantes}',
                ),
                _chip(
                  Icons.volunteer_activism_outlined,
                  'Voluntários: ${stats.voluntarios}',
                ),
                _chip(Icons.groups_outlined, 'Total: ${stats.total}'),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askVolunteerWhatsapp() async {
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

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _locationLabel(String tipoLocal) {
    switch (tipoLocal) {
      case 'online':
        return 'Online';
      case 'hibrido':
        return 'Híbrido';
      default:
        return 'Presencial';
    }
  }
}
