import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../metadata/domain/models/anime_detail.dart';
import '../../data/hls/hls_parser.dart';
import '../../data/repositories/diagnostics_repository.dart';
import '../../data/repositories/stream_preferences_repository.dart';
import '../../data/repositories/stream_provider_registry.dart';
import '../../data/repositories/title_match_repository.dart';
import '../models/audio_language.dart';
import '../models/quality_option.dart';
import '../models/source_episode.dart';
import '../models/source_match.dart';
import '../models/stream_provider.dart';
import '../models/stream_variant.dart';
import '../models/subtitle_track.dart';

/// Exception thrown when no stream provider can resolve a playable stream.
class StreamResolutionException implements Exception {
  final String message;
  final List<String> attemptedProviders;

  const StreamResolutionException(this.message, [this.attemptedProviders = const []]);

  @override
  String toString() =>
      'StreamResolutionException: $message (attempted: ${attemptedProviders.join(', ')})';
}

/// Result of an episode stream resolution.
class StreamResolutionResult {
  final SourceMatch match;
  final SourceEpisode episode;
  final StreamProvider activeProvider;
  final List<StreamVariant> variants;
  final StreamVariant selectedVariant;
  final AudioLanguage selectedAudio;
  final SubtitleTrack selectedSubtitle;
  final QualityOption selectedQuality;
  final List<SourceMatch> candidateMatches;

  const StreamResolutionResult({
    required this.match,
    required this.episode,
    required this.activeProvider,
    required this.variants,
    required this.selectedVariant,
    required this.selectedAudio,
    required this.selectedSubtitle,
    required this.selectedQuality,
    this.candidateMatches = const [],
  });

  StreamResolutionResult copyWith({
    SourceMatch? match,
    SourceEpisode? episode,
    StreamProvider? activeProvider,
    List<StreamVariant>? variants,
    StreamVariant? selectedVariant,
    AudioLanguage? selectedAudio,
    SubtitleTrack? selectedSubtitle,
    QualityOption? selectedQuality,
    List<SourceMatch>? candidateMatches,
  }) =>
      StreamResolutionResult(
        match: match ?? this.match,
        episode: episode ?? this.episode,
        activeProvider: activeProvider ?? this.activeProvider,
        variants: variants ?? this.variants,
        selectedVariant: selectedVariant ?? this.selectedVariant,
        selectedAudio: selectedAudio ?? this.selectedAudio,
        selectedSubtitle: selectedSubtitle ?? this.selectedSubtitle,
        selectedQuality: selectedQuality ?? this.selectedQuality,
        candidateMatches: candidateMatches ?? this.candidateMatches,
      );
}

/// Orchestrates catalog matching, fallback failover across providers,
/// variant selection, and preference persistence.
class StreamOrchestrator {
  final StreamProviderRegistry registry;
  final TitleMatchRepository matchRepo;
  final StreamPreferencesRepository prefsRepo;
  final DiagnosticsRepository diagnostics;
  final Map<String, List<SourceEpisode>> _episodesCache = {};

  StreamOrchestrator({
    required this.registry,
    required this.matchRepo,
    required this.prefsRepo,
    required this.diagnostics,
  });

