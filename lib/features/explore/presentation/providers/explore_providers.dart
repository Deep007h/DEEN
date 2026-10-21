import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../../../metadata/domain/models/anime_summary.dart';
import '../../../metadata/domain/repositories/metadata_repository.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';

/// Available layout listing modes for the Explore catalog.
enum ExploreViewMode {
  grid,
  compact,
  wide,
}

/// Active genre selected on Explore page (defaults to Action).
final selectedExploreGenreProvider = StateProvider<String>((ref) => 'Action');

/// Current layout display mode for Explore catalog.
final exploreViewModeProvider = StateProvider<ExploreViewMode>((ref) => ExploreViewMode.grid);

/// Top hero anime for the active genre with banner art and synopsis.
final genreHeroProvider = FutureProvider.autoDispose.family<FeaturedAnimeItem?, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getFeaturedAnimeByGenre(genre);
});

/// Trending titles in the selected genre (TRENDING_DESC).
final genreTrendingProvider = FutureProvider.autoDispose.family<List<AnimeSummary>, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getAnimeByGenreCatalog(
    genre: genre,
    sort: const ['TRENDING_DESC'],
    limit: 12,
  );
});

/// All-time masterpieces in the selected genre (SCORE_DESC).
final genreTopRatedProvider = FutureProvider.autoDispose.family<List<AnimeSummary>, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getAnimeByGenreCatalog(
    genre: genre,
    sort: const ['SCORE_DESC'],
    limit: 12,
  );
});

/// Popular community hits in the selected genre (POPULARITY_DESC).
final genrePopularProvider = FutureProvider.autoDispose.family<List<AnimeSummary>, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getAnimeByGenreCatalog(
    genre: genre,
    sort: const ['POPULARITY_DESC'],
    limit: 12,
  );
});

/// State of endless scrolling catalog for a genre.
class GenreCatalogState {
  final List<AnimeSummary> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final Object? error;

  const GenreCatalogState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  GenreCatalogState copyWith({
    List<AnimeSummary>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    Object? error,
  }) {
    return GenreCatalogState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error ?? this.error,
    );
  }
}

/// Notifier powering infinite scroll pagination for genre catalogs.
class GenreCatalogNotifier extends StateNotifier<GenreCatalogState> {
  final MetadataRepository _repo;
  final String genre;
  CancelToken? _cancelToken;

  GenreCatalogNotifier(this._repo, this.genre) : super(const GenreCatalogState()) {
    init();
  }

  Future<void> init() async {
    _cancelToken?.cancel('New catalog request');
    final token = CancelToken();
    _cancelToken = token;

    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final results = await _repo.getAnimeByGenreCatalog(
        genre: genre,
        sort: const ['POPULARITY_DESC'],
        page: 1,
        limit: 20,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      state = state.copyWith(
        items: results,
        isLoading: false,
        page: 1,
        hasMore: results.length >= 15,
      );
    } catch (e) {
      if (token.isCancelled) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    try {
      final more = await _repo.getAnimeByGenreCatalog(
        genre: genre,
        sort: const ['POPULARITY_DESC'],
        page: nextPage,
        limit: 20,
      );
      final existingIds = state.items.map((e) => e.id).toSet();
      final newUnique = more.where((e) => !existingIds.contains(e.id)).toList();
      state = state.copyWith(
        items: [...state.items, ...newUnique],
        isLoadingMore: false,
        page: nextPage,
        hasMore: more.length >= 15,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

/// Family provider yielding an infinite catalog manager per genre.
final genreCatalogProvider =
    StateNotifierProvider.family<GenreCatalogNotifier, GenreCatalogState, String>((ref, genre) {
  final repo = ref.watch(metadataRepositoryProvider);
  return GenreCatalogNotifier(repo, genre);
});
