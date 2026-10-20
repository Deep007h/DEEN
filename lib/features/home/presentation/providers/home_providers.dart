import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../../../metadata/domain/models/anime_summary.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';

/// Featured anime banner list provider for the Home hero carousel.
final featuredAnimeProvider = FutureProvider<List<FeaturedAnimeItem>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getFeaturedAnime(limit: 6);
});

/// Trending anime list provider.
final trendingAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getTrendingAnime(limit: 10);
});

/// Top rated anime list provider.
final topRatedAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getTopRatedAnime(limit: 10);
});

/// Recently added / airing anime list provider.
final recentlyAddedAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getRecentlyUpdatedAnime(limit: 10);
});

/// Anime list filtered by genre / category.
final categoryAnimeProvider = FutureProvider.family<List<AnimeSummary>, String>((ref, genre) async {
  final repo = ref.watch(metadataRepositoryProvider);
  return repo.getAnimeByGenre(genre, limit: 10);
});

/// Alias for [categoryAnimeProvider] used by Explore screen.
final selectedGenreAnimeProvider = categoryAnimeProvider;
