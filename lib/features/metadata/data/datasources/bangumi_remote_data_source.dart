import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/anime_detail.dart';
import '../../domain/models/anime_summary.dart';
import '../../domain/models/anime_tag.dart';
import '../../domain/models/anime_titles.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/season.dart';
import '../../domain/models/search_sort.dart';

class BangumiRemoteDataSource {
  final ApiClient apiClient;
  static const String baseUrl = 'https://api.bgm.tv';

  BangumiRemoteDataSource({ApiClient? client})
      : apiClient = client ?? ApiClient(baseUrl: baseUrl);

  /// Search subjects with keyword, sort, filter (anime type: 2), and pagination.
  Future<List<AnimeSummary>> searchSubjects(
    String keyword, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final filterMap = <String, dynamic>{
      'type': [2], // 2 = Anime
    };
    if (tags != null && tags.isNotEmpty) {
      filterMap['tag'] = tags;
    }

    final response = await apiClient.dio.post(
      '$baseUrl/v0/search/subjects',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      data: {
        'keyword': keyword,
        'sort': sort.apiValue,
        'filter': filterMap,
      },
      cancelToken: cancelToken,
    );

    final rawData = response.data;
    if (rawData == null || rawData is! Map<String, dynamic>) {
      return [];
    }

    final list = rawData['data'] as List<dynamic>? ?? [];
    return list.map((item) => parseAnimeSummary(item as Map<String, dynamic>)).toList();
  }

  /// Get subject detail by ID.
  Future<AnimeDetail> getSubjectDetail(int id, {CancelToken? cancelToken}) async {
    final response = await apiClient.dio.get(
      '$baseUrl/v0/subjects/$id',
      cancelToken: cancelToken,
    );

    final data = response.data as Map<String, dynamic>;
    return parseAnimeDetail(data);
  }

  /// Get main episodes (type 0 = main episodes) for an anime.
  Future<List<Episode>> getEpisodes(int subjectId, {CancelToken? cancelToken}) async {
    final response = await apiClient.dio.get(
      '$baseUrl/v0/episodes',
      queryParameters: {
        'subject_id': subjectId,
        'type': 0, // 0 = Main story episodes
        'limit': 100,
      },
      cancelToken: cancelToken,
    );

    final rawData = response.data;
    if (rawData == null || rawData is! Map<String, dynamic>) {
      return [];
    }

    final list = rawData['data'] as List<dynamic>? ?? [];
    return list.map((item) => parseEpisode(item as Map<String, dynamic>)).toList();
  }

  /// Get subject relations and build an ordered season chain.
  Future<List<Season>> getRelations(int currentSubjectId, {CancelToken? cancelToken}) async {
    final response = await apiClient.dio.get(
      '$baseUrl/v0/subjects/$currentSubjectId/subjects',
      cancelToken: cancelToken,
    );

    final rawData = response.data;
    if (rawData == null || rawData is! List<dynamic>) {
      return [
        Season(
          id: currentSubjectId,
          name: 'Season 1',
          relation: 'Current',
          isCurrent: true,
        ),
      ];
    }

    // Filter to anime type 2 only (ignore manga, music, CDs)
    final animeRelations = rawData
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 2)
        .toList();

