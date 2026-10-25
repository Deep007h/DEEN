import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/core/presentation/widgets/floating_nav_bar.dart';

void main() {
  group('FloatingNavBar Widget Tests', () {
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
      FloatingNavBarItem(
        icon: Icons.bookmark_outline_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: 'Library',
      ),
      FloatingNavBarItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    testWidgets('renders all items with icons and labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    });

    testWidgets('active indicator is a solid lime capsule surrounding active icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 1, // Explore is selected
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );

      final exploreTextFinder = find.text('Explore');
      expect(exploreTextFinder, findsOneWidget);

      // Find all AnimatedContainers
      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers.length, 4);

      // Verify selected tab has solid lime active background (#B5F237)
      const activeLime = Color(0xFFB5F237);
      final selectedContainer = animatedContainers.firstWhere(
        (c) => (c.decoration as BoxDecoration?)?.color == activeLime,
      );
      expect(selectedContainer, isNotNull);

      // Verify the Icon widget is inside the solid lime capsule
      expect(
        find.descendant(
          of: find.byWidget(selectedContainer),
          matching: find.byIcon(Icons.grid_view_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping an item invokes onTap callback', (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              items: items,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);
    });
  });
}
