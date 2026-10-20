import 'package:freezed_annotation/freezed_annotation.dart';

part 'anime_titles.freezed.dart';
part 'anime_titles.g.dart';

enum TitlePreference {
  english,
  localized,
  original,
}

@freezed
abstract class AnimeTitles with _$AnimeTitles {
  const AnimeTitles._();

  const factory AnimeTitles({
    required String original,
    String? english,
    String? localized,
  }) = _AnimeTitles;

  factory AnimeTitles.fromJson(Map<String, dynamic> json) => _$AnimeTitlesFromJson(json);

  /// Determines if a string consists primarily of Latin characters.
  static bool isPrimarilyLatin(String str) {
    if (str.isEmpty) return false;
    int latinCount = 0;
    int cjkCount = 0;
    for (final codeUnit in str.runes) {
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
          (codeUnit >= 0x0061 && codeUnit <= 0x007A) ||
          (codeUnit >= 0x0030 && codeUnit <= 0x0039)) {
        latinCount++;
      } else if ((codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
          (codeUnit >= 0x3040 && codeUnit <= 0x30FF)) {
        cjkCount++;
      }
    }
    return latinCount > 0 && latinCount >= cjkCount;
  }

  /// Resolves the user's preferred title with graceful fallbacks.
  String preferredTitle([TitlePreference pref = TitlePreference.english]) {
    switch (pref) {
      case TitlePreference.english:
        if (english != null && english!.trim().isNotEmpty && isPrimarilyLatin(english!)) {
          return english!;
        }
        if (localized != null && localized!.trim().isNotEmpty && isPrimarilyLatin(localized!)) {
          return localized!;
        }
        if (isPrimarilyLatin(original)) {
          return original;
        }
        if (english != null && english!.trim().isNotEmpty) return english!;
        if (localized != null && localized!.trim().isNotEmpty) return localized!;
        return original;
      case TitlePreference.localized:
        if (localized != null && localized!.trim().isNotEmpty) return localized!;
        if (english != null && english!.trim().isNotEmpty) return english!;
        return original;
      case TitlePreference.original:
        if (original.trim().isNotEmpty) return original;
        if (english != null && english!.trim().isNotEmpty) return english!;
        return localized ?? '';
    }
  }
}
