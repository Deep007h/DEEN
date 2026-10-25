import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/presentation/widgets/player_corner_banner_ad.dart';

void main() {
  group('PlayerCornerBannerAd Widget Tests', () {
    testWidgets('renders cleanly in test environment without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PlayerCornerBannerAd(isVisible: true),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PlayerCornerBannerAd), findsOneWidget);
    });

    testWidgets('respects isVisible = false gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PlayerCornerBannerAd(
                  isVisible: false,
                  availableWidth: 80,
                  availableHeight: 360,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PlayerCornerBannerAd), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when availableWidth is less than 36', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PlayerCornerBannerAd(
                  isVisible: true,
                  availableWidth: 20.0,
                  availableHeight: 360.0,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PlayerCornerBannerAd), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(PlayerCornerBannerAd),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });
  });
}