    return buildSeasonChain(currentSubjectId, animeRelations);
  }

  // --- Static parsing helpers with robust fallback and null safety ---

  static AnimeSummary parseAnimeSummary(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final original = json['name'] as String? ?? '';
    final localized = json['name_cn'] as String? ?? '';
    final english = extractEnglishTitle(json['infobox']);

    final titles = AnimeTitles(
      original: original.isNotEmpty ? original : localized,
      english: english,
      localized: localized.isNotEmpty ? localized : null,
    );

    final images = json['images'] as Map<String, dynamic>?;
    final posterUrl = images?['large'] as String? ??
        images?['common'] as String? ??
        images?['medium'] as String? ??
        images?['small'] as String? ??
        json['image'] as String?;

    final rating = json['rating'] as Map<String, dynamic>?;
    final score = (rating?['score'] as num?)?.toDouble();
    final ratingCount = rating?['total'] as int?;
    final rank = rating?['rank'] as int?;

    final collection = json['collection'] as Map<String, dynamic>?;
    int? heat;
    if (collection != null) {
      final doing = collection['doing'] as int? ?? 0;
      final collect = collection['collect'] as int? ?? 0;
      final wish = collection['wish'] as int? ?? 0;
      heat = doing + collect + wish;
    }

    final eps = json['eps'] as int? ?? json['total_episodes'] as int?;
    final airDate = json['date'] as String?;
    final platform = json['platform'] as String?;

    return AnimeSummary(
      id: id,
      titles: titles,
      posterUrl: posterUrl,
      score: score,
      ratingCount: ratingCount,
      rank: rank,
      eps: eps,
      heat: heat,
      airDate: airDate,
      platform: platform,
    );
  }

  static AnimeDetail parseAnimeDetail(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final original = json['name'] as String? ?? '';
    final localized = json['name_cn'] as String? ?? '';
    final english = extractEnglishTitle(json['infobox']);

    final titles = AnimeTitles(
      original: original.isNotEmpty ? original : localized,
      english: english,
      localized: localized.isNotEmpty ? localized : null,
    );

    final images = json['images'] as Map<String, dynamic>?;
    final posterUrl = images?['large'] as String? ??
        images?['common'] as String? ??
        images?['medium'] as String?;

    final rating = json['rating'] as Map<String, dynamic>?;
    final score = (rating?['score'] as num?)?.toDouble();
    final ratingCount = rating?['total'] as int?;
    final rank = rating?['rank'] as int?;

    final tagsRaw = json['tags'] as List<dynamic>? ?? [];
    final tags = tagsRaw
        .whereType<Map<String, dynamic>>()
        .map((t) => AnimeTag(
              name: t['name'] as String? ?? '',
              count: t['count'] as int? ?? 0,
            ))
        .where((t) => t.name.isNotEmpty)
        .toList();

    return AnimeDetail(
      id: id,
      titles: titles,
      posterUrl: posterUrl,
      summary: json['summary'] as String?,
      score: score,
      ratingCount: ratingCount,
      rank: rank,
      airDate: json['date'] as String?,
      eps: json['eps'] as int? ?? json['total_episodes'] as int?,
      platform: json['platform'] as String?,
      tags: tags,
    );
  }

  static Episode parseEpisode(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final epNum = (json['ep'] as num?)?.toDouble() ??
        (json['sort'] as num?)?.toDouble() ??
        1.0;
    final sort = json['sort'] as int? ?? epNum.toInt();

    final nameCn = json['name_cn'] as String? ?? '';
    final nameJp = json['name'] as String? ?? '';

    // Prefer localized title if available, otherwise original
    final title = nameCn.isNotEmpty
        ? nameCn
        : (nameJp.isNotEmpty ? nameJp : 'Episode ${epNum.toInt()}');

    return Episode(
      id: id,
      number: epNum,
      sort: sort,
      title: title,
      titleOriginal: nameJp.isNotEmpty ? nameJp : null,
      airDate: json['airdate'] as String?,
      duration: json['duration'] as String?,
      summary: json['desc'] as String?,
      type: json['type'] as int? ?? 0,
    );
  }

  /// Extracts English title from Bangumi infobox structure.
  static String? extractEnglishTitle(dynamic infobox) {
    if (infobox == null || infobox is! List<dynamic>) return null;

    for (final item in infobox) {
      if (item is Map<String, dynamic>) {
        final key = item['key'] as String? ?? '';

        // Check direct English key
        if (key == '英文名' || key == 'English') {
          final val = item['value'];
          if (val is String && val.trim().isNotEmpty) return val.trim();
        }

        // Check aliases ("别名") for ASCII/Latin title
        if (key == '别名') {
          final val = item['value'];
          if (val is List<dynamic>) {
            for (final v in val) {
              String? candidate;
              if (v is Map<String, dynamic>) {
                candidate = v['v'] as String?;
              } else if (v is String) {
                candidate = v;
              }
              if (candidate != null && _isPrimarilyLatin(candidate)) {
                return candidate.trim();
              }
            }
          } else if (val is String && _isPrimarilyLatin(val)) {
            return val.trim();
          }
        }
      }
    }
    return null;
  }

  /// Determines if a string consists primarily of Latin characters (English/Romaji).
  static bool _isPrimarilyLatin(String str) {
    if (str.isEmpty) return false;
    int latinCount = 0;
    int cjkCount = 0;
    for (final codeUnit in str.runes) {
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
          (codeUnit >= 0x0061 && codeUnit <= 0x007A) ||
          (codeUnit >= 0x0030 && codeUnit <= 0x0039)) {
        latinCount++;
      } else if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        cjkCount++;
      }
    }
    return latinCount > 3 && latinCount > cjkCount;
  }

  /// Reconstructs ordered seasons chain from relations list.
  static List<Season> buildSeasonChain(
    int currentId,
    List<Map<String, dynamic>> relations,
  ) {
    final prequels = <Season>[];
    final sequels = <Season>[];
    final others = <Season>[];

    for (final rel in relations) {
      final id = rel['id'] as int? ?? 0;
      final nameCn = rel['name_cn'] as String? ?? '';
      final name = rel['name'] as String? ?? '';
      final title = nameCn.isNotEmpty ? nameCn : name;
      final relationType = rel['relation'] as String? ?? '';

      final season = Season(
        id: id,
        name: title,
        originalName: name,
        relation: relationType,
        isCurrent: id == currentId,
      );

      if (relationType == '前传') {
        prequels.add(season);
      } else if (relationType == '续集') {
        sequels.add(season);
      } else {
        others.add(season);
      }
    }

    // Build the ordered chain
    final result = <Season>[];

    // 1. Prequels (ordered from oldest to nearest)
    for (int i = 0; i < prequels.length; i++) {
      result.add(prequels[i].copyWith(name: 'Season ${i + 1} (Prequel)'));
    }

    // 2. Current season
    final currentSeasonNumber = prequels.length + 1;
    result.add(Season(
      id: currentId,
      name: 'Season $currentSeasonNumber',
      relation: 'Current',
      isCurrent: true,
    ));

    // 3. Sequels
    for (int i = 0; i < sequels.length; i++) {
      final seqNum = currentSeasonNumber + 1 + i;
      result.add(sequels[i].copyWith(name: 'Season $seqNum'));
    }

    // 4. Movies / OVAs / Side stories
    for (final item in others) {
      final rel = item.relation ?? '';
      String label;
      if (rel.contains('剧场版') || rel.contains('Movie')) {
        label = 'Movie: ${item.name}';
      } else if (rel.contains('番外') || rel.contains('OVA')) {
        label = 'OVA: ${item.name}';
      } else {
        label = item.name;
      }
      result.add(item.copyWith(name: label));
    }

    return result;
  }
}
