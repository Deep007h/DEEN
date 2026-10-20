import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../player/domain/models/watch_history_item.dart';
import '../providers/library_providers.dart';

/// Recent tab screen displaying watch history.
/// Features progress bars, resume playback on tap, swipe-to-delete,
/// and "Clear all" with confirmation dialog.
class RecentScreen extends ConsumerWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final historyAsync = ref.watch(watchHistoryListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header with Title and "Clear all" action
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + AppSpacing.md,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.recentTitle,
                        style: AppText.pageTitle,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      historyAsync.when(
                        data: (items) => items.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.18),
                                  borderRadius: AppRadius.pillBorder,
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${items.length}',
                                  style: AppText.badgeText.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  // "Clear all" button
                  historyAsync.when(
                    data: (items) {
                      if (items.isEmpty) return const SizedBox.shrink();
                      return TextButton.icon(
                        onPressed: () => _confirmClearAll(context, ref),
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(
                          'Clear all',
                          style: AppText.meta.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Watch history list
          historyAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.pageMargin),
                    child: _buildEmptyState(l10n),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _HistoryCard(item: item),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 84,
                      borderRadius: AppRadius.cardBorder,
                    ),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (err, _) => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Failed to load watch history',
                    style: AppText.bodySecondary,
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding for floating navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.floatingBarBottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.recentEmpty,
            textAlign: TextAlign.center,
            style: AppText.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.recentEmptyDesc,
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: const Text('Clear Watch History', style: AppText.sectionTitle),
          content: const Text(
            'Are you sure you want to clear your entire watch history? This action cannot be undone.',
            style: AppText.bodySecondary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await ref.read(playbackHistoryRepositoryProvider).clearAllHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('Watch history cleared'),
                    ),
                  );
                }
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final WatchHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey('history_${item.animeId}_${item.episodeNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFF453A).withValues(alpha: 0.85),
          borderRadius: AppRadius.cardBorder,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await ref
            .read(playbackHistoryRepositoryProvider)
            .deleteHistoryItem(item.animeId, item.episodeNumber);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text('Removed "${item.animeTitle}" from history'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
        child: InkWell(
          onTap: () {
            context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
          },
          borderRadius: AppRadius.cardBorder,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Thumbnail poster (with play icon overlay)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 76,
                    height: 52,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: item.posterUrl!,
                            memCacheWidth: 160,
                            memCacheHeight: 220,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.surfaceElevated,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceElevated,
                              child: const Icon(
                                Icons.movie_rounded,
                                color: AppColors.textDisabled,
                                size: 20,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(
                              Icons.movie_rounded,
                              color: AppColors.textDisabled,
                              size: 20,
                            ),
                          ),
                        // Dark scrim
                        Container(color: Colors.black38),
                        // Play icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Title and progress info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.animeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Episode ${item.episodeNumber} · ${item.formattedProgress}',
                        style: AppText.meta.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Linear progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: item.progressFraction,
                          minHeight: 3.5,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Resume arrow icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
