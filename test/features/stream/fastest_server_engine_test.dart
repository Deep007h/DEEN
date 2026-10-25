import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/models/stream_variant.dart';
import 'package:anime_stream/features/stream/domain/orchestration/fastest_server_engine.dart';

void main() {
  group('FastestServerEngine Tests', () {
    test('ranks servers by fastest response latency', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.path.contains('fast-server')) {
              await Future.delayed(const Duration(milliseconds: 20));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 206,
                  data: Stream.fromIterable([[1, 2, 3]]),
                ),
              );
            } else if (options.path.contains('slow-server')) {
              await Future.delayed(const Duration(milliseconds: 100));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 206,
                  data: Stream.fromIterable([[1, 2, 3]]),
                ),
              );
            } else if (options.path.contains('broken-server')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Connection refused',
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final engine = FastestServerEngine(client: dio);

      const slowVar = StreamVariant(
        url: 'https://slow-server.top/master.m3u8',
        audio: AudioLanguage.japaneseOriginal,
      );
      const fastVar = StreamVariant(
        url: 'https://fast-server.top/master.m3u8',
        audio: AudioLanguage.japaneseOriginal,
      );
      const brokenVar = StreamVariant(
        url: 'https://broken-server.top/master.m3u8',
        audio: AudioLanguage.japaneseOriginal,
      );

      final ranked = await engine.rankBySpeed([slowVar, brokenVar, fastVar]);
      expect(ranked, hasLength(3));
      // Fast server must be ranked 1st!
      expect(ranked[0].url, contains('fast-server'));
      // Slow server 2nd
      expect(ranked[1].url, contains('slow-server'));
      // Broken server last
      expect(ranked[2].url, contains('broken-server'));
    });

    test('probeAll returns detailed latency metrics for UI display', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: Stream.fromIterable([[1, 2, 3]]),
              ),
            );
          },
        ),
      );

      final engine = FastestServerEngine(client: dio);

      const variant = StreamVariant(
        url: 'https://hls.dramahot.top/stream/master.m3u8',
        audio: AudioLanguage.japaneseOriginal,
      );

      final results = await engine.probeAll([variant]);
      expect(results, hasLength(1));
      expect(results.first.isHealthy, isTrue);
      expect(results.first.serverName, 'Server 1');
      expect(results.first.badgeText, contains('ms'));
    });
  });
}
