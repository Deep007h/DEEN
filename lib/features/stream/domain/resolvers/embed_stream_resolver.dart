import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/audio_language.dart';
import '../models/quality_option.dart';
import '../models/stream_variant.dart';
import '../models/subtitle_track.dart';

/// Parsed components of a MegaVid / KissKH embed URL.
class EmbedUrlInfo {
  final String rawUrl;
  final String? animeId;
  final int episodeNumber;
  final String audio; // 'dub' or 'sub'
  final String? kisskhEpId;

  const EmbedUrlInfo({
    required this.rawUrl,
    this.animeId,
    this.episodeNumber = 1,
    this.audio = 'sub',
    this.kisskhEpId,
  });

  bool get isKisskh => kisskhEpId != null && kisskhEpId!.isNotEmpty;
  bool get isAnime => animeId != null && animeId!.isNotEmpty;
}

/// Rich metadata payload returned by the MegaVid /source endpoint.
class EmbedStreamResult {
  final String embedUrl;
  final String streamUrl;
  final StreamVariant variant;
  final List<SubtitleTrack> subtitles;
  final (double, double)? intro;
  final (double, double)? outro;
  final List<Map<String, dynamic>> providers;
  final String? activeProvider;
  final bool isAnimeX;

  const EmbedStreamResult({
    required this.embedUrl,
    required this.streamUrl,
    required this.variant,
    this.subtitles = const [],
    this.intro,
    this.outro,
    this.providers = const [],
    this.activeProvider,
    this.isAnimeX = false,
  });
}

/// High-performance stream resolver that implements the background resolution technique
/// proven in the MegaVid Cinema test project.
///
/// Features:
/// 1. Takes any canonical or custom embed URL (or Anime ID + Episode + Audio).
/// 2. Queries the `/source` endpoint with `Referer: <embedUrl>` and desktop User-Agent.
/// 3. Extracts direct unthrottled Cloudflare CDN HLS stream, 33+ subtitle tracks, and chapter markers.
/// 4. Appends `#.m3u8` path hint for instant FFmpeg demuxing in libmpv.
class EmbedStreamResolver {
  static const String defaultBaseUrl = 'https://megavid.buzz';
  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  final Dio _dio;
  final Map<String, (EmbedStreamResult, DateTime)> _resultCache = {};

  void clearCache() {
    _resultCache.clear();
  }

