import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/data/engine/mock_playback_engine.dart';
import 'package:anime_stream/features/player/domain/engine/video_playback_engine.dart';

void main() {
  group('MockPlaybackEngine', () {
    late MockPlaybackEngine engine;

    setUp(() {
      engine = MockPlaybackEngine(
        initialPosition: const Duration(seconds: 10),
        initialDuration: const Duration(minutes: 24),
      );
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('initializes with given position and duration', () {
      expect(engine.position, const Duration(seconds: 10));
      expect(engine.duration, const Duration(minutes: 24));
      expect(engine.isPlaying, isTrue);
      expect(engine.playbackRate, 1.0);
      expect(engine.volume, 1.0);
      expect(engine.aspectRatioMode, VideoAspectRatioMode.fit);
    });

    test('open sets url and triggers streams', () async {
      final positionUpdates = <Duration>[];
      final sub = engine.positionStream.listen(positionUpdates.add);

      await engine.open(
        'https://example.com/test.m3u8',
        startPosition: const Duration(seconds: 45),
      );

      expect(engine.currentUrl, 'https://example.com/test.m3u8');
      expect(engine.position, const Duration(seconds: 45));
      expect(positionUpdates.last, const Duration(seconds: 45));
      await sub.cancel();
    });

    test('play, pause, and togglePlay update state and streams', () async {
      final playingEvents = <bool>[];
      final sub = engine.isPlayingStream.listen(playingEvents.add);

      await engine.pause();
      expect(engine.isPlaying, isFalse);
      expect(playingEvents.last, isFalse);

      await engine.play();
      expect(engine.isPlaying, isTrue);
      expect(playingEvents.last, isTrue);

      await engine.togglePlay();
      expect(engine.isPlaying, isFalse);
      expect(playingEvents.last, isFalse);

      await sub.cancel();
    });

    test('seek clamps within valid duration', () async {
      await engine.seek(const Duration(seconds: 120));
      expect(engine.position, const Duration(seconds: 120));

      await engine.seek(const Duration(seconds: -50));
      expect(engine.position, Duration.zero);

      await engine.seek(const Duration(hours: 2));
      expect(engine.position, const Duration(minutes: 24));
    });

    test('rate, volume, and aspect ratio updates', () async {
      await engine.setRate(1.5);
      expect(engine.playbackRate, 1.5);

      await engine.setVolume(0.7);
      expect(engine.volume, 0.7);

      engine.setAspectRatioMode(VideoAspectRatioMode.sixteenNine);
      expect(engine.aspectRatioMode, VideoAspectRatioMode.sixteenNine);
    });
  });
}
