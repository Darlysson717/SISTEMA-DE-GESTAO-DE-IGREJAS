import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const _githubApiLatestRelease =
    'https://api.github.com/repos/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest';

/// Provider que retorna null se a versão local já é a mais recente,
/// ou [AppUpdateInfo] com os dados da atualização disponível.
final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersionStr = '${packageInfo.version}+${packageInfo.buildNumber}';
    final localVersion = AppVersion.parse(localVersionStr);
    final latestRelease = await _fetchLatestReleaseInfo();

    if (latestRelease == null) {
      return null;
    }

    final remoteVersion = AppVersion.parse(
      latestRelease['tag_name'] as String? ?? '',
    );

    if (localVersion.compareTo(remoteVersion) >= 0) {
      return null;
    }

    // Procura o primeiro APK nos assets da release
    final assets = latestRelease['assets'] as List<dynamic>? ?? [];
    String? apkUrl;
    String? apkName;

    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.endsWith('.apk')) {
        apkUrl = asset['browser_download_url'] as String?;
        apkName = asset['name'] as String?;
        break;
      }
    }

    // Se não encontrou APK, usa a página da release como fallback
    apkUrl ??= latestRelease['html_url'] as String? ?? '';

    // Extrai o body/changelog da release e limpa markdown básico
    final body = latestRelease['body'] as String? ?? '';
    final changelog = _parseChangelog(body);

    return AppUpdateInfo(
      version: remoteVersion,
      apkDownloadUrl: apkUrl,
      apkFileName: apkName,
      changelog: changelog,
    );
  } catch (_) {
    return null;
  }
});

/// Provider simples que expõe a versão atual do app (sem lógica de update).
final appVersionProvider = Provider<String>((ref) {
  // Assume que o appUpdateProvider já foi avaliado ou será lazy.
  // Usamos PackageInfo diretamente para evitar depender do Future.
  throw UnimplementedError('Use packageInfoProvider em vez deste');
});

/// Provider que expõe a versão local do app (ex: "1.0.0+1")
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Converte o body da release (markdown) em texto simples com bullets
String _parseChangelog(String body) {
  if (body.trim().isEmpty) {
    return '';
  }

  // Remove markdown básico e mantém bullets
  final lines = body.split('\n');
  final result = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    // Converte ### Título para texto em negrito simples
    if (trimmed.startsWith('###')) {
      result.add(trimmed.replaceAll('#', '').trim());
      continue;
    }

    // Converte ## Título
    if (trimmed.startsWith('##')) {
      result.add(trimmed.replaceAll('#', '').trim());
      continue;
    }

    // Mantém bullets (- ou *)
    if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
      result.add(trimmed);
      continue;
    }

    // Linhas normais
    result.add(trimmed);
  }

  return result.join('\n');
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.apkDownloadUrl,
    this.apkFileName,
    this.changelog = '',
  });

  final AppVersion version;
  final String apkDownloadUrl;
  final String? apkFileName;
  final String changelog;

  String get displayVersion => version.toString();

  String get title => 'Nova versão disponível';

  String get message =>
      'Uma nova versão do aplicativo está disponível para download.';
}

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.parts, this.build);

  final List<int> parts;
  final int build;

  factory AppVersion.parse(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final versionSegments = normalized.split('+');
    final baseParts = versionSegments.first
        .split('.')
        .map(_parseSegment)
        .toList();

    while (baseParts.length < 3) {
      baseParts.add(0);
    }

    final build = versionSegments.length > 1
        ? _parseSegment(versionSegments[1])
        : 0;

    return AppVersion(baseParts, build);
  }

  static int _parseSegment(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) {
      return 0;
    }
    return int.tryParse(match.group(0) ?? '') ?? 0;
  }

  @override
  int compareTo(AppVersion other) {
    // Compara apenas a parte semântica (major.minor.patch), ignorando build
    for (var index = 0;
        index < parts.length && index < other.parts.length;
        index++) {
      final comparison = parts[index].compareTo(other.parts[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return parts.length.compareTo(other.parts.length);
  }

  @override
  String toString() {
    final base = parts.join('.');
    return build > 0 ? '$base+$build' : base;
  }
}

/// Busca as informações da última release do GitHub
Future<Map<String, dynamic>?> _fetchLatestReleaseInfo() async {
  final response = await http.get(
    Uri.parse(_githubApiLatestRelease),
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'centro-social-app',
    },
  );

  if (response.statusCode != 200) {
    return null;
  }

  return jsonDecode(response.body) as Map<String, dynamic>?;
}