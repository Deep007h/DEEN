import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_center_controls.dart';

void main() {
  group('PlayerCenterControls Navigation & Layout Tests', () {
    testWidgets('Renders 5-button center controls layout with Prev and Next icons', (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;
      bool playTapped = false;
      bool replayTapped = false;
      bool forwardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerCenterControls(
              isPlaying: true,
              isBuffering: false,
              hasPreviousEpisode: true,
              hasNextEpisode: true,
              onPreviousEpisode: () => prevTapped = true,
              onNextEpisode: () => nextTapped = true,
              onTogglePlay: () => playTapped = true,
              onReplay10: () => replayTapped = true,
              onForward10: () => forwardTapped = true,
            ),
          ),
        ),
      );

      // Verify all 5 icons are present
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

      // Tap Previous Episode
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(prevTapped, isTrue);

      // Tap Next Episode
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(nextTapped, isTrue);

      // Tap Play/Pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(playTapped, isTrue);

      // Tap Replay 10
      await tester.tap(find.byIcon(Icons.replay_10_rounded));
      expect(replayTapped, isTrue);

      // Tap Forward 10
      await tester.tap(find.byIcon(Icons.forward_10_rounded));
      expect(forwardTapped, isTrue);
    });

    testWidgets('Previous episode button is disabled when hasPreviousEpisode is false', (tester) async {
      bool prevTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerCenterControls(
              isPlaying: false,
              isBuffering: false,
              hasPreviousEpisode: false,
              hasNextEpisode: true,
              onPreviousEpisode: () => prevTapped = true,
              onNextEpisode: () {},
              onTogglePlay: () {},
              onReplay10: () {},
              onForward10: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);

      // Tapping disabled previous button should NOT trigger callback
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(prevTapped, isFalse);
    });
  });
}
