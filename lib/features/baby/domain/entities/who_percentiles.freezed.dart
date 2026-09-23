// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'who_percentiles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WhoPercentiles {

 int get ageDays; DateTime get date; int get p3; int get p50; int get p97;
/// Create a copy of WhoPercentiles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhoPercentilesCopyWith<WhoPercentiles> get copyWith => _$WhoPercentilesCopyWithImpl<WhoPercentiles>(this as WhoPercentiles, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WhoPercentiles;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhoPercentiles&&(identical(other.ageDays, _this.ageDays) || other.ageDays == _this.ageDays)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.p3, _this.p3) || other.p3 == _this.p3)&&(identical(other.p50, _this.p50) || other.p50 == _this.p50)&&(identical(other.p97, _this.p97) || other.p97 == _this.p97));
}


@override
int get hashCode {
  final _this = this as WhoPercentiles;
  return Object.hash(runtimeType,_this.ageDays,_this.date,_this.p3,_this.p50,_this.p97);
}

@override
String toString() {
  final _this = this as WhoPercentiles;
  return 'WhoPercentiles(ageDays: ${_this.ageDays}, date: ${_this.date}, p3: ${_this.p3}, p50: ${_this.p50}, p97: ${_this.p97})';
}


}

/// @nodoc
abstract mixin class $WhoPercentilesCopyWith<$Res>  {
  factory $WhoPercentilesCopyWith(WhoPercentiles value, $Res Function(WhoPercentiles) _then) = _$WhoPercentilesCopyWithImpl;
@useResult
$Res call({
 int ageDays, DateTime date, int p3, int p50, int p97
});




}
/// @nodoc
class _$WhoPercentilesCopyWithImpl<$Res>
    implements $WhoPercentilesCopyWith<$Res> {
  _$WhoPercentilesCopyWithImpl(this._self, this._then);

  final WhoPercentiles _self;
  final $Res Function(WhoPercentiles) _then;

/// Create a copy of WhoPercentiles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ageDays = null,Object? date = null,Object? p3 = null,Object? p50 = null,Object? p97 = null,}) {
  return _then(WhoPercentiles(
ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,p3: null == p3 ? _self.p3 : p3 // ignore: cast_nullable_to_non_nullable
as int,p50: null == p50 ? _self.p50 : p50 // ignore: cast_nullable_to_non_nullable
as int,p97: null == p97 ? _self.p97 : p97 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WhoPercentiles].
extension WhoPercentilesPatterns on WhoPercentiles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhoPercentiles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhoPercentiles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhoPercentiles value)  $default,){
final _that = this;
switch (_that) {
case _WhoPercentiles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhoPercentiles value)?  $default,){
final _that = this;
switch (_that) {
case _WhoPercentiles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ageDays,  DateTime date,  int p3,  int p50,  int p97)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhoPercentiles() when $default != null:
return $default(_that.ageDays,_that.date,_that.p3,_that.p50,_that.p97);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ageDays,  DateTime date,  int p3,  int p50,  int p97)  $default,) {final _that = this;
switch (_that) {
case _WhoPercentiles():
return $default(_that.ageDays,_that.date,_that.p3,_that.p50,_that.p97);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ageDays,  DateTime date,  int p3,  int p50,  int p97)?  $default,) {final _that = this;
switch (_that) {
case _WhoPercentiles() when $default != null:
return $default(_that.ageDays,_that.date,_that.p3,_that.p50,_that.p97);case _:
  return null;

}
}

}

/// @nodoc


class _WhoPercentiles implements WhoPercentiles {
  const _WhoPercentiles({required this.ageDays, required this.date, required this.p3, required this.p50, required this.p97});
  

@override final  int ageDays;
@override final  DateTime date;
@override final  int p3;
@override final  int p50;
@override final  int p97;

/// Create a copy of WhoPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhoPercentilesCopyWith<_WhoPercentiles> get copyWith => __$WhoPercentilesCopyWithImpl<_WhoPercentiles>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhoPercentiles&&(identical(other.ageDays, ageDays) || other.ageDays == ageDays)&&(identical(other.date, date) || other.date == date)&&(identical(other.p3, p3) || other.p3 == p3)&&(identical(other.p50, p50) || other.p50 == p50)&&(identical(other.p97, p97) || other.p97 == p97));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ageDays,date,p3,p50,p97);
}

@override
String toString() {
    return 'WhoPercentiles(ageDays: $ageDays, date: $date, p3: $p3, p50: $p50, p97: $p97)';
}


}

/// @nodoc
abstract mixin class _$WhoPercentilesCopyWith<$Res> implements $WhoPercentilesCopyWith<$Res> {
  factory _$WhoPercentilesCopyWith(_WhoPercentiles value, $Res Function(_WhoPercentiles) _then) = __$WhoPercentilesCopyWithImpl;
@override @useResult
$Res call({
 int ageDays, DateTime date, int p3, int p50, int p97
});




}
/// @nodoc
class __$WhoPercentilesCopyWithImpl<$Res>
    implements _$WhoPercentilesCopyWith<$Res> {
  __$WhoPercentilesCopyWithImpl(this._self, this._then);

  final _WhoPercentiles _self;
  final $Res Function(_WhoPercentiles) _then;

/// Create a copy of WhoPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ageDays = null,Object? date = null,Object? p3 = null,Object? p50 = null,Object? p97 = null,}) {
  return _then(_WhoPercentiles(
ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,p3: null == p3 ? _self.p3 : p3 // ignore: cast_nullable_to_non_nullable
as int,p50: null == p50 ? _self.p50 : p50 // ignore: cast_nullable_to_non_nullable
as int,p97: null == p97 ? _self.p97 : p97 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
