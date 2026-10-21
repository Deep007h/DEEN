import 'package:flutter/material.dart';

/// Bottom controls bar matching reference image 1:1:
/// - Single horizontal row
/// - Elapsed timestamp (e.g. 07:49)
/// - Continuous vibrant red seek bar with buffered extent & white circular thumb
/// - Total duration timestamp (e.g. 23:40)
/// - Frosted circular Episodes button (rectangle with 2 lines)
/// - Frosted circular Settings gear button
/// - Frosted circular Fullscreen expand button
class PlayerBottomBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekStart;
  final ValueChanged<Duration> onSeekEnd;
  final VoidCallback onOpenEpisodes;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleFullscreen;
  final bool hasPreviousEpisode;
  final bool hasNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onCast;
  final VoidCallback? onPip;
  final VoidCallback? onLock;
  final bool isSettingsOpen;

  const PlayerBottomBar({
    super.key,
    required this.position,
    required this.duration,
    required this.buffer,
    required this.onSeek,
    required this.onSeekStart,
    required this.onSeekEnd,
    required this.onOpenEpisodes,
    required this.onOpenSettings,
    required this.onToggleFullscreen,
    this.hasPreviousEpisode = false,
    this.hasNextEpisode = false,
    this.onPreviousEpisode,
    this.onNextEpisode,
    this.onCast,
    this.onPip,
    this.onLock,
    this.isSettingsOpen = false,
  });

  @override
  State<PlayerBottomBar> createState() => _PlayerBottomBarState();
}

class _PlayerBottomBarState extends State<PlayerBottomBar> {
  bool _isDragging = false;
  double _dragPositionFraction = 0.0;

  String _formatDuration(Duration duration) {
    if (duration < Duration.zero) duration = Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMillis = widget.duration.inMilliseconds;
    final currentMillis = _isDragging
        ? (_dragPositionFraction * totalMillis).round()
        : widget.position.inMilliseconds.clamp(0, totalMillis > 0 ? totalMillis : 0);

    final displayPosition = Duration(milliseconds: currentMillis);
    final bufferMillis = widget.buffer.inMilliseconds.clamp(0, totalMillis > 0 ? totalMillis : 0);

    final progressRatio = totalMillis > 0 ? (currentMillis / totalMillis).clamp(0.0, 1.0) : 0.0;
    final bufferRatio = totalMillis > 0 ? (bufferMillis / totalMillis).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xCC000000),
            Color(0x66000000),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Elapsed time (e.g. 07:49)
            Text(
              _formatDuration(displayPosition),
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFC6F16D),
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 14),

            // Continuous interactive progress bar
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      if (totalMillis <= 0 || barWidth <= 0) return;
                      setState(() {
                        _isDragging = true;
                        _dragPositionFraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                      });
                      final target = Duration(
                        milliseconds: (_dragPositionFraction * totalMillis).round(),
                      );
                      widget.onSeekStart(target);
                    },
                    onHorizontalDragUpdate: (details) {
                      if (totalMillis <= 0 || barWidth <= 0) return;
                      setState(() {
                        _dragPositionFraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                      });
                      final target = Duration(
                        milliseconds: (_dragPositionFraction * totalMillis).round(),
                      );
                      widget.onSeek(target);
                    },
                    onHorizontalDragEnd: (_) {
                      if (totalMillis <= 0) {
                        setState(() => _isDragging = false);
                        return;
                      }
                      final target = Duration(
                        milliseconds: (_dragPositionFraction * totalMillis).round(),
                      );
                      setState(() {
                        _isDragging = false;
                      });
                      widget.onSeekEnd(target);
                    },
                    onTapDown: (details) {
                      if (totalMillis <= 0 || barWidth <= 0) return;
                      final fraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                      final target = Duration(
                        milliseconds: (fraction * totalMillis).round(),
                      );
                      widget.onSeekStart(target);
                      widget.onSeek(target);
                      widget.onSeekEnd(target);
                    },
                    child: Container(
                      height: 36, // Large touch hit target
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background rail
                          Container(
                            height: 3.5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E261E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Buffered rail
                          FractionallySizedBox(
                            widthFactor: bufferRatio,
                            child: Container(
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: const Color(0x40C6F16D),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Active electric lime progress rail
                          FractionallySizedBox(
                            widthFactor: progressRatio,
                            child: Container(
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC6F16D),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66C6F16D),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Electric lime circular scrubber thumb
                          Positioned(
                            left: barWidth > 12.0
                                ? (progressRatio * barWidth - 6.0).clamp(0.0, barWidth - 12.0)
                                : 0.0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC6F16D),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x80C6F16D),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // Total duration (e.g. 23:40)
            Text(
              _formatDuration(widget.duration),
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF8E9E8E),
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 16),

            // PiP button if available
            if (widget.onPip != null) ...[
              _FrostedBarButton(
                icon: Icons.picture_in_picture_alt_rounded,
                size: 19,
                onPressed: widget.onPip!,
                tooltip: 'Picture in Picture',
              ),
              const SizedBox(width: 8),
            ],

            // Episodes button (matching rectangle with 2 bars)
            _FrostedBarButton(
              icon: Icons.subtitles_outlined,
              size: 19,
              onPressed: widget.onOpenEpisodes,
              tooltip: 'Episodes',
            ),
            const SizedBox(width: 8),

            // Lock button if present
            if (widget.onLock != null) ...[
              _FrostedBarButton(
                icon: Icons.lock_outline_rounded,
                size: 19,
                onPressed: widget.onLock!,
                tooltip: 'Lock Screen',
              ),
              const SizedBox(width: 8),
            ],

            // Settings gear button (active state when settings sheet open)
            _FrostedBarButton(
              icon: Icons.settings_rounded,
              size: 19,
              onPressed: widget.onOpenSettings,
              tooltip: 'Playback Settings',
              isActive: widget.isSettingsOpen,
            ),
            const SizedBox(width: 8),

            // Fullscreen / Aspect Ratio button
            _FrostedBarButton(
              icon: Icons.fullscreen_rounded,
              size: 21,
              onPressed: widget.onToggleFullscreen,
              tooltip: 'Fullscreen',
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedBarButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;

  const _FrostedBarButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1E2D1A) : const Color(0xEE141914),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFFC6F16D) : const Color(0xFF263526),
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive ? const Color(0x33C6F16D) : const Color(0x66000000),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: size,
                color: isActive ? const Color(0xFFC6F16D) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
