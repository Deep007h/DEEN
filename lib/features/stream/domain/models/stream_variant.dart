import 'audio_language.dart';
import 'subtitle_track.dart';
import 'quality_option.dart';

/// A playable stream variant for an episode.
class StreamVariant {
  final String url; // HLS (.m3u8) or MP4
  final Map<String, String> headers;
  final AudioLanguage audio; // original, english dub, hindi dub, ...
  final List<SubtitleTrack> subtitles; // language, url or embedded index, format (vtt/srt/ass)
  final List<QualityOption> qualities; // 360p / 480p / 720p / 1080p / Auto
  final double? introStart;
  final double? introEnd;
  final double? outroStart;
  final double? outroEnd;

  const StreamVariant({
    required this.url,
    this.headers = const {},
    required this.audio,
    this.subtitles = const [],
    this.qualities = const [],
    this.introStart,
    this.introEnd,
    this.outroStart,
    this.outroEnd,
  });

  StreamVariant copyWith({
    String? url,
    Map<String, String>? headers,
    AudioLanguage? audio,
    List<SubtitleTrack>? subtitles,
    List<QualityOption>? qualities,
    double? introStart,
    double? introEnd,
    double? outroStart,
    double? outroEnd,
  }) =>
      StreamVariant(
        url: url ?? this.url,
        headers: headers ?? this.headers,
        audio: audio ?? this.audio,
        subtitles: subtitles ?? this.subtitles,
        qualities: qualities ?? this.qualities,
        introStart: introStart ?? this.introStart,
        introEnd: introEnd ?? this.introEnd,
        outroStart: outroStart ?? this.outroStart,
        outroEnd: outroEnd ?? this.outroEnd,
      );

  bool get isHls => url.toLowerCase().contains('.m3u8');
  bool get isMp4 => url.toLowerCase().contains('.mp4');
  bool get hasIntro => introStart != null && introEnd != null && introEnd! > introStart!;
  bool get hasOutro => outroStart != null && outroEnd != null && outroEnd! > outroStart!;

  Map<String, dynamic> toJson() => {
        'url': url,
        'headers': headers,
        'audio': audio.toJson(),
        'subtitles': subtitles.map((s) => s.toJson()).toList(),
        'qualities': qualities.map((q) => q.toJson()).toList(),
        'introStart': introStart,
        'introEnd': introEnd,
        'outroStart': outroStart,
        'outroEnd': outroEnd,
      };

  factory StreamVariant.fromJson(Map<String, dynamic> json) => StreamVariant(
        url: json['url'] as String? ?? '',
        headers: (json['headers'] as Map?)?.cast<String, String>() ?? const {},
        audio: AudioLanguage.fromJson(
            (json['audio'] as Map?)?.cast<String, dynamic>() ?? {}),
        subtitles: ((json['subtitles'] as List?) ?? [])
            .map((e) => SubtitleTrack.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        qualities: ((json['qualities'] as List?) ?? [])
            .map((e) => QualityOption.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        introStart: (json['introStart'] as num?)?.toDouble(),
        introEnd: (json['introEnd'] as num?)?.toDouble(),
        outroStart: (json['outroStart'] as num?)?.toDouble(),
        outroEnd: (json['outroEnd'] as num?)?.toDouble(),
      );

  @override
  String toString() =>
      'StreamVariant(url: $url, audio: ${audio.label}, subs: ${subtitles.length}, qualities: ${qualities.length})';
}
