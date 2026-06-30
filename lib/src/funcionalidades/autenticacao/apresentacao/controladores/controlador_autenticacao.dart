import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/entrar_com_google.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/sair.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;

  AuthController({
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
  }) : _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       super(const AsyncData(null));

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_signInWithGoogle.call);
    
    // Registrar token FCM após login bem-sucedido
    if (state is AsyncData) {
      await ServicoNotificacoes().registrarToken();
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_signOut.call);
    
    // Remover token FCM após logout
    await ServicoNotificacoes().removerToken();
  }
}
