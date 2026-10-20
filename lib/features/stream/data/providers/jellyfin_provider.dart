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
import '../repositories/stream_provider_registry.dart';

/// Provider connecting to a self-hosted Jellyfin media server.
class JellyfinProvider implements StreamProvider {
  final StreamProviderRegistry _registry;
  final Dio _dio;

  JellyfinProvider(this._registry, [Dio? dio]) : _dio = dio ?? Dio();

  @override
  String get id => 'jellyfin';

  @override
  String get displayName => 'Jellyfin Server';

  String get _host => _registry.getJellyfinHost().replaceAll(RegExp(r'/+$'), '');
  String get _token => _registry.getJellyfinToken();

  Map<String, String> _headers() => {
        if (_token.isNotEmpty) 'X-Emby-Token': _token,
        'Accept': 'application/json',
      };

  /// Probes the server health and latency for the Sources settings screen.
  Future<int?> testConnection() async {
    if (_host.isEmpty) return null;
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _dio.get(
        '$_host/System/Info/Public',
        options: Options(headers: _headers(), sendTimeout: const Duration(seconds: 4)),
      );
      stopwatch.stop();
      if (res.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    if (_host.isEmpty) {
      // Unconfigured server: return empty match list
      return [];
    }

    final query = anime.titles.preferredTitle();
    try {
      final res = await _dio.get(
        '$_host/Items',
        queryParameters: {
          'searchTerm': query,
          'includeItemTypes': 'Series',
          'recursive': 'true',
          'limit': 5,
        },
        options: Options(headers: _headers()),
      );

      final items = (res.data?['Items'] as List?) ?? [];
      final matches = <SourceMatch>[];

      for (final item in items) {
        final id = item['Id']?.toString() ?? '';
        final name = item['Name']?.toString() ?? '';
        final year = item['ProductionYear'] as int?;

        final score = TitleMatcher.scoreCandidate(
          anime: anime,
          candidateTitle: name,
          candidateYear: year,
        );

        matches.add(
          SourceMatch(
            id: id,
            title: name,
            providerId: this.id,
            year: year,
            confidenceScore: score,
            customData: {'jellyfinItemId': id},
          ),
        );
      }

      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
      return matches;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    if (_host.isEmpty) return [];

    try {
      final res = await _dio.get(
        '$_host/Shows/${match.id}/Episodes',
        options: Options(headers: _headers()),
      );

      final items = (res.data?['Items'] as List?) ?? [];
      final episodes = <SourceEpisode>[];

      for (final item in items) {
        final id = item['Id']?.toString() ?? '';
        final index = (item['IndexNumber'] as int?) ?? (episodes.length + 1);
        final name = item['Name']?.toString();

        episodes.add(
          SourceEpisode(
            id: id,
            number: index,
            title: name,
            matchId: match.id,
            providerId: this.id,
            customData: {'jellyfinVideoId': id},
          ),
        );
      }

      episodes.sort((a, b) => a.number.compareTo(b.number));
      return episodes;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    if (_host.isEmpty) return [];

    final videoId = episode.customData['jellyfinVideoId']?.toString() ?? episode.id;

    final hlsUrl = '$_host/Videos/$videoId/master.m3u8?api_key=$_token';
    final directUrl = '$_host/Videos/$videoId/stream?static=true&api_key=$_token';

    return [
      StreamVariant(
        url: hlsUrl,
        headers: _headers(),
        audio: AudioLanguage.japaneseOriginal,
        subtitles: [
          SubtitleTrack.off(),
        ],
        qualities: const [
          QualityOption(label: 'Auto', height: 1080, isAuto: true),
          QualityOption(label: '1080p', height: 1080),
          QualityOption(label: '720p', height: 720),
          QualityOption(label: '480p', height: 480),
        ],
      ),
      StreamVariant(
        url: directUrl,
        headers: _headers(),
        audio: AudioLanguage.japaneseOriginal,
        subtitles: [
          SubtitleTrack.off(),
        ],
        qualities: const [
          QualityOption(label: 'Direct Play', isAuto: false),
        ],
      ),
    ];
  }
}
