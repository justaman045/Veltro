import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.changelog,
    required this.downloadUrl,
  });
}

class UpdateController {
  // IMPORTANT: The user must explicitly define their exact GitHub Username or correct repository namespace below
  // so the OTA pipeline can locate the raw app_version.json payload branch target!
  static const String repoPath = 'justaman045/agentic-todo';
  static const String branch =
      'master'; // fallback to 'main' if your repository requires it

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionString =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      // Ping GitHub Raw content CDN to fetch the CI/CD generated version payload
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$repoPath/$branch/app_version.json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersionString = data['version'] as String;

        final hasUpdate = _compareSemVer(
          currentVersionString,
          latestVersionString,
        );

        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersionString,
          latestVersion: latestVersionString,
          changelog: data['changelog'] ?? 'No changelog provided.',
          downloadUrl: data['downloadUrl'] ?? '',
        );
      }
    } catch (e) {
      // Catch socket exceptions quietly since offline users don't need update notifications
      debugPrint('Network exception caught firing OTA check: $e');
    }
    return null;
  }

  /// Performs mathematical comparisons across string semantic versions (ex. "1.0.12+3")
  static bool _compareSemVer(String current, String latest) {
    if (current == latest) return false;

    int computePower(String v) {
      final parts = v.split('+');
      final semver = parts[0].split('.');

      int major = semver.isNotEmpty ? int.tryParse(semver[0]) ?? 0 : 0;
      int minor = semver.length > 1 ? int.tryParse(semver[1]) ?? 0 : 0;
      int patch = semver.length > 2 ? int.tryParse(semver[2]) ?? 0 : 0;
      int build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      return (major * 1000000000) + (minor * 1000000) + (patch * 1000) + build;
    }

    return computePower(latest) > computePower(current);
  }
}
