import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Landscape and portrait side sheet displaying the anime's full synopsis,
/// title variants, score, release year, genres, and metadata.
/// Shares the exact squircle geometry, typography, and dark palette as [PlayerSettingsSheet].
class PlayerDescriptionSheet extends StatelessWidget {
  final String title;
  final String? originalTitle;
  final String? summary;
  final double? score;
  final int? year;
  final int? episodes;
  final String? format;
  final String? status;
  final List<String> tags;
  final VoidCallback onClose;

  const PlayerDescriptionSheet({
    super.key,
    required this.title,
    this.originalTitle,
    this.summary,
    this.score,
    this.year,
    this.episodes,
    this.format,
    this.status,
    this.tags = const [],
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header matching PlayerSettingsSheet & PlayerMoreOptionsSheet
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accent,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Anime Synopsis & Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E281E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2E3D2E),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFFC0D0C0),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1C251C)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (originalTitle != null && originalTitle!.isNotEmpty && originalTitle != title) ...[
                    const SizedBox(height: 3),
                    Text(
                      originalTitle!,
                      style: const TextStyle(
                        color: Color(0xFF8E9E8E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Metadata Badges Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (score != null && score! > 0)
                        _buildBadge(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.ratingStar,
                          text: score!.toStringAsFixed(1),
                          textColor: Colors.white,
                        ),
                      if (year != null)
                        _buildBadge(
                          text: year.toString(),
                        ),
                      if (format != null && format!.isNotEmpty)
                        _buildBadge(
                          text: format!.toUpperCase(),
                        ),
                      if (episodes != null && episodes! > 0)
                        _buildBadge(
                          text: '$episodes Episodes',
                        ),
                      if (status != null && status!.isNotEmpty)
                        _buildBadge(
                          text: status!,
                          textColor: AppColors.accent,
                        ),
                    ],
                  ),

                  // Tags / Genres
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: tags.map((t) => _buildGenrePill(t)).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Signature | Lime vertical accent for Synopsis Header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3.5,
                        height: 15,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Synopsis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Full Description / Summary text
                  Text(
                    (summary != null && summary!.trim().isNotEmpty)
                        ? summary!.trim()
                        : 'No synopsis available for this title.',
                    style: const TextStyle(
                      color: Color(0xFFB6C4B6),
                      fontSize: 13.0,
                      height: 1.55,
                      letterSpacing: 0.15,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    IconData? icon,
    Color? iconColor,
    required String text,
    Color textColor = const Color(0xFFD0DCD0),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? AppColors.accent, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenrePill(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A221A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2B3A2B), width: 0.8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFA2B6A2),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
