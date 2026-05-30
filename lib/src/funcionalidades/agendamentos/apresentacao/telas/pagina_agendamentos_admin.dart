import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/utilitarios/formatadores_agenda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminAppointmentsPage extends ConsumerStatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  ConsumerState<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends ConsumerState<AdminAppointmentsPage> {
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _emailController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final professionalsAsync = ref.watch(professionalsProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administração de Atendimentos'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group_outlined), text: 'Profissionais'),
              Tab(icon: Icon(Icons.list_alt_outlined), text: 'Atendimentos'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(professionalsProvider);
            ref.invalidate(allAppointmentsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: TabBarView(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
                children: [
                  _buildProfessionalForm(context),
                  const SizedBox(height: 16),
                  Text(
                    'Profissionais e disponibilidades',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  professionalsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Card(
                          child: ListTile(
                            title: Text('Nenhum profissional cadastrado.'),
                          ),
                        );
                      }
                      return Column(
                        children: items
                            .map(
                              (professional) => _ProfessionalAdminCard(
                                professional: professional,
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Card(
                      child: ListTile(
                        title: Text('Erro ao carregar profissionais: $error'),
                      ),
                    ),
                  ),
                ],
              ),
              ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
                children: [
                  appointmentsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Card(
                          child: ListTile(
                            title: Text('Nenhum atendimento registrado.'),
                          ),
                        );
                      }

                      return Column(
                        children: items
                            .map(
                              (item) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    '${item.communityUserName} com ${item.professionalName}',
                                  ),
                                  subtitle: Text(
                                    '${item.specialty} • ${formatDateTime(item.startsAt)}',
                                  ),
                                  trailing: Chip(
                                    label: Text(statusLabel(item.status)),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Card(
                      child: ListTile(
                        title: Text('Erro ao carregar atendimentos: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastro de profissional com especialidade',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail do usuário já cadastrado no sistema',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Especialidade (ex.: Psicologia)',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('Profissional ativo'),
              contentPadding: EdgeInsets.zero,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (_emailController.text.trim().isEmpty ||
                      _specialtyController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha e-mail e especialidade.'),
                      ),
                    );
                    return;
                  }

                  await ref
                      .read(schedulingRepositoryProvider)
                      .upsertProfessionalByEmail(
                        email: _emailController.text,
                        specialty: _specialtyController.text,
                        isActive: _isActive,
                      );
                  ref.invalidate(professionalsProvider);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profissional atualizado com sucesso.'),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar profissional: $error'),
                    ),
                  );
                }
              },
              child: const Text('Salvar profissional'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalAdminCard extends ConsumerWidget {
  final Professional professional;

  const _ProfessionalAdminCard({required this.professional});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text('${professional.name} • ${professional.specialty}'),
              subtitle: Text(professional.email),
              trailing: IconButton(
                onPressed: () => _openAddAvailabilityDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Adicionar disponibilidade',
              ),
            ),
            if (professional.availabilities.isEmpty)
              const Text('Sem horários cadastrados.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: professional.availabilities
                    .map(
                      (a) => InputChip(
                        label: Text(
                          '${dayLabel(a.dayOfWeek)} ${a.startTime}-${a.endTime}',
                        ),
                        onDeleted: () async {
                          await ref
                              .read(schedulingRepositoryProvider)
                              .removeAvailability(a.id);
                          ref.invalidate(professionalsProvider);
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddAvailabilityDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    int selectedDay = 1;
    TimeOfDay? start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? end = const TimeOfDay(hour: 12, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar disponibilidade'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(dayLabel(index)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => selectedDay = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start!,
                          );
                          if (picked == null) {
                            return;
                          }
                          setState(() => start = picked);
                        },
                        child: Text('Início ${start!.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: end!,
                          );
                          if (picked == null) {
                            return;
                          }
                          setState(() => end = picked);
                        },
                        child: Text('Fim ${end!.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final startText =
                      '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}:00';
                  final endText =
                      '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}:00';

                  await ref
                      .read(schedulingRepositoryProvider)
                      .addAvailability(
                        professionalId: professional.id,
                        dayOfWeek: selectedDay,
                        startTime: startText,
                        endTime: endText,
                      );

                  ref.invalidate(professionalsProvider);

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
