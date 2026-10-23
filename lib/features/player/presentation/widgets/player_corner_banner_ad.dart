import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';
import '../../../../core/services/ad_service.dart';

/// Minimal, non-intrusive Start.io banner ad container designed specifically
/// to fit inside the black pillarbox/letterbox corner space during video playback.
class PlayerCornerBannerAd extends StatefulWidget {
  /// Whether the ad should be visible (e.g. controls hidden, not locked, not scrubbing).
  final bool isVisible;

  const PlayerCornerBannerAd({
    super.key,
    required this.isVisible,
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
    if (_hasError || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Offstage ensures the platform view is completely removed from Flutter's
    // hit-testing tree when invisible, ensuring controls & gestures are 100% responsive.
    return Offstage(
      offstage: !widget.isVisible,
      child: Transform.scale(
        scale: 0.78,
        alignment: Alignment.topRight,
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'AD',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              StartAppBanner(_bannerAd!),
            ],
          ),
        ),
      ),
    );
  }
}
