// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_vaccine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomVaccine {

 VaccineCode? get code; String? get name; DateTime get givenAt; String? get brand; String? get lot;
/// Create a copy of CustomVaccine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomVaccineCopyWith<CustomVaccine> get copyWith => _$CustomVaccineCopyWithImpl<CustomVaccine>(this as CustomVaccine, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CustomVaccine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomVaccine&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.givenAt, _this.givenAt) || other.givenAt == _this.givenAt)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.lot, _this.lot) || other.lot == _this.lot));
}


@override
int get hashCode {
  final _this = this as CustomVaccine;
  return Object.hash(runtimeType,_this.code,_this.name,_this.givenAt,_this.brand,_this.lot);
}

@override
String toString() {
  final _this = this as CustomVaccine;
  return 'CustomVaccine(code: ${_this.code}, name: ${_this.name}, givenAt: ${_this.givenAt}, brand: ${_this.brand}, lot: ${_this.lot})';
}


}

/// @nodoc
abstract mixin class $CustomVaccineCopyWith<$Res>  {
  factory $CustomVaccineCopyWith(CustomVaccine value, $Res Function(CustomVaccine) _then) = _$CustomVaccineCopyWithImpl;
@useResult
$Res call({
 VaccineCode? code, String? name, DateTime givenAt, String? brand, String? lot
});




}
/// @nodoc
class _$CustomVaccineCopyWithImpl<$Res>
    implements $CustomVaccineCopyWith<$Res> {
  _$CustomVaccineCopyWithImpl(this._self, this._then);

  final CustomVaccine _self;
  final $Res Function(CustomVaccine) _then;

/// Create a copy of CustomVaccine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? name = freezed,Object? givenAt = null,Object? brand = freezed,Object? lot = freezed,}) {
  return _then(CustomVaccine(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as VaccineCode?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomVaccine].
extension CustomVaccinePatterns on CustomVaccine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomVaccine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomVaccine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomVaccine value)  $default,){
final _that = this;
switch (_that) {
case _CustomVaccine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomVaccine value)?  $default,){
final _that = this;
switch (_that) {
case _CustomVaccine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VaccineCode? code,  String? name,  DateTime givenAt,  String? brand,  String? lot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomVaccine() when $default != null:
return $default(_that.code,_that.name,_that.givenAt,_that.brand,_that.lot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VaccineCode? code,  String? name,  DateTime givenAt,  String? brand,  String? lot)  $default,) {final _that = this;
switch (_that) {
case _CustomVaccine():
return $default(_that.code,_that.name,_that.givenAt,_that.brand,_that.lot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VaccineCode? code,  String? name,  DateTime givenAt,  String? brand,  String? lot)?  $default,) {final _that = this;
switch (_that) {
case _CustomVaccine() when $default != null:
return $default(_that.code,_that.name,_that.givenAt,_that.brand,_that.lot);case _:
  return null;

}
}

}

/// @nodoc


class _CustomVaccine extends CustomVaccine {
  const _CustomVaccine({this.code, this.name, required this.givenAt, this.brand, this.lot}): super._();
  

@override final  VaccineCode? code;
@override final  String? name;
@override final  DateTime givenAt;
@override final  String? brand;
@override final  String? lot;

/// Create a copy of CustomVaccine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomVaccineCopyWith<_CustomVaccine> get copyWith => __$CustomVaccineCopyWithImpl<_CustomVaccine>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomVaccine&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.givenAt, givenAt) || other.givenAt == givenAt)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.lot, lot) || other.lot == lot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,name,givenAt,brand,lot);
}

@override
String toString() {
    return 'CustomVaccine(code: $code, name: $name, givenAt: $givenAt, brand: $brand, lot: $lot)';
}


}

/// @nodoc
abstract mixin class _$CustomVaccineCopyWith<$Res> implements $CustomVaccineCopyWith<$Res> {
  factory _$CustomVaccineCopyWith(_CustomVaccine value, $Res Function(_CustomVaccine) _then) = __$CustomVaccineCopyWithImpl;
@override @useResult
$Res call({
 VaccineCode? code, String? name, DateTime givenAt, String? brand, String? lot
});




}
/// @nodoc
class __$CustomVaccineCopyWithImpl<$Res>
    implements _$CustomVaccineCopyWith<$Res> {
  __$CustomVaccineCopyWithImpl(this._self, this._then);

  final _CustomVaccine _self;
  final $Res Function(_CustomVaccine) _then;

/// Create a copy of CustomVaccine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? name = freezed,Object? givenAt = null,Object? brand = freezed,Object? lot = freezed,}) {
  return _then(_CustomVaccine(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as VaccineCode?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
