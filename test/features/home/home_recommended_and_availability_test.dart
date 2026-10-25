import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/home/presentation/screens/home_screen.dart';
import 'package:anime_stream/features/home/presentation/providers/home_providers.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen Recommended For You & Availability Filtering Tests', () {
    testWidgets('Recommended for You renders dynamic anime cards with score and eps badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final recommendedItems = [
        const AnimeSummary(
          id: 101922,
          titles: AnimeTitles(
            original: 'Kimetsu no Yaiba',
            english: 'Demon Slayer: Kimetsu no Yaiba',
            localized: 'Demon Slayer',
          ),
          posterUrl: 'https://example.com/demonslayer.jpg',
          score: 8.6,
          eps: 26,
          platform: 'TV',
        ),
        const AnimeSummary(
          id: 151801,
          titles: AnimeTitles(
            original: 'Ore dake Level Up na Ken',
            english: 'Solo Leveling',
            localized: 'Solo Leveling',
          ),
          posterUrl: 'https://example.com/sololeveling.jpg',
          score: 8.9,
          eps: 12,
          platform: 'TV',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredAnimeProvider.overrideWith((ref) async => []),
            trendingAnimeProvider.overrideWith((ref) async => []),
            recommendedAnimeProvider.overrideWith((ref) async => recommendedItems),
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

      // Verify "Recommended for You" section header exists
      expect(find.text('Recommended for You'), findsOneWidget);

      // Verify the dynamic titles are displayed
      expect(find.text('Demon Slayer: Kimetsu no Yaiba'), findsOneWidget);
      expect(find.text('Solo Leveling'), findsOneWidget);

      // Verify badges: ratings and episodes
      expect(find.text('8.6'), findsOneWidget);
      expect(find.text('26 eps'), findsOneWidget);
      expect(find.text('8.9'), findsOneWidget);
      expect(find.text('12 eps'), findsOneWidget);

      // Verify hardcoded characters no longer exist
      expect(find.text('Gojo Satoru'), findsNothing);
      expect(find.text('Ken Kaneki'), findsNothing);
    });

    testWidgets('Tapping Recommended tab filters to Recommended', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll horizontal pill bar so 'Recommended' is fully within view
      await tester.drag(find.text('Anime'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Tap Recommended pill
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();

      expect(container.read(homeGenreFilterProvider), equals('Recommended'));
    });
  });
}
