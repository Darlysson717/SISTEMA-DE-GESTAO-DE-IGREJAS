import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<AppUser?> getCurrentAppUser();
}
