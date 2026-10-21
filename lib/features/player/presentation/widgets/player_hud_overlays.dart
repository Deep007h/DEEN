import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';

/// Top-center speed pill indicator shown during temporary hold gesture (e.g. "1.5X Speed ▶▶").
class HoldSpeedPill extends StatelessWidget {
  final double speed;

  const HoldSpeedPill({
    super.key,
    this.speed = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final speedText = speed == speed.roundToDouble()
        ? '${speed.toInt()}X Speed'
        : '${speed.toStringAsFixed(1)}X Speed';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: ((scale - 0.8) / 0.2).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE618181B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x33FFFFFF),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  speedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical pill slider HUD for Brightness (left) or Volume (right).
class VerticalSliderHud extends StatelessWidget {
  final bool isVolume; // true = volume, false = brightness
  final double value; // 0.0 to 1.0

  const VerticalSliderHud({
    super.key,
    required this.isVolume,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percentage = (clamped * 100).round();

    IconData icon;
    if (isVolume) {
      if (clamped <= 0.0) {
        icon = Icons.volume_off_rounded;
      } else if (clamped < 0.5) {
        icon = Icons.volume_down_rounded;
      } else {
        icon = Icons.volume_up_rounded;
      }
    } else {
      if (clamped < 0.4) {
        icon = Icons.brightness_low_rounded;
      } else if (clamped < 0.7) {
        icon = Icons.brightness_medium_rounded;
      } else {
        icon = Icons.brightness_high_rounded;
      }
    }

    return Align(
      alignment: isVolume ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 10),
            // Vertical bar
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: clamped,
                    child: Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: isVolume ? AppColors.accent : Colors.amberAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$percentage%',
              style: AppText.meta.copyWith(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Double-tap seeking badge that ripples on left or right third.
class DoubleTapSeekBadge extends StatelessWidget {
  final int offsetSeconds; // negative for rewind, positive for forward

  const DoubleTapSeekBadge({
    super.key,
    required this.offsetSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final isRewind = offsetSeconds < 0;
    final absSeconds = offsetSeconds.abs();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.75, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: ((scale - 0.75) / 0.25).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isRewind ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(
            left: isRewind ? 48 : 0,
            right: isRewind ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRewind) ...[
                const Icon(Icons.fast_rewind_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                '${isRewind ? '-' : '+'}${absSeconds}s',
                style: AppText.sectionTitle.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isRewind) ...[
                const SizedBox(width: 6),
                const Icon(Icons.fast_forward_rounded, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrub preview HUD showing live target position.
class ScrubPreviewHud extends StatelessWidget {
  final Duration targetPosition;
  final Duration totalDuration;
  final Duration delta;

  const ScrubPreviewHud({
    super.key,
    required this.targetPosition,
    required this.totalDuration,
    required this.delta,
  });

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final deltaSeconds = delta.inSeconds;
    final isForward = deltaSeconds >= 0;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: AppRadius.cardBorder,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_format(targetPosition)} / ${_format(totalDuration)}',
              style: AppText.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForward ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 13,
                  color: isForward ? AppColors.accent : Colors.amberAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isForward ? '+' : ''}${deltaSeconds}s',
                  style: AppText.meta.copyWith(
                    color: isForward ? AppColors.accent : Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
