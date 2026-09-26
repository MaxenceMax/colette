// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bottle_timer_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BottleTimerRun {

 DateTime get startedAt; DateTime get feedingEndsAt;
/// Create a copy of BottleTimerRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottleTimerRunCopyWith<BottleTimerRun> get copyWith => _$BottleTimerRunCopyWithImpl<BottleTimerRun>(this as BottleTimerRun, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BottleTimerRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottleTimerRun&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.feedingEndsAt, _this.feedingEndsAt) || other.feedingEndsAt == _this.feedingEndsAt));
}


@override
int get hashCode {
  final _this = this as BottleTimerRun;
  return Object.hash(runtimeType,_this.startedAt,_this.feedingEndsAt);
}

@override
String toString() {
  final _this = this as BottleTimerRun;
  return 'BottleTimerRun(startedAt: ${_this.startedAt}, feedingEndsAt: ${_this.feedingEndsAt})';
}


}

/// @nodoc
abstract mixin class $BottleTimerRunCopyWith<$Res>  {
  factory $BottleTimerRunCopyWith(BottleTimerRun value, $Res Function(BottleTimerRun) _then) = _$BottleTimerRunCopyWithImpl;
@useResult
$Res call({
 DateTime startedAt, DateTime feedingEndsAt
});




}
/// @nodoc
class _$BottleTimerRunCopyWithImpl<$Res>
    implements $BottleTimerRunCopyWith<$Res> {
  _$BottleTimerRunCopyWithImpl(this._self, this._then);

  final BottleTimerRun _self;
  final $Res Function(BottleTimerRun) _then;

/// Create a copy of BottleTimerRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = null,Object? feedingEndsAt = null,}) {
  return _then(BottleTimerRun(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,feedingEndsAt: null == feedingEndsAt ? _self.feedingEndsAt : feedingEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BottleTimerRun].
extension BottleTimerRunPatterns on BottleTimerRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BottleTimerRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BottleTimerRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BottleTimerRun value)  $default,){
final _that = this;
switch (_that) {
case _BottleTimerRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BottleTimerRun value)?  $default,){
final _that = this;
switch (_that) {
case _BottleTimerRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startedAt,  DateTime feedingEndsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BottleTimerRun() when $default != null:
return $default(_that.startedAt,_that.feedingEndsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startedAt,  DateTime feedingEndsAt)  $default,) {final _that = this;
switch (_that) {
case _BottleTimerRun():
return $default(_that.startedAt,_that.feedingEndsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startedAt,  DateTime feedingEndsAt)?  $default,) {final _that = this;
switch (_that) {
case _BottleTimerRun() when $default != null:
return $default(_that.startedAt,_that.feedingEndsAt);case _:
  return null;

}
}

}

/// @nodoc


class _BottleTimerRun extends BottleTimerRun {
  const _BottleTimerRun({required this.startedAt, required this.feedingEndsAt}): super._();
  

@override final  DateTime startedAt;
@override final  DateTime feedingEndsAt;

/// Create a copy of BottleTimerRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottleTimerRunCopyWith<_BottleTimerRun> get copyWith => __$BottleTimerRunCopyWithImpl<_BottleTimerRun>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottleTimerRun&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.feedingEndsAt, feedingEndsAt) || other.feedingEndsAt == feedingEndsAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startedAt,feedingEndsAt);
}

@override
String toString() {
    return 'BottleTimerRun(startedAt: $startedAt, feedingEndsAt: $feedingEndsAt)';
}


}

/// @nodoc
abstract mixin class _$BottleTimerRunCopyWith<$Res> implements $BottleTimerRunCopyWith<$Res> {
  factory _$BottleTimerRunCopyWith(_BottleTimerRun value, $Res Function(_BottleTimerRun) _then) = __$BottleTimerRunCopyWithImpl;
@override @useResult
$Res call({
 DateTime startedAt, DateTime feedingEndsAt
});




}
/// @nodoc
class __$BottleTimerRunCopyWithImpl<$Res>
    implements _$BottleTimerRunCopyWith<$Res> {
  __$BottleTimerRunCopyWithImpl(this._self, this._then);

  final _BottleTimerRun _self;
  final $Res Function(_BottleTimerRun) _then;

/// Create a copy of BottleTimerRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startedAt = null,Object? feedingEndsAt = null,}) {
  return _then(_BottleTimerRun(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,feedingEndsAt: null == feedingEndsAt ? _self.feedingEndsAt : feedingEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
