import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide SubtitleTrack;
import 'package:media_kit/media_kit.dart' as mk show SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import '../../../stream/data/hls/local_hls_server.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Real video playback engine powered by [media_kit] and libmpv hardware decoding.
class MediaKitPlaybackEngine implements VideoPlaybackEngine {
  final Player _player;
  final VideoController _videoController;

  VideoAspectRatioMode _aspectRatioMode = VideoAspectRatioMode.fit;
  final _aspectRatioController = StreamController<VideoAspectRatioMode>.broadcast();

  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;
  String? _preferredAudioLanguage;
  String? _preferredQuality;

  MediaKitPlaybackEngine._(this._player, this._videoController) {
    _subscriptions.add(_player.stream.tracks.listen((tracks) {
      _applyPreferredTracks(tracks);
    }));
  }

  /// Creates and initializes a [MediaKitPlaybackEngine].
  static Future<MediaKitPlaybackEngine> create() async {
    MediaKit.ensureInitialized();
    final player = Player(
      configuration: const PlayerConfiguration(
        pitch: true,
        logLevel: MPVLogLevel.warn,
        bufferSize: 32 * 1024 * 1024,
      ),
    );
    final videoController = VideoController(player);
    final engine = MediaKitPlaybackEngine._(
      player,
      videoController,
    );
    engine._subscriptions.addAll([
      player.stream.error.listen((err) => print('[ENGINE_ERROR] $err')),
      player.stream.log.listen((log) => print('[ENGINE_MPV] [${log.prefix}] ${log.text}')),
      player.stream.buffering.listen((b) => print('[ENGINE_BUFFERING] $b')),
      player.stream.duration.listen((d) => print('[ENGINE_DURATION] ${d.inSeconds}s')),
      player.stream.position.listen((p) => print('[ENGINE_POSITION] ${p.inSeconds}s')),
    ]);
    return engine;
  }

  @override
  Duration get position => _player.state.position;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Duration get duration => _player.state.duration;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Duration get buffer => _player.state.buffer;

  @override
  Stream<Duration> get bufferStream => _player.stream.buffer;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  Stream<bool> get isPlayingStream => _player.stream.playing;

  @override
  bool get isBuffering => _player.state.buffering;

  @override
  Stream<bool> get isBufferingStream => _player.stream.buffering;

  @override
  double get playbackRate => _player.state.rate;

  @override
  Stream<double> get playbackRateStream => _player.stream.rate;

  @override
  double get volume => _player.state.volume / 100.0;

  @override
  Stream<double> get volumeStream =>
      _player.stream.volume.map((vol) => vol / 100.0);

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Stream<String?> get errorStream => _player.stream.error;

  @override
  VideoAspectRatioMode get aspectRatioMode => _aspectRatioMode;

  @override
  Stream<VideoAspectRatioMode> get aspectRatioModeStream =>
      _aspectRatioController.stream;

  @override
  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    final urlLower = url.toLowerCase();
    final isHls = urlLower.contains('.m3u8') || urlLower.contains('/hls/');
    final effectiveUrl = isHls && !url.contains('.m3u8') ? '$url#.m3u8' : url;
    final ua = headers?['User-Agent'] ?? headers?['user-agent'] ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    effectiveHeaders.putIfAbsent('Referer', () => 'https://megavid.buzz/');
    effectiveHeaders.putIfAbsent('Origin', () => 'https://megavid.buzz');
    effectiveHeaders.putIfAbsent('User-Agent', () => ua);

    print('[ENGINE_OPEN] Opening effectiveUrl: $effectiveUrl, startPosition: $startPosition');
    print('[ENGINE_OPEN] Headers: $effectiveHeaders');

    // Route HLS streams through in-app LocalHlsServer to guarantee headers, retry transient CDN blocks, and bypass demuxer MIME issues
    String playUrl = effectiveUrl;
    if (isHls && !effectiveUrl.contains('127.0.0.1')) {
      try {
        LocalHlsServer.instance.clearSessions();
        playUrl = await LocalHlsServer.instance.proxyStream(
          url.split('#').first.trim(),
          headers: effectiveHeaders,
        );
        print('[ENGINE_OPEN] Proxied via LocalHlsServer: $playUrl');
      } catch (e) {
        print('[ENGINE_OPEN] LocalHlsServer proxy failed, using direct URL: $e');
        playUrl = effectiveUrl;
      }
    }

