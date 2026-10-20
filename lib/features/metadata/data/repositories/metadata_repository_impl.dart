import 'package:dio/dio.dart';
import '../../domain/models/anime_detail.dart';
import '../../domain/models/anime_summary.dart';
import '../../domain/models/anime_tag.dart';
import '../../domain/models/anime_titles.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/season.dart';
import '../../domain/models/search_sort.dart';
import '../../domain/repositories/metadata_repository.dart';
import '../cache/metadata_cache.dart';
import '../datasources/bangumi_remote_data_source.dart';
import '../datasources/anilist_remote_data_source.dart';

class MetadataRepositoryImpl implements MetadataRepository {
  final BangumiRemoteDataSource bangumiDataSource;
  final AniListRemoteDataSource anilistDataSource;
  final MetadataCache cache;
  final Map<int, String> _idSourceMap = {};

  MetadataRepositoryImpl({
    BangumiRemoteDataSource? bangumi,
    AniListRemoteDataSource? anilist,
    MetadataCache? cache,
  })  : bangumiDataSource = bangumi ?? BangumiRemoteDataSource(),
        anilistDataSource = anilist ?? AniListRemoteDataSource(),
        cache = cache ?? MetadataCache();

  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty && (tags == null || tags.isEmpty)) return [];

    final tagsKey = (tags ?? []).join(',');
    final cacheKey = 'search_${trimmed}_${tagsKey}_${sort.name}_${limit}_$offset';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null) {
      for (final s in cached) {
        _idSourceMap.putIfAbsent(s.id, () => 'anilist');
      }
      return cached;
    }

    final isLatin = trimmed.isNotEmpty && AnimeTitles.isPrimarilyLatin(trimmed);

    // 1. If query is Latin (English), prioritize AniList for fast response and full English metadata
    if (isLatin && (tags == null || tags.isEmpty)) {
      try {
        final page = (offset ~/ limit) + 1;
        final anilistResults = await anilistDataSource.searchSubjects(
          trimmed,
          limit: limit,
          page: page,
          cancelToken: cancelToken,
        );
        if (anilistResults.isNotEmpty) {
          for (final s in anilistResults) {
            _idSourceMap[s.id] = 'anilist';
          }
          cache.set(cacheKey, anilistResults, MetadataCache.searchTtl);
          return anilistResults;
        }
      } catch (_) {
        // Fall back to Bangumi if AniList fails
      }
    }

    try {
      // 2. Fetch from Bangumi source with a 4s timeout to avoid connection hanging
      final results = await bangumiDataSource.searchSubjects(
        trimmed,
        sort: sort,
        tags: tags,
        limit: limit,
        offset: offset,
        cancelToken: cancelToken,
      ).timeout(const Duration(seconds: 4));

      for (final s in results) {
        _idSourceMap[s.id] = 'bangumi';
      }

      // If English title is missing on top results, try to enrich asynchronously from AniList
      // Throttle to top 4 items to prevent exhausting AniList's 90 req/min rate limit
      final topToEnrich = results.take(4).toList();
      final remaining = results.skip(4).toList();

      final enrichedTop = await Future.wait(
        topToEnrich.map((summary) async {
          if (summary.titles.english != null &&
              summary.titles.english!.isNotEmpty &&
              AnimeTitles.isPrimarilyLatin(summary.titles.english!)) {
            return summary;
          }
          try {
            final queryTitle = summary.titles.original.isNotEmpty
                ? summary.titles.original
                : trimmed;
            final anilist = await anilistDataSource.searchMedia(
              queryTitle,
              cancelToken: cancelToken,
            );
            if (anilist != null) {
              final enTitle = anilist.titles.english ?? anilist.titles.localized;
              if (enTitle != null && enTitle.isNotEmpty) {
                return summary.copyWith(
                  titles: summary.titles.copyWith(
                    english: enTitle,
                    localized: anilist.titles.localized ?? summary.titles.localized,
                  ),
                );
              }
            }
          } catch (_) {}
          return summary;
        }),
      );

      final enrichedResults = [...enrichedTop, ...remaining];
      cache.set(cacheKey, enrichedResults, MetadataCache.searchTtl);
      return enrichedResults;
    } catch (e) {
      // If Bangumi failed or timed out (e.g. connection abort), fall back to AniList
      if (trimmed.isNotEmpty) {
        try {
          final page = (offset ~/ limit) + 1;
          final anilistResults = await anilistDataSource.searchSubjects(
            trimmed,
            limit: limit,
            page: page,
            cancelToken: cancelToken,
          );
          if (anilistResults.isNotEmpty) {
            cache.set(cacheKey, anilistResults, MetadataCache.searchTtl);
            return anilistResults;
          }
        } catch (_) {}
      }

      // Offline fallback: check if we have any stale cached results for this query
      final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
      if (stale != null) return stale;
      return [];
    }
  }

  @override
  Future<AnimeDetail> getAnimeDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'detail_$id';
    final cached = cache.get<AnimeDetail>(cacheKey);
    if (cached != null) return cached;

    final sourceOrigin = _idSourceMap[id];

    // If this ID is known to be from Bangumi, prioritize Bangumi to avoid AniList ID space collisions
    if (sourceOrigin == 'bangumi') {
      try {
        final detailFuture = bangumiDataSource.getSubjectDetail(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
        final episodesFuture = bangumiDataSource.getEpisodes(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
        final relationsFuture = bangumiDataSource.getRelations(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));

        final detail = await detailFuture;
        final episodes = await episodesFuture;
        final seasons = await relationsFuture;

        var titles = detail.titles;
        String? bannerUrl = detail.bannerUrl;
        String? summary = detail.summary;
        var tags = detail.tags;

        try {
          final queryTitle = (titles.english != null && titles.english!.isNotEmpty)
              ? titles.english!
              : titles.original;
          final anilist = await anilistDataSource.searchMedia(
            queryTitle,
            cancelToken: cancelToken,
          );
          if (anilist != null) {
            final enTitle = anilist.titles.english ?? anilist.titles.localized;
            if (enTitle != null && enTitle.isNotEmpty) {
              titles = titles.copyWith(
                english: enTitle,
                localized: anilist.titles.localized ?? titles.localized,
              );
            }
            bannerUrl ??= anilist.bannerImage;
            summary ??= anilist.description;
            if (tags.isEmpty && anilist.genres != null) {
              tags = anilist.genres!.map((g) => AnimeTag(name: g, count: 100)).toList();
            }
          }
        } catch (_) {}

        final fullDetail = detail.copyWith(
          titles: titles,
          bannerUrl: bannerUrl,
          summary: summary,
          tags: tags,
          episodes: episodes,
          seasons: seasons,
        );
        cache.set(cacheKey, fullDetail, MetadataCache.detailTtl);
        return fullDetail;
      } catch (_) {}
    }

    // 1. Try AniList first (fast worldwide Cloudflare CDN, full English metadata)
    try {
      final anilist = await anilistDataSource.getMediaById(id, cancelToken: cancelToken);
      if (anilist != null) {
        final totalEps = anilist.episodes ?? 12;
        final episodes = anilist.episodesList ??
            List.generate(
              totalEps,
              (i) => Episode(
                id: anilist.id * 1000 + (i + 1),
                number: (i + 1).toDouble(),
                sort: i + 1,
                title: 'Episode ${i + 1}',
              ),
            );

        final detail = AnimeDetail(
          id: anilist.id,
          titles: anilist.titles,
          posterUrl: anilist.coverImage,
          bannerUrl: anilist.bannerImage,
          summary: anilist.description,
          score: anilist.score,
          eps: totalEps,
          airDate: anilist.year != null ? '${anilist.year}-01-01' : null,
          platform: anilist.format ?? 'TV',
          tags: (anilist.genres ?? [])
              .map((g) => AnimeTag(name: g, count: 100))
              .toList(),
          seasons: anilist.seasons ??
              [
                Season(
                  id: anilist.id,
                  name: anilist.titles.preferredTitle(TitlePreference.english),
                  isCurrent: true,
                ),
              ],
          episodes: episodes,
        );
        cache.set(cacheKey, detail, MetadataCache.detailTtl);
        return detail;
      }
    } catch (_) {}

    try {
      // 2. Fall back to Bangumi source with a 4s timeout
      final detailFuture = bangumiDataSource.getSubjectDetail(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
      final episodesFuture = bangumiDataSource.getEpisodes(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
      final relationsFuture = bangumiDataSource.getRelations(id, cancelToken: cancelToken).timeout(const Duration(seconds: 4));

      final detail = await detailFuture;
      final episodes = await episodesFuture;
      final seasons = await relationsFuture;

      // Enrich English title, banner, description, and tags from AniList
      var titles = detail.titles;
      String? bannerUrl = detail.bannerUrl;
      String? summary = detail.summary;
      var tags = detail.tags;

      try {
        final queryTitle = (titles.english != null && titles.english!.isNotEmpty)
            ? titles.english!
            : titles.original;
        final anilist = await anilistDataSource.searchMedia(
          queryTitle,
          cancelToken: cancelToken,
        );
        if (anilist != null) {
          final enTitle = anilist.titles.english ?? anilist.titles.localized;
          if (enTitle != null && enTitle.isNotEmpty) {
            titles = titles.copyWith(
              english: enTitle,
              localized: anilist.titles.localized ?? titles.localized,
            );
          }
          bannerUrl ??= anilist.bannerImage;
          if (anilist.description != null && anilist.description!.trim().isNotEmpty) {
            summary = anilist.description!.trim();
          }
          if (anilist.genres != null && anilist.genres!.isNotEmpty) {
            final englishGenreTags = anilist.genres!
                .map((g) => AnimeTag(name: g, count: 100))
                .toList();
            tags = [...englishGenreTags, ...tags];
          }
        }
      } catch (_) {}

      final fullDetail = detail.copyWith(
        titles: titles,
        bannerUrl: bannerUrl,
        summary: summary,
        tags: tags,
        episodes: episodes,
        seasons: seasons,
      );

      cache.set(cacheKey, fullDetail, MetadataCache.detailTtl);
      return fullDetail;
    } catch (e) {
      // Offline fallback: check stale cache
      final stale = cache.getStale<AnimeDetail>(cacheKey);
      if (stale != null) return stale;

      // Try AniList fallback by numeric ID
      try {
        final anilist = await anilistDataSource.getMediaById(id, cancelToken: cancelToken);
        if (anilist != null) {
          final totalEps = anilist.episodes ?? 12;
          final fallbackDetail = AnimeDetail(
            id: anilist.id,
            titles: anilist.titles,
            posterUrl: anilist.coverImage,
            bannerUrl: anilist.bannerImage,
            score: anilist.score,
            eps: totalEps,
            airDate: anilist.year != null ? '${anilist.year}-01-01' : null,
            platform: anilist.format,
            episodes: List.generate(
              totalEps,
              (i) => Episode(
                id: anilist.id * 1000 + (i + 1),
                number: (i + 1).toDouble(),
                sort: i + 1,
                title: 'Episode ${i + 1}',
              ),
            ),
          );
          cache.set(cacheKey, fallbackDetail, MetadataCache.detailTtl);
          return fallbackDetail;
        }
      } catch (_) {}

      rethrow;
    }
  }

  @override
  Future<List<Episode>> getEpisodes(
    int animeId, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'episodes_$animeId';
    final cached = cache.get<List<Episode>>(cacheKey);
    if (cached != null) return cached;

    final detailCached = cache.get<AnimeDetail>('detail_$animeId');
    if (detailCached != null && detailCached.episodes.isNotEmpty) {
      cache.set(cacheKey, detailCached.episodes, MetadataCache.detailTtl);
      return detailCached.episodes;
    }

    try {
      final anilist = await anilistDataSource.getMediaById(animeId, cancelToken: cancelToken);
      if (anilist != null && anilist.episodesList != null && anilist.episodesList!.isNotEmpty) {
        cache.set(cacheKey, anilist.episodesList!, MetadataCache.detailTtl);
        return anilist.episodesList!;
      }
    } catch (_) {}

    try {
      final episodes = await bangumiDataSource.getEpisodes(animeId, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
      cache.set(cacheKey, episodes, MetadataCache.detailTtl);
      return episodes;
    } catch (e) {
      final stale = cache.getStale<List<Episode>>(cacheKey);
      if (stale != null) return stale;
      return [];
    }
  }

  @override
  Future<List<Season>> getSeasons(
    int animeId, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'seasons_$animeId';
    final cached = cache.get<List<Season>>(cacheKey);
    if (cached != null) return cached;

    final detailCached = cache.get<AnimeDetail>('detail_$animeId');
    if (detailCached != null && detailCached.seasons.isNotEmpty) {
      cache.set(cacheKey, detailCached.seasons, MetadataCache.detailTtl);
      return detailCached.seasons;
    }

    try {
      final anilist = await anilistDataSource.getMediaById(animeId, cancelToken: cancelToken);
      if (anilist != null && anilist.seasons != null && anilist.seasons!.isNotEmpty) {
        cache.set(cacheKey, anilist.seasons!, MetadataCache.detailTtl);
        return anilist.seasons!;
      }
    } catch (_) {}

    try {
      final seasons = await bangumiDataSource.getRelations(animeId, cancelToken: cancelToken).timeout(const Duration(seconds: 4));
      cache.set(cacheKey, seasons, MetadataCache.detailTtl);
      return seasons;
    } catch (e) {
      final stale = cache.getStale<List<Season>>(cacheKey);
      if (stale != null) return stale;
      return [Season(id: animeId, name: 'Season 1', isCurrent: true)];
    }
  }

  @override
  Future<List<FeaturedAnimeItem>> getFeaturedAnime({
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    const cacheKey = 'home_featured';
    final cached = cache.get<List<FeaturedAnimeItem>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getFeaturedAnime(
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<FeaturedAnimeItem>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _curatedFeatured.take(limit).toList();
  }

  @override
  Future<List<AnimeSummary>> getTrendingAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    const cacheKey = 'home_trending';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getTrendingAnime(
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _curatedTrending.take(limit).toList();
  }

  @override
  Future<List<AnimeSummary>> getTopRatedAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    const cacheKey = 'home_top_rated';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getTopRatedAnime(
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _curatedTrending.reversed.take(limit).toList();
  }

  @override
  Future<List<AnimeSummary>> getRecentlyUpdatedAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    const cacheKey = 'home_recently_updated';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getRecentlyUpdatedAnime(
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _curatedTrending.take(limit).toList();
  }

  @override
  Future<List<AnimeSummary>> getAnimeByGenre(
    String genre, {
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'genre_$genre';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getAnimeByGenre(
        genre,
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _curatedTrending.take(limit).toList();
  }

  @override
  Future<List<AnimeSummary>> getAnimeByGenreCatalog({
    required String genre,
    List<String> sort = const ['POPULARITY_DESC'],
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final sortKey = sort.join('_');
    final cacheKey = 'genre_cat_${genre}_${sortKey}_${status ?? 'all'}_${page}_$limit';
    final cached = cache.get<List<AnimeSummary>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final items = await anilistDataSource.getAnimeByGenreCatalog(
        genre: genre,
        sort: sort,
        status: status,
        page: page,
        limit: limit,
        cancelToken: cancelToken,
      );
      if (items.isNotEmpty) {
        cache.set(cacheKey, items, MetadataCache.searchTtl);
        return items;
      }
    } catch (_) {}

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return page == 1 ? _curatedTrending.take(limit).toList() : [];
  }

  @override
  Future<FeaturedAnimeItem?> getFeaturedAnimeByGenre(
    String genre, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'genre_hero_$genre';
    final cached = cache.get<FeaturedAnimeItem>(cacheKey);
    if (cached != null) return cached;

    try {
      final item = await anilistDataSource.getFeaturedAnimeByGenre(
        genre,
        cancelToken: cancelToken,
      );
      if (item != null) {
        cache.set(cacheKey, item, MetadataCache.detailTtl);
        return item;
      }
    } catch (_) {}

    return _curatedFeatured.firstWhere(
      (f) => f.genres.any((g) => g.toLowerCase() == genre.toLowerCase()),
      orElse: () => _curatedFeatured.first,
    );
  }

  static const List<FeaturedAnimeItem> _curatedFeatured = [
    FeaturedAnimeItem(
      id: 151801,
      titles: AnimeTitles(original: 'Ore dake Level Up na Ken', english: 'Solo Leveling', localized: 'Solo Leveling'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151801-9tScebB1A6a6.png',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/151801-3bH0j1k0s5mJ.jpg',
      score: 8.5,
      eps: 12,
      format: 'TV',
      summary: 'They say whatever doesn’t kill you makes you stronger, but that’s not the case for the world’s weakest hunter, Sung Jinwoo.',
      genres: ['Action', 'Fantasy', 'Adventure'],
    ),
    FeaturedAnimeItem(
      id: 101922,
      titles: AnimeTitles(original: 'Kimetsu no Yaiba', english: 'Demon Slayer: Kimetsu no Yaiba', localized: 'Demon Slayer'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-WBsBl0ClmgYL.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101922-YfZhTBblAZyn.jpg',
      score: 8.4,
      eps: 26,
      format: 'TV',
      summary: 'Tanjiro Kamado sets out to become a demon slayer to avenge his family and cure his sister Nezuko.',
      genres: ['Action', 'Supernatural', 'Historical'],
    ),
    FeaturedAnimeItem(
      id: 154587,
      titles: AnimeTitles(original: 'Sousou no Frieren', english: "Frieren: Beyond Journey's End", localized: 'Frieren'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-n1fmjvsrJDzb.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-9k3qK00v3V8w.jpg',
      score: 9.3,
      eps: 28,
      format: 'TV',
      summary: 'The adventure is over but life goes on for an elf mage just beginning to learn what living is all about.',
      genres: ['Adventure', 'Drama', 'Fantasy'],
    ),
  ];

  static const List<AnimeSummary> _curatedTrending = [
    AnimeSummary(
      id: 151801,
      titles: AnimeTitles(original: 'Ore dake Level Up na Ken', english: 'Solo Leveling', localized: 'Solo Leveling'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151801-9tScebB1A6a6.png',
      score: 8.5,
      eps: 12,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 101922,
      titles: AnimeTitles(original: 'Kimetsu no Yaiba', english: 'Demon Slayer: Kimetsu no Yaiba', localized: 'Demon Slayer'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-WBsBl0ClmgYL.jpg',
      score: 8.4,
      eps: 26,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 113415,
      titles: AnimeTitles(original: 'Jujutsu Kaisen', english: 'JUJUTSU KAISEN', localized: 'JUJUTSU KAISEN'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx113415-bbBWj4pEFseh.jpg',
      score: 8.6,
      eps: 24,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 154587,
      titles: AnimeTitles(original: 'Sousou no Frieren', english: "Frieren: Beyond Journey's End", localized: 'Frieren'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-n1fmjvsrJDzb.jpg',
      score: 9.3,
      eps: 28,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 16498,
      titles: AnimeTitles(original: 'Shingeki no Kyojin', english: 'Attack on Titan', localized: 'Attack on Titan'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-m5ZMNSczuoxP.jpg',
      score: 9.0,
      eps: 25,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 127230,
      titles: AnimeTitles(original: 'Chainsaw Man', english: 'Chainsaw Man', localized: 'Chainsaw Man'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx127230-NuFvF0eaT5kL.png',
      score: 8.4,
      eps: 12,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 21,
      titles: AnimeTitles(original: 'ONE PIECE', english: 'ONE PIECE', localized: 'ONE PIECE'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21-4w814kJv8j07.png',
      score: 8.8,
      eps: 1100,
      platform: 'TV',
    ),
    AnimeSummary(
      id: 171018,
      titles: AnimeTitles(original: 'Dandadan', english: 'DAN DA DAN', localized: 'DAN DA DAN'),
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx171018-oXkC15bIeWwJ.jpg',
      score: 8.6,
      eps: 12,
      platform: 'TV',
    ),
  ];
}
