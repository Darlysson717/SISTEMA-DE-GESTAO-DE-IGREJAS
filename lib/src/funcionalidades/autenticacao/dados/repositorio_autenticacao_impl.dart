import 'package:centro_social_app/src/nucleo/configuracao/configuracao_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  const AuthRepositoryImpl(this._client);

  @override
  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentAppUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final profile = await _upsertAndReadProfile(user);

      return AppUser(
        id: user.id,
        email: user.email ?? '',
        nome: profile['full_name'] as String?,
        role: UserRole.comunidade,
      );
    } catch (_) {
      final fullName =
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;

      return AppUser(
        id: user.id,
        email: user.email ?? '',
        nome: fullName,
        role: UserRole.comunidade,
      );
    }
  }

  Future<Map<String, dynamic>> _upsertAndReadProfile(User user) async {
    final fullName =
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String?;
    final avatarUrl =
      user.userMetadata?['avatar_url'] as String? ??
      user.userMetadata?['picture'] as String? ??
      user.userMetadata?['photo_url'] as String?;

    for (var attempt = 0; attempt < 3; attempt++) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
      }, onConflict: 'id');

      final response = await _client
          .from('profiles')
          .select('id, email, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    throw Exception('Perfil não encontrado após autenticação.');
  }
}
