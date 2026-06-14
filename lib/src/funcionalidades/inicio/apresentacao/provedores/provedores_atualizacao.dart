import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const _githubRepositoryUrl =
    'https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS';
const _githubPagesUrl =
  'https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/';
const _githubRawPubspecUrl =
    'https://raw.githubusercontent.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/main/pubspec.yaml';

final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = AppVersion.parse(
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );
    final remoteVersion = await _fetchLatestVersion();

    if (remoteVersion == null) {
      return null;
    }

    if (localVersion.compareTo(remoteVersion.version) >= 0) {
      return null;
    }

    return remoteVersion;
  } catch (_) {
    return null;
  }
});

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.link,
    required this.title,
    required this.message,
  });

  final AppVersion version;
  final String link;
  final String title;
  final String message;

  String get displayVersion => version.toString();
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
    for (var index = 0; index < parts.length && index < other.parts.length; index++) {
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

Future<AppUpdateInfo?> _fetchLatestVersion() async {
  final response = await http.get(
    Uri.parse(_githubRawPubspecUrl),
    headers: const {
      'Accept': 'text/plain',
      'User-Agent': 'centro-social-app',
    },
  );

  if (response.statusCode != 200) {
    return null;
  }

  final match = RegExp(r'^version:\s*([^\s#]+)', multiLine: true)
      .firstMatch(response.body);
  if (match == null) {
    return null;
  }

  final version = AppVersion.parse(match.group(1) ?? '');

  return AppUpdateInfo(
    version: version,
    link: _githubPagesUrl,
    title: 'Atualização disponível',
    message:
        'Existe uma versão mais recente do app no GitHub. Abra o link abaixo para acessar a atualização.',
  );
}