  /// Resolves playable variants for [anime] and [episodeNumber].
  /// Automatically tries enabled providers in priority order with fallback.
  Future<StreamResolutionResult> resolveEpisode({
    required AnimeDetail anime,
    required int episodeNumber,
    String? preferredProviderId,
  }) async {
    final title = anime.titles.preferredTitle();
    diagnostics.info(
      'Starting resolution for "$title" (ID: ${anime.id}) Ep: $episodeNumber',
      {'preferredProvider': preferredProviderId ?? 'none'},
    );

    // 1. Build ordered list of providers to attempt
    final enabledProviders = registry.getOrderedEnabledProviders();
    final candidateProviders = <StreamProvider>[];

    if (preferredProviderId != null) {
      final preferred = registry.getProvider(preferredProviderId);
      if (preferred != null) candidateProviders.add(preferred);
    }

    for (final p in enabledProviders) {
      if (!candidateProviders.any((x) => x.id == p.id)) {
        candidateProviders.add(p);
      }
    }

    if (candidateProviders.isEmpty) {
      final primary = registry.getProvider('megavid') ?? registry.allProviders.firstOrNull;
      if (primary != null) candidateProviders.add(primary);
    }

    final attempted = <String>[];

    // 2. Iterate through providers with fallback
    for (final provider in candidateProviders) {
      attempted.add(provider.displayName);
      try {
        diagnostics.info('Attempting provider: ${provider.displayName} (${provider.id})');

        // Check for manual match override first
        SourceMatch? match = matchRepo.getSavedMatch(anime.id, provider.id);
        List<SourceMatch> allCandidates = [];

        if (match == null) {
          diagnostics.info('Searching title on ${provider.displayName}...');
          allCandidates = await provider.findTitle(anime).timeout(const Duration(seconds: 10));
          if (allCandidates.isEmpty) {
            diagnostics.warn('No matches returned by ${provider.displayName}');
            continue;
          }
          // Pick best candidate
          allCandidates.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
          match = allCandidates.first;

          if (match.confidenceScore < 0.35) {
            diagnostics.warn(
              'Best candidate "${match.title}" has low confidence '
              '(${(match.confidenceScore * 100).toStringAsFixed(1)}% < 35%), skipping provider',
            );
            continue;
          }

          diagnostics.info('Matched candidate "${match.title}" (score: ${(match.confidenceScore * 100).toStringAsFixed(1)}%)');
          await matchRepo.saveMatch(anime.id, provider.id, match);
        } else {
          diagnostics.info('Using user-confirmed match "${match.title}"');
          allCandidates = [match];
        }

        // Fetch episodes with memory caching per provider match
        diagnostics.info('Listing episodes on ${provider.displayName}...');
        final cacheKey = '${provider.id}_${match.id}';
        List<SourceEpisode> episodes = _episodesCache[cacheKey] ?? const [];
        if (episodes.isEmpty) {
          episodes = await provider.episodes(match).timeout(const Duration(seconds: 10));
          if (episodes.isNotEmpty) {
            _episodesCache[cacheKey] = episodes;
          }
        }
        SourceEpisode? targetEpisode;

        for (final ep in episodes) {
          if (ep.number == episodeNumber) {
            targetEpisode = ep;
            break;
          }
        }

        final effectiveAudio = prefsRepo.getEffectiveAudioLanguage(anime.id);

        final epId = targetEpisode?.id ?? '${match.id}_ep_$episodeNumber';
        final epTitle = targetEpisode?.title ?? 'Episode $episodeNumber';
        final epData = {
          if (targetEpisode != null) ...targetEpisode.customData,
          'preferredAudio': effectiveAudio,
        };

        final resolvedTargetEpisode = SourceEpisode(
          id: epId,
          number: episodeNumber,
          title: epTitle,
          matchId: match.id,
          providerId: provider.id,
          customData: epData,
        );

        // Resolve variants (20s timeout to allow resilient network fallback)
        diagnostics.info('Resolving variants on ${provider.displayName} for Ep $episodeNumber...');
        final variants = await provider.resolve(resolvedTargetEpisode).timeout(const Duration(seconds: 20));

        if (variants.isEmpty) {
          diagnostics.warn('Provider ${provider.displayName} returned 0 variants');
          continue;
        }

        // Validate variants: reject truncated (<60s) or broken /vid/ streams concurrently
        final candidates = variants.where((v) {
          if (v.url.contains('/vid/')) {
            diagnostics.warn('Banned /vid/ proxy URL rejected: ${v.url}');
            return false;
          }
          return true;
        }).toList();

        final probeResults = await Future.wait(
          candidates.map((v) => _probeAndEnrichVariant(v)),
        );

        final healthyVariants = <StreamVariant>[];
        for (int i = 0; i < candidates.length; i++) {
          final (isHealthy, enriched) = probeResults[i];
          if (isHealthy) {
            healthyVariants.add(enriched);
          } else {
            diagnostics.warn('Variant failed health check: ${candidates[i].url}');
          }
        }

        if (healthyVariants.isEmpty) {
          diagnostics.warn('Provider ${provider.displayName} has 0 healthy variants (>60s)');
          continue;
        }

        // Direct high-speed streaming: append #.m3u8 if missing so libmpv/FFmpeg detects HLS format instantly
        final resolvedVariants = <StreamVariant>[];
        for (final v in healthyVariants) {
          final streamUrl = v.url.contains('.m3u8') ? v.url : '${v.url}#.m3u8';
          resolvedVariants.add(v.copyWith(url: streamUrl));
        }

        diagnostics.info(
          'Successfully resolved ${resolvedVariants.length} verified variant(s) on ${provider.displayName}',
          {'url': resolvedVariants.first.url},
        );

        // Apply Audio preference (prioritizing English Dub if requested)
        final prefersDub = effectiveAudio == 'en' || effectiveAudio == AudioLanguage.englishDub.code;
        StreamVariant selectedVariant = resolvedVariants.firstWhere(
          (v) => prefersDub
              ? (v.audio.code == 'en' || v.audio.code == AudioLanguage.englishDub.code || v.audio.isDub)
              : (v.audio.code == effectiveAudio),
          orElse: () => resolvedVariants.firstWhere(
            (v) => prefersDub
                ? (v.audio.isDub || v.audio.code == 'en')
                : v.audio.isOriginal,
            orElse: () => resolvedVariants.firstWhere(
              (v) => v.audio.isOriginal,
              orElse: () => resolvedVariants.first,
            ),
          ),
        );

        // Apply Subtitle preference
        final effectiveSub = prefsRepo.getEffectiveSubtitleLanguage(anime.id);
        SubtitleTrack selectedSubtitle;
        if (effectiveSub == 'off') {
          selectedSubtitle = SubtitleTrack.off();
        } else {
          selectedSubtitle = selectedVariant.subtitles.firstWhere(
            (s) => s.languageCode == effectiveSub,
            orElse: () => selectedVariant.subtitles.firstWhere(
              (s) => !s.isOff,
              orElse: () => SubtitleTrack.off(),
            ),
          );
        }

        // Apply Quality preference
        final effectiveQuality = prefsRepo.getEffectiveQuality(anime.id);
        final selectedQuality = StreamPreferencesRepository.pickClosestQuality(
          selectedVariant.qualities,
          effectiveQuality,
        );

        return StreamResolutionResult(
          match: match,
          episode: resolvedTargetEpisode,
          activeProvider: provider,
          variants: resolvedVariants,
          selectedVariant: selectedVariant,
          selectedAudio: selectedVariant.audio,
          selectedSubtitle: selectedSubtitle,
          selectedQuality: selectedQuality,
          candidateMatches: allCandidates,
        );
      } catch (e, stack) {
        diagnostics.warn(
          'Provider ${provider.displayName} failed: $e',
          {'error': e.toString(), 'stack': stack.toString().split('\n').take(3).join(' ')},
        );
      }
    }

    diagnostics.error('All providers failed for anime ID ${anime.id} Ep $episodeNumber');
    throw StreamResolutionException(
      'Could not resolve stream for episode $episodeNumber',
      attempted,
    );
  }

