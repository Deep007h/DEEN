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

  // 4. Material 3 Duration Tokens
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);

  // 5. Material 3 Scroll Physics (Stretching overscroll on Android 12+, clamping base)
  static const ScrollPhysics m3ScrollPhysics = ClampingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
}
