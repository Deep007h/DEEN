import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:startapp_sdk/startapp.dart';

/// Service managing Start.io ad initialization, caching, and rate-limited playback transitions.
class AdService {
  final StartAppSdk _sdk;
  
  bool get _isTestEnv => Platform.environment.containsKey('FLUTTER_TEST');

  bool _initialized = false;
  bool _testMode = true; // Safe test mode by default
  bool _adsEnabled = true;

  StartAppInterstitialAd? _preloadedInterstitial;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShowTime;

  /// Cooldown between interstitial ads (default 3 minutes)
  Duration interstitialCooldown = const Duration(minutes: 3);

  AdService({StartAppSdk? sdk}) : _sdk = sdk ?? StartAppSdk();

  bool get isInitialized => _initialized;
  bool get testMode => _testMode;
  bool get adsEnabled => _adsEnabled;

  /// Initialize Start.io SDK and configure test ad mode.
  Future<void> initialize({bool testMode = true}) async {
    if (_initialized) return;
    _testMode = testMode;
    if (_isTestEnv) {
      _initialized = true;
      return;
    }
    try {
      if (!kIsWeb) {
        await _sdk.setTestAdsEnabled(_testMode);
      }
      _initialized = true;
      // Preload the first interstitial ad in the background
      preloadInterstitial();
    } catch (e) {
      debugPrint('[AdService] Initialization notice: $e');
    }
  }

  /// Toggle test mode dynamically (e.g., from Settings screen).
  Future<void> setTestMode(bool enabled) async {
    _testMode = enabled;
    if (_isTestEnv) return;
    try {
      if (!kIsWeb) {
        await _sdk.setTestAdsEnabled(enabled);
      }
    } catch (e) {
      debugPrint('[AdService] Failed to set test ads: $e');
    }
  }

  /// Toggle all ads on or off.
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
  }

  /// Preloads an interstitial ad into memory for instant display when needed.
  Future<void> preloadInterstitial() async {
    if (!_adsEnabled || _isLoadingInterstitial || _preloadedInterstitial != null || _isTestEnv) return;
    _isLoadingInterstitial = true;
    try {
      _preloadedInterstitial = await _sdk.loadInterstitialAd(
        onAdHidden: () {
          _preloadedInterstitial = null;
          // Automatically preload the next ad for future transitions
          preloadInterstitial();
        },
        onAdNotDisplayed: () {
          _preloadedInterstitial = null;
        },
      );
    } catch (e) {
      debugPrint('[AdService] Failed to preload interstitial: $e');
      _preloadedInterstitial = null;
    } finally {
      _isLoadingInterstitial = false;
    }
  }

  /// Checks if an interstitial ad is eligible to show based on cooldown and readiness.
  bool canShowInterstitial() {
    if (!_adsEnabled) return false;
    if (_lastInterstitialShowTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShowTime!);
      if (elapsed < interstitialCooldown) {
        return false;
      }
    }
    return true;
  }

  /// Shows an interstitial ad if cooldown has passed, then calls [onComplete].
  /// Never blocks the caller if the ad is unavailable or fails.
  Future<void> showInterstitialIfReady({VoidCallback? onComplete}) async {
    if (!canShowInterstitial() || _preloadedInterstitial == null) {
      onComplete?.call();
      if (_preloadedInterstitial == null) {
        preloadInterstitial();
      }
      return;
    }

    final ad = _preloadedInterstitial!;
    _preloadedInterstitial = null;

    try {
      _lastInterstitialShowTime = DateTime.now();
      await ad.show();
    } catch (e) {
      debugPrint('[AdService] Error showing interstitial: $e');
    } finally {
      onComplete?.call();
      preloadInterstitial();
    }
  }

  /// Explicitly forces a test interstitial ad on-demand (e.g. from developer/settings screen)
  /// ignoring cooldown.
  Future<bool> showTestInterstitial() async {
    if (_isTestEnv) return true;
    try {
      final ad = await _sdk.loadInterstitialAd();
      return await ad.show();
    } catch (e) {
      debugPrint('[AdService] Error showing test interstitial: $e');
      return false;
    }
  }

  /// Loads a banner ad instance for embedding in a widget.
  Future<StartAppBannerAd?> loadBanner({
    StartAppBannerType type = StartAppBannerType.BANNER,
    VoidCallback? onImpression,
    VoidCallback? onClicked,
  }) async {
    if (!_adsEnabled || _isTestEnv) return null;
    try {
      return await _sdk.loadBannerAd(
        type,
        onAdImpression: onImpression,
        onAdClicked: onClicked,
      );
    } catch (e) {
      debugPrint('[AdService] Error loading banner ad: $e');
      return null;
    }
  }
}
