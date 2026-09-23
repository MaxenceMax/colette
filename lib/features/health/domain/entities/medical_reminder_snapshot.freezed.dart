// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_reminder_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicalReminderStage {

 MedicalStageId get stageId; DateTime get dueFrom; DateTime get dueUntil; bool get hasAppointment;
/// Create a copy of MedicalReminderStage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalReminderStageCopyWith<MedicalReminderStage> get copyWith => _$MedicalReminderStageCopyWithImpl<MedicalReminderStage>(this as MedicalReminderStage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MedicalReminderStage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalReminderStage&&(identical(other.stageId, _this.stageId) || other.stageId == _this.stageId)&&(identical(other.dueFrom, _this.dueFrom) || other.dueFrom == _this.dueFrom)&&(identical(other.dueUntil, _this.dueUntil) || other.dueUntil == _this.dueUntil)&&(identical(other.hasAppointment, _this.hasAppointment) || other.hasAppointment == _this.hasAppointment));
}


@override
int get hashCode {
  final _this = this as MedicalReminderStage;
  return Object.hash(runtimeType,_this.stageId,_this.dueFrom,_this.dueUntil,_this.hasAppointment);
}

@override
String toString() {
  final _this = this as MedicalReminderStage;
  return 'MedicalReminderStage(stageId: ${_this.stageId}, dueFrom: ${_this.dueFrom}, dueUntil: ${_this.dueUntil}, hasAppointment: ${_this.hasAppointment})';
}


}

