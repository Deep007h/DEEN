import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';
import '../../../player/domain/models/watch_history_item.dart';
import '../../domain/models/followed_anime.dart';

export '../../../metadata/presentation/providers/metadata_providers.dart'
    show followRepositoryProvider, playbackHistoryRepositoryProvider;

/// Active sort option in the Following tab.
final followSortProvider = StateProvider<FollowSort>((ref) {
  return FollowSort.recentlyFollowed;
});

/// Raw stream of followed anime items from repository.
final rawFollowedStreamProvider = StreamProvider<List<FollowedAnime>>((ref) {
  final repo = ref.watch(followRepositoryProvider);
  return repo.followedAnimeStream;
});

/// Provider for sorted followed anime items.
final followedAnimeListProvider = FutureProvider<List<FollowedAnime>>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  final sort = ref.watch(followSortProvider);
  // Re-evaluate whenever followed items stream emits
  ref.watch(rawFollowedStreamProvider);
  return repo.getFollowedList(sort: sort);
});

/// Raw stream of watch history items from repository.
final rawWatchHistoryStreamProvider = StreamProvider<List<WatchHistoryItem>>((ref) {
  final repo = ref.watch(playbackHistoryRepositoryProvider);
  return repo.watchHistoryStream;
});

/// Provider for watch history list ordered chronologically.
final watchHistoryListProvider = FutureProvider<List<WatchHistoryItem>>((ref) async {
  final repo = ref.watch(playbackHistoryRepositoryProvider);
  // Re-evaluate whenever history stream emits
  ref.watch(rawWatchHistoryStreamProvider);
  return repo.getHistoryList();
});

/// Computes remaining unwatched episodes for a given anime.
final unwatchedCountProvider = FutureProvider.autoDispose.family<int, int>((ref, animeId) async {
  final historyRepo = ref.watch(playbackHistoryRepositoryProvider);
  final lastWatchedEp = await historyRepo.getLastWatchedEpisode(animeId);
  final list = await ref.watch(followedAnimeListProvider.future);

  final match = list.where((item) => item.id == animeId);
  if (match.isEmpty) return 0;

  final total = match.first.totalEpisodes;
  if (total <= 0) return 0;
  if (lastWatchedEp == null) return total;

  return (total - lastWatchedEp).clamp(0, total).toInt();
});
