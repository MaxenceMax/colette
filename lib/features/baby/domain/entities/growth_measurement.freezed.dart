// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'growth_measurement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrowthMeasurement {

 String get id; DateTime get measuredAt; int? get grams; int? get lengthMm; int? get headCircumferenceMm;
/// Create a copy of GrowthMeasurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrowthMeasurementCopyWith<GrowthMeasurement> get copyWith => _$GrowthMeasurementCopyWithImpl<GrowthMeasurement>(this as GrowthMeasurement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GrowthMeasurement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrowthMeasurement&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.measuredAt, _this.measuredAt) || other.measuredAt == _this.measuredAt)&&(identical(other.grams, _this.grams) || other.grams == _this.grams)&&(identical(other.lengthMm, _this.lengthMm) || other.lengthMm == _this.lengthMm)&&(identical(other.headCircumferenceMm, _this.headCircumferenceMm) || other.headCircumferenceMm == _this.headCircumferenceMm));
}


@override
int get hashCode {
  final _this = this as GrowthMeasurement;
  return Object.hash(runtimeType,_this.id,_this.measuredAt,_this.grams,_this.lengthMm,_this.headCircumferenceMm);
}

@override
String toString() {
  final _this = this as GrowthMeasurement;
  return 'GrowthMeasurement(id: ${_this.id}, measuredAt: ${_this.measuredAt}, grams: ${_this.grams}, lengthMm: ${_this.lengthMm}, headCircumferenceMm: ${_this.headCircumferenceMm})';
}


}

/// @nodoc
abstract mixin class $GrowthMeasurementCopyWith<$Res>  {
  factory $GrowthMeasurementCopyWith(GrowthMeasurement value, $Res Function(GrowthMeasurement) _then) = _$GrowthMeasurementCopyWithImpl;
@useResult
$Res call({
 String id, DateTime measuredAt, int? grams, int? lengthMm, int? headCircumferenceMm
});




}
/// @nodoc
class _$GrowthMeasurementCopyWithImpl<$Res>
    implements $GrowthMeasurementCopyWith<$Res> {
  _$GrowthMeasurementCopyWithImpl(this._self, this._then);

  final GrowthMeasurement _self;
  final $Res Function(GrowthMeasurement) _then;

/// Create a copy of GrowthMeasurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? measuredAt = null,Object? grams = freezed,Object? lengthMm = freezed,Object? headCircumferenceMm = freezed,}) {
  return _then(GrowthMeasurement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,measuredAt: null == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int?,lengthMm: freezed == lengthMm ? _self.lengthMm : lengthMm // ignore: cast_nullable_to_non_nullable
as int?,headCircumferenceMm: freezed == headCircumferenceMm ? _self.headCircumferenceMm : headCircumferenceMm // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GrowthMeasurement].
extension GrowthMeasurementPatterns on GrowthMeasurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrowthMeasurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrowthMeasurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrowthMeasurement value)  $default,){
final _that = this;
switch (_that) {
case _GrowthMeasurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrowthMeasurement value)?  $default,){
final _that = this;
switch (_that) {
case _GrowthMeasurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime measuredAt,  int? grams,  int? lengthMm,  int? headCircumferenceMm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrowthMeasurement() when $default != null:
return $default(_that.id,_that.measuredAt,_that.grams,_that.lengthMm,_that.headCircumferenceMm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime measuredAt,  int? grams,  int? lengthMm,  int? headCircumferenceMm)  $default,) {final _that = this;
switch (_that) {
case _GrowthMeasurement():
return $default(_that.id,_that.measuredAt,_that.grams,_that.lengthMm,_that.headCircumferenceMm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime measuredAt,  int? grams,  int? lengthMm,  int? headCircumferenceMm)?  $default,) {final _that = this;
switch (_that) {
case _GrowthMeasurement() when $default != null:
return $default(_that.id,_that.measuredAt,_that.grams,_that.lengthMm,_that.headCircumferenceMm);case _:
  return null;

}
}

}

/// @nodoc


class _GrowthMeasurement implements GrowthMeasurement {
  const _GrowthMeasurement({required this.id, required this.measuredAt, this.grams, this.lengthMm, this.headCircumferenceMm});
  

@override final  String id;
@override final  DateTime measuredAt;
@override final  int? grams;
@override final  int? lengthMm;
@override final  int? headCircumferenceMm;

/// Create a copy of GrowthMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrowthMeasurementCopyWith<_GrowthMeasurement> get copyWith => __$GrowthMeasurementCopyWithImpl<_GrowthMeasurement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrowthMeasurement&&(identical(other.id, id) || other.id == id)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.lengthMm, lengthMm) || other.lengthMm == lengthMm)&&(identical(other.headCircumferenceMm, headCircumferenceMm) || other.headCircumferenceMm == headCircumferenceMm));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,measuredAt,grams,lengthMm,headCircumferenceMm);
}

@override
String toString() {
    return 'GrowthMeasurement(id: $id, measuredAt: $measuredAt, grams: $grams, lengthMm: $lengthMm, headCircumferenceMm: $headCircumferenceMm)';
}


}

/// @nodoc
abstract mixin class _$GrowthMeasurementCopyWith<$Res> implements $GrowthMeasurementCopyWith<$Res> {
  factory _$GrowthMeasurementCopyWith(_GrowthMeasurement value, $Res Function(_GrowthMeasurement) _then) = __$GrowthMeasurementCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime measuredAt, int? grams, int? lengthMm, int? headCircumferenceMm
});




}
/// @nodoc
class __$GrowthMeasurementCopyWithImpl<$Res>
    implements _$GrowthMeasurementCopyWith<$Res> {
  __$GrowthMeasurementCopyWithImpl(this._self, this._then);

  final _GrowthMeasurement _self;
  final $Res Function(_GrowthMeasurement) _then;

/// Create a copy of GrowthMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? measuredAt = null,Object? grams = freezed,Object? lengthMm = freezed,Object? headCircumferenceMm = freezed,}) {
  return _then(_GrowthMeasurement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,measuredAt: null == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int?,lengthMm: freezed == lengthMm ? _self.lengthMm : lengthMm // ignore: cast_nullable_to_non_nullable
as int?,headCircumferenceMm: freezed == headCircumferenceMm ? _self.headCircumferenceMm : headCircumferenceMm // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
