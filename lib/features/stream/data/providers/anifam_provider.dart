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

/// Stream provider for AniFam (anifam.net / dramahot / megaplay cluster).
/// Uses dynamic mirror rotation, direct multi-bitrate HLS master streams,
/// hotlink media_headers forwarding, VTT subtitles, and intro/outro timestamps.
class AniFamProvider implements StreamProvider {
  final Dio _dio;
  static const List<String> defaultMirrors = [
    'https://anifam.net',
    'https://app.anifam.net',
    'https://anifam.buzz',
    'https://anifam.top',
    'https://anifam.cfd',
  ];

  final List<String> _mirrors;
  int _activeMirrorIndex = 0;

  static const Map<String, String> requiredHeaders = {
    'Accept': 'application/json',
    'X-App-Version': '20',
    'X-App-Platform': 'android',
    'User-Agent': 'AniFam/0.2.9 (Linux; Android 14)',
  };

  AniFamProvider({Dio? client, List<String>? mirrors})
      : _mirrors = mirrors ?? List<String>.from(defaultMirrors),
        _dio = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 6),
                headers: requiredHeaders,
              ),
            );

  String get currentBaseUrl => _mirrors[_activeMirrorIndex];

  final Map<int, List<SourceMatch>> _matchCache = {};
  final Map<String, List<SourceEpisode>> _episodeCache = {};
  final Map<String, (List<StreamVariant>, DateTime)> _variantCache = {};

  void clearCache() {
    _matchCache.clear();
    _episodeCache.clear();
    _variantCache.clear();
  }

  @override
  String get id => 'anifam';

  @override
  String get displayName => 'AniFam (Fast HLS / Multi-Mirror)';

  /// Performs an HTTP GET with automatic mirror rotation on failure.
  Future<Response<T>> _requestWithFailover<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    DioException? lastException;
    final startIndex = _activeMirrorIndex;

    for (int i = 0; i < _mirrors.length; i++) {
      final mirrorIndex = (startIndex + i) % _mirrors.length;
      final baseUrl = _mirrors[mirrorIndex];
      final fullUrl = '$baseUrl$path';

      try {
        final options = Options(
          method: method,
          headers: requiredHeaders,
        );
        final response = method == 'POST'
            ? await _dio.post<T>(fullUrl, data: data, queryParameters: queryParameters, options: options)
            : await _dio.get<T>(fullUrl, queryParameters: queryParameters, options: options);

        if (response.statusCode == 200 && response.data != null) {
          _activeMirrorIndex = mirrorIndex; // Sticky successful mirror
          return response;
        }
      } on DioException catch (e) {
        lastException = e;
        // Continue to next mirror
      } catch (e) {
        lastException = DioException(
          requestOptions: RequestOptions(path: fullUrl),
          error: e,
        );
      }
    }

    throw lastException ??
        DioException(
          requestOptions: RequestOptions(path: path),
          error: 'All AniFam mirrors failed',
        );
  }

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    if (_matchCache.containsKey(anime.id)) {
      return _matchCache[anime.id]!;
    }

    final titlesToTry = <String>{
      anime.titles.preferredTitle(),
      if (anime.titles.english != null && anime.titles.english!.isNotEmpty) anime.titles.english!,
      if (anime.titles.localized != null && anime.titles.localized!.isNotEmpty) anime.titles.localized!,
      anime.titles.original,
    }.toList();

    final matches = <SourceMatch>[];
    final seenIds = <String>{};

    for (final title in titlesToTry) {
      if (title.trim().isEmpty) continue;
      try {
        final resp = await _requestWithFailover<Map<String, dynamic>>(
          '/api/v1/app/search',
          queryParameters: {'q': title, 'page': 1},
        );

        final rawData = resp.data?['data'];
        final list = rawData is List ? rawData : (resp.data is List ? resp.data as List : []);

        for (final item in list) {
          if (item is! Map) continue;
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.contains(id)) continue;
          seenIds.add(id);

          final candidateTitle = item['title']?.toString() ?? '';
          final epCount = (item['eps'] as num?)?.toInt() ?? (item['sub'] as num?)?.toInt() ?? anime.eps;
          final score = (item['score'] as num?)?.toDouble();

          final confidence = TitleMatcher.scoreCandidate(
            anime: anime,
            candidateTitle: candidateTitle,
            candidateEpisodeCount: epCount,
          );

          matches.add(
            SourceMatch(
              id: id,
              title: candidateTitle,
              providerId: this.id,
              episodeCount: epCount,
              confidenceScore: confidence,
              customData: {
                'poster': item['poster'],
                'slug': item['slug'],
                'score': score,
                'type': item['type'],
                'sub': item['sub'],
                'dub': item['dub'],
              },
            ),
          );
        }

        if (matches.any((m) => m.confidenceScore >= 0.75)) {
          break; // High confidence match found
        }
      } catch (_) {}
    }

    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    _matchCache[anime.id] = matches;
    return matches;
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    if (_episodeCache.containsKey(match.id)) {
      return _episodeCache[match.id]!;
    }

    final resp = await _requestWithFailover<Map<String, dynamic>>(
      '/api/v1/app/anime/${match.id}/episodes',
    );

    final rawData = resp.data?['data'];
    final list = rawData is List ? rawData : (resp.data is List ? resp.data as List : []);

    final result = <SourceEpisode>[];
    for (final item in list) {
      if (item is! Map) continue;
      final epId = item['id']?.toString() ?? '';
      final numVal = (item['number'] as num?)?.toInt() ?? (result.length + 1);
      final title = item['title']?.toString() ?? 'Episode $numVal';

      result.add(
        SourceEpisode(
          id: epId,
          number: numVal,
          title: title,
          matchId: match.id,
          providerId: id,
          customData: {
            'has_sub': item['has_sub'] == true,
            'has_dub': item['has_dub'] == true,
            'is_filler': item['is_filler'] == true,
            'thumbnail': item['thumbnail'],
          },
        ),
      );
    }

    _episodeCache[match.id] = result;
    return result;
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    final effectiveAudio = episode.customData['preferredAudio']?.toString() ?? 'ja';
    final prefersDub = effectiveAudio == 'en' || effectiveAudio == AudioLanguage.englishDub.code;
    final track = prefersDub ? 'dub' : 'sub';
    final cacheKey = '${episode.id}_$track';

    final cached = _variantCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.$2).inMinutes < 15) {
      return cached.$1;
    }

    final resp = await _requestWithFailover<Map<String, dynamic>>(
      '/api/v1/app/episodes/${episode.id}/play',
      method: 'POST',
      data: {'track': track},
    );

    final data = resp.data ?? {};
    final sources = (data['sources'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

    final variants = <StreamVariant>[];

    // 1. Process direct HLS source
    for (final src in sources) {
      final kind = src['kind']?.toString();
      final url = src['url']?.toString();
      if (kind == 'hls' && url != null && url.isNotEmpty) {
        final mediaHeaders = (src['media_headers'] as Map?)?.cast<String, String>() ?? {};
        final subtitles = _parseSubtitles(src['subtitles']);
        final qualities = _parseQualities(src['qualities']);
        final (introStart, introEnd, outroStart, outroEnd) = _parseSkip(src['skip']);

        variants.add(
          StreamVariant(
            url: url,
            headers: {
              ...mediaHeaders,
              'User-Agent': mediaHeaders['User-Agent'] ?? requiredHeaders['User-Agent']!,
              if (mediaHeaders['Referer'] != null) 'Referer': mediaHeaders['Referer']!,
            },
            audio: prefersDub ? AudioLanguage.englishDub : AudioLanguage.japaneseOriginal,
            subtitles: subtitles,
            qualities: qualities,
            introStart: introStart,
            introEnd: introEnd,
            outroStart: outroStart,
            outroEnd: outroEnd,
          ),
        );
      }
    }

    // 2. Process resolvable upstream servers concurrently to eliminate sequential waiting
    final resolvableSources = sources.where((s) => s['resolvable'] == true && s['server_id'] != null).toList();
    if (resolvableSources.isNotEmpty) {
      final futures = resolvableSources.take(2).map((src) async {
        final serverId = src['server_id'];
        try {
          final resolveResp = await _requestWithFailover<Map<String, dynamic>>(
            '/api/v1/app/episodes/${episode.id}/resolve',
            method: 'POST',
            data: {
              'server_id': serverId,
              'track': track,
            },
          ).timeout(const Duration(milliseconds: 1800));

          final rData = resolveResp.data ?? {};
          final rUrl = rData['url']?.toString();
          if (rUrl != null && rUrl.isNotEmpty) {
            final mediaHeaders = (rData['media_headers'] as Map?)?.cast<String, String>() ?? {};
            final subtitles = _parseSubtitles(rData['subtitles']);
            final qualities = _parseQualities(rData['qualities']);
            final (introStart, introEnd, outroStart, outroEnd) = _parseSkip(rData['skip']);

            return StreamVariant(
              url: rUrl,
              headers: {
                ...mediaHeaders,
                'User-Agent': mediaHeaders['User-Agent'] ?? requiredHeaders['User-Agent']!,
                if (mediaHeaders['Referer'] != null) 'Referer': mediaHeaders['Referer']!,
                if (mediaHeaders['Origin'] != null) 'Origin': mediaHeaders['Origin']!,
              },
              audio: prefersDub ? AudioLanguage.englishDub : AudioLanguage.japaneseOriginal,
              subtitles: subtitles,
              qualities: qualities,
              introStart: introStart,
              introEnd: introEnd,
              outroStart: outroStart,
              outroEnd: outroEnd,
            );
          }
        } catch (_) {}
        return null;
      });

      final resolved = await Future.wait(futures);
      for (final v in resolved) {
        if (v != null) {
          variants.add(v);
        }
      }
    }

    if (variants.isNotEmpty) {
      _variantCache[cacheKey] = (variants, DateTime.now());
    }

    return variants;
  }

  List<SubtitleTrack> _parseSubtitles(dynamic raw) {
    if (raw is! List) return const [];
    final list = <SubtitleTrack>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final lang = item['lang']?.toString() ?? 'en';
      final label = item['label']?.toString() ?? 'English';
      final url = item['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        list.add(
          SubtitleTrack(
            id: lang,
            languageCode: lang,
            label: label,
            url: url,
            format: url.endsWith('.ass') ? SubtitleFormat.ass : SubtitleFormat.vtt,
            isDefault: item['default'] == true,
          ),
        );
      }
    }
    return list;
  }

  List<QualityOption> _parseQualities(dynamic raw) {
    if (raw is! List) return const [];
    final list = <QualityOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final height = (item['height'] as num?)?.toInt();
      final bandwidth = (item['bandwidth'] as num?)?.toInt();
      if (height != null && height > 0) {
        list.add(
          QualityOption(
            label: '${height}p',
            height: height,
            bandwidth: bandwidth,
          ),
        );
      }
    }
    return list;
  }

  (double?, double?, double?, double?) _parseSkip(dynamic raw) {
    if (raw is! Map) return (null, null, null, null);
    double? introStart;
    double? introEnd;
    double? outroStart;
    double? outroEnd;

    final intro = raw['intro'];
    if (intro is List && intro.length >= 2) {
      introStart = (intro[0] as num?)?.toDouble();
      introEnd = (intro[1] as num?)?.toDouble();
    }

    final outro = raw['outro'];
    if (outro is List && outro.length >= 2) {
      outroStart = (outro[0] as num?)?.toDouble();
      outroEnd = (outro[1] as num?)?.toDouble();
    }

    return (introStart, introEnd, outroStart, outroEnd);
  }
}
