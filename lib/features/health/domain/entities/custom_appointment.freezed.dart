// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomAppointment {

 String get id; String get title; DateTime get appointmentAt; String? get practitioner; DateTime? get doneAt; String? get note; List<CustomVaccine> get vaccines; DateTime get updatedAt; String get updatedByDeviceId;
/// Create a copy of CustomAppointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomAppointmentCopyWith<CustomAppointment> get copyWith => _$CustomAppointmentCopyWithImpl<CustomAppointment>(this as CustomAppointment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CustomAppointment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomAppointment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.appointmentAt, _this.appointmentAt) || other.appointmentAt == _this.appointmentAt)&&(identical(other.practitioner, _this.practitioner) || other.practitioner == _this.practitioner)&&(identical(other.doneAt, _this.doneAt) || other.doneAt == _this.doneAt)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.vaccines, _this.vaccines)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.updatedByDeviceId, _this.updatedByDeviceId) || other.updatedByDeviceId == _this.updatedByDeviceId));
}


@override
int get hashCode {
  final _this = this as CustomAppointment;
  return Object.hash(runtimeType,_this.id,_this.title,_this.appointmentAt,_this.practitioner,_this.doneAt,_this.note,const DeepCollectionEquality().hash(_this.vaccines),_this.updatedAt,_this.updatedByDeviceId);
}

@override
String toString() {
  final _this = this as CustomAppointment;
  return 'CustomAppointment(id: ${_this.id}, title: ${_this.title}, appointmentAt: ${_this.appointmentAt}, practitioner: ${_this.practitioner}, doneAt: ${_this.doneAt}, note: ${_this.note}, vaccines: ${_this.vaccines}, updatedAt: ${_this.updatedAt}, updatedByDeviceId: ${_this.updatedByDeviceId})';
}


}

/// @nodoc
abstract mixin class $CustomAppointmentCopyWith<$Res>  {
  factory $CustomAppointmentCopyWith(CustomAppointment value, $Res Function(CustomAppointment) _then) = _$CustomAppointmentCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime appointmentAt, String? practitioner, DateTime? doneAt, String? note, List<CustomVaccine> vaccines, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class _$CustomAppointmentCopyWithImpl<$Res>
    implements $CustomAppointmentCopyWith<$Res> {
  _$CustomAppointmentCopyWithImpl(this._self, this._then);

  final CustomAppointment _self;
  final $Res Function(CustomAppointment) _then;

/// Create a copy of CustomAppointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? appointmentAt = null,Object? practitioner = freezed,Object? doneAt = freezed,Object? note = freezed,Object? vaccines = null,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(CustomAppointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,appointmentAt: null == appointmentAt ? _self.appointmentAt : appointmentAt // ignore: cast_nullable_to_non_nullable
as DateTime,practitioner: freezed == practitioner ? _self.practitioner : practitioner // ignore: cast_nullable_to_non_nullable
as String?,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,vaccines: null == vaccines ? _self.vaccines : vaccines // ignore: cast_nullable_to_non_nullable
as List<CustomVaccine>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomAppointment].
extension CustomAppointmentPatterns on CustomAppointment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomAppointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomAppointment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomAppointment value)  $default,){
final _that = this;
switch (_that) {
case _CustomAppointment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomAppointment value)?  $default,){
final _that = this;
switch (_that) {
case _CustomAppointment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  List<CustomVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomAppointment() when $default != null:
return $default(_that.id,_that.title,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  List<CustomVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)  $default,) {final _that = this;
switch (_that) {
case _CustomAppointment():
return $default(_that.id,_that.title,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  List<CustomVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)?  $default,) {final _that = this;
switch (_that) {
case _CustomAppointment() when $default != null:
return $default(_that.id,_that.title,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
  return null;

}
}

}

/// @nodoc


class _CustomAppointment implements CustomAppointment {
  const _CustomAppointment({required this.id, required this.title, required this.appointmentAt, this.practitioner, this.doneAt, this.note,  List<CustomVaccine> vaccines = const <CustomVaccine>[], required this.updatedAt, required this.updatedByDeviceId}): _vaccines = vaccines;
  

@override final  String id;
@override final  String title;
@override final  DateTime appointmentAt;
@override final  String? practitioner;
@override final  DateTime? doneAt;
@override final  String? note;
 final  List<CustomVaccine> _vaccines;
@override@JsonKey() List<CustomVaccine> get vaccines {
  if (_vaccines is EqualUnmodifiableListView) return _vaccines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vaccines);
}

@override final  DateTime updatedAt;
@override final  String updatedByDeviceId;

/// Create a copy of CustomAppointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomAppointmentCopyWith<_CustomAppointment> get copyWith => __$CustomAppointmentCopyWithImpl<_CustomAppointment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomAppointment&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.appointmentAt, appointmentAt) || other.appointmentAt == appointmentAt)&&(identical(other.practitioner, practitioner) || other.practitioner == practitioner)&&(identical(other.doneAt, doneAt) || other.doneAt == doneAt)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.vaccines, _vaccines)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedByDeviceId, updatedByDeviceId) || other.updatedByDeviceId == updatedByDeviceId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,appointmentAt,practitioner,doneAt,note,const DeepCollectionEquality().hash(_vaccines),updatedAt,updatedByDeviceId);
}

@override
String toString() {
    return 'CustomAppointment(id: $id, title: $title, appointmentAt: $appointmentAt, practitioner: $practitioner, doneAt: $doneAt, note: $note, vaccines: $vaccines, updatedAt: $updatedAt, updatedByDeviceId: $updatedByDeviceId)';
}


}

/// @nodoc
abstract mixin class _$CustomAppointmentCopyWith<$Res> implements $CustomAppointmentCopyWith<$Res> {
  factory _$CustomAppointmentCopyWith(_CustomAppointment value, $Res Function(_CustomAppointment) _then) = __$CustomAppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime appointmentAt, String? practitioner, DateTime? doneAt, String? note, List<CustomVaccine> vaccines, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class __$CustomAppointmentCopyWithImpl<$Res>
    implements _$CustomAppointmentCopyWith<$Res> {
  __$CustomAppointmentCopyWithImpl(this._self, this._then);

  final _CustomAppointment _self;
  final $Res Function(_CustomAppointment) _then;

/// Create a copy of CustomAppointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? appointmentAt = null,Object? practitioner = freezed,Object? doneAt = freezed,Object? note = freezed,Object? vaccines = null,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(_CustomAppointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,appointmentAt: null == appointmentAt ? _self.appointmentAt : appointmentAt // ignore: cast_nullable_to_non_nullable
as DateTime,practitioner: freezed == practitioner ? _self.practitioner : practitioner // ignore: cast_nullable_to_non_nullable
as String?,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,vaccines: null == vaccines ? _self._vaccines : vaccines // ignore: cast_nullable_to_non_nullable
as List<CustomVaccine>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
