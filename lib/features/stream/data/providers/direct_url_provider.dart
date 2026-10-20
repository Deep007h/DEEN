import '../../../metadata/domain/models/anime_detail.dart';
import '../../domain/models/audio_language.dart';
import '../../domain/models/quality_option.dart';
import '../../domain/models/source_episode.dart';
import '../../domain/models/source_match.dart';
import '../../domain/models/stream_provider.dart';
import '../../domain/models/stream_variant.dart';
import '../../domain/models/subtitle_track.dart';
import '../repositories/stream_provider_registry.dart';

/// Provider resolving direct media files or custom HLS patterns
/// configured by the user in Settings.
class DirectUrlProvider implements StreamProvider {
  final StreamProviderRegistry _registry;

  const DirectUrlProvider(this._registry);

  @override
  String get id => 'direct_url';

  @override
  String get displayName => 'Direct URL (Self-Hosted)';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    final title = anime.titles.preferredTitle();
    return [
      SourceMatch(
        id: 'direct_${anime.id}',
        title: title,
        providerId: id,
        year: null,
        episodeCount: anime.eps ?? (anime.episodes.isNotEmpty ? anime.episodes.length : 12),
        confidenceScore: 1.0,
        customData: {'animeId': anime.id},
      ),
    ];
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    final count = match.episodeCount ?? 12;
    return List.generate(
      count,
      (index) {
        final epNum = index + 1;
        return SourceEpisode(
          id: '${match.id}_ep_$epNum',
          number: epNum,
          title: 'Episode $epNum',
          matchId: match.id,
          providerId: id,
          customData: match.customData,
        );
      },
    );
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    final pattern = _registry.getDirectUrlPattern();
    final animeId = episode.customData['animeId']?.toString() ?? 'anime';
    final epStr = episode.number.toString();
    final ep2Str = episode.number.toString().padLeft(2, '0');

    var resolvedUrl = pattern
        .replaceAll('{id}', animeId)
        .replaceAll('{ep}', epStr)
        .replaceAll('{ep2}', ep2Str);

    final isHls = resolvedUrl.toLowerCase().contains('.m3u8');

    return [
      StreamVariant(
        url: resolvedUrl,
        audio: AudioLanguage.japaneseOriginal,
        subtitles: [
          SubtitleTrack.off(),
        ],
        qualities: [
          const QualityOption(label: 'Auto', height: 1080, isAuto: true),
          if (!isHls) const QualityOption(label: 'Source', isAuto: false),
        ],
      ),
    ];
  }
}
