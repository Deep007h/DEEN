import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';
import 'package:anime_stream/features/stream/domain/matching/title_matcher.dart';

void main() {
  group('TitleMatcher Tests', () {
    test('Title normalization strips punctuation and unifies season keywords', () {
      expect(
        TitleMatcher.normalize('Attack on Titan: Season 2!'),
        'attack on titan s2',
      );
      expect(
        TitleMatcher.normalize('Jujutsu Kaisen 2nd Season'),
        'jujutsu kaisen s2',
      );
      expect(
        TitleMatcher.normalize('Bleach: Thousand-Year Blood War - Part 2'),
        'bleach thousand year blood war p2',
      );
    });

    test('String similarity returns 1.0 for identical normalized strings', () {
      final sim = TitleMatcher.stringSimilarity(
        'Frieren: Beyond Journey\'s End',
        'frieren beyond journeys end',
      );
      expect(sim, 1.0);
    });

    test('Candidate score includes title similarity, year bonus, and episode bonus', () {
      const anime = AnimeDetail(
        id: 400602,
        titles: AnimeTitles(
          original: '葬送のフリーレン',
          english: 'Frieren: Beyond Journey\'s End',
          localized: '葬送的芙莉莲',
        ),
        airDate: '2023-09-29',
        eps: 28,
      );

      final exactScore = TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: 'Frieren: Beyond Journey\'s End',
        candidateYear: 2023,
        candidateEpisodeCount: 28,
      );
      expect(exactScore, greaterThanOrEqualTo(0.95));

      final shortScore = TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: 'Frieren',
        candidateYear: 2023,
        candidateEpisodeCount: 28,
      );
      expect(shortScore, greaterThan(0.85));

      final partialScore = TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: 'Frieren Season 1',
        candidateYear: 2023,
        candidateEpisodeCount: 28,
      );
      expect(partialScore, greaterThan(0.5));

      final unrelatedScore = TitleMatcher.scoreCandidate(
        anime: anime,
        candidateTitle: 'Naruto Shippuden',
        candidateYear: 2007,
        candidateEpisodeCount: 500,
      );
      expect(unrelatedScore, lessThan(0.3));
    });

    test('Candidate score matches Roman numerals and subtitles (Mushoku Tensei S3)', () {
      const mushokuAnime = AnimeDetail(
        id: 501963,
        titles: AnimeTitles(
          original: '無職転生Ⅲ ～異世界行ったら本気だす～',
          english: 'Mushoku Tensei: Jobless Reincarnation Season 3',
          localized: '无职转生 第三季 ～到了异世界就拿出真本事～',
        ),
        airDate: '2026-07-04',
        eps: 14,
      );

      final score = TitleMatcher.scoreCandidate(
        anime: mushokuAnime,
        candidateTitle: 'Mushoku Tensei: Jobless Reincarnation Season 3',
        candidateSub: 'Mushoku Tensei III: Isekai Ittara Honki Dasu',
        candidateYear: 2026,
        candidateEpisodeCount: 14,
      );
      expect(score, greaterThanOrEqualTo(0.9));
    });
  });
}
