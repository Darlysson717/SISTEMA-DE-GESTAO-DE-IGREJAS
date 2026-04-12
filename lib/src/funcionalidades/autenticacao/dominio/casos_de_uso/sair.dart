import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';

class SignOut {
  final AuthRepository repository;

  const SignOut(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}
