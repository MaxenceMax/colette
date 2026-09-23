// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SleepSession {

 String get id; DateTime get startAt; DateTime? get endAt; SleepKind get kind; String get createdByDeviceId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SleepSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SleepSessionCopyWith<SleepSession> get copyWith => _$SleepSessionCopyWithImpl<SleepSession>(this as SleepSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SleepSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startAt, _this.startAt) || other.startAt == _this.startAt)&&(identical(other.endAt, _this.endAt) || other.endAt == _this.endAt)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.createdByDeviceId, _this.createdByDeviceId) || other.createdByDeviceId == _this.createdByDeviceId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as SleepSession;
  return Object.hash(runtimeType,_this.id,_this.startAt,_this.endAt,_this.kind,_this.createdByDeviceId,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as SleepSession;
  return 'SleepSession(id: ${_this.id}, startAt: ${_this.startAt}, endAt: ${_this.endAt}, kind: ${_this.kind}, createdByDeviceId: ${_this.createdByDeviceId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SleepSessionCopyWith<$Res>  {
  factory $SleepSessionCopyWith(SleepSession value, $Res Function(SleepSession) _then) = _$SleepSessionCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startAt, DateTime? endAt, SleepKind kind, String createdByDeviceId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SleepSessionCopyWithImpl<$Res>
    implements $SleepSessionCopyWith<$Res> {
  _$SleepSessionCopyWithImpl(this._self, this._then);

  final SleepSession _self;
  final $Res Function(SleepSession) _then;

/// Create a copy of SleepSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startAt = null,Object? endAt = freezed,Object? kind = null,Object? createdByDeviceId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(SleepSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SleepKind,createdByDeviceId: null == createdByDeviceId ? _self.createdByDeviceId : createdByDeviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SleepSession].
extension SleepSessionPatterns on SleepSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SleepSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SleepSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SleepSession value)  $default,){
final _that = this;
switch (_that) {
case _SleepSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SleepSession value)?  $default,){
final _that = this;
switch (_that) {
case _SleepSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startAt,  DateTime? endAt,  SleepKind kind,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SleepSession() when $default != null:
return $default(_that.id,_that.startAt,_that.endAt,_that.kind,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startAt,  DateTime? endAt,  SleepKind kind,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SleepSession():
return $default(_that.id,_that.startAt,_that.endAt,_that.kind,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startAt,  DateTime? endAt,  SleepKind kind,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SleepSession() when $default != null:
return $default(_that.id,_that.startAt,_that.endAt,_that.kind,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SleepSession extends SleepSession {
  const _SleepSession({required this.id, required this.startAt, this.endAt, required this.kind, required this.createdByDeviceId, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  DateTime startAt;
@override final  DateTime? endAt;
@override final  SleepKind kind;
@override final  String createdByDeviceId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SleepSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SleepSessionCopyWith<_SleepSession> get copyWith => __$SleepSessionCopyWithImpl<_SleepSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SleepSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdByDeviceId, createdByDeviceId) || other.createdByDeviceId == createdByDeviceId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,startAt,endAt,kind,createdByDeviceId,createdAt,updatedAt);
}

@override
String toString() {
    return 'SleepSession(id: $id, startAt: $startAt, endAt: $endAt, kind: $kind, createdByDeviceId: $createdByDeviceId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SleepSessionCopyWith<$Res> implements $SleepSessionCopyWith<$Res> {
  factory _$SleepSessionCopyWith(_SleepSession value, $Res Function(_SleepSession) _then) = __$SleepSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startAt, DateTime? endAt, SleepKind kind, String createdByDeviceId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SleepSessionCopyWithImpl<$Res>
    implements _$SleepSessionCopyWith<$Res> {
  __$SleepSessionCopyWithImpl(this._self, this._then);

  final _SleepSession _self;
  final $Res Function(_SleepSession) _then;

/// Create a copy of SleepSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startAt = null,Object? endAt = freezed,Object? kind = null,Object? createdByDeviceId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SleepSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SleepKind,createdByDeviceId: null == createdByDeviceId ? _self.createdByDeviceId : createdByDeviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
