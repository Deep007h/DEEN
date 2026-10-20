// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnimeDetail _$AnimeDetailFromJson(Map<String, dynamic> json) => _AnimeDetail(
  id: (json['id'] as num).toInt(),
  titles: AnimeTitles.fromJson(json['titles'] as Map<String, dynamic>),
  posterUrl: json['posterUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  summary: json['summary'] as String?,
  score: (json['score'] as num?)?.toDouble(),
  ratingCount: (json['ratingCount'] as num?)?.toInt(),
  rank: (json['rank'] as num?)?.toInt(),
  airDate: json['airDate'] as String?,
  eps: (json['eps'] as num?)?.toInt(),
  platform: json['platform'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => AnimeTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  episodes:
      (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AnimeDetailToJson(_AnimeDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titles': instance.titles,
      'posterUrl': instance.posterUrl,
      'bannerUrl': instance.bannerUrl,
      'summary': instance.summary,
      'score': instance.score,
      'ratingCount': instance.ratingCount,
      'rank': instance.rank,
      'airDate': instance.airDate,
      'eps': instance.eps,
      'platform': instance.platform,
      'tags': instance.tags,
      'seasons': instance.seasons,
      'episodes': instance.episodes,
    };
