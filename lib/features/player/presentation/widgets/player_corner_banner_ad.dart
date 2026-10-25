import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';
import '../../../../core/services/ad_service.dart';

/// Minimal, non-intrusive Start.io banner ad container designed specifically
/// to fit vertically inside the black pillarbox (non-content) space during video playback.
class PlayerCornerBannerAd extends StatefulWidget {
  /// Whether the ad should be visible (e.g. controls hidden, not locked, not scrubbing).
  final bool isVisible;

  /// Available width in the non-content pillarbox area (in logical pixels).
  final double availableWidth;

  /// Available height in the player viewport (in logical pixels).
  final double availableHeight;

  /// Optional quarter turns rotation: default 1 (90 degrees clockwise for top-to-bottom reading).
  final int quarterTurns;

  const PlayerCornerBannerAd({
    super.key,
    required this.isVisible,
    this.availableWidth = 80.0,
    this.availableHeight = 360.0,
    this.quarterTurns = 1,
  });

  @override
  State<PlayerCornerBannerAd> createState() => _PlayerCornerBannerAdState();
}

class _PlayerCornerBannerAdState extends State<PlayerCornerBannerAd> {
  StartAppBannerAd? _bannerAd;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final adService = AdService.instance;
    if (!adService.adsEnabled) return;

    try {
      final ad = await adService.loadBanner();
      if (mounted) {
        setState(() {
          _bannerAd = ad;
          _hasError = ad == null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableWidth < 36.0 || _hasError || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Base dimensions for vertical rotated banner:
    // StartAppBanner is 320w x 50h. When rotated 90 degrees, width is 50.0, height is 320.0.
    // Plus AD label header (~16.0 px height).
    const double unscaledWidth = 50.0;
    const double unscaledHeight = 336.0;

    final double maxAllowedWidth = math.max(0.0, widget.availableWidth - 8.0);
    final double maxAllowedHeight = math.max(0.0, widget.availableHeight - 16.0);
    final double scaleW = maxAllowedWidth / unscaledWidth;
    final double scaleH = maxAllowedHeight / unscaledHeight;
    final double scale = math.min(1.0, math.min(scaleW, scaleH));

    if (scale <= 0.35) {
      return const SizedBox.shrink();
    }

    final double effectiveWidth = unscaledWidth * scale;
    final double effectiveHeight = unscaledHeight * scale;

    // Offstage ensures the platform view is completely removed from Flutter's
    // hit-testing tree when invisible, ensuring controls & gestures are 100% responsive.
    return Offstage(
      offstage: !widget.isVisible,
      child: SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: Container(
            width: unscaledWidth,
            height: unscaledHeight,
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: widget.quarterTurns,
                      child: StartAppBanner(_bannerAd!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
