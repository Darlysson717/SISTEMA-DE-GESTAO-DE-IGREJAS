enum UserRole { comunidade }

extension UserRoleX on UserRole {
  String get value {
    return 'community';
  }

  String get label {
    return 'Usuário da comunidade';
  }
}

UserRole parseUserRole(String? role) {
  return UserRole.comunidade;
}

class AppUser {
  final String id;
  final String email;
  final String? nome;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.nome,
    this.role = UserRole.comunidade,
  });
}
