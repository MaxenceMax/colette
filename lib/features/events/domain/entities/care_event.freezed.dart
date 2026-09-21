// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareEvent {

 String get id; DateTime get startAt; DateTime get endAt; bool get pee; bool get poop; bool get diaperChange; bool get adrigyl; bool get bath; bool get eyeCare; bool get noseCare; bool get umbilicalCare; int? get bottleMl; String? get note; String get createdByDeviceId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of CareEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareEventCopyWith<CareEvent> get copyWith => _$CareEventCopyWithImpl<CareEvent>(this as CareEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CareEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startAt, _this.startAt) || other.startAt == _this.startAt)&&(identical(other.endAt, _this.endAt) || other.endAt == _this.endAt)&&(identical(other.pee, _this.pee) || other.pee == _this.pee)&&(identical(other.poop, _this.poop) || other.poop == _this.poop)&&(identical(other.diaperChange, _this.diaperChange) || other.diaperChange == _this.diaperChange)&&(identical(other.adrigyl, _this.adrigyl) || other.adrigyl == _this.adrigyl)&&(identical(other.bath, _this.bath) || other.bath == _this.bath)&&(identical(other.eyeCare, _this.eyeCare) || other.eyeCare == _this.eyeCare)&&(identical(other.noseCare, _this.noseCare) || other.noseCare == _this.noseCare)&&(identical(other.umbilicalCare, _this.umbilicalCare) || other.umbilicalCare == _this.umbilicalCare)&&(identical(other.bottleMl, _this.bottleMl) || other.bottleMl == _this.bottleMl)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdByDeviceId, _this.createdByDeviceId) || other.createdByDeviceId == _this.createdByDeviceId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as CareEvent;
  return Object.hash(runtimeType,_this.id,_this.startAt,_this.endAt,_this.pee,_this.poop,_this.diaperChange,_this.adrigyl,_this.bath,_this.eyeCare,_this.noseCare,_this.umbilicalCare,_this.bottleMl,_this.note,_this.createdByDeviceId,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as CareEvent;
  return 'CareEvent(id: ${_this.id}, startAt: ${_this.startAt}, endAt: ${_this.endAt}, pee: ${_this.pee}, poop: ${_this.poop}, diaperChange: ${_this.diaperChange}, adrigyl: ${_this.adrigyl}, bath: ${_this.bath}, eyeCare: ${_this.eyeCare}, noseCare: ${_this.noseCare}, umbilicalCare: ${_this.umbilicalCare}, bottleMl: ${_this.bottleMl}, note: ${_this.note}, createdByDeviceId: ${_this.createdByDeviceId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CareEventCopyWith<$Res>  {
  factory $CareEventCopyWith(CareEvent value, $Res Function(CareEvent) _then) = _$CareEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startAt, DateTime endAt, bool pee, bool poop, bool diaperChange, bool adrigyl, bool bath, bool eyeCare, bool noseCare, bool umbilicalCare, int? bottleMl, String? note, String createdByDeviceId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$CareEventCopyWithImpl<$Res>
    implements $CareEventCopyWith<$Res> {
  _$CareEventCopyWithImpl(this._self, this._then);

  final CareEvent _self;
  final $Res Function(CareEvent) _then;

/// Create a copy of CareEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startAt = null,Object? endAt = null,Object? pee = null,Object? poop = null,Object? diaperChange = null,Object? adrigyl = null,Object? bath = null,Object? eyeCare = null,Object? noseCare = null,Object? umbilicalCare = null,Object? bottleMl = freezed,Object? note = freezed,Object? createdByDeviceId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(CareEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,pee: null == pee ? _self.pee : pee // ignore: cast_nullable_to_non_nullable
as bool,poop: null == poop ? _self.poop : poop // ignore: cast_nullable_to_non_nullable
as bool,diaperChange: null == diaperChange ? _self.diaperChange : diaperChange // ignore: cast_nullable_to_non_nullable
as bool,adrigyl: null == adrigyl ? _self.adrigyl : adrigyl // ignore: cast_nullable_to_non_nullable
as bool,bath: null == bath ? _self.bath : bath // ignore: cast_nullable_to_non_nullable
as bool,eyeCare: null == eyeCare ? _self.eyeCare : eyeCare // ignore: cast_nullable_to_non_nullable
as bool,noseCare: null == noseCare ? _self.noseCare : noseCare // ignore: cast_nullable_to_non_nullable
as bool,umbilicalCare: null == umbilicalCare ? _self.umbilicalCare : umbilicalCare // ignore: cast_nullable_to_non_nullable
as bool,bottleMl: freezed == bottleMl ? _self.bottleMl : bottleMl // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdByDeviceId: null == createdByDeviceId ? _self.createdByDeviceId : createdByDeviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CareEvent].
extension CareEventPatterns on CareEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareEvent value)  $default,){
final _that = this;
switch (_that) {
case _CareEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CareEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startAt,  DateTime endAt,  bool pee,  bool poop,  bool diaperChange,  bool adrigyl,  bool bath,  bool eyeCare,  bool noseCare,  bool umbilicalCare,  int? bottleMl,  String? note,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareEvent() when $default != null:
return $default(_that.id,_that.startAt,_that.endAt,_that.pee,_that.poop,_that.diaperChange,_that.adrigyl,_that.bath,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bottleMl,_that.note,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startAt,  DateTime endAt,  bool pee,  bool poop,  bool diaperChange,  bool adrigyl,  bool bath,  bool eyeCare,  bool noseCare,  bool umbilicalCare,  int? bottleMl,  String? note,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CareEvent():
return $default(_that.id,_that.startAt,_that.endAt,_that.pee,_that.poop,_that.diaperChange,_that.adrigyl,_that.bath,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bottleMl,_that.note,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startAt,  DateTime endAt,  bool pee,  bool poop,  bool diaperChange,  bool adrigyl,  bool bath,  bool eyeCare,  bool noseCare,  bool umbilicalCare,  int? bottleMl,  String? note,  String createdByDeviceId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CareEvent() when $default != null:
return $default(_that.id,_that.startAt,_that.endAt,_that.pee,_that.poop,_that.diaperChange,_that.adrigyl,_that.bath,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bottleMl,_that.note,_that.createdByDeviceId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CareEvent extends CareEvent {
  const _CareEvent({required this.id, required this.startAt, required this.endAt, this.pee = false, this.poop = false, this.diaperChange = false, this.adrigyl = false, this.bath = false, this.eyeCare = false, this.noseCare = false, this.umbilicalCare = false, this.bottleMl, this.note, required this.createdByDeviceId, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  DateTime startAt;
@override final  DateTime endAt;
@override@JsonKey() final  bool pee;
@override@JsonKey() final  bool poop;
@override@JsonKey() final  bool diaperChange;
@override@JsonKey() final  bool adrigyl;
@override@JsonKey() final  bool bath;
@override@JsonKey() final  bool eyeCare;
@override@JsonKey() final  bool noseCare;
@override@JsonKey() final  bool umbilicalCare;
@override final  int? bottleMl;
@override final  String? note;
@override final  String createdByDeviceId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of CareEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareEventCopyWith<_CareEvent> get copyWith => __$CareEventCopyWithImpl<_CareEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.pee, pee) || other.pee == pee)&&(identical(other.poop, poop) || other.poop == poop)&&(identical(other.diaperChange, diaperChange) || other.diaperChange == diaperChange)&&(identical(other.adrigyl, adrigyl) || other.adrigyl == adrigyl)&&(identical(other.bath, bath) || other.bath == bath)&&(identical(other.eyeCare, eyeCare) || other.eyeCare == eyeCare)&&(identical(other.noseCare, noseCare) || other.noseCare == noseCare)&&(identical(other.umbilicalCare, umbilicalCare) || other.umbilicalCare == umbilicalCare)&&(identical(other.bottleMl, bottleMl) || other.bottleMl == bottleMl)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdByDeviceId, createdByDeviceId) || other.createdByDeviceId == createdByDeviceId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,startAt,endAt,pee,poop,diaperChange,adrigyl,bath,eyeCare,noseCare,umbilicalCare,bottleMl,note,createdByDeviceId,createdAt,updatedAt);
}

@override
String toString() {
    return 'CareEvent(id: $id, startAt: $startAt, endAt: $endAt, pee: $pee, poop: $poop, diaperChange: $diaperChange, adrigyl: $adrigyl, bath: $bath, eyeCare: $eyeCare, noseCare: $noseCare, umbilicalCare: $umbilicalCare, bottleMl: $bottleMl, note: $note, createdByDeviceId: $createdByDeviceId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CareEventCopyWith<$Res> implements $CareEventCopyWith<$Res> {
  factory _$CareEventCopyWith(_CareEvent value, $Res Function(_CareEvent) _then) = __$CareEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startAt, DateTime endAt, bool pee, bool poop, bool diaperChange, bool adrigyl, bool bath, bool eyeCare, bool noseCare, bool umbilicalCare, int? bottleMl, String? note, String createdByDeviceId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$CareEventCopyWithImpl<$Res>
    implements _$CareEventCopyWith<$Res> {
  __$CareEventCopyWithImpl(this._self, this._then);

  final _CareEvent _self;
  final $Res Function(_CareEvent) _then;

/// Create a copy of CareEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startAt = null,Object? endAt = null,Object? pee = null,Object? poop = null,Object? diaperChange = null,Object? adrigyl = null,Object? bath = null,Object? eyeCare = null,Object? noseCare = null,Object? umbilicalCare = null,Object? bottleMl = freezed,Object? note = freezed,Object? createdByDeviceId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_CareEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,pee: null == pee ? _self.pee : pee // ignore: cast_nullable_to_non_nullable
as bool,poop: null == poop ? _self.poop : poop // ignore: cast_nullable_to_non_nullable
as bool,diaperChange: null == diaperChange ? _self.diaperChange : diaperChange // ignore: cast_nullable_to_non_nullable
as bool,adrigyl: null == adrigyl ? _self.adrigyl : adrigyl // ignore: cast_nullable_to_non_nullable
as bool,bath: null == bath ? _self.bath : bath // ignore: cast_nullable_to_non_nullable
as bool,eyeCare: null == eyeCare ? _self.eyeCare : eyeCare // ignore: cast_nullable_to_non_nullable
as bool,noseCare: null == noseCare ? _self.noseCare : noseCare // ignore: cast_nullable_to_non_nullable
as bool,umbilicalCare: null == umbilicalCare ? _self.umbilicalCare : umbilicalCare // ignore: cast_nullable_to_non_nullable
as bool,bottleMl: freezed == bottleMl ? _self.bottleMl : bottleMl // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdByDeviceId: null == createdByDeviceId ? _self.createdByDeviceId : createdByDeviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
