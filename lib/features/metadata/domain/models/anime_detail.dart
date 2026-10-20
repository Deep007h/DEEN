import 'package:freezed_annotation/freezed_annotation.dart';
import 'anime_titles.dart';
import 'anime_tag.dart';
import 'season.dart';
import 'episode.dart';

part 'anime_detail.freezed.dart';
part 'anime_detail.g.dart';

@freezed
abstract class AnimeDetail with _$AnimeDetail {
  const factory AnimeDetail({
    required int id,
    required AnimeTitles titles,
    String? posterUrl,
    String? bannerUrl,
    String? summary,
    double? score,
    int? ratingCount,
    int? rank,
    String? airDate,
    int? eps,
    String? platform,
    @Default([]) List<AnimeTag> tags,
    @Default([]) List<Season> seasons,
    @Default([]) List<Episode> episodes,
  }) = _AnimeDetail;

  factory AnimeDetail.fromJson(Map<String, dynamic> json) => _$AnimeDetailFromJson(json);
}
