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

 DateTime get nextBottleAt; int get suggestedMl; DateTime get computedAt;/// Premier biberon du matin après [nextBottleAt] : rappel de secours si
/// aucun biberon n'est noté d'ici là ; `null` sans biberon.
 DateTime? get morningBottleAt;/// Biberons des 24 prochaines heures, rappelés un par un par la Cloud
/// Function.
 List<UpcomingBottle> get upcomingBottles;
/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedingPlanSnapshotCopyWith<FeedingPlanSnapshot> get copyWith => _$FeedingPlanSnapshotCopyWithImpl<FeedingPlanSnapshot>(this as FeedingPlanSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedingPlanSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedingPlanSnapshot&&(identical(other.nextBottleAt, _this.nextBottleAt) || other.nextBottleAt == _this.nextBottleAt)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt)&&(identical(other.morningBottleAt, _this.morningBottleAt) || other.morningBottleAt == _this.morningBottleAt)&&const DeepCollectionEquality().equals(other.upcomingBottles, _this.upcomingBottles));
}


@override
int get hashCode {
  final _this = this as FeedingPlanSnapshot;
  return Object.hash(runtimeType,_this.nextBottleAt,_this.suggestedMl,_this.computedAt,_this.morningBottleAt,const DeepCollectionEquality().hash(_this.upcomingBottles));
}

@override
String toString() {
  final _this = this as FeedingPlanSnapshot;
  return 'FeedingPlanSnapshot(nextBottleAt: ${_this.nextBottleAt}, suggestedMl: ${_this.suggestedMl}, computedAt: ${_this.computedAt}, morningBottleAt: ${_this.morningBottleAt}, upcomingBottles: ${_this.upcomingBottles})';
}


}

/// @nodoc
abstract mixin class $FeedingPlanSnapshotCopyWith<$Res>  {
  factory $FeedingPlanSnapshotCopyWith(FeedingPlanSnapshot value, $Res Function(FeedingPlanSnapshot) _then) = _$FeedingPlanSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime nextBottleAt, int suggestedMl, DateTime computedAt, DateTime? morningBottleAt, List<UpcomingBottle> upcomingBottles
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
@pragma('vm:prefer-inline') @override $Res call({Object? nextBottleAt = null,Object? suggestedMl = null,Object? computedAt = null,Object? morningBottleAt = freezed,Object? upcomingBottles = null,}) {
  return _then(FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,morningBottleAt: freezed == morningBottleAt ? _self.morningBottleAt : morningBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upcomingBottles: null == upcomingBottles ? _self.upcomingBottles : upcomingBottles // ignore: cast_nullable_to_non_nullable
as List<UpcomingBottle>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  List<UpcomingBottle> upcomingBottles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.upcomingBottles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  List<UpcomingBottle> upcomingBottles)  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot():
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.upcomingBottles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime nextBottleAt,  int suggestedMl,  DateTime computedAt,  DateTime? morningBottleAt,  List<UpcomingBottle> upcomingBottles)?  $default,) {final _that = this;
switch (_that) {
case _FeedingPlanSnapshot() when $default != null:
return $default(_that.nextBottleAt,_that.suggestedMl,_that.computedAt,_that.morningBottleAt,_that.upcomingBottles);case _:
  return null;

}
}

}

/// @nodoc


class _FeedingPlanSnapshot implements FeedingPlanSnapshot {
  const _FeedingPlanSnapshot({required this.nextBottleAt, required this.suggestedMl, required this.computedAt, this.morningBottleAt,  List<UpcomingBottle> upcomingBottles = const []}): _upcomingBottles = upcomingBottles;
  

@override final  DateTime nextBottleAt;
@override final  int suggestedMl;
@override final  DateTime computedAt;
/// Premier biberon du matin après [nextBottleAt] : rappel de secours si
/// aucun biberon n'est noté d'ici là ; `null` sans biberon.
@override final  DateTime? morningBottleAt;
/// Biberons des 24 prochaines heures, rappelés un par un par la Cloud
/// Function.
 final  List<UpcomingBottle> _upcomingBottles;
/// Biberons des 24 prochaines heures, rappelés un par un par la Cloud
/// Function.
@override@JsonKey() List<UpcomingBottle> get upcomingBottles {
  if (_upcomingBottles is EqualUnmodifiableListView) return _upcomingBottles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingBottles);
}


/// Create a copy of FeedingPlanSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedingPlanSnapshotCopyWith<_FeedingPlanSnapshot> get copyWith => __$FeedingPlanSnapshotCopyWithImpl<_FeedingPlanSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedingPlanSnapshot&&(identical(other.nextBottleAt, nextBottleAt) || other.nextBottleAt == nextBottleAt)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&(identical(other.morningBottleAt, morningBottleAt) || other.morningBottleAt == morningBottleAt)&&const DeepCollectionEquality().equals(other.upcomingBottles, _upcomingBottles));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nextBottleAt,suggestedMl,computedAt,morningBottleAt,const DeepCollectionEquality().hash(_upcomingBottles));
}

