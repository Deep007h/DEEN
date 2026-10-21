import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/updater/data/repositories/github_updater_repository.dart';

class MockAdapter implements HttpClientAdapter {
  final int statusCode;
  final dynamic responseBody;
  final bool throwDioException;

  MockAdapter({
    this.statusCode = 200,
    this.responseBody,
    this.throwDioException = false,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwDioException) {
      throw DioException(
        requestOptions: options,
        error: 'Network connection failed',
        type: DioExceptionType.connectionError,
      );
    }

    final data = jsonEncode(responseBody ?? []);
    return ResponseBody.fromString(
      data,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('GithubUpdaterRepository Tests', () {
    test('returns null when GitHub releases list is empty [] (no releases in repo)', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(statusCode: 200, responseBody: []);
      final repo = GithubUpdaterRepository(dio: dio);

      final latest = await repo.getLatestRelease();
      expect(latest, isNull);

      final update = await repo.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('returns null when GitHub API returns 404', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(statusCode: 404, responseBody: {'message': 'Not Found'});
      final repo = GithubUpdaterRepository(dio: dio);

      final latest = await repo.getLatestRelease();
      expect(latest, isNull);
    });

    test('returns null gracefully on network failure without throwing', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(throwDioException: true);
      final repo = GithubUpdaterRepository(dio: dio);

      final latest = await repo.getLatestRelease();
      expect(latest, isNull);
    });

    test('returns release info and detects update when newer release exists', () async {
      final mockReleases = [
        {
          'tag_name': 'v1.1.0',
          'name': 'DEEN v1.1.0 - Performance & UI Boost',
          'body': 'Exciting new features and bug fixes',
          'html_url': 'https://github.com/Deep007h/DEEN/releases/tag/v1.1.0',
          'draft': false,
          'prerelease': false,
          'assets': [
            {
              'name': 'app-arm64-v8a-release.apk',
              'browser_download_url': 'https://github.com/Deep007h/DEEN/releases/download/v1.1.0/app-arm64-v8a-release.apk',
              'size': 35000000,
            }
          ]
        }
      ];

      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(statusCode: 200, responseBody: mockReleases);
      final repo = GithubUpdaterRepository(dio: dio);

      final latest = await repo.getLatestRelease();
      expect(latest, isNotNull);
      expect(latest!.tagName, equals('v1.1.0'));

      // Check against current v1 (1.0.0) -> Update is available!
      final update = await repo.checkForUpdate('1.0.0');
      expect(update, isNotNull);
      expect(update!.tagName, equals('v1.1.0'));
      expect(update.apkDownloadUrl, contains('app-arm64-v8a-release.apk'));

      // Check against current 1.1.0 -> No update needed!
      final noUpdate = await repo.checkForUpdate('1.1.0');
      expect(noUpdate, isNull);
    });
  });
}
