import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../metadata/domain/models/anime_detail.dart';
import '../../domain/matching/title_matcher.dart';
import '../../domain/models/audio_language.dart';
import '../../domain/models/quality_option.dart';
import '../../domain/models/source_episode.dart';
import '../../domain/models/source_match.dart';
import '../../domain/models/stream_provider.dart';
import '../../domain/models/stream_variant.dart';
import '../hls/hls_parser.dart';

/// Stream provider for Animelok (animelok.cc / ravok.buzz / AnimeSalt cluster).
/// Uses native AniList IDs directly, extracts Multi-1 multi-audio streams (Hindi,
/// Tamil, Telugu, English, Japanese), and provides adaptive multi-bitrate HLS playback.
class AnimelokProvider implements StreamProvider {
  final Dio _dio;

  static const String baseUrl = 'https://animelok.cc';
  static const String ravokBaseUrl = 'https://ravok.buzz';

  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://animelok.cc/',
    'Accept': 'application/json',
  };

  AnimelokProvider({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                headers: defaultHeaders,
              ),
            );

  final Map<int, List<SourceMatch>> _matchCache = {};
  final Map<String, List<SourceEpisode>> _episodeCache = {};
  final Map<String, List<StreamVariant>> _variantCache = {};

  void clearCache() {
    _matchCache.clear();
    _episodeCache.clear();
    _variantCache.clear();
  }

  @override
  String get id => 'animelok';

  @override
  String get displayName => 'Animelok (Multi-Audio HLS / Hindi)';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    if (_matchCache.containsKey(anime.id)) {
      return _matchCache[anime.id]!;
    }

    // 1. Direct AniList ID Check: Animelok endpoints accept AniList IDs natively
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/anilist/${anime.id}/1',
        options: Options(headers: defaultHeaders),
      );

      final data = resp.data;
      if (data != null && data['success'] == true) {
        final servers = data['servers'] as List? ?? [];
        final hasRavok = servers.any(
          (s) =>
              s is Map &&
              (s['server'] == 'Multi-1' ||
                  (s['url'] != null && s['url'].toString().contains('ravok.buzz'))),
        );

        if (hasRavok) {
          final directMatch = SourceMatch(
            id: anime.id.toString(),
            title: anime.titles.preferredTitle(),
            providerId: id,
            episodeCount: (anime.eps ?? 0) > 0 ? anime.eps! : 24,
            confidenceScore: 1.0,
            customData: {
              'anilistId': anime.id,
              'sourceType': 'animelok_direct',
            },
          );
          _matchCache[anime.id] = [directMatch];
          return [directMatch];
        }
      }
    } catch (_) {
      // Fallback to title search if direct check encounters network error or 404
    }

    // 2. Title Search Fallback
    final titlesToTry = <String>{
      anime.titles.preferredTitle(),
      if (anime.titles.english != null && anime.titles.english!.isNotEmpty) anime.titles.english!,
      if (anime.titles.localized != null && anime.titles.localized!.isNotEmpty) anime.titles.localized!,
    }.toList();

    final matches = <SourceMatch>[];
    final seenIds = <String>{};

    for (final title in titlesToTry) {
      if (title.trim().isEmpty) continue;
      try {
        final resp = await _dio.get<Map<String, dynamic>>(
          '$baseUrl/api/search',
          queryParameters: {'q': title},
          options: Options(headers: defaultHeaders),
        );

        final data = resp.data;
        if (data != null && data['results'] is List) {
          final results = data['results'] as List;
          for (final item in results) {
            if (item is! Map) continue;
            final map = item.cast<String, dynamic>();
            final anilistId = map['anilist_id']?.toString() ?? '';
            if (anilistId.isEmpty || seenIds.contains(anilistId)) continue;
            seenIds.add(anilistId);

            final titleObj = map['title'] is Map ? map['title'] as Map : {};
            final candidateTitle = titleObj['english']?.toString() ??
                titleObj['romaji']?.toString() ??
                titleObj['native']?.toString() ??
                '';
            final epCount = (map['episodes'] as num?)?.toInt() ?? anime.eps;

            final score = TitleMatcher.scoreCandidate(
              anime: anime,
              candidateTitle: candidateTitle,
              candidateEpisodeCount: epCount,
            );

            matches.add(
              SourceMatch(
                id: anilistId,
                title: candidateTitle.isNotEmpty ? candidateTitle : anime.titles.preferredTitle(),
                providerId: id,
                episodeCount: (epCount ?? 0) > 0 ? epCount! : (anime.eps ?? 24),
                confidenceScore: score,
                customData: {
                  'anilistId': anilistId,
                  'sourceType': 'animelok_search',
                },
              ),
            );
          }
        }
      } catch (_) {}

      if (matches.any((m) => m.confidenceScore >= 0.80)) {
        break;
      }
    }

    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    if (matches.isNotEmpty) {
      _matchCache[anime.id] = matches;
    }
    return matches;
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    final cached = _episodeCache[match.id];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final totalEps = (match.episodeCount ?? 0) > 0 ? match.episodeCount! : 24;
    final result = <SourceEpisode>[];

    for (int i = 1; i <= totalEps; i++) {
      result.add(
        SourceEpisode(
          id: '${match.id}_$i',
          number: i,
          title: 'Episode $i',
          matchId: match.id,
          providerId: id,
          customData: {
            'anilistId': match.id,
            'epNum': i,
          },
        ),
      );
    }

    _episodeCache[match.id] = result;
    return result;
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    final cacheKey = '${episode.matchId}_${episode.number}';
    final cached = _variantCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 1. Fetch servers list from Animelok API
    final anilistId = episode.customData['anilistId'] ?? episode.matchId;
    final epNum = episode.number;

    final resp = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/api/anilist/$anilistId/$epNum',
      options: Options(headers: defaultHeaders),
    );

    final data = resp.data;
    if (data == null || data['servers'] is! List) {
      throw Exception('Failed to load servers for Animelok episode $epNum');
    }

    final servers = (data['servers'] as List).whereType<Map>().toList();

    // 2. Identify Multi-1 (AnimeSalt / Ravok) server
    Map? targetServer;
    for (final s in servers) {
      final sName = s['server']?.toString();
      final sUrl = s['url']?.toString() ?? '';
      if (sName == 'Multi-1' || sUrl.contains('ravok.buzz')) {
        targetServer = s;
        break;
      }
    }

    if (targetServer == null) {
      throw Exception('No playable Multi-1 / Ravok server available for Animelok episode $epNum');
    }

    final rawUrl = targetServer['url']?.toString() ?? '';
    final hash = rawUrl.split('/').last.trim();
    if (hash.isEmpty || !rawUrl.contains('ravok.buzz')) {
      throw Exception('Invalid Ravok video URL on Animelok server: $rawUrl');
    }

    // 3. Request videoSource from Ravok player API
    final postUrl = '$ravokBaseUrl/player/index.php?data=$hash&do=getVideo';
    final refEncoded = Uri.encodeComponent('$baseUrl/');
    final postBody = 'hash=$hash&r=$refEncoded';

    final ravokResp = await _dio.post<dynamic>(
      postUrl,
      data: postBody,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': '$ravokBaseUrl/',
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
      ),
    );

    Map<String, dynamic>? ravokData;
    if (ravokResp.data is Map) {
      ravokData = (ravokResp.data as Map).cast<String, dynamic>();
    } else if (ravokResp.data is String) {
      try {
        final decoded = jsonDecode(ravokResp.data as String);
        if (decoded is Map) {
          ravokData = decoded.cast<String, dynamic>();
        }
      } catch (_) {}
    }

    final videoSource = ravokData?['videoSource']?.toString() ??
        ravokData?['securedLink']?.toString();

    if (videoSource == null || videoSource.isEmpty) {
      throw Exception('Ravok did not return a valid videoSource for hash: $hash');
    }

    // 4. Fetch and parse master HLS playlist for audios and qualities
    List<QualityOption> qualities = const [];
    final detectedAudios = <AudioLanguage>[];

    try {
      final masterResp = await _dio.get<String>(
        videoSource,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36',
            'Referer': '$ravokBaseUrl/',
          },
          responseType: ResponseType.plain,
        ),
      );

      final masterContent = masterResp.data ?? '';
      qualities = HlsParser.parse(masterContent, baseUrl: videoSource);

      // Parse audio language tracks from #EXT-X-MEDIA:TYPE=AUDIO
      for (final line in masterContent.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXT-X-MEDIA:') && trimmed.contains('TYPE=AUDIO')) {
          final langMatch = RegExp(r'LANGUAGE="([^"]+)"', caseSensitive: false).firstMatch(trimmed);
          final nameMatch = RegExp(r'NAME="([^"]+)"', caseSensitive: false).firstMatch(trimmed);
          final langCode = langMatch?.group(1)?.toLowerCase() ?? '';
          final name = nameMatch?.group(1) ?? '';
          final normalized = _normalizeAudioLanguage(langCode, name);
          if (normalized != null && !detectedAudios.any((a) => a.code == normalized.code)) {
            detectedAudios.add(normalized);
          }
        }
      }
    } catch (_) {
      // Fallback default qualities
      qualities = _defaultHlsQualities(videoSource);
    }

    if (qualities.isEmpty) {
      qualities = _defaultHlsQualities(videoSource);
    }

    // Ensure common audio tracks if parser failed to extract them
    if (detectedAudios.isEmpty) {
      detectedAudios.addAll([
        AudioLanguage.hindiDub,
        AudioLanguage.japaneseOriginal,
        AudioLanguage.englishDub,
      ]);
    }

    final headers = {
      'Referer': '$ravokBaseUrl/',
      'Origin': ravokBaseUrl,
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
    };

    final variants = <StreamVariant>[];
    for (final audio in detectedAudios) {
      variants.add(
        StreamVariant(
          url: videoSource,
          headers: headers,
          audio: audio,
          qualities: qualities,
        ),
      );
    }

    if (variants.isNotEmpty) {
      _variantCache[cacheKey] = variants;
    }
    return variants;
  }

  AudioLanguage? _normalizeAudioLanguage(String code, String name) {
    final c = code.toLowerCase();
    final n = name.toLowerCase();
    if (c == 'hin' || n.contains('hindi')) return AudioLanguage.hindiDub;
    if (c == 'eng' || n.contains('english')) return AudioLanguage.englishDub;
    if (c == 'jpn' || c == 'ja' || n.contains('japanese')) return AudioLanguage.japaneseOriginal;
    if (c == 'tam' || n.contains('tamil')) return const AudioLanguage(code: 'ta', label: 'Tamil Dub');
    if (c == 'tel' || n.contains('telugu')) return const AudioLanguage(code: 'te', label: 'Telugu Dub');
    if (c == 'kan' || n.contains('kannada')) return const AudioLanguage(code: 'kn', label: 'Kannada Dub');
    if (c == 'mal' || n.contains('malayalam')) return const AudioLanguage(code: 'ml', label: 'Malayalam Dub');
    return AudioLanguage(code: code, label: name);
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
}
