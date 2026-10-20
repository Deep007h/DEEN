import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
abstract class Episode with _$Episode {
  const factory Episode({
    required int id,
    required double number,
    required int sort,
    required String title,
    String? titleOriginal,
    String? airDate,
    String? duration,
    String? summary,
    @Default(0) int type,
    String? thumbnail,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
}
