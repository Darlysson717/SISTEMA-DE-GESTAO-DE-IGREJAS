import 'package:flutter/material.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/servicos/apresentacao/componentes/formulario_oferecer_servico.dart';

class OfferServicePage extends StatelessWidget {
  final Service? initialService;

  const OfferServicePage({super.key, this.initialService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialService == null
            ? 'Oferecer um Servico'
            : 'Editar Servico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OfferServiceForm(initialService: initialService),
      ),
    );
  }
}