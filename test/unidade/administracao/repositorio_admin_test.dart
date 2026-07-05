import 'package:centro_social_app/src/funcionalidades/administracao/dados/repositorio_admin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePublishRequestStatus', () {
    test('converte os valores conhecidos do banco', () {
      expect(parsePublishRequestStatus('approved'), PublishRequestStatus.approved);
      expect(parsePublishRequestStatus('rejected'), PublishRequestStatus.rejected);
      expect(parsePublishRequestStatus('pending'), PublishRequestStatus.pending);
    });

    test('ignora maiúsculas e espaços ao redor', () {
      expect(
        parsePublishRequestStatus(' APPROVED '),
        PublishRequestStatus.approved,
      );
      expect(
        parsePublishRequestStatus('Rejected'),
        PublishRequestStatus.rejected,
      );
    });

    test('usa pending como padrão para valores desconhecidos', () {
      expect(parsePublishRequestStatus(''), PublishRequestStatus.pending);
      expect(
        parsePublishRequestStatus('valor-invalido'),
        PublishRequestStatus.pending,
      );
    });
  });
}
