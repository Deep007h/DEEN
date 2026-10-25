import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standard typography styles for the iOS dark anime streaming theme.
abstract final class AppText {
  // Page Title (large header like "主页" / "Bangumi 搜索")
  static const TextStyle pageTitle = TextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Section Headers (e.g. "热门番组 ∨", "标签")
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 19.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // Anime Card Titles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Subtitle / Body text
  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Meta information / Badges (ratings, dates, rank)
  static const TextStyle meta = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  // Navigation tab labels
  static TextStyle get navActive => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    letterSpacing: -0.1,
  );

  static const TextStyle navInactive = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: -0.1,
  );

  // Action buttons (Play, Follow, Search)
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Color(0xFF0B0E0B), // Pitch black on CTA
  );

  // Studio Monospace & Telemetry Badges
  static TextStyle get techBadge => TextStyle(
    fontFamily: 'monospace',
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.accent,
  );

  static const TextStyle telemetryCode = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // Material 3 Canonical Type Scale
  static const TextStyle displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: AppColors.textPrimary);
  static const TextStyle displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.16, color: AppColors.textPrimary);
  static const TextStyle displaySmall = TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.22, color: AppColors.textPrimary);

  static const TextStyle headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.25, color: AppColors.textPrimary);
  static const TextStyle headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25, height: 1.29, color: AppColors.textPrimary);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.33, color: AppColors.textPrimary);

  static const TextStyle titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.27, color: AppColors.textPrimary);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.50, color: AppColors.textPrimary);
  static const TextStyle titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimary);

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.50, color: AppColors.textPrimary);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: AppColors.textPrimary);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: AppColors.textSecondary);

  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimary);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.33, color: AppColors.textSecondary);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.45, color: AppColors.textSecondary);

  static TextTheme get m3TextTheme => const TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
