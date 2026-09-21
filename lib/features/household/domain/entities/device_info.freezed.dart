// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceInfo {

 String get id; String get label; String? get fcmToken; bool get notifyOnOthersEvents; bool get notifyBottleReminder; bool get notifyMorningDigest; int get morningDigestHour;
/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<DeviceInfo> get copyWith => _$DeviceInfoCopyWithImpl<DeviceInfo>(this as DeviceInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.fcmToken, _this.fcmToken) || other.fcmToken == _this.fcmToken)&&(identical(other.notifyOnOthersEvents, _this.notifyOnOthersEvents) || other.notifyOnOthersEvents == _this.notifyOnOthersEvents)&&(identical(other.notifyBottleReminder, _this.notifyBottleReminder) || other.notifyBottleReminder == _this.notifyBottleReminder)&&(identical(other.notifyMorningDigest, _this.notifyMorningDigest) || other.notifyMorningDigest == _this.notifyMorningDigest)&&(identical(other.morningDigestHour, _this.morningDigestHour) || other.morningDigestHour == _this.morningDigestHour));
}


@override
int get hashCode {
  final _this = this as DeviceInfo;
  return Object.hash(runtimeType,_this.id,_this.label,_this.fcmToken,_this.notifyOnOthersEvents,_this.notifyBottleReminder,_this.notifyMorningDigest,_this.morningDigestHour);
}

@override
String toString() {
  final _this = this as DeviceInfo;
  return 'DeviceInfo(id: ${_this.id}, label: ${_this.label}, fcmToken: ${_this.fcmToken}, notifyOnOthersEvents: ${_this.notifyOnOthersEvents}, notifyBottleReminder: ${_this.notifyBottleReminder}, notifyMorningDigest: ${_this.notifyMorningDigest}, morningDigestHour: ${_this.morningDigestHour})';
}


}

/// @nodoc
abstract mixin class $DeviceInfoCopyWith<$Res>  {
  factory $DeviceInfoCopyWith(DeviceInfo value, $Res Function(DeviceInfo) _then) = _$DeviceInfoCopyWithImpl;
@useResult
$Res call({
 String id, String label, String? fcmToken, bool notifyOnOthersEvents, bool notifyBottleReminder, bool notifyMorningDigest, int morningDigestHour
});




}
/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._self, this._then);

  final DeviceInfo _self;
  final $Res Function(DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? fcmToken = freezed,Object? notifyOnOthersEvents = null,Object? notifyBottleReminder = null,Object? notifyMorningDigest = null,Object? morningDigestHour = null,}) {
  return _then(DeviceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,notifyOnOthersEvents: null == notifyOnOthersEvents ? _self.notifyOnOthersEvents : notifyOnOthersEvents // ignore: cast_nullable_to_non_nullable
as bool,notifyBottleReminder: null == notifyBottleReminder ? _self.notifyBottleReminder : notifyBottleReminder // ignore: cast_nullable_to_non_nullable
as bool,notifyMorningDigest: null == notifyMorningDigest ? _self.notifyMorningDigest : notifyMorningDigest // ignore: cast_nullable_to_non_nullable
as bool,morningDigestHour: null == morningDigestHour ? _self.morningDigestHour : morningDigestHour // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfo].
extension DeviceInfoPatterns on DeviceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfo value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String? fcmToken,  bool notifyOnOthersEvents,  bool notifyBottleReminder,  bool notifyMorningDigest,  int morningDigestHour)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.id,_that.label,_that.fcmToken,_that.notifyOnOthersEvents,_that.notifyBottleReminder,_that.notifyMorningDigest,_that.morningDigestHour);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String? fcmToken,  bool notifyOnOthersEvents,  bool notifyBottleReminder,  bool notifyMorningDigest,  int morningDigestHour)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that.id,_that.label,_that.fcmToken,_that.notifyOnOthersEvents,_that.notifyBottleReminder,_that.notifyMorningDigest,_that.morningDigestHour);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String? fcmToken,  bool notifyOnOthersEvents,  bool notifyBottleReminder,  bool notifyMorningDigest,  int morningDigestHour)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.id,_that.label,_that.fcmToken,_that.notifyOnOthersEvents,_that.notifyBottleReminder,_that.notifyMorningDigest,_that.morningDigestHour);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceInfo implements DeviceInfo {
  const _DeviceInfo({required this.id, required this.label, this.fcmToken, this.notifyOnOthersEvents = true, this.notifyBottleReminder = true, this.notifyMorningDigest = true, this.morningDigestHour = 8});
  

@override final  String id;
@override final  String label;
@override final  String? fcmToken;
@override@JsonKey() final  bool notifyOnOthersEvents;
@override@JsonKey() final  bool notifyBottleReminder;
@override@JsonKey() final  bool notifyMorningDigest;
@override@JsonKey() final  int morningDigestHour;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoCopyWith<_DeviceInfo> get copyWith => __$DeviceInfoCopyWithImpl<_DeviceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.notifyOnOthersEvents, notifyOnOthersEvents) || other.notifyOnOthersEvents == notifyOnOthersEvents)&&(identical(other.notifyBottleReminder, notifyBottleReminder) || other.notifyBottleReminder == notifyBottleReminder)&&(identical(other.notifyMorningDigest, notifyMorningDigest) || other.notifyMorningDigest == notifyMorningDigest)&&(identical(other.morningDigestHour, morningDigestHour) || other.morningDigestHour == morningDigestHour));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,fcmToken,notifyOnOthersEvents,notifyBottleReminder,notifyMorningDigest,morningDigestHour);
}

@override
String toString() {
    return 'DeviceInfo(id: $id, label: $label, fcmToken: $fcmToken, notifyOnOthersEvents: $notifyOnOthersEvents, notifyBottleReminder: $notifyBottleReminder, notifyMorningDigest: $notifyMorningDigest, morningDigestHour: $morningDigestHour)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoCopyWith<$Res> implements $DeviceInfoCopyWith<$Res> {
  factory _$DeviceInfoCopyWith(_DeviceInfo value, $Res Function(_DeviceInfo) _then) = __$DeviceInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String? fcmToken, bool notifyOnOthersEvents, bool notifyBottleReminder, bool notifyMorningDigest, int morningDigestHour
});




}
/// @nodoc
class __$DeviceInfoCopyWithImpl<$Res>
    implements _$DeviceInfoCopyWith<$Res> {
  __$DeviceInfoCopyWithImpl(this._self, this._then);

  final _DeviceInfo _self;
  final $Res Function(_DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? fcmToken = freezed,Object? notifyOnOthersEvents = null,Object? notifyBottleReminder = null,Object? notifyMorningDigest = null,Object? morningDigestHour = null,}) {
  return _then(_DeviceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,notifyOnOthersEvents: null == notifyOnOthersEvents ? _self.notifyOnOthersEvents : notifyOnOthersEvents // ignore: cast_nullable_to_non_nullable
as bool,notifyBottleReminder: null == notifyBottleReminder ? _self.notifyBottleReminder : notifyBottleReminder // ignore: cast_nullable_to_non_nullable
as bool,notifyMorningDigest: null == notifyMorningDigest ? _self.notifyMorningDigest : notifyMorningDigest // ignore: cast_nullable_to_non_nullable
as bool,morningDigestHour: null == morningDigestHour ? _self.morningDigestHour : morningDigestHour // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
