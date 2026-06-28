/// Representa um horário de disponibilidade semanal de um profissional.
///
/// Cada [ProfessionalAvailability] define um período (início e fim) em que
/// o profissional está disponível para agendamentos em um dia específico da semana.
/// O [dayOfWeek] segue o padrão ISO (1=segunda, 7=domingo).
class ProfessionalAvailability {
  /// Identificador único da disponibilidade no Supabase.
  final String id;

  /// Dia da semana (1=segunda-feira, 7=domingo).
  final int dayOfWeek;

  /// Horário de início no formato 'HH:mm'.
  final String startTime;

  /// Horário de término no formato 'HH:mm'.
  final String endTime;

  /// Cria uma [ProfessionalAvailability] com todos os campos obrigatórios.
  const ProfessionalAvailability({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}

/// Representa um profissional voluntário que oferece serviços na comunidade.
///
/// Cada [Professional] está vinculado a um perfil de usuário e possui
/// uma especialidade, status de atividade e uma lista de horários
/// disponíveis para agendamento.
class Professional {
  /// ID do usuário no Supabase Auth (mesmo ID do perfil).
  final String id;

  /// Nome completo do profissional para exibição.
  final String name;

  /// E-mail de contato do profissional.
  final String email;

  /// Especialidade ou área de atuação (ex: Psicologia, Jurídico).
  final String specialty;

  /// Indica se o profissional está ativo e disponível para agendamentos.
  final bool isActive;

  /// Lista de horários de disponibilidade semanal.
  final List<ProfessionalAvailability> availabilities;

  /// Cria um [Professional] com todos os campos obrigatórios.
  const Professional({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.isActive,
    required this.availabilities,
  });
}