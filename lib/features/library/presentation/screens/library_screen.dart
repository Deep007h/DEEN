import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
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
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                title: const Text('Clear Watch History'),
                                content: const Text('Remove all items from your playback history?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor: theme.colorScheme.onError,
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
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            extra: {'posterUrl': item.posterUrl, 'title': item.title},
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
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
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
                              color: Colors.red.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            final repo = ref.read(playbackHistoryRepositoryProvider);
                            await repo.deleteHistoryItem(item.animeId, item.episodeNumber);
                            ref.invalidate(watchHistoryListProvider);
                          },
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), width: 0.8),
                            ),
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
                                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                                  onPressed: () {
                                    context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
                                  },
                                ),
                              ],
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
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
