import 'package:flutter/material.dart';

/// Ad-free corner banner widget that renders nothing.
class PlayerCornerBannerAd extends StatelessWidget {
  final bool isVisible;
  final double availableWidth;
  final double availableHeight;
  final int quarterTurns;

  const PlayerCornerBannerAd({
    super.key,
    required this.isVisible,
    this.availableWidth = 80.0,
    this.availableHeight = 360.0,
    this.quarterTurns = 1,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
