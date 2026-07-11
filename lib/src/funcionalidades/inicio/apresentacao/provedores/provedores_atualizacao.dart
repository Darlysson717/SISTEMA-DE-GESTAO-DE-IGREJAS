import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const _githubApiLatestRelease =
    'https://api.github.com/repos/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest';

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

    final tagName =
        latestRelease['tag_name'] as String? ?? remoteVersion.toString();

    return AppUpdateInfo(
      version: remoteVersion,
      apkDownloadUrl: apkUrl,
      apkFileName: apkName,
    );
  } catch (_) {
    return null;
  }
});

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.apkDownloadUrl,
    this.apkFileName,
  });

  final AppVersion version;
  final String apkDownloadUrl;
  final String? apkFileName;

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
    for (var index = 0;
        index < parts.length && index < other.parts.length;
        index++) {
      final comparison = parts[index].compareTo(other.parts[index]);
      if (comparison != 0) {
        return comparison;
      }
    }

    final buildComparison = build.compareTo(other.build);
    if (buildComparison != 0) {
      return buildComparison;
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