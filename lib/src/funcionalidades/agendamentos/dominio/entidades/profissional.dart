class ProfessionalAvailability {
  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  const ProfessionalAvailability({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}

class Professional {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final bool isActive;
  final List<ProfessionalAvailability> availabilities;

  const Professional({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.isActive,
    required this.availabilities,
  });
}
