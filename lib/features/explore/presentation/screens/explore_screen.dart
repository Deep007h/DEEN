import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/floating_nav_bar.dart';
import '../../../../core/presentation/widgets/hero_shuttle_builder.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../../../metadata/domain/models/anime_summary.dart';
import '../providers/explore_providers.dart';
import '../../../settings/data/repositories/app_settings_repository.dart';

/// Interactive Explore Screen with full-page genre reactivity, curated multi-lists,
/// hero spotlight, view-mode toggles, and endless paginated scrolling.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<({String name, IconData icon, Color color})> _genres = const [
    (name: 'Action', icon: Icons.flash_on_rounded, color: Color(0xFFEF4444)),
    (name: 'Adventure', icon: Icons.explore_rounded, color: Color(0xFFF59E0B)),
    (name: 'Fantasy', icon: Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
    (name: 'Isekai', icon: Icons.cyclone_rounded, color: Color(0xFFEC4899)),
    (name: 'Romance', icon: Icons.favorite_rounded, color: Color(0xFFF43F5E)),
    (name: 'Comedy', icon: Icons.sentiment_very_satisfied_rounded, color: Color(0xFF10B981)),
    (name: 'Sci-Fi', icon: Icons.rocket_launch_rounded, color: Color(0xFF06B6D4)),
    (name: 'Supernatural', icon: Icons.nights_stay_rounded, color: Color(0xFF6366F1)),
    (name: 'Mystery', icon: Icons.psychology_rounded, color: Color(0xFF14B8A6)),
    (name: 'Sports', icon: Icons.sports_basketball_rounded, color: Color(0xFFEAB308)),
    (name: 'Slice of Life', icon: Icons.coffee_rounded, color: Color(0xFFA855F7)),
    (name: 'Horror', icon: Icons.cruelty_free_rounded, color: Color(0xFFDC2626)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 500) {
      final selectedGenre = ref.read(selectedExploreGenreProvider);
      ref.read(genreCatalogProvider(selectedGenre).notifier).loadMore();
    }
  }

  void _onGenreSelected(String genre) {
    if (ref.read(selectedExploreGenreProvider) == genre) return;
    ref.read(selectedExploreGenreProvider.notifier).state = genre;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppMotion.medium3,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accentColorProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final selectedGenre = ref.watch(selectedExploreGenreProvider);
    final viewMode = ref.watch(exploreViewModeProvider);

    // Watch genre-specific providers that reactively change with selectedGenre
    final heroAsync = ref.watch(genreHeroProvider(selectedGenre));
    final trendingAsync = ref.watch(genreTrendingProvider(selectedGenre));
    final topRatedAsync = ref.watch(genreTopRatedProvider(selectedGenre));
    final popularAsync = ref.watch(genrePopularProvider(selectedGenre));
    final catalogState = ref.watch(genreCatalogProvider(selectedGenre));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridCrossAxisCount = screenWidth >= 1000
        ? 5
        : (screenWidth >= 700 ? 4 : (screenWidth >= 480 ? 3 : 2));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        // ignore: deprecated_member_use
        cacheExtent: 500,
        physics: AppMotion.m3ScrollPhysics,
        slivers: [
          // 1. Top Header with App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 14,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3.5,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Explore Codex',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text(
                            'CATALOG DISCOVERY • ',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF6F826F),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              selectedGenre.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Search anime & series',
                    onPressed: () => context.push('/search'),
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Interactive Horizontal Genre Pill Bar (Material 3 FilterChip)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: AppMotion.m3ScrollPhysics,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                itemCount: _genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final g = _genres[index];
                  final isSelected = g.name == selectedGenre;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (_) => _onGenreSelected(g.name),
                    avatar: Icon(
                      g.icon,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      g.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : const Color(0xFFE2E8E2),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 18)),

          // 3. Featured Hero Spotlight for Selected Genre
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 416),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey('hero_$selectedGenre'),
                child: heroAsync.when(
                  data: (hero) {
                    if (hero == null) return const SizedBox.shrink();
                    return _ExploreHeroSpotlight(
                      hero: hero,
                      genreName: selectedGenre,
                    );
                  },
                  loading: () => const _HeroSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4. Curated Carousel: Trending in [Genre]
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Trending in $selectedGenre',
              badge: 'HOT',
              badgeColor: const Color(0xFFEF4444),
              onSeeAll: () => context.push('/search?query=$selectedGenre'),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: AppMotion.medium2,
              child: KeyedSubtree(
                key: ValueKey('trending_$selectedGenre'),
                child: SizedBox(
                  height: 237,
                  child: trendingAsync.when(
                    data: (list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      // ignore: deprecated_member_use
                      cacheExtent: 350,
                      physics: AppMotion.m3ScrollPhysics,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _ExplorePosterCard(
                          item: list[index],
                          rank: index + 1,
                          contextPrefix: 'trending',
                        );
                      },
                    ),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 26)),

          // 5. Curated Carousel: All-Time Masterpieces in [Genre]
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: '$selectedGenre Masterpieces',
              badge: 'TOP RATED',
              badgeColor: const Color(0xFFFFB800),
              onSeeAll: () => context.push('/search?query=$selectedGenre'),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: AppMotion.medium2,
              child: KeyedSubtree(
                key: ValueKey('toprated_$selectedGenre'),
                child: SizedBox(
                  height: 237,
                  child: topRatedAsync.when(
                    data: (list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      // ignore: deprecated_member_use
                      cacheExtent: 350,
                      physics: AppMotion.m3ScrollPhysics,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _ExplorePosterCard(
                          item: list[index],
                          contextPrefix: 'toprated',
                        );
                      },
                    ),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 26)),

          // 6. Curated Carousel: Most Popular Community Hits in [Genre]
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Most Popular $selectedGenre',
              badge: 'POPULAR',
              badgeColor: const Color(0xFF8B5CF6),
              onSeeAll: () => context.push('/search?query=$selectedGenre'),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: AppMotion.medium2,
              child: KeyedSubtree(
                key: ValueKey('popular_$selectedGenre'),
                child: SizedBox(
                  height: 237,
                  child: popularAsync.when(
                    data: (list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      // ignore: deprecated_member_use
                      cacheExtent: 350,
                      physics: AppMotion.m3ScrollPhysics,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _ExplorePosterCard(
                          item: list[index],
                          contextPrefix: 'popular',
                        );
                      },
                    ),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 7. Endless Catalog Header with View Mode Switcher
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Browse All $selectedGenre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  _ViewModeSelector(
                    activeMode: viewMode,
                    onChanged: (mode) {
                      ref.read(exploreViewModeProvider.notifier).state = mode;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // 8. Endless Scrolling Catalog Items (Grid vs Compact vs Wide)
          if (catalogState.isLoading && catalogState.items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                ),
              ),
            )
          else if (catalogState.error != null && catalogState.items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.pageMargin),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load $selectedGenre catalog',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.read(genreCatalogProvider(selectedGenre).notifier).init(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.accentContrast,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (catalogState.items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No anime found in this category',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
            )
          else ...[
            if (viewMode == ExploreViewMode.grid)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 11,
                    mainAxisSpacing: 13,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = catalogState.items[index];
                      return _CatalogGridCard(item: item);
                    },
                    childCount: catalogState.items.length,
                  ),
                ),
              )
            else if (viewMode == ExploreViewMode.compact)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = catalogState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CatalogListCard(item: item),
                      );
                    },
                    childCount: catalogState.items.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = catalogState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CatalogWideCard(item: item),
                      );
                    },
                    childCount: catalogState.items.length,
                  ),
                ),
              ),

            // Pagination loader at bottom
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: catalogState.isLoadingMore
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Loading more anime...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        )
                      : (!catalogState.hasMore
                          ? const Text(
                              'You have reached the end of this category 🎉',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ),
          ],

          // Bottom padding so content is not obscured by floating nav bar
          SliverToBoxAdapter(
            child: SizedBox(height: FloatingNavBar.getBottomPadding(context)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section Header with Optional Pill Badge
// -----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.badge,
    this.badgeColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pageMargin,
        right: AppSpacing.pageMargin,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.accent).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (badgeColor ?? AppColors.accent).withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: badgeColor ?? AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93), size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Hero Spotlight Billboard for Selected Genre
