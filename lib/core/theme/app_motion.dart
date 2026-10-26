import 'package:flutter/material.dart';

/// Material 3 Motion & Physics tokens aligned with m3.material.io/styles/motion.
abstract final class AppMotion {
  // 1. Material 3 Emphasized Easing Curves
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  // 2. Material 3 Standard Easing Curves
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  // 3. Material 3 Expressive Spring-to-Curve Conversions
  static const Curve expressiveFastSpatial = Cubic(0.42, 1.67, 0.21, 0.90);
  static const Curve expressiveDefaultSpatial = Cubic(0.38, 1.21, 0.22, 1.00);
  static const Curve expressiveSlowSpatial = Cubic(0.39, 1.29, 0.35, 0.98);
  static const Curve expressiveFastEffects = Cubic(0.31, 0.94, 0.34, 1.00);
  static const Curve expressiveDefaultEffects = Cubic(0.34, 0.80, 0.34, 1.00);

  // 3b. HyperOS 4 Alive Motion Physics Curves
  /// Elastic spring overshoot for tactile tap release, micro-interactions, and card bounces.
  static const Curve hyperOsSpring = Cubic(0.34, 1.45, 0.64, 1.0);
  /// Ultra-smooth natural deceleration for fluid route entries, sheets, and dialogs.
  static const Curve hyperOsDecelerate = Cubic(0.14, 1.0, 0.28, 1.0);
  /// Clean accelerated exit for dismissals and pop operations.
  static const Curve hyperOsAccelerate = Cubic(0.4, 0.0, 0.8, 0.2);
  /// Responsive snappy curve for quick toggle switches and state badges.
  static const Curve hyperOsSnappy = Cubic(0.2, 0.9, 0.2, 1.0);
  /// Fluid organic curve for carousel paging and hero transitions.
  static const Curve hyperOsFluid = Cubic(0.25, 0.1, 0.25, 1.0);

  // 4. Material 3 Duration Tokens (Scaled by 1.3x for smoother, relaxed UI animations)
  static const Duration short1 = Duration(milliseconds: 65);
  static const Duration short2 = Duration(milliseconds: 130);
  static const Duration short3 = Duration(milliseconds: 195);
  static const Duration short4 = Duration(milliseconds: 260);

  static const Duration medium1 = Duration(milliseconds: 325);
  static const Duration medium2 = Duration(milliseconds: 390);
  static const Duration medium3 = Duration(milliseconds: 455);
  static const Duration medium4 = Duration(milliseconds: 520);

  static const Duration long1 = Duration(milliseconds: 585);
  static const Duration long2 = Duration(milliseconds: 650);
  static const Duration long3 = Duration(milliseconds: 715);
  static const Duration long4 = Duration(milliseconds: 780);

  static const Duration extraLong1 = Duration(milliseconds: 910);
  static const Duration extraLong2 = Duration(milliseconds: 1040);
  static const Duration extraLong3 = Duration(milliseconds: 1170);
  static const Duration extraLong4 = Duration(milliseconds: 1300);

  // 5. Material 3 Scroll Physics (Expressive stretching/bouncing overscroll)
  static const ScrollPhysics m3ScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  // 6. Dedicated Overlay & HUD Transitions
  static const Duration overlayEnter = Duration(milliseconds: 240);
  static const Duration overlayExit = Duration(milliseconds: 180);
  static const Curve overlayEnterCurve = hyperOsDecelerate;
  static const Curve overlayExitCurve = hyperOsAccelerate;
}
