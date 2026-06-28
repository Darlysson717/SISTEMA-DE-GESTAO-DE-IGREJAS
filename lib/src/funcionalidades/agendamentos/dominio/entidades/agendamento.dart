/// Status possíveis para um agendamento no sistema.
///
/// Representa o ciclo de vida de um agendamento:
/// - [scheduled]: Agendado e aguardando atendimento
/// - [completed]: Atendimento concluído com sucesso
/// - [cancelled]: Cancelado por qualquer uma das partes
/// - [noShow]: Profissional aguardou mas o usuário não compareceu
enum AppointmentStatus { scheduled, completed, cancelled, noShow }

/// Extensões utilitárias para [AppointmentStatus].
///
/// Fornece:
/// - [value]: String no formato do banco (pt-BR)
/// - [label]: String formatada para exibição na UI
extension AppointmentStatusX on AppointmentStatus {
  /// Retorna o valor do status no formato usado pelo Supabase.
  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'agendado';
      case AppointmentStatus.completed:
        return 'concluido';
      case AppointmentStatus.cancelled:
        return 'cancelado';
      case AppointmentStatus.noShow:
        return 'faltou';
    }
  }

  /// Retorna o label formatado para exibição em português.
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Agendado';
      case AppointmentStatus.completed:
        return 'Concluído';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.noShow:
        return 'Faltou';
    }
  }
}

/// Converte uma string de status do banco para o enum [AppointmentStatus].
///
/// Por padrão, retorna [AppointmentStatus.scheduled] caso o valor
/// não corresponda a nenhum status conhecido.
AppointmentStatus parseAppointmentStatus(String status) {
  switch (status) {
    case 'agendado':
      return AppointmentStatus.scheduled;
    case 'concluido':
      return AppointmentStatus.completed;
    case 'cancelado':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.scheduled;
  }
}

/// Representa um agendamento de serviço entre um membro da comunidade
/// e um profissional voluntário.
///
/// Cada [Appointment] vincula um [communityUserId] (membro da comunidade)
/// a um serviço específico prestado por um profissional. Contém todas as
/// informações necessárias para exibição e gerenciamento do agendamento,
/// incluindo data, horário, local, tipo de atendimento e observações.
class Appointment {
  /// Identificador único do agendamento no Supabase.
  final String id;

  /// ID do serviço ao qual este agendamento está vinculado.
  final String serviceId;

  /// ID do profissional (dono do serviço) no Supabase Auth.
  final String professionalId;

  /// Nome do profissional para exibição na UI.
  final String professionalName;

  /// ID do usuário da comunidade que fez o agendamento.
  final String communityUserId;

  /// Nome do usuário da comunidade para exibição.
  final String communityUserName;

  /// URL da foto do perfil do usuário da comunidade (opcional).
  final String? communityUserPhotoUrl;

  /// Especialidade/categoria do serviço agendado.
  final String specialty;

  /// Data e hora de início do agendamento.
  final DateTime startsAt;

  /// Data e hora de término (calculada com base na duração do serviço).
  final DateTime endsAt;

  /// Status atual do agendamento.
  final AppointmentStatus status;

  /// Tipo de atendimento: 'online' ou 'presencial'.
  final String? serviceType;

  /// Local do atendimento presencial (endereço ou sala).
  final String? location;

  /// Telefone para contato relacionado ao serviço.
  final String? phone;

  /// Observações adicionais sobre o agendamento.
  final String? notes;

  /// Cria um [Appointment] com todos os campos obrigatórios.
  const Appointment({
    required this.id,
    required this.serviceId,
    required this.professionalId,
    required this.professionalName,
    required this.communityUserId,
    required this.communityUserName,
    this.communityUserPhotoUrl,
    required this.specialty,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.serviceType,
    this.location,
    this.phone,
    this.notes,
  });
}