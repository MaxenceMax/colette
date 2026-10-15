// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tooth_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToothRecord {

 ToothId get toothId; DateTime? get eruptedAt; DateTime? get lostAt; String? get note; DateTime get updatedAt; String get updatedByDeviceId;
/// Create a copy of ToothRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToothRecordCopyWith<ToothRecord> get copyWith => _$ToothRecordCopyWithImpl<ToothRecord>(this as ToothRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ToothRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToothRecord&&(identical(other.toothId, _this.toothId) || other.toothId == _this.toothId)&&(identical(other.eruptedAt, _this.eruptedAt) || other.eruptedAt == _this.eruptedAt)&&(identical(other.lostAt, _this.lostAt) || other.lostAt == _this.lostAt)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.updatedByDeviceId, _this.updatedByDeviceId) || other.updatedByDeviceId == _this.updatedByDeviceId));
}


@override
int get hashCode {
  final _this = this as ToothRecord;
  return Object.hash(runtimeType,_this.toothId,_this.eruptedAt,_this.lostAt,_this.note,_this.updatedAt,_this.updatedByDeviceId);
}

@override
String toString() {
  final _this = this as ToothRecord;
  return 'ToothRecord(toothId: ${_this.toothId}, eruptedAt: ${_this.eruptedAt}, lostAt: ${_this.lostAt}, note: ${_this.note}, updatedAt: ${_this.updatedAt}, updatedByDeviceId: ${_this.updatedByDeviceId})';
}


}

/// @nodoc
abstract mixin class $ToothRecordCopyWith<$Res>  {
  factory $ToothRecordCopyWith(ToothRecord value, $Res Function(ToothRecord) _then) = _$ToothRecordCopyWithImpl;
@useResult
$Res call({
 ToothId toothId, DateTime? eruptedAt, DateTime? lostAt, String? note, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class _$ToothRecordCopyWithImpl<$Res>
    implements $ToothRecordCopyWith<$Res> {
  _$ToothRecordCopyWithImpl(this._self, this._then);

  final ToothRecord _self;
  final $Res Function(ToothRecord) _then;

/// Create a copy of ToothRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toothId = null,Object? eruptedAt = freezed,Object? lostAt = freezed,Object? note = freezed,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(ToothRecord(
toothId: null == toothId ? _self.toothId : toothId // ignore: cast_nullable_to_non_nullable
as ToothId,eruptedAt: freezed == eruptedAt ? _self.eruptedAt : eruptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lostAt: freezed == lostAt ? _self.lostAt : lostAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToothRecord].
extension ToothRecordPatterns on ToothRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToothRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToothRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToothRecord value)  $default,){
final _that = this;
switch (_that) {
case _ToothRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToothRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ToothRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ToothId toothId,  DateTime? eruptedAt,  DateTime? lostAt,  String? note,  DateTime updatedAt,  String updatedByDeviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToothRecord() when $default != null:
return $default(_that.toothId,_that.eruptedAt,_that.lostAt,_that.note,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ToothId toothId,  DateTime? eruptedAt,  DateTime? lostAt,  String? note,  DateTime updatedAt,  String updatedByDeviceId)  $default,) {final _that = this;
switch (_that) {
case _ToothRecord():
return $default(_that.toothId,_that.eruptedAt,_that.lostAt,_that.note,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ToothId toothId,  DateTime? eruptedAt,  DateTime? lostAt,  String? note,  DateTime updatedAt,  String updatedByDeviceId)?  $default,) {final _that = this;
switch (_that) {
case _ToothRecord() when $default != null:
return $default(_that.toothId,_that.eruptedAt,_that.lostAt,_that.note,_that.updatedAt,_that.updatedByDeviceId);case _:
  return null;

}
}

}

/// @nodoc


class _ToothRecord extends ToothRecord {
  const _ToothRecord({required this.toothId, this.eruptedAt, this.lostAt, this.note, required this.updatedAt, required this.updatedByDeviceId}): super._();
  

@override final  ToothId toothId;
@override final  DateTime? eruptedAt;
@override final  DateTime? lostAt;
@override final  String? note;
@override final  DateTime updatedAt;
@override final  String updatedByDeviceId;

/// Create a copy of ToothRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToothRecordCopyWith<_ToothRecord> get copyWith => __$ToothRecordCopyWithImpl<_ToothRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToothRecord&&(identical(other.toothId, toothId) || other.toothId == toothId)&&(identical(other.eruptedAt, eruptedAt) || other.eruptedAt == eruptedAt)&&(identical(other.lostAt, lostAt) || other.lostAt == lostAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedByDeviceId, updatedByDeviceId) || other.updatedByDeviceId == updatedByDeviceId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,toothId,eruptedAt,lostAt,note,updatedAt,updatedByDeviceId);
}

@override
String toString() {
    return 'ToothRecord(toothId: $toothId, eruptedAt: $eruptedAt, lostAt: $lostAt, note: $note, updatedAt: $updatedAt, updatedByDeviceId: $updatedByDeviceId)';
}


}

/// @nodoc
abstract mixin class _$ToothRecordCopyWith<$Res> implements $ToothRecordCopyWith<$Res> {
  factory _$ToothRecordCopyWith(_ToothRecord value, $Res Function(_ToothRecord) _then) = __$ToothRecordCopyWithImpl;
@override @useResult
$Res call({
 ToothId toothId, DateTime? eruptedAt, DateTime? lostAt, String? note, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class __$ToothRecordCopyWithImpl<$Res>
    implements _$ToothRecordCopyWith<$Res> {
  __$ToothRecordCopyWithImpl(this._self, this._then);

  final _ToothRecord _self;
  final $Res Function(_ToothRecord) _then;

/// Create a copy of ToothRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toothId = null,Object? eruptedAt = freezed,Object? lostAt = freezed,Object? note = freezed,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(_ToothRecord(
toothId: null == toothId ? _self.toothId : toothId // ignore: cast_nullable_to_non_nullable
as ToothId,eruptedAt: freezed == eruptedAt ? _self.eruptedAt : eruptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lostAt: freezed == lostAt ? _self.lostAt : lostAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
