import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/entrar_com_google.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/sair.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final AuthRepository _authRepository;

  /// Flag estática: true quando o usuário marcou o checkbox e clicou em "Entrar"
  static bool _pendingTermsAcceptance = false;

  AuthController({
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required AuthRepository authRepository,
  }) : _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _authRepository = authRepository,
       super(const AsyncData(null));

  /// Inicia o fluxo OAuth do Google.
  /// ATENÇÃO: Este método retorna imediatamente após iniciar o redirecionamento.
  /// O usuário ainda NÃO está logado. O login só é concluído quando o
  /// navegador redireciona de volta para o app.
  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_signInWithGoogle.call);
  }

  /// Marca que o usuário aceitou os termos e inicia o login.
  /// O salvamento no banco (terms_accepted = true) ocorrerá quando o
  /// authStateChanges detectar que o login foi concluído.
  Future<void> loginWithTermsAccepted() async {
    _pendingTermsAcceptance = true;
    await loginWithGoogle();
  }

  /// Deve ser chamado quando o authStateChanges detectar um login concluído.
  /// Salva os termos pendentes e registra o token FCM.
  Future<void> onAuthStateChanged(AuthState state) async {
    if (state.session != null && _pendingTermsAcceptance) {
      _pendingTermsAcceptance = false;
      await _authRepository.acceptConsent();
      await ServicoNotificacoes().registrarToken();
    }
  }

  Future<void> acceptConsent() async {
    await _authRepository.acceptConsent();
  }

  Future<bool> hasAcceptedConsent() async {
    return _authRepository.hasAcceptedConsent();
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    
    // Remover token FCM antes de encerrar a sessão, para garantir acesso ao currentUser
    await ServicoNotificacoes().removerToken();
    state = await AsyncValue.guard(_signOut.call);
  }
}
