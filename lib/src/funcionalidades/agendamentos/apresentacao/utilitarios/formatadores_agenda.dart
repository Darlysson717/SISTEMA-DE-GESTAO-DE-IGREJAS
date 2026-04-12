import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:intl/intl.dart';

String formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

String formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

String dayLabel(int dayOfWeek) {
  switch (dayOfWeek) {
    case 0:
      return 'Domingo';
    case 1:
      return 'Segunda';
    case 2:
      return 'Terça';
    case 3:
      return 'Quarta';
    case 4:
      return 'Quinta';
    case 5:
      return 'Sexta';
    case 6:
      return 'Sábado';
    default:
      return 'Dia';
  }
}

String statusLabel(AppointmentStatus status) => status.label;
