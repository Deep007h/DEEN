import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/github_updater_repository.dart';
import '../../domain/models/app_release_info.dart';

/// Provider for the updater repository.
final updaterRepositoryProvider = Provider<UpdaterRepository>((ref) {
  return GithubUpdaterRepository();
});

/// Current application semantic version (designated as v1 / 1.0.0).
final currentAppVersionProvider = Provider<String>((ref) {
  return '1.0.0';
});

/// Tracks whether a cold-start update check has already executed in this session.
/// Guarantees that the OTA check dialog will only be presented once per cold launch.
final hasCheckedColdStartProvider = StateProvider<bool>((ref) {
  return false;
});

/// Future provider to manually or programmatically check for an update.
final checkForUpdateProvider = FutureProvider.autoDispose<AppReleaseInfo?>((ref) async {
  final repo = ref.watch(updaterRepositoryProvider);
  final currentVersion = ref.watch(currentAppVersionProvider);
  return await repo.checkForUpdate(currentVersion);
});
