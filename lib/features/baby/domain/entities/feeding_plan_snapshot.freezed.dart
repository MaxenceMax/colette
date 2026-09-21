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

 DateTime get nextBottleAt; int get suggestedMl; DateTime get computedAt;
/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedingPlanSnapshotCopyWith<FeedingPlanSnapshot> get copyWith => _$FeedingPlanSnapshotCopyWithImpl<FeedingPlanSnapshot>(this as FeedingPlanSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedingPlanSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedingPlanSnapshot&&(identical(other.nextBottleAt, _this.nextBottleAt) || other.nextBottleAt == _this.nextBottleAt)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt));
}


@override
int get hashCode {
  final _this = this as FeedingPlanSnapshot;
  return Object.hash(runtimeType,_this.nextBottleAt,_this.suggestedMl,_this.computedAt);
}

@override
String toString() {
  final _this = this as FeedingPlanSnapshot;
  return 'FeedingPlanSnapshot(nextBottleAt: ${_this.nextBottleAt}, suggestedMl: ${_this.suggestedMl}, computedAt: ${_this.computedAt})';
}


}

/// @nodoc
abstract mixin class $FeedingPlanSnapshotCopyWith<$Res>  {
  factory $FeedingPlanSnapshotCopyWith(FeedingPlanSnapshot value, $Res Function(FeedingPlanSnapshot) _then) = _$FeedingPlanSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime nextBottleAt, int suggestedMl, DateTime computedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? nextBottleAt = null,Object? suggestedMl = null,Object? computedAt = null,}) {
  return _then(FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt)  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot():
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc


class _FeedingPlanSnapshot implements FeedingPlanSnapshot {
  const _FeedingPlanSnapshot({required this.nextBottleAt, required this.suggestedMl, required this.computedAt});
  

@override final  DateTime nextBottleAt;
@override final  int suggestedMl;
@override final  DateTime computedAt;

/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedingPlanSnapshotCopyWith<_FeedingPlanSnapshot> get copyWith => __$FeedingPlanSnapshotCopyWithImpl<_FeedingPlanSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedingPlanSnapshot&&(identical(other.nextBottleAt, nextBottleAt) || other.nextBottleAt == nextBottleAt)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nextBottleAt,suggestedMl,computedAt);
}

@override
String toString() {
    return 'FeedingPlanSnapshot(nextBottleAt: $nextBottleAt, suggestedMl: $suggestedMl, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$FeedingPlanSnapshotCopyWith<$Res> implements $FeedingPlanSnapshotCopyWith<$Res> {
  factory _$FeedingPlanSnapshotCopyWith(_FeedingPlanSnapshot value, $Res Function(_FeedingPlanSnapshot) _then) = __$FeedingPlanSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime nextBottleAt, int suggestedMl, DateTime computedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? nextBottleAt = null,Object? suggestedMl = null,Object? computedAt = null,}) {
  return _then(_FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
