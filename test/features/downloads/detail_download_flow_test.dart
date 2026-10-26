import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/detail/presentation/screens/detail_screen.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/metadata/domain/models/episode.dart';
import 'package:anime_stream/features/downloads/presentation/providers/download_providers.dart';
import 'package:anime_stream/features/downloads/data/download_service.dart';
import 'package:anime_stream/features/settings/data/repositories/app_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  group('DetailScreen Download Mode Tests', () {
    testWidgets('Renders Watch and Download pills, allows episode selection, and displays download action bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testDetail = AnimeDetail(
        id: 400602,
        titles: AnimeTitles(original: 'Frieren', english: "Frieren: Beyond Journey's End"),
        score: 9.3,
        eps: 3,
        summary: 'After the defeat of the demon king...',
        episodes: [
          Episode(id: 1, sort: 1, number: 1, title: 'The End of the Journey'),
          Episode(id: 2, sort: 2, number: 2, title: 'It Was Truly Fun'),
          Episode(id: 3, sort: 3, number: 3, title: 'Killing Magic'),
        ],
      );

      final prefs = await SharedPreferences.getInstance();
      final downloadService = DownloadService(prefs: prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            downloadServiceProvider.overrideWith((ref) => downloadService),
            animeDetailProvider(400602).overrideWith((ref) async => testDetail),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DetailScreen(animeId: '400602'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Watch and Download pills exist
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      // Initially in Watch mode (no bottom download bar)
      expect(find.text('Download (1)'), findsNothing);

      // Tap "Download" mode pill
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      // In Download mode: "Select All" should be visible
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('No episodes selected'), findsOneWidget);

      // Tap Episode 1 to select it
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Now 1 episode is selected
      expect(find.text('1 Episode(s) selected'), findsOneWidget);
      expect(find.text('Download (1)'), findsOneWidget);

      // Tap "Select All"
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // All 3 episodes selected
      expect(find.text('3 Episode(s) selected'), findsOneWidget);
      expect(find.text('Download (3)'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);

      // Tap "Download (3)" button
      await tester.tap(find.text('Download (3)'));
      await tester.pumpAndSettle();

      // Selection clears after starting download
      expect(find.text('No episodes selected'), findsOneWidget);
    });
  });
}
