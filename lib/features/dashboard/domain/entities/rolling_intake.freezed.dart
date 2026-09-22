// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rolling_intake.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RollingIntake {

 int get bottles; int get ml;
/// Create a copy of RollingIntake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RollingIntakeCopyWith<RollingIntake> get copyWith => _$RollingIntakeCopyWithImpl<RollingIntake>(this as RollingIntake, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RollingIntake;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RollingIntake&&(identical(other.bottles, _this.bottles) || other.bottles == _this.bottles)&&(identical(other.ml, _this.ml) || other.ml == _this.ml));
}


@override
int get hashCode {
  final _this = this as RollingIntake;
  return Object.hash(runtimeType,_this.bottles,_this.ml);
}

@override
String toString() {
  final _this = this as RollingIntake;
  return 'RollingIntake(bottles: ${_this.bottles}, ml: ${_this.ml})';
}


}

/// @nodoc
abstract mixin class $RollingIntakeCopyWith<$Res>  {
  factory $RollingIntakeCopyWith(RollingIntake value, $Res Function(RollingIntake) _then) = _$RollingIntakeCopyWithImpl;
@useResult
$Res call({
 int bottles, int ml
});




}
/// @nodoc
class _$RollingIntakeCopyWithImpl<$Res>
    implements $RollingIntakeCopyWith<$Res> {
  _$RollingIntakeCopyWithImpl(this._self, this._then);

  final RollingIntake _self;
  final $Res Function(RollingIntake) _then;

/// Create a copy of RollingIntake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bottles = null,Object? ml = null,}) {
  return _then(RollingIntake(
bottles: null == bottles ? _self.bottles : bottles // ignore: cast_nullable_to_non_nullable
as int,ml: null == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RollingIntake].
extension RollingIntakePatterns on RollingIntake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RollingIntake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RollingIntake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RollingIntake value)  $default,){
final _that = this;
switch (_that) {
case _RollingIntake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RollingIntake value)?  $default,){
final _that = this;
switch (_that) {
case _RollingIntake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bottles,  int ml)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RollingIntake() when $default != null:
return $default(_that.bottles,_that.ml);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bottles,  int ml)  $default,) {final _that = this;
switch (_that) {
case _RollingIntake():
return $default(_that.bottles,_that.ml);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bottles,  int ml)?  $default,) {final _that = this;
switch (_that) {
case _RollingIntake() when $default != null:
return $default(_that.bottles,_that.ml);case _:
  return null;

}
}

}

/// @nodoc


class _RollingIntake implements RollingIntake {
  const _RollingIntake({required this.bottles, required this.ml});
  

@override final  int bottles;
@override final  int ml;

/// Create a copy of RollingIntake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RollingIntakeCopyWith<_RollingIntake> get copyWith => __$RollingIntakeCopyWithImpl<_RollingIntake>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RollingIntake&&(identical(other.bottles, bottles) || other.bottles == bottles)&&(identical(other.ml, ml) || other.ml == ml));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bottles,ml);
}

@override
String toString() {
    return 'RollingIntake(bottles: $bottles, ml: $ml)';
}


}

/// @nodoc
abstract mixin class _$RollingIntakeCopyWith<$Res> implements $RollingIntakeCopyWith<$Res> {
  factory _$RollingIntakeCopyWith(_RollingIntake value, $Res Function(_RollingIntake) _then) = __$RollingIntakeCopyWithImpl;
@override @useResult
$Res call({
 int bottles, int ml
});




}
/// @nodoc
class __$RollingIntakeCopyWithImpl<$Res>
    implements _$RollingIntakeCopyWith<$Res> {
  __$RollingIntakeCopyWithImpl(this._self, this._then);

  final _RollingIntake _self;
  final $Res Function(_RollingIntake) _then;

/// Create a copy of RollingIntake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bottles = null,Object? ml = null,}) {
  return _then(_RollingIntake(
bottles: null == bottles ? _self.bottles : bottles // ignore: cast_nullable_to_non_nullable
as int,ml: null == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
