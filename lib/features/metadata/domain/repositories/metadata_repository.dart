import 'package:dio/dio.dart';
import '../../data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../models/anime_summary.dart';
import '../models/anime_detail.dart';
import '../models/episode.dart';
import '../models/season.dart';
import '../models/search_sort.dart';

/// Abstract interface for fetching anime metadata from interchangeable or combined sources.
abstract class MetadataRepository {
  /// Searches for anime by keyword with sorting, filtering, tags, and pagination.
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  });

  /// Retrieves full anime detail including metadata, tags, and relations.
  Future<AnimeDetail> getAnimeDetail(
    int id, {
    CancelToken? cancelToken,
  });

  /// Retrieves main episodes for a given subject.
  Future<List<Episode>> getEpisodes(
    int animeId, {
    CancelToken? cancelToken,
  });

  /// Retrieves and constructs an ordered list of seasons/relations.
  Future<List<Season>> getSeasons(
    int animeId, {
    CancelToken? cancelToken,
  });

  /// Fetches featured banner anime for the Home hero carousel.
  Future<List<FeaturedAnimeItem>> getFeaturedAnime({
    int page = 1,
    int limit = 6,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches trending anime sorted by real-time AniList trending index.
  Future<List<AnimeSummary>> getTrendingAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches top rated anime of all time.
  Future<List<AnimeSummary>> getTopRatedAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches recently released / actively airing anime.
  Future<List<AnimeSummary>> getRecentlyUpdatedAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches anime for a specific category / genre.
  Future<List<AnimeSummary>> getAnimeByGenre(
    String genre, {
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches anime for a specific category / genre with custom sort, pagination, and status.
  Future<List<AnimeSummary>> getAnimeByGenreCatalog({
    required String genre,
    List<String> sort = const ['POPULARITY_DESC'],
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async => [];

  /// Fetches top featured hero anime with high-res banner for a specific genre.
  Future<FeaturedAnimeItem?> getFeaturedAnimeByGenre(
    String genre, {
    CancelToken? cancelToken,
  }) async => null;

  /// Records a discovered K-Show / K-Drama match or origin so subsequent detail fetches use KissKH/MegaVid.
  void recordKShowMatch(dynamic match) {}

  /// Fetches K-Show / K-Drama detail by KissKH ID.
  Future<AnimeDetail> getKShowDetail(int id, {CancelToken? cancelToken}) async {
    return getAnimeDetail(id, cancelToken: cancelToken);
  }
}

