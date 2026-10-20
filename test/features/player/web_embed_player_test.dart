import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/presentation/widgets/web_embed_player_view.dart';

void main() {
  group('WebEmbedPlayerView Widget Tests', () {
    testWidgets('renders WebEmbedPlayerView with title and switch button', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var nativeTapped = false;
      var backTapped = false;
      var lockTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WebEmbedPlayerView(
            embedUrl: 'https://megavid.buzz/ani/178789/10/dub',
            title: 'Mushoku Tensei S2',
            episodeSubtitle: 'Episode 10 • Megavid Web Embed',
            onBack: () => backTapped = true,
            onSwitchToNative: () => nativeTapped = true,
            isLocked: false,
            onToggleLock: () => lockTapped = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Mushoku Tensei S2'), findsOneWidget);
      expect(find.text('Episode 10 • Megavid Web Embed'), findsOneWidget);
      expect(find.text('WEB EMBED (DEFAULT)'), findsOneWidget);

      // Verify Native Player switch button
      expect(find.text('Native Player'), findsOneWidget);
      await tester.tap(find.text('Native Player'));
      expect(nativeTapped, isTrue);

      // Verify Back button
      await tester.tap(find.byTooltip('Back'));
      expect(backTapped, isTrue);

      // Verify Lock button
      await tester.tap(find.byTooltip('Lock screen'));
      expect(lockTapped, isTrue);
    });

    testWidgets('renders locked state correctly when isLocked is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WebEmbedPlayerView(
            embedUrl: 'https://megavid.buzz/ani/178789/10/sub',
            title: 'Mushoku Tensei S2',
            episodeSubtitle: 'Episode 10',
            onBack: () {},
            onSwitchToNative: () {},
            isLocked: true,
            onToggleLock: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When locked, the top bar controls should be hidden
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Native Player'), findsNothing);
    });
  });
}
