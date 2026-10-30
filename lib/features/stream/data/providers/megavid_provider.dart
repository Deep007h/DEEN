import 'dart:async';
import 'package:dio/dio.dart';
import '../../../metadata/domain/models/anime_detail.dart';
import '../../domain/matching/title_matcher.dart';
import '../../domain/models/audio_language.dart';
import '../../domain/models/quality_option.dart';
import '../../domain/models/source_episode.dart';
import '../../domain/models/source_match.dart';
import '../../domain/models/stream_provider.dart';
import '../../domain/models/stream_variant.dart';
import '../../domain/models/subtitle_track.dart';
import '../../domain/resolvers/embed_stream_resolver.dart';

/// Stream provider for megavid.buzz (Anime Player - Embed API).
/// Directly supports AniList, MyAnimeList, and KissKH sources with live HLS streams,
/// multi-language WebVTT subtitles, and intro/outro timestamps.
class MegaVidProvider implements StreamProvider {
  final Dio _dio;
  final EmbedStreamResolver _embedResolver;
  static const String defaultBaseUrl = 'https://megavid.buzz';

  MegaVidProvider({Dio? client, EmbedStreamResolver? embedResolver})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: defaultBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'Referer': '$defaultBaseUrl/',
                  'User-Agent': EmbedStreamResolver.defaultUserAgent,
                  'Accept': 'application/json, text/plain, */*',
                },
              ),
            ),
        _embedResolver = embedResolver ??
            EmbedStreamResolver(
              client: client,
            );

  EmbedStreamResolver get embedResolver => _embedResolver;

  final Map<int, List<SourceMatch>> _matchMemoryCache = {};
  final Map<String, (List<StreamVariant>, DateTime)> _variantMemoryCache = {};
  final Map<String, List<SourceEpisode>> _episodeMemoryCache = {};
  final Map<String, bool> _dubAvailabilityCache = {};

  void clearCache() {
    _variantMemoryCache.clear();
    _episodeMemoryCache.clear();
    _dubAvailabilityCache.clear();
    _embedResolver.clearCache();
  }

  /// Checks if Dub track is available for this match on MegaVid/AniStream.
  Future<bool> checkDubExists(String id) async {
    if (_dubAvailabilityCache.containsKey(id)) {
      return _dubAvailabilityCache[id]!;
    }
    final cacheKey = '${id}_1';
    final cached = _variantMemoryCache[cacheKey];
    if (cached != null) {
      final hasDub = cached.$1.any((v) =>
          v.audio.isDub ||
          v.audio.code == AudioLanguage.englishDub.code ||
          v.audio.code == 'en');
      _dubAvailabilityCache[id] = hasDub;
      return hasDub;
    }

    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/ani/$id/1/dub',
        options: Options(
          headers: {
            'Referer': '$defaultBaseUrl/ani/$id/1/dub',
            'Origin': defaultBaseUrl,
            'User-Agent': EmbedStreamResolver.defaultUserAgent,
          },
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 2),
        ),
      );
      final exists = resp.data != null && resp.data!['success'] == true;
      _dubAvailabilityCache[id] = exists;
      return exists;
    } catch (_) {
      _dubAvailabilityCache[id] = false;
      return false;
    }
  }

  @override
  String get id => 'megavid';

  @override
  String get displayName => 'MegaVid (AniList / KissKH)';

  /// Map metadata entry to megavid.buzz catalog candidates.
  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    final cached = _matchMemoryCache[anime.id];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final isKDrama = anime.platform == 'K-Drama' ||
        anime.tags.any((t) => t.name.toLowerCase() == 'k-drama') ||
        anime.tags.any((t) => t.name.toLowerCase() == 'drama');
    if (isKDrama) {
      final matches = [
        SourceMatch(
          id: anime.id.toString(),
          title: anime.titles.preferredTitle(),
          providerId: id,
          episodeCount: anime.eps,
          confidenceScore: 1.0,
          customData: {
            'sourceType': 'kisskh',
            if (anime.posterUrl != null) 'thumb': anime.posterUrl,
          },
        ),
      ];
      _matchMemoryCache[anime.id] = matches;
      return matches;
    }

    final queries = <String>[];

    void addQuery(String? raw) {
      if (raw == null) return;
      final clean = _sanitizeQuery(raw);
      if (clean.isNotEmpty && !queries.contains(clean)) {
        queries.add(clean);
      }
    }

    // 1. English title
    addQuery(anime.titles.english);

    // 2. Preferred title
    addQuery(anime.titles.preferredTitle());

    // 3. Localized (Romaji / Chinese)
    addQuery(anime.titles.localized);

    // 4. Original (Japanese Kanji / Hiragana)
    addQuery(anime.titles.original);

    // 5. Base title prefixes (before Season, Part, colon, etc.)
    final titleForBase = anime.titles.english ?? anime.titles.preferredTitle();
    final baseMatch = RegExp(
      r'^(.*?)(?:\s*(?::| -| –| ~| Season| Part| 2nd| 3rd| 4th|\bS\d+\b|第\d+))',
      caseSensitive: false,
    ).firstMatch(titleForBase);
    if (baseMatch != null) {
      addQuery(baseMatch.group(1));
    }

    final origBaseMatch = RegExp(
      r'^(.*?)(?:\s*(?::| -| –| ~|～|〜| 1| 2| 3| 4|第\d+))',
      caseSensitive: false,
    ).firstMatch(anime.titles.original);
    if (origBaseMatch != null) {
      addQuery(origBaseMatch.group(1));
    }

    final matches = <SourceMatch>[];
    final seenIds = <String>{};

    // Parallel search across prioritized query titles for fastest match discovery
    final searchFutures = queries.take(3).map((q) async {
      try {
        final resp = await _dio.get<Map<String, dynamic>>(
          '/api/find',
          queryParameters: {'kind': 'anime', 'q': q},
        );
        return resp.data;
      } catch (_) {
        return null;
      }
    });

    final responses = await Future.wait(searchFutures);
    for (final data in responses) {
      if (data != null && data['results'] is List) {
        final list = data['results'] as List;
        for (final item in list) {
          if (item is! Map) continue;
          final map = item.cast<String, dynamic>();
          final matchId = (map['id'] ?? '').toString();
          if (matchId.isEmpty || seenIds.contains(matchId)) continue;
          seenIds.add(matchId);

          final candidateTitle = (map['title'] ?? '').toString();
          final candidateSub = (map['sub'] ?? '').toString();
          final candidateYear = map['year'] as int?;
          final candidateEps = map['episodes'] as int?;

          final score = TitleMatcher.scoreCandidate(
            anime: anime,
            candidateTitle: candidateTitle,
            candidateSub: candidateSub,
            candidateYear: candidateYear,
            candidateEpisodeCount: candidateEps,
          );

          matches.add(
            SourceMatch(
              id: matchId,
              title: candidateTitle,
              providerId: id,
              year: candidateYear,
              episodeCount: candidateEps ?? anime.eps,
              confidenceScore: score,
              customData: {
                'sourceType': 'ani',
                'sub': map['sub'],
                'thumb': map['thumb'],
                'format': map['format'],
              },
            ),
          );
        }
      }
    }

    // Sort descending by confidence score
    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    if (matches.isNotEmpty) {
      _matchMemoryCache[anime.id] = matches;
    }
    return matches;
  }

  /// Search K-Shows / Asian Dramas from megavid via KissKH.
  Future<List<SourceMatch>> searchKShows(String query, {CancelToken? cancelToken}) async {
    final cleanQuery = _sanitizeQuery(query);
    if (cleanQuery.isEmpty) return const [];

    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/find',
        queryParameters: {'kind': 'kshow', 'q': cleanQuery},
        cancelToken: cancelToken,
      );

      final data = resp.data;
      if (data != null && data['results'] is List) {
        final list = data['results'] as List;
        return list.map((item) {
          final map = (item as Map).cast<String, dynamic>();
          final matchId = (map['id'] ?? '').toString();
          return SourceMatch(
            id: matchId,
            title: (map['title'] ?? '').toString(),
            providerId: id,
            episodeCount: map['episodes'] as int?,
            confidenceScore: 0.9,
            customData: {
              'sourceType': 'kisskh',
              'thumb': map['thumb'],
            },
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Get episodes available for the match.
  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    final cached = _episodeMemoryCache[match.id];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final isKisskh = match.customData['sourceType'] == 'kisskh';

    if (isKisskh) {
      try {
        final resp = await _dio.get<Map<String, dynamic>>(
          '/api/kshow-eps',
          queryParameters: {'id': match.id},
        );

        final data = resp.data;
        if (data != null && data['episodes'] is List) {
          final eps = data['episodes'] as List;
          final result = eps.map((e) {
            final map = (e as Map).cast<String, dynamic>();
            final epId = (map['id'] ?? '').toString();
            final epNum = (map['number'] as num?)?.toInt() ?? 1;

            return SourceEpisode(
              id: epId,
              number: epNum,
              title: 'Episode $epNum',
              matchId: match.id,
              providerId: id,
              customData: {'kisskhEpId': epId},
            );
          }).toList();
          if (result.isNotEmpty) {
            result.sort((a, b) => a.number.compareTo(b.number));
            _episodeMemoryCache[match.id] = result;
            return result;
          }
        }
      } catch (_) {}

      // Fallback to kisskh.co directly
      try {
        final resp = await _dio.get<Map<String, dynamic>>(
          'https://kisskh.co/api/DramaList/Drama/${match.id}',
          options: Options(
            headers: {'Referer': 'https://kisskh.co/'},
          ),
        );
        final data = resp.data;
        if (data != null && data['episodes'] is List) {
          final eps = data['episodes'] as List;
          final result = <SourceEpisode>[];
          for (final item in eps) {
            if (item is! Map) continue;
            final map = item.cast<String, dynamic>();
            final epId = (map['id'] ?? '').toString();
            final numVal = (map['number'] as num?)?.toDouble() ?? 1.0;
            final epNum = numVal.toInt();
            result.add(
              SourceEpisode(
                id: epId,
                number: epNum,
                title: 'Episode $epNum',
                matchId: match.id,
                providerId: id,
                customData: {'kisskhEpId': epId},
              ),
            );
          }
          if (result.isNotEmpty) {
            result.sort((a, b) => a.number.compareTo(b.number));
            _episodeMemoryCache[match.id] = result;
            return result;
          }
        }
      } catch (_) {}
    }

    // Default Anime (AniList / MAL) episode list
    final total = match.episodeCount ?? 12;
    final result = List.generate(total, (i) {
      final epNum = i + 1;
      return SourceEpisode(
        id: '${match.id}_$epNum',
        number: epNum,
        title: 'Episode $epNum',
        matchId: match.id,
        providerId: id,
        customData: {'sourceType': 'ani', 'anilistId': match.id},
      );
    });
    _episodeMemoryCache[match.id] = result;
    return result;
  }

  /// Resolves playable stream variants (Sub, Dub, WebVTT subtitles, Intro/Outro skip).
  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    final kisskhEpId = episode.customData['kisskhEpId']?.toString();

    // 1. Resolve KissKH stream (for K-Shows / Dramas)
    if (kisskhEpId != null && kisskhEpId.isNotEmpty) {
      final variant = await _resolveKissKh(kisskhEpId);
      if (variant != null) return [variant];
    }

    final cacheKey = '${episode.matchId}_${episode.number}';
    final preferredAudio = episode.customData['preferredAudio']?.toString().toLowerCase();
    final prefersDub = preferredAudio == AudioLanguage.englishDub.code ||
        preferredAudio == 'dub' ||
        preferredAudio == 'en' ||
        preferredAudio == 'english';
    final targetAudioCode = prefersDub ? AudioLanguage.englishDub.code : AudioLanguage.japaneseOriginal.code;

    final cached = _variantMemoryCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.$2).inMinutes < 5 && cached.$1.isNotEmpty) {
      final hasBrokenDub = cached.$1.any((v) =>
          v.audio.code == AudioLanguage.englishDub.code &&
          v.url.contains('WUQWQEVZS0xXBhVX'));
      final hasTarget = cached.$1.any((v) => v.audio.code == targetAudioCode);
      if (!hasBrokenDub && (hasTarget || cached.$1.length > 1)) {
        return cached.$1;
      }
    }

    final variants = <StreamVariant>[];
    final anilistId = episode.matchId;
    final epNum = episode.number;

    final primaryLang = prefersDub ? 'dub' : 'sub';
    final secondaryLang = prefersDub ? 'sub' : 'dub';

    // Start primary and secondary requests concurrently
    final primaryFuture = _resolveAniStream(anilistId, epNum, primaryLang);
    final secondaryFuture = _resolveAniStream(anilistId, epNum, secondaryLang);

    // 1. Wait for primary track with a 5-second timeout
    StreamVariant? primaryVariant;
    try {
      primaryVariant = await primaryFuture.timeout(const Duration(seconds: 5));
    } catch (_) {
      primaryVariant = null;
    }

    if (primaryVariant != null) {
      variants.add(primaryVariant);

      // Wait up to 200ms for secondary track (Dub / Sub) if immediately available
      try {
        final secondaryVariant = await secondaryFuture.timeout(
          const Duration(milliseconds: 200),
        );
        if (secondaryVariant != null && !variants.any((v) => v.audio.code == secondaryVariant.audio.code)) {
          variants.add(secondaryVariant);
        }
      } catch (_) {
        // If secondary took longer than 200ms, populate cache in background when it arrives
        secondaryFuture.then((sec) {
          if (sec != null) {
            final existing = _variantMemoryCache[cacheKey]?.$1 ?? [primaryVariant!];
            if (!existing.any((v) => v.audio.code == sec.audio.code)) {
              _variantMemoryCache[cacheKey] = ([...existing, sec], DateTime.now());
            }
          }
        }).catchError((_) {});
      }
    } else {
      // Primary track failed or timed out: wait for secondary track as fallback
      try {
        final secondaryVariant = await secondaryFuture.timeout(const Duration(seconds: 5));
        if (secondaryVariant != null) {
          variants.add(secondaryVariant);
        }
      } catch (_) {}
    }

    // 2. Final fallback if still empty
    if (variants.isEmpty) {
      final fallbackVariant = await _resolveSourceFallback(anilistId, epNum, primaryLang);
      if (fallbackVariant != null) {
        variants.add(fallbackVariant);
      } else {
        final secFallback = await _resolveSourceFallback(anilistId, epNum, secondaryLang);
        if (secFallback != null) variants.add(secFallback);
      }
    }

    if (variants.isNotEmpty) {
      _variantMemoryCache[cacheKey] = (variants, DateTime.now());
    }

    return variants;
  }

  StreamVariant? _buildVariantFromData(
    Map<String, dynamic>? data,
    String id,
    int ep,
    String lang,
    AudioLanguage audio, {
    String? embedUrl,
  }) {
    if (data == null) return null;
    final streamUrl = (data['source'] ?? data['Video'])?.toString();
    if (streamUrl == null || streamUrl.isEmpty) return null;

    // Allow MegaVid /vid/ streams (production endpoint)

    // Permanently ban broken 'yuki' provider on cdnx.aniwatchtv.site for DUB
    final provider = (data['provider'] ?? '').toString().toLowerCase();
    if (lang == 'dub' && (provider == 'yuki' || streamUrl.contains('cdnx.aniwatchtv.site'))) {
      return null;
    }

    final tracks = _parseSubtitleTracks(data['tracks']);
    final intro = _parseChapters(data['chapters'], 'intro') ?? _parseTimeRange(data['intro']);
    final outro = _parseChapters(data['chapters'], 'outro') ?? _parseTimeRange(data['outro']);
    final canonicalReferer = embedUrl ??
        EmbedStreamResolver.buildEmbedUrl(
          animeId: id,
          episodeNumber: ep,
          audio: lang,
        );

    return StreamVariant(
      url: streamUrl,
      headers: {
        'Referer': canonicalReferer,
        'Origin': defaultBaseUrl,
        'User-Agent': EmbedStreamResolver.defaultUserAgent,
      },
      audio: audio,
      subtitles: tracks,
      qualities: _defaultHlsQualities(streamUrl),
      introStart: intro?.$1,
      introEnd: intro?.$2,
      outroStart: outro?.$1,
      outroEnd: outro?.$2,
    );
  }

  Future<StreamVariant?> _raceFirstNonNull(List<Future<StreamVariant?>> futures) async {
    final completer = Completer<StreamVariant?>();
    var remaining = futures.length;

    for (final future in futures) {
      future.then((variant) {
        if (!completer.isCompleted) {
          if (variant != null) {
            completer.complete(variant);
          } else {
            remaining--;
            if (remaining <= 0) completer.complete(null);
          }
        }
      }).catchError((_) {
        if (!completer.isCompleted) {
          remaining--;
          if (remaining <= 0) completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  Future<StreamVariant?> _resolveAniStream(String id, int ep, String lang) async {
    final canonicalEmbedUrl = EmbedStreamResolver.buildEmbedUrl(
      animeId: id,
      episodeNumber: ep,
      audio: lang,
    );

    // Concurrently probe direct high-speed CDN mirrors using the test project's
    final isDub = lang == 'dub';
    final directProbes = <Future<StreamVariant?>>[
      if (isDub) ...[
        // 1. Primary verified DUB provider (loli on echovideo.to - zero 403 blocks)
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl, serverOverride: 'loli');
          return res?.variant;
        }(),
        // 2. Direct production CDN endpoint
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl);
          return res?.variant;
        }(),
      ] else ...[
        // 1. Primary high-speed verified CDN mirror (?axsv=zuna)
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl, serverOverride: 'zuna');
          return res?.variant;
        }(),
        // 2. Alternative server mirror (?axsv=loli)
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl, serverOverride: 'loli');
          return res?.variant;
        }(),
        // 3. Alternative verified server mirror (?axsv=sora)
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl, serverOverride: 'sora');
          return res?.variant;
        }(),
        // 4. Direct production CDN endpoint (/ani/{id}/{ep}/{lang}/source)
        () async {
          final res = await _embedResolver.resolveEmbedUrl(canonicalEmbedUrl);
          return res?.variant;
        }(),
      ],
      // Direct /api/ani route with canonical Referer
      () async {
        try {
          final resp = await _dio.get<Map<String, dynamic>>(
            '/api/ani/$id/$ep/$lang',
            options: Options(
              headers: {
                'Referer': canonicalEmbedUrl,
                'Origin': defaultBaseUrl,
                'User-Agent': EmbedStreamResolver.defaultUserAgent,
              },
              receiveTimeout: const Duration(seconds: 4),
              sendTimeout: const Duration(seconds: 3),
            ),
          );
          final audio = isDub ? AudioLanguage.englishDub : AudioLanguage.japaneseOriginal;
          return _buildVariantFromData(resp.data, id, ep, lang, audio, embedUrl: canonicalEmbedUrl);
        } catch (_) {
          return null;
        }
      }(),
    ];

    final directResult = await _raceFirstNonNull(directProbes);
    if (directResult != null) {
      return directResult;
    }

    return null;
  }

  Future<StreamVariant?> _resolveKissKh(String episodeId) async {
    final kisskhEmbedUrl = EmbedStreamResolver.buildKisskhUrl(episodeId);
    final res = await _embedResolver.resolveEmbedUrl(kisskhEmbedUrl);
    return res?.variant;
  }

  Future<StreamVariant?> _resolveSourceFallback(String id, int ep, String lang) async {
    final canonicalEmbedUrl = EmbedStreamResolver.buildEmbedUrl(
      animeId: id,
      episodeNumber: ep,
      audio: lang,
    );
    final isDub = lang == 'dub';
    final res = await _embedResolver.resolveEmbedUrl(
      canonicalEmbedUrl,
      serverOverride: isDub ? 'loli' : 'zuna',
    );
    return res?.variant;
  }

  List<SubtitleTrack> _parseSubtitleTracks(dynamic rawTracks) {
    return EmbedStreamResolver.parseSubtitleTracks(rawTracks, baseUrl: defaultBaseUrl);
  }

  (double, double)? _parseChapters(dynamic chapters, String kind) {
    if (chapters is! List) return null;
    for (final c in chapters) {
      if (c is Map) {
        final title = (c['title'] ?? '').toString().toLowerCase();
        if (title.contains(kind.toLowerCase())) {
          final start = (c['start'] as num?)?.toDouble() ?? 0.0;
          final end = (c['end'] as num?)?.toDouble() ?? 0.0;
          if (end > start) return (start, end);
        }
      }
    }
    return null;
  }

  (double, double)? _parseTimeRange(dynamic range) {
    if (range is! Map) return null;
    final start = (range['start'] as num?)?.toDouble();
    final end = (range['end'] as num?)?.toDouble();
    if (start != null && end != null && end > start) {
      return (start, end);
    }
    return null;
  }

  List<QualityOption> _defaultHlsQualities(String masterUrl) {
    return [
      const QualityOption(label: 'Auto (Adaptive)', height: 1080, isAuto: true),
      QualityOption(label: '1080p', height: 1080, bandwidth: 5000000, url: masterUrl),
      QualityOption(label: '720p', height: 720, bandwidth: 2800000, url: masterUrl),
      QualityOption(label: '480p', height: 480, bandwidth: 1400000, url: masterUrl),
      QualityOption(label: '360p', height: 360, bandwidth: 800000, url: masterUrl),
    ];
  }



  String _sanitizeQuery(String raw) {
    var s = raw;
    // Normalize Roman numerals
    s = s.replaceAll('ⅰ', ' 1 ').replaceAll('ⅱ', ' 2 ').replaceAll('ⅲ', ' 3 ')
         .replaceAll('ⅳ', ' 4 ').replaceAll('ⅴ', ' 5 ');
    s = s.replaceAll('Ⅰ', ' 1 ').replaceAll('Ⅱ', ' 2 ').replaceAll('Ⅲ', ' 3 ')
         .replaceAll('Ⅳ', ' 4 ').replaceAll('Ⅴ', ' 5 ');
    // Standardize CJK and English season/part keywords
    s = s.replaceAllMapped(RegExp(r'第\s*(\d+)\s*[季期部分クール]'), (m) => ' s${m[1]} ');
    s = s.replaceAllMapped(RegExp(r'\bseason\s*(\d+)\b', caseSensitive: false), (m) => ' s${m[1]} ');
    // Standardize fullwidth tilde, dash, colon
    s = s.replaceAll(RegExp(r'[～〜~：:–—\-_]'), ' ');
    // Strip non-alphanumeric, non-CJK, non-Hangul
    s = s.replaceAll(RegExp(r'[^\w\s\u4e00-\u9fa5\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
