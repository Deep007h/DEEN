import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/floating_nav_bar.dart';
import '../../../../core/presentation/widgets/hero_shuttle_builder.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../settings/data/repositories/app_settings_repository.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';
import 'package:anime_stream/features/stream/presentation/providers/stream_providers.dart';
import 'package:anime_stream/features/player/presentation/widgets/embed_stream_dialog.dart';

/// Filter tabs for unified search results
enum SearchFilterTab {
  all,
  anime,
  kdrama,
}

/// Unified search result item model merging Anime and K-Drama/Asian Drama titles
class UnifiedSearchItem {
  final String id;
  final String title;
  final String? posterUrl;
  final double? score;
  final int? heat;
  final int? episodeCount;
  final bool isKShow;
  final AnimeSummary? anime;
  final SourceMatch? kshow;

  UnifiedSearchItem.fromAnime(this.anime, this.title)
      : id = anime!.id.toString(),
        posterUrl = anime.posterUrl,
        score = anime.score,
        heat = anime.heat,
        episodeCount = anime.eps,
        isKShow = false,
        kshow = null;

  UnifiedSearchItem.fromKShow(this.kshow)
      : id = kshow!.id,
        title = kshow.title,
        posterUrl = kshow.customData['thumb'] as String?,
        score = null,
        heat = null,
        episodeCount = kshow.episodeCount,
        isKShow = true,
        anime = null;
}

