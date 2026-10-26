import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';

/// Center controls overlay with 5-button layout:
/// - Frosted circular Previous Episode button (far left, 44x44)
/// - Frosted circular Replay-10s button (inner left, 52x52)
/// - Large frosted circular Play/Pause button with white border (center, 72x72)
/// - Frosted circular Forward-10s button (inner right, 52x52)
/// - Frosted circular Next Episode button (far right, 44x44)
/// - Persistent 20px spacing with tactile spring physics on all controls
class PlayerCenterControls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTogglePlay;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;
  final bool hasPreviousEpisode;
  final bool hasNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;

  const PlayerCenterControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onTogglePlay,
    required this.onReplay10,
    required this.onForward10,
    this.hasPreviousEpisode = false,
    this.hasNextEpisode = false,
    this.onPreviousEpisode,
    this.onNextEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Previous Episode Button
              _EpisodeCircleButton(
                icon: Icons.skip_previous_rounded,
                onPressed: hasPreviousEpisode ? onPreviousEpisode : null,
                tooltip: 'Previous Episode',
                enabled: hasPreviousEpisode,
              ),
              const SizedBox(width: AppSpacing.xl),

              // 2. Replay 10s frosted circle
              _SeekCircleButton(
                icon: Icons.replay_10_rounded,
                onPressed: onReplay10,
                tooltip: 'Replay 10 seconds',
              ),
              const SizedBox(width: AppSpacing.xl),

              // 3. Central Play/Pause button with white border (or 72x72 placeholder during buffering)
              isBuffering
                  ? const SizedBox(
                      width: AppSpacing.circleButtonLg,
                      height: AppSpacing.circleButtonLg,
                    )
                  : PressableScale(
                      targetScale: 0.92,
                      curve: AppMotion.hyperOsSpring,
                      onTap: onTogglePlay,
                      child: Container(
                        width: AppSpacing.circleButtonLg,
                        height: AppSpacing.circleButtonLg,
                        decoration: BoxDecoration(
                          color: const Color(0x66000000),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x66FFFFFF),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D000000),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: AppMotion.short3,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.82, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: AppMotion.hyperOsSpring,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey<bool>(isPlaying),
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(width: AppSpacing.xl),

              // 4. Forward 10s frosted circle
              _SeekCircleButton(
                icon: Icons.forward_10_rounded,
                onPressed: onForward10,
                tooltip: 'Forward 10 seconds',
              ),
              const SizedBox(width: AppSpacing.xl),

              // 5. Next Episode Button
              _EpisodeCircleButton(
                icon: Icons.skip_next_rounded,
                onPressed: hasNextEpisode ? onNextEpisode : null,
                tooltip: 'Next Episode',
                enabled: hasNextEpisode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool enabled;

  const _EpisodeCircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final button = Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: AppMotion.short4,
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: AppSpacing.circleButtonSm,
          height: AppSpacing.circleButtonSm,
          decoration: BoxDecoration(
            color: enabled ? const Color(0x52000000) : const Color(0x22000000),
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? const Color(0x40FFFFFF) : const Color(0x1FFFFFFF),
              width: 1.0,
            ),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: enabled ? Colors.white : const Color(0x88FFFFFF),
            ),
          ),
        ),
      ),
    );

    if (!enabled || onPressed == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Center(child: button),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: Center(
        child: PressableScale(
          targetScale: 0.90,
          curve: AppMotion.hyperOsSpring,
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }
}

class _SeekCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _SeekCircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: Center(
        child: PressableScale(
          targetScale: 0.91,
          curve: AppMotion.hyperOsSpring,
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: AppSpacing.circleButtonMd,
              height: AppSpacing.circleButtonMd,
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x3DFFFFFF),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
