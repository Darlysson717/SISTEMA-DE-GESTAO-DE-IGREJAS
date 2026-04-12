import 'dart:convert';
import 'dart:io';

const _bucketName = 'servicos_images';
const _placeholderFileName = '.emptyFolderPlaceholder';
const _chunkSize = 100;

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');

  final supabaseUrl = Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final serviceRoleKey =
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY']?.trim() ?? '';

  if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty) {
    stderr.writeln('Erro: defina SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY.');
    stderr.writeln('Exemplo PowerShell:');
    stderr.writeln(r'  $env:SUPABASE_URL="https://SEU-PROJETO.supabase.co"');
    stderr.writeln(r'  $env:SUPABASE_SERVICE_ROLE_KEY="SUA_SERVICE_ROLE_KEY"');
    stderr.writeln(r'  dart run tool/clean_orphan_service_images.dart --apply');
    exitCode = 1;
    return;
  }

  final client = HttpClient();
  try {
    final referencedPaths = await _loadReferencedServiceImages(
      client,
      supabaseUrl,
      serviceRoleKey,
    );

    final storagePaths = await _loadStorageObjectPaths(
      client,
      supabaseUrl,
      serviceRoleKey,
    );

    final orphanPaths =
        storagePaths
            .where((path) => !referencedPaths.contains(path))
            .where((path) => !_isPlaceholderPath(path))
            .toList()
          ..sort();

    stdout.writeln('Imagens referenciadas: ${referencedPaths.length}');
    stdout.writeln('Arquivos no bucket: ${storagePaths.length}');
    stdout.writeln('Órfãs encontradas: ${orphanPaths.length}');

    if (orphanPaths.isNotEmpty) {
      for (final path in orphanPaths) {
        stdout.writeln(' - $path');
      }
    }

    if (!apply) {
      stdout.writeln('');
      stdout.writeln('Dry-run finalizado. Nada foi excluído.');
      stdout.writeln('Use --apply para remover as órfãs via Storage API.');
      return;
    }

    if (orphanPaths.isEmpty) {
      stdout.writeln('Nenhuma imagem órfã para excluir.');
      return;
    }

    var deletedCount = 0;
    for (var i = 0; i < orphanPaths.length; i += _chunkSize) {
      final chunk = orphanPaths.skip(i).take(_chunkSize).toList();
      await _deleteStorageObjects(client, supabaseUrl, serviceRoleKey, chunk);
      deletedCount += chunk.length;
    }

    stdout.writeln('Exclusão concluída. Arquivos removidos: $deletedCount');
  } finally {
    client.close(force: true);
  }
}

Future<Set<String>> _loadReferencedServiceImages(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
) async {
  final uri = Uri.parse(
    '$supabaseUrl/rest/v1/servicos'
    '?select=imagem_profissional'
    '&imagem_profissional=not.is.null'
    '&limit=10000',
  );

  final rows = await _requestJsonList(
    client: client,
    uri: uri,
    method: 'GET',
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    },
  );

  final paths = <String>{};
  for (final row in rows) {
    final imageUrl = (row['imagem_profissional'] as String?)?.trim();
    final path = _extractStoragePathFromPublicUrl(imageUrl);
    if (path != null && path.isNotEmpty) {
      paths.add(path);
    }
  }

  return paths;
}

Future<Set<String>> _loadStorageObjectPaths(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
) async {
  final uri = Uri.parse(
    '$supabaseUrl/rest/v1/objects'
    '?select=name'
    '&bucket_id=eq.$_bucketName'
    '&limit=10000',
  );

  final rows = await _requestJsonList(
    client: client,
    uri: uri,
    method: 'GET',
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Accept-Profile': 'storage',
    },
  );

  return rows
      .map((row) => (row['name'] as String?)?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toSet();
}

Future<void> _deleteStorageObjects(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  List<String> paths,
) async {
  final uri = Uri.parse('$supabaseUrl/storage/v1/object/$_bucketName');

  await _requestJson(
    client: client,
    uri: uri,
    method: 'DELETE',
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
    },
    body: {'prefixes': paths},
    acceptedStatusCodes: {200},
  );
}

bool _isPlaceholderPath(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return false;
  }

  return normalized == _placeholderFileName ||
      normalized.endsWith('/$_placeholderFileName');
}

String? _extractStoragePathFromPublicUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(imageUrl);
  if (uri == null) {
    return null;
  }

  final segments = uri.pathSegments;
  final bucketIndex = segments.indexOf(_bucketName);
  if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
    return null;
  }

  final encodedPath = segments.sublist(bucketIndex + 1).join('/');
  return Uri.decodeComponent(encodedPath);
}

Future<List<Map<String, dynamic>>> _requestJsonList({
  required HttpClient client,
  required Uri uri,
  required String method,
  required Map<String, String> headers,
}) async {
  final data = await _requestJson(
    client: client,
    uri: uri,
    method: method,
    headers: headers,
    acceptedStatusCodes: {200},
  );

  if (data is! List) {
    throw Exception('Resposta inesperada para $uri: esperado JSON array.');
  }

  return data.cast<Map<String, dynamic>>();
}

Future<dynamic> _requestJson({
  required HttpClient client,
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  Map<String, dynamic>? body,
  Set<int> acceptedStatusCodes = const {200},
}) async {
  final request = await client.openUrl(method, uri);
  headers.forEach(request.headers.set);

  if (body != null) {
    request.write(jsonEncode(body));
  }

  final response = await request.close();
  final responseBody = await utf8.decodeStream(response);

  if (!acceptedStatusCodes.contains(response.statusCode)) {
    throw Exception(
      'Falha na requisição ${uri.path} '
      '(status ${response.statusCode}): $responseBody',
    );
  }

  if (responseBody.trim().isEmpty) {
    return null;
  }

  return jsonDecode(responseBody);
}
