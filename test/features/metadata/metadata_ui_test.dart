import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:anime_stream/main.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_tag.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';

class FakeMetadataRepository extends MetadataRepository {
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
            localized: '葬送的芙莉莲',
          ),
          score: 8.5,
          ratingCount: 36616,
          rank: 43,
          eps: 28,
          airDate: '2023-09-29',
          platform: 'TV',
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
        localized: '葬送的芙莉莲',
      ),
      summary: 'Elven mage Frieren and her party defeated the Demon King...',
      score: 8.5,
      ratingCount: 36616,
      rank: 43,
      airDate: '2023-09-29',
      eps: 28,
      platform: 'TV',
      tags: [
        AnimeTag(name: 'Healing / 治愈', count: 8131),
        AnimeTag(name: 'Fantasy / 奇幻', count: 6455),
      ],
      seasons: [
        Season(id: 400602, name: 'Season 1', isCurrent: true),
        Season(id: 515759, name: 'Season 2', isCurrent: false),
      ],
      episodes: [
        Episode(
          id: 1227087,
          number: 1.0,
          sort: 1,
          title: 'The End of the Beginning (冒险结束)',
          titleOriginal: '冒険の終わり',
          airDate: '2023-09-29',
          duration: '00:26:00',
        ),
        Episode(
          id: 1227088,
          number: 2.0,
          sort: 2,
          title: "It Didn't Have to Be Magic... (不见得一定是靠魔法…)",
          titleOriginal: '別に魔法じゃなくたって…',
          airDate: '2023-09-29',
          duration: '00:26:00',
        ),
      ],
    );
  }

  @override
  Future<List<Episode>> getEpisodes(int animeId, {CancelToken? cancelToken}) async {
    final detail = await getAnimeDetail(animeId);
    return detail.episodes;
  }

  @override
  Future<List<Season>> getSeasons(int animeId, {CancelToken? cancelToken}) async {
    final detail = await getAnimeDetail(animeId);
    return detail.seasons;
  }
}

void main() {
  testWidgets('Search "frieren" displays parsed card and opens detail with seasons, tags, and episodes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeMetadataRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const AnimeStreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // From Home, tap the search button to navigate to /search
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    // Verify on search screen
    expect(find.text('Anime Search'), findsOneWidget);

    // Type "frieren" into the search field
    await tester.enterText(find.byType(TextField), 'frieren');
    // Wait for the 400ms debounce
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify parsed search result card
    expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);

    // Scroll down to ensure search card is in viewport and tap it
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Frieren: Beyond Journey's End"));
    await tester.pumpAndSettle();

    // Verify detail screen content
    expect(find.text('葬送のフリーレン'), findsOneWidget);
    expect(find.text('Rank #43'), findsOneWidget);
    expect(find.text('Synopsis'), findsOneWidget);

    // Verify seasons selector
    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);

    // Verify tags
    expect(find.text('Healing / 治愈 8131'), findsOneWidget);
    expect(find.text('Fantasy / 奇幻 6455'), findsOneWidget);

    // Scroll down to reveal episode list in CustomScrollView
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    // Verify default grid view shows episode number
    expect(find.text('1'), findsWidgets);

    // Switch to list view to verify episode full title
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();

    // Verify episode list
    expect(find.text('The End of the Beginning (冒险结束)'), findsOneWidget);
    expect(find.text("It Didn't Have to Be Magic... (不见得一定是靠魔法…)"), findsOneWidget);
  });
}
