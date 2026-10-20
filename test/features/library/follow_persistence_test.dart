import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/features/library/data/repositories/follow_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('FollowRepository Local Persistence Tests', () {
    test('Toggling follow adds anime ID and persists', () async {
      final repo = FollowRepository();

      // Initially not following
      expect(await repo.isFollowing(400602), isFalse);

      // Follow anime
      final followed = await repo.toggleFollow(400602);
      expect(followed, isTrue);
      expect(await repo.isFollowing(400602), isTrue);

      final ids = await repo.getFollowedIds();
      expect(ids.contains(400602), isTrue);

      // Verify persistence by creating a fresh repository instance
      final freshRepo = FollowRepository();
      expect(await freshRepo.isFollowing(400602), isTrue);

      // Unfollow
      final unfollowed = await repo.toggleFollow(400602);
      expect(unfollowed, isFalse);
      expect(await repo.isFollowing(400602), isFalse);
    });
  });
}
