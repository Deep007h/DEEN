import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
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
  });
}
