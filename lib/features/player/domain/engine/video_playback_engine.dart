import 'package:flutter/widgets.dart';
import '../../../stream/domain/models/subtitle_track.dart';

/// Display aspect ratio modes for the video surface.
enum VideoAspectRatioMode {
  fit('Fit (Letterbox)'),
  fill('Fill (Crop)'),
  sixteenNine('16:9'),
  fourThree('4:3');

  final String label;
  const VideoAspectRatioMode(this.label);
}

/// Abstract contract for video playback, isolating platform-specific video engines
/// (MediaKit / native MPV) from player UI and business logic.
abstract class VideoPlaybackEngine {
  /// Current playback position.
  Duration get position;

  /// Stream of playback position updates.
  Stream<Duration> get positionStream;

  /// Total duration of the loaded media.
  Duration get duration;

  /// Stream of total duration updates.
  Stream<Duration> get durationStream;

  /// Current buffered extent.
  Duration get buffer;

  /// Stream of buffered extent updates.
  Stream<Duration> get bufferStream;

  /// Whether video is currently playing.
  bool get isPlaying;

  /// Stream of playing state changes.
  Stream<bool> get isPlayingStream;

  /// Whether video is currently buffering.
  bool get isBuffering;

  /// Stream of buffering state changes.
  Stream<bool> get isBufferingStream;

  /// Current playback rate multiplier (e.g. 1.0, 1.5, 2.0).
  double get playbackRate;

  /// Stream of playback rate changes.
  Stream<double> get playbackRateStream;

  /// Current volume level (0.0 to 100.0 or 0.0 to 1.0).
  double get volume;

  /// Stream of volume changes.
  Stream<double> get volumeStream;

  /// Stream signaling media playback has ended.
  Stream<bool> get completedStream;

  /// Stream signaling media playback errors.
  Stream<String?> get errorStream;

  /// Current aspect ratio mode.
  VideoAspectRatioMode get aspectRatioMode;

  /// Stream of aspect ratio mode changes.
  Stream<VideoAspectRatioMode> get aspectRatioModeStream;

  /// Opens and starts playback of a media source URL.
  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  });

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback, clears buffers, and resets position.
  Future<void> stop();

  /// Toggles between play and pause.
  Future<void> togglePlay();

  /// Seeks to a specific target position.
  Future<void> seek(Duration position);

  /// Sets the playback rate multiplier.
  Future<void> setRate(double rate);

  /// Sets audio volume level (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Sets video aspect ratio display mode.
  void setAspectRatioMode(VideoAspectRatioMode mode);

  /// Selects or disables subtitle track.
  Future<void> setSubtitleTrack(SubtitleTrack track);

  /// Sets track preferences for automatic selection when media streams load.
  void setTrackPreferences({String? audioLanguage, String? qualityPreference});

  /// Builds the visual video rendering widget.
  Widget buildVideoView({Key? key});

  /// Releases resources.
  Future<void> dispose();
}
