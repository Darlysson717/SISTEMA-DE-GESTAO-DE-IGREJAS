import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerWidget {
  final AppUser user;
  final String titulo;
  final List<HomeAction> actions;

  const HomeShell({
    super.key,
    required this.user,
    required this.titulo,
    required this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nome ?? 'Usuário',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(user.email),
                        const SizedBox(height: 4),
                        Chip(label: Text(user.role.label)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Ações rápidas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...actions.map(
            (action) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: Text(action.label),
                subtitle: const Text('Toque para abrir'),
                trailing: const Icon(Icons.chevron_right),
                onTap: action.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeAction {
  final String label;
  final VoidCallback onTap;

  const HomeAction({required this.label, required this.onTap});
}
