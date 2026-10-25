import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/anime_detail.dart';
import '../../domain/models/anime_summary.dart';
import '../../domain/models/anime_titles.dart';
import '../../domain/models/search_sort.dart';
import '../../domain/repositories/metadata_repository.dart';
import '../../data/repositories/metadata_repository_impl.dart';
import '../../../library/data/repositories/follow_repository.dart';
import '../../../player/data/repositories/playback_history_repository.dart';
import '../../../settings/data/repositories/app_settings_repository.dart';

export '../../../player/data/repositories/playback_history_repository.dart' show playbackHistoryRepositoryProvider;

/// Provider for MetadataRepository singleton
final metadataRepositoryProvider = Provider<MetadataRepository>((ref) {
  return MetadataRepositoryImpl();
});

/// Provider for FollowRepository singleton
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FollowRepository(prefs);
});

/// Stream of followed IDs
final followedAnimeIdsProvider = StreamProvider<Set<int>>((ref) {
  final repo = ref.watch(followRepositoryProvider);
  return repo.followStream;
});

/// Provider checking if specific anime is followed
final isFollowingProvider = FutureProvider.autoDispose.family<bool, int>((ref, animeId) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.isFollowing(animeId);
});

/// Provider for last watched episode of an anime
final lastWatchedEpisodeProvider = FutureProvider.autoDispose.family<int?, int>((ref, animeId) async {
  final repo = ref.watch(playbackHistoryRepositoryProvider);
  return repo.getLastWatchedEpisode(animeId);
});

/// Preference for displaying anime titles (English, Localized, or Original)
final titlePreferenceProvider = Provider<TitlePreference>((ref) {
  return ref.watch(appSettingsProvider).titlePreference;
});

/// Current raw search query string entered in the search bar
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected sort option
final searchSortProvider = StateProvider<SearchSort>((ref) => SearchSort.match);

/// Selected tags for filtering
class SelectedTagsNotifier extends StateNotifier<List<String>> {
  SelectedTagsNotifier() : super([]);

  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !state.contains(trimmed)) {
      state = [...state, trimmed];
    }
  }

  void removeTag(String tag) {
    state = state.where((t) => t != tag).toList();
  }

  void clear() {
    state = [];
  }
}

final selectedTagsProvider = StateNotifierProvider<SelectedTagsNotifier, List<String>>((ref) {
  return SelectedTagsNotifier();
});

/// Debounced search query provider (300ms debounce)
final debouncedSearchQueryProvider = StreamProvider.autoDispose<String>((ref) {
  final controller = StreamController<String>();
  Timer? timer;

  final sub = ref.listen<String>(searchQueryProvider, (previous, next) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 300), () {
      if (!controller.isClosed) {
        controller.add(next.trim());
      }
    });
  }, fireImmediately: true);

  ref.onDispose(() {
    timer?.cancel();
    sub.close();
    controller.close();
  });

  return controller.stream;
});

/// Search pagination state
class SearchPaginationState {
  final List<AnimeSummary> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final int offset;

  const SearchPaginationState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.offset = 0,
  });

  SearchPaginationState copyWith({
    List<AnimeSummary>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    int? offset,
  }) {
    return SearchPaginationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      offset: offset ?? this.offset,
    );
  }
}

/// Notifier managing search query, sort, tags, and infinite scroll pagination
class SearchPaginationNotifier extends StateNotifier<SearchPaginationState> {
  final MetadataRepository _repository;
  final Ref _ref;
  CancelToken? _cancelToken;
  static const int pageSize = 20;

  SearchPaginationNotifier(this._repository, this._ref)
      : super(const SearchPaginationState()) {
    _init();
  }

  void _init() {
    // Watch search query, sort, and tags changes
    _ref.listen<AsyncValue<String>>(debouncedSearchQueryProvider, (previous, next) {
      search();
    });
    _ref.listen<SearchSort>(searchSortProvider, (previous, next) {
      search();
    });
    _ref.listen<List<String>>(selectedTagsProvider, (previous, next) {
      search();
    });
    search();
  }

