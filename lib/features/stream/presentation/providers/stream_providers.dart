import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide StreamProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/audio_language.dart';
import '../../domain/models/quality_option.dart';
import '../../domain/models/source_match.dart';
import '../../domain/models/stream_provider.dart';
import '../../domain/models/subtitle_track.dart';
import '../../domain/orchestration/stream_orchestrator.dart';
import '../../data/providers/demo_provider.dart';
import '../../data/providers/direct_url_provider.dart';
import '../../data/providers/jellyfin_provider.dart';
import '../../data/providers/megavid_provider.dart';
import '../../data/repositories/diagnostics_repository.dart';
import '../../data/repositories/stream_preferences_repository.dart';
import '../../data/repositories/stream_provider_registry.dart';
import '../../data/repositories/title_match_repository.dart';
import 'package:dio/dio.dart';
import '../../../metadata/domain/models/anime_detail.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';
import '../../../settings/data/repositories/app_settings_repository.dart';

/// Global shared diagnostics repository provider.
final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  return DiagnosticsRepository();
});

/// Shared preferences async provider with crash-safe fallback.
final sharedPreferencesAsyncProvider = FutureProvider<SharedPreferences>((ref) async {
  try {
    return await SharedPreferences.getInstance();
  } catch (e) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      return await SharedPreferences.getInstance();
    }
    rethrow;
  }
});

/// Direct instance provider for MegaVidProvider.
final megaVidProvider = Provider<MegaVidProvider>((ref) => MegaVidProvider());

/// Registry provider managing available providers and priorities.
final streamProviderRegistryProvider = FutureProvider<StreamProviderRegistry>((ref) async {
  final prefs = await ref.watch(sharedPreferencesAsyncProvider.future);
  final registry = StreamProviderRegistry(prefs, const []);
  final megavid = ref.watch(megaVidProvider);
  const demo = DemoProvider();
  final direct = DirectUrlProvider(registry);
  final jellyfin = JellyfinProvider(registry);

  registry.register(megavid);
  registry.register(demo);
  registry.register(direct);
  registry.register(jellyfin);

  return registry;
});

/// Provider for list of all registered StreamProvider implementations.
final streamProvidersProvider = Provider<List<StreamProvider>>((ref) {
  final registryAsync = ref.watch(streamProviderRegistryProvider);
  return registryAsync.maybeWhen(
    data: (reg) => reg.allProviders,
    orElse: () => const [DemoProvider()],
  );
});

/// Stream preferences repository provider.
final streamPreferencesRepositoryProvider = FutureProvider<StreamPreferencesRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesAsyncProvider.future);
  try {
    await prefs.reload();
  } catch (_) {}
  final settings = ref.watch(appSettingsProvider);
  return StreamPreferencesRepository(prefs, settings: settings);
});

/// Title match repository provider.
final titleMatchRepositoryProvider = FutureProvider<TitleMatchRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesAsyncProvider.future);
  return TitleMatchRepository(prefs);
});

/// Orchestrator provider connecting registry, match persistence, and preferences.
final streamOrchestratorProvider = FutureProvider<StreamOrchestrator>((ref) async {
  final registry = await ref.watch(streamProviderRegistryProvider.future);
  final matchRepo = await ref.watch(titleMatchRepositoryProvider.future);
  final prefsRepo = await ref.watch(streamPreferencesRepositoryProvider.future);
  final diagnostics = ref.watch(diagnosticsRepositoryProvider);

  return StreamOrchestrator(
    registry: registry,
    matchRepo: matchRepo,
    prefsRepo: prefsRepo,
    diagnostics: diagnostics,
  );
});

/// Resolution input parameters.
class StreamResolutionParams {
  final int animeId;
  final int episodeNumber;
  final String? preferredProviderId;

  const StreamResolutionParams({
    required this.animeId,
    required this.episodeNumber,
    this.preferredProviderId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamResolutionParams &&
          runtimeType == other.runtimeType &&
          animeId == other.animeId &&
          episodeNumber == other.episodeNumber &&
          preferredProviderId == other.preferredProviderId;

  @override
  int get hashCode =>
      animeId.hashCode ^ episodeNumber.hashCode ^ preferredProviderId.hashCode;
}

/// State notifier for managing active stream playback variant and choices.
class ActiveStreamStateNotifier
    extends AutoDisposeFamilyAsyncNotifier<StreamResolutionResult, StreamResolutionParams> {
  @override
  Future<StreamResolutionResult> build(StreamResolutionParams arg) async {
    final orchestrator = await ref.watch(streamOrchestratorProvider.future);
    final metadataRepo = ref.watch(metadataRepositoryProvider);

    AnimeDetail anime;
    try {
      anime = await metadataRepo.getAnimeDetail(arg.animeId);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.cancel || CancelToken.isCancel(e))) {
        // If preceding screen navigation cancelled an in-flight request, re-fetch cleanly
        anime = await metadataRepo.getAnimeDetail(arg.animeId);
      } else {
        rethrow;
      }
    }

    return orchestrator.resolveEpisode(
      anime: anime,
      episodeNumber: arg.episodeNumber,
      preferredProviderId: arg.preferredProviderId,
    );
  }

