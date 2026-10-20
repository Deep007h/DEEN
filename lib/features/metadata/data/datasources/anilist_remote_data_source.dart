import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/anime_summary.dart';
import '../../domain/models/anime_titles.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/season.dart';

class AniListMetadata {
  final int id;
  final AnimeTitles titles;
  final String? coverImage;
  final String? bannerImage;
  final double? score;
  final int? popularity;
  final int? episodes;
  final String? format;
  final int? year;
  final String? description;
  final List<String>? genres;
  final List<Season>? seasons;
  final List<Episode>? episodesList;

  AniListMetadata({
    required this.id,
    required this.titles,
    this.coverImage,
    this.bannerImage,
    this.score,
    this.popularity,
    this.episodes,
    this.format,
    this.year,
    this.description,
    this.genres,
    this.seasons,
    this.episodesList,
  });
}

class AniListRemoteDataSource {
  final ApiClient apiClient;
  static const String endpoint = 'https://graphql.anilist.co';

  AniListRemoteDataSource({ApiClient? client})
      : apiClient = client ?? ApiClient(baseUrl: endpoint);

  static String? _cleanDescription(String? raw) {
    if (raw == null) return null;
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  static const String _mediaSearchQuery = r'''
query ($search: String) {
  Media(search: $search, type: ANIME) {
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      large
      extraLarge
    }
    bannerImage
    averageScore
    popularity
    episodes
    format
    seasonYear
    description(asHtml: false)
    genres
  }
}
''';

  /// Searches AniList by title to enrich English title, banner image, and score.
  Future<AniListMetadata?> searchMedia(String title, {CancelToken? cancelToken}) async {
    try {
      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _mediaSearchQuery,
          'variables': {'search': title},
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) return null;

      final media = data['data']?['Media'] as Map<String, dynamic>?;
      if (media == null) return null;

      final titlesJson = media['title'] as Map<String, dynamic>? ?? {};
      final romaji = titlesJson['romaji'] as String?;
      final english = titlesJson['english'] as String?;
      final native = titlesJson['native'] as String?;

      final englishTitle = (english != null && english.trim().isNotEmpty)
          ? english.trim()
          : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

      final titles = AnimeTitles(
        original: native ?? romaji ?? title,
        english: englishTitle,
        localized: romaji,
      );

      final cover = media['coverImage']?['extraLarge'] as String? ??
          media['coverImage']?['large'] as String?;
      final banner = media['bannerImage'] as String?;
      final avgScore = (media['averageScore'] as num?)?.toDouble();
      final score = avgScore != null ? avgScore / 10.0 : null; // Normalize to 10.0 scale

      final rawDesc = media['description'] as String?;
      final description = _cleanDescription(rawDesc);
      final genresRaw = media['genres'] as List<dynamic>?;
      final genres = genresRaw?.whereType<String>().toList();

      return AniListMetadata(
        id: media['id'] as int? ?? 0,
        titles: titles,
        coverImage: cover,
        bannerImage: banner,
        score: score,
        popularity: media['popularity'] as int?,
        episodes: media['episodes'] as int?,
        format: media['format'] as String?,
        year: media['seasonYear'] as int?,
        description: description,
        genres: genres,
      );
    } catch (_) {
      // Graceful fallback: return null on rate limit or network error
      return null;
    }
  }

  static const String _mediaByIdQuery = r'''
query ($id: Int) {
  Media(id: $id) {
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      large
      extraLarge
    }
    bannerImage
    averageScore
    popularity
    episodes
    nextAiringEpisode {
      episode
    }
    format
    seasonYear
    description(asHtml: false)
    genres
    relations {
      edges {
        relationType
        node {
          id
          title {
            romaji
            english
            native
          }
          format
          coverImage {
            large
          }
        }
      }
    }
  }
}
''';

