import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';

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

    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      child: Container(
        width: 320,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.border, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 24,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          left: false,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: 8,
                top: 8,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Episodes ($count)',
                    style: AppText.sectionTitle.copyWith(fontSize: 15),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
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
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
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
      ),
    ),
  );
}
}
