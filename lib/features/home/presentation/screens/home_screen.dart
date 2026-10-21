// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/presentation/providers/library_providers.dart';
import '../../../metadata/data/datasources/anilist_remote_data_source.dart' show FeaturedAnimeItem;
import '../../../metadata/domain/models/anime_summary.dart';
import '../../../player/domain/models/watch_history_item.dart';
import '../../../player/presentation/widgets/embed_stream_dialog.dart';
import '../providers/home_providers.dart';
import '../widgets/notifications_sheet.dart';
import '../../../library/domain/models/followed_anime.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../explore/presentation/providers/explore_providers.dart';

/// State provider for Home screen genre filter pill bar.
final homeGenreFilterProvider = StateProvider<String>((ref) => 'All');

/// Redesigned Home screen matching reference UI (media_1792319611255.png) 1:1.
/// Features:
/// - Custom top bar: DEEN PRO logo, "STREAM ANIME YOUR WAY", circular search button, & profile with online green dot.
/// - "Watch Now" header with interactive horizontal genre pill bar (🔥 All, ⚔️ Action, 🧭 Adventure, ✨ Fantasy, etc.).
/// - Hero Spotlight Billboard Card with [🔥 #1 Trending] badge, title, meta (★ 8.6 | TV • 170 Episodes), 2-line synopsis,
///   Play Now (electric lime CTA) + My List button, and carousel indicator dots.
/// - "Trending Anime" with rank badges (#1, #2, #3, #4 in squircle) & score pill (★ 8.6) with title and genres below.
/// - "Continue Watching" with 16:9 widescreen thumbnails, [RESUME] badge, circular play button, progress bar & title below.
/// - "Popular This Week" compact cards carousel.
/// - Comprehensive categories, top rated, and user favourites.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.paddingOf(context).top;

    final selectedGenre = ref.watch(homeGenreFilterProvider);
    final featuredAsync = ref.watch(featuredAnimeProvider);
    final trendingAsync = selectedGenre == 'All'
        ? ref.watch(trendingAnimeProvider)
        : ref.watch(categoryAnimeProvider(selectedGenre));
    final topRatedAsync = ref.watch(topRatedAnimeProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedAnimeProvider);
    final followedAsync = ref.watch(followedAnimeListProvider);
    final historyAsync = ref.watch(watchHistoryListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: const Color(0xFF141914),
        displacement: 40,
        edgeOffset: topPadding + 4,
        onRefresh: () async {
          ref.invalidate(featuredAnimeProvider);
          ref.invalidate(trendingAnimeProvider);
          ref.invalidate(topRatedAnimeProvider);
          ref.invalidate(recentlyAddedAnimeProvider);
          ref.invalidate(followedAnimeListProvider);
          ref.invalidate(watchHistoryListProvider);
          if (selectedGenre != 'All') {
            ref.invalidate(categoryAnimeProvider(selectedGenre));
          }
        },
        child: CustomScrollView(
          cacheExtent: 500,
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // 1. Top App Bar: Deen PRO logo on left, Circular Search & Profile with online indicator on right
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 10,
                  left: AppSpacing.pageMargin,
                  right: AppSpacing.pageMargin,
                  bottom: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Logo + Deen PRO title & Tagline
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'DEEN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(alpha: 0.6),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'STREAM ANIME YOUR WAY',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF8E9E8E),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Top Bar Action Buttons: Circular Search & Profile avatar with green online badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141914),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF263526), width: 0.9),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                            tooltip: 'Search anime',
                            onPressed: () => context.push('/search'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _ProfileDropdownButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. "Watch Now" Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: Row(
                  children: [
                    Container(
                      width: 4,
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
                    const SizedBox(width: 10),
                    const Text(
                      'Watch Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 3. Horizontal Genre Filter Pill Bar
            const SliverToBoxAdapter(
              child: _GenreFilterPillBar(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 4. Hero Spotlight Billboard Card
            SliverToBoxAdapter(
              child: featuredAsync.when(
                data: (items) => _HeroSpotlightBillboard(items: items),
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 350,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 5. "Trending Anime"
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending Anime',
                onSeeAll: () => context.push('/search'),
              ),
            ),
            SliverToBoxAdapter(
              child: trendingAsync.when(
                data: (items) => _TrendingLargeCardsList(items: items),
                loading: () => const _CardListSkeleton(itemWidth: 135, itemHeight: 190),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 6. Continue Watching (if history exists, below Trending Anime)
            historyAsync.maybeWhen(
              data: (history) {
                if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Continue Watching',
                        onSeeAll: () => context.go('/library'),
                      ),
                      SizedBox(
                        height: 195,
                        child: ListView.separated(
                          cacheExtent: 500,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                          scrollDirection: Axis.horizontal,
                          physics: AppMotion.m3ScrollPhysics,
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 11),
                          itemBuilder: (context, index) {
                            return RepaintBoundary(
                              child: _ContinueWatchingCard(
                                item: history[index],
                                isFirst: index == 0,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // 7. "Popular This Week"
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Popular This Week',
                onSeeAll: () => context.push('/search'),
              ),
            ),
            SliverToBoxAdapter(
              child: featuredAsync.when(
                data: (featuredItems) {
                  final list = featuredItems.map((f) => AnimeSummary(
                    id: f.id,
                    titles: f.titles,
                    posterUrl: f.posterUrl,
                    score: f.score,
                  )).toList();
                  return _PopularThisWeekList(items: list);
                },
                loading: () => const _CardListSkeleton(itemWidth: 115, itemHeight: 165),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 8. Popular Categories
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Popular Categories',
                onSeeAll: () => context.go('/explore'),
              ),
            ),
            const SliverToBoxAdapter(
              child: _PopularCategoriesList(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 9. Top Rated Anime
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Top Rated Anime',
                onSeeAll: () => context.push('/search'),
              ),
            ),
            SliverToBoxAdapter(
              child: topRatedAsync.when(
                data: (items) => _TopRatedHorizontalList(items: items),
                loading: () => const _CardListSkeleton(itemWidth: 125, itemHeight: 175),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 10. Recently Added
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recently Added',
                onSeeAll: () => context.push('/search'),
              ),
            ),
            SliverToBoxAdapter(
              child: recentlyAddedAsync.when(
                data: (items) => _RecentlyAddedHorizontalList(items: items),
                loading: () => const _CardListSkeleton(itemWidth: 125, itemHeight: 175),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // 11. My Favourites
            followedAsync.maybeWhen(
              data: (followed) {
                if (followed.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 26),
                      _SectionHeader(
                        title: 'My Favourites',
                        onSeeAll: () => context.go('/library'),
                      ),
                      _UserFavouritesList(items: followed),
                    ],
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Bottom padding for comfortable scroll above floating nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Dropdown Button with Electric Lime Online Indicator Dot
// ---------------------------------------------------------------------------
class _ProfileDropdownButton extends StatelessWidget {
  const _ProfileDropdownButton();

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141914),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF263526)),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'DEEN PRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Autonomous Anime Streaming Studio',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Engineered with AniList GraphQL, high-speed CDN multi-mirror streaming, zero-stall HLS demuxing, and Autonomous Studio telemetry.',
              style: TextStyle(color: Color(0xFF8E9E8E), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF141914),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF141914),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF263526), width: 1),
          ),
          elevation: 16,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Profile & Settings',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/default_avatar.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Electric Lime Online Status Dot at bottom-right
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFC6F16D),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0B0E0B),
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
        offset: const Offset(0, 50),
        onSelected: (val) {
          if (val == 'settings') {
            context.push('/settings');
          } else if (val == 'sources') {
            context.push('/settings/sources');
          } else if (val == 'embed_stream') {
            EmbedStreamDialog.show(context);
          } else if (val == 'notifications') {
            NotificationsSheet.show(context);
          } else if (val == 'library') {
            context.go('/library');
          } else if (val == 'about') {
            _showAboutDialog(context);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: Image(
                        image: AssetImage('assets/images/default_avatar.png'),
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guest User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Signed in as Guest', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Divider(color: Color(0xFF2A2A32), height: 16),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'embed_stream',
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 12),
                Text('Play from Embed URL', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Settings', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'sources',
            child: Row(
              children: [
                Icon(Icons.dns_outlined, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Streaming Sources', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'notifications',
            child: Row(
              children: [
                Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'library',
            child: Row(
              children: [
                Icon(Icons.video_library_outlined, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('My Library', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('About Deen', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Genre Filter Pill Bar (matching user reference screenshot: All, Action, Adventure, Fantasy)
// ---------------------------------------------------------------------------
Widget smoothHeroFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final Widget toHeroWidget = (toHeroContext.widget as Hero).child;
  return Material(
    type: MaterialType.transparency,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: toHeroWidget,
    ),
  );
}

class _GenreFilterPillBar extends ConsumerWidget {
  const _GenreFilterPillBar();

  static const List<String> genres = [
    'All',
    'Action',
    'Adventure',
    'Fantasy',
    'Romance',
    'Comedy',
    'Sci-Fi',
    'Isekai',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(homeGenreFilterProvider);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre == selected;

          return PressableScale(
            targetScale: 0.94,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(homeGenreFilterProvider.notifier).state = genre;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF263618) : const Color(0xFF141714),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC6F16D)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.0 : 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC6F16D).withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFC6F16D) : const Color(0xFFD6DFD6),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Spotlight Billboard Card (matching media_1792319611255.png)
// ---------------------------------------------------------------------------
class _HeroSpotlightBillboard extends ConsumerStatefulWidget {
  final List<FeaturedAnimeItem> items;

  const _HeroSpotlightBillboard({required this.items});

  @override
  ConsumerState<_HeroSpotlightBillboard> createState() => _HeroSpotlightBillboardState();
}

class _HeroSpotlightBillboardState extends ConsumerState<_HeroSpotlightBillboard> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _cleanSummary(String? summary) {
    if (summary == null || summary.isEmpty) {
      return 'As destiny unfolds, legendary warriors launch a desperate battle against evil to protect their kingdom.';
    }
    return summary
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('\n', ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final count = widget.items.length.clamp(1, 5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF141914),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0x384E604E),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 24,
              spreadRadius: 2,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x24263526),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PageView for Billboard Items
              PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final title = item.titles.preferredTitle();
                  final imageUrl = item.bannerUrl ?? item.posterUrl;
                  final score = item.score != null ? item.score!.toStringAsFixed(1) : '8.6';
                  final format = item.format ?? 'TV';
                  final eps = item.eps ?? 170;
                  final summary = _cleanSummary(item.summary);
                  final followedIds = ref.watch(followedAnimeIdsProvider).value ?? const <int>{};
                  final isFollowed = followedIds.contains(item.id);
                  final heroTag = 'poster_${item.id}_home_spotlight';

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push(
                        '/anime/${item.id}?heroTag=$heroTag',
                        extra: {
                          'posterUrl': item.posterUrl ?? imageUrl,
                          'previewPoster': item.posterUrl ?? imageUrl,
                          'title': title,
                          'previewTitle': title,
                          'heroTag': heroTag,
                        },
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Backdrop Artwork
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Hero(
                            tag: heroTag,
                            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                            flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                memCacheWidth: 800,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                                errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                              ),
                            ),
                          )
                        else
                          Container(color: const Color(0xFF141914)),

                      // Gradient Scrim overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                              const Color(0xFF0B0E0B).withValues(alpha: 0.98),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Top-Left "#1 Trending" Badge
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xDD182412),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFC6F16D).withValues(alpha: 0.75),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFFC6F16D),
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '#${index + 1} Trending',
                                style: const TextStyle(
                                  color: Color(0xFFC6F16D),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Content: Title, metadata, synopsis, CTA buttons
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 15,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  score,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '|',
                                  style: TextStyle(color: Color(0xFF6F826F), fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$format • $eps Episodes',
                                  style: const TextStyle(
                                    color: Color(0xFFB0BFB0),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFC0CEC0),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: AppMotion.m3ScrollPhysics,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Vibrant Amber / Gold "Play Now" Button matching screenshot
                                        PressableScale(
                                          targetScale: 0.94,
                                          onTap: () => context.push('/player?animeId=${item.id}&ep=1'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5BA18),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x55F5BA18),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.black,
                                                  size: 19,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Play Now',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12.5,
                                                    letterSpacing: 0.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Translucent Frosted Glass "+ My List" Button matching screenshot
                                        PressableScale(
                                          targetScale: 0.94,
                                          onTap: () {
                                            ref.read(followRepositoryProvider).toggleFollow(
                                                  item.id,
                                                  metadata: FollowedAnime(
                                                    id: item.id,
                                                    title: title,
                                                    posterUrl: item.posterUrl,
                                                    totalEpisodes: item.eps ?? 0,
                                                    score: item.score ?? 0.0,
                                                    followedAt: DateTime.now(),
                                                  ),
                                                );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.22),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isFollowed ? Icons.check_rounded : Icons.add_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isFollowed ? 'In List' : 'My List',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    letterSpacing: 0.1,
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
                                const SizedBox(width: 8),

                                // Pagination Dots
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(count, (dotIdx) {
                                    final isActive = dotIdx == _currentPage;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: isActive ? 16 : 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFC6F16D) : const Color(0xFF556055),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trending Anime Cards (matching reference image with #1 rank squircle & ★ score on poster)
// ---------------------------------------------------------------------------
class _TrendingLargeCardsList extends StatelessWidget {
  final List<AnimeSummary> items;

  const _TrendingLargeCardsList({required this.items});

  static Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFC6F16D); // Neon lime
      case 1:
        return const Color(0xFF00E5FF); // Electric cyan
      case 2:
        return const Color(0xFFFFB800); // Gold amber
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item.titles.preferredTitle();
          final heroTag = 'poster_${item.id}_home_trending';
          final rankColor = _getRankColor(index);
          final scoreStr = item.score != null ? item.score!.toStringAsFixed(1) : '8.6';

          return RepaintBoundary(
            child: PressableScale(
              onTap: () => context.push(
                '/anime/${item.id}?heroTag=$heroTag',
                extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
              ),
              child: SizedBox(
                width: 149,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster Card Box with rich multi-layer ambient & rim shadows
                    Container(
                      width: 149,
                      height: 209,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141914),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x384E604E), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Color(0x24263526),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                        Hero(
                          tag: heroTag,
                          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                          flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.posterUrl!,
                                    memCacheWidth: 300,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                                  )
                                : Container(color: const Color(0xFF141914)),
                          ),
                        ),

                        // Subtle bottom gradient for score visibility
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),

                        // Top-Left Rank Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xEE0B0E0B),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: rankColor.withValues(alpha: 0.7),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: rankColor,
                              ),
                            ),
                          ),
                        ),

                        // Bottom-Right Score Badge on Poster
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xEE0B0E0B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                                const SizedBox(width: 2.5),
                                Text(
                                  scoreStr,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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

                const SizedBox(height: 7),

                // Title below poster
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 2),

                // Genre subtitle
                const Text(
                  'Action • Fantasy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8E9E8E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }
}

// ---------------------------------------------------------------------------
// Popular This Week Horizontal List (compact posters with rounded corners)
// ---------------------------------------------------------------------------
class _PopularThisWeekList extends StatelessWidget {
  final List<AnimeSummary> items;

  const _PopularThisWeekList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 198,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final heroTag = 'poster_${item.id}_home_popular';

          return RepaintBoundary(
            child: PressableScale(
              onTap: () => context.push(
                '/anime/${item.id}?heroTag=$heroTag',
                extra: {'posterUrl': item.posterUrl, 'title': item.titles.preferredTitle(), 'heroTag': heroTag},
              ),
              child: Container(
                width: 127,
                height: 182,
                decoration: BoxDecoration(
                  color: const Color(0xFF141914),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x384E604E), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Color(0x24263526),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                      ? Hero(
                          tag: heroTag,
                          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                          flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: CachedNetworkImage(
                              imageUrl: item.posterUrl!,
                              memCacheWidth: 240,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                              errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header Widget with Clean Green Bar and "See All >" link
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onSeeAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF8E9E8E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Color(0xFF8E9E8E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popular Categories (Themed square artwork cards)
// ---------------------------------------------------------------------------
class _PopularCategoriesList extends ConsumerWidget {
  const _PopularCategoriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      (name: 'Action', color1: const Color(0xFF8B0000), color2: const Color(0xFF3B0000), icon: Icons.local_fire_department_rounded),
      (name: 'Adventure', color1: const Color(0xFF0072FF), color2: const Color(0xFF00C853), icon: Icons.terrain_rounded),
      (name: 'Fantasy', color1: const Color(0xFF7B1FA2), color2: const Color(0xFF311B92), icon: Icons.castle_rounded),
      (name: 'Isekai', color1: const Color(0xFF00E5FF), color2: const Color(0xFF1A237E), icon: Icons.auto_awesome_rounded),
      (name: 'Romance', color1: const Color(0xFFFF4081), color2: const Color(0xFF880E4F), icon: Icons.favorite_rounded),
      (name: 'Comedy', color1: const Color(0xFFFF9100), color2: const Color(0xFFFF3D00), icon: Icons.sentiment_very_satisfied_rounded),
      (name: 'Sci-Fi', color1: const Color(0xFF00F5D4), color2: const Color(0xFF7B2CBF), icon: Icons.rocket_launch_rounded),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = categories[index];

          return RepaintBoundary(
            child: PressableScale(
              onTap: () {
                ref.read(selectedExploreGenreProvider.notifier).state = cat.name;
                context.go('/explore');
              },
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141914),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0x384E604E),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Color(0x24263526),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(cat.icon, color: AppColors.accent, size: 30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Rated Anime Horizontal List
// ---------------------------------------------------------------------------
class _TopRatedHorizontalList extends StatelessWidget {
  final List<AnimeSummary> items;

  const _TopRatedHorizontalList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item.titles.preferredTitle();
          final heroTag = 'poster_${item.id}_home_toprated';

          return RepaintBoundary(
            child: PressableScale(
              onTap: () => context.push(
                '/anime/${item.id}?heroTag=$heroTag',
                extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
              ),
              child: SizedBox(
                width: 138,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141914),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x384E604E), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Color(0x24263526),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          width: 138,
                          height: 193,
                          color: const Color(0xFF141914),
                          child: item.posterUrl != null
                              ? Hero(
                                  tag: heroTag,
                                  createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                                  flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: CachedNetworkImage(
                                      imageUrl: item.posterUrl!,
                                      memCacheWidth: 250,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text(
                          item.score != null ? item.score!.toStringAsFixed(1) : '9.0',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.eps ?? 24} eps',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF8E9E8E),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recently Added with "NEW" Badge
// ---------------------------------------------------------------------------
class _RecentlyAddedHorizontalList extends StatelessWidget {
  final List<AnimeSummary> items;

  const _RecentlyAddedHorizontalList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item.titles.preferredTitle();
          final heroTag = 'poster_${item.id}_home_new';

          return RepaintBoundary(
            child: PressableScale(
              onTap: () => context.push(
                '/anime/${item.id}?heroTag=$heroTag',
                extra: {'posterUrl': item.posterUrl, 'title': title, 'heroTag': heroTag},
              ),
              child: SizedBox(
                width: 138,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141914),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x384E604E), width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Color(0x24263526),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              width: 138,
                              height: 193,
                              color: const Color(0xFF141914),
                              child: item.posterUrl != null
                                  ? Hero(
                                      tag: heroTag,
                                      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                                      flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: CachedNetworkImage(
                                          imageUrl: item.posterUrl!,
                                          memCacheWidth: 250,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                                          errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      // Electric Lime "NEW" Badge on top-right
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF0B0E0B),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.eps ?? 12} Episodes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User Favourites (from user's followed anime)
// ---------------------------------------------------------------------------
class _UserFavouritesList extends StatelessWidget {
  final List<dynamic> items;

  const _UserFavouritesList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final dynamic item = items[index];
          final title = (item.title ?? item.name ?? '').toString();
          final poster = item.posterUrl?.toString();

          return RepaintBoundary(
            child: PressableScale(
              onTap: () => context.push(
                '/anime/${item.id}',
                extra: {'posterUrl': poster, 'title': title},
              ),
              child: SizedBox(
                width: 138,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141914),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x384E604E), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Color(0x24263526),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 138,
                          height: 193,
                          color: const Color(0xFF1E1E26),
                          child: poster != null && poster.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: poster,
                                  memCacheWidth: 250,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: const Color(0xFF1E1E26)),
                                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF1E1E26)),
                                )
                              : const Icon(Icons.star_rounded, color: Colors.white24, size: 40),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Continue Watching Card Widget (16:9 widescreen with play circle & title below)
// ---------------------------------------------------------------------------
class _ContinueWatchingCard extends StatelessWidget {
  final WatchHistoryItem item;
  final bool isFirst;

  const _ContinueWatchingCard({required this.item, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
      },
      child: SizedBox(
        width: 275,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 154,
              decoration: BoxDecoration(
                color: const Color(0xFF141914),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x384E604E),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x24263526),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                  if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: item.posterUrl!,
                      memCacheWidth: 500,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                    )
                  else
                    Container(color: const Color(0xFF141914)),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          const Color(0xFF0B0E0B).withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Top-Right RESUME Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xEE0B0E0B),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'RESUME',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Center Play Button (Electric lime circle on first, frosted translucent on others)
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isFirst ? AppColors.accent : const Color(0xB31F2A1F),
                        shape: BoxShape.circle,
                        border: isFirst
                            ? null
                            : Border.all(color: const Color(0x55FFFFFF), width: 1.0),
                        boxShadow: isFirst
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: isFirst ? const Color(0xFF0B0E0B) : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  // Episode info and Three-dot menu at bottom of thumbnail
                  Positioned(
                    left: 10,
                    right: 6,
                    bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Ep ${item.episodeNumber} · ${item.formattedProgress}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  // Progress Bar at the very bottom edge of thumbnail
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: item.progressFraction,
                      minHeight: 3.0,
                      backgroundColor: const Color(0x66000000),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 7),

            // Title below card
            Text(
              item.animeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton Placeholders
// ---------------------------------------------------------------------------
class _CardListSkeleton extends StatelessWidget {
  final double itemWidth;
  final double itemHeight;

  const _CardListSkeleton({required this.itemWidth, required this.itemHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight + 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: itemWidth,
                height: itemHeight,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: itemWidth * 0.7,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ),
    );
  }
}
