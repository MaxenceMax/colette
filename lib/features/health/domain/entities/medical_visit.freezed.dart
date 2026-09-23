// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_visit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicalVisit {

 MedicalStageId get stageId; DateTime? get appointmentAt; String? get practitioner; DateTime? get doneAt; String? get note; Map<VaccineCode, GivenVaccine> get vaccines; DateTime get updatedAt; String get updatedByDeviceId;
/// Create a copy of MedicalVisit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalVisitCopyWith<MedicalVisit> get copyWith => _$MedicalVisitCopyWithImpl<MedicalVisit>(this as MedicalVisit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MedicalVisit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalVisit&&(identical(other.stageId, _this.stageId) || other.stageId == _this.stageId)&&(identical(other.appointmentAt, _this.appointmentAt) || other.appointmentAt == _this.appointmentAt)&&(identical(other.practitioner, _this.practitioner) || other.practitioner == _this.practitioner)&&(identical(other.doneAt, _this.doneAt) || other.doneAt == _this.doneAt)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.vaccines, _this.vaccines)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.updatedByDeviceId, _this.updatedByDeviceId) || other.updatedByDeviceId == _this.updatedByDeviceId));
}


@override
int get hashCode {
  final _this = this as MedicalVisit;
  return Object.hash(runtimeType,_this.stageId,_this.appointmentAt,_this.practitioner,_this.doneAt,_this.note,const DeepCollectionEquality().hash(_this.vaccines),_this.updatedAt,_this.updatedByDeviceId);
}

@override
String toString() {
  final _this = this as MedicalVisit;
  return 'MedicalVisit(stageId: ${_this.stageId}, appointmentAt: ${_this.appointmentAt}, practitioner: ${_this.practitioner}, doneAt: ${_this.doneAt}, note: ${_this.note}, vaccines: ${_this.vaccines}, updatedAt: ${_this.updatedAt}, updatedByDeviceId: ${_this.updatedByDeviceId})';
}


}

