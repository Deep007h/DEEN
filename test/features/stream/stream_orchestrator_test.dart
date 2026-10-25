import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/models/quality_option.dart';
import 'package:anime_stream/features/stream/domain/models/source_episode.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';
import 'package:anime_stream/features/stream/domain/models/stream_provider.dart';
import 'package:anime_stream/features/stream/domain/models/stream_variant.dart';
import 'package:anime_stream/features/stream/domain/orchestration/stream_orchestrator.dart';
import 'package:anime_stream/features/stream/data/providers/demo_provider.dart';
import 'package:anime_stream/features/stream/data/repositories/diagnostics_repository.dart';
import 'package:anime_stream/features/stream/data/repositories/stream_preferences_repository.dart';
import 'package:anime_stream/features/stream/data/repositories/stream_provider_registry.dart';
import 'package:anime_stream/features/settings/domain/models/app_settings.dart';
import 'package:anime_stream/features/stream/data/repositories/title_match_repository.dart';

class FailingProvider implements StreamProvider {
  @override
  String get id => 'failing';
  @override
  String get displayName => 'Failing Provider';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async => throw Exception('Network timeout');

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async => [];

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async => [];
}

void main() {
  group('StreamOrchestrator Tests', () {
    late SharedPreferences prefs;
    late StreamProviderRegistry registry;
    late TitleMatchRepository matchRepo;
    late StreamPreferencesRepository prefsRepo;
    late DiagnosticsRepository diagnostics;
    late StreamOrchestrator orchestrator;

    const testAnime = AnimeDetail(
      id: 400602,
      titles: AnimeTitles(
        original: '葬送のフリーレン',
        english: 'Frieren: Beyond Journey\'s End',
      ),
      airDate: '2023-09-29',
      eps: 28,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      registry = StreamProviderRegistry(prefs, [
        FailingProvider(),
        const DemoProvider(),
      ]);
      await registry.updatePriorityOrder(['failing', 'demo']);
      await registry.setProviderEnabled('failing', true);
      await registry.setProviderEnabled('demo', true);

      matchRepo = TitleMatchRepository(prefs);
      prefsRepo = StreamPreferencesRepository(prefs);
      diagnostics = DiagnosticsRepository(prefs);

      orchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );
    });

    test('Falls back from failing provider to DemoProvider and logs trace', () async {
      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      expect(result.activeProvider.id, 'demo');
      expect(result.episode.number, 1);
      expect(result.variants.isNotEmpty, isTrue);

      final logs = diagnostics.currentSessionLogs;
      expect(logs.any((l) => l.message.contains('Attempting provider: Failing Provider')), isTrue);
      expect(logs.any((l) => l.message.contains('Attempting provider: Demo (Public Test Streams)')), isTrue);
    });

    test('Applies user preferences for Audio, Subtitle, and Quality', () async {
      await prefsRepo.setAnimeAudioLanguage(testAnime.id, 'en');
      await prefsRepo.setAnimeSubtitleLanguage(testAnime.id, 'off');
      await prefsRepo.setAnimeQuality(testAnime.id, '720p');

      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 2,
      );

      expect(result.selectedAudio.code, 'en');
      expect(result.selectedSubtitle.isOff, isTrue);
      expect(result.selectedQuality.label, '720p');
    });

    test('Automatically resolves English Dub and 1080p when configured in global AppSettings', () async {
      final configuredPrefsRepo = StreamPreferencesRepository(
        prefs,
        settings: const AppSettings(
          defaultAudioLanguage: 'English',
          defaultQuality: '1080p',
        ),
      );

      final configuredOrchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: configuredPrefsRepo,
        diagnostics: diagnostics,
      );

      final result = await configuredOrchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      expect(result.selectedAudio.code, 'en');
      expect(result.selectedQuality.label, '1080p');
    });

    test('Throws StreamResolutionException if all enabled providers fail', () async {
      await registry.setProviderEnabled('demo', false);

      expect(
        () => orchestrator.resolveEpisode(anime: testAnime, episodeNumber: 1),
        throwsA(isA<StreamResolutionException>()),
      );
    });

    test('Routes K-Drama exclusively to megavid provider without Demo fallback', () async {
      const kdramaAnime = AnimeDetail(
        id: 8714,
        titles: AnimeTitles(
          original: 'Queen of Tears',
          english: 'Queen of Tears',
        ),
        platform: 'K-Drama',
        eps: 16,
      );

      // Since registry in setUp only has 'failing' and 'demo', megavid is not present,
      // so candidateProviders for K-Drama has 0 providers, and it must throw StreamResolutionException
      // without ever attempting Demo (Frieren).
      expect(
        () => orchestrator.resolveEpisode(anime: kdramaAnime, episodeNumber: 1),
        throwsA(isA<StreamResolutionException>()),
      );

      final logs = diagnostics.currentSessionLogs;
      expect(logs.any((l) => l.message.contains('Demo')), isFalse);
    });

    test('Resolves K-Drama KissKH /vid/ stream successfully for Teach You a Lesson', () async {
      final kdramaRegistry = StreamProviderRegistry(prefs, [
        _MockMegaVidKdramaProvider(),
      ]);
      await kdramaRegistry.setProviderEnabled('megavid', true);

      final kdramaOrchestrator = StreamOrchestrator(
        registry: kdramaRegistry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );

      const dramaDetail = AnimeDetail(
        id: 12864,
        titles: AnimeTitles(
          original: 'Teach You a Lesson (2026)',
          english: 'Teach You a Lesson (2026)',
        ),
        platform: 'K-Drama',
        eps: 10,
        episodes: [
          Episode(id: 214619, number: 1, sort: 1, title: 'Episode 1'),
        ],
      );

      final result = await kdramaOrchestrator.resolveEpisode(
        anime: dramaDetail,
        episodeNumber: 1,
        preferredProviderId: 'megavid',
      );

      expect(result.selectedVariant.url, contains('/vid/'));
      expect(result.selectedVariant.url, contains('Ep1.v713_index.m3u8'));
      expect(result.selectedAudio.code, 'ko');
    });
  });
}

class _MockMegaVidKdramaProvider implements StreamProvider {
  @override
  String get id => 'megavid';
  @override
  String get displayName => 'MegaVid (KissKH)';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async => [
        SourceMatch(
          id: anime.id.toString(),
          title: anime.titles.preferredTitle(),
          providerId: 'megavid',
          episodeCount: anime.eps,
          customData: const {'sourceType': 'kisskh'},
        ),
      ];

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async => [
        SourceEpisode(
          id: '214619',
          number: 1,
          title: 'Episode 1',
          matchId: match.id,
          providerId: id,
          customData: const {'kisskhEpId': '214619'},
        ),
      ];

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async => const [
        StreamVariant(
          url: 'https://megavid.buzz/vid/cFdbzGmw.../Ep1.v713_index.m3u8',
          headers: {'Referer': 'https://megavid.buzz/kisskh/214619'},
          audio: AudioLanguage.koreanOriginal,
          qualities: [
            QualityOption(label: 'Auto', height: 1080, isAuto: true),
          ],
        ),
      ];
}
