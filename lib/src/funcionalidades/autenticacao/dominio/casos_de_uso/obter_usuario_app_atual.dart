import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';

class GetCurrentAppUser {
  final AuthRepository repository;

  const GetCurrentAppUser(this.repository);

  Future<AppUser?> call() {
    return repository.getCurrentAppUser();
  }
}
