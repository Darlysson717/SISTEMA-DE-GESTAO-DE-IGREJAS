import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/entrar_com_google.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/obter_usuario_app_atual.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/casos_de_uso/sair.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/entidades/usuario_app.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório em memória para verificar a delegação dos casos de uso,
/// sem tocar o Supabase.
class _RepositorioAutenticacaoFalso implements AuthRepository {
  int chamadasSignIn = 0;
  int chamadasSignOut = 0;
  int chamadasGetCurrentAppUser = 0;
  AppUser? usuario;
  Exception? erro;

  @override
  Stream<AuthState> authStateChanges() => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async {
    chamadasSignIn++;
    if (erro != null) {
      throw erro!;
    }
  }

  @override
  Future<void> signOut() async {
    chamadasSignOut++;
    if (erro != null) {
      throw erro!;
    }
  }

  @override
  Future<AppUser?> getCurrentAppUser() async {
    chamadasGetCurrentAppUser++;
    if (erro != null) {
      throw erro!;
    }
    return usuario;
  }
}

void main() {
  late _RepositorioAutenticacaoFalso repositorio;

  setUp(() {
    repositorio = _RepositorioAutenticacaoFalso();
  });

  group('SignInWithGoogle', () {
    test('delega a autenticação ao repositório', () async {
      await SignInWithGoogle(repositorio).call();

      expect(repositorio.chamadasSignIn, 1);
    });

    test('propaga falhas do repositório', () {
      repositorio.erro = Exception('OAuth cancelado');

      expect(SignInWithGoogle(repositorio).call(), throwsException);
    });
  });

  group('SignOut', () {
    test('delega o encerramento de sessão ao repositório', () async {
      await SignOut(repositorio).call();

      expect(repositorio.chamadasSignOut, 1);
    });

    test('propaga falhas do repositório', () {
      repositorio.erro = Exception('Sem conexão');

      expect(SignOut(repositorio).call(), throwsException);
    });
  });

  group('GetCurrentAppUser', () {
    test('retorna o usuário fornecido pelo repositório', () async {
      const usuario = AppUser(
        id: 'usuario-1',
        email: 'teste@iadet.app',
        nome: 'Usuária de Teste',
      );
      repositorio.usuario = usuario;

      final resultado = await GetCurrentAppUser(repositorio).call();

      expect(resultado, same(usuario));
      expect(repositorio.chamadasGetCurrentAppUser, 1);
    });

    test('retorna null quando não há sessão ativa', () async {
      final resultado = await GetCurrentAppUser(repositorio).call();

      expect(resultado, isNull);
    });

    test('propaga falhas do repositório', () {
      repositorio.erro = Exception('Perfil indisponível');

      expect(GetCurrentAppUser(repositorio).call(), throwsException);
    });
  });
}
