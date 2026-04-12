enum AppointmentStatus { scheduled, completed, cancelled, noShow }

extension AppointmentStatusX on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'cancelled';
    }
  }

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

AppointmentStatus parseAppointmentStatus(String status) {
  switch (status) {
    case 'confirmed':
      return AppointmentStatus.scheduled;
    case 'completed':
      return AppointmentStatus.completed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.scheduled;
  }
}

class Appointment {
  final String id;
  final String serviceId;
  final String professionalId;
  final String professionalName;
  final String communityUserId;
  final String communityUserName;
  final String? communityUserPhotoUrl;
  final String specialty;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String? serviceType; // 'online' ou 'presencial'
  final String? location;
  final String? phone;
  final String? notes;

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
