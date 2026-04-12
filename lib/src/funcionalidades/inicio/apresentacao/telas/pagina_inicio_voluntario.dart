import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/shell_inicio.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agenda_diaria_voluntario.dart';
import 'package:flutter/material.dart';

class VolunteerHomePage extends StatelessWidget {
  final AppUser user;

  const VolunteerHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      titulo: 'Painel do Voluntário',
      actions: [
        HomeAction(
          label: 'Ver agenda do dia',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VolunteerDayAgendaPage()),
          ),
        ),
      ],
    );
  }
}
