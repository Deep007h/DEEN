import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../../../metadata/domain/models/anime_summary.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';

/// Dynamic refresh seed that increments when pull-to-refresh is triggered,
/// causing providers to paginate/rotate through new sets of animes and shows.
final homeRefreshSeedProvider = StateProvider<int>((ref) => 0);

/// Featured anime banner list provider for the Home hero carousel.
final featuredAnimeProvider = FutureProvider<List<FeaturedAnimeItem>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final seed = ref.watch(homeRefreshSeedProvider);
  final page = (seed % 5) + 1;
  return repo.getFeaturedAnime(page: page, limit: 6, forceRefresh: seed > 0);
});

/// Trending anime list provider.
final trendingAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final seed = ref.watch(homeRefreshSeedProvider);
  final page = (seed % 10) + 1;
  return repo.getTrendingAnime(page: page, limit: 10, forceRefresh: seed > 0);
});

/// Top rated anime list provider.
final topRatedAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final seed = ref.watch(homeRefreshSeedProvider);
  final page = (seed % 10) + 1;
  return repo.getTopRatedAnime(page: page, limit: 10, forceRefresh: seed > 0);
});

/// Recently added / airing anime list provider.
final recentlyAddedAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final seed = ref.watch(homeRefreshSeedProvider);
  final page = (seed % 10) + 1;
  return repo.getRecentlyUpdatedAnime(page: page, limit: 10, forceRefresh: seed > 0);
});

/// Anime list filtered by genre / category.
final categoryAnimeProvider = FutureProvider.autoDispose.family<List<AnimeSummary>, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  final seed = ref.watch(homeRefreshSeedProvider);
  final page = (seed % 10) + 1;
  return repo.getAnimeByGenre(genre, page: page, limit: 10, forceRefresh: seed > 0);
});

/// Alias for [categoryAnimeProvider] used by Explore screen.
final selectedGenreAnimeProvider = categoryAnimeProvider;

