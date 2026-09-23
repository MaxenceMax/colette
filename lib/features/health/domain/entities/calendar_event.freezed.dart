// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CalendarEvent {

 String get eventId; String get url; String get title; DateTime get start; DateTime get end; String? get notes;/// `calendarItemExternalIdentifier` d'EventKit : l'UID iCloud, identique sur tous les appareils.
 String? get externalId;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CalendarEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.externalId, _this.externalId) || other.externalId == _this.externalId));
}


@override
int get hashCode {
  final _this = this as CalendarEvent;
  return Object.hash(runtimeType,_this.eventId,_this.url,_this.title,_this.start,_this.end,_this.notes,_this.externalId);
}

@override
String toString() {
  final _this = this as CalendarEvent;
  return 'CalendarEvent(eventId: ${_this.eventId}, url: ${_this.url}, title: ${_this.title}, start: ${_this.start}, end: ${_this.end}, notes: ${_this.notes}, externalId: ${_this.externalId})';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 String eventId, String url, String title, DateTime start, DateTime end, String? notes, String? externalId
});




}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? url = null,Object? title = null,Object? start = null,Object? end = null,Object? notes = freezed,Object? externalId = freezed,}) {
  return _then(CalendarEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String url,  String title,  DateTime start,  DateTime end,  String? notes,  String? externalId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.eventId,_that.url,_that.title,_that.start,_that.end,_that.notes,_that.externalId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String url,  String title,  DateTime start,  DateTime end,  String? notes,  String? externalId)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.eventId,_that.url,_that.title,_that.start,_that.end,_that.notes,_that.externalId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String url,  String title,  DateTime start,  DateTime end,  String? notes,  String? externalId)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.eventId,_that.url,_that.title,_that.start,_that.end,_that.notes,_that.externalId);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarEvent implements CalendarEvent {
  const _CalendarEvent({required this.eventId, required this.url, required this.title, required this.start, required this.end, this.notes, this.externalId});
  

@override final  String eventId;
@override final  String url;
@override final  String title;
@override final  DateTime start;
@override final  DateTime end;
@override final  String? notes;
/// `calendarItemExternalIdentifier` d'EventKit : l'UID iCloud, identique sur tous les appareils.
@override final  String? externalId;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.externalId, externalId) || other.externalId == externalId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,eventId,url,title,start,end,notes,externalId);
}

@override
String toString() {
    return 'CalendarEvent(eventId: $eventId, url: $url, title: $title, start: $start, end: $end, notes: $notes, externalId: $externalId)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String url, String title, DateTime start, DateTime end, String? notes, String? externalId
});




}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? url = null,Object? title = null,Object? start = null,Object? end = null,Object? notes = freezed,Object? externalId = freezed,}) {
  return _then(_CalendarEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CalendarEventDraft {

 String get url; String get title; DateTime get start; DateTime get end; String? get notes; List<DateTime> get alarms;
/// Create a copy of CalendarEventDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventDraftCopyWith<CalendarEventDraft> get copyWith => _$CalendarEventDraftCopyWithImpl<CalendarEventDraft>(this as CalendarEventDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CalendarEventDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEventDraft&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.alarms, _this.alarms));
}


@override
int get hashCode {
  final _this = this as CalendarEventDraft;
  return Object.hash(runtimeType,_this.url,_this.title,_this.start,_this.end,_this.notes,const DeepCollectionEquality().hash(_this.alarms));
}

@override
String toString() {
  final _this = this as CalendarEventDraft;
  return 'CalendarEventDraft(url: ${_this.url}, title: ${_this.title}, start: ${_this.start}, end: ${_this.end}, notes: ${_this.notes}, alarms: ${_this.alarms})';
}


}

/// @nodoc
abstract mixin class $CalendarEventDraftCopyWith<$Res>  {
  factory $CalendarEventDraftCopyWith(CalendarEventDraft value, $Res Function(CalendarEventDraft) _then) = _$CalendarEventDraftCopyWithImpl;
@useResult
$Res call({
 String url, String title, DateTime start, DateTime end, String? notes, List<DateTime> alarms
});




}
/// @nodoc
class _$CalendarEventDraftCopyWithImpl<$Res>
    implements $CalendarEventDraftCopyWith<$Res> {
  _$CalendarEventDraftCopyWithImpl(this._self, this._then);

  final CalendarEventDraft _self;
  final $Res Function(CalendarEventDraft) _then;

/// Create a copy of CalendarEventDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? title = null,Object? start = null,Object? end = null,Object? notes = freezed,Object? alarms = null,}) {
  return _then(CalendarEventDraft(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,alarms: null == alarms ? _self.alarms : alarms // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEventDraft].
extension CalendarEventDraftPatterns on CalendarEventDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEventDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEventDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEventDraft value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEventDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEventDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEventDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String title,  DateTime start,  DateTime end,  String? notes,  List<DateTime> alarms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEventDraft() when $default != null:
return $default(_that.url,_that.title,_that.start,_that.end,_that.notes,_that.alarms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String title,  DateTime start,  DateTime end,  String? notes,  List<DateTime> alarms)  $default,) {final _that = this;
switch (_that) {
case _CalendarEventDraft():
return $default(_that.url,_that.title,_that.start,_that.end,_that.notes,_that.alarms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String title,  DateTime start,  DateTime end,  String? notes,  List<DateTime> alarms)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEventDraft() when $default != null:
return $default(_that.url,_that.title,_that.start,_that.end,_that.notes,_that.alarms);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarEventDraft implements CalendarEventDraft {
  const _CalendarEventDraft({required this.url, required this.title, required this.start, required this.end, this.notes,  List<DateTime> alarms = const <DateTime>[]}): _alarms = alarms;
  

@override final  String url;
@override final  String title;
@override final  DateTime start;
@override final  DateTime end;
@override final  String? notes;
 final  List<DateTime> _alarms;
@override@JsonKey() List<DateTime> get alarms {
  if (_alarms is EqualUnmodifiableListView) return _alarms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alarms);
}


/// Create a copy of CalendarEventDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventDraftCopyWith<_CalendarEventDraft> get copyWith => __$CalendarEventDraftCopyWithImpl<_CalendarEventDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEventDraft&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.alarms, _alarms));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,title,start,end,notes,const DeepCollectionEquality().hash(_alarms));
}

@override
String toString() {
    return 'CalendarEventDraft(url: $url, title: $title, start: $start, end: $end, notes: $notes, alarms: $alarms)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventDraftCopyWith<$Res> implements $CalendarEventDraftCopyWith<$Res> {
  factory _$CalendarEventDraftCopyWith(_CalendarEventDraft value, $Res Function(_CalendarEventDraft) _then) = __$CalendarEventDraftCopyWithImpl;
@override @useResult
$Res call({
 String url, String title, DateTime start, DateTime end, String? notes, List<DateTime> alarms
});




}
/// @nodoc
class __$CalendarEventDraftCopyWithImpl<$Res>
    implements _$CalendarEventDraftCopyWith<$Res> {
  __$CalendarEventDraftCopyWithImpl(this._self, this._then);

  final _CalendarEventDraft _self;
  final $Res Function(_CalendarEventDraft) _then;

/// Create a copy of CalendarEventDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? title = null,Object? start = null,Object? end = null,Object? notes = freezed,Object? alarms = null,}) {
  return _then(_CalendarEventDraft(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,alarms: null == alarms ? _self._alarms : alarms // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}


}

// dart format on
