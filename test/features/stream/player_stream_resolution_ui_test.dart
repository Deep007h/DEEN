import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/main.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';

class FakeMetadataRepo extends MetadataRepository {
  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    return [
      const AnimeSummary(
        id: 400602,
        titles: AnimeTitles(
          original: '葬送のフリーレン',
          english: "Frieren: Beyond Journey's End",
        ),
        score: 8.5,
        ratingCount: 36616,
        eps: 28,
        airDate: '2023-09-29',
      ),
    ];
  }

  @override
  Future<AnimeDetail> getAnimeDetail(int id, {CancelToken? cancelToken}) async {
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
          title: 'The End of the Beginning (冒险结束)',
          titleOriginal: '冒険の終わり',
          airDate: '2023-09-29',
        ),
      ],
    );
  }

  @override
  Future<List<Season>> getSeasons(int animeId, {CancelToken? cancelToken}) async {
    return const [Season(id: 400602, name: 'Season 1', isCurrent: true)];
  }

  @override
  Future<List<Episode>> getEpisodes(
    int animeId, {
    int limit = 100,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final detail = await getAnimeDetail(animeId);
    return detail.episodes;
  }
}

void main() {
  testWidgets('Acceptance: choosing episode from detail screen resolves variants from Demo provider with sub/dub and quality options in debug list',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({
      'stream_anime_selected_provider_400602': 'demo',
    });
    final fakeRepo = FakeMetadataRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const AnimeStreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. From Home, navigate to Search
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    // 2. Type "frieren"
    await tester.enterText(find.byType(TextField), 'frieren');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 3. Scroll and open Frieren detail
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Frieren: Beyond Journey's End"));
    await tester.pumpAndSettle();

    // 4. Verify Detail Screen has Server 1 chip
    expect(find.textContaining('Server 1'), findsOneWidget);

    // 5. Scroll down to episode list and switch to list view
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The End of the Beginning (冒险结束)'));
    // Wait for stream resolution and player screen build
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 6. Verify Player Screen content
    // Verify matched catalog title and episode subtitle in top bar
    expect(find.text("Frieren: Beyond Journey's End"), findsWidgets);
    expect(find.textContaining('Episode 01'), findsWidgets);

    // Verify center controls (Replay-10, Play/Pause, Forward-10)
    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // 7. Open Playback Settings via gear icon
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    // Verify Settings Sheet opened
    expect(find.text('Playback Settings'), findsOneWidget);

    // Verify Quality tab choices
    expect(find.text('Auto (1080p)'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('480p'), findsOneWidget);
    expect(find.text('360p'), findsOneWidget);

    // Test interactive quality selection: tap "720p"
    await tester.tap(find.text('720p'));
    await tester.pumpAndSettle();

    // Switch to Subtitles tab in Settings
    await tester.tap(find.text('Subtitles'));
    await tester.pumpAndSettle();

    expect(find.text('Off'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);

    // Switch to Audio tab in Settings
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(find.text('Japanese (Original)'), findsOneWidget);
    expect(find.text('English Dub'), findsOneWidget);
    expect(find.text('Hindi Dub'), findsOneWidget);

    // Test interactive variant selection: tap "English Dub"
    await tester.tap(find.text('English Dub'));
    await tester.pumpAndSettle();

    // Close settings sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap screen to bring controls back if hidden
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 300));

    // 8. Open Diagnostics Sheet from More Options menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byIcon(Icons.bug_report_outlined),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Resolution Trace Logs'), findsOneWidget);
  });
}
