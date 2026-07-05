import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentStatusX.value', () {
    test('converte cada status para o formato do banco', () {
      expect(AppointmentStatus.scheduled.value, 'agendado');
      expect(AppointmentStatus.completed.value, 'concluido');
      expect(AppointmentStatus.cancelled.value, 'cancelado');
      expect(AppointmentStatus.noShow.value, 'faltou');
    });
  });

  group('AppointmentStatusX.label', () {
    test('formata cada status para exibição em português', () {
      expect(AppointmentStatus.scheduled.label, 'Agendado');
      expect(AppointmentStatus.completed.label, 'Concluído');
      expect(AppointmentStatus.cancelled.label, 'Cancelado');
      expect(AppointmentStatus.noShow.label, 'Faltou');
    });
  });

  group('parseAppointmentStatus', () {
    test('converte os valores conhecidos do banco', () {
      expect(parseAppointmentStatus('agendado'), AppointmentStatus.scheduled);
      expect(parseAppointmentStatus('concluido'), AppointmentStatus.completed);
      expect(parseAppointmentStatus('cancelado'), AppointmentStatus.cancelled);
      expect(parseAppointmentStatus('faltou'), AppointmentStatus.noShow);
    });

    test('usa agendado como padrão para valores desconhecidos', () {
      expect(parseAppointmentStatus(''), AppointmentStatus.scheduled);
      expect(
        parseAppointmentStatus('valor-invalido'),
        AppointmentStatus.scheduled,
      );
    });

    test('é sensível a maiúsculas, caindo no padrão', () {
      expect(parseAppointmentStatus('CANCELADO'), AppointmentStatus.scheduled);
    });

    test('faz ida e volta com value para todos os status', () {
      for (final status in AppointmentStatus.values) {
        expect(
          parseAppointmentStatus(status.value),
          status,
          reason: 'status ${status.name} deve sobreviver ao round-trip',
        );
      }
    });
  });

  group('Appointment', () {
    test('atribui os campos obrigatórios e opcionais', () {
      final inicio = DateTime(2026, 7, 10, 9);
      final fim = DateTime(2026, 7, 10, 10);
      final agendamento = Appointment(
        id: 'agendamento-1',
        serviceId: 'servico-1',
        professionalId: 'profissional-1',
        professionalName: 'Dra. Ana',
        communityUserId: 'usuario-1',
        communityUserName: 'João',
        specialty: 'Psicologia',
        startsAt: inicio,
        endsAt: fim,
        status: AppointmentStatus.scheduled,
      );

      expect(agendamento.id, 'agendamento-1');
      expect(agendamento.serviceId, 'servico-1');
      expect(agendamento.professionalId, 'profissional-1');
      expect(agendamento.professionalName, 'Dra. Ana');
      expect(agendamento.communityUserId, 'usuario-1');
      expect(agendamento.communityUserName, 'João');
      expect(agendamento.specialty, 'Psicologia');
      expect(agendamento.startsAt, inicio);
      expect(agendamento.endsAt, fim);
      expect(agendamento.status, AppointmentStatus.scheduled);
      expect(agendamento.communityUserPhotoUrl, isNull);
      expect(agendamento.serviceType, isNull);
      expect(agendamento.location, isNull);
      expect(agendamento.phone, isNull);
      expect(agendamento.notes, isNull);
    });
  });
}
