import 'dart:math';
import '../../../metadata/domain/models/anime_detail.dart';

/// Utility class for normalizing titles and scoring candidate matches.
class TitleMatcher {
  const TitleMatcher();

  /// Normalizes a title by lowercasing, removing punctuation,
  /// and standardizing season/part words.
  static String normalize(String title) {
    if (title.isEmpty) return '';

    var s = title.toLowerCase();

    // Strip apostrophes so "journey's" matches "journeys"
    s = s.replaceAll(RegExp(r"['’]"), '');

    // Standardize Unicode Roman numerals
    s = s.replaceAll('ⅰ', ' 1 ').replaceAll('ⅱ', ' 2 ').replaceAll('ⅲ', ' 3 ')
         .replaceAll('ⅳ', ' 4 ').replaceAll('ⅴ', ' 5 ');
    s = s.replaceAll('Ⅰ', ' 1 ').replaceAll('Ⅱ', ' 2 ').replaceAll('Ⅲ', ' 3 ')
         .replaceAll('Ⅳ', ' 4 ').replaceAll('Ⅴ', ' 5 ');

    // Standardize CJK and English season/part keywords
    s = s.replaceAllMapped(RegExp(r'第\s*(\d+)\s*[季期部分クール]'), (m) => 's${m[1]}');
    s = s.replaceAllMapped(RegExp(r'\bseason\s*(\d+)\b'), (m) => 's${m[1]}');
    s = s.replaceAllMapped(RegExp(r'\b(\d+)(?:st|nd|rd|th)\s*season\b'), (m) => 's${m[1]}');
    s = s.replaceAllMapped(RegExp(r'\bpart\s*(\d+)\b'), (m) => 'p${m[1]}');
    s = s.replaceAllMapped(RegExp(r'\bcour\s*(\d+)\b'), (m) => 'c${m[1]}');
    s = s.replaceAll(RegExp(r'\bii\b'), '2');
    s = s.replaceAll(RegExp(r'\biii\b'), '3');
    s = s.replaceAll(RegExp(r'\biv\b'), '4');

    // Standardize fullwidth tilde, dash, colon
    s = s.replaceAll(RegExp(r'[～〜~：:–—\-_]'), ' ');

    // Replace non-alphanumeric, non-CJK, and non-Hangul punctuation with space
    s = s.replaceAll(RegExp(r'[^\w\s\u4e00-\u9fa5\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]'), ' ');

    // Collapse multiple spaces and trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Calculates a similarity score between 0.0 and 1.0 between two strings.
  static double stringSimilarity(String s1, String s2) {
    final n1 = normalize(s1);
    final n2 = normalize(s2);

    if (n1.isEmpty && n2.isEmpty) return 1.0;
    if (n1.isEmpty || n2.isEmpty) return 0.0;
    if (n1 == n2) return 1.0;

    // Substring containment bonus
    if (n1.contains(n2) || n2.contains(n1)) {
      final ratio = min(n1.length, n2.length) / max(n1.length, n2.length);
      return 0.8 + 0.18 * ratio;
    }

    // Token Jaccard similarity
    final t1 = n1.split(' ').where((w) => w.isNotEmpty).toSet();
    final t2 = n2.split(' ').where((w) => w.isNotEmpty).toSet();
    final intersection = t1.intersection(t2).length;
    final union = t1.union(t2).length;
    final jaccard = union > 0 ? intersection / union : 0.0;

    // Character bigram Dice coefficient
    final bigrams1 = _getBigrams(n1);
    final bigrams2 = _getBigrams(n2);
    if (bigrams1.isEmpty || bigrams2.isEmpty) return jaccard;

    int matches = 0;
    final b2Copy = Map<String, int>.from(bigrams2);
    for (final entry in bigrams1.entries) {
      final countIn2 = b2Copy[entry.key] ?? 0;
      final matched = min(entry.value, countIn2);
      matches += matched;
    }
    final totalBigrams = bigrams1.values.fold(0, (a, b) => a + b) +
        bigrams2.values.fold(0, (a, b) => a + b);
    final dice = totalBigrams > 0 ? (2.0 * matches) / totalBigrams : 0.0;

    return max(jaccard, dice);
  }

  static Map<String, int> _getBigrams(String s) {
    final map = <String, int>{};
    for (int i = 0; i < s.length - 1; i++) {
      final bg = s.substring(i, i + 2);
      map[bg] = (map[bg] ?? 0) + 1;
    }
    return map;
  }

  /// Scores a candidate against all title variants, release year,
  /// and total episode count of an [AnimeDetail].
  static double scoreCandidate({
    required AnimeDetail anime,
    required String candidateTitle,
    String? candidateSub,
    int? candidateYear,
    int? candidateEpisodeCount,
  }) {
    // 1. Title matching against all available variants
    final titlesToTest = <String>[
      if (anime.titles.english != null && anime.titles.english!.isNotEmpty)
        anime.titles.english!,
      if (anime.titles.localized != null && anime.titles.localized!.isNotEmpty)
        anime.titles.localized!,
      if (anime.titles.original.isNotEmpty) anime.titles.original,
    ];

    double bestTitleScore = 0.0;
    for (final title in titlesToTest) {
      final s = stringSimilarity(candidateTitle, title);
      if (s > bestTitleScore) bestTitleScore = s;

      if (candidateSub != null && candidateSub.isNotEmpty) {
        final subScore = stringSimilarity(candidateSub, title);
        if (subScore > bestTitleScore) bestTitleScore = subScore;
      }
    }

    double composite = bestTitleScore;

    // 2. Year correlation
    final animeYear = _parseYear(anime.airDate);
    if (animeYear != null && candidateYear != null) {
      final diff = (animeYear - candidateYear).abs();
      if (diff == 0) {
        composite += 0.08;
      } else if (diff == 1) {
        composite += 0.03;
      } else if (diff > 2) {
        composite -= 0.15;
      }
    }

    // 3. Episode count correlation
    final totalEps = anime.eps ?? (anime.episodes.isNotEmpty ? anime.episodes.length : null);
    if (totalEps != null &&
        totalEps > 0 &&
        candidateEpisodeCount != null &&
        candidateEpisodeCount > 0) {
      final diff = (totalEps - candidateEpisodeCount).abs();
      if (diff == 0) {
        composite += 0.07;
      } else if (diff <= 2) {
        composite += 0.03;
      } else if (diff > 5) {
        composite -= 0.10;
      }
    }

    return composite.clamp(0.0, 1.0);
  }

  static int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.length < 4) return null;
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(dateStr);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
