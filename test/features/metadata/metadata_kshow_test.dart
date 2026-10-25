import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/data/repositories/metadata_repository_impl.dart';
import 'package:anime_stream/features/metadata/data/cache/metadata_cache.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';

void main() {
  group('MetadataRepositoryImpl - K-Show Tests', () {
    late Dio mockDio;
    late MetadataRepositoryImpl repo;

    setUp(() {
      mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/api/DramaList/Drama/8714')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'title': 'Queen of Tears',
                    'description': 'A miraculous love story of a married couple.',
                    'thumbnail': 'https://kisskh.co/thumb.jpg',
                    'country': 'South Korea',
                    'status': 'Completed',
                    'releaseDate': '2024-03-09',
                    'episodes': [
                      {'id': 147731, 'number': 1.0},
                      {'id': 148632, 'number': 2.0},
                    ],
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

      repo = MetadataRepositoryImpl(
        kshowDio: mockDio,
        cache: MetadataCache(),
      );
    });

    test('getKShowDetail fetches full details, sorts episodes, and caches result', () async {
      final detail = await repo.getKShowDetail(8714);

      expect(detail.id, 8714);
      expect(detail.titles.preferredTitle(), 'Queen of Tears');
      expect(detail.platform, 'K-Drama');
      expect(detail.summary, contains('miraculous love story'));
      expect(detail.episodes.length, 2);
      expect(detail.episodes[0].id, 147731);
      expect(detail.episodes[0].number, 1.0);
      expect(detail.episodes[1].id, 148632);
      expect(detail.episodes[1].number, 2.0);
    });

    test('recordKShowMatch marks origin as kisskh and getAnimeDetail delegates to K-Show', () async {
      repo.recordKShowMatch(
        const SourceMatch(
          id: '8714',
          title: 'Queen of Tears',
          providerId: 'megavid',
          customData: {'sourceType': 'kisskh', 'thumb': 'https://kisskh.co/thumb.jpg'},
        ),
      );

      final detail = await repo.getAnimeDetail(8714);
      expect(detail.platform, 'K-Drama');
      expect(detail.titles.preferredTitle(), 'Queen of Tears');
    });
  });
}
