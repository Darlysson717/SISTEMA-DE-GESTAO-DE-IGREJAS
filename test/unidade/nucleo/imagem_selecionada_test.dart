import 'dart:typed_data';

import 'package:centro_social_app/src/nucleo/utilitarios/imagem_selecionada.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Cria uma [ImagemSelecionada] a partir de um nome de arquivo, sem tocar o
/// sistema de arquivos (nome e mime são resolvidos por string).
ImagemSelecionada _imagem(String nome, {String? mimeType}) =>
    ImagemSelecionada(
      arquivo: XFile(nome, mimeType: mimeType),
      bytes: Uint8List(0),
    );

void main() {
  group('ImagemSelecionada.extensao', () {
    test('extrai a extensão do nome do arquivo', () {
      expect(_imagem('foto.png').extensao, 'png');
      expect(_imagem('capa.webp').extensao, 'webp');
    });

    test('converte a extensão para minúsculas', () {
      expect(_imagem('FOTO.JPG').extensao, 'jpg');
      expect(_imagem('logo.PnG').extensao, 'png');
    });

    test('usa a última extensão em nomes com vários pontos', () {
      expect(_imagem('backup.antigo.gif').extensao, 'gif');
    });

    test('usa jpg como fallback sem extensão ou com ponto final', () {
      expect(_imagem('semextensao').extensao, 'jpg');
      expect(_imagem('arquivo.').extensao, 'jpg');
    });
  });

  group('ImagemSelecionada.contentType', () {
    test('prioriza o mime type informado pelo image_picker', () {
      final imagem = _imagem('foto.png', mimeType: 'image/webp');

      expect(imagem.contentType, 'image/webp');
    });

    test('deriva da extensão quando não há mime type', () {
      expect(_imagem('a.jpg').contentType, 'image/jpeg');
      expect(_imagem('a.jpeg').contentType, 'image/jpeg');
      expect(_imagem('a.png').contentType, 'image/png');
      expect(_imagem('a.webp').contentType, 'image/webp');
      expect(_imagem('a.gif').contentType, 'image/gif');
      expect(_imagem('a.heic').contentType, 'image/heic');
      expect(_imagem('a.bmp').contentType, 'image/bmp');
    });

    test('usa image/jpeg para extensões desconhecidas', () {
      expect(_imagem('documento.xyz').contentType, 'image/jpeg');
      expect(_imagem('semextensao').contentType, 'image/jpeg');
    });
  });

  group('ImagemSelecionada.deXFile', () {
    test('lê os bytes do arquivo no momento da seleção', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final arquivo = XFile.fromData(bytes, name: 'foto.png');

      final imagem = await ImagemSelecionada.deXFile(arquivo);

      expect(imagem.bytes, bytes);
      expect(imagem.arquivo, same(arquivo));
    });
  });
}
