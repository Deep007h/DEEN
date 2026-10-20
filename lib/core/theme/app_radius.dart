import 'package:flutter/material.dart';

/// Corner radius tokens matching the reference UI design.
abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  // Material 3 Shape Scale
  static const double m3None = 0.0;
  static const double m3ExtraSmall = 4.0;
  static const double m3Small = 8.0;
  static const double m3Medium = 12.0;
  static const double m3Large = 16.0;
  static const double m3LargeIncreased = 20.0;
  static const double m3ExtraLarge = 28.0;
  static const double m3Full = 999.0;

  // Specific component radii (M3-aligned)
  static const double card = 16.0;      // M3 Large shape
  static const double poster = 12.0;    // M3 Medium shape
  static const double modal = 28.0;     // M3 Extra-Large shape
  static const double pill = 999.0;     // M3 Full shape
  static const double floatingBar = 34.0;

  // BorderRadius helpers
  static final BorderRadius cardBorder = BorderRadius.circular(card);
  static final BorderRadius posterBorder = BorderRadius.circular(poster);
  static final BorderRadius modalBorder = BorderRadius.circular(modal);
  static final BorderRadius pillBorder = BorderRadius.circular(pill);
  static final BorderRadius floatingBarBorder = BorderRadius.circular(floatingBar);
  static final BorderRadius smBorder = BorderRadius.circular(sm);
  static final BorderRadius mdBorder = BorderRadius.circular(md);
  static final BorderRadius lgBorder = BorderRadius.circular(lg);
  static final BorderRadius xlBorder = BorderRadius.circular(xl);
  static final BorderRadius m3ExtraLargeBorder = BorderRadius.circular(m3ExtraLarge);
}
