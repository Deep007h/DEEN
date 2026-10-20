import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/presentation/providers/stream_providers.dart';
import 'package:anime_stream/features/library/domain/models/followed_anime.dart';

/// Detail screen matching reference Screen 2.
/// Features blurred backdrop fade, sharp hero poster, rating and rank badges,
/// action buttons (Play, Follow toggle with local persistence), collapsible tags,
/// synopsis, horizontal seasons selector, and switchable List/Grid episode views.
class DetailScreen extends ConsumerStatefulWidget {
  final String animeId;
  final String? heroTag;
  final String? previewPoster;
  final String? previewTitle;

  const DetailScreen({
    super.key,
    required this.animeId,
    this.heroTag,
    this.previewPoster,
    this.previewTitle,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isTagsExpanded = false;
  bool _isSynopsisExpanded = false;
  bool _isGridView = true;
  int _selectedSeasonId = 0;

  @override
  void initState() {
    super.initState();
    _selectedSeasonId = int.tryParse(widget.animeId) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final currentId = _selectedSeasonId != 0 ? _selectedSeasonId : (int.tryParse(widget.animeId) ?? 0);

    final detailAsync = ref.watch(animeDetailProvider(currentId));
    final titlePref = ref.watch(titlePreferenceProvider);
    final isFollowedAsync = ref.watch(isFollowingProvider(currentId));
    final lastWatchedEpAsync = ref.watch(lastWatchedEpisodeProvider(currentId));

    final registry = ref.watch(streamProviderRegistryProvider).valueOrNull;
    final defaultProviderId = registry?.getOrderedEnabledProviders().firstOrNull?.id ?? 'megavid';
    final selectedProviderId = registry?.getAnimeSelectedProviderId(currentId) ?? defaultProviderId;
    final activeProvider = registry?.getProvider(selectedProviderId) ?? registry?.getProvider(defaultProviderId);
    final providerLabel = activeProvider?.displayName.split(' ').first ?? 'MegaVid';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (detail) {
          final displayTitle = detail.titles.preferredTitle(titlePref);
          final isFollowed = isFollowedAsync.valueOrNull ?? false;
          final lastWatchedEp = lastWatchedEpAsync.valueOrNull;

          // Pre-resolve target episode stream in background for instant 0ms playback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(streamOrchestratorProvider.future).then((orch) {
              final targetEp = lastWatchedEp ?? 1;
              orch.prewarmEpisode(anime: detail, episodeNumber: targetEp);
            });
          });

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surfaceElevated,
            onRefresh: () async {
              ref.invalidate(animeDetailProvider(currentId));
              await ref.read(animeDetailProvider(currentId).future);
            },
            child: CustomScrollView(
              physics: AppMotion.m3ScrollPhysics,
              slivers: [
                // Top Backdrop with Blurred Poster + Round Back Button + Header Content
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // 1. Blurred Backdrop Image
                      if (detail.posterUrl != null && detail.posterUrl!.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 380,
                          child: ClipRect(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Transform.scale(
                                scale: 1.25,
                                child: CachedNetworkImage(
                                  imageUrl: detail.bannerUrl ?? detail.posterUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 720,
                                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 2. Gradient Shade to Pure Black
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 380,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.75),
                                AppColors.background,
                              ],
                              stops: const [0.0, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 3. Foreground Content
                      Padding(
                        padding: EdgeInsets.only(
                          top: topPadding + AppSpacing.xs,
                          left: AppSpacing.pageMargin,
                          right: AppSpacing.pageMargin,
                          bottom: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Round Back Button
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8,
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: 'Back',
                                  padding: EdgeInsets.zero,
                                  onPressed: () => context.pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.textPrimary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Header row: Sharp Hero Poster on left + Titles & Metadata on right
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sharp Poster Card with Hero animation
                                Hero(
                                  tag: widget.heroTag ?? 'poster_${detail.id}',
                                  createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                                  child: Container(
                                    width: 115,
                                    height: 165,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x7A000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: detail.posterUrl != null &&
                                              detail.posterUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: detail.posterUrl!,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 360,
                                              memCacheHeight: 540,
                                              maxWidthDiskCache: 500,
                                              maxHeightDiskCache: 750,
                                              placeholder: (_, __) => Container(
                                                color: AppColors.surface,
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: AppColors.surface,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            )
                                          : Container(color: AppColors.surface),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: AppSpacing.md),

                                // Right Titles & Meta Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Alternate / Original subtitle
                                      if (detail.titles.original != displayTitle)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            detail.titles.original,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.meta.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),

                                      // Main Big Title
                                      Text(
                                        displayTitle,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.pageTitle.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.sm),

                                      // Meta Row 1: Star + Score + Ratings Count + Air Date
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          if (detail.score != null) ...[
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 16,
                                                  color: AppColors.ratingStar,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  detail.score!.toStringAsFixed(1),
                                                  style: AppText.badgeText.copyWith(
                                                    color: AppColors.ratingStar,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (detail.ratingCount != null) ...[
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '(${detail.ratingCount})',
                                                    style: AppText.meta.copyWith(fontSize: 11),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                          if (detail.airDate != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  detail.airDate!,
                                                  style: AppText.meta.copyWith(fontSize: 11.5),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Meta Row 2: Rank # + Format chip + Episodes count
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          if (detail.rank != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentSoft,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppColors.accentBorder,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                'Rank #${detail.rank}',
                                                style: AppText.badgeText.copyWith(
                                                  color: AppColors.accent,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ),
                                          if (detail.platform != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceElevated,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                detail.platform!,
                                                style: AppText.meta.copyWith(fontSize: 10.5),
                                              ),
                                            ),
                                          if (detail.eps != null && detail.eps! > 0)
                                            Text(
                                              '${detail.eps} eps',
                                              style: AppText.meta.copyWith(fontSize: 11.5),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Action Row: Big Red Play Button + Outlined Follow Button
                            Row(
                              children: [
                                // Big Vivid Electric Lime "Play" Button
                                Expanded(
                                  flex: 6,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      final epToPlay = lastWatchedEp ?? 1;
                                      context.push('/player?animeId=$currentId&ep=$epToPlay&provider=$selectedProviderId');
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 24,
                                    ),
                                    label: Text(
                                      lastWatchedEp != null
                                          ? 'PLAY EP $lastWatchedEp'
                                          : l10n.playAction.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: AppSpacing.sm),

                                // "Follow" Star Button with Bouncy Spring Animation
                                Expanded(
                                  flex: 5,
                                  child: _SpringStarButton(
                                    isFollowed: isFollowed,
                                    label: isFollowed ? l10n.followedAction : l10n.followAction,
                                    onToggle: () async {
                                      final followedMeta = FollowedAnime(
                                        id: currentId,
                                        title: detail.titles.preferredTitle(titlePref),
                                        nameCn: detail.titles.localized,
                                        posterUrl: detail.posterUrl,
                                        score: detail.score ?? 0.0,
                                        totalEpisodes: detail.eps ?? detail.episodes.length,
                                        followedAt: DateTime.now(),
                                      );
                                      await ref
                                          .read(followRepositoryProvider)
                                          .toggleFollow(currentId, metadata: followedMeta);
                                      ref.invalidate(isFollowingProvider(currentId));
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Small Outlined Info Chips Row (Watch status, Source selector, Episodes)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _InfoPill(
                                    label: lastWatchedEp != null
                                        ? 'Watched: Ep $lastWatchedEp'
                                        : 'Unwatched',
                                    icon: Icons.history_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoPill(
                                    label: 'Source: $providerLabel ▼',
                                    icon: Icons.cloud_queue_rounded,
                                    onTap: () => _showSourceSelectorSheet(context, currentId, registry),
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoPill(
                                    label: '${detail.episodes.length} Episodes',
                                    icon: Icons.video_library_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tags Section: Rounded Panel with wrapped chips and "Show more" toggle
                if (detail.tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageMargin,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.tagsTitle,
                                style: AppText.sectionTitle.copyWith(fontSize: 16),
                              ),
                              if (detail.tags.length > 6)
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isTagsExpanded = !_isTagsExpanded);
                                  },
                                  child: Text(
                                    _isTagsExpanded ? 'Show less ∧' : 'Show more ∨',
                                    style: AppText.meta.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.cardBorder,
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_isTagsExpanded
                                      ? detail.tags
                                      : detail.tags.take(6))
                                  .map((tag) {
                                return Material(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: AppRadius.pillBorder,
                                  child: InkWell(
                                    borderRadius: AppRadius.pillBorder,
                                    onTap: () {
                                      // Add tag to search filter and navigate to search
                                      ref.read(selectedTagsProvider.notifier).addTag(tag.name);
                                      context.push('/search');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        '${tag.name} ${tag.count}',
                                        style: AppText.meta.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Synopsis Section with "Read more" toggle
                if (detail.summary != null && detail.summary!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageMargin,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Synopsis', style: AppText.sectionTitle.copyWith(fontSize: 16)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            detail.summary!,
                            maxLines: _isSynopsisExpanded ? null : 3,
                            overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                            style: AppText.bodySecondary.copyWith(
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (detail.summary!.length > 120) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() => _isSynopsisExpanded = !_isSynopsisExpanded);
                              },
                              child: Text(
                                _isSynopsisExpanded ? 'Show less' : 'Read more',
                                style: AppText.meta.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Seasons Selector: Horizontal Chips
                if (detail.seasons.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageMargin,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seasons', style: AppText.sectionTitle.copyWith(fontSize: 16)),
                          const SizedBox(height: AppSpacing.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: detail.seasons.map((season) {
                                final isSelected = season.id == currentId;
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(season.name),
                                    selected: isSelected,
                                    selectedColor: AppColors.accentSoft,
                                    backgroundColor: AppColors.surface,
                                    side: BorderSide(
                                      color: isSelected ? AppColors.accent : AppColors.border,
                                      width: 0.8,
                                    ),
                                    labelStyle: AppText.badgeText.copyWith(
                                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                      fontSize: 12.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.pillBorder,
                                    ),
                                    onSelected: (selected) {
                                      if (selected && season.id != currentId) {
                                        setState(() {
                                          _selectedSeasonId = season.id;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Episodes Header with List / Grid View Switcher
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageMargin,
                      AppSpacing.lg,
                      AppSpacing.pageMargin,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.episodesTitle,
                          style: AppText.sectionTitle.copyWith(fontSize: 16),
                        ),
                        // M3 Segmented Button for View Switcher (Grid / List)
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              icon: Icon(Icons.grid_view_rounded, size: 16),
                              tooltip: 'Grid view',
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              icon: Icon(Icons.view_list_rounded, size: 16),
                              tooltip: 'List view',
                            ),
                          ],
                          selected: {_isGridView},
                          onSelectionChanged: (newSelection) {
                            if (newSelection.isNotEmpty) {
                              setState(() => _isGridView = newSelection.first);
                            }
                          },
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Episode List or Grid
                if (detail.episodes.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.pageMargin),
                      child: Text('No episodes listed for this subject', style: AppText.meta),
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ep = detail.episodes[index];
                          final epNum = ep.number.toInt();
                          final isCurrent = lastWatchedEp != null && epNum == lastWatchedEp;
                          final isWatched = lastWatchedEp != null && epNum < lastWatchedEp;

                          return Tooltip(
                            message: 'Episode $epNum${ep.title.isNotEmpty ? ': ${ep.title}' : ''}',
                            child: Material(
                              color: isCurrent
                                  ? AppColors.accent
                                  : isWatched
                                      ? AppColors.accentSoft
                                      : const Color(0xFF141914),
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ref.read(playbackHistoryRepositoryProvider).setLastWatchedEpisode(currentId, epNum);
                                  ref.invalidate(lastWatchedEpisodeProvider(currentId));
                                  context.push('/player?animeId=$currentId&ep=$epNum&provider=$selectedProviderId');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.accent
                                          : isWatched
                                              ? AppColors.accent.withValues(alpha: 0.5)
                                              : const Color(0xFF263526),
                                      width: isCurrent ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$epNum',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent
                                          ? const Color(0xFF0B0E0B)
                                          : isWatched
                                              ? AppColors.accent
                                              : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: detail.episodes.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ep = detail.episodes[index];
                          final epNum = ep.number.toInt();
                          final isWatched = lastWatchedEp != null && epNum <= lastWatchedEp;

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  ref.read(playbackHistoryRepositoryProvider).setLastWatchedEpisode(currentId, epNum);
                                  ref.invalidate(lastWatchedEpisodeProvider(currentId));
                                  context.push('/player?animeId=$currentId&ep=$epNum&provider=$selectedProviderId');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isWatched
                                          ? AppColors.accent.withValues(alpha: 0.3)
                                          : AppColors.border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Episode Number Badge
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isWatched
                                              ? AppColors.accentSoft
                                              : AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$epNum',
                                          style: AppText.badgeText.copyWith(
                                            color: isWatched
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      // Title & Original
                                      Expanded(
                                        child: Builder(
                                          builder: (_) {
                                            final isEpLatin = AnimeTitles.isPrimarilyLatin(ep.title);
                                            final displayEpTitle = (titlePref == TitlePreference.english && !isEpLatin)
                                                ? 'Episode $epNum'
                                                : ep.title;
                                            final displayEpSub = (titlePref == TitlePreference.english)
                                                ? (ep.titleOriginal != null && AnimeTitles.isPrimarilyLatin(ep.titleOriginal!)
                                                    ? ep.titleOriginal
                                                    : (isEpLatin && ep.title != displayEpTitle ? ep.title : null))
                                                : (ep.titleOriginal != null && ep.titleOriginal != ep.title ? ep.titleOriginal : null);

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  displayEpTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppText.body.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (displayEpSub != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    displayEpSub,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppText.meta.copyWith(
                                                      color: AppColors.textMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      // Watched indicator or air date
                                      if (isWatched)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            size: 16,
                                            color: AppColors.accent,
                                          ),
                                        )
                                      else if (ep.airDate != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Text(
                                            ep.airDate!,
                                            style: AppText.meta.copyWith(fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: detail.episodes.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
              ],
            ),
          );
        },
        loading: () => _DetailLoadingSkeleton(
          heroTag: widget.heroTag ?? 'poster_${widget.animeId}',
          previewPoster: widget.previewPoster,
          previewTitle: widget.previewTitle,
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.accent),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.errorLoading, style: AppText.sectionTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(err.toString(), textAlign: TextAlign.center, style: AppText.meta),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(animeDetailProvider(currentId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSourceSelectorSheet(BuildContext context, int currentId, dynamic registry) {
    if (registry == null) return;
    final enabledProviders = registry.getOrderedEnabledProviders();
    final defaultId = enabledProviders.isNotEmpty ? enabledProviders.first.id : 'megavid';
    final currentProviderId = registry.getAnimeSelectedProviderId(currentId) ?? defaultId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Stream Source',
                    style: AppText.sectionTitle,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/settings/sources');
                    },
                    child: const Text('Manage Sources', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...enabledProviders.map<Widget>((p) {
                final isSelected = p.id == currentProviderId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                  title: Text(
                    p.displayName,
                    style: AppText.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    await registry.setAnimeSelectedProviderId(currentId, p.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoPill({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.meta.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: pill,
      );
    }
    return pill;
  }
}


class _DetailLoadingSkeleton extends StatelessWidget {
  final String? heroTag;
  final String? previewPoster;
  final String? previewTitle;

  const _DetailLoadingSkeleton({
    this.heroTag,
    this.previewPoster,
    this.previewTitle,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        if (previewPoster != null && previewPoster!.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Transform.scale(
                  scale: 1.25,
                  child: CachedNetworkImage(
                    imageUrl: previewPoster!,
                    fit: BoxFit.cover,
                    memCacheWidth: 720,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                  AppColors.background,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: topPadding + AppSpacing.xs,
            left: AppSpacing.pageMargin,
            right: AppSpacing.pageMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Round Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (heroTag != null && previewPoster != null && previewPoster!.isNotEmpty)
                    Hero(
                      tag: heroTag!,
                      createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                      child: Container(
                        width: 115,
                        height: 165,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x7A000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: CachedNetworkImage(
                            imageUrl: previewPoster!,
                            fit: BoxFit.cover,
                            memCacheWidth: 360,
                            memCacheHeight: 540,
                          ),
                        ),
                      ),
                    )
                  else
                    ShimmerBox(width: 115, height: 165, borderRadius: BorderRadius.circular(14)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (previewTitle != null)
                          Text(
                            previewTitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sectionTitle.copyWith(fontSize: 18),
                          )
                        else ...[
                          ShimmerBox(width: 90, height: 12, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 8),
                          ShimmerBox(width: 180, height: 22, borderRadius: BorderRadius.circular(6)),
                        ],
                        const SizedBox(height: 12),
                        ShimmerBox(width: 120, height: 14, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 8),
                        ShimmerBox(width: 140, height: 14, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ShimmerBox(width: double.infinity, height: 48, borderRadius: AppRadius.pillBorder),
              const SizedBox(height: AppSpacing.xl),
              ShimmerBox(width: double.infinity, height: 80, borderRadius: AppRadius.cardBorder),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, __) => ShimmerBox(
                    width: double.infinity,
                    height: 56,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpringStarButton extends StatefulWidget {
  final bool isFollowed;
  final Future<void> Function() onToggle;
  final String label;

  const _SpringStarButton({
    required this.isFollowed,
    required this.onToggle,
    required this.label,
  });

  @override
  State<_SpringStarButton> createState() => _SpringStarButtonState();
}

class _SpringStarButtonState extends State<_SpringStarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _handleTap,
      icon: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isFollowed ? Icons.star_rounded : Icons.star_outline_rounded,
          color: widget.isFollowed ? AppColors.ratingStar : Colors.white,
          size: 20,
        ),
      ),
      label: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.buttonPrimary.copyWith(
          fontSize: 14,
          color: widget.isFollowed ? AppColors.ratingStar : Colors.white,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(
          color: widget.isFollowed
              ? AppColors.ratingStar.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: widget.isFollowed
            ? AppColors.ratingStar.withValues(alpha: 0.12)
            : AppColors.surface,
      ),
    );
  }
}

