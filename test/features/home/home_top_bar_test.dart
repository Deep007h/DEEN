import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/home/presentation/screens/home_screen.dart';
import 'package:anime_stream/features/home/presentation/providers/home_providers.dart';
import 'package:anime_stream/features/metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen Fixed Auto-Hiding Top Bar Tests', () {
    testWidgets('Top bar renders fixed with DEEN logo, filter pills, and auto-hides/shows on scroll', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final featuredItems = [
        const FeaturedAnimeItem(
          id: 999001,
          titles: AnimeTitles(original: 'Test Anime', english: 'Test Anime'),
          score: 8.5,
          eps: 12,
          summary: 'A test summary.',
          bannerUrl: 'https://example.com/banner.jpg',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredAnimeProvider.overrideWith((ref) async => featuredItems),
            trendingAnimeProvider.overrideWith((ref) async => []),
            recommendedAnimeProvider.overrideWith((ref) async => []),
            topRatedAnimeProvider.overrideWith((ref) async => []),
            recentlyAddedAnimeProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Top Bar brand elements & pills exist
      expect(find.text('DEEN'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);

      // 2. Initial state: Top bar is visible (translate Y == 0, opacity == 1)
      final topBarTransform = tester.widget<Transform>(
        find.ancestor(
          of: find.text('Stream Anime Your Way'),
          matching: find.byType(Transform),
        ).first,
      );
      expect(topBarTransform.transform.getTranslation().y, equals(0.0));

      // 3. Scroll DOWN by 300px
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify top bar translated up (negative Y)
      final scrolledTransform = tester.widget<Transform>(
        find.ancestor(
          of: find.text('Stream Anime Your Way'),
          matching: find.byType(Transform),
        ).first,
      );
      expect(scrolledTransform.transform.getTranslation().y, lessThan(0.0));

      // 4. Scroll UP by 150px
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify top bar auto-reveals back towards 0
      final revealedTransform = tester.widget<Transform>(
        find.ancestor(
          of: find.text('Stream Anime Your Way'),
          matching: find.byType(Transform),
        ).first,
      );
      expect(revealedTransform.transform.getTranslation().y, greaterThan(-10.0));
    });

    testWidgets('Horizontal drag in carousels/lists does not hide the top bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredAnimeProvider.overrideWith((ref) async => []),
            trendingAnimeProvider.overrideWith((ref) async => []),
            recommendedAnimeProvider.overrideWith((ref) async => []),
            topRatedAnimeProvider.overrideWith((ref) async => []),
            recentlyAddedAnimeProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar starts fully visible
      final initialTransform = tester.widget<Transform>(
        find.ancestor(
          of: find.text('Stream Anime Your Way'),
          matching: find.byType(Transform),
        ).first,
      );
      expect(initialTransform.transform.getTranslation().y, equals(0.0));

      // Drag HORIZONTALLY in the pill bar / carousel (X = -200, Y = 0)
      await tester.drag(find.text('Anime'), const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Top bar must remain fully visible (translation Y must be exactly 0.0)
      final postHorizontalTransform = tester.widget<Transform>(
        find.ancestor(
          of: find.text('Stream Anime Your Way'),
          matching: find.byType(Transform),
        ).first,
      );
      expect(postHorizontalTransform.transform.getTranslation().y, equals(0.0));
    });

    testWidgets('Pull to refresh edgeOffset is below top bar height', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredAnimeProvider.overrideWith((ref) async => []),
            trendingAnimeProvider.overrideWith((ref) async => []),
            recommendedAnimeProvider.overrideWith((ref) async => []),
            topRatedAnimeProvider.overrideWith((ref) async => []),
            recentlyAddedAnimeProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      // edgeOffset must be placed below the top bar (topPadding + 104 + 6 > 100)
      expect(refreshIndicator.edgeOffset, greaterThan(100.0));
    });
  });
}
