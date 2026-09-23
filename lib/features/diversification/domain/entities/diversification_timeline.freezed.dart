// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diversification_timeline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiversificationTimeline {

 DiversificationPhase get phase; int get ageMonths; DateTime get sixMonthsDate; int get daysUntilSixMonths;
/// Create a copy of DiversificationTimeline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiversificationTimelineCopyWith<DiversificationTimeline> get copyWith => _$DiversificationTimelineCopyWithImpl<DiversificationTimeline>(this as DiversificationTimeline, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiversificationTimeline;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiversificationTimeline&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.ageMonths, _this.ageMonths) || other.ageMonths == _this.ageMonths)&&(identical(other.sixMonthsDate, _this.sixMonthsDate) || other.sixMonthsDate == _this.sixMonthsDate)&&(identical(other.daysUntilSixMonths, _this.daysUntilSixMonths) || other.daysUntilSixMonths == _this.daysUntilSixMonths));
}


@override
int get hashCode {
  final _this = this as DiversificationTimeline;
  return Object.hash(runtimeType,_this.phase,_this.ageMonths,_this.sixMonthsDate,_this.daysUntilSixMonths);
}

@override
String toString() {
  final _this = this as DiversificationTimeline;
  return 'DiversificationTimeline(phase: ${_this.phase}, ageMonths: ${_this.ageMonths}, sixMonthsDate: ${_this.sixMonthsDate}, daysUntilSixMonths: ${_this.daysUntilSixMonths})';
}


}

/// @nodoc
abstract mixin class $DiversificationTimelineCopyWith<$Res>  {
  factory $DiversificationTimelineCopyWith(DiversificationTimeline value, $Res Function(DiversificationTimeline) _then) = _$DiversificationTimelineCopyWithImpl;
@useResult
$Res call({
 DiversificationPhase phase, int ageMonths, DateTime sixMonthsDate, int daysUntilSixMonths
});




}
/// @nodoc
class _$DiversificationTimelineCopyWithImpl<$Res>
    implements $DiversificationTimelineCopyWith<$Res> {
  _$DiversificationTimelineCopyWithImpl(this._self, this._then);

  final DiversificationTimeline _self;
  final $Res Function(DiversificationTimeline) _then;

/// Create a copy of DiversificationTimeline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? ageMonths = null,Object? sixMonthsDate = null,Object? daysUntilSixMonths = null,}) {
  return _then(DiversificationTimeline(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as DiversificationPhase,ageMonths: null == ageMonths ? _self.ageMonths : ageMonths // ignore: cast_nullable_to_non_nullable
as int,sixMonthsDate: null == sixMonthsDate ? _self.sixMonthsDate : sixMonthsDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysUntilSixMonths: null == daysUntilSixMonths ? _self.daysUntilSixMonths : daysUntilSixMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DiversificationTimeline].
extension DiversificationTimelinePatterns on DiversificationTimeline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiversificationTimeline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiversificationTimeline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiversificationTimeline value)  $default,){
final _that = this;
switch (_that) {
case _DiversificationTimeline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiversificationTimeline value)?  $default,){
final _that = this;
switch (_that) {
case _DiversificationTimeline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DiversificationPhase phase,  int ageMonths,  DateTime sixMonthsDate,  int daysUntilSixMonths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiversificationTimeline() when $default != null:
return $default(_that.phase,_that.ageMonths,_that.sixMonthsDate,_that.daysUntilSixMonths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DiversificationPhase phase,  int ageMonths,  DateTime sixMonthsDate,  int daysUntilSixMonths)  $default,) {final _that = this;
switch (_that) {
case _DiversificationTimeline():
return $default(_that.phase,_that.ageMonths,_that.sixMonthsDate,_that.daysUntilSixMonths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DiversificationPhase phase,  int ageMonths,  DateTime sixMonthsDate,  int daysUntilSixMonths)?  $default,) {final _that = this;
switch (_that) {
case _DiversificationTimeline() when $default != null:
return $default(_that.phase,_that.ageMonths,_that.sixMonthsDate,_that.daysUntilSixMonths);case _:
  return null;

}
}

}

/// @nodoc


class _DiversificationTimeline implements DiversificationTimeline {
  const _DiversificationTimeline({required this.phase, required this.ageMonths, required this.sixMonthsDate, required this.daysUntilSixMonths});
  

@override final  DiversificationPhase phase;
@override final  int ageMonths;
@override final  DateTime sixMonthsDate;
@override final  int daysUntilSixMonths;

/// Create a copy of DiversificationTimeline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiversificationTimelineCopyWith<_DiversificationTimeline> get copyWith => __$DiversificationTimelineCopyWithImpl<_DiversificationTimeline>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiversificationTimeline&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.ageMonths, ageMonths) || other.ageMonths == ageMonths)&&(identical(other.sixMonthsDate, sixMonthsDate) || other.sixMonthsDate == sixMonthsDate)&&(identical(other.daysUntilSixMonths, daysUntilSixMonths) || other.daysUntilSixMonths == daysUntilSixMonths));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,ageMonths,sixMonthsDate,daysUntilSixMonths);
}

@override
String toString() {
    return 'DiversificationTimeline(phase: $phase, ageMonths: $ageMonths, sixMonthsDate: $sixMonthsDate, daysUntilSixMonths: $daysUntilSixMonths)';
}


}

/// @nodoc
abstract mixin class _$DiversificationTimelineCopyWith<$Res> implements $DiversificationTimelineCopyWith<$Res> {
  factory _$DiversificationTimelineCopyWith(_DiversificationTimeline value, $Res Function(_DiversificationTimeline) _then) = __$DiversificationTimelineCopyWithImpl;
@override @useResult
$Res call({
 DiversificationPhase phase, int ageMonths, DateTime sixMonthsDate, int daysUntilSixMonths
});




}
/// @nodoc
class __$DiversificationTimelineCopyWithImpl<$Res>
    implements _$DiversificationTimelineCopyWith<$Res> {
  __$DiversificationTimelineCopyWithImpl(this._self, this._then);

  final _DiversificationTimeline _self;
  final $Res Function(_DiversificationTimeline) _then;

/// Create a copy of DiversificationTimeline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? ageMonths = null,Object? sixMonthsDate = null,Object? daysUntilSixMonths = null,}) {
  return _then(_DiversificationTimeline(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as DiversificationPhase,ageMonths: null == ageMonths ? _self.ageMonths : ageMonths // ignore: cast_nullable_to_non_nullable
as int,sixMonthsDate: null == sixMonthsDate ? _self.sixMonthsDate : sixMonthsDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysUntilSixMonths: null == daysUntilSixMonths ? _self.daysUntilSixMonths : daysUntilSixMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
