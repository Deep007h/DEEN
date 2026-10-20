import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/features/library/domain/models/followed_anime.dart';
import 'package:anime_stream/features/library/data/repositories/follow_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('FollowRepository Tests', () {
    test('FollowedAnime JSON serialization roundtrip', () {
      final item = FollowedAnime(
        id: 12345,
        title: 'Sousou no Frieren',
        nameCn: '葬送的芙莉莲',
        posterUrl: 'https://example.com/frieren.jpg',
        score: 8.9,
        totalEpisodes: 28,
        followedAt: DateTime.parse('2026-01-01T12:00:00Z'),
      );

      final json = item.toJson();
      final restored = FollowedAnime.fromJson(json);

      expect(restored.id, 12345);
      expect(restored.title, 'Sousou no Frieren');
      expect(restored.nameCn, '葬送的芙莉莲');
      expect(restored.posterUrl, 'https://example.com/frieren.jpg');
      expect(restored.score, 8.9);
      expect(restored.totalEpisodes, 28);
      expect(restored.followedAt, DateTime.parse('2026-01-01T12:00:00Z'));
    });

    test('Follow anime with rich metadata and verify persistence', () async {
      final repo = FollowRepository();

      expect(await repo.isFollowing(101), isFalse);

      final item = FollowedAnime(
        id: 101,
        title: 'Attack on Titan',
        score: 8.8,
        totalEpisodes: 25,
        followedAt: DateTime.now(),
      );

      await repo.follow(item);

      expect(await repo.isFollowing(101), isTrue);
      final list = await repo.getFollowedList();
      expect(list.length, 1);
      expect(list.first.title, 'Attack on Titan');

      // Verify persistence across repository instances
      final freshRepo = FollowRepository();
      expect(await freshRepo.isFollowing(101), isTrue);
      final freshList = await freshRepo.getFollowedList();
      expect(freshList.length, 1);
      expect(freshList.first.id, 101);
    });

    test('Follow list sorting by recentlyFollowed, title, and score', () async {
      final repo = FollowRepository();

      final a = FollowedAnime(
        id: 1,
        title: 'Bleach',
        score: 7.9,
        followedAt: DateTime(2026, 1, 1),
      );
      final b = FollowedAnime(
        id: 2,
        title: 'Attack on Titan',
        score: 8.8,
        followedAt: DateTime(2026, 1, 3),
      );
      final c = FollowedAnime(
        id: 3,
        title: 'Chainsaw Man',
        score: 8.2,
        followedAt: DateTime(2026, 1, 2),
      );

      await repo.follow(a);
      await repo.follow(b);
      await repo.follow(c);

      // Sort by recently followed (b, then c, then a)
      final byRecent = await repo.getFollowedList(sort: FollowSort.recentlyFollowed);
      expect(byRecent.map((e) => e.id).toList(), [2, 3, 1]);

      // Sort by title alphabetical (Attack on Titan, Bleach, Chainsaw Man)
      final byTitle = await repo.getFollowedList(sort: FollowSort.title);
      expect(byTitle.map((e) => e.title).toList(), ['Attack on Titan', 'Bleach', 'Chainsaw Man']);

      // Sort by score descending (8.8, 8.2, 7.9 -> 2, 3, 1)
      final byScore = await repo.getFollowedList(sort: FollowSort.score);
      expect(byScore.map((e) => e.score).toList(), [8.8, 8.2, 7.9]);
    });

    test('Unfollowing anime removes it from list and IDs', () async {
      final repo = FollowRepository();

      await repo.follow(FollowedAnime(
        id: 999,
        title: 'One Piece',
        followedAt: DateTime.now(),
      ));

      expect(await repo.isFollowing(999), isTrue);
      expect((await repo.getFollowedList()).length, 1);

      await repo.unfollow(999);
      expect(await repo.isFollowing(999), isFalse);
      expect((await repo.getFollowedList()).isEmpty, isTrue);
    });

    test('replaceFollowedList replaces entire cache and persists', () async {
      final repo = FollowRepository();

      await repo.follow(FollowedAnime(id: 1, title: 'Old', followedAt: DateTime.now()));

      final imported = [
        FollowedAnime(id: 10, title: 'Imported A', followedAt: DateTime.now()),
        FollowedAnime(id: 20, title: 'Imported B', followedAt: DateTime.now()),
      ];

      await repo.replaceFollowedList(imported);

      final list = await repo.getFollowedList();
      expect(list.length, 2);
      expect(list.map((e) => e.id).toSet(), {10, 20});
      expect(await repo.isFollowing(1), isFalse);
      expect(await repo.isFollowing(10), isTrue);
    });
  });
}
