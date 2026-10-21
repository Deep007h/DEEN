import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';

/// Center controls overlay with 5-button layout:
/// - Frosted circular Previous Episode button (far left)
/// - Frosted circular Replay-10s button (inner left)
/// - Large frosted circular Play/Pause button with white border (center)
/// - Frosted circular Forward-10s button (inner right)
/// - Frosted circular Next Episode button (far right)
/// - Central buffering spinner
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
    if (isBuffering) {
      return Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0x5A000000),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x40FFFFFF),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(22.0),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC6F16D)),
            ),
          ),
        ),
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(width: 22),

              // 2. Replay 10s frosted circle
              _SeekCircleButton(
                icon: Icons.replay_10_rounded,
                onPressed: onReplay10,
                tooltip: 'Replay 10 seconds',
              ),
              const SizedBox(width: 28),

              // 3. Big translucent play/pause button with white border
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTogglePlay,
                  borderRadius: BorderRadius.circular(39),
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0x5A000000),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x59FFFFFF),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),

              // 4. Forward 10s frosted circle
              _SeekCircleButton(
                icon: Icons.forward_10_rounded,
                onPressed: onForward10,
                tooltip: 'Forward 10 seconds',
              ),
              const SizedBox(width: 22),

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Tooltip(
          message: tooltip,
          child: AnimatedOpacity(
            duration: AppMotion.short4,
            opacity: enabled ? 1.0 : 0.35,
            child: Container(
              width: 50,
              height: 50,
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
                  size: 28,
                  color: enabled ? Colors.white : const Color(0x88FFFFFF),
                ),
              ),
            ),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(27),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 54,
            height: 54,
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
                size: 29,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
