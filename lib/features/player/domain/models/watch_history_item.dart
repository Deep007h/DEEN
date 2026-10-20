/// Represents a recorded anime episode watch history entry.
class WatchHistoryItem {
  final int animeId;
  final int episodeNumber;
  final String animeTitle;
  final String? posterUrl;
  final int positionSeconds;
  final int totalDurationSeconds;
  final DateTime lastWatchedAt;

  const WatchHistoryItem({
    required this.animeId,
    required this.episodeNumber,
    required this.animeTitle,
    this.posterUrl,
    required this.positionSeconds,
    required this.totalDurationSeconds,
    required this.lastWatchedAt,
  });

  double get progressFraction {
    if (totalDurationSeconds <= 0) return 0.0;
    return (positionSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  /// Backward-compatible alias for [totalDurationSeconds].
  int get durationSeconds => totalDurationSeconds;

  bool get isCompleted => progressFraction >= 0.90;

  String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String get formattedProgress {
    final posStr = formatDuration(positionSeconds);
    final durStr = formatDuration(totalDurationSeconds);
    return '$posStr / $durStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'episodeNumber': episodeNumber,
      'animeTitle': animeTitle,
      'posterUrl': posterUrl,
      'positionSeconds': positionSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'lastWatchedAt': lastWatchedAt.toIso8601String(),
    };
  }

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      animeId: json['animeId'] as int? ?? 0,
      episodeNumber: json['episodeNumber'] as int? ?? 1,
      animeTitle: json['animeTitle'] as String? ?? 'Anime',
      posterUrl: json['posterUrl'] as String?,
      positionSeconds: json['positionSeconds'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      lastWatchedAt: json['lastWatchedAt'] != null
          ? DateTime.tryParse(json['lastWatchedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WatchHistoryItem copyWith({
    int? animeId,
    int? episodeNumber,
    String? animeTitle,
    String? posterUrl,
    int? positionSeconds,
    int? totalDurationSeconds,
    DateTime? lastWatchedAt,
  }) {
    return WatchHistoryItem(
      animeId: animeId ?? this.animeId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      animeTitle: animeTitle ?? this.animeTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }
}
