import 'dart:async';
import 'package:flutter/material.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Presentation widget rendering high-contrast, beautiful on-screen subtitles and captions.
///
/// Features:
/// - Listens to real-time subtitle cue changes from [VideoPlaybackEngine.subtitleStream].
/// - Dynamic responsive font size based on [SubtitleSettings.fontSize].
/// - Subtle frosted obsidian pill background for legibility over any scene contrast.
/// - Dynamic vertical positioning lifting subtitles above bottom controls when HUD is active.
class PlayerSubtitleOverlay extends StatefulWidget {
  final VideoPlaybackEngine engine;
  final SubtitleSettings settings;
  final bool isHudVisible;

  const PlayerSubtitleOverlay({
    super.key,
    required this.engine,
    required this.settings,
    this.isHudVisible = false,
  });

  @override
  State<PlayerSubtitleOverlay> createState() => _PlayerSubtitleOverlayState();
}

class _PlayerSubtitleOverlayState extends State<PlayerSubtitleOverlay> {
  late List<String> _currentLines;
  StreamSubscription<List<String>>? _subscription;

  @override
  void initState() {
    super.initState();
    _currentLines = widget.engine.currentSubtitle;
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant PlayerSubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      _subscription?.cancel();
      _currentLines = widget.engine.currentSubtitle;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.engine.subtitleStream.listen((lines) {
      if (mounted) {
        setState(() {
          _currentLines = lines;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter out blank or whitespace-only lines
    final activeLines = _currentLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (activeLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayText = activeLines.join('\n');
    final bottomMargin = widget.isHudVisible ? 84.0 : 36.0;

    return IgnorePointer(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 32.0,
          right: 32.0,
          bottom: bottomMargin,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xB8000000), // Semi-transparent obsidian pill
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0x33FFFFFF),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 12.0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.settings.fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.35,
                shadows: const [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
