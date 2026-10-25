import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../stream/presentation/providers/stream_providers.dart';
import '../../data/download_service.dart';

/// Provider for DownloadService.
final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  final prefs = ref.watch(sharedPreferencesAsyncProvider).valueOrNull;
  return DownloadService(prefs: prefs);
});
