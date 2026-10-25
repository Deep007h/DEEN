import 'dart:async';
import 'package:flutter/foundation.dart';

/// Ad-Free stub service ensuring zero ads are loaded or displayed,
/// while maintaining interface compatibility for all providers and caller code.
class AdService {
  static final AdService instance = AdService();

  bool _initialized = false;
  bool _testMode = false;
  bool _adsEnabled = false;

  /// Cooldown between interstitial ads (noop in ad-free mode)
  Duration interstitialCooldown = const Duration(minutes: 2);

  AdService();

  bool get isInitialized => _initialized;
  bool get testMode => _testMode;
  bool get adsEnabled => _adsEnabled;
  bool get hasPreloadedAd => false;

  /// Initialize AdService (noop in ad-free edition)
  Future<void> initialize({bool testMode = false}) async {
    _initialized = true;
    _testMode = testMode;
  }

  /// Toggle test mode dynamically
  Future<void> setTestMode(bool enabled) async {
    _testMode = enabled;
  }

  /// Toggle ads enabled state
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
  }

  /// Preload interstitial ad (noop in ad-free edition)
  Future<void> preloadInterstitial() async {}

  /// Check if an interstitial can be shown (always false in ad-free edition)
  bool canShowInterstitial() {
    return _adsEnabled;
  }

  /// Present interstitial ad (immediately invokes onComplete callback with zero ads)
  Future<void> showInterstitialAd({
    required VoidCallback onComplete,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    onComplete();
  }

  /// Backward-compatible alias for [showInterstitialAd].
  Future<void> showInterstitialIfReady({VoidCallback? onComplete}) async {
    await showInterstitialAd(onComplete: onComplete ?? () {});
  }

  /// Explicit test method to trigger interstitial ad flow
  Future<void> showTestInterstitial({required VoidCallback onComplete}) async {
    onComplete();
  }

  /// Load banner ad (always returns null in ad-free edition)
  Future<dynamic> loadBanner() async {
    return null;
  }
}
