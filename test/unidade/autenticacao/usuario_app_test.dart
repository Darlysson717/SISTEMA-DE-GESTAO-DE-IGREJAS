import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseUserRole', () {
    test('trata qualquer papel do banco como comunidade', () {
      expect(parseUserRole('admin'), UserRole.comunidade);
      expect(parseUserRole('volunteer'), UserRole.comunidade);
      expect(parseUserRole('community'), UserRole.comunidade);
      expect(parseUserRole('valor-invalido'), UserRole.comunidade);
      expect(parseUserRole(''), UserRole.comunidade);
      expect(parseUserRole(null), UserRole.comunidade);
    });
  });

  group('UserRoleX', () {
    test('value usa o formato do banco em inglês', () {
      expect(UserRole.comunidade.value, 'community');
    });

    test('label é formatado em português', () {
      expect(UserRole.comunidade.label, 'Usuário da comunidade');
    });
  });

  group('AppUser', () {
    test('usa comunidade como papel padrão', () {
      const usuario = AppUser(
        id: 'usuario-1',
        email: 'teste@iadet.app',
        nome: 'Usuária de Teste',
      );

      expect(usuario.role, UserRole.comunidade);
    });

    test('atribui os campos informados, incluindo nome nulo', () {
      const usuario = AppUser(
        id: 'usuario-1',
        email: 'teste@iadet.app',
        nome: null,
      );

      expect(usuario.id, 'usuario-1');
      expect(usuario.email, 'teste@iadet.app');
      expect(usuario.nome, isNull);
    });
  });
}
