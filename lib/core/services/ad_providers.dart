import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/repositories/app_settings_repository.dart' show sharedPreferencesProvider;
import 'ad_service.dart';

/// Provider for the singleton AdService instance.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService.instance;
  final testMode = ref.watch(testAdsEnabledProvider);
  service.initialize(testMode: testMode);
  return service;
});

/// State provider for whether test ads are enabled, persisted in SharedPreferences.
final testAdsEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs?.getBool('test_ads_enabled') ?? true;
});
