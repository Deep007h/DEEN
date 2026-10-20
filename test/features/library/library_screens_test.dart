import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/library/domain/models/followed_anime.dart';
import 'package:anime_stream/features/library/data/repositories/follow_repository.dart';
import 'package:anime_stream/features/library/presentation/providers/library_providers.dart';
import 'package:anime_stream/features/library/presentation/screens/following_screen.dart';
import 'package:anime_stream/features/library/presentation/screens/recent_screen.dart';
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

  group('FollowingScreen Tests', () {
    testWidgets('Displays empty state when no anime followed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followRepositoryProvider.overrideWithValue(followRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FollowingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No followed anime yet'), findsOneWidget);
      expect(find.text('Bookmark your favorite anime to receive updates on new episodes.'), findsOneWidget);
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
            home: Scaffold(body: FollowingScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card is displayed
      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.text('8.9'), findsOneWidget);

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

  group('RecentScreen Tests', () {
    testWidgets('Displays empty state when no watch history', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackHistoryRepositoryProvider.overrideWithValue(historyRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RecentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No watch history'), findsOneWidget);
      expect(find.text("Anime you've watched will show up here so you can easily pick up where you left off."), findsOneWidget);
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
            home: Scaffold(body: RecentScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and episode progress text
      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.text('Episode 5 · 12:00 / 24:00'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Clear all button exists in app bar
      expect(find.text('Clear all'), findsOneWidget);

      // Tap Clear all
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Clear Watch History'), findsOneWidget);
      expect(find.text('Are you sure you want to clear your entire watch history? This action cannot be undone.'), findsOneWidget);

      // Tap Clear All in dialog
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // History is now empty
      expect(find.text('No watch history'), findsOneWidget);
    });
  });
}
