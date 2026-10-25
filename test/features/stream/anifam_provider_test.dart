import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/data/providers/anifam_provider.dart';
import 'package:anime_stream/features/stream/domain/models/source_episode.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';

void main() {
  group('AniFamProvider Tests', () {
    late Dio dio;
    late AniFamProvider provider;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final path = options.path;
            if (path.contains('/api/v1/app/search')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [
                      {
                        'id': 2869,
                        'slug': 'sousou-no-frieren',
                        'title': "Frieren: Beyond Journey's End",
                        'score': 8.9,
                        'sub': 28,
                        'dub': 28,
                      }
                    ]
                  },
                ),
              );
            } else if (path.contains('/api/v1/app/anime/2869/episodes')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [
                      {
                        'id': 36785,
                        'number': 1,
                        'title': "The End of the Journey",
                        'has_sub': true,
                        'has_dub': true,
                      }
                    ]
                  },
                ),
              );
            } else if (path.contains('/api/v1/app/episodes/36785/play')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'sources': [
                      {
                        'kind': 'hls',
                        'server': 'AniFam',
                        'url': 'https://hls.dramahot.top/stream/master.m3u8',
                        'media_headers': {
                          'Referer': 'https://zokoanime.video/',
                        },
                        'qualities': [
                          {'height': 1080, 'bandwidth': 4500000},
                          {'height': 720, 'bandwidth': 2500000},
                        ],
                        'subtitles': [
                          {
                            'lang': 'en',
                            'label': 'English',
                            'url': 'https://hls.dramahot.top/subs/en.vtt',
                            'default': true,
                          }
                        ],
                        'skip': {
                          'intro': [85, 175],
                          'outro': [1350, 1440],
                        }
                      },
                      {
                        'kind': 'iframe',
                        'server': 'HD-1',
                        'server_id': 2,
                        'resolvable': true,
                      }
                    ]
                  },
                ),
              );
            } else if (path.contains('/api/v1/app/episodes/36785/resolve')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'url': 'https://megap.shiora.top/upstream/master.m3u8',
                    'media_headers': {
                      'Referer': 'https://megaplay.buzz/',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      provider = AniFamProvider(
        client: dio,
        mirrors: ['https://anifam.net', 'https://anifam.buzz'],
      );
    });

    test('findTitle returns matched candidates with high confidence', () async {
      const anime = AnimeDetail(
        id: 400602,
        titles: AnimeTitles(
          original: '葬送のフリーレン',
          english: "Frieren: Beyond Journey's End",
        ),
        eps: 28,
      );

      final matches = await provider.findTitle(anime);
      expect(matches, isNotEmpty);
      expect(matches.first.id, '2869');
      expect(matches.first.title, "Frieren: Beyond Journey's End");
      expect(matches.first.confidenceScore, greaterThan(0.8));
    });

    test('episodes returns parsed episode list with sub/dub indicators', () async {
      const match = SourceMatch(
        id: '2869',
        title: "Frieren: Beyond Journey's End",
        providerId: 'anifam',
        episodeCount: 28,
        confidenceScore: 0.95,
      );

      final eps = await provider.episodes(match);
      expect(eps, hasLength(1));
      expect(eps.first.id, '36785');
      expect(eps.first.number, 1);
      expect(eps.first.customData['has_sub'], isTrue);
      expect(eps.first.customData['has_dub'], isTrue);
    });

    test('resolve parses direct HLS and resolves upstream servers', () async {
      const episode = SourceEpisode(
        id: '36785',
        number: 1,
        title: 'The End of the Journey',
        matchId: '2869',
        providerId: 'anifam',
        customData: {'preferredAudio': 'ja'},
      );

      final variants = await provider.resolve(episode);
      expect(variants.length, greaterThanOrEqualTo(2));

      // Direct HLS source
      final direct = variants.first;
      expect(direct.url, 'https://hls.dramahot.top/stream/master.m3u8');
      expect(direct.headers['Referer'], 'https://zokoanime.video/');
      expect(direct.qualities, hasLength(2));
      expect(direct.subtitles, hasLength(1));
      expect(direct.hasIntro, isTrue);
      expect(direct.introStart, 85.0);

      // Resolved upstream server HD-1
      final upstream = variants[1];
      expect(upstream.url, 'https://megap.shiora.top/upstream/master.m3u8');
      expect(upstream.headers['Referer'], 'https://megaplay.buzz/');
    });
  });
}
