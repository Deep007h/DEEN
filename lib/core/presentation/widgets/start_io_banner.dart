import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:startapp_sdk/startapp.dart';
import '../../services/ad_providers.dart';

/// Dark-themed, non-intrusive banner ad container for Start.io banner ads.
class StartIoBannerWidget extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry margin;
  final bool showLabel;

  const StartIoBannerWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showLabel = true,
  });

  @override
  ConsumerState<StartIoBannerWidget> createState() => _StartIoBannerWidgetState();
}

class _StartIoBannerWidgetState extends ConsumerState<StartIoBannerWidget> {
  StartAppBannerAd? _bannerAd;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final adService = ref.read(adServiceProvider);
    if (!adService.adsEnabled) {
      return;
    }

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

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ADVERTISEMENT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14141A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: StartAppBanner(_bannerAd!),
          ),
        ],
      ),
    );
  }
}
