import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_motion.dart';

/// Reusable tactile bounce/scale micro-interaction widget with Material 3 spring physics.
/// Scales down swiftly on press and springs back with an expressive M3 overshoot on release.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double targetScale;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve curve;
  final Curve pressCurve;
  final HitTestBehavior behavior;
  final bool enableHaptics;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.targetScale = 0.95,
    this.pressDuration = const Duration(milliseconds: 80),
    this.releaseDuration = const Duration(milliseconds: 285),
    this.curve = AppMotion.expressiveFastSpatial,
    this.pressCurve = Curves.easeOutQuad,
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;
  int _lastTapTimestamp = 0;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    if (!kIsWeb && widget.enableHaptics) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTimestamp < 150) return;
    _lastTapTimestamp = now;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null || widget.onLongPress != null;
    if (!isInteractive) return widget.child;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.targetScale : 1.0,
        duration: _isPressed ? widget.pressDuration : widget.releaseDuration,
        curve: _isPressed ? widget.pressCurve : widget.curve,
        child: widget.child,
      ),
    );
  }
}
