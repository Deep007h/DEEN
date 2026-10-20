import 'dart:math' as math;

/// The horizontal zone of the screen where a gesture occurred.
enum HorizontalZone {
  leftThird,
  centerThird,
  rightThird,
}

/// The horizontal half of the screen where a vertical gesture started.
enum ScreenHalf {
  left,
  right,
}

/// Pure Dart utility for gesture zone classification, double-tap accumulation,
/// horizontal scrub calculation, and vertical volume/brightness scaling.
class PlayerGestureMath {
  /// Window of time within which subsequent taps accumulate seeking (e.g. 650ms).
  final Duration accumulationWindow;

  /// Default step size for double tap seeking.
  final Duration seekStep;

  PlayerGestureMath({
    this.accumulationWindow = const Duration(milliseconds: 650),
    this.seekStep = const Duration(seconds: 10),
  });

  /// Classifies a horizontal coordinate into left-third, center-third, or right-third.
  HorizontalZone getHorizontalZone(double localX, double totalWidth) {
    if (totalWidth <= 0) return HorizontalZone.centerThird;
    final normalized = (localX / totalWidth).clamp(0.0, 1.0);
    if (normalized < 1.0 / 3.0) {
      return HorizontalZone.leftThird;
    } else if (normalized > 2.0 / 3.0) {
      return HorizontalZone.rightThird;
    } else {
      return HorizontalZone.centerThird;
    }
  }

  /// Classifies a coordinate into left half or right half (for vertical gestures).
  ScreenHalf getScreenHalf(double localX, double totalWidth) {
    if (totalWidth <= 0) return ScreenHalf.left;
    final normalized = (localX / totalWidth).clamp(0.0, 1.0);
    return normalized < 0.5 ? ScreenHalf.left : ScreenHalf.right;
  }

  /// Calculates new brightness or volume from vertical drag delta.
  /// Dragging up decreases Y, so deltaY < 0 increases value.
  /// [currentValue]: 0.0 to 1.0
  /// [deltaY]: drag displacement in pixels (negative = up)
  /// [totalHeight]: total height of gesture area
  /// [sensitivity]: multiplier (default 1.2 for responsive feel)
  double calculateVerticalDelta({
    required double currentValue,
    required double deltaY,
    required double totalHeight,
    double sensitivity = 1.2,
  }) {
    if (totalHeight <= 0) return currentValue;
    final change = (-deltaY / totalHeight) * sensitivity;
    return (currentValue + change).clamp(0.0, 1.0);
  }

  /// Calculates target position when scrubbing horizontally.
  /// [basePosition]: video position when scrub started.
  /// [totalDuration]: total length of the video.
  /// [deltaX]: horizontal displacement in pixels from scrub start.
  /// [totalWidth]: total width of gesture area.
  /// [scrubSpan]: maximum span of time scrubbed across full screen width (defaults to min(duration, 90s) or scaled).
  Duration calculateScrubTarget({
    required Duration basePosition,
    required Duration totalDuration,
    required double deltaX,
    required double totalWidth,
    Duration? scrubSpan,
  }) {
    if (totalWidth <= 0 || totalDuration <= Duration.zero) {
      return basePosition;
    }

    final effectiveSpan = scrubSpan ??
        Duration(
          seconds: math.max(
            60,
            math.min(totalDuration.inSeconds, 180),
          ),
        );

    final ratio = deltaX / totalWidth;
    final offsetMicroseconds = (ratio * effectiveSpan.inMicroseconds).round();

    final targetMicros = (basePosition.inMicroseconds + offsetMicroseconds)
        .clamp(0, totalDuration.inMicroseconds);

    return Duration(microseconds: targetMicros);
  }
}

/// Accumulator state machine for repeated double-tap / triple-tap seeking.
class DoubleTapAccumulator {
  final Duration accumulationWindow;
  final Duration step;

  HorizontalZone? _lastZone;
  DateTime? _lastTapTime;
  int _accumulatedSeconds = 0;

  DoubleTapAccumulator({
    this.accumulationWindow = const Duration(milliseconds: 650),
    this.step = const Duration(seconds: 10),
  });

  /// Current accumulated seek offset in seconds.
  int get accumulatedSeconds => _accumulatedSeconds;

  /// Active zone being accumulated (null if idle/expired).
  HorizontalZone? get activeZone => _lastZone;

  /// Registers a double-tap in a given zone at a given timestamp.
  /// Returns the newly accumulated seek offset in seconds (negative for left, positive for right, 0 for center).
  int registerTap(HorizontalZone zone, {DateTime? now, int? stepSeconds}) {
    final effectiveStep = stepSeconds ?? step.inSeconds;
    final currentTime = now ?? DateTime.now();

    if (zone == HorizontalZone.centerThird) {
      reset();
      return 0;
    }

    final isWithinWindow = _lastTapTime != null &&
        currentTime.difference(_lastTapTime!) <= accumulationWindow &&
        _lastZone == zone;

    if (isWithinWindow) {
      if (zone == HorizontalZone.leftThird) {
        _accumulatedSeconds -= effectiveStep;
      } else if (zone == HorizontalZone.rightThird) {
        _accumulatedSeconds += effectiveStep;
      }
    } else {
      _lastZone = zone;
      if (zone == HorizontalZone.leftThird) {
        _accumulatedSeconds = -effectiveStep;
      } else {
        _accumulatedSeconds = effectiveStep;
      }
    }

    _lastTapTime = currentTime;
    return _accumulatedSeconds;
  }

  /// Checks if accumulation window has expired based on current time.
  bool isExpired({DateTime? now}) {
    if (_lastTapTime == null) return true;
    final currentTime = now ?? DateTime.now();
    return currentTime.difference(_lastTapTime!) > accumulationWindow;
  }

  /// Resets accumulator to idle state.
  void reset() {
    _lastZone = null;
    _lastTapTime = null;
    _accumulatedSeconds = 0;
  }
}
