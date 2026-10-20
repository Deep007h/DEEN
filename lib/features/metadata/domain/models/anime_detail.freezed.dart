// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeDetail {

 int get id; AnimeTitles get titles; String? get posterUrl; String? get bannerUrl; String? get summary; double? get score; int? get ratingCount; int? get rank; String? get airDate; int? get eps; String? get platform; List<AnimeTag> get tags; List<Season> get seasons; List<Episode> get episodes;
/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeDetailCopyWith<AnimeDetail> get copyWith => _$AnimeDetailCopyWithImpl<AnimeDetail>(this as AnimeDetail, _$identity);

  /// Serializes this AnimeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnimeDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.titles, _this.titles) || other.titles == _this.titles)&&(identical(other.posterUrl, _this.posterUrl) || other.posterUrl == _this.posterUrl)&&(identical(other.bannerUrl, _this.bannerUrl) || other.bannerUrl == _this.bannerUrl)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.airDate, _this.airDate) || other.airDate == _this.airDate)&&(identical(other.eps, _this.eps) || other.eps == _this.eps)&&(identical(other.platform, _this.platform) || other.platform == _this.platform)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.seasons, _this.seasons)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnimeDetail;
  return Object.hash(runtimeType,_this.id,_this.titles,_this.posterUrl,_this.bannerUrl,_this.summary,_this.score,_this.ratingCount,_this.rank,_this.airDate,_this.eps,_this.platform,const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.seasons),const DeepCollectionEquality().hash(_this.episodes));
}

@override
String toString() {
  final _this = this as AnimeDetail;
  return 'AnimeDetail(id: ${_this.id}, titles: ${_this.titles}, posterUrl: ${_this.posterUrl}, bannerUrl: ${_this.bannerUrl}, summary: ${_this.summary}, score: ${_this.score}, ratingCount: ${_this.ratingCount}, rank: ${_this.rank}, airDate: ${_this.airDate}, eps: ${_this.eps}, platform: ${_this.platform}, tags: ${_this.tags}, seasons: ${_this.seasons}, episodes: ${_this.episodes})';
}


}

/// @nodoc
abstract mixin class $AnimeDetailCopyWith<$Res>  {
  factory $AnimeDetailCopyWith(AnimeDetail value, $Res Function(AnimeDetail) _then) = _$AnimeDetailCopyWithImpl;
@useResult
$Res call({
 int id, AnimeTitles titles, String? posterUrl, String? bannerUrl, String? summary, double? score, int? ratingCount, int? rank, String? airDate, int? eps, String? platform, List<AnimeTag> tags, List<Season> seasons, List<Episode> episodes
});


$AnimeTitlesCopyWith<$Res> get titles;

}
/// @nodoc
class _$AnimeDetailCopyWithImpl<$Res>
    implements $AnimeDetailCopyWith<$Res> {
  _$AnimeDetailCopyWithImpl(this._self, this._then);

  final AnimeDetail _self;
  final $Res Function(AnimeDetail) _then;

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titles = null,Object? posterUrl = freezed,Object? bannerUrl = freezed,Object? summary = freezed,Object? score = freezed,Object? ratingCount = freezed,Object? rank = freezed,Object? airDate = freezed,Object? eps = freezed,Object? platform = freezed,Object? tags = null,Object? seasons = null,Object? episodes = null,}) {
  return _then(AnimeDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titles: null == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as AnimeTitles,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,eps: freezed == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as int?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<AnimeTag>,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<Season>,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<Episode>,
  ));
}
/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeTitlesCopyWith<$Res> get titles {
  
  return $AnimeTitlesCopyWith<$Res>(_self.titles, (value) {
    return _then(_self.copyWith(titles: value));
  });
}
}


