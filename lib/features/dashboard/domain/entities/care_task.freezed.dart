// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareTask {

 CareType get type; int get target; int get done; DateTime? get lastDoneAt;
/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareTaskCopyWith<CareTask> get copyWith => _$CareTaskCopyWithImpl<CareTask>(this as CareTask, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CareTask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareTask&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.lastDoneAt, _this.lastDoneAt) || other.lastDoneAt == _this.lastDoneAt));
}


@override
int get hashCode {
  final _this = this as CareTask;
  return Object.hash(runtimeType,_this.type,_this.target,_this.done,_this.lastDoneAt);
}

@override
String toString() {
  final _this = this as CareTask;
  return 'CareTask(type: ${_this.type}, target: ${_this.target}, done: ${_this.done}, lastDoneAt: ${_this.lastDoneAt})';
}


}

/// @nodoc
abstract mixin class $CareTaskCopyWith<$Res>  {
  factory $CareTaskCopyWith(CareTask value, $Res Function(CareTask) _then) = _$CareTaskCopyWithImpl;
@useResult
$Res call({
 CareType type, int target, int done, DateTime? lastDoneAt
});




}
/// @nodoc
class _$CareTaskCopyWithImpl<$Res>
    implements $CareTaskCopyWith<$Res> {
  _$CareTaskCopyWithImpl(this._self, this._then);

  final CareTask _self;
  final $Res Function(CareTask) _then;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? target = null,Object? done = null,Object? lastDoneAt = freezed,}) {
  return _then(CareTask(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CareType,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,lastDoneAt: freezed == lastDoneAt ? _self.lastDoneAt : lastDoneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CareTask].
extension CareTaskPatterns on CareTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareTask value)  $default,){
final _that = this;
switch (_that) {
case _CareTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareTask value)?  $default,){
final _that = this;
switch (_that) {
case _CareTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CareType type,  int target,  int done,  DateTime? lastDoneAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareTask() when $default != null:
return $default(_that.type,_that.target,_that.done,_that.lastDoneAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CareType type,  int target,  int done,  DateTime? lastDoneAt)  $default,) {final _that = this;
switch (_that) {
case _CareTask():
return $default(_that.type,_that.target,_that.done,_that.lastDoneAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CareType type,  int target,  int done,  DateTime? lastDoneAt)?  $default,) {final _that = this;
switch (_that) {
case _CareTask() when $default != null:
return $default(_that.type,_that.target,_that.done,_that.lastDoneAt);case _:
  return null;

}
}

}

/// @nodoc


class _CareTask extends CareTask {
  const _CareTask({required this.type, required this.target, required this.done, this.lastDoneAt}): super._();
  

@override final  CareType type;
@override final  int target;
@override final  int done;
@override final  DateTime? lastDoneAt;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareTaskCopyWith<_CareTask> get copyWith => __$CareTaskCopyWithImpl<_CareTask>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareTask&&(identical(other.type, type) || other.type == type)&&(identical(other.target, target) || other.target == target)&&(identical(other.done, done) || other.done == done)&&(identical(other.lastDoneAt, lastDoneAt) || other.lastDoneAt == lastDoneAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,target,done,lastDoneAt);
}

@override
String toString() {
    return 'CareTask(type: $type, target: $target, done: $done, lastDoneAt: $lastDoneAt)';
}


}

/// @nodoc
abstract mixin class _$CareTaskCopyWith<$Res> implements $CareTaskCopyWith<$Res> {
  factory _$CareTaskCopyWith(_CareTask value, $Res Function(_CareTask) _then) = __$CareTaskCopyWithImpl;
@override @useResult
$Res call({
 CareType type, int target, int done, DateTime? lastDoneAt
});




}
/// @nodoc
class __$CareTaskCopyWithImpl<$Res>
    implements _$CareTaskCopyWith<$Res> {
  __$CareTaskCopyWithImpl(this._self, this._then);

  final _CareTask _self;
  final $Res Function(_CareTask) _then;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? target = null,Object? done = null,Object? lastDoneAt = freezed,}) {
  return _then(_CareTask(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CareType,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,lastDoneAt: freezed == lastDoneAt ? _self.lastDoneAt : lastDoneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
