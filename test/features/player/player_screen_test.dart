import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/player/data/engine/mock_playback_engine.dart';
import 'package:anime_stream/features/player/data/repositories/playback_history_repository.dart';
import 'package:anime_stream/features/player/data/services/device_controls_service.dart';
import 'package:anime_stream/features/player/presentation/providers/player_engine_provider.dart';
import 'package:anime_stream/features/player/presentation/screens/player_screen.dart';
import 'package:anime_stream/features/player/presentation/widgets/next_episode_card.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_hud_overlays.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_more_options_sheet.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_top_bar.dart';
import 'package:anime_stream/features/player/presentation/widgets/skip_intro_button.dart';

class TestMetadataRepo extends MetadataRepository {
  @override
  Future<AnimeDetail> getAnimeDetail(int id, {dynamic cancelToken}) async {
    return const AnimeDetail(
      id: 400602,
      titles: AnimeTitles(
        original: '葬送のフリーレン',
        english: "Frieren: Beyond Journey's End",
      ),
      summary: 'Frieren and her party defeated the Demon King...',
      score: 8.5,
      ratingCount: 36616,
      airDate: '2023-09-29',
      eps: 28,
      seasons: [
        Season(id: 400602, name: 'Season 1', isCurrent: true),
      ],
      episodes: [
        Episode(
          id: 1227087,
          number: 1.0,
          sort: 1,
          title: 'The End of the Beginning',
          titleOriginal: '冒険の終わり',
          airDate: '2023-09-29',
        ),
      ],
    );
  }

  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    dynamic cancelToken,
  }) async {
    return [];
  }

  @override
  Future<List<Season>> getSeasons(int animeId, {dynamic cancelToken}) async {
    return const [Season(id: 400602, name: 'Season 1', isCurrent: true)];
  }

  @override
  Future<List<Episode>> getEpisodes(int animeId, {int limit = 100, int offset = 0, dynamic cancelToken}) async {
    final detail = await getAnimeDetail(animeId);
    return detail.episodes;
  }
}

