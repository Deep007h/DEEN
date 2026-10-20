import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text.dart';

/// App theme definition configuring Material Design 3 (M3).
/// Adheres strictly to m3.material.io component specifications and
/// material-components-android design architecture.
abstract final class AppTheme {
  static ThemeData get darkTheme => buildDarkTheme(AppColors.accent);

  static ThemeData buildDarkTheme(Color accentColor) {
    // Generate dynamic tonal palette from seed color in dark brightness
    final baseScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
    );

    // Fine-tune Material 3 Surface Containers and Outlines for high contrast dark anime aesthetic
    final colorScheme = baseScheme.copyWith(
      primary: accentColor,
      onPrimary: const Color(0xFF0B0E0B),
      primaryContainer: accentColor.withValues(alpha: 0.22),
      onPrimaryContainer: accentColor,
      secondary: accentColor,
      onSecondary: const Color(0xFF0B0E0B),
      secondaryContainer: accentColor.withValues(alpha: 0.18),
      onSecondaryContainer: accentColor,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      colorScheme: colorScheme,
      textTheme: AppText.m3TextTheme,

      // 1. Material 3 Top App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2.0,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: false,
        titleTextStyle: AppText.titleLarge.copyWith(color: colorScheme.onSurface),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // 2. Material 3 Navigation Bar (Canonical 80dp height, active pill capsule)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 2.0,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        surfaceTintColor: colorScheme.surfaceTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppText.labelMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            );
          }
          return AppText.labelMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onSecondaryContainer, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),

      // 3. Material 3 Cards (Filled, Elevated, Outlined support)
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),

      // 4. Material 3 Chips (Filter, Assist, Input, Suggestion)
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSecondaryContainer),
        checkmarkColor: colorScheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        ),
        elevation: 0,
        pressElevation: 1,
      ),

      // 5. Material 3 Bottom Sheet (28dp rounded corners, drag handle)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        modalBackgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 3,
        modalElevation: 3,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        dragHandleSize: const Size(32, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
        ),
      ),

      // 6. Material 3 Dialog (28dp corners, surfaceContainerHigh)
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        titleTextStyle: AppText.headlineSmall.copyWith(color: colorScheme.onSurface),
        contentTextStyle: AppText.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),

      // 7. Material 3 Search Bar & Search View
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
        elevation: WidgetStateProperty.all(2),
        constraints: const BoxConstraints(minHeight: 56, maxHeight: 56),
        shape: WidgetStateProperty.all(const StadiumBorder()),
        hintStyle: WidgetStateProperty.all(
          TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
        ),
      ),

      // 8. Material 3 Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.secondaryContainer,
          selectedForegroundColor: colorScheme.onSecondaryContainer,
          backgroundColor: colorScheme.surfaceContainerLow,
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),

      // 9. Material 3 Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      // 10. Material 3 Slider & Switch
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        trackHeight: 6.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline;
        }),
      ),

      // 11. Progress Indicator & Badges
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),

      // 12. Tooltip & Divider
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 350),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.8,
        space: 1,
      ),

      // 13. Material 3 Motion Page Transitions & Splash
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
