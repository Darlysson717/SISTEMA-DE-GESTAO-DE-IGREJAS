import 'package:flutter_test/flutter_test.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';

void main() {
  test('Todos os usuários são tratados como comunidade', () {
    expect(parseUserRole('admin'), UserRole.comunidade);
    expect(parseUserRole('volunteer'), UserRole.comunidade);
    expect(parseUserRole('community'), UserRole.comunidade);
    expect(parseUserRole('valor-invalido'), UserRole.comunidade);
    expect(parseUserRole(null), UserRole.comunidade);
  });
}
