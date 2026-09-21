// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_age.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BabyAge {

 BabyAgeUnit get unit; int get count;
/// Create a copy of BabyAge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyAgeCopyWith<BabyAge> get copyWith => _$BabyAgeCopyWithImpl<BabyAge>(this as BabyAge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BabyAge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyAge&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.count, _this.count) || other.count == _this.count));
}


@override
int get hashCode {
  final _this = this as BabyAge;
  return Object.hash(runtimeType,_this.unit,_this.count);
}

@override
String toString() {
  final _this = this as BabyAge;
  return 'BabyAge(unit: ${_this.unit}, count: ${_this.count})';
}


}

/// @nodoc
abstract mixin class $BabyAgeCopyWith<$Res>  {
  factory $BabyAgeCopyWith(BabyAge value, $Res Function(BabyAge) _then) = _$BabyAgeCopyWithImpl;
@useResult
$Res call({
 BabyAgeUnit unit, int count
});




}
/// @nodoc
class _$BabyAgeCopyWithImpl<$Res>
    implements $BabyAgeCopyWith<$Res> {
  _$BabyAgeCopyWithImpl(this._self, this._then);

  final BabyAge _self;
  final $Res Function(BabyAge) _then;

/// Create a copy of BabyAge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unit = null,Object? count = null,}) {
  return _then(BabyAge(
unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BabyAgeUnit,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyAge].
extension BabyAgePatterns on BabyAge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyAge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyAge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyAge value)  $default,){
final _that = this;
switch (_that) {
case _BabyAge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyAge value)?  $default,){
final _that = this;
switch (_that) {
case _BabyAge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BabyAgeUnit unit,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyAge() when $default != null:
return $default(_that.unit,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BabyAgeUnit unit,  int count)  $default,) {final _that = this;
switch (_that) {
case _BabyAge():
return $default(_that.unit,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BabyAgeUnit unit,  int count)?  $default,) {final _that = this;
switch (_that) {
case _BabyAge() when $default != null:
return $default(_that.unit,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _BabyAge implements BabyAge {
  const _BabyAge({required this.unit, required this.count});
  

@override final  BabyAgeUnit unit;
@override final  int count;

/// Create a copy of BabyAge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyAgeCopyWith<_BabyAge> get copyWith => __$BabyAgeCopyWithImpl<_BabyAge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyAge&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode {
    return Object.hash(runtimeType,unit,count);
}

@override
String toString() {
    return 'BabyAge(unit: $unit, count: $count)';
}


}

/// @nodoc
abstract mixin class _$BabyAgeCopyWith<$Res> implements $BabyAgeCopyWith<$Res> {
  factory _$BabyAgeCopyWith(_BabyAge value, $Res Function(_BabyAge) _then) = __$BabyAgeCopyWithImpl;
@override @useResult
$Res call({
 BabyAgeUnit unit, int count
});




}
/// @nodoc
class __$BabyAgeCopyWithImpl<$Res>
    implements _$BabyAgeCopyWith<$Res> {
  __$BabyAgeCopyWithImpl(this._self, this._then);

  final _BabyAge _self;
  final $Res Function(_BabyAge) _then;

/// Create a copy of BabyAge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unit = null,Object? count = null,}) {
  return _then(_BabyAge(
unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BabyAgeUnit,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