  Future<void> search([String? directQuery]) async {
    _cancelToken?.cancel('New search initiated');
    final thisToken = CancelToken();
    _cancelToken = thisToken;

    final debouncedQuery = directQuery ?? _ref.read(debouncedSearchQueryProvider).valueOrNull;
    final query = (debouncedQuery != null && debouncedQuery.isNotEmpty)
        ? debouncedQuery
        : _ref.read(searchQueryProvider).trim();
    final sort = _ref.read(searchSortProvider);
    final tags = _ref.read(selectedTagsProvider);

    if (query.isEmpty && tags.isEmpty) {
      state = const SearchPaginationState(items: [], isLoading: false, hasMore: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null, items: [], offset: 0, hasMore: true);

    try {
      final results = await _repository.searchAnime(
        query,
        sort: sort,
        tags: tags,
        limit: pageSize,
        offset: 0,
        cancelToken: thisToken,
      );

      // If a newer search took over or this token was cancelled, discard silently
      if (thisToken != _cancelToken || thisToken.isCancelled) return;

      state = state.copyWith(
        items: results,
        isLoading: false,
        offset: results.length,
        hasMore: results.length >= pageSize,
      );
    } catch (e) {
      if (thisToken != _cancelToken ||
          thisToken.isCancelled ||
          (e is DioException && (e.type == DioExceptionType.cancel || CancelToken.isCancel(e)))) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final debouncedQuery = _ref.read(debouncedSearchQueryProvider).valueOrNull;
    final query = (debouncedQuery != null && debouncedQuery.isNotEmpty)
        ? debouncedQuery
        : _ref.read(searchQueryProvider).trim();
    final sort = _ref.read(searchSortProvider);
    final tags = _ref.read(selectedTagsProvider);

    if (query.isEmpty && tags.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);
    final thisToken = _cancelToken;

    try {
      final nextResults = await _repository.searchAnime(
        query,
        sort: sort,
        tags: tags,
        limit: pageSize,
        offset: state.offset,
        cancelToken: thisToken,
      );

      if (thisToken != _cancelToken || (thisToken?.isCancelled ?? false)) return;

      state = state.copyWith(
        items: [...state.items, ...nextResults],
        isLoadingMore: false,
        offset: state.offset + nextResults.length,
        hasMore: nextResults.length >= pageSize,
      );
    } catch (e) {
      if ((thisToken?.isCancelled ?? false) ||
          (e is DioException && (e.type == DioExceptionType.cancel || CancelToken.isCancel(e)))) {
        return;
      }
      state = state.copyWith(isLoadingMore: false);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Notifier disposed');
    super.dispose();
  }
}

final searchPaginationProvider =
    StateNotifierProvider.autoDispose<SearchPaginationNotifier, SearchPaginationState>((ref) {
  final repo = ref.watch(metadataRepositoryProvider);
  return SearchPaginationNotifier(repo, ref);
});

/// Legacy provider alias for backward compatibility with existing tests
final searchResultsProvider = FutureProvider.autoDispose<List<AnimeSummary>>((ref) async {
  final pagination = ref.watch(searchPaginationProvider);
  return pagination.items;
});

/// Anime detail provider by ID with autoDispose and cancellation
final animeDetailProvider = FutureProvider.autoDispose.family<AnimeDetail, int>((ref, id) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    cancelToken.cancel('Detail screen closed');
  });

  return repo.getAnimeDetail(id, cancelToken: cancelToken);
});

/// K-Show / Asian Drama detail provider by ID with autoDispose and cancellation
final kshowDetailProvider = FutureProvider.autoDispose.family<AnimeDetail, int>((ref, id) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    cancelToken.cancel('KShow detail screen closed');
  });

  return repo.getKShowDetail(id, cancelToken: cancelToken);
});

