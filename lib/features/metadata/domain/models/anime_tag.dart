import 'package:freezed_annotation/freezed_annotation.dart';

part 'anime_tag.freezed.dart';
part 'anime_tag.g.dart';

@freezed
abstract class AnimeTag with _$AnimeTag {
  const factory AnimeTag({
    required String name,
    required int count,
  }) = _AnimeTag;

  factory AnimeTag.fromJson(Map<String, dynamic> json) => _$AnimeTagFromJson(json);
}
