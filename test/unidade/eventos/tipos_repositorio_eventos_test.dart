import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeOfDaySql.toSql', () {
    test('aplica zero à esquerda em hora e minuto', () {
      expect(const TimeOfDaySql(hour: 8, minute: 5).toSql(), '08:05:00');
      expect(const TimeOfDaySql(hour: 0, minute: 0).toSql(), '00:00:00');
    });

    test('mantém dois dígitos para valores altos', () {
      expect(const TimeOfDaySql(hour: 23, minute: 59).toSql(), '23:59:00');
      expect(const TimeOfDaySql(hour: 12, minute: 30).toSql(), '12:30:00');
    });
  });

  group('EventRegistrationStats.total', () {
    test('soma participantes e voluntários', () {
      const stats = EventRegistrationStats(participantes: 3, voluntarios: 2);

      expect(stats.total, 5);
    });

    test('é zero quando não há inscrições', () {
      const stats = EventRegistrationStats(participantes: 0, voluntarios: 0);

      expect(stats.total, 0);
    });

    test('conta inscrições de um único tipo', () {
      const soParticipantes =
          EventRegistrationStats(participantes: 7, voluntarios: 0);
      const soVoluntarios =
          EventRegistrationStats(participantes: 0, voluntarios: 4);

      expect(soParticipantes.total, 7);
      expect(soVoluntarios.total, 4);
    });
  });
}
