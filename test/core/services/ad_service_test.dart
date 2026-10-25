import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/core/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService Ad-Free Edition Tests', () {
    test('Default states are initialized safely in ad-free mode', () {
      final adService = AdService();
      expect(adService.testMode, isFalse);
      expect(adService.adsEnabled, isFalse);
      expect(adService.isInitialized, isFalse);
      expect(adService.hasPreloadedAd, isFalse);
      expect(adService.canShowInterstitial(), isFalse);
    });

    test('Toggling adsEnabled updates state', () {
      final adService = AdService();
      expect(adService.canShowInterstitial(), isFalse);

      adService.setAdsEnabled(true);
      expect(adService.adsEnabled, isTrue);
      expect(adService.canShowInterstitial(), isTrue);

      adService.setAdsEnabled(false);
      expect(adService.adsEnabled, isFalse);
      expect(adService.canShowInterstitial(), isFalse);
    });

    test('showInterstitialAd invokes onComplete callback cleanly without showing ads', () async {
      final adService = AdService();
      bool completed = false;

      await adService.showInterstitialAd(onComplete: () {
        completed = true;
      });

      expect(completed, isTrue);
    });

    test('showInterstitialIfReady invokes onComplete for backward compatibility', () async {
      final adService = AdService();
      bool completed = false;

      await adService.showInterstitialIfReady(onComplete: () {
        completed = true;
      });

      expect(completed, isTrue);
    });

    test('loadBanner returns null in ad-free mode', () async {
      final adService = AdService();
      final banner = await adService.loadBanner();
      expect(banner, isNull);
    });
  });
}
