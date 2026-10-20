import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/features/player/domain/models/watch_history_item.dart';
import 'package:anime_stream/features/player/data/repositories/playback_history_repository.dart';
import 'package:anime_stream/features/library/domain/models/followed_anime.dart';
import 'package:anime_stream/features/settings/domain/models/data_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('WatchHistoryItem Model Tests', () {
    test('Calculates progressFraction and isCompleted correctly', () {
      final itemInProgress = WatchHistoryItem(
        animeId: 1,
        episodeNumber: 3,
        animeTitle: 'Frieren',
        positionSeconds: 720,
        totalDurationSeconds: 1440,
        lastWatchedAt: DateTime.now(),
      );

      expect(itemInProgress.progressFraction, 0.5);
      expect(itemInProgress.isCompleted, isFalse);
      expect(itemInProgress.formattedProgress, '12:00 / 24:00');

      final itemCompleted = itemInProgress.copyWith(positionSeconds: 1350);
      expect(itemCompleted.progressFraction, closeTo(0.937, 0.01));
      expect(itemCompleted.isCompleted, isTrue);
    });

    test('Formats duration > 1 hour correctly', () {
      final movieItem = WatchHistoryItem(
        animeId: 2,
        episodeNumber: 1,
        animeTitle: 'Anime Movie',
        positionSeconds: 3665, // 1h 1m 5s
        totalDurationSeconds: 7200, // 2h 0m 0s
        lastWatchedAt: DateTime.now(),
      );

      expect(movieItem.formattedProgress, '1:01:05 / 2:00:00');
    });

    test('JSON serialization roundtrip', () {
      final item = WatchHistoryItem(
        animeId: 55,
        episodeNumber: 12,
        animeTitle: 'Steins;Gate',
        posterUrl: 'https://example.com/sg.jpg',
        positionSeconds: 1200,
        totalDurationSeconds: 1440,
        lastWatchedAt: DateTime.parse('2026-02-15T20:30:00Z'),
      );

      final json = item.toJson();
      final restored = WatchHistoryItem.fromJson(json);

      expect(restored.animeId, 55);
      expect(restored.episodeNumber, 12);
      expect(restored.animeTitle, 'Steins;Gate');
      expect(restored.posterUrl, 'https://example.com/sg.jpg');
      expect(restored.positionSeconds, 1200);
      expect(restored.totalDurationSeconds, 1440);
      expect(restored.lastWatchedAt, DateTime.parse('2026-02-15T20:30:00Z'));
    });
  });

  group('PlaybackHistoryRepository Tests', () {
    test('savePlaybackProgress records and updates history list', () async {
      final repo = PlaybackHistoryRepository();

      await repo.savePlaybackProgress(
        101,
        1,
        positionSeconds: 600,
        totalDurationSeconds: 1400,
        animeTitle: 'Jujutsu Kaisen',
        posterUrl: 'https://example.com/jjk.jpg',
      );

      final list = await repo.getHistoryList();
      expect(list.length, 1);
      expect(list.first.animeId, 101);
      expect(list.first.episodeNumber, 1);
      expect(list.first.positionSeconds, 600);
      expect(list.first.animeTitle, 'Jujutsu Kaisen');

      // Check episode progress fraction was also stored
      final progress = await repo.getEpisodeProgress(101, 1);
      expect(progress, closeTo(600 / 1400, 0.01));
    });

    test('Saving progress for same anime updates to top of list', () async {
      final repo = PlaybackHistoryRepository();

      await repo.savePlaybackProgress(
        1,
        1,
        positionSeconds: 100,
        totalDurationSeconds: 1000,
        animeTitle: 'Anime One',
      );
      await repo.savePlaybackProgress(
        2,
        1,
        positionSeconds: 200,
        totalDurationSeconds: 1000,
        animeTitle: 'Anime Two',
      );

      var list = await repo.getHistoryList();
      expect(list.map((e) => e.animeId).toList(), [2, 1]);

      // Now watch Anime One episode 2
      await repo.savePlaybackProgress(
        1,
        2,
        positionSeconds: 300,
        totalDurationSeconds: 1000,
        animeTitle: 'Anime One',
      );

      list = await repo.getHistoryList();
      expect(list.length, 2);
      expect(list.first.animeId, 1);
      expect(list.first.episodeNumber, 2);
    });

    test('deleteHistoryItem removes anime record', () async {
      final repo = PlaybackHistoryRepository();

      await repo.savePlaybackProgress(10, 1, positionSeconds: 10, totalDurationSeconds: 100);
      await repo.savePlaybackProgress(20, 1, positionSeconds: 20, totalDurationSeconds: 100);

      expect((await repo.getHistoryList()).length, 2);

      await repo.deleteHistoryItem(10);
      final list = await repo.getHistoryList();
      expect(list.length, 1);
      expect(list.first.animeId, 20);
    });

    test('clearAllHistory removes all records', () async {
      final repo = PlaybackHistoryRepository();

      await repo.savePlaybackProgress(10, 1, positionSeconds: 10, totalDurationSeconds: 100);
      await repo.savePlaybackProgress(20, 1, positionSeconds: 20, totalDurationSeconds: 100);

      await repo.clearAllHistory();
      expect((await repo.getHistoryList()).isEmpty, isTrue);
    });
  });

  group('DataBackup JSON Export & Import Tests', () {
    test('DataBackup serializes and parses correctly', () {
      final backup = DataBackup(
        exportedAt: DateTime.parse('2026-03-01T00:00:00Z'),
        favorites: [
          FollowedAnime(id: 1, title: 'Fav 1', followedAt: DateTime.parse('2026-01-01T00:00:00Z')),
        ],
        history: [
          WatchHistoryItem(
            animeId: 2,
            episodeNumber: 5,
            animeTitle: 'Hist 2',
            positionSeconds: 500,
            totalDurationSeconds: 1000,
            lastWatchedAt: DateTime.parse('2026-02-01T00:00:00Z'),
          ),
        ],
      );

      final jsonStr = backup.toFormattedJson();
      final parsed = DataBackup.tryParse(jsonStr);

      expect(parsed, isNotNull);
      expect(parsed!.version, 1);
      expect(parsed.favorites.length, 1);
      expect(parsed.favorites.first.title, 'Fav 1');
      expect(parsed.history.length, 1);
      expect(parsed.history.first.animeTitle, 'Hist 2');
      expect(parsed.history.first.episodeNumber, 5);
    });
  });
}