@override
String toString() {
    return 'FeedingPlanSnapshot(nextBottleAt: $nextBottleAt, suggestedMl: $suggestedMl, computedAt: $computedAt, morningBottleAt: $morningBottleAt, upcomingBottles: $upcomingBottles)';
}


}

/// @nodoc
abstract mixin class _$FeedingPlanSnapshotCopyWith<$Res> implements $FeedingPlanSnapshotCopyWith<$Res> {
  factory _$FeedingPlanSnapshotCopyWith(_FeedingPlanSnapshot value, $Res Function(_FeedingPlanSnapshot) _then) = __$FeedingPlanSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime nextBottleAt, int suggestedMl, DateTime computedAt, DateTime? morningBottleAt, List<UpcomingBottle> upcomingBottles
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
@override @pragma('vm:prefer-inline') $Res call({Object? nextBottleAt = null,Object? suggestedMl = null,Object? computedAt = null,Object? morningBottleAt = freezed,Object? upcomingBottles = null,}) {
  return _then(_FeedingPlanSnapshot(
nextBottleAt: null == nextBottleAt ? _self.nextBottleAt : nextBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,morningBottleAt: freezed == morningBottleAt ? _self.morningBottleAt : morningBottleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upcomingBottles: null == upcomingBottles ? _self._upcomingBottles : upcomingBottles // ignore: cast_nullable_to_non_nullable
as List<UpcomingBottle>,
  ));
}


}

/// @nodoc
mixin _$UpcomingBottle {

 DateTime get at; int get suggestedMl;
/// Create a copy of UpcomingBottle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingBottleCopyWith<UpcomingBottle> get copyWith => _$UpcomingBottleCopyWithImpl<UpcomingBottle>(this as UpcomingBottle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpcomingBottle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingBottle&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.suggestedMl, _this.suggestedMl) || other.suggestedMl == _this.suggestedMl));
}


@override
int get hashCode {
  final _this = this as UpcomingBottle;
  return Object.hash(runtimeType,_this.at,_this.suggestedMl);
}

@override
String toString() {
  final _this = this as UpcomingBottle;
  return 'UpcomingBottle(at: ${_this.at}, suggestedMl: ${_this.suggestedMl})';
}


}

/// @nodoc
abstract mixin class $UpcomingBottleCopyWith<$Res>  {
  factory $UpcomingBottleCopyWith(UpcomingBottle value, $Res Function(UpcomingBottle) _then) = _$UpcomingBottleCopyWithImpl;
@useResult
$Res call({
 DateTime at, int suggestedMl
});




}
/// @nodoc
class _$UpcomingBottleCopyWithImpl<$Res>
    implements $UpcomingBottleCopyWith<$Res> {
  _$UpcomingBottleCopyWithImpl(this._self, this._then);

  final UpcomingBottle _self;
  final $Res Function(UpcomingBottle) _then;

/// Create a copy of UpcomingBottle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? at = null,Object? suggestedMl = null,}) {
  return _then(UpcomingBottle(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingBottle].
extension UpcomingBottlePatterns on UpcomingBottle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingBottle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingBottle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingBottle value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingBottle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingBottle value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingBottle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime at,  int suggestedMl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingBottle() when $default != null:
return $default(_that.at,_that.suggestedMl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime at,  int suggestedMl)  $default,) {final _that = this;
switch (_that) {
case _UpcomingBottle():
return $default(_that.at,_that.suggestedMl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime at,  int suggestedMl)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingBottle() when $default != null:
return $default(_that.at,_that.suggestedMl);case _:
  return null;

}
}

}

/// @nodoc


class _UpcomingBottle implements UpcomingBottle {
  const _UpcomingBottle({required this.at, required this.suggestedMl});
  

@override final  DateTime at;
@override final  int suggestedMl;

/// Create a copy of UpcomingBottle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingBottleCopyWith<_UpcomingBottle> get copyWith => __$UpcomingBottleCopyWithImpl<_UpcomingBottle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingBottle&&(identical(other.at, at) || other.at == at)&&(identical(other.suggestedMl, suggestedMl) || other.suggestedMl == suggestedMl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,suggestedMl);
}

@override
String toString() {
    return 'UpcomingBottle(at: $at, suggestedMl: $suggestedMl)';
}


}

/// @nodoc
abstract mixin class _$UpcomingBottleCopyWith<$Res> implements $UpcomingBottleCopyWith<$Res> {
  factory _$UpcomingBottleCopyWith(_UpcomingBottle value, $Res Function(_UpcomingBottle) _then) = __$UpcomingBottleCopyWithImpl;
@override @useResult
$Res call({
 DateTime at, int suggestedMl
});




}
/// @nodoc
class __$UpcomingBottleCopyWithImpl<$Res>
    implements _$UpcomingBottleCopyWith<$Res> {
  __$UpcomingBottleCopyWithImpl(this._self, this._then);

  final _UpcomingBottle _self;
  final $Res Function(_UpcomingBottle) _then;

/// Create a copy of UpcomingBottle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? at = null,Object? suggestedMl = null,}) {
  return _then(_UpcomingBottle(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedMl: null == suggestedMl ? _self.suggestedMl : suggestedMl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
