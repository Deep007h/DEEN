/// Sorting options for followed anime in the Following tab.
enum FollowSort {
  recentlyFollowed,
  title,
  score,
}

/// Represents an anime bookmarked/followed by the user.
class FollowedAnime {
  final int id;
  final String title;
  final String? nameCn;
  final String? posterUrl;
  final double score;
  final int totalEpisodes;
  final DateTime followedAt;

  const FollowedAnime({
    required this.id,
    required this.title,
    this.nameCn,
    this.posterUrl,
    this.score = 0.0,
    this.totalEpisodes = 0,
    required this.followedAt,
  });

  /// Backward-compatible alias for [id].
  int get animeId => id;

  /// Backward-compatible alias for [title].
  String get name => title;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'nameCn': nameCn,
      'posterUrl': posterUrl,
      'score': score,
      'totalEpisodes': totalEpisodes,
      'followedAt': followedAt.toIso8601String(),
    };
  }

  factory FollowedAnime.fromJson(Map<String, dynamic> json) {
    return FollowedAnime(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      nameCn: json['nameCn'] as String?,
      posterUrl: json['posterUrl'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalEpisodes: json['totalEpisodes'] as int? ?? 0,
      followedAt: json['followedAt'] != null
          ? DateTime.tryParse(json['followedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FollowedAnime copyWith({
    int? id,
    String? title,
    String? nameCn,
    String? posterUrl,
    double? score,
    int? totalEpisodes,
    DateTime? followedAt,
  }) {
    return FollowedAnime(
      id: id ?? this.id,
      title: title ?? this.title,
      nameCn: nameCn ?? this.nameCn,
      posterUrl: posterUrl ?? this.posterUrl,
      score: score ?? this.score,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      followedAt: followedAt ?? this.followedAt,
    );
  }
}
