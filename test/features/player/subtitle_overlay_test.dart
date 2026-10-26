import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/data/engine/mock_playback_engine.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_subtitle_overlay.dart';
import 'package:anime_stream/features/stream/domain/models/subtitle_track.dart';

void main() {
  group('PlayerSubtitleOverlay Widget Tests', () {
    late MockPlaybackEngine engine;

    setUp(() {
      engine = MockPlaybackEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    testWidgets('renders subtitle cues when received from engine stream', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSubtitleOverlay(
              engine: engine,
              settings: const SubtitleSettings(fontSize: 16.0),
              isHudVisible: false,
            ),
          ),
        ),
      );

      // Initially no subtitles
      expect(find.text('Hello World!'), findsNothing);

      // Simulate incoming subtitle cue
      engine.simulateSubtitle(['Hello World!']);
      await tester.pump();

      expect(find.text('Hello World!'), findsOneWidget);

      // Multi-line subtitle cue
      engine.simulateSubtitle(['First line', 'Second line']);
      await tester.pumpAndSettle();

      expect(find.text('First line\nSecond line'), findsOneWidget);

      // Clear subtitles
      engine.simulateSubtitle([]);
      await tester.pumpAndSettle();

      expect(find.text('First line\nSecond line'), findsNothing);
    });

    testWidgets('respects font size from SubtitleSettings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSubtitleOverlay(
              engine: engine,
              settings: const SubtitleSettings(fontSize: 24.0),
              isHudVisible: false,
            ),
          ),
        ),
      );

      engine.simulateSubtitle(['Sized Subtitle']);
      await tester.pumpAndSettle();

      final textFinder = find.text('Sized Subtitle');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontSize, 24.0);
    });

    testWidgets('adjusts bottom padding when HUD is visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSubtitleOverlay(
              engine: engine,
              settings: const SubtitleSettings(fontSize: 16.0),
              isHudVisible: false,
            ),
          ),
        ),
      );

      engine.simulateSubtitle(['HUD Positioning Test']);
      await tester.pumpAndSettle();

      final animatedPaddingBefore = tester.widget<AnimatedPadding>(
        find.byType(AnimatedPadding),
      );
      expect((animatedPaddingBefore.padding as EdgeInsets).bottom, 36.0);

      // Re-pump with HUD visible
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSubtitleOverlay(
              engine: engine,
              settings: const SubtitleSettings(fontSize: 16.0),
              isHudVisible: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedPaddingAfter = tester.widget<AnimatedPadding>(
        find.byType(AnimatedPadding),
      );
      expect((animatedPaddingAfter.padding as EdgeInsets).bottom, 84.0);
    });
  });
}
