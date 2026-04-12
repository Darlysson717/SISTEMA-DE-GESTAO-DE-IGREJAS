import 'package:flutter/material.dart';

class VolunteerWhatsappDialog extends StatefulWidget {
  const VolunteerWhatsappDialog({super.key});

  @override
  State<VolunteerWhatsappDialog> createState() =>
      _VolunteerWhatsappDialogState();
}

class _VolunteerWhatsappDialogState extends State<VolunteerWhatsappDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quero ser voluntário'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informe seu WhatsApp para contato do organizador.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'WhatsApp *',
                hintText: '(11) 99999-9999',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            const Text(
              'Aguarde ser chamado pelo organizador do evento.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final raw = _controller.text.trim();
            if (raw.isEmpty) {
              return;
            }
            FocusScope.of(context).unfocus();
            Navigator.pop(context, raw);
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
