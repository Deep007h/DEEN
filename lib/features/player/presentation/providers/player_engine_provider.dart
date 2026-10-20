import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/engine/media_kit_playback_engine.dart';
import '../../data/engine/mock_playback_engine.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Factory provider for creating [VideoPlaybackEngine] instances.
/// Gracefully falls back to [MockPlaybackEngine] in headless test environments.
final videoPlaybackEngineFactoryProvider =
    Provider<Future<VideoPlaybackEngine> Function()>((ref) {
  return () async {
    try {
      return await MediaKitPlaybackEngine.create();
    } catch (_) {
      return MockPlaybackEngine();
    }
  };
});
