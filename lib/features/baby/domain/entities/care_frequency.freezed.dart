// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_frequency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareFrequency {

 int get timesPerDay; int get everyDays; bool get enabled;
/// Create a copy of CareFrequency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<CareFrequency> get copyWith => _$CareFrequencyCopyWithImpl<CareFrequency>(this as CareFrequency, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CareFrequency;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareFrequency&&(identical(other.timesPerDay, _this.timesPerDay) || other.timesPerDay == _this.timesPerDay)&&(identical(other.everyDays, _this.everyDays) || other.everyDays == _this.everyDays)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}


@override
int get hashCode {
  final _this = this as CareFrequency;
  return Object.hash(runtimeType,_this.timesPerDay,_this.everyDays,_this.enabled);
}

@override
String toString() {
  final _this = this as CareFrequency;
  return 'CareFrequency(timesPerDay: ${_this.timesPerDay}, everyDays: ${_this.everyDays}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $CareFrequencyCopyWith<$Res>  {
  factory $CareFrequencyCopyWith(CareFrequency value, $Res Function(CareFrequency) _then) = _$CareFrequencyCopyWithImpl;
@useResult
$Res call({
 int timesPerDay, int everyDays, bool enabled
});




}
/// @nodoc
class _$CareFrequencyCopyWithImpl<$Res>
    implements $CareFrequencyCopyWith<$Res> {
  _$CareFrequencyCopyWithImpl(this._self, this._then);

  final CareFrequency _self;
  final $Res Function(CareFrequency) _then;

/// Create a copy of CareFrequency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timesPerDay = null,Object? everyDays = null,Object? enabled = null,}) {
  return _then(CareFrequency(
timesPerDay: null == timesPerDay ? _self.timesPerDay : timesPerDay // ignore: cast_nullable_to_non_nullable
as int,everyDays: null == everyDays ? _self.everyDays : everyDays // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CareFrequency].
extension CareFrequencyPatterns on CareFrequency {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareFrequency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareFrequency() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareFrequency value)  $default,){
final _that = this;
switch (_that) {
case _CareFrequency():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareFrequency value)?  $default,){
final _that = this;
switch (_that) {
case _CareFrequency() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int timesPerDay,  int everyDays,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareFrequency() when $default != null:
return $default(_that.timesPerDay,_that.everyDays,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int timesPerDay,  int everyDays,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _CareFrequency():
return $default(_that.timesPerDay,_that.everyDays,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int timesPerDay,  int everyDays,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _CareFrequency() when $default != null:
return $default(_that.timesPerDay,_that.everyDays,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _CareFrequency extends CareFrequency {
  const _CareFrequency({this.timesPerDay = 1, this.everyDays = 1, this.enabled = true}): super._();
  

@override@JsonKey() final  int timesPerDay;
@override@JsonKey() final  int everyDays;
@override@JsonKey() final  bool enabled;

/// Create a copy of CareFrequency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareFrequencyCopyWith<_CareFrequency> get copyWith => __$CareFrequencyCopyWithImpl<_CareFrequency>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareFrequency&&(identical(other.timesPerDay, timesPerDay) || other.timesPerDay == timesPerDay)&&(identical(other.everyDays, everyDays) || other.everyDays == everyDays)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode {
    return Object.hash(runtimeType,timesPerDay,everyDays,enabled);
}

@override
String toString() {
    return 'CareFrequency(timesPerDay: $timesPerDay, everyDays: $everyDays, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$CareFrequencyCopyWith<$Res> implements $CareFrequencyCopyWith<$Res> {
  factory _$CareFrequencyCopyWith(_CareFrequency value, $Res Function(_CareFrequency) _then) = __$CareFrequencyCopyWithImpl;
@override @useResult
$Res call({
 int timesPerDay, int everyDays, bool enabled
});




}
/// @nodoc
class __$CareFrequencyCopyWithImpl<$Res>
    implements _$CareFrequencyCopyWith<$Res> {
  __$CareFrequencyCopyWithImpl(this._self, this._then);

  final _CareFrequency _self;
  final $Res Function(_CareFrequency) _then;

/// Create a copy of CareFrequency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timesPerDay = null,Object? everyDays = null,Object? enabled = null,}) {
  return _then(_CareFrequency(
timesPerDay: null == timesPerDay ? _self.timesPerDay : timesPerDay // ignore: cast_nullable_to_non_nullable
as int,everyDays: null == everyDays ? _self.everyDays : everyDays // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
