import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';

class MockMetadataRepository extends MetadataRepository {
  List<String>? lastTags;
  int lastOffset = 0;

  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    lastTags = tags;
    lastOffset = offset;

    return List.generate(
      limit,
      (i) => AnimeSummary(
        id: offset + i + 1,
        titles: AnimeTitles(original: 'Anime ${offset + i + 1}'),
        score: 8.0,
      ),
    );
  }

  @override
  Future<AnimeDetail> getAnimeDetail(int id, {CancelToken? cancelToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(int animeId, {CancelToken? cancelToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Season>> getSeasons(int animeId, {CancelToken? cancelToken}) async {
    throw UnimplementedError();
  }
}

void main() {
  test('Search pagination loads initial page and appends next page', () async {
    final mockRepo = MockMetadataRepository();
    final container = ProviderContainer(
      overrides: [
        metadataRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Initial search
    container.read(searchQueryProvider.notifier).state = 'action';
    await Future.delayed(const Duration(milliseconds: 450));

    final notifier = container.read(searchPaginationProvider.notifier);
    await notifier.search();

    var state = container.read(searchPaginationProvider);
    expect(state.items.length, equals(20));
    expect(state.offset, equals(20));
    expect(state.hasMore, isTrue);

    // Load next page
    await notifier.loadMore();

    state = container.read(searchPaginationProvider);
    expect(state.items.length, equals(40));
    expect(state.offset, equals(40));
    expect(mockRepo.lastOffset, equals(20));

    container.dispose();
  });

  test('Selected tags are passed to search query', () async {
    final mockRepo = MockMetadataRepository();
    final container = ProviderContainer(
      overrides: [
        metadataRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Set base search query
    container.read(searchQueryProvider.notifier).state = 'anime';

    // Add tag
    container.read(selectedTagsProvider.notifier).addTag('Fantasy');
    final notifier = container.read(searchPaginationProvider.notifier);
    await notifier.search();

    expect(mockRepo.lastTags, contains('Fantasy'));

    // Remove tag
    container.read(selectedTagsProvider.notifier).removeTag('Fantasy');
    await notifier.search();

    expect(mockRepo.lastTags, isEmpty);

    container.dispose();
  });
}
