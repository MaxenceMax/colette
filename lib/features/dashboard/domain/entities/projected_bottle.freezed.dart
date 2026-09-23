// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projected_bottle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectedBottle {

/// Heure centrale de la prise.
 DateTime get at; DateTime get windowStart; DateTime get windowEnd; int get suggestedMl;
/// Create a copy of ProjectedBottle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectedBottleCopyWith<ProjectedBottle> get copyWith => _$ProjectedBottleCopyWithImpl<ProjectedBottle>(this as ProjectedBottle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProjectedBottle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectedBottle&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.windowStart, _this.windowStart) || other.windowStart == _this.windowStart)&&(identical(other.windowEnd, _this.windowEnd) || other.windowEnd == _this.windowEnd)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl));
}


@override
int get hashCode {
  final _this = this as ProjectedBottle;
  return Object.hash(runtimeType,_this.at,_this.windowStart,_this.windowEnd,_this.suggestedMl);
}

@override
String toString() {
  final _this = this as ProjectedBottle;
  return 'ProjectedBottle(at: ${_this.at}, windowStart: ${_this.windowStart}, windowEnd: ${_this.windowEnd}, suggestedMl: ${_this.suggestedMl})';
}


}

/// @nodoc
abstract mixin class $ProjectedBottleCopyWith<$Res>  {
  factory $ProjectedBottleCopyWith(ProjectedBottle value, $Res Function(ProjectedBottle) _then) = _$ProjectedBottleCopyWithImpl;
@useResult
$Res call({
 DateTime at, DateTime windowStart, DateTime windowEnd, int suggestedMl
});




}
/// @nodoc
class _$ProjectedBottleCopyWithImpl<$Res>
    implements $ProjectedBottleCopyWith<$Res> {
  _$ProjectedBottleCopyWithImpl(this._self, this._then);

  final ProjectedBottle _self;
  final $Res Function(ProjectedBottle) _then;

/// Create a copy of ProjectedBottle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? at = null,Object? windowStart = null,Object? windowEnd = null,Object? suggestedMl = null,}) {
  return _then(ProjectedBottle(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectedBottle].
extension ProjectedBottlePatterns on ProjectedBottle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectedBottle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectedBottle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectedBottle value)  $default,){
final _that = this;
switch (_that) {
case _ProjectedBottle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectedBottle value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectedBottle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime at,  DateTime windowStart,  DateTime windowEnd,  int suggestedMl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectedBottle() when $default != null:
return $default(_that.at,_that.windowStart,_that.windowEnd,_that.suggestedMl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime at,  DateTime windowStart,  DateTime windowEnd,  int suggestedMl)  $default,) {final _that = this;
switch (_that) {
case _ProjectedBottle():
return $default(_that.at,_that.windowStart,_that.windowEnd,_that.suggestedMl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime at,  DateTime windowStart,  DateTime windowEnd,  int suggestedMl)?  $default,) {final _that = this;
switch (_that) {
case _ProjectedBottle() when $default != null:
return $default(_that.at,_that.windowStart,_that.windowEnd,_that.suggestedMl);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectedBottle implements ProjectedBottle {
  const _ProjectedBottle({required this.at, required this.windowStart, required this.windowEnd, required this.suggestedMl});
  

/// Heure centrale de la prise.
@override final  DateTime at;
@override final  DateTime windowStart;
@override final  DateTime windowEnd;
@override final  int suggestedMl;

/// Create a copy of ProjectedBottle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectedBottleCopyWith<_ProjectedBottle> get copyWith => __$ProjectedBottleCopyWithImpl<_ProjectedBottle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectedBottle&&(identical(other.at, at) || other.at == at)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,windowStart,windowEnd,suggestedMl);
}

@override
String toString() {
    return 'ProjectedBottle(at: $at, windowStart: $windowStart, windowEnd: $windowEnd, suggestedMl: $suggestedMl)';
}


}

/// @nodoc
abstract mixin class _$ProjectedBottleCopyWith<$Res> implements $ProjectedBottleCopyWith<$Res> {
  factory _$ProjectedBottleCopyWith(_ProjectedBottle value, $Res Function(_ProjectedBottle) _then) = __$ProjectedBottleCopyWithImpl;
@override @useResult
$Res call({
 DateTime at, DateTime windowStart, DateTime windowEnd, int suggestedMl
});




}
/// @nodoc
class __$ProjectedBottleCopyWithImpl<$Res>
    implements _$ProjectedBottleCopyWith<$Res> {
  __$ProjectedBottleCopyWithImpl(this._self, this._then);

  final _ProjectedBottle _self;
  final $Res Function(_ProjectedBottle) _then;

/// Create a copy of ProjectedBottle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? at = null,Object? windowStart = null,Object? windowEnd = null,Object? suggestedMl = null,}) {
  return _then(_ProjectedBottle(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
