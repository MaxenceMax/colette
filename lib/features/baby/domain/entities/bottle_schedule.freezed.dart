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

/// Horaires depuis minuit, triés, espacés d'au moins 30 min (y compris du
/// dernier au premier du lendemain). Jamais vide (non vérifiable en `const`).
 List<Duration> get times;
/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottleScheduleCopyWith<BottleSchedule> get copyWith => _$BottleScheduleCopyWithImpl<BottleSchedule>(this as BottleSchedule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BottleSchedule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottleSchedule&&const DeepCollectionEquality().equals(other.times, _this.times));
}


@override
int get hashCode {
  final _this = this as BottleSchedule;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.times));
}

@override
String toString() {
  final _this = this as BottleSchedule;
  return 'BottleSchedule(times: ${_this.times})';
}


}

/// @nodoc
abstract mixin class $BottleScheduleCopyWith<$Res>  {
  factory $BottleScheduleCopyWith(BottleSchedule value, $Res Function(BottleSchedule) _then) = _$BottleScheduleCopyWithImpl;
@useResult
$Res call({
 List<Duration> times
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
@pragma('vm:prefer-inline') @override $Res call({Object? times = null,}) {
  return _then(BottleSchedule(
times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as List<Duration>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Duration> times)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
return $default(_that.times);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Duration> times)  $default,) {final _that = this;
switch (_that) {
case _BottleSchedule():
return $default(_that.times);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Duration> times)?  $default,) {final _that = this;
switch (_that) {
case _BottleSchedule() when $default != null:
return $default(_that.times);case _:
  return null;

}
}

}

/// @nodoc


class _BottleSchedule extends BottleSchedule {
  const _BottleSchedule({ List<Duration> times = defaultBottleTimes}): _times = times,super._();
  

/// Horaires depuis minuit, triés, espacés d'au moins 30 min (y compris du
/// dernier au premier du lendemain). Jamais vide (non vérifiable en `const`).
 final  List<Duration> _times;
/// Horaires depuis minuit, triés, espacés d'au moins 30 min (y compris du
/// dernier au premier du lendemain). Jamais vide (non vérifiable en `const`).
@override@JsonKey() List<Duration> get times {
  if (_times is EqualUnmodifiableListView) return _times;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_times);
}


/// Create a copy of BottleSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottleScheduleCopyWith<_BottleSchedule> get copyWith => __$BottleScheduleCopyWithImpl<_BottleSchedule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottleSchedule&&const DeepCollectionEquality().equals(other.times, _times));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_times));
}

@override
String toString() {
    return 'BottleSchedule(times: $times)';
}


}

/// @nodoc
abstract mixin class _$BottleScheduleCopyWith<$Res> implements $BottleScheduleCopyWith<$Res> {
  factory _$BottleScheduleCopyWith(_BottleSchedule value, $Res Function(_BottleSchedule) _then) = __$BottleScheduleCopyWithImpl;
@override @useResult
$Res call({
 List<Duration> times
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
@override @pragma('vm:prefer-inline') $Res call({Object? times = null,}) {
  return _then(_BottleSchedule(
times: null == times ? _self._times : times // ignore: cast_nullable_to_non_nullable
as List<Duration>,
  ));
}


}

// dart format on