/// @nodoc
abstract mixin class $MedicalVisitCopyWith<$Res>  {
  factory $MedicalVisitCopyWith(MedicalVisit value, $Res Function(MedicalVisit) _then) = _$MedicalVisitCopyWithImpl;
@useResult
$Res call({
 MedicalStageId stageId, DateTime? appointmentAt, String? practitioner, DateTime? doneAt, String? note, Map<VaccineCode, GivenVaccine> vaccines, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class _$MedicalVisitCopyWithImpl<$Res>
    implements $MedicalVisitCopyWith<$Res> {
  _$MedicalVisitCopyWithImpl(this._self, this._then);

  final MedicalVisit _self;
  final $Res Function(MedicalVisit) _then;

/// Create a copy of MedicalVisit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stageId = null,Object? appointmentAt = freezed,Object? practitioner = freezed,Object? doneAt = freezed,Object? note = freezed,Object? vaccines = null,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(MedicalVisit(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as MedicalStageId,appointmentAt: freezed == appointmentAt ? _self.appointmentAt : appointmentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,practitioner: freezed == practitioner ? _self.practitioner : practitioner // ignore: cast_nullable_to_non_nullable
as String?,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,vaccines: null == vaccines ? _self.vaccines : vaccines // ignore: cast_nullable_to_non_nullable
as Map<VaccineCode, GivenVaccine>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalVisit].
extension MedicalVisitPatterns on MedicalVisit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalVisit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalVisit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalVisit value)  $default,){
final _that = this;
switch (_that) {
case _MedicalVisit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalVisit value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalVisit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MedicalStageId stageId,  DateTime? appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  Map<VaccineCode, GivenVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalVisit() when $default != null:
return $default(_that.stageId,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MedicalStageId stageId,  DateTime? appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  Map<VaccineCode, GivenVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)  $default,) {final _that = this;
switch (_that) {
case _MedicalVisit():
return $default(_that.stageId,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MedicalStageId stageId,  DateTime? appointmentAt,  String? practitioner,  DateTime? doneAt,  String? note,  Map<VaccineCode, GivenVaccine> vaccines,  DateTime updatedAt,  String updatedByDeviceId)?  $default,) {final _that = this;
switch (_that) {
case _MedicalVisit() when $default != null:
return $default(_that.stageId,_that.appointmentAt,_that.practitioner,_that.doneAt,_that.note,_that.vaccines,_that.updatedAt,_that.updatedByDeviceId);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalVisit extends MedicalVisit {
  const _MedicalVisit({required this.stageId, this.appointmentAt, this.practitioner, this.doneAt, this.note,  Map<VaccineCode, GivenVaccine> vaccines = const <VaccineCode, GivenVaccine>{}, required this.updatedAt, required this.updatedByDeviceId}): _vaccines = vaccines,super._();
  

@override final  MedicalStageId stageId;
@override final  DateTime? appointmentAt;
@override final  String? practitioner;
@override final  DateTime? doneAt;
@override final  String? note;
 final  Map<VaccineCode, GivenVaccine> _vaccines;
@override@JsonKey() Map<VaccineCode, GivenVaccine> get vaccines {
  if (_vaccines is EqualUnmodifiableMapView) return _vaccines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_vaccines);
}

@override final  DateTime updatedAt;
@override final  String updatedByDeviceId;

/// Create a copy of MedicalVisit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalVisitCopyWith<_MedicalVisit> get copyWith => __$MedicalVisitCopyWithImpl<_MedicalVisit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalVisit&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.appointmentAt, appointmentAt) || other.appointmentAt == appointmentAt)&&(identical(other.practitioner, practitioner) || other.practitioner == practitioner)&&(identical(other.doneAt, doneAt) || other.doneAt == doneAt)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.vaccines, _vaccines)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedByDeviceId, updatedByDeviceId) || other.updatedByDeviceId == updatedByDeviceId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stageId,appointmentAt,practitioner,doneAt,note,const DeepCollectionEquality().hash(_vaccines),updatedAt,updatedByDeviceId);
}

@override
String toString() {
    return 'MedicalVisit(stageId: $stageId, appointmentAt: $appointmentAt, practitioner: $practitioner, doneAt: $doneAt, note: $note, vaccines: $vaccines, updatedAt: $updatedAt, updatedByDeviceId: $updatedByDeviceId)';
}


}

/// @nodoc
abstract mixin class _$MedicalVisitCopyWith<$Res> implements $MedicalVisitCopyWith<$Res> {
  factory _$MedicalVisitCopyWith(_MedicalVisit value, $Res Function(_MedicalVisit) _then) = __$MedicalVisitCopyWithImpl;
@override @useResult
$Res call({
 MedicalStageId stageId, DateTime? appointmentAt, String? practitioner, DateTime? doneAt, String? note, Map<VaccineCode, GivenVaccine> vaccines, DateTime updatedAt, String updatedByDeviceId
});




}
/// @nodoc
class __$MedicalVisitCopyWithImpl<$Res>
    implements _$MedicalVisitCopyWith<$Res> {
  __$MedicalVisitCopyWithImpl(this._self, this._then);

  final _MedicalVisit _self;
  final $Res Function(_MedicalVisit) _then;

/// Create a copy of MedicalVisit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stageId = null,Object? appointmentAt = freezed,Object? practitioner = freezed,Object? doneAt = freezed,Object? note = freezed,Object? vaccines = null,Object? updatedAt = null,Object? updatedByDeviceId = null,}) {
  return _then(_MedicalVisit(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as MedicalStageId,appointmentAt: freezed == appointmentAt ? _self.appointmentAt : appointmentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,practitioner: freezed == practitioner ? _self.practitioner : practitioner // ignore: cast_nullable_to_non_nullable
as String?,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,vaccines: null == vaccines ? _self._vaccines : vaccines // ignore: cast_nullable_to_non_nullable
as Map<VaccineCode, GivenVaccine>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedByDeviceId: null == updatedByDeviceId ? _self.updatedByDeviceId : updatedByDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
