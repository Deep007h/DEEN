import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Episode selection side sheet for jumping between episodes in the player.
class EpisodeSelectorSheet extends StatelessWidget {
  final int totalEpisodes;
  final int currentEpisode;
  final ValueChanged<int> onSelectEpisode;
  final VoidCallback onClose;

  const EpisodeSelectorSheet({
    super.key,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.onSelectEpisode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final count = totalEpisodes > 0 ? totalEpisodes : 24;

    return Container(
      width: 370,
      margin: const EdgeInsets.fromLTRB(6, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F140F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF242E24),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Episodes ($count)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
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
          const Divider(color: Color(0xFF202A20), height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: count,
                itemBuilder: (context, index) {
                  final ep = index + 1;
                  final isCurrent = ep == currentEpisode;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelectEpisode(ep),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.accent : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? AppColors.accent : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$ep',
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFF0F150D) : AppColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }
}
