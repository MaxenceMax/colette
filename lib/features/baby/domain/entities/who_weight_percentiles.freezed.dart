// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'who_weight_percentiles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WhoWeightPercentiles {

 int get ageDays; DateTime get date; int get p3Grams; int get p50Grams; int get p97Grams;
/// Create a copy of WhoWeightPercentiles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhoWeightPercentilesCopyWith<WhoWeightPercentiles> get copyWith => _$WhoWeightPercentilesCopyWithImpl<WhoWeightPercentiles>(this as WhoWeightPercentiles, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WhoWeightPercentiles;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhoWeightPercentiles&&(identical(other.ageDays, _this.ageDays) || other.ageDays == _this.ageDays)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.p3Grams, _this.p3Grams) || other.p3Grams == _this.p3Grams)&&(identical(other.p50Grams, _this.p50Grams) || other.p50Grams == _this.p50Grams)&&(identical(other.p97Grams, _this.p97Grams) || other.p97Grams == _this.p97Grams));
}


@override
int get hashCode {
  final _this = this as WhoWeightPercentiles;
  return Object.hash(runtimeType,_this.ageDays,_this.date,_this.p3Grams,_this.p50Grams,_this.p97Grams);
}

@override
String toString() {
  final _this = this as WhoWeightPercentiles;
  return 'WhoWeightPercentiles(ageDays: ${_this.ageDays}, date: ${_this.date}, p3Grams: ${_this.p3Grams}, p50Grams: ${_this.p50Grams}, p97Grams: ${_this.p97Grams})';
}


}

/// @nodoc
abstract mixin class $WhoWeightPercentilesCopyWith<$Res>  {
  factory $WhoWeightPercentilesCopyWith(WhoWeightPercentiles value, $Res Function(WhoWeightPercentiles) _then) = _$WhoWeightPercentilesCopyWithImpl;
@useResult
$Res call({
 int ageDays, DateTime date, int p3Grams, int p50Grams, int p97Grams
});




}
/// @nodoc
class _$WhoWeightPercentilesCopyWithImpl<$Res>
    implements $WhoWeightPercentilesCopyWith<$Res> {
  _$WhoWeightPercentilesCopyWithImpl(this._self, this._then);

  final WhoWeightPercentiles _self;
  final $Res Function(WhoWeightPercentiles) _then;

/// Create a copy of WhoWeightPercentiles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ageDays = null,Object? date = null,Object? p3Grams = null,Object? p50Grams = null,Object? p97Grams = null,}) {
  return _then(WhoWeightPercentiles(
ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,p3Grams: null == p3Grams ? _self.p3Grams : p3Grams // ignore: cast_nullable_to_non_nullable
as int,p50Grams: null == p50Grams ? _self.p50Grams : p50Grams // ignore: cast_nullable_to_non_nullable
as int,p97Grams: null == p97Grams ? _self.p97Grams : p97Grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WhoWeightPercentiles].
extension WhoWeightPercentilesPatterns on WhoWeightPercentiles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhoWeightPercentiles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhoWeightPercentiles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhoWeightPercentiles value)  $default,){
final _that = this;
switch (_that) {
case _WhoWeightPercentiles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhoWeightPercentiles value)?  $default,){
final _that = this;
switch (_that) {
case _WhoWeightPercentiles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ageDays,  DateTime date,  int p3Grams,  int p50Grams,  int p97Grams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhoWeightPercentiles() when $default != null:
return $default(_that.ageDays,_that.date,_that.p3Grams,_that.p50Grams,_that.p97Grams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ageDays,  DateTime date,  int p3Grams,  int p50Grams,  int p97Grams)  $default,) {final _that = this;
switch (_that) {
case _WhoWeightPercentiles():
return $default(_that.ageDays,_that.date,_that.p3Grams,_that.p50Grams,_that.p97Grams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ageDays,  DateTime date,  int p3Grams,  int p50Grams,  int p97Grams)?  $default,) {final _that = this;
switch (_that) {
case _WhoWeightPercentiles() when $default != null:
return $default(_that.ageDays,_that.date,_that.p3Grams,_that.p50Grams,_that.p97Grams);case _:
  return null;

}
}

}

/// @nodoc


class _WhoWeightPercentiles implements WhoWeightPercentiles {
  const _WhoWeightPercentiles({required this.ageDays, required this.date, required this.p3Grams, required this.p50Grams, required this.p97Grams});
  

@override final  int ageDays;
@override final  DateTime date;
@override final  int p3Grams;
@override final  int p50Grams;
@override final  int p97Grams;

/// Create a copy of WhoWeightPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhoWeightPercentilesCopyWith<_WhoWeightPercentiles> get copyWith => __$WhoWeightPercentilesCopyWithImpl<_WhoWeightPercentiles>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhoWeightPercentiles&&(identical(other.ageDays, ageDays) || other.ageDays == ageDays)&&(identical(other.date, date) || other.date == date)&&(identical(other.p3Grams, p3Grams) || other.p3Grams == p3Grams)&&(identical(other.p50Grams, p50Grams) || other.p50Grams == p50Grams)&&(identical(other.p97Grams, p97Grams) || other.p97Grams == p97Grams));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ageDays,date,p3Grams,p50Grams,p97Grams);
}

@override
String toString() {
    return 'WhoWeightPercentiles(ageDays: $ageDays, date: $date, p3Grams: $p3Grams, p50Grams: $p50Grams, p97Grams: $p97Grams)';
}


}

/// @nodoc
abstract mixin class _$WhoWeightPercentilesCopyWith<$Res> implements $WhoWeightPercentilesCopyWith<$Res> {
  factory _$WhoWeightPercentilesCopyWith(_WhoWeightPercentiles value, $Res Function(_WhoWeightPercentiles) _then) = __$WhoWeightPercentilesCopyWithImpl;
@override @useResult
$Res call({
 int ageDays, DateTime date, int p3Grams, int p50Grams, int p97Grams
});




}
/// @nodoc
class __$WhoWeightPercentilesCopyWithImpl<$Res>
    implements _$WhoWeightPercentilesCopyWith<$Res> {
  __$WhoWeightPercentilesCopyWithImpl(this._self, this._then);

  final _WhoWeightPercentiles _self;
  final $Res Function(_WhoWeightPercentiles) _then;

/// Create a copy of WhoWeightPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ageDays = null,Object? date = null,Object? p3Grams = null,Object? p50Grams = null,Object? p97Grams = null,}) {
  return _then(_WhoWeightPercentiles(
ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,p3Grams: null == p3Grams ? _self.p3Grams : p3Grams // ignore: cast_nullable_to_non_nullable
as int,p50Grams: null == p50Grams ? _self.p50Grams : p50Grams // ignore: cast_nullable_to_non_nullable
as int,p97Grams: null == p97Grams ? _self.p97Grams : p97Grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
