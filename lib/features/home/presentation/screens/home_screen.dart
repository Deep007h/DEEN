// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../../../core/presentation/widgets/hero_shuttle_builder.dart';
import '../../../../core/presentation/widgets/floating_nav_bar.dart';
import '../../../explore/presentation/providers/explore_providers.dart';

/// State provider for Home screen genre filter pill bar.
final homeGenreFilterProvider = StateProvider<String>((ref) => 'Home');

/// Redesigned Home screen matching reference UI (media_1792761512098.png) 1:1.
/// Features:
/// - Custom top bar: DEEN PRO logo, "STREAM ANIME YOUR WAY", circular search button, & profile with online green dot.
/// - Docked bottom navigation bar with solid lime pill capsule for active tab.
/// - Horizontal category pill bar: [Home], [Anime], [Movies], [Trending], [My List].
/// - Hero Spotlight Billboard Card with [🔥 #1 Trending] badge, title, meta, Play Now (electric lime CTA) + My List button, and elongated pill indicator.
/// - "Continue Watching" with 16:9 widescreen thumbnails, circular play button, progress bar & title below.
/// - "Trending Anime" with rank badges (1, 2, 3, 4 squircle) & star score with title below.
/// - "Genres" squircle themed cards (Action, Adventure, Fantasy, Romance, Comedy, Thriller, Sci-Fi, K-Drama).
/// - "Recommended for You" wide character portrait cards (Gojo, Nezuko, Ichigo, Kaneki).
/// - Top rated anime, recently added, and user favourites.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _hideController;
  late final Animation<double> _topBarCurve;
  late final ScrollController _scrollController;
  bool _isTopBarHidden = false;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: AppMotion.short4,
    );
    _topBarCurve = CurvedAnimation(
      parent: _hideController,
      curve: AppMotion.hyperOsDecelerate,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _hideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset <= 12 && _isTopBarHidden) {
        _isTopBarHidden = false;
        _hideController.reverse();
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        // Scrolling down -> auto-hide top bar
        if (_scrollController.hasClients && _scrollController.offset > 45) {
          if (!_isTopBarHidden) {
            _isTopBarHidden = true;
            _hideController.forward();
          }
        }
      } else if (notification.direction == ScrollDirection.forward) {
        // Scrolling up -> auto-show top bar
        if (_isTopBarHidden) {
          _isTopBarHidden = false;
          _hideController.reverse();
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      final dy = notification.scrollDelta ?? 0.0;
      if (dy > 8.0 && _scrollController.hasClients && _scrollController.offset > 50) {
        if (!_isTopBarHidden) {
          _isTopBarHidden = true;
          _hideController.forward();
        }
      } else if (dy < -8.0) {
        if (_isTopBarHidden) {
          _isTopBarHidden = false;
          _hideController.reverse();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final topBarHeight = topPadding + 104.0;

    final selectedGenre = ref.watch(homeGenreFilterProvider);
    final featuredAsync = ref.watch(featuredAnimeProvider);
    final trendingAsync = (selectedGenre == 'Home' || selectedGenre == 'All')
        ? ref.watch(trendingAnimeProvider)
        : selectedGenre == 'Trending'
            ? ref.watch(trendingAnimeProvider)
            : selectedGenre == 'Recommended'
                ? ref.watch(recommendedAnimeProvider)
                : ref.watch(categoryAnimeProvider(selectedGenre));
    final recommendedAsync = ref.watch(recommendedAnimeProvider);
    final topRatedAsync = ref.watch(topRatedAnimeProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedAnimeProvider);
    final followedAsync = ref.watch(followedAnimeListProvider);
    final historyAsync = ref.watch(watchHistoryListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            // 1. Scrollable Content Layer with Scoped Refresh Indicator & Stretch
            RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: const Color(0xFF141914),
              displacement: 32,
              edgeOffset: topBarHeight + 6,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.read(homeRefreshSeedProvider.notifier).state++;
                await Future.wait([
                  ref.refresh(featuredAnimeProvider.future),
                  ref.refresh(trendingAnimeProvider.future),
                  ref.refresh(recommendedAnimeProvider.future),
                  ref.refresh(topRatedAnimeProvider.future),
                  ref.refresh(recentlyAddedAnimeProvider.future),
                  ref.refresh(followedAnimeListProvider.future),
                  ref.refresh(watchHistoryListProvider.future),
                  if (selectedGenre != 'Home' && selectedGenre != 'All' && selectedGenre != 'Trending' && selectedGenre != 'Recommended')
                    ref.refresh(categoryAnimeProvider(selectedGenre).future),
                ]);
              },
              child: CustomScrollView(
                controller: _scrollController,
                cacheExtent: 500,
                physics: AppMotion.m3ScrollPhysics,
                slivers: [
                  // Spacer corresponding to the fixed floating top bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: topBarHeight + 10),
                  ),

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
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: _SectionErrorCard(
                    title: 'Featured Anime',
                    onRetry: () => ref.invalidate(featuredAnimeProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 4. Continue Watching (16:9 widescreen cards with play overlay & lime progress)
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
                      _ContinueWatchingSection(history: history),
                      const SizedBox(height: 26),
                    ],
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // 5. Trending Anime (with 1, 2, 3, 4 squircle rank badges and star ratings)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending Anime',
                onSeeAll: () => context.push('/search'),
              ),
            ),
            SliverToBoxAdapter(
              child: trendingAsync.when(
                data: (items) => _TrendingLargeCardsList(items: items),
                loading: () => const _CardListSkeleton(itemWidth: 144, itemHeight: 204),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: _SectionErrorCard(
                    title: 'Trending Anime',
                    onRetry: () => ref.invalidate(trendingAnimeProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 6. Genres (Themed squircle cards: Action, Adventure, Fantasy, Romance, etc.)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Genres',
                onSeeAll: () => context.go('/explore'),
              ),
            ),
            const SliverToBoxAdapter(
              child: _GenresList(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 7. Recommended for You (Dynamic anime cards)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recommended for You',
                onSeeAll: () {
                  ref.read(homeGenreFilterProvider.notifier).state = 'Recommended';
                },
              ),
            ),
            SliverToBoxAdapter(
              child: recommendedAsync.when(
                data: (items) => _RecommendedForYouList(items: items),
                loading: () => const _CardListSkeleton(itemWidth: 168, itemHeight: 104),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: _SectionErrorCard(
                    title: 'Recommended for You',
                    onRetry: () => ref.invalidate(recommendedAnimeProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 8. If non-home category filter is active, show category hit list
            if (selectedGenre != 'Home' && selectedGenre != 'All' && selectedGenre != 'Trending') ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '$selectedGenre Hits',
                  onSeeAll: () => context.push('/search'),
                ),
              ),
              SliverToBoxAdapter(
                child: trendingAsync.when(
                  data: (items) => _TrendingLargeCardsList(items: items),
                  loading: () => const _CardListSkeleton(itemWidth: 144, itemHeight: 204),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
            ],

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
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: _SectionErrorCard(
                    title: 'Top Rated Anime',
                    onRetry: () => ref.invalidate(topRatedAnimeProvider),
                  ),
                ),
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
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: _SectionErrorCard(
                    title: 'Recently Added',
                    onRetry: () => ref.invalidate(recentlyAddedAnimeProvider),
                  ),
                ),
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
            SliverToBoxAdapter(
              child: SizedBox(height: FloatingNavBar.getBottomPadding(context)),
            ),
          ],
        ),
      ),

      // 2. Fixed Floating Auto-Hiding Top Bar
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _topBarCurve,
          builder: (context, child) {
            final curvedVal = _topBarCurve.value;
            final translateY = -curvedVal * topBarHeight;
            final opacity = (1.0 - curvedVal).clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Opacity(
                opacity: opacity,
                child: IgnorePointer(
                  ignoring: curvedVal > 0.5,
                  child: child,
                ),
              ),
            );
          },
          child: RepaintBoundary(
            child: _HomeTopBar(topPadding: topPadding),
          ),
        ),
      ),
    ],
  ),
),
);
  }
}

