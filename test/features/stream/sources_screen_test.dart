import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/features/settings/presentation/screens/sources_screen.dart';

void main() {
  testWidgets('SourcesScreen displays providers, allows toggling and testing connectivity',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SourcesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and description
    expect(find.text('Stream Providers'), findsOneWidget);
    expect(find.textContaining('Hold & drag to reorder priority'), findsOneWidget);

    // Verify 4 providers
    expect(find.text('MegaVid (AniList / KissKH)'), findsOneWidget);
    expect(find.text('Demo (Public Test Streams)'), findsOneWidget);
    expect(find.text('Direct URL (Self-Hosted)'), findsOneWidget);
    expect(find.text('Jellyfin Server'), findsOneWidget);

    // Test connectivity of provider
    await tester.tap(find.text('Test Source').first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.textContaining('Online'), findsOneWidget);
  });
}
