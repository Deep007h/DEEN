// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Season _$SeasonFromJson(Map<String, dynamic> json) => _Season(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  originalName: json['originalName'] as String?,
  relation: json['relation'] as String?,
  isCurrent: json['isCurrent'] as bool? ?? false,
  posterUrl: json['posterUrl'] as String?,
);

Map<String, dynamic> _$SeasonToJson(_Season instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'originalName': instance.originalName,
  'relation': instance.relation,
  'isCurrent': instance.isCurrent,
  'posterUrl': instance.posterUrl,
};
