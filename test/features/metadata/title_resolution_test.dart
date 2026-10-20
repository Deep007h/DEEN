import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';

void main() {
  group('Title Resolution Strategy Tests', () {
    const titlesFull = AnimeTitles(
      original: '葬送のフリーレン',
      english: "Frieren: Beyond Journey's End",
      localized: '葬送的芙莉莲',
    );

    test('English preference returns English when available', () {
      expect(
        titlesFull.preferredTitle(TitlePreference.english),
        equals("Frieren: Beyond Journey's End"),
      );
    });

    test('English preference falls back to localized when English is null', () {
      const titlesNoEng = AnimeTitles(
        original: '葬送のフリーレン',
        localized: '葬送的芙莉莲',
      );
      expect(
        titlesNoEng.preferredTitle(TitlePreference.english),
        equals('葬送的芙莉莲'),
      );
    });

    test('English preference falls back to original when English and localized are null', () {
      const titlesOnlyOrig = AnimeTitles(
        original: '葬送のフリーレン',
      );
      expect(
        titlesOnlyOrig.preferredTitle(TitlePreference.english),
        equals('葬送のフリーレン'),
      );
    });

    test('Localized preference returns localized title when available', () {
      expect(
        titlesFull.preferredTitle(TitlePreference.localized),
        equals('葬送的芙莉莲'),
      );
    });

    test('Original preference returns Japanese original title', () {
      expect(
        titlesFull.preferredTitle(TitlePreference.original),
        equals('葬送のフリーレン'),
      );
    });
  });
}
