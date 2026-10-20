// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Episode _$EpisodeFromJson(Map<String, dynamic> json) => _Episode(
  id: (json['id'] as num).toInt(),
  number: (json['number'] as num).toDouble(),
  sort: (json['sort'] as num).toInt(),
  title: json['title'] as String,
  titleOriginal: json['titleOriginal'] as String?,
  airDate: json['airDate'] as String?,
  duration: json['duration'] as String?,
  summary: json['summary'] as String?,
  type: (json['type'] as num?)?.toInt() ?? 0,
  thumbnail: json['thumbnail'] as String?,
);

Map<String, dynamic> _$EpisodeToJson(_Episode instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'sort': instance.sort,
  'title': instance.title,
  'titleOriginal': instance.titleOriginal,
  'airDate': instance.airDate,
  'duration': instance.duration,
  'summary': instance.summary,
  'type': instance.type,
  'thumbnail': instance.thumbnail,
};
