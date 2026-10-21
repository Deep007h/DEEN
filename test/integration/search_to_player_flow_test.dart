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
import 'package:anime_stream/features/metadata/domain/models/anime_tag.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/player/data/services/device_controls_service.dart';

class FakeFlowMetadataRepository extends MetadataRepository {
  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    if (query.toLowerCase().contains('frieren')) {
      return [
        const AnimeSummary(
          id: 400602,
          titles: AnimeTitles(
            original: '葬送のフリーレン',
            english: "Frieren: Beyond Journey's End",
          ),
          score: 8.9,
          ratingCount: 42000,
          eps: 28,
          airDate: '2023-09-29',
        ),
      ];
    }
    return [];
  }

  @override
  Future<AnimeDetail> getAnimeDetail(int id, {CancelToken? cancelToken}) async {
    return const AnimeDetail(
      id: 400602,
      titles: AnimeTitles(
        original: '葬送のフリーレン',
        english: "Frieren: Beyond Journey's End",
      ),
      summary: 'After a 10-year quest, the elf mage Frieren and her party brought peace to the realm...',
      score: 8.9,
      ratingCount: 42000,
      airDate: '2023-09-29',
      eps: 28,
      tags: [
        AnimeTag(name: 'Fantasy', count: 1200),
        AnimeTag(name: 'Adventure', count: 980),
      ],
      seasons: [
        Season(id: 400602, name: 'Season 1', isCurrent: true),
      ],
      episodes: [
        Episode(
          id: 1227087,
          number: 1.0,
          sort: 1,
          title: 'The Journey Begins',
          titleOriginal: '冒険の終わり',
          airDate: '2023-09-29',
        ),
        Episode(
          id: 1227088,
          number: 2.0,
          sort: 2,
          title: 'It Did Not Have to Be Magic...',
          titleOriginal: '別に魔法じゃなくたって…',
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
  testWidgets('Integration Flow: Search -> Detail -> Play with Demo provider',
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
    final fakeRepo = FakeFlowMetadataRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataRepositoryProvider.overrideWithValue(fakeRepo),
          deviceControlsServiceProvider.overrideWithValue(MockDeviceControlsService()),
        ],
        child: const AnimeStreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigate from Home to Search screen
    final searchButtonFinder = find.byTooltip('Search anime');
    expect(searchButtonFinder, findsOneWidget);
    await tester.tap(searchButtonFinder);
    await tester.pumpAndSettle();

    // 2. On Search screen, search for "frieren"
    expect(find.text('Anime Search'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'frieren');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 3. Find and verify search result card
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();

    final cardFinder = find.text("Frieren: Beyond Journey's End");
    expect(cardFinder, findsOneWidget);
    expect(find.text('8.9'), findsOneWidget);

    // 4. Tap the result card to transition into DetailScreen
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // 5. Verify DetailScreen components (Header & Source Selector)
    expect(find.text('Source: Demo ▼'), findsOneWidget);

    // Scroll to see Synopsis and Episode list
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Synopsis'), findsOneWidget);
    expect(find.text('Season 1'), findsOneWidget);

    // Verify default grid view shows episode number
    expect(find.text('1'), findsWidgets);

    // Switch to list view to verify episode full title
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();

    expect(find.text('The Journey Begins'), findsOneWidget);

    // 6. Tap Episode 1 to resolve stream and launch PlayerScreen
    await tester.tap(find.text('The Journey Begins'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 7. Verify PlayerScreen controls and playback info
    expect(find.text("Frieren: Beyond Journey's End"), findsWidgets);
    expect(find.textContaining('Episode 01'), findsWidgets);
    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // 8. Exit player via back button to return to DetailScreen
    final backButton = find.byTooltip('Back');
    expect(backButton, findsWidgets);
    await tester.tap(backButton.first);
    await tester.pumpAndSettle();

    // 9. Back on DetailScreen, verify we're still on Frieren
    expect(find.text("Frieren: Beyond Journey's End"), findsWidgets);
  });
}
