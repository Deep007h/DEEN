import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../providers/download_providers.dart';
import '../../data/download_service.dart';

/// Screen representing the 4th tab (Downloads) for managing offline media.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Completed, 2: Queued

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 90;
    final downloadService = ref.watch(downloadServiceProvider);
    final allDownloads = downloadService.downloads;

    final filteredDownloads = allDownloads.where((d) {
      if (_selectedFilter == 1) return d.isCompleted;
      if (_selectedFilter == 2) return !d.isCompleted;
      return true;
    }).toList();

    final usedBytes = downloadService.totalUsedBytes;
    final usedMb = (usedBytes / (1024 * 1024)).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: AppMotion.m3ScrollPhysics,
        slivers: [
          // Header Bar with signature vertical accent
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Downloads',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  // Storage indicator chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141914),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x334E604E), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sd_storage_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          '$usedMb MB Used',
                          style: const TextStyle(
                            color: Color(0xFFC0CCC0),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Storage Bar Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
                vertical: 8,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141914),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x284E604E), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Offline Storage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$usedMb MB used by DEEN',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: const Color(0xFF222B22),
                        child: Row(
                          children: [
                            Container(
                              width: (usedBytes > 0) ? 28 : 10,
                              color: AppColors.accent,
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

          // Filter Pills
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
                vertical: 8,
              ),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All (${allDownloads.length})',
                    isSelected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Completed (${allDownloads.where((d) => d.isCompleted).length})',
                    isSelected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Queued (${allDownloads.where((d) => !d.isCompleted).length})',
                    isSelected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
            ),
          ),

          if (filteredDownloads.isEmpty)
            // Empty State
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding, top: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161E16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.download_done_rounded,
                            size: 42,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Downloads Yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Episodes and movies you download for offline playback will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PressableScale(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go('/explore');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_rounded, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Explore Shows',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
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
            )
          else
            // Downloaded Items List
            SliverPadding(
              padding: EdgeInsets.only(
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                top: 8,
                bottom: bottomPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredDownloads[index];
                    return _DownloadItemCard(
                      item: item,
                      onPlay: () {
                        HapticFeedback.lightImpact();
                        context.push('/player?animeId=${item.animeId}&ep=${item.episodeNumber}');
                      },
                      onDelete: () {
                        HapticFeedback.mediumImpact();
                        downloadService.deleteDownload(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed "${item.title}" from downloads'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        );
                      },
                    );
                  },
                  childCount: filteredDownloads.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadItemCard extends StatelessWidget {
  final DownloadedEpisode item;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _DownloadItemCard({
    required this.item,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141914),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222B22), width: 1.0),
      ),
      child: Row(
        children: [
          // Thumbnail / Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 52,
              color: const Color(0xFF1C251C),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                    Image.network(
                      item.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.movie_rounded, color: AppColors.accent, size: 24),
                      ),
                    )
                  else
                    Center(
                      child: Icon(Icons.movie_rounded, color: AppColors.accent, size: 24),
                    ),
                  if (item.isCompleted)
                    Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Metadata Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.animeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.title} • ${item.formattedSize}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!item.isCompleted) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF243024),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          if (item.isCompleted)
            IconButton(
              icon: Icon(Icons.play_circle_fill_rounded, color: AppColors.accent, size: 28),
              onPressed: onPlay,
              tooltip: 'Play Offline',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF889988), size: 22),
            onPressed: onDelete,
            tooltip: 'Delete Download',
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.short3,
        curve: AppMotion.hyperOsSpring,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : const Color(0xFF141914),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0x334E604E),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFCCD6CC),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