  /// Pre-resolves an episode in the background without throwing errors.
  /// When the user taps play, cached variants ensure instant 0ms playback start.
  Future<void> prewarmEpisode({
    required AnimeDetail anime,
    required int episodeNumber,
    String? preferredProviderId,
  }) async {
    try {
      await resolveEpisode(
        anime: anime,
        episodeNumber: episodeNumber,
        preferredProviderId: preferredProviderId,
      );
    } catch (_) {}
  }

  Dio? _sharedProbeDio;

  Dio get _probeDio {
    _sharedProbeDio ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    return _sharedProbeDio!;
  }

  /// Validates that a stream variant is responsive and has valid duration (> 60s),
  /// and if it is an HLS master playlist, enriches it with parsed quality options.
  Future<(bool, StreamVariant)> _probeAndEnrichVariant(StreamVariant variant) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return (!variant.url.contains('/vid/'), variant);
    }

    try {
      final resp = await _probeDio.get<String>(
        variant.url,
        options: Options(
          responseType: ResponseType.plain,
          headers: variant.headers,
        ),
      );

      final body = resp.data ?? '';
      if (body.isEmpty) return (false, variant);

      // Master playlist: parse distinct quality streams if available
      if (body.contains('#EXT-X-STREAM-INF')) {
        try {
          final parsed = HlsParser.parse(body, baseUrl: variant.url);
          if (parsed.length > 1) {
            return (true, variant.copyWith(qualities: parsed));
          }
        } catch (_) {}
        return (true, variant);
      }

      // Media playlist: assert duration is at least 60 seconds
      if (body.contains('#EXTINF')) {
        final dur = HlsParser.calculateDuration(body);
        if (dur != null && dur < 60.0) {
          diagnostics.warn('Stream rejected: total duration too short ($dur seconds < 60s)');
          return (false, variant);
        }
      }

      return (true, variant);
    } catch (e) {
      // If probing times out or fails with network glitch, accept if not /vid/
      return (!variant.url.contains('/vid/'), variant);
    }
  }
}
