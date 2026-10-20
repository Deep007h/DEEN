import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/home/presentation/screens/home_screen.dart';
import 'package:anime_stream/features/player/data/repositories/playback_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaybackHistoryRepository historyRepo;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    historyRepo = PlaybackHistoryRepository();
  });

  group('HomeScreen Continue Watching Tests', () {
    testWidgets('Continue Watching section is hidden when no watch history exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackHistoryRepositoryProvider.overrideWithValue(historyRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Watching'), findsNothing);
      expect(find.text('DEEN'), findsOneWidget);
    });

    testWidgets('Continue Watching carousel is displayed when history exists', (tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await historyRepo.savePlaybackProgress(
        400602,
        3,
        positionSeconds: 720,
        totalDurationSeconds: 1440,
        animeTitle: 'Sousou no Frieren',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackHistoryRepositoryProvider.overrideWithValue(historyRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.text('Ep 3 · 12:00 / 24:00'), findsOneWidget);
    });
  });
}
