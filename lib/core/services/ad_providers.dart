import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_service.dart';

/// Provider for the singleton AdService instance configured for live ad monetization.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService.instance;
  service.initialize(testMode: false);
  return service;
});
