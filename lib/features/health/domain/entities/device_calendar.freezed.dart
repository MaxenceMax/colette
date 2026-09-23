// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_calendar.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceCalendar {

 String get id; String get title; String? get colorHex; String get source;
/// Create a copy of DeviceCalendar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCalendarCopyWith<DeviceCalendar> get copyWith => _$DeviceCalendarCopyWithImpl<DeviceCalendar>(this as DeviceCalendar, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceCalendar;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceCalendar&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.colorHex, _this.colorHex) || other.colorHex == _this.colorHex)&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as DeviceCalendar;
  return Object.hash(runtimeType,_this.id,_this.title,_this.colorHex,_this.source);
}

@override
String toString() {
  final _this = this as DeviceCalendar;
  return 'DeviceCalendar(id: ${_this.id}, title: ${_this.title}, colorHex: ${_this.colorHex}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $DeviceCalendarCopyWith<$Res>  {
  factory $DeviceCalendarCopyWith(DeviceCalendar value, $Res Function(DeviceCalendar) _then) = _$DeviceCalendarCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? colorHex, String source
});




}
/// @nodoc
class _$DeviceCalendarCopyWithImpl<$Res>
    implements $DeviceCalendarCopyWith<$Res> {
  _$DeviceCalendarCopyWithImpl(this._self, this._then);

  final DeviceCalendar _self;
  final $Res Function(DeviceCalendar) _then;

/// Create a copy of DeviceCalendar
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? colorHex = freezed,Object? source = null,}) {
  return _then(DeviceCalendar(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceCalendar].
extension DeviceCalendarPatterns on DeviceCalendar {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceCalendar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceCalendar() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceCalendar value)  $default,){
final _that = this;
switch (_that) {
case _DeviceCalendar():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceCalendar value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceCalendar() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? colorHex,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceCalendar() when $default != null:
return $default(_that.id,_that.title,_that.colorHex,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? colorHex,  String source)  $default,) {final _that = this;
switch (_that) {
case _DeviceCalendar():
return $default(_that.id,_that.title,_that.colorHex,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? colorHex,  String source)?  $default,) {final _that = this;
switch (_that) {
case _DeviceCalendar() when $default != null:
return $default(_that.id,_that.title,_that.colorHex,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceCalendar implements DeviceCalendar {
  const _DeviceCalendar({required this.id, required this.title, this.colorHex, required this.source});
  

@override final  String id;
@override final  String title;
@override final  String? colorHex;
@override final  String source;

/// Create a copy of DeviceCalendar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCalendarCopyWith<_DeviceCalendar> get copyWith => __$DeviceCalendarCopyWithImpl<_DeviceCalendar>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceCalendar&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,colorHex,source);
}

@override
String toString() {
    return 'DeviceCalendar(id: $id, title: $title, colorHex: $colorHex, source: $source)';
}


}

/// @nodoc
abstract mixin class _$DeviceCalendarCopyWith<$Res> implements $DeviceCalendarCopyWith<$Res> {
  factory _$DeviceCalendarCopyWith(_DeviceCalendar value, $Res Function(_DeviceCalendar) _then) = __$DeviceCalendarCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? colorHex, String source
});




}
/// @nodoc
class __$DeviceCalendarCopyWithImpl<$Res>
    implements _$DeviceCalendarCopyWith<$Res> {
  __$DeviceCalendarCopyWithImpl(this._self, this._then);

  final _DeviceCalendar _self;
  final $Res Function(_DeviceCalendar) _then;

/// Create a copy of DeviceCalendar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? colorHex = freezed,Object? source = null,}) {
  return _then(_DeviceCalendar(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
