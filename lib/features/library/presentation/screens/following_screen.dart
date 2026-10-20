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
import '../../domain/models/followed_anime.dart';
import '../providers/library_providers.dart';

/// Following tab screen displaying tracked anime (追番).
/// Features unwatched-episode badges, sorting by recently followed / title / score,
/// long-press to unfollow with confirmation, and smooth responsive grid.
class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final currentSort = ref.watch(followSortProvider);
    final followedAsync = ref.watch(followedAnimeListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header title and count badge
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + AppSpacing.md,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.followingTitle,
                    style: AppText.pageTitle,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  followedAsync.when(
                    data: (items) => Container(
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
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Sort Chips bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SortChip(
                      label: 'Recently Added',
                      icon: Icons.history_rounded,
                      isSelected: currentSort == FollowSort.recentlyFollowed,
                      onTap: () {
                        ref.read(followSortProvider.notifier).state =
                            FollowSort.recentlyFollowed;
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SortChip(
                      label: 'Title',
                      icon: Icons.sort_by_alpha_rounded,
                      isSelected: currentSort == FollowSort.title,
                      onTap: () {
                        ref.read(followSortProvider.notifier).state = FollowSort.title;
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SortChip(
                      label: 'Rating',
                      icon: Icons.star_outline_rounded,
                      isSelected: currentSort == FollowSort.score,
                      onTap: () {
                        ref.read(followSortProvider.notifier).state = FollowSort.score;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content state
          followedAsync.when(
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
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 13,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _FollowedAnimeCard(anime: item);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerBox(
                    width: double.infinity,
                    height: 220,
                    borderRadius: AppRadius.cardBorder,
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
                    'Failed to load followed anime',
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
              Icons.star_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.followingEmpty,
            textAlign: TextAlign.center,
            style: AppText.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.followingEmptyDesc,
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.18) : AppColors.surface,
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: isSelected ? primaryColor.withValues(alpha: 0.4) : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? primaryColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.meta.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowedAnimeCard extends ConsumerWidget {
  final FollowedAnime anime;

  const _FollowedAnimeCard({required this.anime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unwatchedAsync = ref.watch(unwatchedCountProvider(anime.id));

    return InkWell(
      onTap: () => context.push(
        '/anime/${anime.id}',
        extra: {'posterUrl': anime.posterUrl, 'title': anime.title},
      ),
      onLongPress: () => _confirmUnfollow(context, ref),
      borderRadius: AppRadius.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Card
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.cardBorder,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (anime.posterUrl != null && anime.posterUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: anime.posterUrl!,
                      memCacheWidth: 360,
                      memCacheHeight: 540,
                      maxWidthDiskCache: 500,
                      maxHeightDiskCache: 750,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.movie_rounded, color: AppColors.textDisabled, size: 28),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppColors.textDisabled, size: 28),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Icon(Icons.movie_rounded, color: AppColors.textDisabled, size: 32),
                      ),
                    ),

                  // Subtle gradient overlay at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-Right: Unwatched episode badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: unwatchedAsync.when(
                      data: (unwatched) {
                        if (unwatched <= 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(color: Colors.white24, width: 0.6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 11, color: Color(0xFF00E676)),
                                SizedBox(width: 3),
                                Text(
                                  'Watched',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: AppRadius.pillBorder,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$unwatched new',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // Bottom-Left: Rating Badge
                  if (anime.score > 0)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ratingBadge,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.ratingStar,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              anime.score.toStringAsFixed(1),
                              style: AppText.badgeText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Anime Title
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(fontSize: 14),
          ),

          const SizedBox(height: 2),

          // Total episodes subtext
          Text(
            anime.totalEpisodes > 0 ? '${anime.totalEpisodes} episodes' : 'Series',
            style: AppText.meta.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _confirmUnfollow(BuildContext context, WidgetRef ref) {
    final followRepo = ref.read(followRepositoryProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: Text('Unfollow ${anime.title}?', style: AppText.sectionTitle),
          content: const Text(
            'Remove this anime from your followed list?',
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
                await followRepo.unfollow(anime.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('Unfollowed ${anime.title}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: primaryColor,
                        onPressed: () async {
                          await followRepo.follow(anime);
                        },
                      ),
                    ),
                  );
                }
              },
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    );
  }
}
