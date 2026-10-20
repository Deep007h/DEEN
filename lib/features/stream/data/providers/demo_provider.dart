import '../../../metadata/domain/models/anime_detail.dart';
import '../../domain/matching/title_matcher.dart';
import '../../domain/models/audio_language.dart';
import '../../domain/models/quality_option.dart';
import '../../domain/models/source_episode.dart';
import '../../domain/models/source_match.dart';
import '../../domain/models/stream_provider.dart';
import '../../domain/models/stream_variant.dart';
import '../../domain/models/subtitle_track.dart';

/// Demo stream provider providing official, public test streams
/// with multiple audio languages (Japanese original, English dub, Hindi dub),
/// subtitles, and video quality tiers for development and testing.
class DemoProvider implements StreamProvider {
  const DemoProvider();

  @override
  String get id => 'demo';

  @override
  String get displayName => 'Demo (Public Test Streams)';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    // Artificial network simulation
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final bestTitle = anime.titles.preferredTitle();
    final year = _parseYear(anime.airDate);
    final count = anime.eps ?? (anime.episodes.isNotEmpty ? anime.episodes.length : 12);

    final primaryMatch = SourceMatch(
      id: 'demo_${anime.id}',
      title: bestTitle,
      providerId: id,
      year: year,
      episodeCount: count,
      confidenceScore: TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: bestTitle,
        candidateYear: year,
        candidateEpisodeCount: count,
      ),
      customData: {'source': 'demo_catalog'},
    );

    final altMatch = SourceMatch(
      id: 'demo_${anime.id}_ova',
      title: '$bestTitle: Special Edition',
      providerId: id,
      year: year,
      episodeCount: 1,
      confidenceScore: TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: '$bestTitle: Special Edition',
        candidateYear: year,
        candidateEpisodeCount: 1,
      ),
      customData: {'source': 'demo_catalog_alt'},
    );

    return [primaryMatch, altMatch];
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final total = match.episodeCount ?? 12;
    return List.generate(
      total,
      (index) {
        final epNum = index + 1;
        return SourceEpisode(
          id: '${match.id}_ep_$epNum',
          number: epNum,
          title: 'Episode $epNum',
          matchId: match.id,
          providerId: id,
        );
      },
    );
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Variant 1: Japanese Audio (Mux Test HLS stream with adaptive bitrate)
    final japaneseVariant = StreamVariant(
      url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      headers: {
        'User-Agent': 'DEEN/1.0 DemoPlayer',
      },
      audio: AudioLanguage.japaneseOriginal,
      subtitles: [
        SubtitleTrack.off(),
        const SubtitleTrack(
          id: 'en',
          languageCode: 'en',
          label: 'English',
          url: 'https://bitdash-a.akamaihd.net/content/sintel/subtitles/subtitles_en.vtt',
          format: SubtitleFormat.vtt,
          isDefault: true,
        ),
        const SubtitleTrack(
          id: 'es',
          languageCode: 'es',
          label: 'Spanish',
          format: SubtitleFormat.vtt,
        ),
        const SubtitleTrack(
          id: 'fr',
          languageCode: 'fr',
          label: 'French',
          format: SubtitleFormat.vtt,
        ),
      ],
      qualities: const [
        QualityOption(label: 'Auto', height: 1080, isAuto: true),
        QualityOption(
          label: '1080p',
          height: 1080,
          bandwidth: 5000000,
          url: 'https://test-streams.mux.dev/x36xhzz/url_8/1920_1080/index.m3u8',
        ),
        QualityOption(
          label: '720p',
          height: 720,
          bandwidth: 2800000,
          url: 'https://test-streams.mux.dev/x36xhzz/url_6/1280_720/index.m3u8',
        ),
        QualityOption(
          label: '480p',
          height: 480,
          bandwidth: 1400000,
          url: 'https://test-streams.mux.dev/x36xhzz/url_4/848_480/index.m3u8',
        ),
        QualityOption(
          label: '360p',
          height: 360,
          bandwidth: 800000,
          url: 'https://test-streams.mux.dev/x36xhzz/url_2/640_360/index.m3u8',
        ),
      ],
    );

    // Variant 2: English Dub (Apple bipbop HLS)
    final englishDubVariant = StreamVariant(
      url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
      headers: {
        'User-Agent': 'DEEN/1.0 DemoPlayer',
      },
      audio: AudioLanguage.englishDub,
      subtitles: [
        SubtitleTrack.off(),
        const SubtitleTrack(
          id: 'en_cc',
          languageCode: 'en',
          label: 'English [CC]',
          format: SubtitleFormat.vtt,
          isDefault: true,
        ),
      ],
      qualities: const [
        QualityOption(label: 'Auto', height: 1080, isAuto: true),
        QualityOption(label: '1080p', height: 1080, bandwidth: 4500000),
        QualityOption(label: '720p', height: 720, bandwidth: 2400000),
        QualityOption(label: '480p', height: 480, bandwidth: 1200000),
      ],
    );

    // Variant 3: Hindi Dub (Public MP4 stream)
    final hindiDubVariant = StreamVariant(
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      headers: const {},
      audio: AudioLanguage.hindiDub,
      subtitles: [
        SubtitleTrack.off(),
        const SubtitleTrack(
          id: 'en',
          languageCode: 'en',
          label: 'English',
          format: SubtitleFormat.vtt,
        ),
      ],
      qualities: const [
        QualityOption(label: 'Auto', height: 720, isAuto: true),
        QualityOption(label: '720p', height: 720, bandwidth: 2200000),
        QualityOption(label: '480p', height: 480, bandwidth: 1000000),
      ],
    );

    return [japaneseVariant, englishDubVariant, hindiDubVariant];
  }

  static int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.length < 4) return null;
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
