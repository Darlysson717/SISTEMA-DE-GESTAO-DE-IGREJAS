import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/inicio/apresentacao/telas/shell_inicio.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/telas/pagina_agendamentos_usuario.dart';
import 'package:flutter/material.dart';

class CommunityHomePage extends StatelessWidget {
  final AppUser user;

  const CommunityHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      titulo: 'Serviços da Comunidade',
      actions: [
        HomeAction(
          label: 'Ver profissionais disponíveis',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserAppointmentsPage()),
          ),
        ),
        HomeAction(
          label: 'Agendar, cancelar ou reagendar horário',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserAppointmentsPage()),
          ),
        ),
      ],
    );
  }
}
