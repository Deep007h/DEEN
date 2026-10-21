import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_colors.dart';

/// Centralized, synchronized ticker for all shimmer skeletons across the application.
/// Uses a single scheduler frame callback regardless of how many shimmer skeletons
/// are currently mounted, eliminating CPU contention and visual phase drift.
class _SharedShimmerController {
  static Ticker? _ticker;
  static final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  static int _activeCount = 0;
  static const int _periodMs = 1400;

  static void register() {
    _activeCount++;
    if (_ticker == null) {
      _ticker = Ticker((Duration elapsed) {
        final totalMs = elapsed.inMilliseconds;
        final fraction = (totalMs % _periodMs) / _periodMs;
        progress.value = fraction;
      });
      _ticker!.start();
    }
  }

  static void unregister() {
    _activeCount--;
    if (_activeCount <= 0) {
      _activeCount = 0;
      _ticker?.stop();
      _ticker?.dispose();
      _ticker = null;
      progress.value = 0.0;
    }
  }
}

/// Dark-themed Material 3 shimmer animation widget used for loading skeletons.
/// All instances across the application share a single synchronized ticker.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> {
  @override
  void initState() {
    super.initState();
    _SharedShimmerController.register();
  }

  @override
  void dispose() {
    _SharedShimmerController.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderRadius ?? BorderRadius.circular(8);

    return ValueListenableBuilder<double>(
      valueListenable: _SharedShimmerController.progress,
      builder: (context, value, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: border,
            gradient: LinearGradient(
              begin: Alignment(-2.5 + 5.0 * value, -0.3),
              end: Alignment(-0.5 + 5.0 * value, 0.3),
              stops: const [0.0, 0.5, 1.0],
              colors: const [
                AppColors.surfaceContainerLow,
                AppColors.surfaceHighlight,
                AppColors.surfaceContainerLow,
              ],
            ),
          ),
        );
      },
    );
  }
}
