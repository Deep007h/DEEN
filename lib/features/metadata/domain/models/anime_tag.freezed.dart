// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeTag {

 String get name; int get count;
/// Create a copy of AnimeTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeTagCopyWith<AnimeTag> get copyWith => _$AnimeTagCopyWithImpl<AnimeTag>(this as AnimeTag, _$identity);

  /// Serializes this AnimeTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnimeTag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeTag&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.count, _this.count) || other.count == _this.count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnimeTag;
  return Object.hash(runtimeType,_this.name,_this.count);
}

@override
String toString() {
  final _this = this as AnimeTag;
  return 'AnimeTag(name: ${_this.name}, count: ${_this.count})';
}


}

/// @nodoc
abstract mixin class $AnimeTagCopyWith<$Res>  {
  factory $AnimeTagCopyWith(AnimeTag value, $Res Function(AnimeTag) _then) = _$AnimeTagCopyWithImpl;
@useResult
$Res call({
 String name, int count
});




}
/// @nodoc
class _$AnimeTagCopyWithImpl<$Res>
    implements $AnimeTagCopyWith<$Res> {
  _$AnimeTagCopyWithImpl(this._self, this._then);

  final AnimeTag _self;
  final $Res Function(AnimeTag) _then;

/// Create a copy of AnimeTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? count = null,}) {
  return _then(AnimeTag(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AnimeTag].
extension AnimeTagPatterns on AnimeTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeTag value)  $default,){
final _that = this;
switch (_that) {
case _AnimeTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeTag value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeTag() when $default != null:
return $default(_that.name,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int count)  $default,) {final _that = this;
switch (_that) {
case _AnimeTag():
return $default(_that.name,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int count)?  $default,) {final _that = this;
switch (_that) {
case _AnimeTag() when $default != null:
return $default(_that.name,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeTag implements AnimeTag {
  const _AnimeTag({required this.name, required this.count});
  factory _AnimeTag.fromJson(Map<String, dynamic> json) => _$AnimeTagFromJson(json);

@override final  String name;
@override final  int count;

/// Create a copy of AnimeTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeTagCopyWith<_AnimeTag> get copyWith => __$AnimeTagCopyWithImpl<_AnimeTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeTagToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeTag&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,count);
}

@override
String toString() {
    return 'AnimeTag(name: $name, count: $count)';
}


}

/// @nodoc
abstract mixin class _$AnimeTagCopyWith<$Res> implements $AnimeTagCopyWith<$Res> {
  factory _$AnimeTagCopyWith(_AnimeTag value, $Res Function(_AnimeTag) _then) = __$AnimeTagCopyWithImpl;
@override @useResult
$Res call({
 String name, int count
});




}
/// @nodoc
class __$AnimeTagCopyWithImpl<$Res>
    implements _$AnimeTagCopyWith<$Res> {
  __$AnimeTagCopyWithImpl(this._self, this._then);

  final _AnimeTag _self;
  final $Res Function(_AnimeTag) _then;

/// Create a copy of AnimeTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? count = null,}) {
  return _then(_AnimeTag(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
