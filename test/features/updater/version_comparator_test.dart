import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/updater/domain/models/app_release_info.dart';

void main() {
  group('AppReleaseInfo Version Parsing & Comparison Tests', () {
    test('extractVersionNumbers handles various formats', () {
      expect(AppReleaseInfo.extractVersionNumbers('1.0.0'), equals([1, 0, 0]));
      expect(AppReleaseInfo.extractVersionNumbers('v1.0.0'), equals([1, 0, 0]));
      expect(AppReleaseInfo.extractVersionNumbers('v1'), equals([1, 0, 0]));
      expect(AppReleaseInfo.extractVersionNumbers('1.0.0+1'), equals([1, 0, 0]));
      expect(AppReleaseInfo.extractVersionNumbers('v1.2.3-beta.1'), equals([1, 2, 3]));
      expect(AppReleaseInfo.extractVersionNumbers('v2.1'), equals([2, 1, 0]));
      expect(AppReleaseInfo.extractVersionNumbers('10.2.30'), equals([10, 2, 30]));
    });

    test('isUpdateAvailable correctly detects newer versions', () {
      // Current is 1.0.0 (v1)
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v1.0.0'), isFalse);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', '1.0.0'), isFalse);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v1'), isFalse);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v1.0.1'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v1.1.0'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v2.0.0'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v2'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', 'v0.9.9'), isFalse);

      // Current is v1 or 1.0.0+1
      expect(AppReleaseInfo.isUpdateAvailable('v1', 'v1.0.1'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0+1', 'v1.0.1'), isTrue);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0+1', 'v1.0.0'), isFalse);

      // Empty or invalid tags
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', ''), isFalse);
      expect(AppReleaseInfo.isUpdateAvailable('1.0.0', '   '), isFalse);
    });

    test('fromJson correctly parses release assets and metadata', () {
      final json = {
        'tag_name': 'v1.0.1',
        'name': 'DEEN v1.0.1 Release',
        'body': '- Added OTA auto-updater\n- Performance improvements',
        'html_url': 'https://github.com/Deep007h/DEEN/releases/tag/v1.0.1',
        'published_at': '2026-10-21T10:00:00Z',
        'assets': [
          {
            'name': 'app-armeabi-v7a-release.apk',
            'browser_download_url': 'https://github.com/download/app-v7a.apk',
            'size': 30000000,
          },
          {
            'name': 'app-arm64-v8a-release.apk',
            'browser_download_url': 'https://github.com/download/app-arm64-v8a-release.apk',
            'size': 35651584, // ~34 MB
          },
        ],
      };

      final release = AppReleaseInfo.fromJson(json);
      expect(release.tagName, equals('v1.0.1'));
      expect(release.title, equals('DEEN v1.0.1 Release'));
      expect(release.releaseNotes, contains('OTA auto-updater'));
      expect(release.apkDownloadUrl, equals('https://github.com/download/app-arm64-v8a-release.apk'));
      expect(release.formattedSize, equals('34.0 MB'));
    });

    test('fromJson falls back gracefully when assets are empty', () {
      final json = {
        'tag_name': 'v1.0.2',
        'name': '',
        'body': '',
        'html_url': 'https://github.com/Deep007h/DEEN/releases/tag/v1.0.2',
        'assets': [],
      };

      final release = AppReleaseInfo.fromJson(json);
      expect(release.tagName, equals('v1.0.2'));
      expect(release.title, equals('DEEN v1.0.2'));
      expect(release.apkDownloadUrl, equals('https://github.com/Deep007h/DEEN/releases/tag/v1.0.2'));
      expect(release.formattedSize, isNull);
    });
  });
}