/// Adds pattern-matching-related methods to [AnimeDetail].
extension AnimeDetailPatterns on AnimeDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeDetail value)  $default,){
final _that = this;
switch (_that) {
case _AnimeDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  AnimeTitles titles,  String? posterUrl,  String? bannerUrl,  String? summary,  double? score,  int? ratingCount,  int? rank,  String? airDate,  int? eps,  String? platform,  List<AnimeTag> tags,  List<Season> seasons,  List<Episode> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that.id,_that.titles,_that.posterUrl,_that.bannerUrl,_that.summary,_that.score,_that.ratingCount,_that.rank,_that.airDate,_that.eps,_that.platform,_that.tags,_that.seasons,_that.episodes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  AnimeTitles titles,  String? posterUrl,  String? bannerUrl,  String? summary,  double? score,  int? ratingCount,  int? rank,  String? airDate,  int? eps,  String? platform,  List<AnimeTag> tags,  List<Season> seasons,  List<Episode> episodes)  $default,) {final _that = this;
switch (_that) {
case _AnimeDetail():
return $default(_that.id,_that.titles,_that.posterUrl,_that.bannerUrl,_that.summary,_that.score,_that.ratingCount,_that.rank,_that.airDate,_that.eps,_that.platform,_that.tags,_that.seasons,_that.episodes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  AnimeTitles titles,  String? posterUrl,  String? bannerUrl,  String? summary,  double? score,  int? ratingCount,  int? rank,  String? airDate,  int? eps,  String? platform,  List<AnimeTag> tags,  List<Season> seasons,  List<Episode> episodes)?  $default,) {final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that.id,_that.titles,_that.posterUrl,_that.bannerUrl,_that.summary,_that.score,_that.ratingCount,_that.rank,_that.airDate,_that.eps,_that.platform,_that.tags,_that.seasons,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeDetail implements AnimeDetail {
  const _AnimeDetail({required this.id, required this.titles, this.posterUrl, this.bannerUrl, this.summary, this.score, this.ratingCount, this.rank, this.airDate, this.eps, this.platform,  List<AnimeTag> tags = const [],  List<Season> seasons = const [],  List<Episode> episodes = const []}): _tags = tags,_seasons = seasons,_episodes = episodes;
  factory _AnimeDetail.fromJson(Map<String, dynamic> json) => _$AnimeDetailFromJson(json);

@override final  int id;
@override final  AnimeTitles titles;
@override final  String? posterUrl;
@override final  String? bannerUrl;
@override final  String? summary;
@override final  double? score;
@override final  int? ratingCount;
@override final  int? rank;
@override final  String? airDate;
@override final  int? eps;
@override final  String? platform;
 final  List<AnimeTag> _tags;
@override@JsonKey() List<AnimeTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<Season> _seasons;
@override@JsonKey() List<Season> get seasons {
  if (_seasons is EqualUnmodifiableListView) return _seasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seasons);
}

 final  List<Episode> _episodes;
@override@JsonKey() List<Episode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}


/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeDetailCopyWith<_AnimeDetail> get copyWith => __$AnimeDetailCopyWithImpl<_AnimeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.titles, titles) || other.titles == titles)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.score, score) || other.score == score)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.platform, platform) || other.platform == platform)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.seasons, _seasons)&&const DeepCollectionEquality().equals(other.episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,titles,posterUrl,bannerUrl,summary,score,ratingCount,rank,airDate,eps,platform,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_seasons),const DeepCollectionEquality().hash(_episodes));
}

@override
String toString() {
    return 'AnimeDetail(id: $id, titles: $titles, posterUrl: $posterUrl, bannerUrl: $bannerUrl, summary: $summary, score: $score, ratingCount: $ratingCount, rank: $rank, airDate: $airDate, eps: $eps, platform: $platform, tags: $tags, seasons: $seasons, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$AnimeDetailCopyWith<$Res> implements $AnimeDetailCopyWith<$Res> {
  factory _$AnimeDetailCopyWith(_AnimeDetail value, $Res Function(_AnimeDetail) _then) = __$AnimeDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, AnimeTitles titles, String? posterUrl, String? bannerUrl, String? summary, double? score, int? ratingCount, int? rank, String? airDate, int? eps, String? platform, List<AnimeTag> tags, List<Season> seasons, List<Episode> episodes
});


@override $AnimeTitlesCopyWith<$Res> get titles;

}
/// @nodoc
class __$AnimeDetailCopyWithImpl<$Res>
    implements _$AnimeDetailCopyWith<$Res> {
  __$AnimeDetailCopyWithImpl(this._self, this._then);

  final _AnimeDetail _self;
  final $Res Function(_AnimeDetail) _then;

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titles = null,Object? posterUrl = freezed,Object? bannerUrl = freezed,Object? summary = freezed,Object? score = freezed,Object? ratingCount = freezed,Object? rank = freezed,Object? airDate = freezed,Object? eps = freezed,Object? platform = freezed,Object? tags = null,Object? seasons = null,Object? episodes = null,}) {
  return _then(_AnimeDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titles: null == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as AnimeTitles,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,eps: freezed == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as int?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<AnimeTag>,seasons: null == seasons ? _self._seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<Season>,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<Episode>,
  ));
}

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeTitlesCopyWith<$Res> get titles {
  
  return $AnimeTitlesCopyWith<$Res>(_self.titles, (value) {
    return _then(_self.copyWith(titles: value));
  });
}
}

// dart format on