// -----------------------------------------------------------------------------
class _ExploreHeroSpotlight extends StatelessWidget {
  final FeaturedAnimeItem hero;
  final String genreName;

  const _ExploreHeroSpotlight({
    required this.hero,
    required this.genreName,
  });

  @override
  Widget build(BuildContext context) {
    final title = hero.titles.preferredTitle();
    final heroTag = 'poster_${hero.id}_explore_hero';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: PressableScale(
        onTap: () => context.push(
          '/anime/${hero.id}?heroTag=$heroTag',
          extra: {'posterUrl': hero.posterUrl, 'title': title, 'heroTag': heroTag},
        ),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop banner image
                Hero(
                  tag: heroTag,
                  createRectTween: smoothHeroRectTween,
                  flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                  child: CachedNetworkImage(
                    imageUrl: hero.bannerUrl ?? hero.posterUrl ?? '',
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    memCacheHeight: 320,
                    placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                  ),
                ),

                // Multi-stop gradient for readable text
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.7),
                        const Color(0xFF0A0A0E).withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$genreName Spotlight',
                              style: const TextStyle(
                                color: Color(0xFF0B0E0B),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (hero.score != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    hero.score!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (hero.summary != null && hero.summary!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          hero.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFC7C7CC),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// View Mode Selector (Grid / Compact / Wide)
// -----------------------------------------------------------------------------
class _ViewModeSelector extends StatelessWidget {
  final ExploreViewMode activeMode;
  final ValueChanged<ExploreViewMode> onChanged;

  const _ViewModeSelector({
    required this.activeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExploreViewMode>(
      segments: const [
        ButtonSegment(
          value: ExploreViewMode.grid,
          icon: Icon(Icons.grid_view_rounded, size: 16),
          tooltip: 'Grid',
        ),
        ButtonSegment(
          value: ExploreViewMode.compact,
          icon: Icon(Icons.view_agenda_rounded, size: 16),
          tooltip: 'Compact',
        ),
        ButtonSegment(
          value: ExploreViewMode.wide,
          icon: Icon(Icons.panorama_rounded, size: 16),
          tooltip: 'Wide',
        ),
      ],
      selected: {activeMode},
      onSelectionChanged: (newSelection) {
        if (newSelection.isNotEmpty) {
          onChanged(newSelection.first);
        }
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Horizontal Carousel Poster Card
// -----------------------------------------------------------------------------
class _ExplorePosterCard extends StatelessWidget {
  final AnimeSummary item;
  final int? rank;
  final String contextPrefix;

  const _ExplorePosterCard({
    required this.item,
    this.rank,
    this.contextPrefix = 'explore',
  });

  @override
  Widget build(BuildContext context) {
    final title = item.titles.preferredTitle();
    final heroTag = 'poster_${item.id}_${contextPrefix}_${rank ?? 0}';

    return RepaintBoundary(
      child: PressableScale(
        onTap: () => context.push(
          '/anime/${item.id}?heroTag=$heroTag',
          extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
        ),
        child: SizedBox(
          width: 143,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Hero(
                          tag: heroTag,
                          createRectTween: smoothHeroRectTween,
                          flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                          child: CachedNetworkImage(
                            imageUrl: item.posterUrl ?? '',
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                            placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceContainerLow,
                              child: const Icon(Icons.broken_image, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (rank != null)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (item.score != null)
                    Positioned(
                      bottom: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 11),
                            const SizedBox(width: 3),
                            Text(
                              item.score!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

// -----------------------------------------------------------------------------
// 2-Column Catalog Grid Card
// -----------------------------------------------------------------------------
class _CatalogGridCard extends StatelessWidget {
  final AnimeSummary item;

  const _CatalogGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.titles.preferredTitle();
    final heroTag = 'poster_${item.id}_grid';

    return RepaintBoundary(
      child: PressableScale(
        onTap: () => context.push(
          '/anime/${item.id}?heroTag=$heroTag',
          extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1.0),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: Offset(0, 5),
                    ),
                    BoxShadow(
                      color: AppColors.border.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: heroTag,
                        createRectTween: smoothHeroRectTween,
                        flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                        child: CachedNetworkImage(
                          imageUrl: item.posterUrl ?? '',
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                          errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.65, 1.0],
                          ),
                        ),
                      ),
                      if (item.score != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  item.score!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (item.eps != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.eps} eps',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.platform ?? 'TV Series',
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Compact List Card
// -----------------------------------------------------------------------------
class _CatalogListCard extends StatelessWidget {
  final AnimeSummary item;

  const _CatalogListCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.titles.preferredTitle();
    final heroTag = 'poster_${item.id}_list';

    return RepaintBoundary(
      child: PressableScale(
        onTap: () => context.push(
          '/anime/${item.id}?heroTag=$heroTag',
          extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.border.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Hero(
                  tag: heroTag,
                  createRectTween: smoothHeroRectTween,
                  flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl ?? '',
                    width: 70,
                    height: 97,
                    fit: BoxFit.cover,
                    memCacheWidth: 180,
                    memCacheHeight: 250,
                    maxWidthDiskCache: 360,
                    maxHeightDiskCache: 500,
                    placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.score != null) ...[
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            item.score!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (item.eps != null) ...[
                          Text(
                            '${item.eps} Episodes',
                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          item.platform ?? 'TV',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Wide Banner Card
// -----------------------------------------------------------------------------
class _CatalogWideCard extends StatelessWidget {
  final AnimeSummary item;

  const _CatalogWideCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.titles.preferredTitle();
    final heroTag = 'poster_${item.id}_wide';

    return RepaintBoundary(
      child: PressableScale(
        onTap: () => context.push(
          '/anime/${item.id}?heroTag=$heroTag',
          extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
        ),
        child: Container(
          height: 154,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.border.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag,
                  createRectTween: smoothHeroRectTween,
                  flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl ?? '',
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    memCacheHeight: 340,
                    maxWidthDiskCache: 900,
                    maxHeightDiskCache: 510,
                    placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF0A0A0E).withValues(alpha: 0.95),
                        const Color(0xFF0A0A0E).withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item.score != null) ...[
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              item.score!.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            item.platform ?? 'Anime',
                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Skeletons
// -----------------------------------------------------------------------------
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: ShimmerBox(
        width: double.infinity,
        height: 190,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 237,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => ShimmerBox(
          width: 143,
          height: 204,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
