import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import '../../../../l10n/app_localizations.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_summary.dart';
import 'package:anime_stream/features/metadata/domain/models/search_sort.dart';
import 'package:anime_stream/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:anime_stream/features/stream/domain/models/source_match.dart';
import 'package:anime_stream/features/stream/presentation/providers/stream_providers.dart';
import 'package:anime_stream/features/player/presentation/widgets/embed_stream_dialog.dart';

enum SearchCatalogKind { anime, kshow }

/// Full-screen search screen matching reference Screen 3.
/// Features a dark control panel, tag filters, segmented sort, 2-column poster grid,
/// floating rating & heat badges, infinite scroll, and hero transitions.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  SearchCatalogKind _selectedKind = SearchCatalogKind.anime;
  List<SourceMatch> _kshowResults = [];
  bool _isKShowLoading = false;
  String? _kshowError;
  Timer? _kshowDebounceTimer;
  CancelToken? _kshowCancelToken;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_selectedKind == SearchCatalogKind.anime &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      ref.read(searchPaginationProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _kshowDebounceTimer?.cancel();
    _kshowCancelToken?.cancel('SearchScreen disposed');
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    if (_selectedKind == SearchCatalogKind.anime) {
      ref.read(searchQueryProvider.notifier).state = val;
    } else {
      _kshowDebounceTimer?.cancel();
      _kshowDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _searchKShows(val);
      });
    }
  }

  Future<void> _searchKShows(String query) async {
    _kshowDebounceTimer?.cancel();
    _kshowCancelToken?.cancel('New search initiated');
    final cancelToken = CancelToken();
    _kshowCancelToken = cancelToken;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _kshowResults = [];
        _isKShowLoading = false;
        _kshowError = null;
      });
      return;
    }
    setState(() {
      _isKShowLoading = true;
      _kshowError = null;
    });
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
          _kshowError = 'Failed to load K-Shows';
        });
      }
    }
  }

  void _submitSearch([String? rawQuery]) {
    FocusScope.of(context).unfocus();
    final query = (rawQuery ?? _searchController.text).trim();
    if (_selectedKind == SearchCatalogKind.kshow) {
      _kshowDebounceTimer?.cancel();
      _searchKShows(query);
    } else {
      ref.read(searchQueryProvider.notifier).state = query;
      ref.read(searchPaginationProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currentSort = ref.watch(searchSortProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    final paginationState = ref.watch(searchPaginationProvider);
    final titlePref = ref.watch(titlePreferenceProvider);

    final sortOptions = [
      (SearchSort.match, l10n.filterMatch),
      (SearchSort.heat, l10n.filterPopularity),
      (SearchSort.score, l10n.filterRating),
    ];

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridCrossAxisCount = screenWidth >= 1000
        ? 5
        : (screenWidth >= 700 ? 4 : (screenWidth >= 480 ? 3 : 2));

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
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: IconButton(
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        leadingWidth: AppSpacing.pageMargin + 44,
        centerTitle: true,
        title: Text(
          l10n.searchTitle,
          style: AppText.sectionTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pageMargin),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Stream from Embed URL',
                    padding: EdgeInsets.zero,
                    onPressed: () => EmbedStreamDialog.show(context),
                    icon: const Icon(
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
        physics: AppMotion.m3ScrollPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Big Page Title: "Anime Search" (Bangumi 搜索) & subtitle
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
                    style: AppText.pageTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.searchInstruction,
                    style: AppText.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // Material 3 Dark Control Panel containing input, tags, and segmented sort
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Field + Search Button
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: AppRadius.pillBorder,
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Catalog Kind Dropdown: Anime vs K-Show
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SearchCatalogKind>(
                                  value: _selectedKind,
                                  dropdownColor: theme.colorScheme.surfaceContainerHigh,
                                  icon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 20,
                                  ),
                                  style: AppText.meta.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (val) {
                                    if (val != null && val != _selectedKind) {
                                      setState(() => _selectedKind = val);
                                      _submitSearch();
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: SearchCatalogKind.anime,
                                      child: Text('Anime'),
                                    ),
                                    DropdownMenuItem(
                                      value: SearchCatalogKind.kshow,
                                      child: Text('K-Show'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _searchController,
                                  builder: (context, value, _) {
                                    return TextField(
                                      controller: _searchController,
                                      autofocus: false,
                                      textInputAction: TextInputAction.search,
                                      style: AppText.body,
                                      cursorColor: AppColors.accent,
                                      onSubmitted: (val) => _submitSearch(val),
                                      onChanged: _onQueryChanged,
                                      decoration: InputDecoration(
                                        hintText: _selectedKind == SearchCatalogKind.kshow
                                            ? 'Search kshow…'
                                            : l10n.searchHint,
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
                            ),
                            // Search Button
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilledButton.icon(
                                onPressed: _submitSearch,
                                icon: const Icon(Icons.search_rounded, size: 16),
                                label: Text(l10n.searchAction),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_selectedKind != SearchCatalogKind.kshow) ...[
                        // Tag Filter Row (Material 3 InputChip)
                        if (selectedTags.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
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

                        const SizedBox(height: AppSpacing.md),

                        // Material 3 SegmentedButton (Match | Popularity | Score)
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
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // 2-Column Grid Results, Shimmer Loading, Empty, and Error States
          if (_selectedKind == SearchCatalogKind.kshow) ...[
            if (_isKShowLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _PosterSkeletonCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_kshowError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.accent),
                        const SizedBox(height: AppSpacing.md),
                        Text('Error loading K-Shows', style: AppText.sectionTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => _searchKShows(_searchController.text),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l10n.retry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceHighlight,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_kshowResults.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.live_tv_rounded,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchController.text.trim().isEmpty
                              ? 'Search K-Shows, K-Dramas & Asian Dramas'
                              : 'No K-Shows found',
                          textAlign: TextAlign.center,
                          style: AppText.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = _kshowResults[index];
                      return _KShowPosterCard(
                        match: match,
                        onTap: () {
                          ref.read(metadataRepositoryProvider).recordKShowMatch(match);
                          final thumb = match.customData['thumb'] as String?;
                          context.push(
                            '/anime/${match.id}?isKShow=true',
                            extra: {
                              'posterUrl': thumb,
                              'title': match.title,
                              'isKShow': true,
                              'match': match,
                            },
                          );
                        },
                      );
                    },
                    childCount: _kshowResults.length,
                  ),
                ),
              ),
          ] else ...[
            if (paginationState.isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _PosterSkeletonCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (paginationState.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.accent),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.errorLoading, style: AppText.sectionTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          paginationState.error.toString(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(searchPaginationProvider.notifier).search(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l10n.retry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceHighlight,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (paginationState.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchController.text.trim().isEmpty && selectedTags.isEmpty
                              ? l10n.homeEmptySearchPrompt
                              : 'No anime found',
                          textAlign: TextAlign.center,
                          style: AppText.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 11,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final anime = paginationState.items[index];
                      final title = anime.titles.preferredTitle(titlePref);
                      return _PosterGridCard(
                        anime: anime,
                        title: title,
                        onTap: () => context.push(
                          '/anime/${anime.id}',
                          extra: {'posterUrl': anime.posterUrl, 'title': title},
                        ),
                      );
                    },
                    childCount: paginationState.items.length,
                  ),
                ),
              ),
          ],

          // Infinite Scroll Bottom Loading Spinner
          if (paginationState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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

          SliverToBoxAdapter(child: SizedBox(height: FloatingNavBar.getBottomPadding(context))),
        ],
      ),
    );
  }
}

/// 2-Column Poster Card matching the reference design.
/// Aspect ratio ~2:3 with rounded corners, translucent rating & heat pills over the poster,
/// and title below.
class _PosterGridCard extends StatelessWidget {
  final AnimeSummary anime;
  final String title;
  final VoidCallback onTap;

  const _PosterGridCard({
    required this.anime,
    required this.title,
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
    final heatStr = _formatHeat(anime.heat);

    return PressableScale(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with Hero transition and bottom overlay badges
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster_${anime.id}',
                    createRectTween: smoothHeroRectTween,
                    flightShuttleBuilder: smoothHeroFlightShuttleBuilder,
                    child: anime.posterUrl != null && anime.posterUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: anime.posterUrl!,
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
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),

                  // Bottom Gradient Shade for Badges Readability
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
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Badges Row (Left: Star + Rating, Right: Flame + Heat)
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Star + Score
                        if (anime.score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
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
                                const SizedBox(width: 2.5),
                                Text(
                                  anime.score!.toStringAsFixed(1),
                                  style: AppText.badgeText.copyWith(
                                    fontSize: 10.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // Right: Flame + Heat
                        if (heatStr.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
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

          const SizedBox(height: 6),

          // Title below the poster (aligned container with consistent sizing so card heights don't jitter)
          SizedBox(
            height: 36,
            child: Text(
              title,
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
    );
  }
}

/// Shimmer placeholder card for 2-column grid loading state
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
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        const SizedBox(height: 6),
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

/// 2-Column Poster Card for K-Shows / Dramas from KissKH
class _KShowPosterCard extends StatelessWidget {
  final SourceMatch match;
  final VoidCallback onTap;

  const _KShowPosterCard({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = match.customData['thumb'] as String?;
    final eps = match.episodeCount;

    return PressableScale(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb != null && thumb.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      memCacheWidth: 360,
                      memCacheHeight: 540,
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
                        child: const Icon(Icons.live_tv_rounded, color: AppColors.textMuted),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.live_tv_rounded, color: AppColors.textMuted),
                    ),

                  // Bottom Gradient
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
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Episodes badge
                  if (eps != null && eps > 0)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$eps eps',
                          style: AppText.badgeText.copyWith(fontSize: 10.5, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: Text(
              match.title,
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
    );
  }
}
