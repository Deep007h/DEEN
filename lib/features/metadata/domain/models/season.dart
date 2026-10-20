import 'package:freezed_annotation/freezed_annotation.dart';

part 'season.freezed.dart';
part 'season.g.dart';

@freezed
abstract class Season with _$Season {
  const factory Season({
    required int id,
    required String name,
    String? originalName,
    String? relation,
    @Default(false) bool isCurrent,
    String? posterUrl,
  }) = _Season;

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
}
