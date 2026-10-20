import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/data/providers/demo_provider.dart';

void main() {
  group('DemoProvider Tests', () {
    const provider = DemoProvider();

    const testAnime = AnimeDetail(
      id: 400602,
      titles: AnimeTitles(
        original: '葬送のフリーレン',
        english: 'Frieren: Beyond Journey\'s End',
      ),
      airDate: '2023-09-29',
      eps: 28,
    );

    test('findTitle returns scored catalog candidates', () async {
      final matches = await provider.findTitle(testAnime);
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.title, 'Frieren: Beyond Journey\'s End');
      expect(matches.first.providerId, 'demo');
      expect(matches.first.confidenceScore, greaterThan(0.8));
    });

    test('episodes returns 28 episodes matching catalog match', () async {
      final matches = await provider.findTitle(testAnime);
      final episodes = await provider.episodes(matches.first);
      expect(episodes.length, 28);
      expect(episodes.first.number, 1);
      expect(episodes.last.number, 28);
    });

    test('resolve returns sub and dub variants with quality tiers', () async {
      final matches = await provider.findTitle(testAnime);
      final episodes = await provider.episodes(matches.first);
      final variants = await provider.resolve(episodes.first);

      expect(variants.length, 3);

      // Variant 1: Japanese Audio
      final ja = variants[0];
      expect(ja.audio.code, 'ja');
      expect(ja.audio.isOriginal, isTrue);
      expect(ja.isHls, isTrue);
      expect(ja.subtitles.any((s) => s.isOff), isTrue);
      expect(ja.subtitles.any((s) => s.languageCode == 'en'), isTrue);
      expect(ja.qualities.any((q) => q.isAuto), isTrue);
      expect(ja.qualities.any((q) => q.label == '1080p'), isTrue);

      // Variant 2: English Dub
      final en = variants[1];
      expect(en.audio.code, 'en');
      expect(en.audio.isOriginal, isFalse);

      // Variant 3: Hindi Dub
      final hi = variants[2];
      expect(hi.audio.code, 'hi');
      expect(hi.audio.isOriginal, isFalse);
    });
  });
}
