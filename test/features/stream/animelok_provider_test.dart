import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/data/providers/animelok_provider.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/models/source_episode.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';

void main() {
  group('AnimelokProvider Tests', () {
    late Dio mockDio;
    late AnimelokProvider provider;

    const sampleMasterM3u8 = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Hindi",DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="hin",URI="https://as-cdn1.top/audio/hin.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Tamil",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE="tam",URI="https://as-cdn1.top/audio/tam.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Telugu",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE="tel",URI="https://as-cdn1.top/audio/tel.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE="eng",URI="https://as-cdn1.top/audio/eng.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Japanese",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE="jpn",URI="https://as-cdn1.top/audio/jpn.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=4500000,RESOLUTION=1920x1080,AUDIO="audio"
https://as-cdn1.top/video/1080p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720,AUDIO="audio"
https://as-cdn1.top/video/720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=854x480,AUDIO="audio"
https://as-cdn1.top/video/480p.m3u8
''';

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://animelok.cc'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final uri = options.uri.toString();

            // Direct check for AniList 176496
            if (uri.contains('/api/anilist/176496/1')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'servers': [
                      {
                        'id': 'ravok-1',
                        'name': 'Multi-1',
                        'url': 'https://ravok.buzz/video/test_hash_176496_ep1',
                      },
                      {
                        'id': 'stream-2',
                        'name': 'Server 2',
                        'url': 'https://other.buzz/video/test_hash_other',
                      }
                    ],
                  },
                ),
              );
            }

            // Direct check for AniList 999999 (404 / Not Found)
            if (uri.contains('/api/anilist/999999/1')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 404,
                  ),
                ),
              );
            }

            // Search query fallback
            if (uri.contains('/api/search')) {
              final q = options.queryParameters['q']?.toString() ?? '';
              if (q.toLowerCase().contains('solo leveling')) {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'success': true,
                      'results': [
                        {
                          'anilist_id': 151807,
                          'title': {
                            'english': 'Solo Leveling',
                            'romaji': 'Ore dake Level Up na Ken',
                          },
                          'episodes': 12,
                        }
                      ],
                    },
                  ),
                );
              }
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'results': []},
                ),
              );
            }

            // Ravok player endpoint
            if (uri.contains('ravok.buzz/player/index.php')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'videoSource': 'https://as-cdn1.top/hls/master.m3u8?md5=secret_token&expires=1890000000',
                  },
                ),
              );
            }

            // Master playlist fetch
            if (uri.contains('as-cdn1.top/hls/master.m3u8')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: sampleMasterM3u8,
                ),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Not found: $uri',
              ),
            );
          },
        ),
      );

      provider = AnimelokProvider(client: mockDio);
    });

    test('metadata and provider identity are correctly configured', () {
      expect(provider.id, 'animelok');
      expect(provider.displayName, 'Animelok (Multi-Audio HLS / Hindi)');
    });

    test('findTitle succeeds via direct AniList ID lookup', () async {
      const anime = AnimeDetail(
        id: 176496,
        titles: AnimeTitles(
          original: 'ダンダダン',
          english: 'Dandadan',
          localized: 'Dandadan',
        ),
        eps: 12,
      );

      final matches = await provider.findTitle(anime);
      expect(matches, isNotEmpty);
      expect(matches.first.id, '176496');
      expect(matches.first.providerId, 'animelok');
      expect(matches.first.confidenceScore, 1.0);
      expect(matches.first.customData['sourceType'], 'animelok_direct');
    });

    test('findTitle falls back to title search when direct lookup fails', () async {
      const anime = AnimeDetail(
        id: 999999,
        titles: AnimeTitles(
          original: '俺だけレベルアップな件',
          english: 'Solo Leveling',
          localized: 'Ore dake Level Up na Ken',
        ),
        eps: 12,
      );

      final matches = await provider.findTitle(anime);
      expect(matches, isNotEmpty);
      expect(matches.first.id, '151807');
      expect(matches.first.title, 'Solo Leveling');
      expect(matches.first.confidenceScore, greaterThanOrEqualTo(0.8));
    });

    test('episodes generates correct number of SourceEpisode instances', () async {
      const match = SourceMatch(
        id: '176496',
        title: 'Dandadan',
        providerId: 'animelok',
        episodeCount: 12,
      );

      final eps = await provider.episodes(match);
      expect(eps.length, 12);
      expect(eps.first.number, 1);
      expect(eps.first.id, '176496_1');
      expect(eps.last.number, 12);
      expect(eps.last.id, '176496_12');
    });

    test('resolve extracts ravok buzz stream and multi-audio variants', () async {
      const episode = SourceEpisode(
        id: '176496_1',
        number: 1,
        title: 'Episode 1',
        matchId: '176496',
        providerId: 'animelok',
        customData: {
          'anilistId': 176496,
          'epNum': 1,
        },
      );

      final variants = await provider.resolve(episode);
      expect(variants, isNotEmpty);

      // Check URL and headers
      final firstVariant = variants.first;
      expect(firstVariant.url, contains('master.m3u8'));
      expect(firstVariant.headers['Referer'], 'https://ravok.buzz/');

      // Audio tracks check across variants
      final languages = variants.map((v) => v.audio.code).toSet();
      expect(languages, contains(AudioLanguage.hindiDub.code));
      expect(languages, contains(AudioLanguage.englishDub.code));
      expect(languages, contains(AudioLanguage.japaneseOriginal.code));
      expect(languages, contains('ta')); // Tamil
      expect(languages, contains('te')); // Telugu

      // Qualities check
      expect(firstVariant.qualities, isNotEmpty);
      expect(firstVariant.qualities.any((q) => q.height == 1080), isTrue);
      expect(firstVariant.qualities.any((q) => q.height == 720), isTrue);
      expect(firstVariant.qualities.any((q) => q.height == 480), isTrue);
    });
  });
}
