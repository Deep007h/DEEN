/// Subtitle file format.
enum SubtitleFormat {
  vtt,
  srt,
  ass;

  static SubtitleFormat fromString(String? val) {
    if (val == null) return SubtitleFormat.vtt;
    return SubtitleFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SubtitleFormat.vtt,
    );
  }
}

/// Represents a subtitle or closed caption track.
class SubtitleTrack {
  final String id;
  final String languageCode;
  final String label;
  final String? url;
  final int? embeddedIndex;
  final SubtitleFormat format;
  final bool isDefault;

  const SubtitleTrack({
    required this.id,
    required this.languageCode,
    required this.label,
    this.url,
    this.embeddedIndex,
    this.format = SubtitleFormat.vtt,
    this.isDefault = false,
  });

  /// Factory for disabling subtitles ("Off").
  factory SubtitleTrack.off() => const SubtitleTrack(
        id: 'off',
        languageCode: 'off',
        label: 'Off',
        format: SubtitleFormat.vtt,
        isDefault: false,
      );

  bool get isOff => id == 'off' || languageCode == 'off';

  Map<String, dynamic> toJson() => {
        'id': id,
        'languageCode': languageCode,
        'label': label,
        'url': url,
        'embeddedIndex': embeddedIndex,
        'format': format.name,
        'isDefault': isDefault,
      };

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => SubtitleTrack(
        id: json['id'] as String? ?? 'off',
        languageCode: json['languageCode'] as String? ?? 'off',
        label: json['label'] as String? ?? 'Off',
        url: json['url'] as String?,
        embeddedIndex: json['embeddedIndex'] as int?,
        format: SubtitleFormat.fromString(json['format'] as String?),
        isDefault: json['isDefault'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          languageCode == other.languageCode;

  @override
  int get hashCode => id.hashCode ^ languageCode.hashCode;

  @override
  String toString() => 'SubtitleTrack($id, $label, format: ${format.name})';
}
