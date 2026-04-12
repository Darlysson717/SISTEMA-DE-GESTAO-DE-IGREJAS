import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';

class CancellationNotice {
  final String message;
  final DateTime? scheduledAt;
  final String? professionalName;
  final String? specialty;
  final String? location;

  const CancellationNotice({
    required this.message,
    this.scheduledAt,
    this.professionalName,
    this.specialty,
    this.location,
  });
}

abstract class SchedulingRepository {
  Future<List<Professional>> listProfessionals({String? specialty});
  Future<List<Service>> listPublishedServices();
  Future<List<Service>> listMyServices();
  Stream<List<Service>> watchPublishedServices();
  Stream<List<Service>> watchMyServices();
  Future<void> deleteService(String serviceId);
  Future<void> upsertProfessionalByEmail({
    required String email,
    required String specialty,
    required bool isActive,
  });
  Future<void> addAvailability({
    required String professionalId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  });
  Future<void> removeAvailability(String availabilityId);

  Future<List<Appointment>> listCommunityAppointments();
  Future<List<Appointment>> listTodayProfessionalAppointments();
  Future<List<Appointment>> listProfessionalAppointments();
  Future<List<Appointment>> listAllAppointments();
  Stream<List<Appointment>> watchCommunityAppointments();
  Stream<List<Appointment>> watchProfessionalAppointments();
  Stream<List<Appointment>> watchTodayProfessionalAppointments();
  Stream<List<Appointment>> watchAllAppointments();

  Future<void> createAppointment({
    required DateTime startsAt,
    required String serviceId,
  });
  Future<Set<String>> listBookedTimesForServiceOnDate({
    required String serviceId,
    required DateTime date,
  });
  Future<void> cancelAppointment(String appointmentId);
  Future<List<CancellationNotice>> consumeCancellationMessages();
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime startsAt,
    required String serviceId,
  });
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus status,
  });
}
