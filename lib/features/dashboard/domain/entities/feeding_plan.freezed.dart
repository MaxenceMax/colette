// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feeding_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedingPlan {

 int get dailyTargetMl; int get feedsPerDay; DateTime get nextBottleAt; int get suggestedMl; int get bottlesGiven; int get givenMl; bool get isEstimatedFromAge;
/// Create a copy of FeedingPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedingPlanCopyWith<FeedingPlan> get copyWith => _$FeedingPlanCopyWithImpl<FeedingPlan>(this as FeedingPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedingPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedingPlan&&(identical(other.dailyTargetMl, _this.dailyTargetMl) || other.dailyTargetMl == _this.dailyTargetMl)&&(identical(other.feedsPerDay, _this.feedsPerDay) || other.feedsPerDay == _this.feedsPerDay)&&(identical(other.nextBottleAt, _this.nextBottleAt) || other.nextBottleAt == _this.nextBottleAt)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl)&&(identical(other.bottlesGiven, _this.bottlesGiven) || other.bottlesGiven == _this.bottlesGiven)&&(identical(other.givenMl, _this.givenMl) || other.givenMl == _this.givenMl)&&(identical(other.isEstimatedFromAge, _this.isEstimatedFromAge) || other.isEstimatedFromAge == _this.isEstimatedFromAge));
}


@override
int get hashCode {
  final _this = this as FeedingPlan;
  return Object.hash(runtimeType,_this.dailyTargetMl,_this.feedsPerDay,_this.nextBottleAt,_this.suggestedMl,_this.bottlesGiven,_this.givenMl,_this.isEstimatedFromAge);
}

@override
String toString() {
  final _this = this as FeedingPlan;
  return 'FeedingPlan(dailyTargetMl: ${_this.dailyTargetMl}, feedsPerDay: ${_this.feedsPerDay}, nextBottleAt: ${_this.nextBottleAt}, suggestedMl: ${_this.suggestedMl}, bottlesGiven: ${_this.bottlesGiven}, givenMl: ${_this.givenMl}, isEstimatedFromAge: ${_this.isEstimatedFromAge})';
}


}

