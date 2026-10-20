/// Represents a catalog match found by a [StreamProvider] for an anime.
class SourceMatch {
  final String id;
  final String title;
  final String providerId;
  final int? year;
  final int? episodeCount;
  final double confidenceScore;
  final Map<String, dynamic> customData;

  const SourceMatch({
    required this.id,
    required this.title,
    required this.providerId,
    this.year,
    this.episodeCount,
    this.confidenceScore = 1.0,
    this.customData = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'providerId': providerId,
        'year': year,
        'episodeCount': episodeCount,
        'confidenceScore': confidenceScore,
        'customData': customData,
      };

  factory SourceMatch.fromJson(Map<String, dynamic> json) => SourceMatch(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        year: json['year'] as int?,
        episodeCount: json['episodeCount'] as int?,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
        customData: (json['customData'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  String toString() =>
      'SourceMatch(id: $id, title: $title, provider: $providerId, score: ${(confidenceScore * 100).toStringAsFixed(1)}%)';
}
