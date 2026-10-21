import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/floating_nav_bar.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/library_providers.dart';

/// Unified Library Screen presenting Followed anime and Watch History with Material 3 SegmentedButton.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0; // 0: Following, 1: History

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final followedAsync = ref.watch(followedAnimeListProvider);
    final historyAsync = ref.watch(watchHistoryListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        key: PageStorageKey<String>('library_scroll_$_selectedTab'),
        physics: AppMotion.m3ScrollPhysics,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_selectedTab == 1 && (historyAsync.value?.isNotEmpty ?? false))
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.modalBorder),
                                  title: const Text('Clear Watch History'),
                                  content: const Text('Remove all items from your playback history?'),
                                  actions: [
                                    TextButton(
                                      style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.error,
                                        foregroundColor: theme.colorScheme.onError,
                                        minimumSize: const Size(64, 48),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final repo = ref.read(playbackHistoryRepositoryProvider);
                                await repo.clearAllHistory();
                                ref.invalidate(watchHistoryListProvider);
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Material 3 SegmentedButton
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: [
                        ButtonSegment<int>(
                          value: 0,
                          icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
                          label: Text('Following (${followedAsync.value?.length ?? 0})'),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: Text('History (${historyAsync.value?.length ?? 0})'),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (newSelection) {
                        if (newSelection.isNotEmpty) {
                          setState(() => _selectedTab = newSelection.first);
                        }
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_selectedTab == 0)
            followedAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_border_rounded, size: 56, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          const Text('No followed anime yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Tap the star on any anime detail to follow it', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.go('/explore'),
                            icon: const Icon(Icons.explore_rounded, size: 18),
                            label: const Text('Explore Anime'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = list[index];
                        return GestureDetector(
                          onTap: () => context.push(
                            '/anime/${item.id}',
                            extra: {
                              'posterUrl': item.posterUrl,
                              'title': item.title,
                              'heroTag': 'poster_${item.id}',
                            },
                          ),
                          onLongPress: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                shape: const RoundedRectangleBorder(borderRadius: AppRadius.modalBorder),
                                title: Text('Unfollow ${item.title}?'),
                                content: const Text('Remove this anime from your bookmarks?'),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor: theme.colorScheme.onError,
                                      minimumSize: const Size(64, 48),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Unfollow'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final repo = ref.read(followRepositoryProvider);
                              await repo.unfollow(item.id);
                              ref.invalidate(followedAnimeListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.surfaceElevated,
                                    content: Text('Unfollowed ${item.title}'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: AppColors.accent,
                                      onPressed: () async {
                                        await repo.follow(item);
                                        ref.invalidate(followedAnimeListProvider);
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Hero(
                                    tag: 'poster_${item.id}',
                                    createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                                    child: CachedNetworkImage(
                                      imageUrl: item.posterUrl ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (_, __) => Container(color: const Color(0xFF1E1E26)),
                                      errorWidget: (_, __, ___) => Container(
                                        color: const Color(0xFF1E1E26),
                                        child: const Icon(Icons.broken_image, color: Colors.white24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            )
          else
            historyAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 56, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          const Text('No watch history yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Played episodes will automatically appear here', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.go('/explore'),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Start Watching'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = list[index];
                        final progress = item.progressFraction;
                        return Dismissible(
                          key: Key('hist_${item.animeId}_${item.episodeNumber}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.delete_rounded, color: theme.colorScheme.onErrorContainer),
                          ),
                          onDismissed: (_) async {
                            final repo = ref.read(playbackHistoryRepositoryProvider);
                            await repo.deleteHistoryItem(item.animeId, item.episodeNumber);
                            ref.invalidate(watchHistoryListProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.surfaceElevated,
                                  content: Text(
                                    'Removed "${item.animeTitle.isNotEmpty ? item.animeTitle : 'Episode ${item.episodeNumber}'}" from history',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    textColor: AppColors.accent,
                                    onPressed: () async {
                                      await repo.savePlaybackProgress(
                                        item.animeId,
                                        item.episodeNumber,
                                        positionSeconds: item.positionSeconds,
                                        totalDurationSeconds: item.totalDurationSeconds,
                                        animeTitle: item.animeTitle,
                                        posterUrl: item.posterUrl,
                                      );
                                      ref.invalidate(watchHistoryListProvider);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: InkWell(
                              onTap: () {
                                context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 77,
                                        height: 77,
                                        child: CachedNetworkImage(
                                          imageUrl: item.posterUrl ?? '',
                                          memCacheWidth: 160,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: const Color(0xFF1E1E26)),
                                          errorWidget: (_, __, ___) => Container(
                                            color: const Color(0xFF1E1E26),
                                            child: const Icon(Icons.movie, color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.animeTitle.isNotEmpty ? item.animeTitle : 'Anime #${item.animeId}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Episode ${item.episodeNumber}',
                                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.white12,
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                              minHeight: 3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                                      onPressed: () {
                                        context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      );
                      },
                      childCount: list.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ShimmerBox(width: 77, height: 77, borderRadius: BorderRadius.circular(10)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(width: 140, height: 16, borderRadius: BorderRadius.circular(4)),
                                const SizedBox(height: 8),
                                ShimmerBox(width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
                                const SizedBox(height: 10),
                                ShimmerBox(width: double.infinity, height: 4, borderRadius: BorderRadius.circular(2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    childCount: 4,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: FloatingNavBar.getBottomPadding(context))),
        ],
      ),
    );
  }
}
