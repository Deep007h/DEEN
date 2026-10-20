import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide StreamProvider;
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../stream/domain/models/audio_language.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../../stream/domain/orchestration/stream_orchestrator.dart';
import '../../../stream/domain/resolvers/embed_stream_resolver.dart';
import '../../../stream/presentation/providers/stream_providers.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';
import '../../../settings/data/repositories/app_settings_repository.dart';
import '../../data/repositories/playback_history_repository.dart';
import '../../domain/engine/video_playback_engine.dart';
import '../../domain/gestures/player_gesture_math.dart';
import '../providers/player_engine_provider.dart';
import '../widgets/episode_selector_sheet.dart';
import '../widgets/next_episode_card.dart';
import '../widgets/player_bottom_bar.dart';
import '../widgets/player_center_controls.dart';
import '../widgets/player_hud_overlays.dart';
import '../widgets/player_settings_sheet.dart';
import '../widgets/player_top_bar.dart';
import '../widgets/skip_intro_button.dart';
import '../widgets/web_embed_player_view.dart';

/// Full-screen landscape video player matching the reference design:
/// - Letterboxed centered video canvas
/// - Auto-hiding custom controls overlay (top bar, center controls, bottom seek bar)
/// - Pure Dart gesture math integration (accumulating double-taps, hold-for-2x, scrub, brightness/volume)
/// - Landscape sliding side panel for Quality, Audio, Subtitles, Speed, Aspect ratio, and Sources
/// - Auto-resume, periodic progress saving, intro skip chip, and next-episode countdown
class PlayerScreen extends ConsumerStatefulWidget {
  final int animeId;
  final int episodeNumber;
  final String? preferredProviderId;
  final bool? defaultToEmbed;

