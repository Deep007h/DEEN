import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/data/providers/megavid_provider.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/models/source_episode.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';
import 'package:anime_stream/features/stream/domain/models/subtitle_track.dart';

void main() {
  group('MegaVidProvider Tests', () {
    late Dio mockDio;
    late MegaVidProvider provider;

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://megavid.buzz'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final path = options.path;
            final query = options.queryParameters;

            // 1. /api/find
            if (path == '/api/find') {
              final kind = query['kind'];
              if (kind == 'anime') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'results': [
                        {
                          'id': '154587',
                          'title': 'Frieren: Beyond Journey\'s End',
                          'year': 2023,
                          'episodes': 28,
                          'sub': 28,
                          'thumb': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx154587.jpg',
                          'format': 'TV',
                        },
                        {
                          'id': '999999',
                          'title': 'Sousou no Frieren Mini Anime',
                          'year': 2023,
                          'episodes': 12,
                          'sub': 12,
                          'thumb': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/mini.jpg',
                          'format': 'ONA',
                        },
                      ],
                    },
                  ),
                );
              } else if (kind == 'kshow') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'results': [
                        {
                          'id': '12345',
                          'title': 'Crash Landing on You',
                          'episodes': 16,
                          'thumb': 'https://kisskh.co/thumb/cloy.jpg',
                        },
                      ],
                    },
                  ),
                );
              }
            }

            // 2. /api/kshow-eps
            if (path == '/api/kshow-eps') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'episodes': [
                      {'id': 'ep_101', 'number': 1},
                      {'id': 'ep_102', 'number': 2},
                      {'id': 'ep_103', 'number': 3},
                    ],
                  },
                ),
              );
            }

            // 3. /api/ani/:id/:ep/:lang
            if (path.startsWith('/api/ani/')) {
              final parts = path.split('/');
              final lang = parts.length > 5 ? parts[5] : 'sub';

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'source': 'https://stream.megavid.buzz/hls/154587/ep1/$lang/master.m3u8',
                    'tracks': [
                      {
                        'file': 'https://stream.megavid.buzz/sub/en.vtt',
                        'label': 'English',
                        'kind': 'captions',
                        'default': true,
                      },
                      {
                        'file': 'https://stream.megavid.buzz/sub/es.vtt',
                        'label': 'Spanish',
                        'kind': 'captions',
                      },
                    ],
                    'intro': {'start': 90, 'end': 180},
                    'outro': {'start': 1350, 'end': 1440},
                  },
                ),
              );
            }

            // 3b. /ani/:id/:ep/:lang/source
            if (path.startsWith('/ani/') && path.endsWith('/source')) {
              final parts = path.split('/');
              final lang = parts.length > 4 ? parts[4] : 'sub';

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'ok',
                    'source': 'https://stream.megavid.buzz/hls/154587/ep1/$lang/master.m3u8',
                    'tracks': [
                      {
                        'file': 'https://stream.megavid.buzz/sub/en.vtt',
                        'label': 'English',
                        'kind': 'captions',
                        'default': true,
                      },
                      {
                        'file': 'https://stream.megavid.buzz/sub/es.vtt',
                        'label': 'Spanish',
                        'kind': 'captions',
                      },
                    ],
                    'chapters': [
                      {'title': 'Intro', 'start': 90, 'end': 180},
                      {'title': 'Outro', 'start': 1350, 'end': 1440},
                    ],
                  },
                ),
              );
            }

            // 4. /kisskh/:id/source
            if (path.startsWith('/kisskh/') && path.endsWith('/source')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'Video': 'https://kisskh.stream/kshow/ep_101/playlist.m3u8',
                    'tracks': [
                      {
                        'src': 'https://kisskh.stream/sub/en.vtt',
                        'label': 'English',
                        'default': true,
                      },
                    ],
                  },
                ),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Not found: ${options.path}',
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      provider = MegaVidProvider(client: mockDio);
    });

    test('findTitle returns ranked AniList candidates from MegaVid', () async {
      const anime = AnimeDetail(
        id: 400602,
        titles: AnimeTitles(
          original: '葬送のフリーレン',
          english: 'Frieren: Beyond Journey\'s End',
        ),
        airDate: '2023-09-29',
        eps: 28,
      );

      final matches = await provider.findTitle(anime);

      expect(matches, isNotEmpty);
      final best = matches.first;
      expect(best.id, '154587');
      expect(best.title, 'Frieren: Beyond Journey\'s End');
      expect(best.providerId, 'megavid');
      expect(best.year, 2023);
      expect(best.episodeCount, 28);
      expect(best.confidenceScore, greaterThan(0.8));
      expect(best.customData['sourceType'], 'ani');
      expect(best.customData['format'], 'TV');
    });

    test('searchKShows returns KissKH drama candidates', () async {
      final results = await provider.searchKShows('Crash Landing on You');

      expect(results.length, 1);
      final drama = results.first;
      expect(drama.id, '12345');
      expect(drama.title, 'Crash Landing on You');
      expect(drama.episodeCount, 16);
      expect(drama.customData['sourceType'], 'kisskh');
      expect(drama.customData['thumb'], 'https://kisskh.co/thumb/cloy.jpg');
    });

    test('episodes generates episodes for Anime match', () async {
      const match = SourceMatch(
        id: '154587',
        title: 'Frieren',
        providerId: 'megavid',
        episodeCount: 28,
        confidenceScore: 0.95,
        customData: {'sourceType': 'ani'},
      );

      final eps = await provider.episodes(match);

      expect(eps.length, 28);
      expect(eps.first.number, 1);
      expect(eps.first.matchId, '154587');
      expect(eps.last.number, 28);
    });

    test('episodes queries KissKH API for K-Show match', () async {
      const match = SourceMatch(
        id: '12345',
        title: 'Crash Landing on You',
        providerId: 'megavid',
        episodeCount: 16,
        confidenceScore: 0.9,
        customData: {'sourceType': 'kisskh'},
      );

      final eps = await provider.episodes(match);

      expect(eps.length, 3);
      expect(eps[0].id, 'ep_101');
      expect(eps[0].number, 1);
      expect(eps[0].customData['kisskhEpId'], 'ep_101');
      expect(eps[2].id, 'ep_103');
      expect(eps[2].number, 3);
    });

    test('resolve parses Sub & Dub variants with timestamps and subtitles for Anime', () async {
      const episode = SourceEpisode(
        id: '154587_1',
        number: 1,
        title: 'Episode 1',
        matchId: '154587',
        providerId: 'megavid',
        customData: {'sourceType': 'ani'},
      );

      final variants = await provider.resolve(episode);

      expect(variants.length, 2);

      // Sub variant
      final sub = variants.firstWhere((v) => v.audio == AudioLanguage.japaneseOriginal);
      expect(sub.url, contains('/sub/master.m3u8'));
      expect(sub.headers['Referer'], 'https://megavid.buzz/');
      expect(sub.isHls, isTrue);
      expect(sub.hasIntro, isTrue);
      expect(sub.introStart, 90.0);
      expect(sub.introEnd, 180.0);
      expect(sub.hasOutro, isTrue);
      expect(sub.outroStart, 1350.0);
      expect(sub.outroEnd, 1440.0);
      expect(sub.subtitles.length, 3); // Off + English + Spanish
      expect(sub.subtitles.any((s) => s.isOff), isTrue);
      expect(sub.subtitles.any((s) => s.label == 'English' && s.format == SubtitleFormat.vtt), isTrue);

      // Dub variant
      final dub = variants.firstWhere((v) => v.audio == AudioLanguage.englishDub);
      expect(dub.url, contains('/dub/master.m3u8'));
      expect(dub.headers['Referer'], 'https://megavid.buzz/');
    });

    test('resolve parses KissKH stream for K-Show episode', () async {
      const episode = SourceEpisode(
        id: 'ep_101',
        number: 1,
        title: 'Episode 1',
        matchId: '12345',
        providerId: 'megavid',
        customData: {'kisskhEpId': 'ep_101'},
      );

      final variants = await provider.resolve(episode);

      expect(variants.length, 1);
      final drama = variants.first;
      expect(drama.url, 'https://kisskh.stream/kshow/ep_101/playlist.m3u8');
      expect(drama.audio, AudioLanguage.koreanOriginal);
      expect(drama.headers['Referer'], contains('https://megavid.buzz'));
      expect(drama.subtitles.any((s) => s.label == 'English'), isTrue);
    });

    test('resolve rejects invalid /vid/ endpoints and prefers direct CDN sources', () async {
      final directMockDio = Dio(BaseOptions(baseUrl: 'https://megavid.buzz'));
      directMockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.startsWith('/ani/') && options.path.endsWith('/source')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'ok',
                    'source': 'https://cp.megavid.buzz/hls/test-uuid/playlist.m3u8',
                    'tracks': [],
                  },
                ),
              );
            }
            if (options.path.startsWith('/api/ani/')) {
              // Legacy endpoint returning bad /vid/ URL
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'source': 'https://megavid.buzz/vid/bad-token/invalid',
                  },
                ),
              );
            }
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Not found',
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final directProvider = MegaVidProvider(client: directMockDio);
      const episode = SourceEpisode(
        id: '154587_1',
        number: 1,
        title: 'Episode 1',
        matchId: '154587',
        providerId: 'megavid',
        customData: {'sourceType': 'ani'},
      );

      final variants = await directProvider.resolve(episode);
      expect(variants, isNotEmpty);
      expect(variants.first.url, 'https://cp.megavid.buzz/hls/test-uuid/playlist.m3u8');
      expect(variants.any((v) => v.url.contains('/vid/')), isFalse);
    });

    test('resolve extracts stream via embed page HTML when direct API is unreachable', () async {
      final embedMockDio = Dio(BaseOptions(baseUrl: 'https://megavid.buzz'));
      embedMockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Direct /source endpoint fails
            if (options.path.startsWith('/ani/') && options.path.endsWith('/source')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Blocked or not found',
                  type: DioExceptionType.badResponse,
                ),
              );
            }
            if (options.path.startsWith('/api/ani/')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Legacy route down',
                  type: DioExceptionType.badResponse,
                ),
              );
            }
            // Embed page HTML returns player-payload
            if (options.path.startsWith('/ani/') && !options.path.endsWith('/source')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: '''
                    <!DOCTYPE html>
                    <html>
                    <body>
                      <script id="player-payload" type="application/json">{"sourceUrl":"/custom/embed/source","color":"#2563eb"}</script>
                    </body>
                    </html>
                  ''',
                ),
              );
            }
            // Custom payload source URL resolves to stream
            if (options.path == '/custom/embed/source') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'ok',
                    'source': 'https://cdnx.aniwatchtv.site/uwu/master.m3u8',
                    'tracks': [
                      {
                        'file': 'https://sub.domain/track.vtt',
                        'label': 'English',
                        'kind': 'captions',
                      }
                    ],
                  },
                ),
              );
            }
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Not found',
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final embedProvider = MegaVidProvider(client: embedMockDio);
      const episode = SourceEpisode(
        id: '154587_1',
        number: 1,
        title: 'Episode 1',
        matchId: '154587',
        providerId: 'megavid',
        customData: {'sourceType': 'ani'},
      );

      final variants = await embedProvider.resolve(episode);
      expect(variants, isNotEmpty);
      expect(variants.first.url, 'https://cdnx.aniwatchtv.site/uwu/master.m3u8');
      expect(variants.first.subtitles.any((s) => s.label == 'English'), isTrue);
    });
  });
}
