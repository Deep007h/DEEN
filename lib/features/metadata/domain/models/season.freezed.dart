// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'season.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Season {

 int get id; String get name; String? get originalName; String? get relation; bool get isCurrent; String? get posterUrl;
/// Create a copy of Season
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonCopyWith<Season> get copyWith => _$SeasonCopyWithImpl<Season>(this as Season, _$identity);

  /// Serializes this Season to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Season;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Season&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.originalName, _this.originalName) || other.originalName == _this.originalName)&&(identical(other.relation, _this.relation) || other.relation == _this.relation)&&(identical(other.isCurrent, _this.isCurrent) || other.isCurrent == _this.isCurrent)&&(identical(other.posterUrl, _this.posterUrl) || other.posterUrl == _this.posterUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Season;
  return Object.hash(runtimeType,_this.id,_this.name,_this.originalName,_this.relation,_this.isCurrent,_this.posterUrl);
}

@override
String toString() {
  final _this = this as Season;
  return 'Season(id: ${_this.id}, name: ${_this.name}, originalName: ${_this.originalName}, relation: ${_this.relation}, isCurrent: ${_this.isCurrent}, posterUrl: ${_this.posterUrl})';
}


}

/// @nodoc
abstract mixin class $SeasonCopyWith<$Res>  {
  factory $SeasonCopyWith(Season value, $Res Function(Season) _then) = _$SeasonCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? originalName, String? relation, bool isCurrent, String? posterUrl
});




}
/// @nodoc
class _$SeasonCopyWithImpl<$Res>
    implements $SeasonCopyWith<$Res> {
  _$SeasonCopyWithImpl(this._self, this._then);

  final Season _self;
  final $Res Function(Season) _then;

/// Create a copy of Season
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? originalName = freezed,Object? relation = freezed,Object? isCurrent = null,Object? posterUrl = freezed,}) {
  return _then(Season(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,originalName: freezed == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String?,relation: freezed == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Season].
extension SeasonPatterns on Season {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Season value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Season() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Season value)  $default,){
final _that = this;
switch (_that) {
case _Season():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Season value)?  $default,){
final _that = this;
switch (_that) {
case _Season() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? originalName,  String? relation,  bool isCurrent,  String? posterUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Season() when $default != null:
return $default(_that.id,_that.name,_that.originalName,_that.relation,_that.isCurrent,_that.posterUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? originalName,  String? relation,  bool isCurrent,  String? posterUrl)  $default,) {final _that = this;
switch (_that) {
case _Season():
return $default(_that.id,_that.name,_that.originalName,_that.relation,_that.isCurrent,_that.posterUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? originalName,  String? relation,  bool isCurrent,  String? posterUrl)?  $default,) {final _that = this;
switch (_that) {
case _Season() when $default != null:
return $default(_that.id,_that.name,_that.originalName,_that.relation,_that.isCurrent,_that.posterUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Season implements Season {
  const _Season({required this.id, required this.name, this.originalName, this.relation, this.isCurrent = false, this.posterUrl});
  factory _Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? originalName;
@override final  String? relation;
@override@JsonKey() final  bool isCurrent;
@override final  String? posterUrl;

/// Create a copy of Season
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeasonCopyWith<_Season> get copyWith => __$SeasonCopyWithImpl<_Season>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeasonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Season&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,originalName,relation,isCurrent,posterUrl);
}

@override
String toString() {
    return 'Season(id: $id, name: $name, originalName: $originalName, relation: $relation, isCurrent: $isCurrent, posterUrl: $posterUrl)';
}


}

/// @nodoc
abstract mixin class _$SeasonCopyWith<$Res> implements $SeasonCopyWith<$Res> {
  factory _$SeasonCopyWith(_Season value, $Res Function(_Season) _then) = __$SeasonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? originalName, String? relation, bool isCurrent, String? posterUrl
});




}
/// @nodoc
class __$SeasonCopyWithImpl<$Res>
    implements _$SeasonCopyWith<$Res> {
  __$SeasonCopyWithImpl(this._self, this._then);

  final _Season _self;
  final $Res Function(_Season) _then;

/// Create a copy of Season
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? originalName = freezed,Object? relation = freezed,Object? isCurrent = null,Object? posterUrl = freezed,}) {
  return _then(_Season(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,originalName: freezed == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String?,relation: freezed == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
