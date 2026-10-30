import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/domain/models/audio_language.dart';
import 'package:anime_stream/features/stream/domain/models/quality_option.dart';
import 'package:anime_stream/features/stream/domain/models/source_episode.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';
import 'package:anime_stream/features/stream/domain/models/stream_provider.dart';
import 'package:anime_stream/features/stream/domain/models/stream_variant.dart';
import 'package:anime_stream/features/stream/domain/orchestration/stream_orchestrator.dart';
import 'package:anime_stream/features/stream/data/repositories/diagnostics_repository.dart';
import 'package:anime_stream/features/stream/data/repositories/stream_preferences_repository.dart';
import 'package:anime_stream/features/stream/data/repositories/stream_provider_registry.dart';
import 'package:anime_stream/features/settings/domain/models/app_settings.dart';
import 'package:anime_stream/features/stream/data/repositories/title_match_repository.dart';

class MockMultiAudioProvider implements StreamProvider {
  final String providerId;
  final String providerName;
  final List<AudioLanguage> supportedAudios;

  const MockMultiAudioProvider({
    required this.providerId,
    required this.providerName,
    required this.supportedAudios,
  });

  @override
  String get id => providerId;

  @override
  String get displayName => providerName;

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    return [
      SourceMatch(
        id: 'mock_match_1',
        title: anime.titles.preferredTitle(),
        providerId: id,
        episodeCount: 12,
        confidenceScore: 1.0,
      ),
    ];
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    return [
      SourceEpisode(
        id: 'ep_1',
        number: 1,
        title: 'Episode 1',
        matchId: match.id,
        providerId: id,
      ),
    ];
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    return supportedAudios.map((audio) {
      return StreamVariant(
        url: 'https://cdn.example.com/${audio.code}/master.m3u8',
        audio: audio,
        qualities: const [
          QualityOption(label: '1080p', height: 1080),
        ],
      );
    }).toList();
  }
}