  const PlayerScreen({
    super.key,
    this.animeId = 400602,
    this.episodeNumber = 1,
    this.preferredProviderId,
    this.defaultToEmbed,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  VideoPlaybackEngine? _engine;
  bool _isEngineReady = false;

  final List<StreamSubscription> _engineSubscriptions = [];

  // Playback state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;
  bool _isPlaying = true;
  bool _isBuffering = false;
  double _playbackRate = 1.0;
  double _volume = 1.0;
  double _brightness = 0.5;
  VideoAspectRatioMode _aspectRatioMode = VideoAspectRatioMode.fit;
  SubtitleSettings _subtitleSettings = const SubtitleSettings();
  bool _danmakuEnabled = true;

  // UI state & auto-hide
  bool _controlsVisible = true;
  Timer? _controlsHideTimer;
  Timer? _progressSaveTimer;

  // Next episode auto-play countdown
  bool _showNextEpisodeCountdown = false;
  int _nextEpisodeCountdownSeconds = 5;
  Timer? _countdownTimer;

  // Gestures
  final PlayerGestureMath _gestureMath = PlayerGestureMath();
  final DoubleTapAccumulator _doubleTapAccumulator = DoubleTapAccumulator();

  Timer? _singleTapTimer;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  bool _isHolding2x = false;
  double _rateBeforeHold = 1.0;

  bool _isScrubbing = false;
  bool _isUserSeeking = false;
  Duration _scrubBasePosition = Duration.zero;
  Duration _scrubTargetPosition = Duration.zero;
  double _scrubStartX = 0.0;

  bool _showVerticalHud = false;
  bool _isVerticalHudVolume = true;
  ScreenHalf? _verticalDragHalf;
  double _verticalDragStartY = 0.0;
  double _verticalDragStartVal = 0.0;
  Timer? _verticalHudTimer;

  int? _doubleTapOffsetSeconds;
  VideoAspectRatioMode _currentAspectMode = VideoAspectRatioMode.fit;
  Timer? _doubleTapBadgeTimer;

  // Side panels
  bool _showSettingsSheet = false;
  bool _showEpisodeSheet = false;

  // Screen lock system
  bool _isLocked = false;
  bool _showUnlockButton = false;
  Timer? _unlockButtonTimer;

  // Resume toast
  String? _resumeToastMessage;
  Timer? _resumeToastTimer;
  bool _hasCheckedResume = false;
  String? _currentlyLoadedUrl;
  SubtitleTrack? _currentlyLoadedSubtitle;
  Duration? _languageSwitchSeekTarget;
  bool _isSwitchingAudio = false;
  late PlaybackHistoryRepository _historyRepo;

  // Watchdog for auto-recovering timestamp stalls and stream discontinuities
  Timer? _stallWatchdogTimer;
  Duration _lastStallPosition = Duration.zero;
  int _stallStuckCount = 0;
  int _bufferingStuckSeconds = 0;

  // Embed player mode toggle (default: true for APK/real devices)
  late bool _useEmbedPlayer;

  StreamResolutionParams get _params => StreamResolutionParams(
        animeId: widget.animeId,
        episodeNumber: widget.episodeNumber,
        preferredProviderId: widget.preferredProviderId,
      );

  @override
  void initState() {
    super.initState();
    _useEmbedPlayer = widget.defaultToEmbed ?? false;
    _historyRepo = ref.read(playbackHistoryRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);

    // Lock to landscape & hide system bars
    _lockLandscape();

    // Prevent screen sleeping
    _enableWakelock();

    // Initialize engine & periodic progress saving
    _initEngine();
    _startProgressSavingTimer();
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _enableWakelock() {
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  void _disableWakelock() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _initEngine() async {
    final engineFactory = ref.read(videoPlaybackEngineFactoryProvider);
    final engine = await engineFactory();
    if (!mounted) {
      await engine.dispose();
      return;
    }

    _engine = engine;
    _isEngineReady = true;

    final settings = ref.read(appSettingsProvider);
    final prefAudioCode = settings.defaultAudioLanguage.toLowerCase().contains('eng') ? 'en' : 'ja';
    engine.setTrackPreferences(
      audioLanguage: prefAudioCode,
      qualityPreference: settings.defaultQuality,
    );

    _engineSubscriptions.add(engine.positionStream.listen((pos) {
      if (!mounted) return;
      if (_isScrubbing || _isUserSeeking) return; // Prevent overwriting user's active drag/scrub!
      setState(() {
        _position = pos;
      });
      _checkEpisodeEndCountdown(pos, _duration);
    }));

    _engineSubscriptions.add(engine.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() {
        _duration = dur;
      });

      // Handle seamless position restoration on language switch
      if (_languageSwitchSeekTarget != null && _languageSwitchSeekTarget! > Duration.zero) {
        final target = _languageSwitchSeekTarget!;
        _languageSwitchSeekTarget = null;
        _hasCheckedResume = true;
        _engine?.seek(target);
        if (_isSwitchingAudio) {
          final minutes = target.inMinutes.remainder(60).toString().padLeft(2, '0');
          final seconds = target.inSeconds.remainder(60).toString().padLeft(2, '0');
          final timeStr = target.inHours > 0 ? '${target.inHours}:$minutes:$seconds' : '$minutes:$seconds';
          setState(() {
            _isSwitchingAudio = false;
            _resumeToastMessage = 'Audio switched · Resumed at $timeStr';
          });
          _resumeToastTimer?.cancel();
          _resumeToastTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _resumeToastMessage = null);
          });
        }
      } else if (dur > const Duration(seconds: 10) && !_hasCheckedResume) {
        _checkAndApplyResume(dur);
      }
    }));

    _engineSubscriptions.add(engine.bufferStream.listen((buf) {
      if (!mounted) return;
      setState(() {
        _buffer = buf;
      });
    }));

    _engineSubscriptions.add(engine.isPlayingStream.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    }));

    _engineSubscriptions.add(engine.isBufferingStream.listen((buffering) {
      if (!mounted) return;
      setState(() {
        _isBuffering = buffering;
      });
    }));

    _engineSubscriptions.add(engine.playbackRateStream.listen((rate) {
      if (!mounted) return;
      setState(() {
        _playbackRate = rate;
      });
    }));

    _engineSubscriptions.add(engine.completedStream.listen((completed) {
      if (!mounted) return;
      if (completed) {
        // Prevent premature episode advance from stream hiccups, audio switches, or short EOFs
        if (!_isSwitchingAudio &&
            _languageSwitchSeekTarget == null &&
            _duration > const Duration(minutes: 1) &&
            _position >= _duration - const Duration(seconds: 25)) {
          _triggerNextEpisodeCountdown();
        } else if (!_isSwitchingAudio &&
            _languageSwitchSeekTarget == null &&
            _duration > const Duration(seconds: 30) &&
            _position < _duration - const Duration(seconds: 25)) {
          // Demuxer hit premature EOF or chunk stall before end of episode: auto-recover by nudging forward 1s
          _engine?.seek(_position + const Duration(seconds: 1));
          _engine?.play();
        } else if (!_isSwitchingAudio &&
            _languageSwitchSeekTarget == null &&
            !_isPlaying &&
            !_isBuffering &&
            !_isScrubbing &&
            (_duration <= const Duration(seconds: 30) || _position < const Duration(seconds: 15))) {
          // Stream truncated prematurely (e.g. 3-second broken proxy): auto-failover to backup server/provider
          setState(() {
            _resumeToastMessage = 'Stream interrupted · Switching to backup server...';
          });
          _resumeToastTimer?.cancel();
          _resumeToastTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _resumeToastMessage = null);
          });
          ref.read(activeStreamProvider(_params).notifier).retryWithNextProvider();
        }
      }
    }));

    _engineSubscriptions.add(engine.errorStream.listen((err) {
      if (!mounted || err == null) return;
      print('[ENGINE_ERROR_STREAM] Non-fatal MPV error reported: $err');
    }));

    _startStallWatchdog();
    setState(() {});
    _resetControlsHideTimer();

    final currentResult = ref.read(activeStreamProvider(_params)).valueOrNull;
    if (currentResult != null) {
      _openStreamIfReady(currentResult);
    }
  }

  void _openStreamIfReady(StreamResolutionResult result) {
    if (_useEmbedPlayer) {
      _engine?.pause();
      return;
    }
    if (!_isEngineReady || _engine == null) return;

    final activeUrl = (result.selectedQuality.url != null && result.selectedQuality.url!.isNotEmpty)
        ? result.selectedQuality.url!
        : result.selectedVariant.url;

    if (_currentlyLoadedUrl != activeUrl) {
      final isStreamSwitch = _currentlyLoadedUrl != null && _position > Duration.zero;
      if (isStreamSwitch) {
        _languageSwitchSeekTarget = _position;
        _isSwitchingAudio = true;
      }
      _currentlyLoadedUrl = activeUrl;
      _hasCheckedResume = false;
      final startPos = _position > Duration.zero ? _position : null;
      _engine!.setTrackPreferences(
        audioLanguage: result.selectedAudio.code,
        qualityPreference: result.selectedQuality.label,
      );
      _engine!.open(
        activeUrl,
        headers: result.selectedVariant.headers,
        startPosition: startPos,
      );
    } else {
      _engine!.setTrackPreferences(
        audioLanguage: result.selectedAudio.code,
        qualityPreference: result.selectedQuality.label,
      );
    }
    if (_currentlyLoadedSubtitle != result.selectedSubtitle) {
      _currentlyLoadedSubtitle = result.selectedSubtitle;
      _engine!.setSubtitleTrack(result.selectedSubtitle);
    }
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodeNumber != widget.episodeNumber ||
        oldWidget.animeId != widget.animeId ||
        oldWidget.preferredProviderId != widget.preferredProviderId) {
      _currentlyLoadedUrl = null;
      _currentlyLoadedSubtitle = null;
      _hasCheckedResume = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _bufferingStuckSeconds = 0;
      final currentResult = ref.read(activeStreamProvider(_params)).valueOrNull;
      if (currentResult != null) {
        _openStreamIfReady(currentResult);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _engine?.pause();
      _saveCurrentProgress();
    } else if (state == AppLifecycleState.resumed) {
      _lockLandscape();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreOrientations();
    _disableWakelock();

    _controlsHideTimer?.cancel();
    _progressSaveTimer?.cancel();
    _countdownTimer?.cancel();
    _singleTapTimer?.cancel();
    _verticalHudTimer?.cancel();
    _doubleTapBadgeTimer?.cancel();
    _resumeToastTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _unlockButtonTimer?.cancel();

    _saveCurrentProgress();

    for (final sub in _engineSubscriptions) {
      sub.cancel();
    }
    _engine?.dispose();

    super.dispose();
  }

  void _startStallWatchdog() {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _engine == null) return;

      // Detect continuous buffering stall (e.g. infinite loading animation)
      if (_isBuffering) {
        _bufferingStuckSeconds += 2;
        if (_bufferingStuckSeconds >= 28 && !_isScrubbing && !_isUserSeeking) {
          _bufferingStuckSeconds = 0;
          print('[BUFFERING_WATCHDOG] Buffer stall at 28s. Auto-reloading stream at ${_position.inSeconds}s...');
          setState(() {
            _resumeToastMessage = 'Buffering stall · Reconnecting stream...';
          });
          _resumeToastTimer?.cancel();
          _resumeToastTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _resumeToastMessage = null);
          });
          if (_currentlyLoadedUrl != null) {
            final reloadPos = _position > Duration.zero ? _position : null;
            _engine?.open(_currentlyLoadedUrl!, startPosition: reloadPos);
            _engine?.play();
          }
        }
        return;
      } else {
        _bufferingStuckSeconds = 0;
      }

      if (!_isPlaying || _isScrubbing || _isSwitchingAudio || _isUserSeeking) {
        _stallStuckCount = 0;
        _lastStallPosition = _position;
        return;
      }

      // If playback is active, but the position has stayed unchanged for > 12 seconds
      // and we are not near the end of the video
      if (_position > Duration.zero &&
          _duration > const Duration(seconds: 30) &&
          _position < _duration - const Duration(seconds: 15)) {
        if ((_position - _lastStallPosition).abs() < const Duration(milliseconds: 300)) {
          _stallStuckCount++;
          if (_stallStuckCount >= 6) {
            // Video has been frozen at this exact timestamp for 12 seconds!
            // Auto-nudge forward by 1 second to bypass the TS discontinuity / corrupt packet boundary
            _stallStuckCount = 0;
            final nudgeTarget = _position + const Duration(seconds: 1);
            _engine?.seek(nudgeTarget);
            _engine?.play();
          }
        } else {
          _stallStuckCount = 0;
          _lastStallPosition = _position;
        }
      } else {
        _stallStuckCount = 0;
        _lastStallPosition = _position;
      }
    });
  }

  void _startProgressSavingTimer() {
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentProgress();
    });
  }

  String? _cachedAnimeTitle;
  String? _cachedPosterUrl;

  Future<void> _saveCurrentProgress() async {
    if (_duration <= Duration.zero) return;

    if (mounted) {
      try {
        final animeDetail = ref.read(animeDetailProvider(widget.animeId)).value;
        if (animeDetail != null) {
          _cachedAnimeTitle = animeDetail.titles.preferredTitle();
          _cachedPosterUrl = animeDetail.posterUrl;
        }
      } catch (_) {}
    }

    final animeTitle = _cachedAnimeTitle ?? 'Anime #${widget.animeId}';
    final posterUrl = _cachedPosterUrl;

    await _historyRepo.savePlaybackProgress(
      widget.animeId,
      widget.episodeNumber,
      positionSeconds: _position.inSeconds,
      totalDurationSeconds: _duration.inSeconds,
      animeTitle: animeTitle,
      posterUrl: posterUrl,
    );
  }

  Future<void> _checkAndApplyResume(Duration totalDuration) async {
    if (_hasCheckedResume) return;
    _hasCheckedResume = true;

    final settings = ref.read(appSettingsProvider);
    if (settings.resumeBehavior == 'never') return;

    final savedSeconds = await _historyRepo.getEpisodePositionSeconds(
      widget.animeId,
      widget.episodeNumber,
    );

    if (savedSeconds != null && savedSeconds > 5) {
      // Don't resume if watched past 90%
      final fraction = totalDuration.inSeconds > 0
          ? savedSeconds / totalDuration.inSeconds
          : 0.0;
      if (fraction < 0.90) {
        final resumePos = Duration(seconds: savedSeconds);
        await _engine?.seek(resumePos);

        final minutes = resumePos.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = resumePos.inSeconds.remainder(60).toString().padLeft(2, '0');
        final timeStr = resumePos.inHours > 0
            ? '${resumePos.inHours}:$minutes:$seconds'
            : '$minutes:$seconds';

        setState(() {
          _resumeToastMessage = 'Resumed from $timeStr';
        });

        _resumeToastTimer?.cancel();
        _resumeToastTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _resumeToastMessage = null);
        });
      }
    }
  }

  void _checkEpisodeEndCountdown(Duration currentPos, Duration totalDur) {
    if (totalDur <= const Duration(minutes: 1)) return;
    final settings = ref.read(appSettingsProvider);
    if (!settings.autoplayNext) return;

    final remaining = (totalDur - currentPos).inSeconds;

    if (remaining <= 5 && remaining >= 0 && !_showNextEpisodeCountdown) {
      _triggerNextEpisodeCountdown();
    }
  }

  void _triggerNextEpisodeCountdown() {
    if (_showNextEpisodeCountdown) return;
    setState(() {
      _showNextEpisodeCountdown = true;
      _nextEpisodeCountdownSeconds = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_nextEpisodeCountdownSeconds <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        setState(() {
          _nextEpisodeCountdownSeconds--;
        });
      }
    });
  }

  void _cancelNextEpisodeCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _showNextEpisodeCountdown = false;
    });
  }

  void _playNextEpisode() {
    _countdownTimer?.cancel();
    _saveCurrentProgress();
    final nextEp = widget.episodeNumber + 1;
    context.pushReplacement('/player?animeId=${widget.animeId}&ep=$nextEp');
  }

  void _playPreviousEpisode() {
    if (widget.episodeNumber <= 1) return;
    _saveCurrentProgress();
    final prevEp = widget.episodeNumber - 1;
    context.pushReplacement('/player?animeId=${widget.animeId}&ep=$prevEp');
  }

  // Auto-hide controls
  void _resetControlsHideTimer() {
    _controlsHideTimer?.cancel();
    if (!_controlsVisible || _isScrubbing || _isHolding2x || _showSettingsSheet || _showEpisodeSheet) {
      return;
    }
    _controlsHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      if (_controlsVisible) {
        _showSettingsSheet = false;
        _showEpisodeSheet = false;
      }
    });
    if (_controlsVisible) {
      _resetControlsHideTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void _showLockedPrompt() {
    setState(() {
      _showUnlockButton = true;
    });
    _unlockButtonTimer?.cancel();
    _unlockButtonTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUnlockButton = false);
    });
  }

  void _lockPlayer() {
    setState(() {
      _isLocked = true;
      _controlsVisible = false;
      _showSettingsSheet = false;
      _showEpisodeSheet = false;
    });
    _controlsHideTimer?.cancel();
    _showLockedPrompt();
  }

  void _unlockPlayer() {
    setState(() {
      _isLocked = false;
      _showUnlockButton = false;
      _controlsVisible = true;
    });
    _unlockButtonTimer?.cancel();
    _resetControlsHideTimer();
  }

  // Gesture handling
  void _handleTapDown(TapDownDetails details, double screenWidth) {
    if (_isLocked) {
      _showLockedPrompt();
      return;
    }

    final now = DateTime.now();
    final isConsecutiveTap = _lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapAccumulator.accumulationWindow &&
        _lastTapPosition != null &&
        (details.localPosition - _lastTapPosition!).distance < 60;

    _lastTapTime = now;
    _lastTapPosition = details.localPosition;

    if (isConsecutiveTap) {
      // Cancel pending single tap toggle
      _singleTapTimer?.cancel();

      final settings = ref.read(appSettingsProvider);
      final step = settings.skipStepSeconds;

      final zone = _gestureMath.getHorizontalZone(details.localPosition.dx, screenWidth);
      final offset = _doubleTapAccumulator.registerTap(zone, now: now, stepSeconds: step);

      if (zone == HorizontalZone.centerThird) {
        _engine?.togglePlay();
      } else {
        final target = _position + Duration(seconds: zone == HorizontalZone.leftThird ? -step : step);
        final seekTarget = target < Duration.zero
            ? Duration.zero
            : (_duration > Duration.zero && target > _duration ? _duration : target);
        setState(() => _position = seekTarget);
        _engine?.seek(seekTarget);
        _showDoubleTapBadge(offset);
      }
      _resetControlsHideTimer();
    } else {
      // Wait to see if second tap follows; if not, toggle controls
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(const Duration(milliseconds: 260), () {
        if (mounted) {
          _toggleControls();
        }
      });
    }
  }

  void _showDoubleTapBadge(int offsetSeconds) {
    setState(() {
      _doubleTapOffsetSeconds = offsetSeconds;
    });
    _doubleTapBadgeTimer?.cancel();
    _doubleTapBadgeTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _doubleTapOffsetSeconds = null;
        });
      }
    });
  }

  void _handleLongPressStart() {
    if (_isLocked) {
      _showLockedPrompt();
      return;
    }
    final settings = ref.read(appSettingsProvider);
    if (!settings.gesturesEnabled) return;

    _singleTapTimer?.cancel();
    _rateBeforeHold = _playbackRate;
    _engine?.setRate(settings.longPressSpeed);
    setState(() {
      _isHolding2x = true;
      _controlsVisible = false;
      _showSettingsSheet = false;
      _showEpisodeSheet = false;
      _showVerticalHud = false;
      _doubleTapOffsetSeconds = null;
      _isScrubbing = false;
    });
    _controlsHideTimer?.cancel();
  }

  void _handleLongPressEnd() {
    if (!_isHolding2x) return;
    _engine?.setRate(_rateBeforeHold);
    setState(() {
      _isHolding2x = false;
    });
    _resetControlsHideTimer();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_isLocked || _isHolding2x) {
      if (_isLocked) _showLockedPrompt();
      return;
    }
    final settings = ref.read(appSettingsProvider);
    if (!settings.gesturesEnabled) return;

    _singleTapTimer?.cancel();
    setState(() {
      _isScrubbing = true;
      _scrubStartX = details.localPosition.dx;
      _scrubBasePosition = _position;
      _scrubTargetPosition = _position;
    });
    _controlsHideTimer?.cancel();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isScrubbing) return;
    final deltaX = details.localPosition.dx - _scrubStartX;
    final target = _gestureMath.calculateScrubTarget(
      basePosition: _scrubBasePosition,
      totalDuration: _duration,
      deltaX: deltaX,
      totalWidth: screenWidth,
    );
    setState(() {
      _scrubTargetPosition = target;
    });
  }

  void _handleHorizontalDragEnd() {
    if (!_isScrubbing) return;
    _position = _scrubTargetPosition;
    _engine?.seek(_scrubTargetPosition);
    setState(() {
      _isScrubbing = false;
    });
    _resetControlsHideTimer();
  }

  void _handleVerticalDragStart(DragStartDetails details, double screenWidth) {
    if (_isLocked || _isHolding2x) {
      if (_isLocked) _showLockedPrompt();
      return;
    }
    final settings = ref.read(appSettingsProvider);
    if (!settings.gesturesEnabled) return;

    _singleTapTimer?.cancel();
    _verticalDragHalf = _gestureMath.getScreenHalf(details.localPosition.dx, screenWidth);
    _verticalDragStartY = details.localPosition.dy;
    _verticalDragStartVal = _verticalDragHalf == ScreenHalf.left ? _brightness : _volume;
    _isVerticalHudVolume = _verticalDragHalf == ScreenHalf.right;

    setState(() {
      _showVerticalHud = true;
    });
    _verticalHudTimer?.cancel();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double screenHeight) {
    final deltaY = details.localPosition.dy - _verticalDragStartY;
    final newVal = _gestureMath.calculateVerticalDelta(
      currentValue: _verticalDragStartVal,
      deltaY: deltaY,
      totalHeight: screenHeight,
    );

    setState(() {
      if (_verticalDragHalf == ScreenHalf.left) {
        _brightness = newVal;
      } else {
        _volume = newVal;
        _engine?.setVolume(newVal);
      }
    });
  }

  void _handleVerticalDragEnd() {
    _verticalHudTimer?.cancel();
    _verticalHudTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showVerticalHud = false;
        });
      }
    });
    _resetControlsHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<StreamResolutionResult>>(
      activeStreamProvider(_params),
      (previous, next) {
        final result = next.valueOrNull;
        if (result != null) {
          _openStreamIfReady(result);
        }
      },
    );

    final streamAsync = ref.watch(activeStreamProvider(_params));
    final streamNotifier = ref.read(activeStreamProvider(_params).notifier);
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: streamAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Resolving stream variants...',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
        error: (err, _) => _buildErrorScreen(err),
        data: (result) {
          final matchTitle = result.match.title;
          final epSubtitle = 'Episode ${widget.episodeNumber.toString().padLeft(2, '0')} • ${result.activeProvider.displayName}';

          // 1. Default to Web Embed technique for playback (User's preferred technique)
          if (_useEmbedPlayer) {
            _engine?.pause();
            final matchId = result.match.id.isNotEmpty ? result.match.id : widget.animeId.toString();
            final isDub = result.selectedAudio.code == AudioLanguage.englishDub.code;
            final lang = isDub ? 'dub' : 'sub';
            final kisskhEpId = result.episode.customData['kisskhEpId'];
            final embedUrl = kisskhEpId != null
                ? 'https://megavid.buzz/kisskh/$kisskhEpId'
                : 'https://megavid.buzz/ani/$matchId/${widget.episodeNumber}/$lang';

            return WebEmbedPlayerView(
              embedUrl: embedUrl,
              title: matchTitle,
              episodeSubtitle: epSubtitle,
              audioLabel: isDub ? 'DUB' : 'SUB',
              onToggleAudio: () {
                final targetAudio = isDub ? AudioLanguage.japaneseOriginal : AudioLanguage.englishDub;
                streamNotifier.selectAudioLanguage(targetAudio);
              },
              onBack: () => context.pop(),
              onSwitchToNative: () {
                setState(() => _useEmbedPlayer = false);
                _openStreamIfReady(result);
                _engine?.play();
              },
              isLocked: _isLocked,
              onToggleLock: () {
                setState(() {
                  _isLocked = !_isLocked;
                  _showUnlockButton = _isLocked;
                });
              },
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Interactive Video Surface with Multi-Gesture Handler
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTapDown(details, screenSize.width),
                onLongPressStart: (_) => _handleLongPressStart(),
                onLongPressEnd: (_) => _handleLongPressEnd(),
                onLongPressCancel: () => _handleLongPressEnd(),
                onHorizontalDragStart: _handleHorizontalDragStart,
                onHorizontalDragUpdate: (details) => _handleHorizontalDragUpdate(details, screenSize.width),
                onHorizontalDragEnd: (_) => _handleHorizontalDragEnd(),
                onVerticalDragStart: (details) => _handleVerticalDragStart(details, screenSize.width),
                onVerticalDragUpdate: (details) => _handleVerticalDragUpdate(details, screenSize.height),
                onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
                child: Center(
                  child: _engine != null
                      ? _engine!.buildVideoView()
                      : Container(color: Colors.black),
                ),
              ),

              // Center Buffering Spinner (visible when controls are hidden or during audio switch)
              if ((_isBuffering || _isSwitchingAudio) && !_controlsVisible && !_isHolding2x && !_isLocked)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),
                ),

              // 2. Center Hold Speed Pill ("2X Speed ▶▶") - Sole overlay visible while holding
              if (_isHolding2x) const IgnorePointer(child: HoldSpeedPill()),

              // 3. Double-tap seek badges (<< -20s or +30s >>)
              if (_doubleTapOffsetSeconds != null && !_isHolding2x && !_isLocked)
                IgnorePointer(
                  child: DoubleTapSeekBadge(offsetSeconds: _doubleTapOffsetSeconds!),
                ),

              // 4. Horizontal Scrub live preview HUD
              if (_isScrubbing && !_isHolding2x && !_isLocked)
                IgnorePointer(
                  child: ScrubPreviewHud(
                    targetPosition: _scrubTargetPosition,
                    totalDuration: _duration,
                    delta: _scrubTargetPosition - _scrubBasePosition,
                  ),
                ),

              // 5. Vertical Brightness / Volume HUD
              if (_showVerticalHud && !_isHolding2x && !_isLocked)
                IgnorePointer(
                  child: VerticalSliderHud(
                    isVolume: _isVerticalHudVolume,
                    value: _isVerticalHudVolume ? _volume : _brightness,
                  ),
                ),

              // 6. Resume Toast ("Resumed from mm:ss")
              if (_resumeToastMessage != null && !_isHolding2x && !_isLocked)
                _buildResumeToast(),

              // 7. Next Episode Auto-Play Countdown Card
              if (_showNextEpisodeCountdown && !_isHolding2x && !_isLocked)
                Positioned(
                  right: 24,
                  bottom: 82,
                  child: NextEpisodeCountdownCard(
                    secondsRemaining: _nextEpisodeCountdownSeconds,
                    nextEpisodeNumber: widget.episodeNumber + 1,
                    onPlayNow: _playNextEpisode,
                    onCancel: _cancelNextEpisodeCountdown,
                  ),
                ),

              // 8. Skip Intro / Skip Outro Pill
              Builder(
                builder: (context) {
                  if (_isHolding2x || _isLocked) return const SizedBox.shrink();
                  final posSec = _position.inMilliseconds / 1000.0;
                  final selectedVar = result.selectedVariant;
                  if (selectedVar.hasIntro &&
                      posSec >= selectedVar.introStart! &&
                      posSec < selectedVar.introEnd!) {
                    return Positioned(
                      right: 24,
                      bottom: _controlsVisible ? 86 : 28,
                      child: _buildSkipPill(
                        label: 'Skip Intro',
                        onSkip: () {
                          final targetMs = (selectedVar.introEnd! * 1000).round();
                          final target = Duration(milliseconds: targetMs);
                          setState(() => _position = target);
                          _engine?.seek(target);
                        },
                      ),
                    );
                  } else if (selectedVar.hasOutro &&
                      posSec >= selectedVar.outroStart! &&
                      posSec < selectedVar.outroEnd!) {
                    return Positioned(
                      right: 24,
                      bottom: _controlsVisible ? 86 : 28,
                      child: _buildSkipPill(
                        label: 'Skip Outro',
                        onSkip: () {
                          final targetMs = (selectedVar.outroEnd! * 1000).round();
                          final target = Duration(milliseconds: targetMs);
                          setState(() => _position = target);
                          _engine?.seek(target);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // 9. Auto-hiding Controls Overlay
              AnimatedOpacity(
                opacity: (_controlsVisible && !_isLocked && !_isHolding2x) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_controlsVisible || _isLocked || _isHolding2x,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Top Bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: PlayerTopBar(
                          title: matchTitle,
                          episodeSubtitle: epSubtitle,
                          danmakuEnabled: _danmakuEnabled,
                          audioLabel: result.selectedAudio.code == AudioLanguage.englishDub.code ? 'DUB' : 'SUB',
                          onLock: _lockPlayer,
                          onToggleAudio: () {
                            final currentAudio = result.selectedAudio;
                            final targetAudio = currentAudio.code == AudioLanguage.englishDub.code
                                ? AudioLanguage.japaneseOriginal
                                : AudioLanguage.englishDub;
                            streamNotifier.selectAudioLanguage(targetAudio);
                          },
                          onBack: () => context.pop(),
                          onToggleDanmaku: () {
                            setState(() => _danmakuEnabled = !_danmakuEnabled);
                            _resetControlsHideTimer();
                          },
                          onCast: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Searching for Cast / AirPlay devices...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _resetControlsHideTimer();
                          },
                          onOpenMore: () => _showMoreOptionsSheet(context, result),
                          onOpenEpisodes: () {
                            setState(() {
                              _showEpisodeSheet = true;
                              _showSettingsSheet = false;
                              _controlsVisible = true;
                            });
                          },
                          onOpenDiagnostics: () => _showDiagnosticsSheet(context),
                          onSwitchToEmbed: () {
                            setState(() => _useEmbedPlayer = true);
                            _engine?.pause();
                          },
                          onCopyEmbedUrl: () {
                            final matchId = result.match.id.isNotEmpty ? result.match.id : widget.animeId.toString();
                            final isDub = result.selectedAudio.code == AudioLanguage.englishDub.code;
                            final lang = isDub ? 'dub' : 'sub';
                            final kisskhEpId = result.episode.customData['kisskhEpId'];
                            final embedUrl = kisskhEpId != null
                                ? 'https://megavid.buzz/kisskh/$kisskhEpId'
                                : 'https://megavid.buzz/ani/$matchId/${widget.episodeNumber}/$lang';
                            Clipboard.setData(ClipboardData(text: embedUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied embed URL: $embedUrl'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          },
                        ),
                      ),

                      // Floating Screen Lock Button (Left Side Dock - Safe from camera punch holes)
                      Positioned(
                        left: math.max(MediaQuery.paddingOf(context).left + 28, 68),
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _lockPlayer,
                              borderRadius: BorderRadius.circular(24),
                              child: Tooltip(
                                message: 'Lock Screen',
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC141914),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF263526),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center Controls (Prev Ep, Replay-10, Play/Pause circle, Forward-10, Next Ep)
                      Builder(
                        builder: (context) {
                          final animeDetail = ref.watch(animeDetailProvider(widget.animeId)).value;
                          final totalEps = animeDetail?.eps;
                          final hasNextEp = totalEps == null || widget.episodeNumber < totalEps;
                          final hasPrevEp = widget.episodeNumber > 1;

                          return PlayerCenterControls(
                            isPlaying: _isPlaying,
                            isBuffering: _isBuffering,
                            hasPreviousEpisode: hasPrevEp,
                            hasNextEpisode: hasNextEp,
                            onPreviousEpisode: _playPreviousEpisode,
                            onNextEpisode: _playNextEpisode,
                            onTogglePlay: () {
                              _engine?.togglePlay();
                              _resetControlsHideTimer();
                            },
                            onReplay10: () {
                              final step = ref.read(appSettingsProvider).skipStepSeconds;
                              final raw = _position - Duration(seconds: step);
                              final target = raw < Duration.zero ? Duration.zero : raw;
                              setState(() => _position = target);
                              _engine?.seek(target);
                              _showDoubleTapBadge(-step);
                              _resetControlsHideTimer();
                            },
                            onForward10: () {
                              final step = ref.read(appSettingsProvider).skipStepSeconds;
                              final raw = _position + Duration(seconds: step);
                              final target = (_duration > Duration.zero && raw > _duration) ? _duration : raw;
                              setState(() => _position = target);
                              _engine?.seek(target);
                              _showDoubleTapBadge(step);
                              _resetControlsHideTimer();
                            },
                          );
                        },
                      ),

                      // Skip Intro (+85s) Chip
                      if (_position.inSeconds < 90 && _duration.inSeconds > 120)
                        Positioned(
                          left: 24,
                          bottom: 74,
                          child: SkipIntroButton(
                            onSkip: () {
                              final raw = _position + const Duration(seconds: 85);
                              final target = (_duration > Duration.zero && raw > _duration) ? _duration : raw;
                              setState(() => _position = target);
                              _engine?.seek(target);
                              _resetControlsHideTimer();
                            },
                          ),
                        ),

                      // Bottom Bar (Seek bar + action buttons)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: PlayerBottomBar(
                          position: _isScrubbing ? _scrubTargetPosition : _position,
                          duration: _duration,
                          buffer: _buffer,
                          hasPreviousEpisode: widget.episodeNumber > 1,
                          hasNextEpisode: true,
                          onPreviousEpisode: _playPreviousEpisode,
                          onNextEpisode: _playNextEpisode,
                          onLock: _lockPlayer,
                          onSeekStart: (_) {
                            _isUserSeeking = true;
                            _controlsHideTimer?.cancel();
                          },
                          onSeek: (target) {
                            setState(() => _position = target);
                          },
                          onSeekEnd: (target) {
                            setState(() => _position = target);
                            _engine?.seek(target);
                            _isUserSeeking = false;
                            _resetControlsHideTimer();
                          },
                          onOpenEpisodes: () {
                            setState(() {
                              _showEpisodeSheet = true;
                              _showSettingsSheet = false;
                              _controlsVisible = true;
                            });
                          },
                          onOpenSettings: () {
                            setState(() {
                              _showSettingsSheet = true;
                              _showEpisodeSheet = false;
                              _controlsVisible = true;
                            });
                          },
                          onToggleFullscreen: _toggleAspectRatioMode,
                          onCast: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Searching for Cast / AirPlay devices...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _resetControlsHideTimer();
                          },
                          onPip: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Picture in Picture activated'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _resetControlsHideTimer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 10. Floating Unlock Button (visible when tapped while locked)
              if (_isLocked && _showUnlockButton && !_isHolding2x)
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _unlockPlayer,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xF0101510),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFC6F16D), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66C6F16D),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 18,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_open_rounded, color: Color(0xFFC6F16D), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tap to Unlock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 11. Sliding Landscape Settings Side-Panel
              if (_showSettingsSheet && !_isLocked && !_isHolding2x)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: PlayerSettingsSheet(
                    availableQualities: result.selectedVariant.qualities,
                    selectedQuality: result.selectedQuality,
                    onSelectQuality: (q) {
                      streamNotifier.selectQuality(q);
                    },
                    availableAudios: () {
                      final list = result.variants.map((v) => v.audio).toSet().toList();
                      if (!list.any((a) => a.code == AudioLanguage.japaneseOriginal.code)) {
                        list.insert(0, AudioLanguage.japaneseOriginal);
                      }
                      if (!list.any((a) => a.code == AudioLanguage.englishDub.code)) {
                        list.add(AudioLanguage.englishDub);
                      }
                      return list;
                    }(),
                    selectedAudio: result.selectedAudio,
                    onSelectAudio: (a) {
                      streamNotifier.selectAudioLanguage(a);
                    },
                    availableSubtitles: result.selectedVariant.subtitles,
                    selectedSubtitle: result.selectedSubtitle,
                    onSelectSubtitle: (s) {
                      streamNotifier.selectSubtitleTrack(s);
                    },
                    subtitleSettings: _subtitleSettings,
                    onUpdateSubtitleSettings: (settings) {
                      setState(() => _subtitleSettings = settings);
                    },
                    currentSpeed: _playbackRate,
                    onSelectSpeed: (speed) {
                      _engine?.setRate(speed);
                    },
                    currentAspectRatio: _aspectRatioMode,
                    onSelectAspectRatio: (mode) {
                      setState(() => _aspectRatioMode = mode);
                      _engine?.setAspectRatioMode(mode);
                    },
                    availableProviders: ref.read(streamProvidersProvider),
                    activeProvider: result.activeProvider,
                    onSelectProvider: (p) {
                      setState(() {
                        _showSettingsSheet = false;
                      });
                      context.pushReplacement(
                        '/player?animeId=${widget.animeId}&ep=${widget.episodeNumber}&provider=${p.id}',
                      );
                    },
                    onClose: () {
                      setState(() => _showSettingsSheet = false);
                      _resetControlsHideTimer();
                    },
                  ),
                ),

              // 12. Sliding Episode Selector Side-Panel
              if (_showEpisodeSheet && !_isLocked && !_isHolding2x)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: EpisodeSelectorSheet(
                    totalEpisodes: result.match.episodeCount ?? 24,
                    currentEpisode: widget.episodeNumber,
                    onSelectEpisode: (ep) {
                      setState(() => _showEpisodeSheet = false);
                      _saveCurrentProgress();
                      context.pushReplacement('/player?animeId=${widget.animeId}&ep=$ep');
                    },
                    onClose: () {
                      setState(() => _showEpisodeSheet = false);
                      _resetControlsHideTimer();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumeToast() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                _resumeToastMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipPill({
    required String label,
    required VoidCallback onSkip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSkip,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.fast_forward_rounded, size: 16, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object err) {
    if (err is DioException &&
        (err.type == DioExceptionType.cancel || CancelToken.isCancel(err))) {
      // Re-trigger resolution if cancellation occurred during screen navigation transition
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(activeStreamProvider(_params));
      });
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      );
    }

    final String errorMessage;
    if (err is DioException) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your network connection.';
      } else {
        errorMessage = 'Network error (${err.response?.statusCode ?? err.message ?? "Request error"})';
      }
    } else if (err is TimeoutException || err.toString().contains('TimeoutException')) {
      errorMessage = 'Stream provider took too long to respond. Tap Retry to reconnect.';
    } else if (err.toString().contains('StreamResolutionException')) {
      errorMessage = 'Could not resolve a playable video stream for this episode. Tap Retry or switch providers.';
    } else {
      errorMessage = err.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.pageMargin),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Playback Stream Failed',
              style: AppText.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppText.meta.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final embedUrl = 'https://megavid.buzz/ani/${widget.animeId}/${widget.episodeNumber}/sub';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WebEmbedPlayerView(
                          embedUrl: embedUrl,
                          title: 'Anime #${widget.animeId}',
                          episodeSubtitle: 'Episode ${widget.episodeNumber} • Web Embed',
                          onBack: () => Navigator.of(context).pop(),
                          onSwitchToNative: () => Navigator.of(context).pop(),
                          isLocked: false,
                          onToggleLock: () {},
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.language_rounded, size: 16),
                  label: const Text('Play in Web Player'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showDiagnosticsSheet(context),
                  icon: const Icon(Icons.bug_report_rounded, size: 16),
                  label: const Text('Diagnostics'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _currentlyLoadedUrl = null;
                    ref.invalidate(activeStreamProvider(_params));
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF0F150D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAspectRatioMode() {
    const modes = VideoAspectRatioMode.values;
    final nextIndex = (_currentAspectMode.index + 1) % modes.length;
    final nextMode = modes[nextIndex];
    setState(() => _currentAspectMode = nextMode);
    _engine?.setAspectRatioMode(nextMode);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aspect: ${nextMode.label}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetControlsHideTimer();
  }

  void _showMoreOptionsSheet(BuildContext context, StreamResolutionResult result) {
    _controlsHideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: const Color(0xFA141416),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'More Options',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  if (widget.episodeNumber > 1)
                    ListTile(
                      leading: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                      title: const Text('Previous Episode', style: TextStyle(color: Colors.white, fontSize: 14)),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _playPreviousEpisode();
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.skip_next_rounded, color: Colors.white),
                    title: const Text('Next Episode', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _playNextEpisode();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                    title: const Text('Lock Controls', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _lockPlayer();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                    title: const Text('Picture in Picture', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Picture in Picture activated'), duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: Colors.white),
                    title: const Text('Switch to Web Embed Player', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _useEmbedPlayer = true);
                      _engine?.pause();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.link_rounded, color: Colors.white),
                    title: const Text('Copy Embed URL', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final matchId = result.match.id.isNotEmpty ? result.match.id : widget.animeId.toString();
                      final isDub = result.selectedAudio.code == AudioLanguage.englishDub.code;
                      final lang = isDub ? 'dub' : 'sub';
                      final kisskhEpId = result.episode.customData['kisskhEpId'];
                      final embedUrl = kisskhEpId != null
                          ? 'https://megavid.buzz/kisskh/$kisskhEpId'
                          : 'https://megavid.buzz/ani/$matchId/${widget.episodeNumber}/$lang';
                      Clipboard.setData(ClipboardData(text: embedUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied embed URL: $embedUrl'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    },
                  ),
                   ListTile(
                    leading: const Icon(Icons.dns_rounded, color: Colors.white),
                    title: const Text('Stream Server / Mirror', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(
                      'Switch servers (Zuna, Sora, Loli, Nero)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showServerSelectionSheet(context, result);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined, color: Colors.white),
                    title: const Text('Stream Diagnostics', style: TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showDiagnosticsSheet(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServerSelectionSheet(BuildContext context, StreamResolutionResult result) {
    final servers = [
      {'id': 'zuna', 'name': 'Zuna (Fast • Soft Sub • Recommended)', 'tip': 'High quality'},
      {'id': 'sora', 'name': 'Sora (Fast • High Quality)', 'tip': 'Soft sub'},
      {'id': 'loli', 'name': 'Loli (Multi-server • HLS)', 'tip': 'Sub and dub'},
      {'id': 'nero', 'name': 'Nero (Fastest)', 'tip': 'Direct'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFA141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Select Stream Server',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Switch servers if you encounter buffering or stall at specific timestamps.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...servers.map((s) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_queue_rounded, color: AppColors.accent),
                  title: Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final resolver = EmbedStreamResolver();
                    final matchId = result.match.id.isNotEmpty ? result.match.id : widget.animeId.toString();
                    final isDub = result.selectedAudio.code == AudioLanguage.englishDub.code;
                    final lang = isDub ? 'dub' : 'sub';
                    final embedUrl = 'https://megavid.buzz/ani/$matchId/${widget.episodeNumber}/$lang';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switching to server ${s['id']}...'), duration: const Duration(seconds: 1)),
                    );
                    final resolved = await resolver.resolveEmbedUrl(embedUrl, serverOverride: s['id']!);
                    if (resolved != null && mounted) {
                      final currentPos = _position;
                      _currentlyLoadedUrl = resolved.streamUrl;
                      await _engine?.open(
                        resolved.streamUrl,
                        headers: resolved.variant.headers,
                        startPosition: currentPos,
                      );
                      _engine?.play();
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiagnosticsSheet(BuildContext context) {
    final diagnosticsRepo = ref.read(diagnosticsRepositoryProvider);
    final report = diagnosticsRepo.generateDiagnosticReport(
      animeId: widget.animeId,
      episodeNumber: widget.episodeNumber,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Resolution Trace Logs', style: AppText.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: report));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Diagnostics copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    report,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
