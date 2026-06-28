import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';

/// Notificação de cancelamento de agendamento enviada ao usuário da comunidade.
///
/// Quando um profissional cancela um agendamento, uma mensagem é registrada
/// na tabela `appointment_cancellation_messages` para que o usuário afetado
/// possa ser notificado ao abrir o aplicativo.
class CancellationNotice {
  /// Mensagem descritiva do cancelamento.
  final String message;

  /// Data/hora original do agendamento que foi cancelado (opcional).
  final DateTime? scheduledAt;

  /// Nome do profissional que cancelou (opcional).
  final String? professionalName;

  /// Especialidade do serviço cancelado (opcional).
  final String? specialty;

  /// Local do atendimento que foi cancelado (opcional).
  final String? location;

  /// Cria um [CancellationNotice] com a mensagem obrigatória.
  const CancellationNotice({
    required this.message,
    this.scheduledAt,
    this.professionalName,
    this.specialty,
    this.location,
  });
}

/// Interface abstrata do repositório de agendamentos.
///
/// Define o contrato para todas as operações relacionadas a:
/// - Profissionais e suas disponibilidades
/// - Serviços comunitários (CRUD e consultas)
/// - Agendamentos (criação, cancelamento, reagendamento)
/// - Notificações de cancelamento
///
/// A implementação concreta ([SchedulingRepositoryImpl]) utiliza o Supabase
/// como fonte de dados, mas esta interface permite trocar a implementação
/// sem afetar as camadas superiores (casos de uso e UI).
abstract class SchedulingRepository {
  /// Lista profissionais ativos, opcionalmente filtrados por especialidade.
  Future<List<Professional>> listProfessionals({String? specialty});

  /// Lista todos os serviços publicados com status 'ativo'.
  Future<List<Service>> listPublishedServices();

  /// Lista os serviços criados pelo usuário logado.
  Future<List<Service>> listMyServices();

  /// Observa em tempo real os serviços publicados (stream).
  Stream<List<Service>> watchPublishedServices();

  /// Observa em tempo real os serviços do usuário logado (stream).
  Stream<List<Service>> watchMyServices();

  /// Exclui um serviço e seus agendamentos relacionados.
  Future<void> deleteService(String serviceId);

  /// Cria ou atualiza um perfil profissional a partir do e-mail.
  ///
  /// Localiza o usuário pelo e-mail, atualiza a role para 'volunteer'
  /// e insere/atualiza o registro em `professional_profiles`.
  Future<void> upsertProfessionalByEmail({
    required String email,
    required String specialty,
    required bool isActive,
  });

  /// Adiciona um horário de disponibilidade para um profissional.
  Future<void> addAvailability({
    required String professionalId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  });

  /// Remove um horário de disponibilidade pelo ID.
  Future<void> removeAvailability(String availabilityId);

  /// Lista os agendamentos do usuário da comunidade logado.
  Future<List<Appointment>> listCommunityAppointments();

  /// Lista os agendamentos de hoje para o profissional logado.
  Future<List<Appointment>> listTodayProfessionalAppointments();

  /// Lista todos os agendamentos do profissional logado.
  Future<List<Appointment>> listProfessionalAppointments();

  /// Lista todos os agendamentos do sistema (admin).
  Future<List<Appointment>> listAllAppointments();

  /// Observa em tempo real os agendamentos do usuário da comunidade.
  Stream<List<Appointment>> watchCommunityAppointments();

  /// Observa em tempo real os agendamentos do profissional.
  Stream<List<Appointment>> watchProfessionalAppointments();

  /// Observa em tempo real os agendamentos de hoje do profissional.
  Stream<List<Appointment>> watchTodayProfessionalAppointments();

  /// Observa em tempo real todos os agendamentos (admin).
  Stream<List<Appointment>> watchAllAppointments();

  /// Cria um novo agendamento.
  ///
  /// Valida conflitos de horário e agendamentos duplicados antes de inserir.
  /// Lança [Exception] se o horário já estiver ocupado.
  Future<void> createAppointment({
    required DateTime startsAt,
    required String serviceId,
  });

  /// Retorna os horários já agendados para um serviço em uma data específica.
  Future<Set<String>> listBookedTimesForServiceOnDate({
    required String serviceId,
    required DateTime date,
  });

  /// Cancela um agendamento pelo ID.
  ///
  /// Se o cancelamento for feito pelo profissional, uma notificação
  /// é enviada ao usuário da comunidade via [consumeCancellationMessages].
  Future<void> cancelAppointment(String appointmentId);

  /// Consome e retorna as notificações de cancelamento não lidas.
  ///
  /// Após retornar, marca as mensagens como lidas no banco.
  Future<List<CancellationNotice>> consumeCancellationMessages();

  /// Reagenda um agendamento para uma nova data/horário/serviço.
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime startsAt,
    required String serviceId,
  });

  /// Atualiza o status de um agendamento.
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus status,
  });
}