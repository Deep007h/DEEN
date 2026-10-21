import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/domain/gestures/player_gesture_math.dart';

void main() {
  group('PlayerGestureMath - Zones and Halves', () {
    final math = PlayerGestureMath();

    test('classifies horizontal zones correctly across 900px screen', () {
      expect(math.getHorizontalZone(100, 900), HorizontalZone.leftThird);
      expect(math.getHorizontalZone(299, 900), HorizontalZone.leftThird);

      expect(math.getHorizontalZone(300, 900), HorizontalZone.centerThird);
      expect(math.getHorizontalZone(450, 900), HorizontalZone.centerThird);
      expect(math.getHorizontalZone(600, 900), HorizontalZone.centerThird);

      expect(math.getHorizontalZone(601, 900), HorizontalZone.rightThird);
      expect(math.getHorizontalZone(899, 900), HorizontalZone.rightThird);
    });

    test('handles edge values and zero widths gracefully', () {
      expect(math.getHorizontalZone(0, 0), HorizontalZone.centerThird);
      expect(math.getHorizontalZone(-50, 900), HorizontalZone.leftThird);
      expect(math.getHorizontalZone(1200, 900), HorizontalZone.rightThird);
    });

    test('classifies screen halves for vertical gesture handling', () {
      expect(math.getScreenHalf(200, 1000), ScreenHalf.left);
      expect(math.getScreenHalf(499, 1000), ScreenHalf.left);
      expect(math.getScreenHalf(500, 1000), ScreenHalf.right);
      expect(math.getScreenHalf(800, 1000), ScreenHalf.right);
    });
  });

  group('PlayerGestureMath - Vertical Drag Scaling', () {
    final math = PlayerGestureMath();

    test('dragging up increases brightness/volume, dragging down decreases', () {
      // Dragging up by 100px on 500px height with 1.0 sensitivity -> +0.2
      final increased = math.calculateVerticalDelta(
        currentValue: 0.5,
        deltaY: -100,
        totalHeight: 500,
        sensitivity: 1.0,
      );
      expect(increased, closeTo(0.7, 0.001));

      // Dragging down by 100px on 500px height with 1.0 sensitivity -> -0.2
      final decreased = math.calculateVerticalDelta(
        currentValue: 0.5,
        deltaY: 100,
        totalHeight: 500,
        sensitivity: 1.0,
      );
      expect(decreased, closeTo(0.3, 0.001));
    });

    test('clamps values within [0.0, 1.0]', () {
      final cappedTop = math.calculateVerticalDelta(
        currentValue: 0.9,
        deltaY: -500,
        totalHeight: 500,
      );
      expect(cappedTop, 1.0);

      final cappedBottom = math.calculateVerticalDelta(
        currentValue: 0.1,
        deltaY: 500,
        totalHeight: 500,
      );
      expect(cappedBottom, 0.0);
    });

    test('default sensitivity of 0.6 provides reduced, fine-grained control', () {
      // Dragging up 100px on 500px height with default sensitivity (0.6):
      // change = (100 / 500) * 0.6 = +0.12
      final change = math.calculateVerticalDelta(
        currentValue: 0.5,
        deltaY: -100,
        totalHeight: 500,
      );
      expect(change, closeTo(0.62, 0.001));
    });
  });

  group('PlayerGestureMath - Scrubbing Math', () {
    final math = PlayerGestureMath();

    test('calculates forward and backward scrubbing target correctly', () {
      const basePos = Duration(seconds: 120);
      const totalDur = Duration(minutes: 24); // 1440s
      const span = Duration(seconds: 120);

      // Scrubbing forward 25% of 800px screen (200px)
      final forward = math.calculateScrubTarget(
        basePosition: basePos,
        totalDuration: totalDur,
        deltaX: 200,
        totalWidth: 800,
        scrubSpan: span,
      );
      expect(forward.inSeconds, 150); // 120s + (0.25 * 120s) = 150s

      // Scrubbing backward 25% of 800px screen (-200px)
      final backward = math.calculateScrubTarget(
        basePosition: basePos,
        totalDuration: totalDur,
        deltaX: -200,
        totalWidth: 800,
        scrubSpan: span,
      );
      expect(backward.inSeconds, 90); // 120s - 30s = 90s
    });

    test('clamps scrub targets between zero and total duration', () {
      const basePos = Duration(seconds: 10);
      const totalDur = Duration(seconds: 60);

      final clampedZero = math.calculateScrubTarget(
        basePosition: basePos,
        totalDuration: totalDur,
        deltaX: -500,
        totalWidth: 500,
      );
      expect(clampedZero, Duration.zero);

      final clampedMax = math.calculateScrubTarget(
        basePosition: const Duration(seconds: 55),
        totalDuration: totalDur,
        deltaX: 500,
        totalWidth: 500,
      );
      expect(clampedMax, totalDur);
    });
  });

  group('DoubleTapAccumulator - Accumulation & Timing', () {
    test('accumulates consecutive double taps on right side (+10s, +20s, +30s)', () {
      final accumulator = DoubleTapAccumulator(
        accumulationWindow: const Duration(milliseconds: 650),
        step: const Duration(seconds: 10),
      );

      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      // First double-tap on right side: +10s
      var offset = accumulator.registerTap(HorizontalZone.rightThird, now: t0);
      expect(offset, 10);
      expect(accumulator.accumulatedSeconds, 10);
      expect(accumulator.activeZone, HorizontalZone.rightThird);

      // Second double-tap 200ms later: +20s
      final t1 = t0.add(const Duration(milliseconds: 200));
      offset = accumulator.registerTap(HorizontalZone.rightThird, now: t1);
      expect(offset, 20);
      expect(accumulator.accumulatedSeconds, 20);

      // Third double-tap 300ms later: +30s
      final t2 = t1.add(const Duration(milliseconds: 300));
      offset = accumulator.registerTap(HorizontalZone.rightThird, now: t2);
      expect(offset, 30);
      expect(accumulator.accumulatedSeconds, 30);
    });

    test('accumulates consecutive double taps on left side (-10s, -20s, -30s)', () {
      final accumulator = DoubleTapAccumulator();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      var offset = accumulator.registerTap(HorizontalZone.leftThird, now: t0);
      expect(offset, -10);

      final t1 = t0.add(const Duration(milliseconds: 200));
      offset = accumulator.registerTap(HorizontalZone.leftThird, now: t1);
      expect(offset, -20);
    });

    test('resets accumulation after window expires', () {
      final accumulator = DoubleTapAccumulator(
        accumulationWindow: const Duration(milliseconds: 650),
      );
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      accumulator.registerTap(HorizontalZone.rightThird, now: t0);
      expect(accumulator.accumulatedSeconds, 10);

      // Tap 800ms later (exceeding 650ms window) resets back to single step
      final tExpired = t0.add(const Duration(milliseconds: 800));
      expect(accumulator.isExpired(now: tExpired), isTrue);

      final offset = accumulator.registerTap(HorizontalZone.rightThird, now: tExpired);
      expect(offset, 10); // reset to initial step
    });

    test('switching sides immediately switches direction and resets accumulation', () {
      final accumulator = DoubleTapAccumulator();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      accumulator.registerTap(HorizontalZone.rightThird, now: t0);
      expect(accumulator.accumulatedSeconds, 10);

      // Immediately tap left side
      final t1 = t0.add(const Duration(milliseconds: 100));
      final offset = accumulator.registerTap(HorizontalZone.leftThird, now: t1);
      expect(offset, -10);
      expect(accumulator.activeZone, HorizontalZone.leftThird);
    });

    test('center tap resets accumulator and returns 0', () {
      final accumulator = DoubleTapAccumulator();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      accumulator.registerTap(HorizontalZone.rightThird, now: t0);
      expect(accumulator.accumulatedSeconds, 10);

      final offset = accumulator.registerTap(HorizontalZone.centerThird, now: t0);
      expect(offset, 0);
      expect(accumulator.accumulatedSeconds, 0);
      expect(accumulator.activeZone, isNull);
    });
  });
}
