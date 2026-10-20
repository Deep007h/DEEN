import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/home/presentation/screens/home_screen.dart';
import 'package:anime_stream/features/home/presentation/providers/home_providers.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/detail/presentation/screens/detail_screen.dart';
import 'package:anime_stream/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/metadata/domain/models/season.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:dio/dio.dart';

class _FakeRepo extends MetadataRepository {
  @override
  Future<List<AnimeSummary>> searchAnime(
    String query, {
    SearchSort sort = SearchSort.match,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async => [];

  @override
  Future<AnimeDetail> getAnimeDetail(int id, {CancelToken? cancelToken}) async {
    return const AnimeDetail(
      id: 999001,
      titles: AnimeTitles(
        original: 'オーバーギアード',
        english: 'Overgeared',
      ),
      summary: 'Sin Yeong-U finds a powerful VR game item.',
      score: 7.6,
      eps: 12,
      seasons: [Season(id: 999001, name: 'Season 1', isCurrent: true)],
      episodes: [
        Episode(id: 1, number: 1.0, sort: 1, title: 'Episode 1'),
        Episode(id: 2, number: 2.0, sort: 2, title: 'Episode 2'),
        Episode(id: 3, number: 3.0, sort: 3, title: 'Episode 3'),
      ],
    );
  }

  @override
  Future<List<Season>> getSeasons(int animeId, {CancelToken? cancelToken}) async {
    return const [Season(id: 999001, name: 'Season 1', isCurrent: true)];
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  group('Spotlight Billboard & Detail Grid Default Tests', () {
    testWidgets('Spotlight billboard displays featured anime and has Hero animation tag', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final featuredItems = [
        const FeaturedAnimeItem(
          id: 999001,
          titles: AnimeTitles(original: 'オーバーギアード', english: 'Overgeared'),
          score: 7.6,
          format: 'ONA',
          eps: 12,
          summary: 'Sin Yeong-U finds a powerful legendary item in the popular VR game.',
          bannerUrl: 'https://example.com/overgeared_banner.jpg',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredAnimeProvider.overrideWith((ref) async => featuredItems),
            metadataRepositoryProvider.overrideWithValue(_FakeRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify billboard title and trending badge
      expect(find.text('Overgeared'), findsWidgets);
      expect(find.text('#1 Trending'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);

      // Verify Hero widget is configured on billboard
      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'poster_999001_home_spotlight',
      );
      expect(heroFinder, findsOneWidget);
    });

    testWidgets('DetailScreen defaults to grid view for episodes and allows switching to list view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataRepositoryProvider.overrideWithValue(_FakeRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DetailScreen(animeId: '999001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to episodes section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify default is Grid View: episodes numbers are displayed in grid
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);

      // Verify segmented button switchers
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);

      // Switch to List View
      await tester.tap(find.byIcon(Icons.view_list_rounded));
      await tester.pumpAndSettle();

      // In list view, full episode titles are shown
      expect(find.text('Episode 1'), findsOneWidget);
      expect(find.text('Episode 2'), findsOneWidget);
      expect(find.text('Episode 3'), findsOneWidget);
    });
  });
}
