import 'package:centro_social_app/src/funcionalidades/autenticacao/dados/repositorio_autenticacao_impl.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/obter_usuario_app_atual.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/entrar_com_google.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/sair.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

final getCurrentAppUserProvider = Provider<GetCurrentAppUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentAppUser(repository);
});

final currentAppUserProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  ref.watch(authStateChangesProvider);
  final usecase = ref.watch(getCurrentAppUserProvider);
  return usecase();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(
        signInWithGoogle: SignInWithGoogle(repository),
        signOut: SignOut(repository),
      );
    });
