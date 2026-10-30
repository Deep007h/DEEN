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

  static const tamilDub = AudioLanguage(
    code: 'ta',
    label: 'Tamil Dub',
    isOriginal: false,
  );

  static const teluguDub = AudioLanguage(
    code: 'te',
    label: 'Telugu Dub',
    isOriginal: false,
  );

  static const kannadaDub = AudioLanguage(
    code: 'kn',
    label: 'Kannada Dub',
    isOriginal: false,
  );

  static const malayalamDub = AudioLanguage(
    code: 'ml',
    label: 'Malayalam Dub',
    isOriginal: false,
  );

  /// Primary list of languages supported across streaming servers.
  static const List<AudioLanguage> supportedLanguages = [
    japaneseOriginal,
    englishDub,
    hindiDub,
    tamilDub,
    teluguDub,
    koreanOriginal,
  ];

  /// Resolves an [AudioLanguage] from a language code or common code aliases.
  static AudioLanguage fromCode(String code, {String? label}) {
    final lower = code.toLowerCase().trim();
    if (lower == 'ja' || lower == 'jpn' || lower.contains('jap') || lower.contains('orig')) {
      return japaneseOriginal;
    }
    if (lower == 'en' || lower == 'eng' || lower.contains('english') || lower.contains('dub')) {
      return englishDub;
    }
    if (lower == 'hi' || lower == 'hin' || lower.contains('hindi')) {
      return hindiDub;
    }
    if (lower == 'ta' || lower == 'tam' || lower.contains('tamil')) {
      return tamilDub;
    }
    if (lower == 'te' || lower == 'tel' || lower.contains('telugu')) {
      return teluguDub;
    }
    if (lower == 'kn' || lower == 'kan' || lower.contains('kannada')) {
      return kannadaDub;
    }
    if (lower == 'ml' || lower == 'mal' || lower.contains('malayalam')) {
      return malayalamDub;
    }
    if (lower == 'ko' || lower == 'kor' || lower.contains('korean')) {
      return koreanOriginal;
    }
    return AudioLanguage(
      code: lower,
      label: label ?? '${lower.toUpperCase()} Audio',
      isOriginal: lower == 'ja' || lower == 'ko',
    );
  }

  /// Resolves an [AudioLanguage] from a human-readable display name.
  static AudioLanguage fromName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('hindi')) return hindiDub;
    if (lower.contains('english')) return englishDub;
    if (lower.contains('japanese') || lower.contains('original')) return japaneseOriginal;
    if (lower.contains('tamil')) return tamilDub;
    if (lower.contains('telugu')) return teluguDub;
    if (lower.contains('kannada')) return kannadaDub;
    if (lower.contains('malayalam')) return malayalamDub;
    if (lower.contains('korean')) return koreanOriginal;
    return fromCode(lower, label: name);
  }

  /// Compact uppercase badge label for player top bar (e.g. 'HINDI', 'DUB', 'SUB').
  String get shortLabel {
    if (code == 'ja' || code == 'ko') return 'SUB';
    if (code == 'hi') return 'HINDI';
    if (code == 'en') return 'DUB';
    if (code == 'ta') return 'TAMIL';
    if (code == 'te') return 'TELUGU';
    return code.toUpperCase();
  }

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