/// Redesigned Full-Screen Unified Search Screen.
/// Seamlessly queries and merges Anime and K-Drama catalogs concurrently.
/// Features a streamlined search bar, animated filter pills, trending suggestions,
/// and smooth staggered entry animations.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  SearchFilterTab _selectedFilter = SearchFilterTab.all;
  List<SourceMatch> _kshowResults = [];
  bool _isKShowLoading = false;
  Timer? _kshowDebounceTimer;
  CancelToken? _kshowCancelToken;

  static const List<String> _trendingSearches = [
    'Frieren',
    'Solo Leveling',
    'Queen of Tears',
    'Demon Slayer',
    'Crash Landing on You',
    'Jujutsu Kaisen',
    'Teach You a Lesson',
    'Vincenzo',
    'Attack on Titan',
    'Squid Game',
  ];

  static const List<String> _popularGenres = [
    'Action',
    'Fantasy',
    'Romance',
    'Drama',
    'Mystery',
    'Sci-Fi',
    'Comedy',
    'Supernatural',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_onScroll);

    if (initialQuery.trim().isNotEmpty) {
      _searchKShows(initialQuery.trim());
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 320) {
      ref.read(searchPaginationProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _kshowDebounceTimer?.cancel();
    _kshowCancelToken?.cancel('SearchScreen disposed');
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    ref.read(searchQueryProvider.notifier).state = val;
    _kshowDebounceTimer?.cancel();
    _kshowDebounceTimer = Timer(const Duration(milliseconds: 320), () {
      _searchKShows(val);
    });
  }

  Future<void> _searchKShows(String query) async {
    _kshowDebounceTimer?.cancel();
    _kshowCancelToken?.cancel('New search initiated');
    final cancelToken = CancelToken();
    _kshowCancelToken = cancelToken;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _kshowResults = [];
          _isKShowLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isKShowLoading = true;
      });
    }

    try {
      final results = await ref.read(megaVidProvider).searchKShows(
        trimmed,
        cancelToken: cancelToken,
      );
      if (mounted && !cancelToken.isCancelled && cancelToken == _kshowCancelToken) {
        for (final m in results) {
          ref.read(metadataRepositoryProvider).recordKShowMatch(m);
        }
        setState(() {
          _kshowResults = results;
          _isKShowLoading = false;
        });
      }
    } catch (e) {
      if (cancelToken.isCancelled ||
          (e is DioException && (e.type == DioExceptionType.cancel || CancelToken.isCancel(e)))) {
        return;
      }
      if (mounted && cancelToken == _kshowCancelToken) {
        setState(() {
          _isKShowLoading = false;
        });
      }
    }
  }

  void _submitSearch([String? rawQuery]) {
    _focusNode.unfocus();
    final query = (rawQuery ?? _searchController.text).trim();
    ref.read(searchQueryProvider.notifier).state = query;
    ref.read(searchPaginationProvider.notifier).search(query);
    _kshowDebounceTimer?.cancel();
    _searchKShows(query);
  }

  void _applyQuickQuery(String query) {
    HapticFeedback.selectionClick();
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _submitSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final currentSort = ref.watch(searchSortProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    final paginationState = ref.watch(searchPaginationProvider);
    final titlePref = ref.watch(titlePreferenceProvider);

    final sortOptions = [
      (SearchSort.match, l10n.filterMatch),
      (SearchSort.heat, l10n.filterPopularity),
      (SearchSort.score, l10n.filterRating),
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridCrossAxisCount = screenWidth >= 1000
        ? 5
        : (screenWidth >= 700 ? 4 : (screenWidth >= 480 ? 3 : 2));

    // Construct unified items list
    final animeItems = paginationState.items
        .map((a) => UnifiedSearchItem.fromAnime(a, a.titles.preferredTitle(titlePref)))
        .toList();
    final kshowItems = _kshowResults
        .map((k) => UnifiedSearchItem.fromKShow(k))
        .toList();

    List<UnifiedSearchItem> displayedItems;
    switch (_selectedFilter) {
      case SearchFilterTab.all:
        // Interleave matches gracefully: prioritize exact/strong title matches first
        final combined = <UnifiedSearchItem>[];
        final query = _searchController.text.trim().toLowerCase();

        final priorityAnime = <UnifiedSearchItem>[];
        final otherAnime = <UnifiedSearchItem>[];
        for (final item in animeItems) {
          if (query.isNotEmpty && item.title.toLowerCase().contains(query)) {
            priorityAnime.add(item);
          } else {
            otherAnime.add(item);
          }
        }

        final priorityKShow = <UnifiedSearchItem>[];
        final otherKShow = <UnifiedSearchItem>[];
        for (final item in kshowItems) {
          if (query.isNotEmpty && item.title.toLowerCase().contains(query)) {
            priorityKShow.add(item);
          } else {
            otherKShow.add(item);
          }
        }

        combined.addAll(priorityAnime);
        combined.addAll(priorityKShow);
        combined.addAll(otherAnime);
        combined.addAll(otherKShow);
        displayedItems = combined;
        break;
      case SearchFilterTab.anime:
        displayedItems = animeItems;
        break;
      case SearchFilterTab.kdrama:
        displayedItems = kshowItems;
        break;
    }

    final isSearching = paginationState.isLoading || _isKShowLoading;
    final hasActiveQuery = _searchController.text.trim().isNotEmpty || selectedTags.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.pageMargin),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: PressableScale(
                targetScale: 0.92,
                curve: AppMotion.hyperOsSpring,
                onTap: () => context.pop(),
                child: Container(
                  width: AppSpacing.circleButtonSm,
                  height: AppSpacing.circleButtonSm,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        leadingWidth: AppSpacing.pageMargin + 48,
        centerTitle: true,
        title: Text(
          l10n.searchTitle,
          style: AppText.sectionTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pageMargin),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: PressableScale(
                  targetScale: 0.92,
                  curve: AppMotion.hyperOsSpring,
                  onTap: () => EmbedStreamDialog.show(context),
                  child: Container(
                    width: AppSpacing.circleButtonSm,
                    height: AppSpacing.circleButtonSm,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Header: "Anime Search" (Ensures test compatibility) & Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bangumiSearchTitle,
                    style: AppText.pageTitle.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Search all anime, k-dramas, and asian series concurrently',
                    style: AppText.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.elementGapMd),
                ],
              ),
            ),
          ),

          // Streamlined Material 3 Search Control Bar (Without Dropdown)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.elementGapMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unified Search Bar Pill
                    Container(
                      height: AppSpacing.buttonHeightLg,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.pillBorder,
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.accent.withValues(alpha: 0.6)
                              : theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: _focusNode.hasFocus ? 1.2 : 0.8,
                        ),
                        boxShadow: _focusNode.hasFocus
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            color: _focusNode.hasFocus
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, _) {
                                return TextField(
                                  controller: _searchController,
                                  focusNode: _focusNode,
                                  autofocus: false,
                                  textInputAction: TextInputAction.search,
                                  style: AppText.body.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: AppColors.accent,
                                  onSubmitted: (val) => _submitSearch(val),
                                  onChanged: _onQueryChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Search anime, k-drama, series…',
                                    hintStyle: AppText.bodySecondary.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    suffixIcon: value.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            tooltip: 'Clear',
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              _searchController.clear();
                                              _onQueryChanged('');
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: PressableScale(
                              targetScale: 0.94,
                              curve: AppMotion.hyperOsSpring,
                              onTap: _submitSearch,
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: AppColors.accentContrast,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      l10n.searchAction,
                                      style: TextStyle(
                                        color: AppColors.accentContrast,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter Pills: All / Anime / K-Drama
                    if (hasActiveQuery || displayedItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.elementGapMd),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: AppMotion.m3ScrollPhysics,
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: 'All (${animeItems.length + kshowItems.length})',
                              tab: SearchFilterTab.all,
                              icon: Icons.auto_awesome_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Anime (${animeItems.length})',
                              tab: SearchFilterTab.anime,
                              icon: Icons.movie_filter_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'K-Drama (${kshowItems.length})',
                              tab: SearchFilterTab.kdrama,
                              icon: Icons.live_tv_rounded,
                              activeColor: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tag Filter Row (when tags are active)
                    if (selectedTags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.elementGapSm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.tagFilter,
                            style: AppText.meta.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: AppMotion.m3ScrollPhysics,
                              child: Row(
                                children: selectedTags.map((tag) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InputChip(
                                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                                      onDeleted: () {
                                        ref.read(selectedTagsProvider.notifier).removeTag(tag);
                                      },
                                      deleteIconColor: AppColors.accent,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Segmented Sort (Match | Popularity | Score)
                    if (_selectedFilter != SearchFilterTab.kdrama && hasActiveQuery) ...[
                      const SizedBox(height: AppSpacing.elementGapMd),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<SearchSort>(
                          segments: sortOptions.map((entry) {
                            return ButtonSegment<SearchSort>(
                              value: entry.$1,
                              label: Text(entry.$2),
                            );
                          }).toList(),
                          selected: {currentSort},
                          onSelectionChanged: (newSelection) {
                            if (newSelection.isNotEmpty) {
                              ref.read(searchSortProvider.notifier).state = newSelection.first;
                            }
                          },
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.elementGapMd)),

          // Content States: Loading / Empty Suggestions / Results Grid
          if (isSearching && displayedItems.isEmpty) ...[
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
                  (context, index) => const _PosterSkeletonCard(),
                  childCount: 6,
                ),
              ),
            ),
          ] else if (!hasActiveQuery && displayedItems.isEmpty) ...[
            // Discovery & Trending Suggestions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.elementGapSm),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 19,
                          color: Color(0xFFFF6D00),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Trending Searches',
                          style: AppText.sectionTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.elementGapSm + 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _trendingSearches.map((keyword) {
                        return PressableScale(
                          targetScale: 0.94,
                          curve: AppMotion.hyperOsSpring,
                          onTap: () => _applyQuickQuery(keyword),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  keyword,
                                  style: AppText.meta.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Popular Genres',
                          style: AppText.sectionTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.elementGapSm + 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularGenres.map((genre) {
                        return PressableScale(
                          targetScale: 0.94,
                          curve: AppMotion.hyperOsSpring,
                          onTap: () {
                            ref.read(selectedTagsProvider.notifier).addTag(genre);
                            _submitSearch();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: AppText.meta.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],
                ),
              ),
            ),
          ] else if (displayedItems.isEmpty) ...[
            // Empty Results State
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.elementGapLg),
                      Text(
                        'No matching titles found',
                        style: AppText.sectionTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try searching by anime name, drama title, or alternative spelling',
                        textAlign: TextAlign.center,
                        style: AppText.bodySecondary.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Animated Staggered Results Grid
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
                    final item = displayedItems[index];
                    return _UnifiedPosterCard(
                      key: ValueKey(item.id + (item.isKShow ? '_kshow' : '_anime')),
                      item: item,
                      index: index,
                      onTap: () {
                        if (item.isKShow && item.kshow != null) {
                          ref.read(metadataRepositoryProvider).recordKShowMatch(item.kshow!);
                          context.push(
                            '/anime/${item.id}?isKShow=true',
                            extra: {
                              'posterUrl': item.posterUrl,
                              'title': item.title,
                              'isKShow': true,
                              'match': item.kshow,
                            },
                          );
                        } else if (item.anime != null) {
                          context.push(
                            '/anime/${item.id}',
                            extra: {
                              'posterUrl': item.posterUrl,
                              'title': item.title,
                            },
                          );
                        }
                      },
                    );
                  },
                  childCount: displayedItems.length,
                ),
              ),
            ),
          ],

          // Infinite Scroll Bottom Loading Spinner for Anime
          if (paginationState.isLoadingMore && _selectedFilter != SearchFilterTab.kdrama)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(height: FloatingNavBar.getBottomPadding(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required SearchFilterTab tab,
    required IconData icon,
    Color? activeColor,
  }) {
    final isSelected = _selectedFilter == tab;
    final tint = activeColor ?? AppColors.accent;

    return PressableScale(
      targetScale: 0.94,
      curve: AppMotion.hyperOsSpring,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = tab);
      },
      child: AnimatedContainer(
        duration: AppMotion.short4,
        curve: AppMotion.hyperOsDecelerate,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? tint.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? tint.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? tint : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified Poster Card with Smooth Staggered Slide+Fade Transition
class _UnifiedPosterCard extends StatelessWidget {
  final UnifiedSearchItem item;
  final int index;
  final VoidCallback onTap;

  const _UnifiedPosterCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  String _formatHeat(int? heat) {
    if (heat == null || heat <= 0) return '';
    if (heat >= 10000) {
      return '${(heat / 1000).toStringAsFixed(1)}k';
    }
    return heat.toString();
  }

  @override
  Widget build(BuildContext context) {
    final heatStr = _formatHeat(item.heat);

    // Stagger animation based on card index
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + math.min(index * 20, 260)),
      curve: AppMotion.hyperOsDecelerate,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 12),
            child: child,
          ),
        );
      },
      child: PressableScale(
        targetScale: 0.94,
        curve: AppMotion.hyperOsSpring,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Frame
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: item.isKShow
                          ? 'kshow_poster_${item.id}'
                          : 'poster_${item.id}',
                      createRectTween: smoothHeroRectTween,
                      flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                      child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.posterUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 360,
                              memCacheHeight: 540,
                              maxWidthDiskCache: 500,
                              maxHeightDiskCache: 750,
                              placeholder: (context, url) => Container(
                                color: AppColors.surface,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surface,
                                child: Icon(
                                  item.isKShow ? Icons.live_tv_rounded : Icons.broken_image_outlined,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: Icon(
                                item.isKShow ? Icons.live_tv_rounded : Icons.movie_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),

                    // Top Gradient Shadow for Badge Legibility
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-Left Category Badge: ANIME vs K-DRAMA
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: item.isKShow
                              ? const Color(0xE67C3AED)
                              : const Color(0xE6101216),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isKShow
                                ? const Color(0xFFA78BFA)
                                : AppColors.accent.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.isKShow) ...[
                              const Icon(
                                Icons.live_tv_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              item.isKShow ? 'K-DRAMA' : 'ANIME',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: item.isKShow ? Colors.white : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Gradient Shadow for Rating / Stats Legibility
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Badges Row (Rating / Episodes / Heat)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: AppColors.ratingStar,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.score!.toStringAsFixed(1),
                                    style: AppText.badgeText.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (item.episodeCount != null && item.episodeCount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.episodeCount} eps',
                                style: AppText.badgeText.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          if (heatStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 12,
                                    color: Color(0xFFFF6D00),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    heatStr,
                                    style: AppText.badgeText.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 7),

            // Title below poster (fixed 36px height container so cards align symmetrically)
            SizedBox(
              height: 36,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardTitle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer Skeleton placeholder card for loading state
class _PosterSkeletonCard extends StatelessWidget {
  const _PosterSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 7),
        ShimmerBox(
          width: 110,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        ShimmerBox(
          width: 70,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