// ---------------------------------------------------------------------------
// Fixed Auto-Hiding Top Bar Component
// ---------------------------------------------------------------------------
class _HomeTopBar extends StatelessWidget {
  final double topPadding;

  const _HomeTopBar({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Brand Row: DEEN PRO logo on left, Search, Notification Bell & Profile Avatar on right
              Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 6,
                  left: AppSpacing.pageMargin,
                  right: AppSpacing.pageMargin,
                  bottom: 8,
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
                          Image.asset(
                            'assets/images/logo.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    const Text(
                                      'DEEN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.proBadgeBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.proBadgeBorder,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.proBadgeText,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  'Stream Anime Your Way',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF8E9E8E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Top Bar Action Buttons: Circular Search, Notification Bell with lime unread dot & Profile Avatar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Search anime',
                          child: PressableScale(
                            targetScale: 0.92,
                            onTap: () => context.push('/search'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141914),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x334E604E), width: 0.9),
                              ),
                              child: const Center(
                                child: Icon(Icons.search_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _NotificationButton(),
                        const SizedBox(width: 8),
                        const _ProfileDropdownButton(),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // Horizontal Category / Genre Filter Pill Bar
              const _GenreFilterPillBar(),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Bell Button with Lime Unread Dot Badge
// ---------------------------------------------------------------------------
class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141914),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x334E604E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E281E),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              ),
              title: const Text(
                'DEEN PRO v2.0 Ready',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Full UI redesign, dynamic pull-to-refresh & K-Drama catalog enabled',
                style: TextStyle(color: Color(0xFF8E9E8E), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      targetScale: 0.92,
      onTap: () {
        HapticFeedback.lightImpact();
        _showNotificationsSheet(context);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF141914),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x334E604E), width: 0.9),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 20,
            ),
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0C100C), width: 1.2),
                ),
              ),
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
            Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
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
        content: Column(
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
            const SizedBox(height: 8),
            const Text(
              'Engineered with AniList GraphQL, high-speed CDN multi-mirror streaming, zero-stall HLS demuxing, and Autonomous Studio telemetry.',
              style: TextStyle(color: Color(0xFF8E9E8E), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
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
                  color: AppColors.accent,
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
          PopupMenuItem(
            value: 'embed_stream',
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                const Text('Play from Embed URL', style: TextStyle(color: Colors.white, fontSize: 14)),
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
// Category / Genre Filter Pill Bar (matching media_1792761512098.png 1:1)
// ---------------------------------------------------------------------------

class _GenreFilterPillBar extends ConsumerWidget {
  const _GenreFilterPillBar();

  static const List<String> categories = [
    'Home',
    'Anime',
    'Movies',
    'Trending',
    'Recommended',
    'K-Drama',
    'My List',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(homeGenreFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;

          return PressableScale(
            targetScale: 0.94,
            onTap: () {
              HapticFeedback.selectionClick();
              if (cat == 'My List') {
                context.go('/library');
                return;
              }
              ref.read(homeGenreFilterProvider.notifier).state = cat;
            },
            child: AnimatedContainer(
              duration: AppMotion.short4,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : const Color(0xFF141914),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : const Color(0x384E604E),
                  width: 0.9,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0D120D)
                        : const Color(0xFFD6DFD6),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: -0.2,
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
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 7200), (_) {
      if (!mounted || !_pageController.hasClients || widget.items.isEmpty) return;
      final count = widget.items.length.clamp(1, 5);
      if (count <= 1) return;
      final next = (_currentPageNotifier.value + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _currentPageNotifier.dispose();
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
    final followedIds = ref.watch(followedAnimeIdsProvider).value ?? const <int>{};

    final clampedScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.25);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350, maxHeight: 385),
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
          child: Listener(
            onPointerDown: (_) => _pauseAutoScroll(),
            onPointerUp: (_) => _resumeAutoScroll(),
            onPointerCancel: (_) => _resumeAutoScroll(),
            child: Stack(
              fit: StackFit.expand,
              children: [
              // PageView for Billboard Items
              PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (index) {
                  _currentPageNotifier.value = index;
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final title = item.titles.preferredTitle();
                  final imageUrl = item.bannerUrl ?? item.posterUrl;
                  final score = item.score != null ? item.score!.toStringAsFixed(1) : '—';
                  final format = item.format ?? 'TV';
                  final eps = item.eps != null ? '${item.eps} Episodes' : 'Ongoing';
                  final summary = _cleanSummary(item.summary);
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
                            createRectTween: smoothHeroRectTween,
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
                            color: const Color(0xDD142010),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.accent,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '#${index + 1} Trending',
                                style: TextStyle(
                                  color: AppColors.accent,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '2024  •  $format  •  $eps  •  $score',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFD6DFD6),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 16,
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
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Electric Lime "Watch Now" Button
                                PressableScale(
                                  targetScale: 0.94,
                                  onTap: () {
                                    context.push('/player?animeId=${item.id}&ep=1');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accentSoft,
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.accentContrast,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Watch Now',
                                          style: TextStyle(
                                            color: AppColors.accentContrast,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Translucent Frosted Glass "+ My List" Button
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: const Color(0x551E281E),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFollowed ? Icons.check_rounded : Icons.add_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isFollowed ? 'In List' : 'My List',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

            // 5. Pagination Dots anchored at bottom right
            Positioned(
              right: 16,
              bottom: 22,
              child: ValueListenableBuilder<int>(
                valueListenable: _currentPageNotifier,
                builder: (context, activeIndex, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (dotIdx) {
                      final isActive = dotIdx == activeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: AppMotion.hyperOsSpring,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        width: isActive ? 20 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accent : const Color(0x55FFFFFF),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            ],
          ),
        ),
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
        return AppColors.accent; // Primary dynamic accent
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
      height: 260,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item.titles.preferredTitle();
          final heroTag = 'poster_${item.id}_home_trending';
          final rankColor = _getRankColor(index);
          final scoreStr = item.score != null ? item.score!.toStringAsFixed(1) : '—';

          return RepaintBoundary(
            child: PressableScale(
              targetScale: 0.95,
              onTap: () {
                final isKDrama = item.platform == 'K-Drama';
                context.push(
                  '/anime/${item.id}?heroTag=$heroTag${isKDrama ? '&isKShow=true' : ''}',
                  extra: {
                    'posterUrl': item.posterUrl,
                    'title': title,
                    'heroTag': heroTag,
                    'isKShow': isKDrama,
                  },
                );
              },
              child: SizedBox(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster Card Box with rich multi-layer ambient & rim shadows
                    Container(
                      width: 144,
                      height: 204,
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
                              createRectTween: smoothHeroRectTween,
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

                            // Top-Left Rank Squircle Badge (plain 1, 2, 3, 4 without #)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xEE0B0E0B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: rankColor.withValues(alpha: 0.7),
                                    width: 0.9,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: rankColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Title row with three-dot icon on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF8E9E8E),
                          size: 16,
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Subtitle: Star rating and metadata
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          scoreStr,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF8E9E8E),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.platform != null && item.platform!.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: Color(0xFF8E9E8E), fontSize: 11)),
                          Expanded(
                            child: Text(
                              item.platform!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8E9E8E),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
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
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Genres (Themed squircle cards: Action, Adventure, Fantasy, Romance, etc.)
// ---------------------------------------------------------------------------
class _GenresList extends ConsumerWidget {
  const _GenresList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      (name: 'Action', color: const Color(0xFFFF5722), icon: Icons.local_fire_department_rounded),
      (name: 'Adventure', color: const Color(0xFF00E676), icon: Icons.explore_rounded),
      (name: 'Fantasy', color: const Color(0xFFAB47BC), icon: Icons.auto_awesome_rounded),
      (name: 'Romance', color: const Color(0xFFFF4081), icon: Icons.favorite_rounded),
      (name: 'Comedy', color: const Color(0xFFFFC107), icon: Icons.sentiment_very_satisfied_rounded),
      (name: 'Thriller', color: const Color(0xFFE53935), icon: Icons.visibility_rounded),
      (name: 'Sci-Fi', color: const Color(0xFF00E5FF), icon: Icons.rocket_launch_rounded),
      (name: 'K-Drama', color: AppColors.accent, icon: Icons.live_tv_rounded),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];

          return RepaintBoundary(
            child: PressableScale(
              targetScale: 0.94,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(selectedExploreGenreProvider.notifier).state = cat.name;
                context.go('/explore');
              },
              child: Container(
                width: 88,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF141914),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cat.color.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat.icon, color: cat.color, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
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
// Recommended for You (Dynamic anime cards)
// ---------------------------------------------------------------------------
class _RecommendedForYouList extends StatelessWidget {
  final List<AnimeSummary> items;
  const _RecommendedForYouList({this.items = const []});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 106,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final heroTag = 'recommended_${item.id}';
          final title = item.titles.preferredTitle();
          final isKDrama = item.platform == 'K-Drama';

          return RepaintBoundary(
            child: PressableScale(
              targetScale: 0.95,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(
                  '/anime/${item.id}?heroTag=$heroTag${isKDrama ? '&isKShow=true' : ''}',
                  extra: {
                    'heroTag': heroTag,
                    'previewTitle': title,
                    'previewPoster': item.posterUrl,
                    'isKShow': isKDrama,
                  },
                );
              },
              child: Container(
                width: 168,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xFF141914),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x384E604E), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                        Hero(
                          tag: heroTag,
                          flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                          child: CachedNetworkImage(
                            imageUrl: item.posterUrl!,
                            memCacheWidth: 340,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF141914),
                              child: const Icon(Icons.movie_rounded, color: Color(0xFF8E9E8E)),
                            ),
                          ),
                        )
                      else
                        Container(color: const Color(0xFF141914)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.88),
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                        ),
                      ),
                      // Score badge
                      if (item.score != null && item.score! > 0)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 11, color: AppColors.accent),
                                const SizedBox(width: 3),
                                Text(
                                  item.score!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Episode / Format pill
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.eps != null && item.eps! > 0
                                ? '${item.eps} eps'
                                : (item.platform ?? 'TV'),
                            style: const TextStyle(
                              color: Color(0xFFB5E2B5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Title
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
              onTap: () {
                final isKDrama = item.platform == 'K-Drama';
                context.push(
                  '/anime/${item.id}?heroTag=$heroTag${isKDrama ? '&isKShow=true' : ''}',
                  extra: {
                    'posterUrl': item.posterUrl,
                    'title': title,
                    'heroTag': heroTag,
                    'isKShow': isKDrama,
                  },
                );
              },
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
                                  createRectTween: smoothHeroRectTween,
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
                          item.score != null ? item.score!.toStringAsFixed(1) : '—',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.eps != null ? '${item.eps} eps' : 'Series',
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
              onTap: () {
                final isKDrama = item.platform == 'K-Drama';
                context.push(
                  '/anime/${item.id}?heroTag=$heroTag${isKDrama ? '&isKShow=true' : ''}',
                  extra: {
                    'posterUrl': item.posterUrl,
                    'title': title,
                    'heroTag': heroTag,
                    'isKShow': isKDrama,
                  },
                );
              },
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
                                      createRectTween: smoothHeroRectTween,
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
                    item.eps != null ? '${item.eps} Episodes' : 'Latest Release',
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
// Continue Watching Section & 16:9 Widescreen Cards (matching media_1792761512098.png)
// ---------------------------------------------------------------------------
class _ContinueWatchingPreview {
  final String title;
  final String subtitle;
  final double progress;
  final String posterUrl;
  final String query;

  const _ContinueWatchingPreview({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.posterUrl,
    required this.query,
  });
}

const List<_ContinueWatchingPreview> _kContinueWatchingPreviews = [
  _ContinueWatchingPreview(
    title: 'Jujutsu Kaisen',
    subtitle: 'S1 E12 • 14m left',
    progress: 0.65,
    posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113415-jQBSkxWAAk83.jpg',
    query: 'Jujutsu Kaisen',
  ),
  _ContinueWatchingPreview(
    title: 'Demon Slayer',
    subtitle: 'S3 E8 • 21m left',
    progress: 0.35,
    posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101922-YfZhKBUDDS6L.jpg',
    query: 'Demon Slayer',
  ),
  _ContinueWatchingPreview(
    title: 'One Piece',
    subtitle: 'E1085 • 8m left',
    progress: 0.85,
    posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21-wf37VakJSpdH.jpg',
    query: 'One Piece',
  ),
];

class _ContinueWatchingSection extends ConsumerWidget {
  final List<WatchHistoryItem> history;

  const _ContinueWatchingSection({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHistory = history.isNotEmpty;
    final count = hasHistory ? history.length : _kContinueWatchingPreviews.length;

    return SizedBox(
      height: 206,
      child: ListView.separated(
        cacheExtent: 500,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: AppMotion.m3ScrollPhysics,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (hasHistory) {
            final item = history[index];
            return RepaintBoundary(
              child: _ContinueWatchingCard(
                title: item.animeTitle,
                subtitle: 'Ep ${item.episodeNumber} · ${item.formattedProgress}',
                progress: item.progressFraction,
                posterUrl: item.posterUrl,
                isFirst: index == 0,
                onTap: () {
                  context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
                },
                onRemove: () async {
                  final repo = ref.read(playbackHistoryRepositoryProvider);
                  await repo.deleteHistoryItem(item.animeId, item.episodeNumber);
                },
              ),
            );
          } else {
            final preview = _kContinueWatchingPreviews[index];
            return RepaintBoundary(
              child: _ContinueWatchingCard(
                title: preview.title,
                subtitle: preview.subtitle,
                progress: preview.progress,
                posterUrl: preview.posterUrl,
                isFirst: index == 0,
                onTap: () {
                  context.push('/search?q=${Uri.encodeComponent(preview.query)}');
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String? posterUrl;
  final bool isFirst;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ContinueWatchingCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    this.posterUrl,
    this.isFirst = false,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      targetScale: 0.96,
      onTap: onTap,
      child: SizedBox(
        width: 236,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
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
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (posterUrl != null && posterUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: posterUrl!,
                        memCacheWidth: 480,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFF141914)),
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF141914)),
                      )
                    else
                      Container(color: const Color(0xFF141914)),

                    // Dark gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),

                    // Centered circular frosted play button with white icon
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0x66000000),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x66FFFFFF), width: 1.0),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // Bottom progress bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 3.5,
                          backgroundColor: const Color(0x66000000),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 7),

            // Line 1: Title + Three-dot menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onRemove != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    tooltip: 'Options',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF8E9E8E),
                      size: 18,
                    ),
                    color: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0x384E604E), width: 0.8),
                    ),
                    onSelected: (val) {
                      if (val == 'remove') {
                        onRemove!();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'remove',
                        height: 36,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Remove from history', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF8E9E8E),
                    size: 18,
                  ),
              ],
            ),

            const SizedBox(height: 2),

            // Line 2: Subtitle
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8E9E8E),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
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

class _SectionErrorCard extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _SectionErrorCard({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141914),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x384E604E), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8E9E8E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load $title',
              style: const TextStyle(
                color: Color(0xFF8E9E8E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(48, 32),
              foregroundColor: AppColors.accent,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
