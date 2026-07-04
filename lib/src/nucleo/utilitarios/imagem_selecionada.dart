import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Imagem escolhida pelo usuário com os bytes lidos no momento da seleção.
///
/// Funciona em Android, iOS e Web sem depender de `dart:io`. Na web o
/// [XFile.path] é uma blob-URL sem extensão, por isso nome, extensão e
/// content-type são derivados de [XFile.name] e [XFile.mimeType].
class ImagemSelecionada {
  /// Arquivo original retornado pelo image_picker.
  final XFile arquivo;

  /// Conteúdo do arquivo, lido no momento da seleção.
  final Uint8List bytes;

  const ImagemSelecionada({required this.arquivo, required this.bytes});

  /// Cria uma [ImagemSelecionada] lendo os bytes do [arquivo].
  static Future<ImagemSelecionada> deXFile(XFile arquivo) async {
    return ImagemSelecionada(
      arquivo: arquivo,
      bytes: await arquivo.readAsBytes(),
    );
  }

  /// Nome original do arquivo, com extensão (preservado também na web).
  String get nome => arquivo.name;

  /// Extensão do arquivo em minúsculas (fallback: `jpg`).
  String get extensao {
    final ponto = nome.lastIndexOf('.');
    if (ponto == -1 || ponto == nome.length - 1) {
      return 'jpg';
    }
    return nome.substring(ponto + 1).toLowerCase();
  }

  /// Content-type para upload (Storage), derivado do mime ou da extensão.
  String get contentType =>
      arquivo.mimeType ??
      const {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'gif': 'image/gif',
        'heic': 'image/heic',
        'bmp': 'image/bmp',
      }[extensao] ??
      'image/jpeg';
}
