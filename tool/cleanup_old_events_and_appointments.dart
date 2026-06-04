import 'dart:convert';
import 'dart:io';

const _eventsBucket = 'eventos_images';
const _chunkSize = 100;

DateTime _subtractMonths(DateTime dt, int months) {
  final y = dt.year;
  final m = dt.month - months;
  final newYear = y + (m <= 0 ? ((m - 11) ~/ 12) : 0);
  final newMonth = ((m - 1) % 12) + 1;
  final day = dt.day;
  final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
  return DateTime(newYear, newMonth, day > lastDayOfMonth ? lastDayOfMonth : day);
}

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
    stderr.writeln(r'  dart run tool/cleanup_old_events_and_appointments.dart --apply');
    exitCode = 1;
    return;
  }

  final now = DateTime.now().toUtc();
  final cutoff = _subtractMonths(now, 2);
  final cutoffDate = '${cutoff.year.toString().padLeft(4, '0')}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';

  final client = HttpClient();
  try {
    stdout.writeln('Cutoff (2 months): $cutoffDate');

    // Load events (data_fim < cutoffDate)
    final events = await _loadOldEvents(client, supabaseUrl, serviceRoleKey, cutoffDate);

    // Load appointments with fallbacks if certain columns are missing
    List<Map<String, dynamic>> appointments = const [];
    try {
      appointments = await _loadOldAppointments(client, supabaseUrl, serviceRoleKey, cutoff.toIso8601String());
    } catch (e) {
      stderr.writeln('Aviso: falha ao consultar appointments com filtro ends_at: $e');
      stderr.writeln('Tentando alternativa: starts_at');
      try {
        appointments = await _loadOldAppointmentsByField(client, supabaseUrl, serviceRoleKey, 'starts_at', cutoff.toIso8601String());
      } catch (e2) {
        stderr.writeln('Aviso: falha ao consultar por starts_at: $e2');
        stderr.writeln('Tentando alternativa: created_at (date)');
        try {
          appointments = await _loadOldAppointmentsByField(client, supabaseUrl, serviceRoleKey, 'created_at', cutoffDate);
        } catch (e3) {
          stderr.writeln('Erro: não foi possível recuperar agendamentos por nenhuma coluna conhecida. Pulando remoção de appointments.');
          appointments = const [];
        }
      }
    }

    stdout.writeln('Eventos encontrados para remoção: ${events.length}');
    if (events.isNotEmpty) {
      stdout.writeln('Detalhes dos eventos encontrados:');
      for (final e in events) {
        final gallery = (e['galeria_imagens_urls'] as List<dynamic>?) ?? <dynamic>[];
        stdout.writeln(' - id=${e['id']}, cover=${e['imagem_capa_url'] ?? ''}, gallery_count=${gallery.length}');
      }
    }

    stdout.writeln('Agendamentos encontrados para remoção: ${appointments.length}');
    if (appointments.isNotEmpty) {
      stdout.writeln('Detalhes dos agendamentos encontrados:');
      for (final a in appointments) {
        stdout.writeln(' - id=${a['id']}, starts_at=${a['starts_at'] ?? a['created_at'] ?? a['ends_at'] ?? 'N/A'}');
      }
    }

    final allPaths = <String>{};
    for (final ev in events) {
      final cover = _extractStoragePathFromPublicUrl(ev['imagem_capa_url'] as String?);
      if (cover != null) allPaths.add(cover);
      final gallery = (ev['galeria_imagens_urls'] as List<dynamic>?) ?? <dynamic>[];
      for (final g in gallery) {
        final p = _extractStoragePathFromPublicUrl(g as String?);
        if (p != null) allPaths.add(p);
      }
    }

    stdout.writeln('Arquivos de storage a remover: ${allPaths.length}');

    if (!apply) {
      stdout.writeln('\nDry-run finalizado. Nada foi excluído.');
      stdout.writeln('Use --apply para executar a remoção de assets e registros.');
      return;
    }

    if (allPaths.isNotEmpty) {
      final pathsList = allPaths.toList();
      for (var i = 0; i < pathsList.length; i += _chunkSize) {
        final chunk = pathsList.skip(i).take(_chunkSize).toList();
        await _deleteStorageObjects(client, supabaseUrl, serviceRoleKey, chunk);
      }
      stdout.writeln('Remoção de arquivos concluída (${allPaths.length}).');
    }

    if (events.isNotEmpty) {
      final ids = events.map((e) => e['id'] as String).toList();
      await _deleteRows(client, supabaseUrl, serviceRoleKey, 'eventos', ids);
      stdout.writeln('Eventos removidos: ${ids.length}');
    }

    if (appointments.isNotEmpty) {
      final ids = appointments.map((a) => a['id'] as String).toList();
      await _deleteRows(client, supabaseUrl, serviceRoleKey, 'appointments', ids);
      stdout.writeln('Agendamentos removidos: ${ids.length}');
    }

    stdout.writeln('Operação concluída.');
  } finally {
    client.close(force: true);
  }
}

Future<List<Map<String, dynamic>>> _loadOldEvents(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  String cutoffDate,
) async {
  final encoded = Uri.encodeComponent(cutoffDate);
  final uri = Uri.parse(
    '$supabaseUrl/rest/v1/eventos?select=id,imagem_capa_url,galeria_imagens_urls&data_fim=lt.$encoded&limit=10000',
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

  return rows.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> _loadOldAppointments(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  String cutoffIso,
) async {
  final encoded = Uri.encodeComponent(cutoffIso);
  final uri = Uri.parse(
    '$supabaseUrl/rest/v1/appointments?select=id,starts_at,ends_at&ends_at=lt.$encoded&limit=10000',
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

  return rows.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> _loadOldAppointmentsByField(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  String field,
  String cutoff,
) async {
  final encoded = Uri.encodeComponent(cutoff);
  final uri = Uri.parse('$supabaseUrl/rest/v1/appointments?select=id,$field&$field=lt.$encoded&limit=10000');

  final rows = await _requestJsonList(
    client: client,
    uri: uri,
    method: 'GET',
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    },
  );

  return rows.cast<Map<String, dynamic>>().map((r) => {'id': r['id']}).toList();
}

Future<void> _deleteStorageObjects(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  List<String> paths,
) async {
  final uri = Uri.parse('$supabaseUrl/storage/v1/object/$_eventsBucket');

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

Future<void> _deleteRows(
  HttpClient client,
  String supabaseUrl,
  String serviceRoleKey,
  String table,
  List<String> ids,
) async {
  final encoded = ids.map((e) => Uri.encodeComponent(e)).join(',');
  final uri = Uri.parse('$supabaseUrl/rest/v1/$table?id=in.($encoded)');

  await _requestJson(
    client: client,
    uri: uri,
    method: 'DELETE',
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    },
    acceptedStatusCodes: {204, 200},
  );
}

String? _extractStoragePathFromPublicUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;
  final uri = Uri.tryParse(imageUrl);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  final bucketIndex = segments.indexOf(_eventsBucket);
  if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return null;
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
      'Falha na requisição ${uri.path} (status ${response.statusCode}): $responseBody',
    );
  }

  if (responseBody.trim().isEmpty) return null;
  return jsonDecode(responseBody);
}
