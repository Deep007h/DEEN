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
                PlayerCornerBannerAd(isVisible: false),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PlayerCornerBannerAd), findsOneWidget);
    });
  });
}
