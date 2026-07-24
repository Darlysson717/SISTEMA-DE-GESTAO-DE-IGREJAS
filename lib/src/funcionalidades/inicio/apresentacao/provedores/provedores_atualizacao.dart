import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider que retorna null se a versão local já é a mais recente,
/// ou [AppUpdateInfo] com os dados da atualização disponível.
final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersionStr = '${packageInfo.version}+${packageInfo.buildNumber}';
    final localVersion = AppVersion.parse(localVersionStr);
    final latestVersion = await _fetchLatestVersionFromSupabase();

    if (latestVersion == null) {
      return null;
    }

    final remoteVersion = AppVersion.parse(
      latestVersion['version_full'] as String? ?? '',
    );

    // Verifica se a versão remota é mais recente que a local
    if (localVersion.compareTo(remoteVersion) >= 0) {
      return null;
    }

    // Extrai o changelog
    final changelog = latestVersion['changelog'] as String? ?? '';
    final parsedChangelog = _parseChangelog(changelog);

    return AppUpdateInfo(
      version: remoteVersion,
      apkDownloadUrl: latestVersion['apk_download_url'] as String? ?? '',
      apkFileName: latestVersion['apk_file_name'] as String?,
      changelog: parsedChangelog,
      isMandatory: latestVersion['is_mandatory'] as bool? ?? false,
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
    this.isMandatory = false,
  });

  final AppVersion version;
  final String apkDownloadUrl;
  final String? apkFileName;
  final String changelog;
  final bool isMandatory;

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

/// Busca a versão mais recente do Supabase
Future<Map<String, dynamic>?> _fetchLatestVersionFromSupabase() async {
  try {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('app_versions')
        .select()
        .eq('is_active', true)
        .order('released_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
}