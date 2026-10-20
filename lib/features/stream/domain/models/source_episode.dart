/// Represents an episode available from a [StreamProvider].
class SourceEpisode {
  final String id;
  final int number;
  final String? title;
  final String matchId;
  final String providerId;
  final Map<String, dynamic> customData;

  const SourceEpisode({
    required this.id,
    required this.number,
    this.title,
    required this.matchId,
    required this.providerId,
    this.customData = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'matchId': matchId,
        'providerId': providerId,
        'customData': customData,
      };

  factory SourceEpisode.fromJson(Map<String, dynamic> json) => SourceEpisode(
        id: json['id'] as String? ?? '',
        number: json['number'] as int? ?? 1,
        title: json['title'] as String?,
        matchId: json['matchId'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        customData: (json['customData'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  String toString() => 'SourceEpisode(ep: $number, id: $id, title: $title)';
}
