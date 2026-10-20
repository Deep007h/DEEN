// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Episode {

 int get id; double get number; int get sort; String get title; String? get titleOriginal; String? get airDate; String? get duration; String? get summary; int get type; String? get thumbnail;
/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeCopyWith<Episode> get copyWith => _$EpisodeCopyWithImpl<Episode>(this as Episode, _$identity);

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Episode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Episode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.titleOriginal, _this.titleOriginal) || other.titleOriginal == _this.titleOriginal)&&(identical(other.airDate, _this.airDate) || other.airDate == _this.airDate)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.thumbnail, _this.thumbnail) || other.thumbnail == _this.thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Episode;
  return Object.hash(runtimeType,_this.id,_this.number,_this.sort,_this.title,_this.titleOriginal,_this.airDate,_this.duration,_this.summary,_this.type,_this.thumbnail);
}

@override
String toString() {
  final _this = this as Episode;
  return 'Episode(id: ${_this.id}, number: ${_this.number}, sort: ${_this.sort}, title: ${_this.title}, titleOriginal: ${_this.titleOriginal}, airDate: ${_this.airDate}, duration: ${_this.duration}, summary: ${_this.summary}, type: ${_this.type}, thumbnail: ${_this.thumbnail})';
}


}

/// @nodoc
abstract mixin class $EpisodeCopyWith<$Res>  {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) _then) = _$EpisodeCopyWithImpl;
@useResult
$Res call({
 int id, double number, int sort, String title, String? titleOriginal, String? airDate, String? duration, String? summary, int type, String? thumbnail
});




}
/// @nodoc
class _$EpisodeCopyWithImpl<$Res>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._self, this._then);

  final Episode _self;
  final $Res Function(Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? sort = null,Object? title = null,Object? titleOriginal = freezed,Object? airDate = freezed,Object? duration = freezed,Object? summary = freezed,Object? type = null,Object? thumbnail = freezed,}) {
  return _then(Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as double,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,titleOriginal: freezed == titleOriginal ? _self.titleOriginal : titleOriginal // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Episode].
extension EpisodePatterns on Episode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Episode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Episode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Episode value)  $default,){
final _that = this;
switch (_that) {
case _Episode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Episode value)?  $default,){
final _that = this;
switch (_that) {
case _Episode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  double number,  int sort,  String title,  String? titleOriginal,  String? airDate,  String? duration,  String? summary,  int type,  String? thumbnail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.number,_that.sort,_that.title,_that.titleOriginal,_that.airDate,_that.duration,_that.summary,_that.type,_that.thumbnail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  double number,  int sort,  String title,  String? titleOriginal,  String? airDate,  String? duration,  String? summary,  int type,  String? thumbnail)  $default,) {final _that = this;
switch (_that) {
case _Episode():
return $default(_that.id,_that.number,_that.sort,_that.title,_that.titleOriginal,_that.airDate,_that.duration,_that.summary,_that.type,_that.thumbnail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  double number,  int sort,  String title,  String? titleOriginal,  String? airDate,  String? duration,  String? summary,  int type,  String? thumbnail)?  $default,) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.number,_that.sort,_that.title,_that.titleOriginal,_that.airDate,_that.duration,_that.summary,_that.type,_that.thumbnail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Episode implements Episode {
  const _Episode({required this.id, required this.number, required this.sort, required this.title, this.titleOriginal, this.airDate, this.duration, this.summary, this.type = 0, this.thumbnail});
  factory _Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

@override final  int id;
@override final  double number;
@override final  int sort;
@override final  String title;
@override final  String? titleOriginal;
@override final  String? airDate;
@override final  String? duration;
@override final  String? summary;
@override@JsonKey() final  int type;
@override final  String? thumbnail;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpisodeCopyWith<_Episode> get copyWith => __$EpisodeCopyWithImpl<_Episode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Episode&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.title, title) || other.title == title)&&(identical(other.titleOriginal, titleOriginal) || other.titleOriginal == titleOriginal)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.type, type) || other.type == type)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,number,sort,title,titleOriginal,airDate,duration,summary,type,thumbnail);
}

@override
String toString() {
    return 'Episode(id: $id, number: $number, sort: $sort, title: $title, titleOriginal: $titleOriginal, airDate: $airDate, duration: $duration, summary: $summary, type: $type, thumbnail: $thumbnail)';
}


}

/// @nodoc
abstract mixin class _$EpisodeCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$EpisodeCopyWith(_Episode value, $Res Function(_Episode) _then) = __$EpisodeCopyWithImpl;
@override @useResult
$Res call({
 int id, double number, int sort, String title, String? titleOriginal, String? airDate, String? duration, String? summary, int type, String? thumbnail
});




}
/// @nodoc
class __$EpisodeCopyWithImpl<$Res>
    implements _$EpisodeCopyWith<$Res> {
  __$EpisodeCopyWithImpl(this._self, this._then);

  final _Episode _self;
  final $Res Function(_Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? sort = null,Object? title = null,Object? titleOriginal = freezed,Object? airDate = freezed,Object? duration = freezed,Object? summary = freezed,Object? type = null,Object? thumbnail = freezed,}) {
  return _then(_Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as double,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,titleOriginal: freezed == titleOriginal ? _self.titleOriginal : titleOriginal // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
