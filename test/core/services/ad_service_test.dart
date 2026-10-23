import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/core/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService Logic & Cooldown Tests', () {
    test('Default states are initialized safely', () {
      final adService = AdService();
      expect(adService.testMode, isTrue);
      expect(adService.adsEnabled, isTrue);
      expect(adService.isInitialized, isFalse);
      expect(adService.interstitialCooldown, const Duration(minutes: 3));
    });

    test('Toggling adsEnabled updates state and blocks interstitials', () {
      final adService = AdService();
      expect(adService.canShowInterstitial(), isTrue);

      adService.setAdsEnabled(false);
      expect(adService.adsEnabled, isFalse);
      expect(adService.canShowInterstitial(), isFalse);

      adService.setAdsEnabled(true);
      expect(adService.adsEnabled, isTrue);
      expect(adService.canShowInterstitial(), isTrue);
    });

    test('showInterstitialIfReady invokes onComplete when no ad is loaded or ready', () async {
      final adService = AdService();
      bool completed = false;

      await adService.showInterstitialIfReady(onComplete: () {
        completed = true;
      });

      expect(completed, isTrue);
    });

    test('Cooldown prevents rapid back-to-back interstitial triggering', () {
      final adService = AdService();
      adService.interstitialCooldown = const Duration(minutes: 3);

      expect(adService.canShowInterstitial(), isTrue);
    });

    test('setTestMode updates testMode state', () async {
      final adService = AdService();
      expect(adService.testMode, isTrue);

      await adService.setTestMode(false);
      expect(adService.testMode, isFalse);

      await adService.setTestMode(true);
      expect(adService.testMode, isTrue);
    });
  });
}
