// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feeding_plan_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedingPlanSnapshot {

 DateTime get nextBottleAt; DateTime get windowStartAt; DateTime get windowEndAt; int get suggestedMl; DateTime get computedAt;/// Premier biberon du matin après [nextBottleAt] et sa fourchette : rappel
/// de secours si aucun biberon n'est noté d'ici là ; `null` sans biberon.
 DateTime? get morningBottleAt; DateTime? get morningWindowStartAt; DateTime? get morningWindowEndAt;
/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedingPlanSnapshotCopyWith<FeedingPlanSnapshot> get copyWith => _$FeedingPlanSnapshotCopyWithImpl<FeedingPlanSnapshot>(this as FeedingPlanSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedingPlanSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedingPlanSnapshot&&(identical(other.nextBottleAt, _this.nextBottleAt) || other.nextBottleAt == _this.nextBottleAt)&&(identical(other.windowStartAt, _this.windowStartAt) || other.windowStartAt == _this.windowStartAt)&&(identical(other.windowEndAt, _this.windowEndAt) || other.windowEndAt == _this.windowEndAt)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt)&&(identical(other.morningBottleAt, _this.morningBottleAt) || other.morningBottleAt == _this.morningBottleAt)&&(identical(other.morningWindowStartAt, _this.morningWindowStartAt) || other.morningWindowStartAt == _this.morningWindowStartAt)&&(identical(other.morningWindowEndAt, _this.morningWindowEndAt) || other.morningWindowEndAt == _this.morningWindowEndAt));
}


@override
int get hashCode {
  final _this = this as FeedingPlanSnapshot;
  return Object.hash(runtimeType,_this.nextBottleAt,_this.windowStartAt,_this.windowEndAt,_this.suggestedMl,_this.computedAt,_this.morningBottleAt,_this.morningWindowStartAt,_this.morningWindowEndAt);
}

@override
String toString() {
  final _this = this as FeedingPlanSnapshot;
  return 'FeedingPlanSnapshot(nextBottleAt: ${_this.nextBottleAt}, windowStartAt: ${_this.windowStartAt}, windowEndAt: ${_this.windowEndAt}, suggestedMl: ${_this.suggestedMl}, computedAt: ${_this.computedAt}, morningBottleAt: ${_this.morningBottleAt}, morningWindowStartAt: ${_this.morningWindowStartAt}, morningWindowEndAt: ${_this.morningWindowEndAt})';
}


}

/// @nodoc
abstract mixin class $FeedingPlanSnapshotCopyWith<$Res>  {
  factory $FeedingPlanSnapshotCopyWith(FeedingPlanSnapshot value, $Res Function(FeedingPlanSnapshot) _then) = _$FeedingPlanSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime nextBottleAt, DateTime windowStartAt, DateTime windowEndAt, int suggestedMl, DateTime computedAt, DateTime? morningBottleAt, DateTime? morningWindowStartAt, DateTime? morningWindowEndAt
});




}
/// @nodoc
class _$FeedingPlanSnapshotCopyWithImpl<$Res>
    implements $FeedingPlanSnapshotCopyWith<$Res> {
  _$FeedingPlanSnapshotCopyWithImpl(this._self, this._then);

  final FeedingPlanSnapshot _self;
  final $Res Function(FeedingPlanSnapshot) _then;

/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nextBottleAt = null,Object? windowStartAt = null,Object? windowEndAt = null,Object? suggestedMl = null,Object? computedAt = null,Object? morningBottleAt = freezed,Object? morningWindowStartAt = freezed,Object? morningWindowEndAt = freezed,}) {
  return _then(FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowStartAt: null == windowStartAt ? _self.windowStartAt : windowStartAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowEndAt: null == windowEndAt ? _self.windowEndAt : windowEndAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,morningBottleAt: freezed == morningBottleAt ? _self.morningBottleAt : morningBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,morningWindowStartAt: freezed == morningWindowStartAt ? _self.morningWindowStartAt : morningWindowStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,morningWindowEndAt: freezed == morningWindowEndAt ? _self.morningWindowEndAt : morningWindowEndAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedingPlanSnapshot].
extension FeedingPlanSnapshotPatterns on FeedingPlanSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedingPlanSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedingPlanSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _FeedingPlanSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedingPlanSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  DateTime windowStartAt,  DateTime windowEndAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  DateTime? morningWindowStartAt,  DateTime? morningWindowEndAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.windowStartAt,_that.windowEndAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.morningWindowStartAt,_that.morningWindowEndAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  DateTime windowStartAt,  DateTime windowEndAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  DateTime? morningWindowStartAt,  DateTime? morningWindowEndAt)  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot():
return $default(_that.nextBottleAt,_that.windowStartAt,_that.windowEndAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.morningWindowStartAt,_that.morningWindowEndAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime nextBottleAt,  DateTime windowStartAt,  DateTime windowEndAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  DateTime? morningWindowStartAt,  DateTime? morningWindowEndAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.windowStartAt,_that.windowEndAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.morningWindowStartAt,_that.morningWindowEndAt);case _:
  return null;

}
}

}

