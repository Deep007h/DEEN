import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_stream/main.dart';

void main() {
  testWidgets('Verify bottom navigation tabs and routing', (WidgetTester tester) async {
    // Test on small screen (360x640) to verify no overflow
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: AnimeStreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home tab is active
    expect(find.text('Home'), findsWidgets);

    // Verify all 4 tabs exist in navigation bar
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);

    // Tap Explore tab
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Explore'), findsWidgets);

    // Tap Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('My Library'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    // Return to Home tab
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
  });
}