/// @nodoc
abstract mixin class $MedicalReminderStageCopyWith<$Res>  {
  factory $MedicalReminderStageCopyWith(MedicalReminderStage value, $Res Function(MedicalReminderStage) _then) = _$MedicalReminderStageCopyWithImpl;
@useResult
$Res call({
 MedicalStageId stageId, DateTime dueFrom, DateTime dueUntil, bool hasAppointment
});




}
/// @nodoc
class _$MedicalReminderStageCopyWithImpl<$Res>
    implements $MedicalReminderStageCopyWith<$Res> {
  _$MedicalReminderStageCopyWithImpl(this._self, this._then);

  final MedicalReminderStage _self;
  final $Res Function(MedicalReminderStage) _then;

/// Create a copy of MedicalReminderStage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stageId = null,Object? dueFrom = null,Object? dueUntil = null,Object? hasAppointment = null,}) {
  return _then(MedicalReminderStage(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as MedicalStageId,dueFrom: null == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dueUntil: null == dueUntil ? _self.dueUntil : dueUntil // ignore: cast_nullable_to_non_nullable
as DateTime,hasAppointment: null == hasAppointment ? _self.hasAppointment : hasAppointment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalReminderStage].
extension MedicalReminderStagePatterns on MedicalReminderStage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalReminderStage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalReminderStage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalReminderStage value)  $default,){
final _that = this;
switch (_that) {
case _MedicalReminderStage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalReminderStage value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalReminderStage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MedicalStageId stageId,  DateTime dueFrom,  DateTime dueUntil,  bool hasAppointment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalReminderStage() when $default != null:
return $default(_that.stageId,_that.dueFrom,_that.dueUntil,_that.hasAppointment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MedicalStageId stageId,  DateTime dueFrom,  DateTime dueUntil,  bool hasAppointment)  $default,) {final _that = this;
switch (_that) {
case _MedicalReminderStage():
return $default(_that.stageId,_that.dueFrom,_that.dueUntil,_that.hasAppointment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MedicalStageId stageId,  DateTime dueFrom,  DateTime dueUntil,  bool hasAppointment)?  $default,) {final _that = this;
switch (_that) {
case _MedicalReminderStage() when $default != null:
return $default(_that.stageId,_that.dueFrom,_that.dueUntil,_that.hasAppointment);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalReminderStage implements MedicalReminderStage {
  const _MedicalReminderStage({required this.stageId, required this.dueFrom, required this.dueUntil, required this.hasAppointment});
  

@override final  MedicalStageId stageId;
@override final  DateTime dueFrom;
@override final  DateTime dueUntil;
@override final  bool hasAppointment;

/// Create a copy of MedicalReminderStage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalReminderStageCopyWith<_MedicalReminderStage> get copyWith => __$MedicalReminderStageCopyWithImpl<_MedicalReminderStage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalReminderStage&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.dueFrom, dueFrom) || other.dueFrom == dueFrom)&&(identical(other.dueUntil, dueUntil) || other.dueUntil == dueUntil)&&(identical(other.hasAppointment, hasAppointment) || other.hasAppointment == hasAppointment));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stageId,dueFrom,dueUntil,hasAppointment);
}

@override
String toString() {
    return 'MedicalReminderStage(stageId: $stageId, dueFrom: $dueFrom, dueUntil: $dueUntil, hasAppointment: $hasAppointment)';
}


}

/// @nodoc
abstract mixin class _$MedicalReminderStageCopyWith<$Res> implements $MedicalReminderStageCopyWith<$Res> {
  factory _$MedicalReminderStageCopyWith(_MedicalReminderStage value, $Res Function(_MedicalReminderStage) _then) = __$MedicalReminderStageCopyWithImpl;
@override @useResult
$Res call({
 MedicalStageId stageId, DateTime dueFrom, DateTime dueUntil, bool hasAppointment
});




}
/// @nodoc
class __$MedicalReminderStageCopyWithImpl<$Res>
    implements _$MedicalReminderStageCopyWith<$Res> {
  __$MedicalReminderStageCopyWithImpl(this._self, this._then);

  final _MedicalReminderStage _self;
  final $Res Function(_MedicalReminderStage) _then;

/// Create a copy of MedicalReminderStage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stageId = null,Object? dueFrom = null,Object? dueUntil = null,Object? hasAppointment = null,}) {
  return _then(_MedicalReminderStage(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as MedicalStageId,dueFrom: null == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dueUntil: null == dueUntil ? _self.dueUntil : dueUntil // ignore: cast_nullable_to_non_nullable
as DateTime,hasAppointment: null == hasAppointment ? _self.hasAppointment : hasAppointment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$MedicalReminderSnapshot {

 List<MedicalReminderStage> get stages; DateTime get computedAt;
/// Create a copy of MedicalReminderSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalReminderSnapshotCopyWith<MedicalReminderSnapshot> get copyWith => _$MedicalReminderSnapshotCopyWithImpl<MedicalReminderSnapshot>(this as MedicalReminderSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MedicalReminderSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalReminderSnapshot&&const DeepCollectionEquality().equals(other.stages, _this.stages)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt));
}


@override
int get hashCode {
  final _this = this as MedicalReminderSnapshot;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.stages),_this.computedAt);
}

@override
String toString() {
  final _this = this as MedicalReminderSnapshot;
  return 'MedicalReminderSnapshot(stages: ${_this.stages}, computedAt: ${_this.computedAt})';
}


}

/// @nodoc
abstract mixin class $MedicalReminderSnapshotCopyWith<$Res>  {
  factory $MedicalReminderSnapshotCopyWith(MedicalReminderSnapshot value, $Res Function(MedicalReminderSnapshot) _then) = _$MedicalReminderSnapshotCopyWithImpl;
@useResult
$Res call({
 List<MedicalReminderStage> stages, DateTime computedAt
});




}
/// @nodoc
class _$MedicalReminderSnapshotCopyWithImpl<$Res>
    implements $MedicalReminderSnapshotCopyWith<$Res> {
  _$MedicalReminderSnapshotCopyWithImpl(this._self, this._then);

  final MedicalReminderSnapshot _self;
  final $Res Function(MedicalReminderSnapshot) _then;

/// Create a copy of MedicalReminderSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stages = null,Object? computedAt = null,}) {
  return _then(MedicalReminderSnapshot(
stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<MedicalReminderStage>,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalReminderSnapshot].
extension MedicalReminderSnapshotPatterns on MedicalReminderSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalReminderSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalReminderSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalReminderSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MedicalReminderSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalReminderSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalReminderSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MedicalReminderStage> stages,  DateTime computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalReminderSnapshot() when $default != null:
return $default(_that.stages,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MedicalReminderStage> stages,  DateTime computedAt)  $default,) {final _that = this;
switch (_that) {
case _MedicalReminderSnapshot():
return $default(_that.stages,_that.computedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MedicalReminderStage> stages,  DateTime computedAt)?  $default,) {final _that = this;
switch (_that) {
case _MedicalReminderSnapshot() when $default != null:
return $default(_that.stages,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalReminderSnapshot implements MedicalReminderSnapshot {
  const _MedicalReminderSnapshot({required  List<MedicalReminderStage> stages, required this.computedAt}): _stages = stages;
  

 final  List<MedicalReminderStage> _stages;
@override List<MedicalReminderStage> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}

@override final  DateTime computedAt;

/// Create a copy of MedicalReminderSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalReminderSnapshotCopyWith<_MedicalReminderSnapshot> get copyWith => __$MedicalReminderSnapshotCopyWithImpl<_MedicalReminderSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalReminderSnapshot&&const DeepCollectionEquality().equals(other.stages, _stages)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_stages),computedAt);
}

@override
String toString() {
    return 'MedicalReminderSnapshot(stages: $stages, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$MedicalReminderSnapshotCopyWith<$Res> implements $MedicalReminderSnapshotCopyWith<$Res> {
  factory _$MedicalReminderSnapshotCopyWith(_MedicalReminderSnapshot value, $Res Function(_MedicalReminderSnapshot) _then) = __$MedicalReminderSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<MedicalReminderStage> stages, DateTime computedAt
});




}
/// @nodoc
class __$MedicalReminderSnapshotCopyWithImpl<$Res>
    implements _$MedicalReminderSnapshotCopyWith<$Res> {
  __$MedicalReminderSnapshotCopyWithImpl(this._self, this._then);

  final _MedicalReminderSnapshot _self;
  final $Res Function(_MedicalReminderSnapshot) _then;

/// Create a copy of MedicalReminderSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stages = null,Object? computedAt = null,}) {
  return _then(_MedicalReminderSnapshot(
stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<MedicalReminderStage>,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
