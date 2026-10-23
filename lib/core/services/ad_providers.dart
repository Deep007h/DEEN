import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_service.dart';

/// Provider for the singleton AdService instance.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  service.initialize(testMode: true);
  return service;
});

/// State provider for whether test ads are enabled.
final testAdsEnabledProvider = StateProvider<bool>((ref) {
  return true;
});