  /// Changes the active audio language and variant, updating user preferences.
  Future<void> selectAudioLanguage(AudioLanguage audio) async {
    final current = state.value;
    if (current == null) return;

    // Find variant with matching audio
    var newVariant = current.variants.firstWhere(
      (v) => v.audio.code == audio.code,
      orElse: () => current.selectedVariant,
    );

    // If requested audio variant is not in the currently resolved list, re-resolve for this audio
    if (newVariant.audio.code != audio.code) {
      state = const AsyncLoading();
      try {
        final prefsRepo = await ref.read(streamPreferencesRepositoryProvider.future);
        await prefsRepo.setAnimeAudioLanguage(arg.animeId, audio.code);

        final orchestrator = await ref.read(streamOrchestratorProvider.future);
        final metadataRepo = ref.read(metadataRepositoryProvider);
        final anime = await metadataRepo.getAnimeDetail(arg.animeId);

        final reloaded = await orchestrator.resolveEpisode(
          anime: anime,
          episodeNumber: arg.episodeNumber,
          preferredProviderId: arg.preferredProviderId,
        );
        state = AsyncData(reloaded);
        return;
      } catch (_) {
        // Restore previous state if fetch failed
        state = AsyncData(current);
        return;
      }
    }

    // Keep same subtitle language if available, else pick off or default
    final subLang = current.selectedSubtitle.languageCode;
    final newSub = newVariant.subtitles.firstWhere(
      (s) => s.languageCode == subLang,
      orElse: () => newVariant.subtitles.firstWhere(
        (s) => !s.isOff,
        orElse: () => SubtitleTrack.off(),
      ),
    );

    // Keep closest quality
    final newQuality = StreamPreferencesRepository.pickClosestQuality(
      newVariant.qualities,
      current.selectedQuality.label,
    );

    state = AsyncData(
      current.copyWith(
        selectedVariant: newVariant,
        selectedAudio: audio,
        selectedSubtitle: newSub,
        selectedQuality: newQuality,
      ),
    );

    // Persist choice per anime
    final prefsRepo = await ref.read(streamPreferencesRepositoryProvider.future);
    await prefsRepo.setAnimeAudioLanguage(arg.animeId, audio.code);
  }

  /// Changes the active subtitle track, updating user preferences.
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(selectedSubtitle: track));

    final prefsRepo = await ref.read(streamPreferencesRepositoryProvider.future);
    await prefsRepo.setAnimeSubtitleLanguage(arg.animeId, track.languageCode);
  }

  /// Changes the active quality option, updating user preferences.
  Future<void> selectQuality(QualityOption quality) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(selectedQuality: quality));

    final prefsRepo = await ref.read(streamPreferencesRepositoryProvider.future);
    await prefsRepo.setAnimeQuality(arg.animeId, quality.label);
  }

  /// Manually confirms or changes the catalog match.
  Future<void> confirmMatch(SourceMatch match) async {
    final matchRepo = await ref.read(titleMatchRepositoryProvider.future);
    await matchRepo.saveMatch(arg.animeId, match.providerId, match);

    // Reload with newly confirmed match
    ref.invalidateSelf();
  }

  /// Switch provider explicitly and re-resolve.
  Future<void> switchProvider(String providerId) async {
    final registry = await ref.read(streamProviderRegistryProvider.future);
    await registry.setAnimeSelectedProviderId(arg.animeId, providerId);
    ref.invalidateSelf();
  }

  /// Automatically retry resolution with the next available provider or invalidate cache.
  Future<void> retryWithNextProvider() async {
    final megavid = ref.read(megaVidProvider);
    megavid.clearCache();

    final current = state.value;
    final registry = await ref.read(streamProviderRegistryProvider.future);
    final order = registry.getOrderedEnabledProviders();
    if (order.length > 1 && current != null) {
      final currentIndex = order.indexWhere((p) => p.id == current.activeProvider.id);
      final nextIndex = (currentIndex + 1) % order.length;
      final nextProvider = order[nextIndex];
      await switchProvider(nextProvider.id);
    } else {
      ref.invalidateSelf();
    }
  }
}

/// Active stream resolution provider for an anime episode.
final activeStreamProvider = AsyncNotifierProvider.autoDispose.family<ActiveStreamStateNotifier,
    StreamResolutionResult, StreamResolutionParams>(
  ActiveStreamStateNotifier.new,
);