void main() {
  late MockPlaybackEngine mockEngine;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
    mockEngine = MockPlaybackEngine(
      initialPosition: const Duration(seconds: 30),
      initialDuration: const Duration(minutes: 24),
      initialBuffer: const Duration(minutes: 6),
    );
  });

  Widget buildPlayerScreen({
    int animeId = 400602,
    int episodeNumber = 1,
    String? preferredProviderId = 'demo',
    PlaybackHistoryRepository? customRepo,
  }) {
    return ProviderScope(
      overrides: [
        metadataRepositoryProvider.overrideWithValue(TestMetadataRepo()),
        videoPlaybackEngineFactoryProvider.overrideWithValue(() async => mockEngine),
        deviceControlsServiceProvider.overrideWithValue(MockDeviceControlsService()),
        if (customRepo != null)
          playbackHistoryRepositoryProvider.overrideWithValue(customRepo),
      ],
      child: MaterialApp(
        home: PlayerScreen(
          animeId: animeId,
          episodeNumber: episodeNumber,
          preferredProviderId: preferredProviderId,
        ),
      ),
    );
  }

  group('PlayerScreen - Layout & Mockup Alignment', () {
    testWidgets('renders all reference mockup controls and elements', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080); // Landscape
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Top bar: back button, title, episode subtitle, comments toggle, cast, more options
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text("Frieren: Beyond Journey's End"), findsWidgets);
      expect(find.textContaining('Episode 01'), findsOneWidget);
      expect(find.byTooltip('Disable Comments'), findsOneWidget);
      expect(find.byTooltip('Cast'), findsOneWidget);
      expect(find.byTooltip('More Options'), findsOneWidget);

      // 2. Center controls: replay-10, large play/pause, forward-10
      expect(find.byTooltip('Replay 10 seconds'), findsOneWidget);
      expect(find.byTooltip('Forward 10 seconds'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // 3. Bottom controls: seek bar, duration timestamps, Episodes, Settings, Fullscreen
      expect(find.text('00:30'), findsOneWidget); // elapsed position
      expect(find.text('24:00'), findsOneWidget); // total duration
      expect(find.byTooltip('Episodes'), findsOneWidget);
      expect(find.byTooltip('Playback Settings'), findsOneWidget);
      expect(find.byTooltip('Fullscreen'), findsOneWidget);

      // 4. Intro skip button (+85s) visible during first 90s
      expect(find.byType(SkipIntroButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('PlayerScreen - Gesture Interactions', () {
    testWidgets('double-tap right third accumulates forward seeking and displays badge', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Right third is x > 600 (out of 900 logical width), vertical center y = 225
      const rightPos = Offset(750, 225);

      // Double tap right side
      await tester.tapAt(rightPos);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(rightPos);
      await tester.pump(const Duration(milliseconds: 50));

      // Verify +10s seek badge is visible
      expect(find.byType(DoubleTapSeekBadge), findsOneWidget);
      expect(find.text('+10s'), findsOneWidget);

      // Immediate 3rd tap accumulates to +20s
      await tester.tapAt(rightPos);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('+20s'), findsOneWidget);
    });

    testWidgets('double-tap left third seeks backward and displays badge', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Left third is x < 300 (out of 900 logical width), vertical center y = 225
      const leftPos = Offset(150, 225);

      await tester.tapAt(leftPos);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(leftPos);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DoubleTapSeekBadge), findsOneWidget);
      expect(find.text('-10s'), findsOneWidget);
    });

    testWidgets('long press triggers 2x hold speed without flashing controls overlay', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      // Let initial auto-hide countdown elapse so controls are hidden
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      const clearPos = Offset(200, 200);

      final gesture = await tester.startGesture(clearPos);
      // Wait 300ms (past former 260ms single-tap timer threshold, but before 500ms long-press threshold)
      await tester.pump(const Duration(milliseconds: 300));

      // Controls overlay must NOT have flashed visible!
      final opacityWidgetBefore = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(PlayerTopBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacityWidgetBefore.opacity, 0.0);

      // Wait past 500ms long-press threshold
      await tester.pump(const Duration(milliseconds: 300));

      // Verify 1.5x pill is shown and rate is accelerated
      expect(find.byType(HoldSpeedPill), findsOneWidget);
      expect(mockEngine.playbackRate, 1.5);

      // Release gesture
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify restored
      expect(find.byType(HoldSpeedPill), findsNothing);
      expect(mockEngine.playbackRate, 1.0);
    });

    testWidgets('vertical drag on right half adjusts volume HUD', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Right half (volume): x = 650, vertical center y = 225
      final gesture = await tester.startGesture(const Offset(650, 225));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, -100)); // drag up
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(VerticalSliderHud), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('vertical drag on left half adjusts brightness HUD', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Left half (brightness): x = 250, vertical center y = 225
      final gesture = await tester.startGesture(const Offset(250, 225));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, -100)); // drag up
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(VerticalSliderHud), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('horizontal scrub displays ScrubPreviewHud and seeks', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final gesture = await tester.startGesture(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(150, 0)); // drag right 150px
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ScrubPreviewHud), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ScrubPreviewHud), findsNothing);
    });
  });

  group('PlayerScreen - Settings Sheet & Side Panels', () {
    testWidgets('opens settings sheet and allows changing speed and quality', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Open settings
      await tester.tap(find.byTooltip('Playback Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerSettingsSheet), findsOneWidget);

      // Select Speed tab
      await tester.ensureVisible(find.text('Speed'));
      await tester.tap(find.text('Speed'));
      await tester.pumpAndSettle();

      expect(find.text('1.5x'), findsOneWidget);
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();

      expect(mockEngine.playbackRate, 1.5);
    });

    testWidgets('opens episode selector sheet when playlist button tapped', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Episodes'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Episodes'), findsWidgets);
    });

    testWidgets('opens more options side panel when 3-dot button tapped', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('More Options'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlayerMoreOptionsSheet), findsOneWidget);
    });
  });

  group('PlayerScreen - Resume & Next Episode', () {
    testWidgets('resumes from saved progress and displays toast', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final historyRepo = PlaybackHistoryRepository();
      // Pre-save 125 seconds of progress
      await historyRepo.savePlaybackProgress(400602, 1, positionSeconds: 125, totalDurationSeconds: 1440);

      await tester.pumpWidget(buildPlayerScreen(customRepo: historyRepo));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Resumed from 02:05'), findsOneWidget);
      expect(mockEngine.position.inSeconds, 125);
    });

    testWidgets('skip intro button seeks forward 85s', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SkipIntroButton), findsOneWidget);
      await tester.tap(find.byType(SkipIntroButton));
      await tester.pump(const Duration(milliseconds: 200));

      // Initial position was 30s, +85s -> 115s
      expect(mockEngine.position.inSeconds, 115);
    });

    testWidgets('shows next episode countdown card near end of playback', (tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlayerScreen());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Simulate position reaching last 4 seconds
      mockEngine.simulatePosition(const Duration(minutes: 23, seconds: 57));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(NextEpisodeCountdownCard), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
