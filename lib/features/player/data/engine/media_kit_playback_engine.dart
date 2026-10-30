import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide SubtitleTrack;
import 'package:media_kit/media_kit.dart' as mk show SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import '../../../stream/data/hls/local_hls_server.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';
import '../subtitles/subtitle_cue.dart';
import '../subtitles/subtitle_parser.dart';

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
  SubtitleTrack _selectedSubtitleTrack = SubtitleTrack.off();
  SubtitleSettings _subtitleSettings = const SubtitleSettings();
  Map<String, String>? _lastStreamHeaders;
  File? _cachedSubtitleFile;

  List<SubtitleCue> _activeCues = [];
  final _subtitleController = StreamController<List<String>>.broadcast();
  List<String> _currentSubtitle = const [];

  MediaKitPlaybackEngine._(this._player, this._videoController) {
    _subscriptions.add(_player.stream.tracks.listen((tracks) {
      _applyPreferredTracks(tracks);
    }));
    _subscriptions.add(_player.stream.position.listen((pos) {
      _updateSubtitlesAtPosition(pos);
    }));
    _subscriptions.add(_player.stream.subtitle.listen((mpvLines) {
      if (_activeCues.isEmpty) {
        final filtered = mpvLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        if (!_listEquals(_currentSubtitle, filtered)) {
          _currentSubtitle = filtered;
          if (!_subtitleController.isClosed) {
            _subtitleController.add(filtered);
          }
        }
      }
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
  Stream<List<String>> get subtitleStream => _subtitleController.stream;

  @override
  List<String> get currentSubtitle => _currentSubtitle;

  @override
  SubtitleSettings get subtitleSettings => _subtitleSettings;

  @override
  void setSubtitleSettings(SubtitleSettings settings) {
    _subtitleSettings = settings;
    try {
      final platform = _player.platform as dynamic;
      platform?.setProperty('sub-delay', settings.delaySeconds.toString());
    } catch (_) {}
    _updateSubtitlesAtPosition(_player.state.position);
  }

  void _updateSubtitlesAtPosition(Duration pos) {
    if (_activeCues.isEmpty || _selectedSubtitleTrack.isOff) {
      if (_currentSubtitle.isNotEmpty) {
        _currentSubtitle = const [];
        if (!_subtitleController.isClosed) {
          _subtitleController.add(const []);
        }
      }
      return;
    }

    final delay = _subtitleSettings.delaySeconds;
    final matching = _activeCues.where((c) => c.matches(pos, delaySeconds: delay)).toList();
    final lines = matching.isNotEmpty ? matching.expand((c) => c.lines).toList() : const <String>[];

    if (!_listEquals(_currentSubtitle, lines)) {
      _currentSubtitle = lines;
      if (!_subtitleController.isClosed) {
        _subtitleController.add(lines);
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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

    final isLocal = effectiveUrl.startsWith('/') || effectiveUrl.startsWith('file://');
    String playUrl = effectiveUrl;
    if (isHls && !isLocal && !effectiveUrl.contains('127.0.0.1')) {
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

    _lastStreamHeaders = effectiveHeaders;
    final media = Media(
      playUrl,
      httpHeaders: effectiveHeaders,
      start: startPosition,
    );
    await _player.open(media, play: true);
    print('[ENGINE_OPEN] _player.open finished with playUrl: $playUrl');

    if (!_selectedSubtitleTrack.isOff) {
      setSubtitleTrack(_selectedSubtitleTrack, headers: effectiveHeaders);
    }
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track, {Map<String, String>? headers}) async {
    _selectedSubtitleTrack = track;
    if (headers != null) {
      _lastStreamHeaders = headers;
    }

    try {
      if (track.isOff) {
        _cleanupCachedSubtitleFile();
        _activeCues = [];
        _currentSubtitle = const [];
        if (!_subtitleController.isClosed) {
          _subtitleController.add(const []);
        }
        await _player.setSubtitleTrack(mk.SubtitleTrack.no());
        return;
      }

      final url = track.url;
      if (url != null && url.isNotEmpty) {
        // 1. Direct local file (downloaded episode or cached)
        if (url.startsWith('/') || url.startsWith('file://')) {
          final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
          final file = File(path);
          if (file.existsSync()) {
            try {
              final content = await file.readAsString();
              _activeCues = SubtitleParser.parse(content);
              _updateSubtitlesAtPosition(_player.state.position);
            } catch (e) {
              print('[ENGINE_SUBTITLE_PARSE_ERR] $e');
            }
          }
          await _player.setSubtitleTrack(
            mk.SubtitleTrack.uri(
              file.uri.toString(),
              title: track.label,
              language: track.languageCode,
            ),
          );
          return;
        }

        // 2. Remote URL: download with upstream headers to eliminate 403 Forbidden
        if (url.startsWith('http://') || url.startsWith('https://')) {
          final localFile = await _downloadSubtitleToCache(url, headers ?? _lastStreamHeaders);
          if (localFile != null && localFile.existsSync()) {
            _cleanupCachedSubtitleFile();
            _cachedSubtitleFile = localFile;
            try {
              final content = await localFile.readAsString();
              _activeCues = SubtitleParser.parse(content);
              _updateSubtitlesAtPosition(_player.state.position);
            } catch (e) {
              print('[ENGINE_SUBTITLE_PARSE_ERR] $e');
            }
            await _player.setSubtitleTrack(
              mk.SubtitleTrack.uri(
                localFile.uri.toString(),
                title: track.label,
                language: track.languageCode,
              ),
            );
            return;
          }

          // Fallback to direct URI if download failed
          await _player.setSubtitleTrack(
            mk.SubtitleTrack.uri(
              url,
              title: track.label,
              language: track.languageCode,
            ),
          );
          return;
        }
      }

      // 3. Embedded track inside the media stream
      _activeCues = [];
      final availableSubs = _player.state.tracks.subtitle;
      final targetLang = track.languageCode.toLowerCase();
      final targetId = track.id.toLowerCase();
      final match = availableSubs.firstWhere(
        (t) {
          final lang = t.language?.toLowerCase() ?? '';
          final id = t.id.toLowerCase();
          final title = t.title?.toLowerCase() ?? '';
          return lang == targetLang ||
              id == targetId ||
              (targetLang != 'off' && (lang.startsWith(targetLang) || title.contains(targetLang)));
        },
        orElse: () => mk.SubtitleTrack.auto(),
      );

      await _player.setSubtitleTrack(match);
    } catch (e) {
      print('[ENGINE_SET_SUBTITLE_ERR] $e');
    }
  }

  Future<File?> _downloadSubtitleToCache(String url, Map<String, String>? headers) async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
        ..connectionTimeout = const Duration(seconds: 8);

      final req = await client.getUrl(Uri.parse(url));
      final effectiveHeaders = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Referer': 'https://megavid.buzz/',
        'Origin': 'https://megavid.buzz',
        ...?headers,
      };
      effectiveHeaders.forEach((k, v) {
        req.headers.set(k, v);
      });

      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final bytes = await resp.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        if (bytes.isNotEmpty) {
          final tempDir = Directory.systemTemp;
          final ext = url.toLowerCase().contains('.ass') ? 'ass' : (url.toLowerCase().contains('.srt') ? 'srt' : 'vtt');
          final file = File('${tempDir.path}/deen_sub_${DateTime.now().millisecondsSinceEpoch}.$ext');
          await file.writeAsBytes(bytes);
          return file;
        }
      }
    } catch (e) {
      print('[ENGINE_SUBTITLE_DOWNLOAD_ERR] $e');
    }
    return null;
  }

  void _cleanupCachedSubtitleFile() {
    try {
      if (_cachedSubtitleFile != null && _cachedSubtitleFile!.existsSync()) {
        _cachedSubtitleFile!.deleteSync();
        _cachedSubtitleFile = null;
      }
    } catch (_) {}
  }

  void _applyPreferredTracks(Tracks tracks) {
    if (!_selectedSubtitleTrack.isOff && tracks.subtitle.length > 1) {
      if (_selectedSubtitleTrack.url == null || _selectedSubtitleTrack.url!.isEmpty) {
        final targetLang = _selectedSubtitleTrack.languageCode.toLowerCase();
        final match = tracks.subtitle.firstWhere(
          (t) {
            final lang = t.language?.toLowerCase() ?? '';
            final id = t.id.toLowerCase();
            return lang == targetLang || id == _selectedSubtitleTrack.id;
          },
          orElse: () => tracks.subtitle.first,
        );
        if (match != _player.state.track.subtitle) {
          _player.setSubtitleTrack(match);
        }
      }
    }
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
          } else if (target == 'hi') {
            return lang.startsWith('hi') || lang == 'hin' || title.contains('hindi');
          } else if (target == 'ta') {
            return lang.startsWith('ta') || lang == 'tam' || title.contains('tamil');
          } else if (target == 'te') {
            return lang.startsWith('te') || lang == 'tel' || title.contains('telugu');
          } else if (target == 'kn') {
            return lang.startsWith('kn') || lang == 'kan' || title.contains('kannada');
          } else if (target == 'ml') {
            return lang.startsWith('ml') || lang == 'mal' || title.contains('malayalam');
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
  Future<void> stop() async {
    await _player.stop();
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
      subtitleViewConfiguration: const SubtitleViewConfiguration(visible: false),
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
    _cleanupCachedSubtitleFile();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _aspectRatioController.close();
    await _subtitleController.close();
    await _player.dispose();
  }
}
