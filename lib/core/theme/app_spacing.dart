import 'package:flutter/widgets.dart';

/// Standard 4px grid spacing tokens used throughout the app.
abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Layout-specific metrics
  static const double pageMargin = 16.0;
  static const double pageMarginWide = 20.0;
  static const double sectionGap = 24.0;
  static const double elementGapSm = 8.0;
  static const double elementGapMd = 12.0;
  static const double elementGapLg = 16.0;
  static const double cardPadding = 16.0;
  static const double floatingBarBottomPadding = 110.0; // Space for content behind floating bar
  static const double floatingBarMarginHorizontal = 18.0;
  static const double floatingBarMarginBottom = 20.0;
  static const double floatingBarHeight = 66.0;

  // Standard Button & Interactive Sizing
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightSm = 32.0;
  static const double minTouchTarget = 48.0;

  static const double circleButtonLg = 72.0;
  static const double circleButtonMd = 52.0;
  static const double circleButtonSm = 44.0;

  static const EdgeInsets buttonPaddingLg = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const EdgeInsets buttonPaddingMd = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
}
