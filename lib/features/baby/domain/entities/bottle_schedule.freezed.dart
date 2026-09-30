// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bottle_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BottleSchedule {

/// Heure du premier biberon, depuis minuit.
 Duration get firstBottle;/// Heure du biberon du soir, depuis minuit ; rien n'est prévu après.
 Duration get lastBottle;/// Temps entre deux biberons de journée.
 Duration get interval;
/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottleScheduleCopyWith<BottleSchedule> get copyWith => _$BottleScheduleCopyWithImpl<BottleSchedule>(this as BottleSchedule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BottleSchedule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottleSchedule&&(identical(other.firstBottle, _this.firstBottle) || other.firstBottle == _this.firstBottle)&&(identical(other.lastBottle, _this.lastBottle) || other.lastBottle == _this.lastBottle)&&(identical(other.interval, _this.interval) || other.interval == _this.interval));
}


@override
int get hashCode {
  final _this = this as BottleSchedule;
  return Object.hash(runtimeType,_this.firstBottle,_this.lastBottle,_this.interval);
}

@override
String toString() {
  final _this = this as BottleSchedule;
  return 'BottleSchedule(firstBottle: ${_this.firstBottle}, lastBottle: ${_this.lastBottle}, interval: ${_this.interval})';
}


}

/// @nodoc
abstract mixin class $BottleScheduleCopyWith<$Res>  {
  factory $BottleScheduleCopyWith(BottleSchedule value, $Res Function(BottleSchedule) _then) = _$BottleScheduleCopyWithImpl;
@useResult
$Res call({
 Duration firstBottle, Duration lastBottle, Duration interval
});




}
/// @nodoc
class _$BottleScheduleCopyWithImpl<$Res>
    implements $BottleScheduleCopyWith<$Res> {
  _$BottleScheduleCopyWithImpl(this._self, this._then);

  final BottleSchedule _self;
  final $Res Function(BottleSchedule) _then;

/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstBottle = null,Object? lastBottle = null,Object? interval = null,}) {
  return _then(BottleSchedule(
firstBottle: null == firstBottle ? _self.firstBottle : firstBottle // ignore: cast_nullable_to_non_nullable
as Duration,lastBottle: null == lastBottle ? _self.lastBottle : lastBottle // ignore: cast_nullable_to_non_nullable
as Duration,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [BottleSchedule].
extension BottleSchedulePatterns on BottleSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BottleSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BottleSchedule value)  $default,){
final _that = this;
switch (_that) {
case _BottleSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BottleSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration firstBottle,  Duration lastBottle,  Duration interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
return $default(_that.firstBottle,_that.lastBottle,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration firstBottle,  Duration lastBottle,  Duration interval)  $default,) {final _that = this;
switch (_that) {
case _BottleSchedule():
return $default(_that.firstBottle,_that.lastBottle,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration firstBottle,  Duration lastBottle,  Duration interval)?  $default,) {final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
return $default(_that.firstBottle,_that.lastBottle,_that.interval);case _:
  return null;

}
}

}

/// @nodoc


class _BottleSchedule extends BottleSchedule {
  const _BottleSchedule({this.firstBottle = const Duration(hours: 7), this.lastBottle = const Duration(hours: 23, minutes: 30), this.interval = const Duration(hours: 3)}): super._();
  

/// Heure du premier biberon, depuis minuit.
@override@JsonKey() final  Duration firstBottle;
/// Heure du biberon du soir, depuis minuit ; rien n'est prévu après.
@override@JsonKey() final  Duration lastBottle;
/// Temps entre deux biberons de journée.
@override@JsonKey() final  Duration interval;

/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottleScheduleCopyWith<_BottleSchedule> get copyWith => __$BottleScheduleCopyWithImpl<_BottleSchedule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottleSchedule&&(identical(other.firstBottle, firstBottle) || other.firstBottle == firstBottle)&&(identical(other.lastBottle, lastBottle) || other.lastBottle == lastBottle)&&(identical(other.interval, interval) || other.interval == interval));
}


@override
int get hashCode {
    return Object.hash(runtimeType,firstBottle,lastBottle,interval);
}

@override
String toString() {
    return 'BottleSchedule(firstBottle: $firstBottle, lastBottle: $lastBottle, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$BottleScheduleCopyWith<$Res> implements $BottleScheduleCopyWith<$Res> {
  factory _$BottleScheduleCopyWith(_BottleSchedule value, $Res Function(_BottleSchedule) _then) = __$BottleScheduleCopyWithImpl;
@override @useResult
$Res call({
 Duration firstBottle, Duration lastBottle, Duration interval
});




}
/// @nodoc
class __$BottleScheduleCopyWithImpl<$Res>
    implements _$BottleScheduleCopyWith<$Res> {
  __$BottleScheduleCopyWithImpl(this._self, this._then);

  final _BottleSchedule _self;
  final $Res Function(_BottleSchedule) _then;

/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstBottle = null,Object? lastBottle = null,Object? interval = null,}) {
  return _then(_BottleSchedule(
firstBottle: null == firstBottle ? _self.firstBottle : firstBottle // ignore: cast_nullable_to_non_nullable
as Duration,lastBottle: null == lastBottle ? _self.lastBottle : lastBottle // ignore: cast_nullable_to_non_nullable
as Duration,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