void main() {
  group('AudioLanguage Model Tests', () {
    test('fromCode parses standard and Indian language codes', () {
      expect(AudioLanguage.fromCode('hi'), AudioLanguage.hindiDub);
      expect(AudioLanguage.fromCode('hin'), AudioLanguage.hindiDub);
      expect(AudioLanguage.fromCode('ta'), AudioLanguage.tamilDub);
      expect(AudioLanguage.fromCode('tam'), AudioLanguage.tamilDub);
      expect(AudioLanguage.fromCode('te'), AudioLanguage.teluguDub);
      expect(AudioLanguage.fromCode('en'), AudioLanguage.englishDub);
      expect(AudioLanguage.fromCode('ja'), AudioLanguage.japaneseOriginal);
      expect(AudioLanguage.fromCode('ko'), AudioLanguage.koreanOriginal);
    });

    test('fromName parses display names properly', () {
      expect(AudioLanguage.fromName('Hindi Dub'), AudioLanguage.hindiDub);
      expect(AudioLanguage.fromName('Hindi'), AudioLanguage.hindiDub);
      expect(AudioLanguage.fromName('English'), AudioLanguage.englishDub);
      expect(AudioLanguage.fromName('Japanese (Original)'), AudioLanguage.japaneseOriginal);
      expect(AudioLanguage.fromName('Tamil'), AudioLanguage.tamilDub);
      expect(AudioLanguage.fromName('Telugu'), AudioLanguage.teluguDub);
    });

    test('shortLabel returns proper badge representation', () {
      expect(AudioLanguage.hindiDub.shortLabel, 'HINDI');
      expect(AudioLanguage.englishDub.shortLabel, 'DUB');
      expect(AudioLanguage.japaneseOriginal.shortLabel, 'SUB');
      expect(AudioLanguage.tamilDub.shortLabel, 'TAMIL');
      expect(AudioLanguage.teluguDub.shortLabel, 'TELUGU');
    });
  });

  group('Primary & Secondary Audio Fallback Tests', () {
    late SharedPreferences prefs;
    late TitleMatchRepository matchRepo;
    late DiagnosticsRepository diagnostics;

    const testAnime = AnimeDetail(
      id: 99901,
      titles: AnimeTitles(
        original: 'チェンソーマン',
        english: 'Chainsaw Man',
      ),
      eps: 12,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      matchRepo = TitleMatchRepository(prefs);
      diagnostics = DiagnosticsRepository(prefs);
    });

    test('Picks primary audio (Hindi) when available', () async {
      const animelok = MockMultiAudioProvider(
        providerId: 'animelok',
        providerName: 'Animelok Provider',
        supportedAudios: [
          AudioLanguage.hindiDub,
          AudioLanguage.englishDub,
          AudioLanguage.japaneseOriginal,
        ],
      );

      final registry = StreamProviderRegistry(prefs, [animelok]);
      await registry.setProviderEnabled('animelok', true);

      const settings = AppSettings(
        defaultAudioLanguage: 'Hindi',
        secondaryAudioLanguage: 'English',
      );
      final prefsRepo = StreamPreferencesRepository(prefs, settings: settings);

      final orchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );

      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      expect(result.selectedAudio.code, 'hi');
      expect(result.selectedVariant.audio.code, 'hi');
    });

    test('Falls back to secondary audio (English) when primary (Hindi) is not available', () async {
      // Provider only has English and Japanese, no Hindi
      const anifam = MockMultiAudioProvider(
        providerId: 'anifam',
        providerName: 'AniFam Provider',
        supportedAudios: [
          AudioLanguage.englishDub,
          AudioLanguage.japaneseOriginal,
        ],
      );

      final registry = StreamProviderRegistry(prefs, [anifam]);
      await registry.setProviderEnabled('anifam', true);

      const settings = AppSettings(
        defaultAudioLanguage: 'Hindi',
        secondaryAudioLanguage: 'English',
      );
      final prefsRepo = StreamPreferencesRepository(prefs, settings: settings);

      final orchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );

      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      expect(result.selectedAudio.code, 'en');
      expect(result.selectedVariant.audio.code, 'en');
    });

    test('Falls back to Japanese original when both primary and secondary are not available', () async {
      // Provider only has Japanese original
      const subOnly = MockMultiAudioProvider(
        providerId: 'sub_only',
        providerName: 'Sub Only Provider',
        supportedAudios: [
          AudioLanguage.japaneseOriginal,
        ],
      );

      final registry = StreamProviderRegistry(prefs, [subOnly]);
      await registry.setProviderEnabled('sub_only', true);

      const settings = AppSettings(
        defaultAudioLanguage: 'Hindi',
        secondaryAudioLanguage: 'English',
      );
      final prefsRepo = StreamPreferencesRepository(prefs, settings: settings);

      final orchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );

      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      expect(result.selectedAudio.code, 'ja');
      expect(result.selectedVariant.audio.code, 'ja');
    });

    test('Prioritizes Animelok provider first when Hindi is preferred', () async {
      const anifam = MockMultiAudioProvider(
        providerId: 'anifam',
        providerName: 'AniFam Provider',
        supportedAudios: [AudioLanguage.englishDub, AudioLanguage.japaneseOriginal],
      );
      const animelok = MockMultiAudioProvider(
        providerId: 'animelok',
        providerName: 'Animelok Provider',
        supportedAudios: [AudioLanguage.hindiDub, AudioLanguage.japaneseOriginal],
      );

      // Default order puts anifam before animelok
      final registry = StreamProviderRegistry(prefs, [anifam, animelok]);
      await registry.updatePriorityOrder(['anifam', 'animelok']);
      await registry.setProviderEnabled('anifam', true);
      await registry.setProviderEnabled('animelok', true);

      // Primary: Hindi
      const settings = AppSettings(
        defaultAudioLanguage: 'Hindi',
        secondaryAudioLanguage: 'English',
      );
      final prefsRepo = StreamPreferencesRepository(prefs, settings: settings);

      final orchestrator = StreamOrchestrator(
        registry: registry,
        matchRepo: matchRepo,
        prefsRepo: prefsRepo,
        diagnostics: diagnostics,
      );

      final result = await orchestrator.resolveEpisode(
        anime: testAnime,
        episodeNumber: 1,
      );

      // Should pick Animelok because Hindi was preferred and Animelok provides Hindi
      expect(result.activeProvider.id, 'animelok');
      expect(result.selectedAudio.code, 'hi');
    });
  });
}