    try {
      final platform = _player.platform as dynamic;
      final properties = <Future<dynamic>>[
        platform?.setProperty('hwdec', 'auto'),
        platform?.setProperty('keep-open', 'yes'), // Prevent MPV from blacking out or closing on EOF
      ];

      if (isHls) {
        properties.addAll([
          platform?.setProperty('demuxer-lavf-format', 'hls'),
          platform?.setProperty('demuxer-lavf-probesize', '65536'), // Fast 64 KB probe
          platform?.setProperty('demuxer-lavf-analyzeduration', '0.1'), // Fast 0.1s analyze duration for instant start
          platform?.setProperty(
            'demuxer-lavf-o',
            'allowed_segment_extensions=ALL,allowed_extensions=ALL,extension_picky=0,seg_max_retry=5,reconnect_streamed=1,reconnect_delay_max=4,reconnect_on_http_error=403\\,404\\,5xx,fflags=+genpts+discardcorrupt+fastseek',
          ),
          platform?.setProperty('correct-pts', 'yes'), // Normalize timestamps across HLS discontinuities
          platform?.setProperty('demuxer-readahead-secs', '30'), // Fast 30s buffer ahead
          platform?.setProperty('cache-secs', '60'),
          platform?.setProperty('cache-pause-initial', 'no'), // Do not pause to fill cache before starting
          platform?.setProperty('cache-pause-wait', '0'), // Auto-resume immediately without waiting to buffer
          platform?.setProperty('demuxer-max-bytes', '67108864'), // 64 MB demuxer memory buffer
          platform?.setProperty('demuxer-lavf-buffersize', '262144'), // 256 KB buffer for immediate first frame
          platform?.setProperty('prefetch-playlist', 'yes'),
          platform?.setProperty('network-timeout', '10'),
          platform?.setProperty('force-seekable', 'yes'),
        ]);
      } else {
        properties.addAll([
          platform?.setProperty('demuxer-lavf-format', ''),
          platform?.setProperty(
            'demuxer-lavf-o',
            'allowed_segment_extensions=ALL,allowed_extensions=ALL,extension_picky=0,reconnect_streamed=1,reconnect_delay_max=4,fflags=+genpts+discardcorrupt+fastseek',
          ),
          platform?.setProperty('correct-pts', 'yes'),
        ]);
      }

      final ref = headers?['Referer'] ?? headers?['referer'] ?? 'https://megavid.buzz/';
      properties.add(platform?.setProperty('referrer', ref));
      properties.add(platform?.setProperty('user-agent', ua));

      await Future.wait(properties.whereType<Future<dynamic>>());
      print('[ENGINE_OPEN] Configured platform properties successfully');
    } catch (e, st) {
      print('[ENGINE_CONFIG_ERROR] Failed to configure platform properties: $e\n$st');
    }

    final media = Media(
      playUrl,
      httpHeaders: effectiveHeaders,
      start: startPosition,
    );
    await _player.open(media, play: true);
    print('[ENGINE_OPEN] _player.open finished with playUrl: $playUrl');
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    try {
      if (track.isOff || track.url == null || track.url!.isEmpty) {
        await _player.setSubtitleTrack(mk.SubtitleTrack.no());
      } else {
        await _player.setSubtitleTrack(
          mk.SubtitleTrack.uri(
            track.url!,
            title: track.label,
            language: track.languageCode,
          ),
        );
      }
    } catch (_) {}
  }

  void _applyPreferredTracks(Tracks tracks) {
    if (_preferredAudioLanguage != null && tracks.audio.length > 1) {
      final target = _preferredAudioLanguage!.toLowerCase();
      final match = tracks.audio.firstWhere(
        (t) {
          final lang = t.language?.toLowerCase() ?? '';
          final title = t.title?.toLowerCase() ?? '';
          if (target == 'en') {
            return lang.startsWith('en') || title.contains('eng') || title.contains('dub');
          } else if (target == 'ja') {
            return lang.startsWith('ja') || title.contains('jap') || title.contains('orig') || title.contains('sub');
          }
          return lang.startsWith(target) || title.contains(target);
        },
        orElse: () => tracks.audio.first,
      );
      if (match != _player.state.track.audio) {
        _player.setAudioTrack(match);
      }
    }

    if (_preferredQuality != null && tracks.video.length > 1) {
      final targetHeight = int.tryParse(_preferredQuality!.replaceAll(RegExp(r'\D'), ''));
      if (targetHeight != null) {
        final nonAuto = tracks.video.where((t) => t.h != null && t.h! > 0).toList();
        if (nonAuto.isNotEmpty) {
          nonAuto.sort((a, b) => (a.h! - targetHeight).abs().compareTo((b.h! - targetHeight).abs()));
          final best = nonAuto.first;
          if (best != _player.state.track.video) {
            _player.setVideoTrack(best);
          }
        }
      }
    }
  }

  @override
  void setTrackPreferences({String? audioLanguage, String? qualityPreference}) {
    _preferredAudioLanguage = audioLanguage;
    _preferredQuality = qualityPreference;
    _applyPreferredTracks(_player.state.tracks);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> togglePlay() async {
    await _player.playOrPause();
  }

  @override
  Future<void> seek(Duration position) async {
    final dur = duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (dur > Duration.zero && position > dur ? dur : position);
    await _player.seek(clamped);
  }

  @override
  Future<void> setRate(double rate) async {
    await _player.setRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    // MediaKit volume is 0.0 to 100.0
    await _player.setVolume((volume.clamp(0.0, 1.0) * 100.0));
  }

  @override
  void setAspectRatioMode(VideoAspectRatioMode mode) {
    _aspectRatioMode = mode;
    _aspectRatioController.add(_aspectRatioMode);
  }

  @override
  Widget buildVideoView({Key? key}) {
    BoxFit fit = BoxFit.contain;
    double? fixedAspect;

    switch (_aspectRatioMode) {
      case VideoAspectRatioMode.fit:
        fit = BoxFit.contain;
        break;
      case VideoAspectRatioMode.fill:
        fit = BoxFit.cover;
        break;
      case VideoAspectRatioMode.sixteenNine:
        fixedAspect = 16.0 / 9.0;
        fit = BoxFit.fill;
        break;
      case VideoAspectRatioMode.fourThree:
        fixedAspect = 4.0 / 3.0;
        fit = BoxFit.fill;
        break;
    }

    Widget videoWidget = Video(
      key: key ?? const ValueKey('mediakit_video_surface'),
      controller: _videoController,
      controls: NoVideoControls,
      fit: fit,
    );

    if (fixedAspect != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: fixedAspect,
          child: videoWidget,
        ),
      );
    }

    return videoWidget;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _aspectRatioController.close();
    await _player.dispose();
  }
}