/// @nodoc


class _FeedingPlanSnapshot implements FeedingPlanSnapshot {
  const _FeedingPlanSnapshot({required this.nextBottleAt, required this.windowStartAt, required this.windowEndAt, required this.suggestedMl, required this.computedAt, this.morningBottleAt, this.morningWindowStartAt, this.morningWindowEndAt});
  

@override final  DateTime nextBottleAt;
@override final  DateTime windowStartAt;
@override final  DateTime windowEndAt;
@override final  int suggestedMl;
@override final  DateTime computedAt;
/// Premier biberon du matin après [nextBottleAt] et sa fourchette : rappel
/// de secours si aucun biberon n'est noté d'ici là ; `null` sans biberon.
@override final  DateTime? morningBottleAt;
@override final  DateTime? morningWindowStartAt;
@override final  DateTime? morningWindowEndAt;

/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedingPlanSnapshotCopyWith<_FeedingPlanSnapshot> get copyWith => __$FeedingPlanSnapshotCopyWithImpl<_FeedingPlanSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedingPlanSnapshot&&(identical(other.nextBottleAt, nextBottleAt) || other.nextBottleAt == nextBottleAt)&&(identical(other.windowStartAt, windowStartAt) || other.windowStartAt == windowStartAt)&&(identical(other.windowEndAt, windowEndAt) || other.windowEndAt == windowEndAt)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&(identical(other.morningBottleAt, morningBottleAt) || other.morningBottleAt == morningBottleAt)&&(identical(other.morningWindowStartAt, morningWindowStartAt) || other.morningWindowStartAt == morningWindowStartAt)&&(identical(other.morningWindowEndAt, morningWindowEndAt) || other.morningWindowEndAt == morningWindowEndAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nextBottleAt,windowStartAt,windowEndAt,suggestedMl,computedAt,morningBottleAt,morningWindowStartAt,morningWindowEndAt);
}

@override
String toString() {
    return 'FeedingPlanSnapshot(nextBottleAt: $nextBottleAt, windowStartAt: $windowStartAt, windowEndAt: $windowEndAt, suggestedMl: $suggestedMl, computedAt: $computedAt, morningBottleAt: $morningBottleAt, morningWindowStartAt: $morningWindowStartAt, morningWindowEndAt: $morningWindowEndAt)';
}


}

/// @nodoc
abstract mixin class _$FeedingPlanSnapshotCopyWith<$Res> implements $FeedingPlanSnapshotCopyWith<$Res> {
  factory _$FeedingPlanSnapshotCopyWith(_FeedingPlanSnapshot value, $Res Function(_FeedingPlanSnapshot) _then) = __$FeedingPlanSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime nextBottleAt, DateTime windowStartAt, DateTime windowEndAt, int suggestedMl, DateTime computedAt, DateTime? morningBottleAt, DateTime? morningWindowStartAt, DateTime? morningWindowEndAt
});




}
/// @nodoc
class __$FeedingPlanSnapshotCopyWithImpl<$Res>
    implements _$FeedingPlanSnapshotCopyWith<$Res> {
  __$FeedingPlanSnapshotCopyWithImpl(this._self, this._then);

  final _FeedingPlanSnapshot _self;
  final $Res Function(_FeedingPlanSnapshot) _then;

/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nextBottleAt = null,Object? windowStartAt = null,Object? windowEndAt = null,Object? suggestedMl = null,Object? computedAt = null,Object? morningBottleAt = freezed,Object? morningWindowStartAt = freezed,Object? morningWindowEndAt = freezed,}) {
  return _then(_FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowStartAt: null == windowStartAt ? _self.windowStartAt : windowStartAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowEndAt: null == windowEndAt ? _self.windowEndAt : windowEndAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,morningBottleAt: freezed == morningBottleAt ? _self.morningBottleAt : morningBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,morningWindowStartAt: freezed == morningWindowStartAt ? _self.morningWindowStartAt : morningWindowStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,morningWindowEndAt: freezed == morningWindowEndAt ? _self.morningWindowEndAt : morningWindowEndAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
