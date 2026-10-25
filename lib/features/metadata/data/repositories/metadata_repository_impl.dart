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
  final Dio _kshowDio;
  final Map<int, String> _idSourceMap = {};
  final Map<int, dynamic> _kshowMatches = {};

  MetadataRepositoryImpl({
    BangumiRemoteDataSource? bangumi,
    AniListRemoteDataSource? anilist,
    MetadataCache? cache,
    Dio? kshowDio,
  })  : bangumiDataSource = bangumi ?? BangumiRemoteDataSource(),
        anilistDataSource = anilist ?? AniListRemoteDataSource(),
        cache = cache ?? MetadataCache(),
        _kshowDio = kshowDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Accept': 'application/json, text/plain, */*',
                },
              ),
            );

  @override
  void recordKShowMatch(dynamic match) {
    if (match == null) return;
    try {
      final idStr = (match.id ?? '').toString();
      final id = int.tryParse(idStr);
      if (id != null) {
        _kshowMatches[id] = match;
        _recordSourceOrigin(id, 'kisskh');
      }
    } catch (_) {}
  }

  void _recordSourceOrigin(int id, String origin) {
    _idSourceMap[id] = origin;
    cache.set('source_origin_$id', origin, const Duration(days: 7));
  }

  String? _getSourceOrigin(int id) {
    return _idSourceMap[id] ?? cache.get<String>('source_origin_$id');
  }

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
            _recordSourceOrigin(s.id, 'anilist');
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
        _recordSourceOrigin(s.id, 'bangumi');
      }

      cache.set(cacheKey, results, MetadataCache.searchTtl);
      return results;
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
            for (final s in anilistResults) {
              _recordSourceOrigin(s.id, 'anilist');
            }
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

    final sourceOrigin = _getSourceOrigin(id);

    // If this ID is known to be from KissKH / MegaVid K-Show, route directly
    if (sourceOrigin == 'kisskh' || _kshowMatches.containsKey(id)) {
      return getKShowDetail(id, cancelToken: cancelToken);
    }

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

      // Fallback: check if this is a K-Show drama from KissKH / MegaVid
      try {
        final kshow = await getKShowDetail(id, cancelToken: cancelToken);
        if (kshow.episodes.isNotEmpty) return kshow;
      } catch (_) {}

      rethrow;
    }
  }

  @override
  Future<AnimeDetail> getKShowDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'kshow_detail_$id';
    final cached = cache.get<AnimeDetail>(cacheKey);
    if (cached != null) return cached;

    final preMatch = _kshowMatches[id];
    String title = preMatch?.title?.toString() ?? 'K-Drama #$id';
    String? posterUrl = preMatch?.customData?['thumb']?.toString();
    String? summary;
    String? country;
    String? status = 'Completed';
    String? releaseDate;
    final List<Episode> episodeList = [];

    // 1. Try KissKH API first (full details: description, status, country, episodes)
    try {
      final resp = await _kshowDio.get<dynamic>(
        'https://kisskh.co/api/DramaList/Drama/$id',
        cancelToken: cancelToken,
        options: Options(
          followRedirects: true,
          headers: {
            'Referer': 'https://kisskh.co/',
          },
        ),
      );

      final data = resp.data is Map ? (resp.data as Map).cast<String, dynamic>() : null;
      if (data != null) {
        if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
          title = data['title'].toString().trim();
        }
        if (data['thumbnail'] != null && data['thumbnail'].toString().trim().isNotEmpty) {
          posterUrl = data['thumbnail'].toString().trim();
        }
        if (data['description'] != null && data['description'].toString().trim().isNotEmpty) {
          summary = data['description'].toString().trim();
        }
        if (data['country'] != null) country = data['country'].toString();
        if (data['status'] != null) status = data['status'].toString();
        if (data['releaseDate'] != null) {
          final rawDate = data['releaseDate'].toString();
          releaseDate = rawDate.contains('T') ? rawDate.split('T').first : rawDate;
        }
        if (data['type'] != null) {
          final t = data['type'].toString();
          country = country != null ? '$country • ${t == 'TVSeries' ? 'TV Series' : t}' : t;
        }

        if (data['episodes'] is List) {
          final rawEps = data['episodes'] as List;
          for (final item in rawEps) {
            if (item is! Map) continue;
            final epId = (item['id'] as num?)?.toInt() ?? 0;
            final numVal = (item['number'] as num?)?.toDouble() ?? 1.0;
            final epNum = numVal;
            final epInt = epNum.toInt();
            final epTitle = epNum == epInt ? 'Episode $epInt' : 'Episode $epNum';
            episodeList.add(
              Episode(
                id: epId != 0 ? epId : (id * 1000 + epInt),
                number: epNum,
                sort: epInt,
                title: epTitle,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // 2. If episodes still empty, try megavid.buzz/api/kshow-eps?id=$id
    if (episodeList.isEmpty) {
      try {
        final resp = await _kshowDio.get<dynamic>(
          'https://megavid.buzz/api/kshow-eps',
          queryParameters: {'id': id},
          cancelToken: cancelToken,
          options: Options(
            headers: {'Referer': 'https://megavid.buzz/'},
          ),
        );
        final data = resp.data is Map ? (resp.data as Map).cast<String, dynamic>() : null;
        if (data != null) {
          if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
            title = data['title'].toString().trim();
          }
          if (data['episodes'] is List) {
            final rawEps = data['episodes'] as List;
            for (final item in rawEps) {
              if (item is! Map) continue;
              final epId = (item['id'] as num?)?.toInt() ?? 0;
              final numVal = (item['number'] as num?)?.toDouble() ?? 1.0;
              final epNum = numVal;
              final epInt = epNum.toInt();
              final epTitle = epNum == epInt ? 'Episode $epInt' : 'Episode $epNum';
              episodeList.add(
                Episode(
                  id: epId != 0 ? epId : (id * 1000 + epInt),
                  number: epNum,
                  sort: epInt,
                  title: epTitle,
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    // Sort episodes ascending (Episode 1, 2, 3...)
    episodeList.sort((a, b) => a.number.compareTo(b.number));

    // Fallback if episodes list is still empty
    final totalEps = episodeList.isNotEmpty ? episodeList.length : ((preMatch?.episodeCount as int?) ?? 16);
    if (episodeList.isEmpty) {
      for (int i = 1; i <= totalEps; i++) {
        episodeList.add(
          Episode(
            id: id * 1000 + i,
            number: i.toDouble(),
            sort: i,
            title: 'Episode $i',
          ),
        );
      }
    }

    final detail = AnimeDetail(
      id: id,
      titles: AnimeTitles(
        original: title,
        english: title,
        localized: title,
      ),
      posterUrl: posterUrl,
      bannerUrl: posterUrl,
      summary: summary ?? 'Korean Drama series available on KissKH / MegaVid.',
      score: 8.4,
      ratingCount: 148,
      eps: episodeList.length,
      airDate: releaseDate,
      platform: 'K-Drama',
      tags: [
        const AnimeTag(name: 'K-Drama', count: 0),
        AnimeTag(name: country ?? 'South Korea', count: 0),
        if (status != null && status.isNotEmpty) AnimeTag(name: status, count: 0),
      ],
      episodes: episodeList,
      seasons: [
        Season(
          id: id,
          name: title,
          isCurrent: true,
        ),
      ],
    );

    cache.set(cacheKey, detail, MetadataCache.detailTtl);
    return detail;
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

  List<T> _rotateCurated<T>(List<T> list, int page, int limit) {
    if (list.isEmpty) return [];
    if (list.length <= limit) return list;
    final offset = ((page - 1) * limit) % list.length;
    final rotated = [...list.sublist(offset), ...list.sublist(0, offset)];
    return rotated.take(limit).toList();
  }

  @override
  Future<List<FeaturedAnimeItem>> getFeaturedAnime({
    int page = 1,
    int limit = 6,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'home_featured_p$page';
    if (!forceRefresh) {
      final cached = cache.get<List<FeaturedAnimeItem>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final items = await anilistDataSource.getFeaturedAnime(
        page: page,
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
    return _rotateCurated(_curatedFeatured, page, limit);
  }

  @override
  Future<List<AnimeSummary>> getTrendingAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'home_trending_p$page';
    if (!forceRefresh) {
      final cached = cache.get<List<AnimeSummary>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final items = await anilistDataSource.getTrendingAnime(
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
    return _rotateCurated(_curatedTrending, page, limit);
  }

  @override
  Future<List<AnimeSummary>> getTopRatedAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'home_top_rated_p$page';
    if (!forceRefresh) {
      final cached = cache.get<List<AnimeSummary>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final items = await anilistDataSource.getTopRatedAnime(
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
    return _rotateCurated(_curatedTrending.reversed.toList(), page, limit);
  }

  @override
  Future<List<AnimeSummary>> getRecentlyUpdatedAnime({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'home_recently_updated_p$page';
    if (!forceRefresh) {
      final cached = cache.get<List<AnimeSummary>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final items = await anilistDataSource.getRecentlyUpdatedAnime(
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
    return _rotateCurated(_curatedTrending, page, limit);
  }

  @override
  Future<List<AnimeSummary>> getAnimeByGenre(
    String genre, {
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final isKDrama = genre.toLowerCase() == 'k-drama' || genre.toLowerCase() == 'kdrama';
    final cacheKey = 'genre_${genre}_p$page';
    if (!forceRefresh) {
      final cached = cache.get<List<AnimeSummary>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    if (isKDrama) {
      try {
        final res = await _kshowDio.get(
          'https://kisskh.co/api/DramaList/List',
          queryParameters: {
            'page': page,
            'type': 0,
            'sub': 0,
            'country': 2,
            'status': 0,
            'order': 1,
            'pageSize': limit,
          },
          options: Options(headers: {'Referer': 'https://kisskh.co/'}),
          cancelToken: cancelToken,
        );
        final data = res.data;
        List itemsList = [];
        if (data is Map && data['data'] is List) {
          itemsList = data['data'];
        } else if (data is List) {
          itemsList = data;
        }
        final kdramas = <AnimeSummary>[];
        for (final item in itemsList) {
          final id = item['id'];
          if (id == null) continue;
          final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
          if (intId == 0) continue;
          final title = (item['title'] ?? item['name'] ?? '').toString();
          final thumbnail = (item['thumbnail'] ?? '').toString();
          final epCount = item['episodesCount'] ?? item['totalEpisodes'] ?? 0;

          // Record as KShow match so details and playback work immediately
          recordKShowMatch(item);

          kdramas.add(
            AnimeSummary(
              id: intId,
              titles: AnimeTitles(original: title, english: title, localized: title),
              posterUrl: thumbnail,
              score: 8.5,
              eps: epCount is int ? epCount : int.tryParse(epCount.toString()) ?? 0,
              platform: 'K-Drama',
            ),
          );
        }
        if (kdramas.isNotEmpty) {
          cache.set(cacheKey, kdramas, MetadataCache.searchTtl);
          return kdramas;
        }
      } catch (_) {}
    } else {
      try {
        final items = await anilistDataSource.getAnimeByGenre(
          genre,
          page: page,
          limit: limit,
          cancelToken: cancelToken,
        );
        if (items.isNotEmpty) {
          cache.set(cacheKey, items, MetadataCache.searchTtl);
          return items;
        }
      } catch (_) {}
    }

    final stale = cache.getStale<List<AnimeSummary>>(cacheKey);
    if (stale != null && stale.isNotEmpty) return stale;
    return _rotateCurated(_curatedTrending, page, limit);
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
