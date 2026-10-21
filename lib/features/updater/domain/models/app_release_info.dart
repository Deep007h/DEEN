import 'package:flutter/foundation.dart';

/// Represents release metadata fetched from the GitHub repository releases.
@immutable
class AppReleaseInfo {
  final String tagName;
  final String title;
  final String releaseNotes;
  final String htmlUrl;
  final String apkDownloadUrl;
  final int? apkSize;
  final DateTime? publishedAt;

  const AppReleaseInfo({
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.apkDownloadUrl,
    this.apkSize,
    this.publishedAt,
  });

  /// Factory constructor to parse GitHub release JSON response.
  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String?)?.trim() ?? '';
    final title = (json['name'] as String?)?.trim() ?? tagName;
    final releaseNotes = (json['body'] as String?)?.trim() ?? '';
    final htmlUrl = (json['html_url'] as String?)?.trim() ?? 'https://github.com/Deep007h/DEEN/releases';

    DateTime? published;
    if (json['published_at'] != null) {
      published = DateTime.tryParse(json['published_at'] as String);
    }

    String apkUrl = htmlUrl;
    int? apkSize;

    // Scan release assets for .apk file
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      // Prioritize arm64-v8a or release apk, then any .apk
      Map<String, dynamic>? selectedAsset;
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            if (name.contains('arm64-v8a')) {
              selectedAsset = asset;
              break;
            } else if (selectedAsset == null || name.contains('release')) {
              selectedAsset = asset;
            }
          }
        }
      }

      if (selectedAsset != null) {
        apkUrl = (selectedAsset['browser_download_url'] as String?)?.trim() ?? htmlUrl;
        apkSize = selectedAsset['size'] as int?;
      }
    }

    return AppReleaseInfo(
      tagName: tagName,
      title: title.isNotEmpty ? title : 'DEEN $tagName',
      releaseNotes: releaseNotes,
      htmlUrl: htmlUrl,
      apkDownloadUrl: apkUrl,
      apkSize: apkSize,
      publishedAt: published,
    );
  }

  /// Extracts numeric semantic version components from version strings such as "v1", "v1.0.1", "1.0.0+1".
  static List<int> extractVersionNumbers(String versionStr) {
    var clean = versionStr.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1).trim();
    }
    // Remove build metadata (e.g. +1)
    if (clean.contains('+')) {
      clean = clean.split('+').first.trim();
    }
    // Remove prerelease suffix (e.g. -beta.1)
    if (clean.contains('-')) {
      clean = clean.split('-').first.trim();
    }

    final parts = clean.split('.');
    final numbers = <int>[];
    for (final part in parts) {
      final match = RegExp(r'^\d+').firstMatch(part.trim());
      if (match != null) {
        numbers.add(int.tryParse(match.group(0)!) ?? 0);
      } else {
        numbers.add(0);
      }
    }

    // Pad to at least [major, minor, patch]
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return numbers;
  }

  /// Determines if [remoteTag] is newer than [currentVersion].
  /// E.g. current "1.0.0" vs remote "v1.0.1" -> true
  /// E.g. current "1.0.0" vs remote "v1" -> false
  /// E.g. current "v1" vs remote "v2" -> true
  static bool isUpdateAvailable(String currentVersion, String remoteTag) {
    if (remoteTag.trim().isEmpty) return false;

    final current = extractVersionNumbers(currentVersion);
    final remote = extractVersionNumbers(remoteTag);

    final maxLen = current.length > remote.length ? current.length : remote.length;
    for (int i = 0; i < maxLen; i++) {
      final c = i < current.length ? current[i] : 0;
      final r = i < remote.length ? remote[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Formats byte size into human-readable MB string.
  String? get formattedSize {
    if (apkSize == null || apkSize! <= 0) return null;
    final mb = apkSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppReleaseInfo &&
          runtimeType == other.runtimeType &&
          tagName == other.tagName &&
          apkDownloadUrl == other.apkDownloadUrl;

  @override
  int get hashCode => tagName.hashCode ^ apkDownloadUrl.hashCode;
}
