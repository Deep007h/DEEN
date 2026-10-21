import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/library/domain/models/followed_anime.dart';
import 'package:anime_stream/features/library/data/repositories/follow_repository.dart';
import 'package:anime_stream/features/library/presentation/providers/library_providers.dart';
import 'package:anime_stream/features/library/presentation/screens/library_screen.dart';
import 'package:anime_stream/features/player/data/repositories/playback_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FollowRepository followRepo;
  late PlaybackHistoryRepository historyRepo;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    followRepo = FollowRepository();
    historyRepo = PlaybackHistoryRepository();
  });

  group('LibraryScreen Following Tests', () {
    testWidgets('Displays empty state when no anime followed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followRepositoryProvider.overrideWithValue(followRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No followed anime yet'), findsOneWidget);
      expect(find.text('Tap the star on any anime detail to follow it'), findsOneWidget);
    });

    testWidgets('Displays followed anime cards and handles unfollow with undo', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await followRepo.follow(
        FollowedAnime(
          id: 101,
          title: 'Sousou no Frieren',
          score: 8.9,
          totalEpisodes: 28,
          followedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followRepositoryProvider.overrideWithValue(followRepo),
            playbackHistoryRepositoryProvider.overrideWithValue(historyRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LibraryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card is displayed
      expect(find.text('Sousou no Frieren'), findsOneWidget);

      // Long press card to trigger unfollow dialog
      await tester.longPress(find.text('Sousou no Frieren'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Unfollow Sousou no Frieren?'), findsOneWidget);
      expect(find.text('Unfollow'), findsOneWidget);

      // Tap Unfollow
      await tester.tap(find.text('Unfollow'));
      await tester.pumpAndSettle();

      // Item is removed, empty state appears
      expect(find.text('No followed anime yet'), findsOneWidget);

      // Undo snackbar is visible
      expect(find.text('Unfollowed Sousou no Frieren'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Item is restored
      expect(find.text('Sousou no Frieren'), findsOneWidget);
    });
  });

  group('LibraryScreen History Tests', () {
    testWidgets('Displays empty state when no watch history', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackHistoryRepositoryProvider.overrideWithValue(historyRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.textContaining('History'));
      await tester.pumpAndSettle();

      expect(find.text('No watch history yet'), findsOneWidget);
      expect(find.text('Played episodes will automatically appear here'), findsOneWidget);
    });

    testWidgets('Displays watch history items with progress bar and Clear All', (tester) async {
      await historyRepo.savePlaybackProgress(
        101,
        5,
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
            home: Scaffold(body: LibraryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.textContaining('History'));
      await tester.pumpAndSettle();

      // Verify title and episode progress text
      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.text('Episode 5'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Clear button exists in header
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Clear Watch History'), findsOneWidget);
      expect(find.text('Remove all items from your playback history?'), findsOneWidget);

      // Tap Clear in dialog
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Clear')));
      await tester.pumpAndSettle();

      // History is now empty
      expect(find.text('No watch history yet'), findsOneWidget);
    });
  });
}
