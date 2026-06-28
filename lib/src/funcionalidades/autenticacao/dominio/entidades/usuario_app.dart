/// Papéis de usuário disponíveis no sistema.
///
/// Atualmente o sistema opera com um modelo simplificado onde
/// todos os usuários são tratados como membros da comunidade.
/// A distinção entre profissionais e comunidade é feita
/// automaticamente quando um usuário publica serviços.
enum UserRole { comunidade }

/// Extensões utilitárias para [UserRole].
extension UserRoleX on UserRole {
  /// Retorna o valor do papel no formato do banco (inglês).
  String get value {
    return 'community';
  }

  /// Retorna o label formatado para exibição em português.
  String get label {
    return 'Usuário da comunidade';
  }
}

/// Converte uma string de papel do banco para o enum [UserRole].
///
/// No modelo atual, todos os usuários são 'comunidade'.
UserRole parseUserRole(String? role) {
  return UserRole.comunidade;
}

/// Representa um usuário autenticado no aplicativo.
///
/// [AppUser] é a entidade base que representa qualquer pessoa
/// que fez login no sistema. Contém informações básicas do perfil
/// como ID, e-mail, nome e papel (role).
class AppUser {
  /// ID do usuário no Supabase Auth (UUID).
  final String id;

  /// E-mail do usuário usado no cadastro/login.
  final String email;

  /// Nome completo do usuário (opcional, pode vir do Google OAuth).
  final String? nome;

  /// Papel do usuário no sistema (atualmente sempre 'comunidade').
  final UserRole role;

  /// Cria um [AppUser] com os campos obrigatórios.
  const AppUser({
    required this.id,
    required this.email,
    required this.nome,
    this.role = UserRole.comunidade,
  });
}