  EmbedStreamResolver({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: defaultBaseUrl,
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'User-Agent': defaultUserAgent,
                  'Accept': 'application/json',
                },
              ),
            );

  /// Constructs a canonical embed URL from anime ID, episode number, and audio type.
  static String buildEmbedUrl({
    required String animeId,
    required int episodeNumber,
    String audio = 'sub',
  }) {
    final cleanAudio = audio.toLowerCase().startsWith('d') ? 'dub' : 'sub';
    return '$defaultBaseUrl/ani/$animeId/$episodeNumber/$cleanAudio';
  }

  /// Constructs a KissKH embed URL from a KissKH episode ID.
  static String buildKisskhUrl(String kisskhEpId) {
    return '$defaultBaseUrl/kisskh/$kisskhEpId';
  }

  /// Parses an embed URL into its components.
  static EmbedUrlInfo parseEmbedUrl(String rawUrl) {
    final clean = rawUrl.trim();
    try {
      final uri = Uri.parse(clean);
      final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (parts.isNotEmpty) {
        if (parts[0] == 'ani' && parts.length >= 2) {
          final id = parts[1];
          final ep = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 1) : 1;
          final aud = parts.length >= 4 && parts[3].toLowerCase().startsWith('d') ? 'dub' : 'sub';
          return EmbedUrlInfo(
            rawUrl: clean,
            animeId: id,
            episodeNumber: ep,
            audio: aud,
          );
        } else if (parts[0] == 'kisskh' && parts.length >= 2) {
          final epId = parts[1];
          return EmbedUrlInfo(
            rawUrl: clean,
            kisskhEpId: epId,
            episodeNumber: 1,
            audio: 'sub',
          );
        }
      }
    } catch (_) {}

    return EmbedUrlInfo(rawUrl: clean);
  }

  /// Resolves an embed URL into an [EmbedStreamResult] with high-speed HLS and rich metadata.
  Future<EmbedStreamResult?> resolveEmbedUrl(
    String rawEmbedUrl, {
    String? serverOverride,
  }) async {
    final cleanUrl = rawEmbedUrl.trim();
    if (cleanUrl.isEmpty) return null;

    final cacheKey = '$cleanUrl#${serverOverride ?? ''}';
    final cached = _resultCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.$2).inMinutes < 10) {
      return cached.$1;
    }

    // 1. Determine canonical embed URL and target /source endpoint
    String embedUrl = cleanUrl;
    String sourceEndpoint = cleanUrl;

    if (sourceEndpoint.endsWith('/source')) {
      embedUrl = sourceEndpoint.substring(0, sourceEndpoint.length - 7);
    } else {
      sourceEndpoint = '${sourceEndpoint.replaceAll(RegExp(r'/+$'), '')}/source';
    }

    final urlInfo = parseEmbedUrl(embedUrl);
    final effectiveServer = serverOverride ?? (urlInfo.audio == 'dub' ? 'loli' : null);

    final queryParams = <String, dynamic>{};
    if (effectiveServer != null && effectiveServer.isNotEmpty) {
      queryParams['server'] = effectiveServer;
      queryParams['axsv'] = effectiveServer;
    }

    String requestPath = sourceEndpoint;
    if (requestPath.startsWith(defaultBaseUrl)) {
      requestPath = requestPath.substring(defaultBaseUrl.length);
    }

    try {
      final resp = await _dio.get<dynamic>(
        requestPath,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'User-Agent': defaultUserAgent,
            'Referer': embedUrl,
            'Origin': defaultBaseUrl,
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final data = resp.data is Map ? (resp.data as Map).cast<String, dynamic>() : null;
      if (data == null) return null;

      final res = parseSourcePayload(data, embedUrl: embedUrl);
      if (res != null) {
        _resultCache[cacheKey] = (res, DateTime.now());
      }
      return res;
    } catch (e) {
      // Fallback: only scrape embed page for default canonical queries, never for serverOverride probes
      if (serverOverride == null) {
        final scraped = await _scrapeEmbedPagePayload(embedUrl);
        if (scraped != null) {
          _resultCache[cacheKey] = (scraped, DateTime.now());
        }
        return scraped;
      }
      return null;
    }
  }

  /// Parses the raw JSON map returned by the `/source` endpoint into [EmbedStreamResult].
  EmbedStreamResult? parseSourcePayload(
    Map<String, dynamic> data, {
    required String embedUrl,
  }) {
    final rawSource = (data['source'] ?? data['Video'])?.toString();
    if (rawSource == null || rawSource.isEmpty) return null;

    // Parse audio
    final urlInfo = parseEmbedUrl(embedUrl);
    final isDub = urlInfo.audio == 'dub';
    final audio = urlInfo.isKisskh
        ? AudioLanguage.koreanOriginal
        : (isDub ? AudioLanguage.englishDub : AudioLanguage.japaneseOriginal);

    // Permanently ban all broken /vid/ proxy streams for anime, but allow valid KissKH HLS streams
    if (!urlInfo.isKisskh && rawSource.contains('/vid/')) return null;

    // Append #.m3u8 path hint so libmpv / FFmpeg recognizes HLS stream format instantly
    final streamUrl = rawSource.contains('.m3u8') ? rawSource : '$rawSource#.m3u8';

    // Parse all subtitle tracks
    final tracks = parseSubtitleTracks(data['tracks']);

    // Parse chapter markers (intro & outro)
    final intro = parseChapters(data['chapters'], 'intro') ?? parseTimeRange(data['intro']);
    final outro = parseChapters(data['chapters'], 'outro') ?? parseTimeRange(data['outro']);

    // Parse providers list
    final providersList = <Map<String, dynamic>>[];
    if (data['providers'] is List) {
      for (final p in data['providers'] as List) {
        if (p is Map) providersList.add(p.cast<String, dynamic>());
      }
    }

    final activeProvider = data['provider']?.toString();
    final isAnimeX = data['animex'] == true;

    final variant = StreamVariant(
      url: streamUrl,
      headers: {
        'Referer': urlInfo.isKisskh ? '$defaultBaseUrl/kisskh/${urlInfo.kisskhEpId}' : '$defaultBaseUrl/',
        'Origin': defaultBaseUrl,
        'User-Agent': defaultUserAgent,
      },
      audio: audio,
      subtitles: tracks,
      qualities: defaultHlsQualities(streamUrl),
      introStart: intro?.$1,
      introEnd: intro?.$2,
      outroStart: outro?.$1,
      outroEnd: outro?.$2,
    );

    return EmbedStreamResult(
      embedUrl: embedUrl,
      streamUrl: streamUrl,
      variant: variant,
      subtitles: tracks,
      intro: intro,
      outro: outro,
      providers: providersList,
      activeProvider: activeProvider,
      isAnimeX: isAnimeX,
    );
  }

  /// Scrapes the embed page HTML looking for `<script id="player-payload">` as a fallback.
  Future<EmbedStreamResult?> _scrapeEmbedPagePayload(String embedUrl) async {
    try {
      String pagePath = embedUrl;
      if (pagePath.startsWith(defaultBaseUrl)) {
        pagePath = pagePath.substring(defaultBaseUrl.length);
      }

      final resp = await _dio.get<String>(
        pagePath,
        options: Options(
          headers: {
            'Referer': '$defaultBaseUrl/',
            'Sec-Fetch-Dest': 'iframe',
            'Sec-Fetch-Mode': 'navigate',
            'User-Agent': defaultUserAgent,
          },
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final html = resp.data;
      if (html == null || html.isEmpty) return null;

      final match = RegExp(
        r'<script[^>]*id=["\x27]player-payload["\x27][^>]*>(.*?)</script>',
        dotAll: true,
      ).firstMatch(html);

      if (match == null) return null;
      final payloadStr = match.group(1)?.trim();
      if (payloadStr == null || payloadStr.isEmpty) return null;

      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final sourcePath = payload['sourceUrl']?.toString();
      if (sourcePath == null || sourcePath.isEmpty) return null;

      String targetSourceUrl = sourcePath.startsWith('http')
          ? sourcePath
          : '$defaultBaseUrl${sourcePath.startsWith('/') ? '' : '/'}$sourcePath';

      String apiPath = targetSourceUrl;
      if (apiPath.startsWith(defaultBaseUrl)) {
        apiPath = apiPath.substring(defaultBaseUrl.length);
      }

      final sourceResp = await _dio.get<Map<String, dynamic>>(
        apiPath,
        options: Options(
          headers: {
            'Referer': embedUrl,
            'Origin': defaultBaseUrl,
            'Accept': 'application/json',
            'User-Agent': defaultUserAgent,
          },
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final sourceData = sourceResp.data;
      if (sourceData != null) {
        return parseSourcePayload(sourceData, embedUrl: embedUrl);
      }
    } catch (_) {}

    return null;
  }

  /// Extracts subtitle tracks into typed [SubtitleTrack] models.
  static List<SubtitleTrack> parseSubtitleTracks(dynamic rawTracks) {
    final list = <SubtitleTrack>[SubtitleTrack.off()];
    if (rawTracks is! List) return list;

    for (final t in rawTracks) {
      if (t is! Map) continue;
      final file = (t['file'] ?? t['src'])?.toString();
      final label = t['label']?.toString();
      if (file == null || file.isEmpty || label == null || label.isEmpty) continue;

      final code = langCodeFromLabel(label);
      final isDefault = t['default'] == true || code == 'en';
      final isSrt = file.toLowerCase().endsWith('.srt');

      list.add(
        SubtitleTrack(
          id: 'sub_${list.length}',
          languageCode: code,
          label: label,
          url: file,
          format: isSrt ? SubtitleFormat.srt : SubtitleFormat.vtt,
          isDefault: isDefault,
        ),
      );
    }

    return list;
  }

  /// Extracts intro/outro chapters.
  static (double, double)? parseChapters(dynamic chapters, String kind) {
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

  /// Parses legacy time range maps `{start: X, end: Y}`.
  static (double, double)? parseTimeRange(dynamic range) {
    if (range is! Map) return null;
    final start = (range['start'] as num?)?.toDouble();
    final end = (range['end'] as num?)?.toDouble();
    if (start != null && end != null && end > start) {
      return (start, end);
    }
    return null;
  }

  /// Generates default HLS quality options.
  static List<QualityOption> defaultHlsQualities(String masterUrl) {
    return [
      const QualityOption(label: 'Auto (Adaptive)', height: 1080, isAuto: true),
      QualityOption(label: '1080p', height: 1080, bandwidth: 5000000, url: masterUrl),
      QualityOption(label: '720p', height: 720, bandwidth: 2800000, url: masterUrl),
      QualityOption(label: '480p', height: 480, bandwidth: 1400000, url: masterUrl),
      QualityOption(label: '360p', height: 360, bandwidth: 800000, url: masterUrl),
    ];
  }

  /// Normalizes human-readable subtitle label to ISO 639-1 language code.
  static String langCodeFromLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('english')) return 'en';
    if (l.contains('spanish') || l.contains('español')) return 'es';
    if (l.contains('french') || l.contains('français')) return 'fr';
    if (l.contains('german') || l.contains('deutsch')) return 'de';
    if (l.contains('italian') || l.contains('italiano')) return 'it';
    if (l.contains('portuguese') || l.contains('português')) return 'pt';
    if (l.contains('russian') || l.contains('русский')) return 'ru';
    if (l.contains('arabic') || l.contains('العربية')) return 'ar';
    if (l.contains('indonesia') || l.contains('indonesian')) return 'id';
    if (l.contains('thai') || l.contains('ภาษาไทย')) return 'th';
    if (l.contains('vietnamese')) return 'vi';
    if (l.contains('polish')) return 'pl';
    if (l.contains('chinese') || l.contains('中文')) return 'zh';
    if (l.contains('malay')) return 'ms';
    if (l.contains('japanese') || l.contains('日本語')) return 'ja';
    if (l.contains('korean') || l.contains('한국어')) return 'ko';
    return 'en';
  }
}
