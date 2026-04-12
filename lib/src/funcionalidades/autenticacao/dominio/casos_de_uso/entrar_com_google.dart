import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  const SignInWithGoogle(this.repository);

  Future<void> call() {
    return repository.signInWithGoogle();
  }
}
