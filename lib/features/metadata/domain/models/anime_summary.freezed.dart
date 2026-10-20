// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeSummary {

 int get id; AnimeTitles get titles; String? get posterUrl; double? get score; int? get ratingCount; int? get rank; int? get eps; int? get heat; String? get airDate; String? get platform;
/// Create a copy of AnimeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeSummaryCopyWith<AnimeSummary> get copyWith => _$AnimeSummaryCopyWithImpl<AnimeSummary>(this as AnimeSummary, _$identity);

  /// Serializes this AnimeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnimeSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.titles, _this.titles) || other.titles == _this.titles)&&(identical(other.posterUrl, _this.posterUrl) || other.posterUrl == _this.posterUrl)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.eps, _this.eps) || other.eps == _this.eps)&&(identical(other.heat, _this.heat) || other.heat == _this.heat)&&(identical(other.airDate, _this.airDate) || other.airDate == _this.airDate)&&(identical(other.platform, _this.platform) || other.platform == _this.platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnimeSummary;
  return Object.hash(runtimeType,_this.id,_this.titles,_this.posterUrl,_this.score,_this.ratingCount,_this.rank,_this.eps,_this.heat,_this.airDate,_this.platform);
}

@override
String toString() {
  final _this = this as AnimeSummary;
  return 'AnimeSummary(id: ${_this.id}, titles: ${_this.titles}, posterUrl: ${_this.posterUrl}, score: ${_this.score}, ratingCount: ${_this.ratingCount}, rank: ${_this.rank}, eps: ${_this.eps}, heat: ${_this.heat}, airDate: ${_this.airDate}, platform: ${_this.platform})';
}


}

/// @nodoc
abstract mixin class $AnimeSummaryCopyWith<$Res>  {
  factory $AnimeSummaryCopyWith(AnimeSummary value, $Res Function(AnimeSummary) _then) = _$AnimeSummaryCopyWithImpl;
@useResult
$Res call({
 int id, AnimeTitles titles, String? posterUrl, double? score, int? ratingCount, int? rank, int? eps, int? heat, String? airDate, String? platform
});


$AnimeTitlesCopyWith<$Res> get titles;

}
/// @nodoc
class _$AnimeSummaryCopyWithImpl<$Res>
    implements $AnimeSummaryCopyWith<$Res> {
  _$AnimeSummaryCopyWithImpl(this._self, this._then);

  final AnimeSummary _self;
  final $Res Function(AnimeSummary) _then;

/// Create a copy of AnimeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titles = null,Object? posterUrl = freezed,Object? score = freezed,Object? ratingCount = freezed,Object? rank = freezed,Object? eps = freezed,Object? heat = freezed,Object? airDate = freezed,Object? platform = freezed,}) {
  return _then(AnimeSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titles: null == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as AnimeTitles,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,eps: freezed == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as int?,heat: freezed == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AnimeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeTitlesCopyWith<$Res> get titles {
  
  return $AnimeTitlesCopyWith<$Res>(_self.titles, (value) {
    return _then(_self.copyWith(titles: value));
  });
}
}


/// Adds pattern-matching-related methods to [AnimeSummary].
extension AnimeSummaryPatterns on AnimeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeSummary value)  $default,){
final _that = this;
switch (_that) {
case _AnimeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  AnimeTitles titles,  String? posterUrl,  double? score,  int? ratingCount,  int? rank,  int? eps,  int? heat,  String? airDate,  String? platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeSummary() when $default != null:
return $default(_that.id,_that.titles,_that.posterUrl,_that.score,_that.ratingCount,_that.rank,_that.eps,_that.heat,_that.airDate,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  AnimeTitles titles,  String? posterUrl,  double? score,  int? ratingCount,  int? rank,  int? eps,  int? heat,  String? airDate,  String? platform)  $default,) {final _that = this;
switch (_that) {
case _AnimeSummary():
return $default(_that.id,_that.titles,_that.posterUrl,_that.score,_that.ratingCount,_that.rank,_that.eps,_that.heat,_that.airDate,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  AnimeTitles titles,  String? posterUrl,  double? score,  int? ratingCount,  int? rank,  int? eps,  int? heat,  String? airDate,  String? platform)?  $default,) {final _that = this;
switch (_that) {
case _AnimeSummary() when $default != null:
return $default(_that.id,_that.titles,_that.posterUrl,_that.score,_that.ratingCount,_that.rank,_that.eps,_that.heat,_that.airDate,_that.platform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeSummary implements AnimeSummary {
  const _AnimeSummary({required this.id, required this.titles, this.posterUrl, this.score, this.ratingCount, this.rank, this.eps, this.heat, this.airDate, this.platform});
  factory _AnimeSummary.fromJson(Map<String, dynamic> json) => _$AnimeSummaryFromJson(json);

@override final  int id;
@override final  AnimeTitles titles;
@override final  String? posterUrl;
@override final  double? score;
@override final  int? ratingCount;
@override final  int? rank;
@override final  int? eps;
@override final  int? heat;
@override final  String? airDate;
@override final  String? platform;

/// Create a copy of AnimeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeSummaryCopyWith<_AnimeSummary> get copyWith => __$AnimeSummaryCopyWithImpl<_AnimeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.titles, titles) || other.titles == titles)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.score, score) || other.score == score)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.heat, heat) || other.heat == heat)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,titles,posterUrl,score,ratingCount,rank,eps,heat,airDate,platform);
}

@override
String toString() {
    return 'AnimeSummary(id: $id, titles: $titles, posterUrl: $posterUrl, score: $score, ratingCount: $ratingCount, rank: $rank, eps: $eps, heat: $heat, airDate: $airDate, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$AnimeSummaryCopyWith<$Res> implements $AnimeSummaryCopyWith<$Res> {
  factory _$AnimeSummaryCopyWith(_AnimeSummary value, $Res Function(_AnimeSummary) _then) = __$AnimeSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, AnimeTitles titles, String? posterUrl, double? score, int? ratingCount, int? rank, int? eps, int? heat, String? airDate, String? platform
});


@override $AnimeTitlesCopyWith<$Res> get titles;

}
/// @nodoc
class __$AnimeSummaryCopyWithImpl<$Res>
    implements _$AnimeSummaryCopyWith<$Res> {
  __$AnimeSummaryCopyWithImpl(this._self, this._then);

  final _AnimeSummary _self;
  final $Res Function(_AnimeSummary) _then;

/// Create a copy of AnimeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titles = null,Object? posterUrl = freezed,Object? score = freezed,Object? ratingCount = freezed,Object? rank = freezed,Object? eps = freezed,Object? heat = freezed,Object? airDate = freezed,Object? platform = freezed,}) {
  return _then(_AnimeSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titles: null == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as AnimeTitles,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,eps: freezed == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as int?,heat: freezed == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AnimeSummary
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
