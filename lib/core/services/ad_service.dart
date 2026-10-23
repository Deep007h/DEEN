import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:startapp_sdk/startapp.dart';

/// Service managing Start.io ad initialization, caching, and rate-limited playback transitions.
class AdService {
  static final AdService instance = AdService();

  final StartAppSdk _sdk;

  bool get _isTestEnv => Platform.environment.containsKey('FLUTTER_TEST');

  bool _initialized = false;
  bool _testMode = true; // Safe test mode by default
  bool _adsEnabled = true;

  StartAppInterstitialAd? _preloadedInterstitial;
  Future<void>? _loadingFuture;
  Completer<void>? _activeAdCompleter;
  DateTime? _lastInterstitialShowTime;

  /// Cooldown between interstitial ads in live mode (default 2 minutes)
  Duration interstitialCooldown = const Duration(minutes: 2);

  AdService({StartAppSdk? sdk}) : _sdk = sdk ?? StartAppSdk();

  bool get isInitialized => _initialized;
  bool get testMode => _testMode;
  bool get adsEnabled => _adsEnabled;
  bool get hasPreloadedAd => _preloadedInterstitial != null;

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
      debugPrint('[AdService] Initialized with testMode: $_testMode');
      // Preload the first interstitial ad in the background
      unawaited(preloadInterstitial());
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
      debugPrint('[AdService] Test mode updated: $enabled');
      _preloadedInterstitial?.dispose();
      _preloadedInterstitial = null;
      unawaited(preloadInterstitial());
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
    if (!_adsEnabled || _isTestEnv || _preloadedInterstitial != null) return;
    if (_loadingFuture != null) {
      await _loadingFuture;
      return;
    }

    final future = _loadInterstitialInternal();
    _loadingFuture = future;
    try {
      await future;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _loadInterstitialInternal() async {
    try {
      debugPrint('[AdService] Preloading interstitial ad...');
      _preloadedInterstitial = await _sdk.loadInterstitialAd(
        onAdDisplayed: () {
          debugPrint('[AdService] Interstitial displayed on screen');
        },
        onAdHidden: () {
          debugPrint('[AdService] Interstitial hidden/closed by user');
          _onAdDismissed();
        },
        onAdNotDisplayed: () {
          debugPrint('[AdService] Interstitial failed to display');
          _onAdDismissed();
        },
      );
      debugPrint('[AdService] Interstitial preloaded successfully');
    } catch (e) {
      debugPrint('[AdService] Error preloading interstitial: $e');
      _preloadedInterstitial = null;
    }
  }

  void _onAdDismissed() {
    try {
      _preloadedInterstitial?.dispose();
    } catch (_) {}
    _preloadedInterstitial = null;

    if (_activeAdCompleter != null && !_activeAdCompleter!.isCompleted) {
      _activeAdCompleter!.complete();
    }
    // Automatically preload the next ad for future transitions
    unawaited(preloadInterstitial());
  }

  /// Checks if an interstitial ad is eligible to show based on cooldown and readiness.
  bool canShowInterstitial() {
    if (!_adsEnabled) return false;
    // In test mode, no cooldown so developers/users can test ads on every episode
    if (_testMode) return true;
    if (_lastInterstitialShowTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShowTime!);
      if (elapsed < interstitialCooldown) {
        return false;
      }
    }
    return true;
  }

  /// Shows an interstitial ad before video playback.
  /// Awaits ad closure before invoking [onComplete], ensuring the video player is not
  /// launched prematurely in landscape while an ad is presenting.
  /// If ad is not immediately cached, it waits up to [loadTimeout] to load one on-demand.
  Future<void> showInterstitialAd({
    required VoidCallback onComplete,
    Duration loadTimeout = const Duration(seconds: 4),
  }) async {
    if (!_adsEnabled || _isTestEnv) {
      onComplete();
      return;
    }

    if (!canShowInterstitial()) {
      debugPrint('[AdService] Cooldown active, skipping interstitial');
      onComplete();
      return;
    }

    if (!_initialized) {
      await initialize(testMode: _testMode);
    }

    // If preloaded ad is not ready, attempt an on-demand load with timeout
    if (_preloadedInterstitial == null) {
      debugPrint('[AdService] No cached ad ready, attempting on-demand load...');
      try {
        await preloadInterstitial().timeout(loadTimeout);
      } catch (e) {
        debugPrint('[AdService] On-demand ad load timed out or failed: $e');
      }
    }

    final ad = _preloadedInterstitial;
    if (ad == null) {
      debugPrint('[AdService] No interstitial available, proceeding to playback');
      onComplete();
      unawaited(preloadInterstitial());
      return;
    }

    _preloadedInterstitial = null;
    final completer = Completer<void>();
    _activeAdCompleter = completer;

    try {
      debugPrint('[AdService] Presenting interstitial ad now...');
      final shown = await ad.show();
      if (!shown) {
        debugPrint('[AdService] ad.show() returned false');
        try {
          ad.dispose();
        } catch (_) {}
        _activeAdCompleter = null;
        onComplete();
        unawaited(preloadInterstitial());
        return;
      }

      // Ad successfully launched
      _lastInterstitialShowTime = DateTime.now();

      // Wait until user closes the ad or safety timeout expires
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[AdService] Ad dismissal wait timed out');
        },
      );
    } catch (e) {
      debugPrint('[AdService] Error presenting interstitial: $e');
    } finally {
      if (_activeAdCompleter == completer) {
        _activeAdCompleter = null;
      }
      try {
        ad.dispose();
      } catch (_) {}
      onComplete();
      unawaited(preloadInterstitial());
    }
  }

  /// Backward-compatible alias for [showInterstitialAd].
  Future<void> showInterstitialIfReady({VoidCallback? onComplete}) async {
    await showInterstitialAd(onComplete: onComplete ?? () {});
  }

  /// Explicitly forces a test interstitial ad on-demand (e.g. from Settings screen)
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