/// @nodoc
abstract mixin class $FeedingPlanCopyWith<$Res>  {
  factory $FeedingPlanCopyWith(FeedingPlan value, $Res Function(FeedingPlan) _then) = _$FeedingPlanCopyWithImpl;
@useResult
$Res call({
 int dailyTargetMl, int feedsPerDay, DateTime nextBottleAt, int suggestedMl, int bottlesGiven, int givenMl, bool isEstimatedFromAge
});




}
/// @nodoc
class _$FeedingPlanCopyWithImpl<$Res>
    implements $FeedingPlanCopyWith<$Res> {
  _$FeedingPlanCopyWithImpl(this._self, this._then);

  final FeedingPlan _self;
  final $Res Function(FeedingPlan) _then;

/// Create a copy of FeedingPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dailyTargetMl = null,Object? feedsPerDay = null,Object? nextBottleAt = null,Object? suggestedMl = null,Object? bottlesGiven = null,Object? givenMl = null,Object? isEstimatedFromAge = null,}) {
  return _then(FeedingPlan(
dailyTargetMl: null == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,bottlesGiven: null == bottlesGiven ? _self.bottlesGiven : bottlesGiven // ignore: cast_nullable_to_non_nullable
as int,givenMl: null == givenMl ? _self.givenMl : givenMl // ignore: cast_nullable_to_non_nullable
as int,isEstimatedFromAge: null == isEstimatedFromAge ? _self.isEstimatedFromAge : isEstimatedFromAge // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedingPlan].
extension FeedingPlanPatterns on FeedingPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedingPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedingPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedingPlan value)  $default,){
final _that = this;
switch (_that) {
case _FeedingPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedingPlan value)?  $default,){
final _that = this;
switch (_that) {
case _FeedingPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dailyTargetMl,  int feedsPerDay,  DateTime nextBottleAt,  int suggestedMl,  int bottlesGiven,  int givenMl,  bool isEstimatedFromAge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedingPlan() when $default != null:
return $default(_that.dailyTargetMl,_that.feedsPerDay,_that.nextBottleAt,_that.suggestedMl,_that.bottlesGiven,_that.givenMl,_that.isEstimatedFromAge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dailyTargetMl,  int feedsPerDay,  DateTime nextBottleAt,  int suggestedMl,  int bottlesGiven,  int givenMl,  bool isEstimatedFromAge)  $default,) {final _that = this;
switch (_that) {
case _FeedingPlan():
return $default(_that.dailyTargetMl,_that.feedsPerDay,_that.nextBottleAt,_that.suggestedMl,_that.bottlesGiven,_that.givenMl,_that.isEstimatedFromAge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dailyTargetMl,  int feedsPerDay,  DateTime nextBottleAt,  int suggestedMl,  int bottlesGiven,  int givenMl,  bool isEstimatedFromAge)?  $default,) {final _that = this;
switch (_that) {
case _FeedingPlan() when $default != null:
return $default(_that.dailyTargetMl,_that.feedsPerDay,_that.nextBottleAt,_that.suggestedMl,_that.bottlesGiven,_that.givenMl,_that.isEstimatedFromAge);case _:
  return null;

}
}

}

/// @nodoc


class _FeedingPlan extends FeedingPlan {
  const _FeedingPlan({required this.dailyTargetMl, required this.feedsPerDay, required this.nextBottleAt, required this.suggestedMl, required this.bottlesGiven, required this.givenMl, required this.isEstimatedFromAge}): super._();
  

@override final  int dailyTargetMl;
@override final  int feedsPerDay;
@override final  DateTime nextBottleAt;
@override final  int suggestedMl;
@override final  int bottlesGiven;
@override final  int givenMl;
@override final  bool isEstimatedFromAge;

/// Create a copy of FeedingPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedingPlanCopyWith<_FeedingPlan> get copyWith => __$FeedingPlanCopyWithImpl<_FeedingPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedingPlan&&(identical(other.dailyTargetMl, dailyTargetMl) || other.dailyTargetMl == dailyTargetMl)&&(identical(other.feedsPerDay, feedsPerDay) || other.feedsPerDay == feedsPerDay)&&(identical(other.nextBottleAt, nextBottleAt) || other.nextBottleAt == nextBottleAt)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl)&&(identical(other.bottlesGiven, bottlesGiven) || other.bottlesGiven == bottlesGiven)&&(identical(other.givenMl, givenMl) || other.givenMl == givenMl)&&(identical(other.isEstimatedFromAge, isEstimatedFromAge) || other.isEstimatedFromAge == isEstimatedFromAge));
}


@override
int get hashCode {
    return Object.hash(runtimeType,dailyTargetMl,feedsPerDay,nextBottleAt,suggestedMl,bottlesGiven,givenMl,isEstimatedFromAge);
}

@override
String toString() {
    return 'FeedingPlan(dailyTargetMl: $dailyTargetMl, feedsPerDay: $feedsPerDay, nextBottleAt: $nextBottleAt, suggestedMl: $suggestedMl, bottlesGiven: $bottlesGiven, givenMl: $givenMl, isEstimatedFromAge: $isEstimatedFromAge)';
}


}

/// @nodoc
abstract mixin class _$FeedingPlanCopyWith<$Res> implements $FeedingPlanCopyWith<$Res> {
  factory _$FeedingPlanCopyWith(_FeedingPlan value, $Res Function(_FeedingPlan) _then) = __$FeedingPlanCopyWithImpl;
@override @useResult
$Res call({
 int dailyTargetMl, int feedsPerDay, DateTime nextBottleAt, int suggestedMl, int bottlesGiven, int givenMl, bool isEstimatedFromAge
});




}
/// @nodoc
class __$FeedingPlanCopyWithImpl<$Res>
    implements _$FeedingPlanCopyWith<$Res> {
  __$FeedingPlanCopyWithImpl(this._self, this._then);

  final _FeedingPlan _self;
  final $Res Function(_FeedingPlan) _then;

/// Create a copy of FeedingPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dailyTargetMl = null,Object? feedsPerDay = null,Object? nextBottleAt = null,Object? suggestedMl = null,Object? bottlesGiven = null,Object? givenMl = null,Object? isEstimatedFromAge = null,}) {
  return _then(_FeedingPlan(
dailyTargetMl: null == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,bottlesGiven: null == bottlesGiven ? _self.bottlesGiven : bottlesGiven // ignore: cast_nullable_to_non_nullable
as int,givenMl: null == givenMl ? _self.givenMl : givenMl // ignore: cast_nullable_to_non_nullable
as int,isEstimatedFromAge: null == isEstimatedFromAge ? _self.isEstimatedFromAge : isEstimatedFromAge // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
