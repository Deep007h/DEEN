import 'package:flutter/material.dart';

/// Design tokens for colors across the application.
/// Matches the obsidian-carbon foundation and dynamic studio aesthetic.
abstract final class AppColors {
  // Default primary accent (Electric Lime)
  static const Color defaultAccent = Color(0xFFB5F237);
  static const int defaultAccentValue = 0xFFB5F237;

  // Active dynamic accent state
  static Color _accent = defaultAccent;

  /// Dynamic primary accent color, updated when user picks a new accent theme.
  static Color get accent => _accent;
  static Color get accentHover => _accent.withValues(alpha: 0.85);
  static Color get accentPressed => _accent.withValues(alpha: 0.70);
  static Color get accentSoft => _accent.withValues(alpha: 0.16);
  static Color get accentBorder => _accent.withValues(alpha: 0.40);

  /// Updates the active accent across all UI components.
  static void updateAccent(Color color) {
    _accent = color;
  }

  // Canvas / Backgrounds (Neutral obsidian OLED dark)
  static const Color background = Color(0xFF0C0D0E); // Neutral obsidian canvas
  static const Color surface = Color(0xFF141517); // Studio card surface
  static const Color surfaceCard = Color(0xFF141517); // Studio card surface alias
  static const Color surfaceElevated = Color(0xFF1A1B1E); // Elevated modals/menus
  static const Color surfaceHighlight = Color(0xFF222328); // Subtle highlights
  static const Color surfaceSecondary = Color(0xFF121315); // Secondary dark surface
  static const Color surfaceDim = Color(0xFF0A0A0C);
  static const Color surfaceBright = Color(0xFF28282C);

  // Material 3 Surface Containers (Elevation Hierarchy)
  static const Color surfaceContainerLowest = Color(0xFF090A0B); // Level 0: Deepest canvas
  static const Color surfaceContainerLow = Color(0xFF131416);    // Level 1: Elevated cards & list items
  static const Color surfaceContainer = Color(0xFF18191C);       // Level 2: NavigationBar, app bars
  static const Color surfaceContainerHigh = Color(0xFF1F2024);   // Level 3: Dialogs, bottom sheets
  static const Color surfaceContainerHighest = Color(0xFF26272C);// Level 4/5: Filled chips, search fields

  // Material 3 Outlines & Borders (Neutral dark outlines)
  static const Color outline = Color(0xFF484A50);                // Interactive element borders
  static const Color outlineVariant = Color(0xFF2E3035);         // Subtle dividers & cards

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

  /// Dynamic high-contrast foreground color on top of [accent]
  static Color get accentContrast =>
      _accent.computeLuminance() > 0.4 ? const Color(0xFF0C0D0E) : Colors.white;

  // Floating Nav Bar Tokens (Dynamic pill and border)
  static const Color navBarBackground = Color(0xF00E0F11); // Frosted obsidian surface (94% alpha)
  static const Color navBarBorder = Color(0x55303238); // Neutral dark 1px border
  static Color get navBarActivePill => _accent; // Dynamic accent active tab capsule
  static Color get navBarActiveBorder => _accent.withValues(alpha: 0.85);
  static Color get navBarActiveIcon => accentContrast; // Contrast-adaptive icon inside active capsule

  // PRO Badge Tokens
  static Color get proBadgeBg => _accent.withValues(alpha: 0.16);
  static Color get proBadgeBorder => _accent;
  static Color get proBadgeText => _accent;

  // Online Indicator
  static const Color onlineDot = Color(0xFF22C55E);

  // Themed Genre Card Tokens
  static const Color genreActionBg = Color(0xFF2A1518);
  static const Color genreActionBorder = Color(0xFF5A252B);
  static const Color genreActionColor = Color(0xFFE57373);

  static const Color genreAdventureBg = Color(0xFF261D10);
  static const Color genreAdventureBorder = Color(0xFF59401C);
  static const Color genreAdventureColor = Color(0xFFFFD54F);

  static const Color genreFantasyBg = Color(0xFF221730);
  static const Color genreFantasyBorder = Color(0xFF4C2F6A);
  static const Color genreFantasyColor = Color(0xFFBA68C8);

  static const Color genreRomanceBg = Color(0xFF2B141F);
  static const Color genreRomanceBorder = Color(0xFF5C263F);
  static const Color genreRomanceColor = Color(0xFFF06292);

  static const Color genreComedyBg = Color(0xFF2B1E12);
  static const Color genreComedyBorder = Color(0xFF5D3E1F);
  static const Color genreComedyColor = Color(0xFFFFB74D);

  static const Color genreThrillerBg = Color(0xFF13222B);
  static const Color genreThrillerBorder = Color(0xFF22485E);
  static const Color genreThrillerColor = Color(0xFF4DD0E1);

  static const Color genreSciFiBg = Color(0xFF101B2B);
  static const Color genreSciFiBorder = Color(0xFF1B3455);
  static const Color genreSciFiColor = Color(0xFF64B5F6);

  static const Color genreKDramaBg = Color(0xFF181B18);
  static const Color genreKDramaBorder = Color(0xFF2D352D);
  static Color get genreKDramaColor => _accent;

  // Typography Colors (WCAG AAA/AA Compliant)
  static const Color textPrimary = Color(0xFFF1F3F5); // Crisp off-white
  static const Color textSecondary = Color(0xFF94979E); // Neutral cool-grey
  static const Color textMuted = Color(0xFF787B82); // WCAG AA 4.6:1 contrast
  static const Color textDisabled = Color(0xFF55585F); // WCAG AA large/decorative
  static const Color onSurfaceVariant = Color(0xFFB8BAC2);

  // Scrim & Shadow
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // Dividers & Borders (Neutral dark)
  static const Color border = Color(0xFF28292E); // Crisp neutral 1px border
  static const Color borderSubtle = Color(0xFF1E1F23); // Subtle inner border
  static const Color divider = Color(0xFF1E1F23);

  // Badges & Ratings
  static const Color ratingStar = Color(0xFFFFB800); // Warm gold
  static const Color ratingBadge = Color(0xCC121315); // Dark translucent pill
  static const Color liveBadge = Color(0xFF22C55E); // Live green badge
  static const Color rankBadgeBg = Color(0x99121315); // Rank number container
}
