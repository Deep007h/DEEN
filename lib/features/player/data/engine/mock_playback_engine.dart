import 'dart:async';
import 'package:flutter/material.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Test and fallback implementation of [VideoPlaybackEngine].
class MockPlaybackEngine implements VideoPlaybackEngine {
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 24);
  Duration _buffer = const Duration(minutes: 5);
  bool _isPlaying = true;
  bool _isBuffering = false;
  double _playbackRate = 1.0;
  double _volume = 1.0;
  VideoAspectRatioMode _aspectRatioMode = VideoAspectRatioMode.fit;
  SubtitleTrack _currentSubtitleTrack = SubtitleTrack.off();

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _isBufferingController = StreamController<bool>.broadcast();
  final _playbackRateController = StreamController<double>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String?>.broadcast();
  final _aspectRatioModeController = StreamController<VideoAspectRatioMode>.broadcast();

  String? currentUrl;
  Map<String, String>? currentHeaders;
  bool isDisposed = false;

  MockPlaybackEngine({
    Duration initialPosition = Duration.zero,
    Duration initialDuration = const Duration(minutes: 24),
    Duration initialBuffer = const Duration(minutes: 5),
    bool autoPlay = true,
  })  : _position = initialPosition,
        _duration = initialDuration,
        _buffer = initialBuffer,
        _isPlaying = autoPlay;

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Duration get buffer => _buffer;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  bool get isBuffering => _isBuffering;

  @override
  Stream<bool> get isBufferingStream => _isBufferingController.stream;

  @override
  double get playbackRate => _playbackRate;

  @override
  Stream<double> get playbackRateStream => _playbackRateController.stream;

  @override
  double get volume => _volume;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Stream<bool> get completedStream => _completedController.stream;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  VideoAspectRatioMode get aspectRatioMode => _aspectRatioMode;

  @override
  Stream<VideoAspectRatioMode> get aspectRatioModeStream =>
      _aspectRatioModeController.stream;

  @override
  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    currentUrl = url;
    currentHeaders = headers;
    if (startPosition != null) {
      _position = startPosition;
    }
    _isPlaying = true;
    _isPlayingController.add(_isPlaying);
    _positionController.add(_position);
    _durationController.add(_duration);
    _bufferController.add(_buffer);
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _isPlayingController.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _isPlayingController.add(false);
  }

  @override
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> seek(Duration target) async {
    _position = target.clamp(Duration.zero, _duration);
    _positionController.add(_position);
  }

  @override
  Future<void> setRate(double rate) async {
    _playbackRate = rate;
    _playbackRateController.add(_playbackRate);
  }

  @override
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    _volumeController.add(_volume);
  }

  @override
  void setAspectRatioMode(VideoAspectRatioMode mode) {
    _aspectRatioMode = mode;
    _aspectRatioModeController.add(_aspectRatioMode);
  }

  SubtitleTrack get currentSubtitleTrack => _currentSubtitleTrack;

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    _currentSubtitleTrack = track;
  }

  /// Helper to simulate position updates in tests.
  void simulatePosition(Duration newPosition) {
    _position = newPosition.clamp(Duration.zero, _duration);
    _positionController.add(_position);
  }

  /// Helper to simulate duration changes.
  void simulateDuration(Duration newDuration) {
    _duration = newDuration;
    _durationController.add(_duration);
  }

  /// Helper to simulate buffer changes.
  void simulateBuffer(Duration newBuffer) {
    _buffer = newBuffer;
    _bufferController.add(_buffer);
  }

  /// Helper to simulate buffering state changes.
  void simulateBuffering(bool isBuffering) {
    _isBuffering = isBuffering;
    _isBufferingController.add(_isBuffering);
  }

  /// Helper to simulate media completion.
  void simulateCompletion() {
    _completedController.add(true);
  }

  /// Helper to simulate playback errors.
  void simulateError(String? error) {
    _errorController.add(error);
  }

  String? preferredAudioLanguage;
  String? preferredQualityPreference;

  @override
  void setTrackPreferences({String? audioLanguage, String? qualityPreference}) {
    preferredAudioLanguage = audioLanguage;
    preferredQualityPreference = qualityPreference;
  }

  @override
  Widget buildVideoView({Key? key}) {
    return Container(
      key: key ?? const ValueKey('mock_video_surface'),
      color: Colors.black,
      child: Center(
        child: Text(
          'Mock Video Engine\nAspect: ${_aspectRatioMode.label}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _isPlayingController.close();
    await _isBufferingController.close();
    await _playbackRateController.close();
    await _volumeController.close();
    await _completedController.close();
    await _errorController.close();
    await _aspectRatioModeController.close();
  }
}

extension on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
