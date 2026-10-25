import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/core/theme/app_colors.dart';
import 'package:anime_stream/core/theme/app_theme.dart';
import 'package:anime_stream/core/presentation/widgets/floating_nav_bar.dart';

void main() {
  group('Dynamic Accent & Neutral Obsidian Theme Tests', () {
    setUp(() {
      AppColors.updateAccent(AppColors.defaultAccent);
    });

    tearDown(() {
      AppColors.updateAccent(AppColors.defaultAccent);
    });

    test('AppColors.updateAccent propagates dynamically to all derived tokens', () {
      expect(AppColors.accent, const Color(0xFFB5F237));
      expect(AppColors.navBarActivePill, const Color(0xFFB5F237));
      expect(AppColors.proBadgeText, const Color(0xFFB5F237));

      // Switch to Crimson Red
      const crimson = Color(0xFFFF4081);
      AppColors.updateAccent(crimson);

      expect(AppColors.accent, crimson);
      expect(AppColors.navBarActivePill, crimson);
      expect(AppColors.proBadgeText, crimson);
      expect(AppColors.accentSoft, crimson.withValues(alpha: 0.16));
      expect(AppColors.accentBorder, crimson.withValues(alpha: 0.40));

      // Neutral obsidian surfaces remain dark and un-tinted
      expect(AppColors.background, const Color(0xFF0C0D0E));
      expect(AppColors.surface, const Color(0xFF141517));
      expect(AppColors.surfaceCard, const Color(0xFF141517));
      expect(AppColors.border, const Color(0xFF28292E));
    });

    test('AppColors.accentContrast adapts to light vs dark accents', () {
      // Light accent (Electric Lime) -> Dark foreground
      AppColors.updateAccent(const Color(0xFFB5F237));
      expect(AppColors.accentContrast, const Color(0xFF0C0D0E));
      expect(AppColors.navBarActiveIcon, const Color(0xFF0C0D0E));

      // Dark accent (Deep Navy / Purple) -> White foreground
      AppColors.updateAccent(const Color(0xFF1A237E));
      expect(AppColors.accentContrast, Colors.white);
      expect(AppColors.navBarActiveIcon, Colors.white);
    });

    testWidgets('FloatingNavBar reflects updated accent color dynamically', (tester) async {
      const items = [
        FloatingNavBarItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        FloatingNavBarItem(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Explore',
        ),
      ];

      // Initially Electric Lime
      AppColors.updateAccent(const Color(0xFFB5F237));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildDarkTheme(const Color(0xFFB5F237)),
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );

      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      final selectedContainer = animatedContainers.firstWhere(
        (c) => (c.decoration as BoxDecoration?)?.color == const Color(0xFFB5F237),
      );
      expect(selectedContainer, isNotNull);

      // Now update accent to Royal Purple and rebuild
      const royalPurple = Color(0xFF8A2BE2);
      AppColors.updateAccent(royalPurple);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildDarkTheme(royalPurple),
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final updatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      final purpleContainer = updatedContainers.firstWhere(
        (c) => (c.decoration as BoxDecoration?)?.color == royalPurple,
      );
      expect(purpleContainer, isNotNull);
    });
  });
}
