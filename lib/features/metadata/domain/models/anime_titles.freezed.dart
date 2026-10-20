// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_titles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeTitles {

 String get original; String? get english; String? get localized;
/// Create a copy of AnimeTitles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeTitlesCopyWith<AnimeTitles> get copyWith => _$AnimeTitlesCopyWithImpl<AnimeTitles>(this as AnimeTitles, _$identity);

  /// Serializes this AnimeTitles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnimeTitles;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeTitles&&(identical(other.original, _this.original) || other.original == _this.original)&&(identical(other.english, _this.english) || other.english == _this.english)&&(identical(other.localized, _this.localized) || other.localized == _this.localized));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnimeTitles;
  return Object.hash(runtimeType,_this.original,_this.english,_this.localized);
}

@override
String toString() {
  final _this = this as AnimeTitles;
  return 'AnimeTitles(original: ${_this.original}, english: ${_this.english}, localized: ${_this.localized})';
}


}

/// @nodoc
abstract mixin class $AnimeTitlesCopyWith<$Res>  {
  factory $AnimeTitlesCopyWith(AnimeTitles value, $Res Function(AnimeTitles) _then) = _$AnimeTitlesCopyWithImpl;
@useResult
$Res call({
 String original, String? english, String? localized
});




}
/// @nodoc
class _$AnimeTitlesCopyWithImpl<$Res>
    implements $AnimeTitlesCopyWith<$Res> {
  _$AnimeTitlesCopyWithImpl(this._self, this._then);

  final AnimeTitles _self;
  final $Res Function(AnimeTitles) _then;

/// Create a copy of AnimeTitles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? original = null,Object? english = freezed,Object? localized = freezed,}) {
  return _then(AnimeTitles(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,english: freezed == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String?,localized: freezed == localized ? _self.localized : localized // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnimeTitles].
extension AnimeTitlesPatterns on AnimeTitles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeTitles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeTitles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeTitles value)  $default,){
final _that = this;
switch (_that) {
case _AnimeTitles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeTitles value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeTitles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String original,  String? english,  String? localized)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeTitles() when $default != null:
return $default(_that.original,_that.english,_that.localized);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String original,  String? english,  String? localized)  $default,) {final _that = this;
switch (_that) {
case _AnimeTitles():
return $default(_that.original,_that.english,_that.localized);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String original,  String? english,  String? localized)?  $default,) {final _that = this;
switch (_that) {
case _AnimeTitles() when $default != null:
return $default(_that.original,_that.english,_that.localized);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeTitles extends AnimeTitles {
  const _AnimeTitles({required this.original, this.english, this.localized}): super._();
  factory _AnimeTitles.fromJson(Map<String, dynamic> json) => _$AnimeTitlesFromJson(json);

@override final  String original;
@override final  String? english;
@override final  String? localized;

/// Create a copy of AnimeTitles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeTitlesCopyWith<_AnimeTitles> get copyWith => __$AnimeTitlesCopyWithImpl<_AnimeTitles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeTitlesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeTitles&&(identical(other.original, original) || other.original == original)&&(identical(other.english, english) || other.english == english)&&(identical(other.localized, localized) || other.localized == localized));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,original,english,localized);
}

@override
String toString() {
    return 'AnimeTitles(original: $original, english: $english, localized: $localized)';
}


}

/// @nodoc
abstract mixin class _$AnimeTitlesCopyWith<$Res> implements $AnimeTitlesCopyWith<$Res> {
  factory _$AnimeTitlesCopyWith(_AnimeTitles value, $Res Function(_AnimeTitles) _then) = __$AnimeTitlesCopyWithImpl;
@override @useResult
$Res call({
 String original, String? english, String? localized
});




}
/// @nodoc
class __$AnimeTitlesCopyWithImpl<$Res>
    implements _$AnimeTitlesCopyWith<$Res> {
  __$AnimeTitlesCopyWithImpl(this._self, this._then);

  final _AnimeTitles _self;
  final $Res Function(_AnimeTitles) _then;

/// Create a copy of AnimeTitles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? original = null,Object? english = freezed,Object? localized = freezed,}) {
  return _then(_AnimeTitles(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,english: freezed == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String?,localized: freezed == localized ? _self.localized : localized // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
