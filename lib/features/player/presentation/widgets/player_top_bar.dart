import 'package:flutter/material.dart';

/// Top bar overlay for the video player:
/// - Frosted circular back button on left
/// - Title and episode subtitle
/// - [ 🎵 DUB ] frosted pill button
/// - Frosted circular buttons: Danmaku/Comments, Cast, More (⋮)
class PlayerTopBar extends StatelessWidget {
  final String title;
  final String episodeSubtitle;
  final VoidCallback onBack;
  final bool danmakuEnabled;
  final VoidCallback onToggleDanmaku;
  final VoidCallback? onOpenEpisodes;
  final VoidCallback? onCast;
  final VoidCallback? onOpenMore;
  final VoidCallback? onOpenDiagnostics;
  final VoidCallback? onSwitchToEmbed;
  final VoidCallback? onCopyEmbedUrl;
  final String? audioLabel;
  final VoidCallback? onToggleAudio;
  final VoidCallback? onLock;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.episodeSubtitle,
    required this.onBack,
    this.danmakuEnabled = true,
    required this.onToggleDanmaku,
    this.onOpenEpisodes,
    this.onCast,
    this.onOpenMore,
    this.onOpenDiagnostics,
    this.onSwitchToEmbed,
    this.onCopyEmbedUrl,
    this.audioLabel,
    this.onToggleAudio,
    this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Color(0x66000000),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Frosted squircle back button
            _FrostedCircleButton(
              icon: Icons.chevron_left_rounded,
              size: 24,
              buttonSize: 38,
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: 14),

            // Anime Title, Episode subtitle, and Stream Telemetry Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141914),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF263526), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF22C55E), size: 5.5),
                            SizedBox(width: 4),
                            Text(
                              'HLS • 1080P',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8E9E8E),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episodeSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF8E9E8E),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // [ 🎵 DUB ] Studio Audio Pill Toggle Button
            if (audioLabel != null && onToggleAudio != null) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleAudio,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xEE141914),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF263526),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFFC6F16D),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          audioLabel!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Comments / Danmaku toggle button
            _FrostedCircleButton(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: danmakuEnabled ? Colors.white : Colors.white38,
              size: 18,
              buttonSize: 40,
              onPressed: onToggleDanmaku,
              tooltip: danmakuEnabled ? 'Disable Comments' : 'Enable Comments',
            ),
            const SizedBox(width: 12),

            // Cast button
            if (onCast != null) ...[
              _FrostedCircleButton(
                icon: Icons.cast_rounded,
                size: 18,
                buttonSize: 40,
                onPressed: onCast!,
                tooltip: 'Cast',
              ),
              const SizedBox(width: 12),
            ],

            // Lock Screen button
            if (onLock != null) ...[
              _FrostedCircleButton(
                icon: Icons.lock_outline_rounded,
                size: 18,
                buttonSize: 40,
                onPressed: onLock!,
                tooltip: 'Lock Screen',
              ),
              const SizedBox(width: 12),
            ],

            // More / Overflow options button (⋮)
            if (onOpenMore != null)
              _FrostedCircleButton(
                icon: Icons.more_vert_rounded,
                size: 20,
                buttonSize: 40,
                onPressed: onOpenMore!,
                tooltip: 'More Options',
              )
            else if (onOpenEpisodes != null)
              _FrostedCircleButton(
                icon: Icons.subtitles_outlined,
                size: 20,
                buttonSize: 40,
                onPressed: onOpenEpisodes!,
                tooltip: 'Episodes',
              ),
          ],
        ),
      ),
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double buttonSize;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color iconColor;

  const _FrostedCircleButton({
    required this.icon,
    this.size = 18,
    this.buttonSize = 40,
    required this.onPressed,
    this.tooltip,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xEE141914),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF263526),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: size,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
