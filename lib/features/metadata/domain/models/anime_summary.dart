import 'package:freezed_annotation/freezed_annotation.dart';
import 'anime_titles.dart';

part 'anime_summary.freezed.dart';
part 'anime_summary.g.dart';

@freezed
abstract class AnimeSummary with _$AnimeSummary {
  const factory AnimeSummary({
    required int id,
    required AnimeTitles titles,
    String? posterUrl,
    double? score,
    int? ratingCount,
    int? rank,
    int? eps,
    int? heat,
    String? airDate,
    String? platform,
  }) = _AnimeSummary;

  factory AnimeSummary.fromJson(Map<String, dynamic> json) => _$AnimeSummaryFromJson(json);
}
