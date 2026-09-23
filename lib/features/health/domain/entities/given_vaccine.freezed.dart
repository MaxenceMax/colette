// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'given_vaccine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GivenVaccine {

 DateTime get givenAt; String? get brand; String? get lot;
/// Create a copy of GivenVaccine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GivenVaccineCopyWith<GivenVaccine> get copyWith => _$GivenVaccineCopyWithImpl<GivenVaccine>(this as GivenVaccine, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GivenVaccine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GivenVaccine&&(identical(other.givenAt, _this.givenAt) || other.givenAt == _this.givenAt)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.lot, _this.lot) || other.lot == _this.lot));
}


@override
int get hashCode {
  final _this = this as GivenVaccine;
  return Object.hash(runtimeType,_this.givenAt,_this.brand,_this.lot);
}

@override
String toString() {
  final _this = this as GivenVaccine;
  return 'GivenVaccine(givenAt: ${_this.givenAt}, brand: ${_this.brand}, lot: ${_this.lot})';
}


}

/// @nodoc
abstract mixin class $GivenVaccineCopyWith<$Res>  {
  factory $GivenVaccineCopyWith(GivenVaccine value, $Res Function(GivenVaccine) _then) = _$GivenVaccineCopyWithImpl;
@useResult
$Res call({
 DateTime givenAt, String? brand, String? lot
});




}
/// @nodoc
class _$GivenVaccineCopyWithImpl<$Res>
    implements $GivenVaccineCopyWith<$Res> {
  _$GivenVaccineCopyWithImpl(this._self, this._then);

  final GivenVaccine _self;
  final $Res Function(GivenVaccine) _then;

/// Create a copy of GivenVaccine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? givenAt = null,Object? brand = freezed,Object? lot = freezed,}) {
  return _then(GivenVaccine(
givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GivenVaccine].
extension GivenVaccinePatterns on GivenVaccine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GivenVaccine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GivenVaccine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GivenVaccine value)  $default,){
final _that = this;
switch (_that) {
case _GivenVaccine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GivenVaccine value)?  $default,){
final _that = this;
switch (_that) {
case _GivenVaccine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime givenAt,  String? brand,  String? lot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GivenVaccine() when $default != null:
return $default(_that.givenAt,_that.brand,_that.lot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime givenAt,  String? brand,  String? lot)  $default,) {final _that = this;
switch (_that) {
case _GivenVaccine():
return $default(_that.givenAt,_that.brand,_that.lot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime givenAt,  String? brand,  String? lot)?  $default,) {final _that = this;
switch (_that) {
case _GivenVaccine() when $default != null:
return $default(_that.givenAt,_that.brand,_that.lot);case _:
  return null;

}
}

}

/// @nodoc


class _GivenVaccine implements GivenVaccine {
  const _GivenVaccine({required this.givenAt, this.brand, this.lot});
  

@override final  DateTime givenAt;
@override final  String? brand;
@override final  String? lot;

/// Create a copy of GivenVaccine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GivenVaccineCopyWith<_GivenVaccine> get copyWith => __$GivenVaccineCopyWithImpl<_GivenVaccine>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GivenVaccine&&(identical(other.givenAt, givenAt) || other.givenAt == givenAt)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.lot, lot) || other.lot == lot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,givenAt,brand,lot);
}

@override
String toString() {
    return 'GivenVaccine(givenAt: $givenAt, brand: $brand, lot: $lot)';
}


}

/// @nodoc
abstract mixin class _$GivenVaccineCopyWith<$Res> implements $GivenVaccineCopyWith<$Res> {
  factory _$GivenVaccineCopyWith(_GivenVaccine value, $Res Function(_GivenVaccine) _then) = __$GivenVaccineCopyWithImpl;
@override @useResult
$Res call({
 DateTime givenAt, String? brand, String? lot
});




}
/// @nodoc
class __$GivenVaccineCopyWithImpl<$Res>
    implements _$GivenVaccineCopyWith<$Res> {
  __$GivenVaccineCopyWithImpl(this._self, this._then);

  final _GivenVaccine _self;
  final $Res Function(_GivenVaccine) _then;

/// Create a copy of GivenVaccine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? givenAt = null,Object? brand = freezed,Object? lot = freezed,}) {
  return _then(_GivenVaccine(
givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
