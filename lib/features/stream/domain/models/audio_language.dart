/// Audio track language configuration (original vs dubs).
class AudioLanguage {
  final String code;
  final String label;
  final bool isOriginal;

  const AudioLanguage({
    required this.code,
    required this.label,
    this.isOriginal = false,
  });

  bool get isDub => !isOriginal;

  static const japaneseOriginal = AudioLanguage(
    code: 'ja',
    label: 'Japanese (Original)',
    isOriginal: true,
  );

  static const koreanOriginal = AudioLanguage(
    code: 'ko',
    label: 'Korean (Original)',
    isOriginal: true,
  );

  static const englishDub = AudioLanguage(
    code: 'en',
    label: 'English Dub',
    isOriginal: false,
  );

  static const hindiDub = AudioLanguage(
    code: 'hi',
    label: 'Hindi Dub',
    isOriginal: false,
  );

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'isOriginal': isOriginal,
      };

  factory AudioLanguage.fromJson(Map<String, dynamic> json) => AudioLanguage(
        code: json['code'] as String? ?? 'ja',
        label: json['label'] as String? ?? 'Japanese (Original)',
        isOriginal: json['isOriginal'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          isOriginal == other.isOriginal;

  @override
  int get hashCode => code.hashCode ^ isOriginal.hashCode;

  @override
  String toString() => 'AudioLanguage($code, $label, original: $isOriginal)';
}
