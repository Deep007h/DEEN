// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnimeSummary _$AnimeSummaryFromJson(Map<String, dynamic> json) =>
    _AnimeSummary(
      id: (json['id'] as num).toInt(),
      titles: AnimeTitles.fromJson(json['titles'] as Map<String, dynamic>),
      posterUrl: json['posterUrl'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      rank: (json['rank'] as num?)?.toInt(),
      eps: (json['eps'] as num?)?.toInt(),
      heat: (json['heat'] as num?)?.toInt(),
      airDate: json['airDate'] as String?,
      platform: json['platform'] as String?,
    );

Map<String, dynamic> _$AnimeSummaryToJson(_AnimeSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titles': instance.titles,
      'posterUrl': instance.posterUrl,
      'score': instance.score,
      'ratingCount': instance.ratingCount,
      'rank': instance.rank,
      'eps': instance.eps,
      'heat': instance.heat,
      'airDate': instance.airDate,
      'platform': instance.platform,
    };
