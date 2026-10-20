import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/resolvers/embed_stream_resolver.dart';

void main() {
  group('EmbedStreamResolver URL Helpers', () {
    test('buildEmbedUrl constructs canonical URL', () {
      final url = EmbedStreamResolver.buildEmbedUrl(
        animeId: '178789',
        episodeNumber: 11,
        audio: 'dub',
      );
      expect(url, 'https://megavid.buzz/ani/178789/11/dub');

      final subUrl = EmbedStreamResolver.buildEmbedUrl(
        animeId: '108465',
        episodeNumber: 1,
        audio: 'sub',
      );
      expect(subUrl, 'https://megavid.buzz/ani/108465/1/sub');
    });

    test('buildKisskhUrl constructs KissKH embed URL', () {
      final url = EmbedStreamResolver.buildKisskhUrl('12345');
      expect(url, 'https://megavid.buzz/kisskh/12345');
    });

    test('parseEmbedUrl extracts components correctly', () {
      final ani = EmbedStreamResolver.parseEmbedUrl('https://megavid.buzz/ani/178789/11/dub');
      expect(ani.isAnime, isTrue);
      expect(ani.animeId, '178789');
      expect(ani.episodeNumber, 11);
      expect(ani.audio, 'dub');
      expect(ani.isKisskh, isFalse);

      final kisskh = EmbedStreamResolver.parseEmbedUrl('https://megavid.buzz/kisskh/ep_999');
      expect(kisskh.isKisskh, isTrue);
      expect(kisskh.kisskhEpId, 'ep_999');
      expect(kisskh.isAnime, isFalse);
    });
  });

  group('EmbedStreamResolver Payload Parsing', () {
    final resolver = EmbedStreamResolver();

    test('parseSourcePayload extracts HLS, subtitles, chapters, and providers', () {
      final samplePayload = {
        'status': 'ok',
        'source': 'https://cdnx.aniwatchtv.site/uwu/ABC123XYZ',
        'tracks': [
          {
            'file': 'https://cdn.subtitles.com/eng.vtt',
            'label': 'English',
            'kind': 'captions',
            'default': true,
          },
          {
            'file': 'https://cdn.subtitles.com/spa.vtt',
            'label': 'Spanish',
            'kind': 'captions',
          },
          {
            'file': 'https://cdn.subtitles.com/ger.vtt',
            'label': 'German',
            'kind': 'captions',
          },
        ],
        'chapters': [
          {'title': 'Intro', 'start': 85.0, 'end': 175.0},
          {'title': 'Outro', 'start': 1320.0, 'end': 1410.0},
        ],
        'providers': [
          {'id': 'yuki', 'tip': 'Soft sub'},
          {'id': 'loli', 'tip': 'HLS streams'},
        ],
        'provider': 'yuki',
        'animex': true,
      };

      final result = resolver.parseSourcePayload(
        samplePayload,
        embedUrl: 'https://megavid.buzz/ani/178789/11/dub',
      );

      expect(result, isNotNull);
      expect(result!.streamUrl, 'https://cdnx.aniwatchtv.site/uwu/ABC123XYZ#.m3u8');
      expect(result.variant.url, contains('#.m3u8'));
      expect(result.variant.audio, AudioLanguage.englishDub);
      expect(result.variant.hasIntro, isTrue);
      expect(result.variant.introStart, 85.0);
      expect(result.variant.introEnd, 175.0);
      expect(result.variant.hasOutro, isTrue);
      expect(result.variant.outroStart, 1320.0);
      expect(result.variant.outroEnd, 1410.0);

      // Subtitles: 1 'Off' + 3 parsed = 4
      expect(result.subtitles.length, 4);
      expect(result.subtitles[0].isOff, isTrue);
      expect(result.subtitles[1].label, 'English');
      expect(result.subtitles[1].languageCode, 'en');
      expect(result.subtitles[2].label, 'Spanish');
      expect(result.subtitles[2].languageCode, 'es');
      expect(result.subtitles[3].label, 'German');
      expect(result.subtitles[3].languageCode, 'de');

      // Providers & Engine
      expect(result.providers.length, 2);
      expect(result.activeProvider, 'yuki');
      expect(result.isAnimeX, isTrue);
    });

    test('parseSourcePayload rejects banned /vid/ URLs', () {
      final brokenPayload = {
        'status': 'ok',
        'source': 'https://megavid.buzz/vid/broken/seg.m3u8',
      };

      final result = resolver.parseSourcePayload(
        brokenPayload,
        embedUrl: 'https://megavid.buzz/ani/178789/11/dub',
      );

      expect(result, isNull);
    });
  });

  group('EmbedStreamResolver Network Resolution', () {
    test('resolveEmbedUrl requests /source with embed URL as Referer', () async {
      String? capturedReferer;
      String? capturedUserAgent;
      String? capturedPath;

      final mockDio = Dio(BaseOptions(baseUrl: 'https://megavid.buzz'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPath = options.path;
            capturedReferer = options.headers['Referer']?.toString();
            capturedUserAgent = options.headers['User-Agent']?.toString();

            if (options.path == '/ani/178789/11/dub/source') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'ok',
                    'source': 'https://cdnx.aniwatchtv.site/uwu/stream123',
                    'tracks': [],
                    'chapters': [],
                  },
                ),
              );
            }
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
              ),
            );
          },
        ),
      );

      final resolver = EmbedStreamResolver(client: mockDio);
      final res = await resolver.resolveEmbedUrl('https://megavid.buzz/ani/178789/11/dub');

      expect(res, isNotNull);
      expect(capturedPath, '/ani/178789/11/dub/source');
      expect(capturedReferer, 'https://megavid.buzz/ani/178789/11/dub');
      expect(capturedUserAgent, contains('Mozilla/5.0'));
      expect(res!.streamUrl, 'https://cdnx.aniwatchtv.site/uwu/stream123#.m3u8');
    });
  });
}
