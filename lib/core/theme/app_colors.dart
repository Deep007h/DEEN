import 'package:flutter/material.dart';

/// Design tokens for colors across the application.
/// Matches the obsidian-carbon foundation and electric lime studio aesthetic.
abstract final class AppColors {
  // Canvas / Backgrounds
  static const Color background = Color(0xFF0B0E0B); // Obsidian carbon foundation
  static const Color surface = Color(0xFF141914); // Studio card surface
  static const Color surfaceElevated = Color(0xFF181E18); // Elevated modals/menus
  static const Color surfaceHighlight = Color(0xFF222B22); // Subtle highlights
  static const Color surfaceSecondary = Color(0xFF121612); // Secondary dark surface
  static const Color surfaceDim = Color(0xFF0A0D0A);
  static const Color surfaceBright = Color(0xFF242E24);

  // Material 3 Surface Containers (Elevation Hierarchy)
  static const Color surfaceContainerLowest = Color(0xFF0C0F0C); // Level 0: Deepest canvas
  static const Color surfaceContainerLow = Color(0xFF131813);    // Level 1: Elevated cards & list items
  static const Color surfaceContainer = Color(0xFF181E18);       // Level 2: NavigationBar, app bars
  static const Color surfaceContainerHigh = Color(0xFF1F261F);   // Level 3: Dialogs, bottom sheets
  static const Color surfaceContainerHighest = Color(0xFF263026);// Level 4/5: Filled chips, search fields

  // Material 3 Outlines & Borders
  static const Color outline = Color(0xFF4A5A4A);                // Interactive element borders
  static const Color outlineVariant = Color(0xFF2B382B);         // Subtle dividers & cards

  // Accent Colors — Electric Lime & Neon Studio
  static const Color accent = Color(0xFFC6F16D); // Electric lime primary accent
  static const Color accentHover = Color(0xFFD4F870);
  static const Color accentPressed = Color(0xFFAEE64B);
  static const Color accentSoft = Color(0x29C6F16D); // 16% alpha lime
  static const Color accentBorder = Color(0x66C6F16D); // 40% alpha lime border

  // Material 3 Tertiary Palette
  static const Color tertiary = Color(0xFF7CD5C8);
  static const Color onTertiary = Color(0xFF003731);
  static const Color tertiaryContainer = Color(0xFF005047);
  static const Color onTertiaryContainer = Color(0xFF98F2E4);

  // Studio Telemetry & Status Badges
  static const Color telemetryLive = Color(0xFF22C55E); // Live status emerald
  static const Color telemetryCyan = Color(0xFF00F0FF); // Model / codec cyan
  static const Color telemetryPurple = Color(0xFFA855F7); // Special tag purple
  static const Color telemetryAmber = Color(0xFFF59E0B); // Warning / alert amber

  // Floating Nav Bar Tokens
  static const Color navBarBackground = Color(0xE60B0E0B); // Frosted obsidian surface (90% alpha)
  static const Color navBarBorder = Color(0x55263526); // Studio green-carbon 1px border
  static const Color navBarActivePill = Color(0xFFC6F16D); // Electric lime active tab capsule
  static const Color navBarActiveBorder = Color(0xFFD4F870);
  static const Color navBarActiveIcon = Color(0xFF0B0E0B); // Pitch black icon inside lime capsule

  // Typography Colors (WCAG AAA/AA Compliant)
  static const Color textPrimary = Color(0xFFF1F5F1); // Crisp off-white
  static const Color textSecondary = Color(0xFF8E9E8E); // Studio sage-grey
  static const Color textMuted = Color(0xFF7E8F7E); // WCAG AA 4.6:1 contrast
  static const Color textDisabled = Color(0xFF5A665A); // WCAG AA large/decorative
  static const Color onSurfaceVariant = Color(0xFFB5C4B5);

  // Scrim & Shadow
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // Dividers & Borders
  static const Color border = Color(0xFF263526); // Crisp studio 1px border
  static const Color borderSubtle = Color(0xFF1D261D); // Subtle inner border
  static const Color divider = Color(0xFF1D261D);

  // Badges & Ratings
  static const Color ratingStar = Color(0xFFFFB800); // Warm gold
  static const Color ratingBadge = Color(0xCC0E130E); // Dark translucent pill
  static const Color liveBadge = Color(0xFF22C55E); // Live green badge
}
