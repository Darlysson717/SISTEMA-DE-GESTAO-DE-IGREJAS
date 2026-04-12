import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_anunciar_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/telas/pagina_detalhes_evento.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/card_feed_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MyEventsPage extends ConsumerStatefulWidget {
  const MyEventsPage({super.key});

  @override
  ConsumerState<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends ConsumerState<MyEventsPage> {
  String? _deletingEventId;
  String _statusFilter = 'todos';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(myEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MEUS EVENTOS')),
      body: eventsAsync.when(
        data: (events) {
          final filteredEvents = _applyStatusFilter(events);

          if (events.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('todos', 'Todos'),
                      const SizedBox(width: 8),
                      _buildFilterChip('publicado', 'Publicados'),
                      const SizedBox(width: 8),
                      _buildFilterChip('agendado', 'Agendados'),
                      const SizedBox(width: 8),
                      _buildFilterChip('cancelado', 'Cancelados'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredEvents.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhum evento encontrado para esse filtro.',
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EventFeedCard(
                                event: event,
                                onCardTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailsPage(event: event),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.circle, size: 10),
                                    label: Text(_statusLabel(event.status)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnnounceEventPage(
                                            initialEvent: event,
                                          ),
                                        ),
                                      );

                                      if (!mounted) return;
                                      _refreshEventFeeds();
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: _deletingEventId == event.id
                                        ? null
                                        : () => _onDeleteEvent(event),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _deletingEventId == event.id
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.delete_outline),
                                    label: Text(
                                      _deletingEventId == event.id
                                          ? 'Excluindo...'
                                          : 'Excluir',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildRegistrationsNamesSection(event),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao carregar eventos: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Você ainda não possui eventos cadastrados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnounceEventPage()),
                );

                if (!mounted) return;
                _refreshEventFeeds();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Anunciar evento'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDeleteEvent(AppEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir evento'),
          content: Text('Tem certeza que deseja excluir "${event.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _deletingEventId = event.id);
    try {
      await ref.read(eventsRepositoryProvider).deleteEvent(event);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluido com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir evento: $e')));
    } finally {
      if (mounted) {
        setState(() => _deletingEventId = null);
      }
    }
  }

  void _refreshEventFeeds() {
    ref.invalidate(myEventsProvider);
    ref.invalidate(publishedEventsProvider);
  }

  Widget _buildRegistrationsNamesSection(AppEvent event) {
    final registrationsAsync = ref.watch(eventRegistrationsProvider(event.id));

    return registrationsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (error, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Nao foi possivel carregar inscritos: $error',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      data: (registrations) {
        final participantes = registrations
            .where(
              (item) => item.interestType == EventInterestType.participante,
            )
            .toList();
        final voluntarios = registrations
            .where((item) => item.interestType == EventInterestType.voluntario)
            .toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNamesGroup(
                title: 'Quem vai participar (${participantes.length})',
                people: participantes,
                emptyLabel: 'Nenhum participante ainda.',
              ),
              if (event.permitirVoluntarios) ...[
                const SizedBox(height: 10),
                _buildNamesGroup(
                  title: 'Quem quer ser voluntário (${voluntarios.length})',
                  people: voluntarios,
                  emptyLabel: 'Nenhum voluntário ainda.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNamesGroup({
    required String title,
    required List<EventRegistrationEntry> people,
    required String emptyLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        if (people.isEmpty)
          Text(emptyLabel, style: const TextStyle(color: Color(0xFF64748B)))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: people
                .map(
                  (person) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildPersonRow(person),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPersonRow(EventRegistrationEntry person) {
    final hasWhatsapp = (person.volunteerWhatsapp ?? '').trim().isNotEmpty;
    final canContactWhatsapp =
        person.interestType == EventInterestType.voluntario && hasWhatsapp;

    if (!canContactWhatsapp) {
      return Text('• ${person.displayName}');
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '• ${person.displayName}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _openVolunteerWhatsapp(person.volunteerWhatsapp!),
          icon: const Icon(Icons.chat_outlined, size: 16),
          label: const Text('WhatsApp'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _openVolunteerWhatsapp(String rawWhatsapp) async {
    final digits = rawWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp inválido para contato.')),
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/$digits');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'publicado':
        return 'Publicado';
      case 'agendado':
        return 'Agendado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Outro';
    }
  }

  List<AppEvent> _applyStatusFilter(List<AppEvent> events) {
    if (_statusFilter == 'todos') {
      return events;
    }
    return events.where((event) => event.status == _statusFilter).toList();
  }

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) {
        setState(() => _statusFilter = value);
      },
    );
  }
}