  /// Fetches AniList media directly by numeric ID with full episodes and seasons.
  Future<AniListMetadata?> getMediaById(int id, {CancelToken? cancelToken}) async {
    try {
      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _mediaByIdQuery,
          'variables': {'id': id},
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) return null;

      final media = data['data']?['Media'] as Map<String, dynamic>?;
      if (media == null) return null;

      final titlesJson = media['title'] as Map<String, dynamic>? ?? {};
      final romaji = titlesJson['romaji'] as String?;
      final english = titlesJson['english'] as String?;
      final native = titlesJson['native'] as String?;

      final englishTitle = (english != null && english.trim().isNotEmpty)
          ? english.trim()
          : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

      final titles = AnimeTitles(
        original: native ?? romaji ?? 'Anime $id',
        english: englishTitle,
        localized: romaji,
      );

      final cover = media['coverImage']?['extraLarge'] as String? ??
          media['coverImage']?['large'] as String?;
      final banner = media['bannerImage'] as String?;
      final avgScore = (media['averageScore'] as num?)?.toDouble();
      final score = avgScore != null ? avgScore / 10.0 : null;

      final rawDesc = media['description'] as String?;
      final description = _cleanDescription(rawDesc);
      final genresRaw = media['genres'] as List<dynamic>?;
      final genres = genresRaw?.whereType<String>().toList();

      int totalEps = media['episodes'] as int? ?? 0;
      if (totalEps <= 0) {
        final nextEp = media['nextAiringEpisode']?['episode'] as int?;
        if (nextEp != null && nextEp > 1) {
          totalEps = nextEp - 1;
        } else {
          totalEps = 12;
        }
      }

      final generatedEpisodes = List.generate(
        totalEps,
        (i) => Episode(
          id: (media['id'] as int? ?? id) * 1000 + (i + 1),
          number: (i + 1).toDouble(),
          sort: i + 1,
          title: 'Episode ${i + 1}',
        ),
      );

      final relationsEdges = media['relations']?['edges'] as List<dynamic>?;
      final parsedSeasons = <Season>[];
      parsedSeasons.add(
        Season(
          id: id,
          name: englishTitle ?? romaji ?? 'Current Season',
          originalName: native,
          isCurrent: true,
          posterUrl: cover,
        ),
      );

      if (relationsEdges != null) {
        for (final edge in relationsEdges) {
          if (edge is! Map<String, dynamic>) continue;
          final node = edge['node'] as Map<String, dynamic>?;
          if (node == null) continue;
          final nodeFormat = node['format'] as String? ?? '';
          const validFormats = {'TV', 'TV_SHORT', 'MOVIE', 'OVA', 'ONA'};
          if (!validFormats.contains(nodeFormat)) continue;

          final edgeId = node['id'] as int? ?? 0;
          if (edgeId == 0 || edgeId == id) continue;
          final nodeTitleJson = node['title'] as Map<String, dynamic>? ?? {};
          final nodeEng = nodeTitleJson['english'] as String?;
          final nodeRomaji = nodeTitleJson['romaji'] as String?;
          final nodeNative = nodeTitleJson['native'] as String?;
          final nodePoster = node['coverImage']?['large'] as String?;
          final relType = edge['relationType'] as String? ?? 'RELATION';

          parsedSeasons.add(
            Season(
              id: edgeId,
              name: (nodeEng != null && nodeEng.isNotEmpty) ? nodeEng : (nodeRomaji ?? 'Season $edgeId'),
              originalName: nodeNative,
              relation: relType,
              isCurrent: false,
              posterUrl: nodePoster,
            ),
          );
        }
      }

      return AniListMetadata(
        id: media['id'] as int? ?? id,
        titles: titles,
        coverImage: cover,
        bannerImage: banner,
        score: score,
        popularity: media['popularity'] as int?,
        episodes: totalEps,
        format: media['format'] as String?,
        year: media['seasonYear'] as int?,
        description: description,
        genres: genres,
        seasons: parsedSeasons,
        episodesList: generatedEpisodes,
      );
    } catch (_) {
      return null;
    }
  }

  static const String _pageSearchQuery = r'''
query ($search: String, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(search: $search, type: ANIME, sort: SEARCH_MATCH) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        extraLarge
      }
      bannerImage
      averageScore
      popularity
      episodes
      seasonYear
      genres
    }
  }
}
''';

  /// Searches anime media directly on AniList as primary or resilient fallback.
  Future<List<AnimeSummary>> searchSubjects(
    String keyword, {
    int limit = 20,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _pageSearchQuery,
          'variables': {
            'search': keyword,
            'page': page,
            'perPage': limit,
          },
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) return [];

      final list = data['data']?['Page']?['media'] as List<dynamic>?;
      if (list == null) return [];

      return list.map<AnimeSummary>((item) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int? ?? 0;
        final titlesJson = map['title'] as Map<String, dynamic>? ?? {};
        final romaji = titlesJson['romaji'] as String?;
        final english = titlesJson['english'] as String?;
        final native = titlesJson['native'] as String?;

        final englishTitle = (english != null && english.trim().isNotEmpty)
            ? english.trim()
            : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

        final titles = AnimeTitles(
          original: native ?? romaji ?? keyword,
          english: englishTitle,
          localized: romaji,
        );

        final cover = map['coverImage']?['large'] as String? ??
            map['coverImage']?['extraLarge'] as String?;
        final avgScore = (map['averageScore'] as num?)?.toDouble();
        final score = avgScore != null ? avgScore / 10.0 : null;
        final eps = map['episodes'] as int?;
        final year = map['seasonYear'] as int?;

        return AnimeSummary(
          id: id,
          titles: titles,
          posterUrl: cover,
          score: score,
          eps: eps,
          airDate: year != null ? '$year-01-01' : null,
          platform: 'TV',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static const String _pageCatalogQuery = r'''
query ($page: Int, $sort: [MediaSort], $status: MediaStatus, $genre: String, $tag: String, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, sort: $sort, status: $status, genre: $genre, tag: $tag) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        extraLarge
      }
      bannerImage
      averageScore
      popularity
      episodes
      format
      seasonYear
      description(asHtml: false)
      genres
    }
  }
}
''';

  /// Fetches featured banner anime with high-res art and synopsis for the Home hero carousel.
  Future<List<FeaturedAnimeItem>> getFeaturedAnime({
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _pageCatalogQuery,
          'variables': {
            'sort': ['TRENDING_DESC', 'POPULARITY_DESC'],
            'perPage': limit,
          },
        },
        cancelToken: cancelToken,
      );

      final list = response.data?['data']?['Page']?['media'] as List<dynamic>?;
      if (list == null) return [];

      return list.map<FeaturedAnimeItem>((item) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int? ?? 0;
        final titlesJson = map['title'] as Map<String, dynamic>? ?? {};
        final romaji = titlesJson['romaji'] as String?;
        final english = titlesJson['english'] as String?;
        final native = titlesJson['native'] as String?;

        final englishTitle = (english != null && english.trim().isNotEmpty)
            ? english.trim()
            : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

        final titles = AnimeTitles(
          original: native ?? romaji ?? '',
          english: englishTitle,
          localized: romaji,
        );

        final cover = map['coverImage']?['extraLarge'] as String? ??
            map['coverImage']?['large'] as String?;
        final banner = map['bannerImage'] as String?;
        final avgScore = (map['averageScore'] as num?)?.toDouble();
        final score = avgScore != null ? avgScore / 10.0 : null;
        final eps = map['episodes'] as int?;
        final format = map['format'] as String? ?? 'TV';
        final rawDesc = map['description'] as String?;
        final genresRaw = map['genres'] as List<dynamic>?;
        final genres = genresRaw?.whereType<String>().toList() ?? <String>[];

        return FeaturedAnimeItem(
          id: id,
          titles: titles,
          posterUrl: cover,
          bannerUrl: banner ?? cover,
          score: score,
          eps: eps,
          format: format,
          summary: _cleanDescription(rawDesc),
          genres: genres,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches trending anime sorted by real-time AniList trending index.
  Future<List<AnimeSummary>> getTrendingAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return _fetchCatalogList(
      sort: ['TRENDING_DESC', 'POPULARITY_DESC'],
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  /// Fetches highest-rated anime of all time.
  Future<List<AnimeSummary>> getTopRatedAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return _fetchCatalogList(
      sort: ['SCORE_DESC'],
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  /// Fetches recently released / actively airing anime.
  Future<List<AnimeSummary>> getRecentlyUpdatedAnime({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return _fetchCatalogList(
      sort: ['POPULARITY_DESC'],
      status: 'RELEASING',
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  /// Fetches anime for a specific genre (Action, Adventure, Fantasy, Romance, etc.).
  Future<List<AnimeSummary>> getAnimeByGenre(
    String genre, {
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return _fetchCatalogList(
      sort: ['POPULARITY_DESC'],
      genre: genre,
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  /// Fetches anime for a specific genre with custom sort and pagination.
  Future<List<AnimeSummary>> getAnimeByGenreCatalog({
    required String genre,
    List<String> sort = const ['POPULARITY_DESC'],
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return _fetchCatalogList(
      sort: sort,
      genre: genre,
      status: status,
      page: page,
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  /// Fetches top featured anime item with banner and description for a specific genre.
  Future<FeaturedAnimeItem?> getFeaturedAnimeByGenre(
    String genre, {
    CancelToken? cancelToken,
  }) async {
    try {
      final variables = <String, dynamic>{
        'page': 1,
        'sort': ['TRENDING_DESC', 'POPULARITY_DESC'],
        'perPage': 4,
      };
      if (genre.toLowerCase() == 'isekai') {
        variables['tag'] = 'Isekai';
      } else {
        variables['genre'] = genre;
      }

      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _pageCatalogQuery,
          'variables': variables,
        },
        cancelToken: cancelToken,
      );

      final list = response.data?['data']?['Page']?['media'] as List<dynamic>?;
      if (list == null || list.isEmpty) return null;

      final chosen = list.firstWhere(
        (m) => (m as Map<String, dynamic>)['bannerImage'] != null,
        orElse: () => list.first,
      ) as Map<String, dynamic>;

      final id = chosen['id'] as int? ?? 0;
      final titlesJson = chosen['title'] as Map<String, dynamic>? ?? {};
      final romaji = titlesJson['romaji'] as String?;
      final english = titlesJson['english'] as String?;
      final native = titlesJson['native'] as String?;

      final englishTitle = (english != null && english.trim().isNotEmpty)
          ? english.trim()
          : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

      final titles = AnimeTitles(
        original: native ?? romaji ?? '',
        english: englishTitle,
        localized: romaji,
      );

      final cover = chosen['coverImage']?['extraLarge'] as String? ??
          chosen['coverImage']?['large'] as String?;
      final banner = chosen['bannerImage'] as String? ?? cover;
      final avgScore = (chosen['averageScore'] as num?)?.toDouble();
      final score = avgScore != null ? avgScore / 10.0 : null;
      final eps = chosen['episodes'] as int?;
      final format = chosen['format'] as String? ?? 'TV';
      final rawDesc = chosen['description'] as String?;
      final cleanDesc = rawDesc?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      final genresList = (chosen['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return FeaturedAnimeItem(
        id: id,
        titles: titles,
        posterUrl: cover,
        bannerUrl: banner,
        score: score,
        eps: eps,
        format: format,
        summary: cleanDesc,
        genres: genresList,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<AnimeSummary>> _fetchCatalogList({
    required List<String> sort,
    String? status,
    String? genre,
    String? tag,
    int page = 1,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final variables = <String, dynamic>{
        'page': page,
        'sort': sort,
        'perPage': limit,
      };
      if (status != null && status.isNotEmpty) {
        variables['status'] = status;
      }
      if (genre != null && genre.isNotEmpty) {
        if (genre.toLowerCase() == 'isekai') {
          variables['tag'] = 'Isekai';
        } else {
          variables['genre'] = genre;
        }
      }
      if (tag != null && tag.isNotEmpty) {
        variables['tag'] = tag;
      }

      final response = await apiClient.dio.post(
        endpoint,
        data: {
          'query': _pageCatalogQuery,
          'variables': variables,
        },
        cancelToken: cancelToken,
      );

      final list = response.data?['data']?['Page']?['media'] as List<dynamic>?;
      if (list == null) return [];

      return list.map<AnimeSummary>((item) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int? ?? 0;
        final titlesJson = map['title'] as Map<String, dynamic>? ?? {};
        final romaji = titlesJson['romaji'] as String?;
        final english = titlesJson['english'] as String?;
        final native = titlesJson['native'] as String?;

        final englishTitle = (english != null && english.trim().isNotEmpty)
            ? english.trim()
            : (romaji != null && romaji.trim().isNotEmpty ? romaji.trim() : null);

        final titles = AnimeTitles(
          original: native ?? romaji ?? '',
          english: englishTitle,
          localized: romaji,
        );

        final cover = map['coverImage']?['large'] as String? ??
            map['coverImage']?['extraLarge'] as String?;
        final avgScore = (map['averageScore'] as num?)?.toDouble();
        final score = avgScore != null ? avgScore / 10.0 : null;
        final eps = map['episodes'] as int?;
        final year = map['seasonYear'] as int?;
        final format = map['format'] as String? ?? 'TV';

        return AnimeSummary(
          id: id,
          titles: titles,
          posterUrl: cover,
          score: score,
          eps: eps,
          airDate: year != null ? '$year-01-01' : null,
          platform: format,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

/// Featured anime banner model for the Home hero carousel.
class FeaturedAnimeItem {
  final int id;
  final AnimeTitles titles;
  final String? posterUrl;
  final String? bannerUrl;
  final double? score;
  final int? eps;
  final String? format;
  final String? summary;
  final List<String> genres;

  const FeaturedAnimeItem({
    required this.id,
    required this.titles,
    this.posterUrl,
    this.bannerUrl,
    this.score,
    this.eps,
    this.format,
    this.summary,
    this.genres = const [],
  });
}
