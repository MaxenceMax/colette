// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_timeline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicalTimelineEntry {

 MedicalStage get stage; DateTime get dueFrom; DateTime get dueUntil; MedicalStageStatus get status; MedicalVisit? get visit;
/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalTimelineEntryCopyWith<MedicalTimelineEntry> get copyWith => _$MedicalTimelineEntryCopyWithImpl<MedicalTimelineEntry>(this as MedicalTimelineEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MedicalTimelineEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalTimelineEntry&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&(identical(other.dueFrom, _this.dueFrom) || other.dueFrom == _this.dueFrom)&&(identical(other.dueUntil, _this.dueUntil) || other.dueUntil == _this.dueUntil)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.visit, _this.visit) || other.visit == _this.visit));
}


@override
int get hashCode {
  final _this = this as MedicalTimelineEntry;
  return Object.hash(runtimeType,_this.stage,_this.dueFrom,_this.dueUntil,_this.status,_this.visit);
}

@override
String toString() {
  final _this = this as MedicalTimelineEntry;
  return 'MedicalTimelineEntry(stage: ${_this.stage}, dueFrom: ${_this.dueFrom}, dueUntil: ${_this.dueUntil}, status: ${_this.status}, visit: ${_this.visit})';
}


}

/// @nodoc
abstract mixin class $MedicalTimelineEntryCopyWith<$Res>  {
  factory $MedicalTimelineEntryCopyWith(MedicalTimelineEntry value, $Res Function(MedicalTimelineEntry) _then) = _$MedicalTimelineEntryCopyWithImpl;
@useResult
$Res call({
 MedicalStage stage, DateTime dueFrom, DateTime dueUntil, MedicalStageStatus status, MedicalVisit? visit
});


$MedicalVisitCopyWith<$Res>? get visit;

}
/// @nodoc
class _$MedicalTimelineEntryCopyWithImpl<$Res>
    implements $MedicalTimelineEntryCopyWith<$Res> {
  _$MedicalTimelineEntryCopyWithImpl(this._self, this._then);

  final MedicalTimelineEntry _self;
  final $Res Function(MedicalTimelineEntry) _then;

/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? dueFrom = null,Object? dueUntil = null,Object? status = null,Object? visit = freezed,}) {
  return _then(MedicalTimelineEntry(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as MedicalStage,dueFrom: null == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dueUntil: null == dueUntil ? _self.dueUntil : dueUntil // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MedicalStageStatus,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as MedicalVisit?,
  ));
}
/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicalVisitCopyWith<$Res>? get visit {
    if (_self.visit == null) {
    return null;
  }

  return $MedicalVisitCopyWith<$Res>(_self.visit!, (value) {
    return _then(_self.copyWith(visit: value));
  });
}
}


/// Adds pattern-matching-related methods to [MedicalTimelineEntry].
extension MedicalTimelineEntryPatterns on MedicalTimelineEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalTimelineEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalTimelineEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalTimelineEntry value)  $default,){
final _that = this;
switch (_that) {
case _MedicalTimelineEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalTimelineEntry value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalTimelineEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MedicalStage stage,  DateTime dueFrom,  DateTime dueUntil,  MedicalStageStatus status,  MedicalVisit? visit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalTimelineEntry() when $default != null:
return $default(_that.stage,_that.dueFrom,_that.dueUntil,_that.status,_that.visit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MedicalStage stage,  DateTime dueFrom,  DateTime dueUntil,  MedicalStageStatus status,  MedicalVisit? visit)  $default,) {final _that = this;
switch (_that) {
case _MedicalTimelineEntry():
return $default(_that.stage,_that.dueFrom,_that.dueUntil,_that.status,_that.visit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MedicalStage stage,  DateTime dueFrom,  DateTime dueUntil,  MedicalStageStatus status,  MedicalVisit? visit)?  $default,) {final _that = this;
switch (_that) {
case _MedicalTimelineEntry() when $default != null:
return $default(_that.stage,_that.dueFrom,_that.dueUntil,_that.status,_that.visit);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalTimelineEntry extends MedicalTimelineEntry {
  const _MedicalTimelineEntry({required this.stage, required this.dueFrom, required this.dueUntil, required this.status, this.visit}): super._();
  

@override final  MedicalStage stage;
@override final  DateTime dueFrom;
@override final  DateTime dueUntil;
@override final  MedicalStageStatus status;
@override final  MedicalVisit? visit;

/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalTimelineEntryCopyWith<_MedicalTimelineEntry> get copyWith => __$MedicalTimelineEntryCopyWithImpl<_MedicalTimelineEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalTimelineEntry&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.dueFrom, dueFrom) || other.dueFrom == dueFrom)&&(identical(other.dueUntil, dueUntil) || other.dueUntil == dueUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.visit, visit) || other.visit == visit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stage,dueFrom,dueUntil,status,visit);
}

@override
String toString() {
    return 'MedicalTimelineEntry(stage: $stage, dueFrom: $dueFrom, dueUntil: $dueUntil, status: $status, visit: $visit)';
}


}

/// @nodoc
abstract mixin class _$MedicalTimelineEntryCopyWith<$Res> implements $MedicalTimelineEntryCopyWith<$Res> {
  factory _$MedicalTimelineEntryCopyWith(_MedicalTimelineEntry value, $Res Function(_MedicalTimelineEntry) _then) = __$MedicalTimelineEntryCopyWithImpl;
@override @useResult
$Res call({
 MedicalStage stage, DateTime dueFrom, DateTime dueUntil, MedicalStageStatus status, MedicalVisit? visit
});


@override $MedicalVisitCopyWith<$Res>? get visit;

}
/// @nodoc
class __$MedicalTimelineEntryCopyWithImpl<$Res>
    implements _$MedicalTimelineEntryCopyWith<$Res> {
  __$MedicalTimelineEntryCopyWithImpl(this._self, this._then);

  final _MedicalTimelineEntry _self;
  final $Res Function(_MedicalTimelineEntry) _then;

/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? dueFrom = null,Object? dueUntil = null,Object? status = null,Object? visit = freezed,}) {
  return _then(_MedicalTimelineEntry(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as MedicalStage,dueFrom: null == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dueUntil: null == dueUntil ? _self.dueUntil : dueUntil // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MedicalStageStatus,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as MedicalVisit?,
  ));
}

/// Create a copy of MedicalTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicalVisitCopyWith<$Res>? get visit {
    if (_self.visit == null) {
    return null;
  }

  return $MedicalVisitCopyWith<$Res>(_self.visit!, (value) {
    return _then(_self.copyWith(visit: value));
  });
}
}

/// @nodoc
mixin _$MedicalTimelineItem {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalTimelineItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'MedicalTimelineItem()';
}


}

/// @nodoc
class $MedicalTimelineItemCopyWith<$Res>  {
$MedicalTimelineItemCopyWith(MedicalTimelineItem _, $Res Function(MedicalTimelineItem) __);
}


/// Adds pattern-matching-related methods to [MedicalTimelineItem].
extension MedicalTimelineItemPatterns on MedicalTimelineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StageItem value)?  stage,TResult Function( AppointmentItem value)?  appointment,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StageItem() when stage != null:
return stage(_that);case AppointmentItem() when appointment != null:
return appointment(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StageItem value)  stage,required TResult Function( AppointmentItem value)  appointment,}){
final _that = this;
switch (_that) {
case StageItem():
return stage(_that);case AppointmentItem():
return appointment(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StageItem value)?  stage,TResult? Function( AppointmentItem value)?  appointment,}){
final _that = this;
switch (_that) {
case StageItem() when stage != null:
return stage(_that);case AppointmentItem() when appointment != null:
return appointment(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( MedicalTimelineEntry entry)?  stage,TResult Function( CustomAppointment appointment,  MedicalStageStatus status)?  appointment,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StageItem() when stage != null:
return stage(_that.entry);case AppointmentItem() when appointment != null:
return appointment(_that.appointment,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( MedicalTimelineEntry entry)  stage,required TResult Function( CustomAppointment appointment,  MedicalStageStatus status)  appointment,}) {final _that = this;
switch (_that) {
case StageItem():
return stage(_that.entry);case AppointmentItem():
return appointment(_that.appointment,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( MedicalTimelineEntry entry)?  stage,TResult? Function( CustomAppointment appointment,  MedicalStageStatus status)?  appointment,}) {final _that = this;
switch (_that) {
case StageItem() when stage != null:
return stage(_that.entry);case AppointmentItem() when appointment != null:
return appointment(_that.appointment,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class StageItem extends MedicalTimelineItem {
  const StageItem(this.entry): super._();
  

 final  MedicalTimelineEntry entry;

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageItemCopyWith<StageItem> get copyWith => _$StageItemCopyWithImpl<StageItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StageItem&&(identical(other.entry, entry) || other.entry == entry));
}


@override
int get hashCode {
    return Object.hash(runtimeType,entry);
}

@override
String toString() {
    return 'MedicalTimelineItem.stage(entry: $entry)';
}


}

/// @nodoc
abstract mixin class $StageItemCopyWith<$Res> implements $MedicalTimelineItemCopyWith<$Res> {
  factory $StageItemCopyWith(StageItem value, $Res Function(StageItem) _then) = _$StageItemCopyWithImpl;
@useResult
$Res call({
 MedicalTimelineEntry entry
});


$MedicalTimelineEntryCopyWith<$Res> get entry;

}
/// @nodoc
class _$StageItemCopyWithImpl<$Res>
    implements $StageItemCopyWith<$Res> {
  _$StageItemCopyWithImpl(this._self, this._then);

  final StageItem _self;
  final $Res Function(StageItem) _then;

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = null,}) {
  return _then(StageItem(
null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as MedicalTimelineEntry,
  ));
}

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicalTimelineEntryCopyWith<$Res> get entry {
  
  return $MedicalTimelineEntryCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}

/// @nodoc


class AppointmentItem extends MedicalTimelineItem {
  const AppointmentItem(this.appointment, this.status): super._();
  

 final  CustomAppointment appointment;
 final  MedicalStageStatus status;

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentItemCopyWith<AppointmentItem> get copyWith => _$AppointmentItemCopyWithImpl<AppointmentItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppointmentItem&&(identical(other.appointment, appointment) || other.appointment == appointment)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode {
    return Object.hash(runtimeType,appointment,status);
}

@override
String toString() {
    return 'MedicalTimelineItem.appointment(appointment: $appointment, status: $status)';
}


}

/// @nodoc
abstract mixin class $AppointmentItemCopyWith<$Res> implements $MedicalTimelineItemCopyWith<$Res> {
  factory $AppointmentItemCopyWith(AppointmentItem value, $Res Function(AppointmentItem) _then) = _$AppointmentItemCopyWithImpl;
@useResult
$Res call({
 CustomAppointment appointment, MedicalStageStatus status
});


$CustomAppointmentCopyWith<$Res> get appointment;

}
/// @nodoc
class _$AppointmentItemCopyWithImpl<$Res>
    implements $AppointmentItemCopyWith<$Res> {
  _$AppointmentItemCopyWithImpl(this._self, this._then);

  final AppointmentItem _self;
  final $Res Function(AppointmentItem) _then;

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? appointment = null,Object? status = null,}) {
  return _then(AppointmentItem(
null == appointment ? _self.appointment : appointment // ignore: cast_nullable_to_non_nullable
as CustomAppointment,null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MedicalStageStatus,
  ));
}

/// Create a copy of MedicalTimelineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomAppointmentCopyWith<$Res> get appointment {
  
  return $CustomAppointmentCopyWith<$Res>(_self.appointment, (value) {
    return _then(_self.copyWith(appointment: value));
  });
}
}

/// @nodoc
mixin _$MedicalTimeline {

 List<MedicalTimelineEntry> get entries; List<AppointmentItem> get appointments;
/// Create a copy of MedicalTimeline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalTimelineCopyWith<MedicalTimeline> get copyWith => _$MedicalTimelineCopyWithImpl<MedicalTimeline>(this as MedicalTimeline, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MedicalTimeline;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalTimeline&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.appointments, _this.appointments));
}


@override
int get hashCode {
  final _this = this as MedicalTimeline;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.appointments));
}

@override
String toString() {
  final _this = this as MedicalTimeline;
  return 'MedicalTimeline(entries: ${_this.entries}, appointments: ${_this.appointments})';
}


}

/// @nodoc
abstract mixin class $MedicalTimelineCopyWith<$Res>  {
  factory $MedicalTimelineCopyWith(MedicalTimeline value, $Res Function(MedicalTimeline) _then) = _$MedicalTimelineCopyWithImpl;
@useResult
$Res call({
 List<MedicalTimelineEntry> entries, List<AppointmentItem> appointments
});




}
/// @nodoc
class _$MedicalTimelineCopyWithImpl<$Res>
    implements $MedicalTimelineCopyWith<$Res> {
  _$MedicalTimelineCopyWithImpl(this._self, this._then);

  final MedicalTimeline _self;
  final $Res Function(MedicalTimeline) _then;

/// Create a copy of MedicalTimeline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? appointments = null,}) {
  return _then(MedicalTimeline(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<MedicalTimelineEntry>,appointments: null == appointments ? _self.appointments : appointments // ignore: cast_nullable_to_non_nullable
as List<AppointmentItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalTimeline].
extension MedicalTimelinePatterns on MedicalTimeline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalTimeline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalTimeline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalTimeline value)  $default,){
final _that = this;
switch (_that) {
case _MedicalTimeline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalTimeline value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalTimeline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MedicalTimelineEntry> entries,  List<AppointmentItem> appointments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalTimeline() when $default != null:
return $default(_that.entries,_that.appointments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MedicalTimelineEntry> entries,  List<AppointmentItem> appointments)  $default,) {final _that = this;
switch (_that) {
case _MedicalTimeline():
return $default(_that.entries,_that.appointments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MedicalTimelineEntry> entries,  List<AppointmentItem> appointments)?  $default,) {final _that = this;
switch (_that) {
case _MedicalTimeline() when $default != null:
return $default(_that.entries,_that.appointments);case _:
  return null;

}
}

}

/// @nodoc


class _MedicalTimeline extends MedicalTimeline {
  const _MedicalTimeline({required  List<MedicalTimelineEntry> entries,  List<AppointmentItem> appointments = const <AppointmentItem>[]}): _entries = entries,_appointments = appointments,super._();
  

 final  List<MedicalTimelineEntry> _entries;
@override List<MedicalTimelineEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<AppointmentItem> _appointments;
@override@JsonKey() List<AppointmentItem> get appointments {
  if (_appointments is EqualUnmodifiableListView) return _appointments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appointments);
}


/// Create a copy of MedicalTimeline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalTimelineCopyWith<_MedicalTimeline> get copyWith => __$MedicalTimelineCopyWithImpl<_MedicalTimeline>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalTimeline&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.appointments, _appointments));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_appointments));
}

@override
String toString() {
    return 'MedicalTimeline(entries: $entries, appointments: $appointments)';
}


}

/// @nodoc
abstract mixin class _$MedicalTimelineCopyWith<$Res> implements $MedicalTimelineCopyWith<$Res> {
  factory _$MedicalTimelineCopyWith(_MedicalTimeline value, $Res Function(_MedicalTimeline) _then) = __$MedicalTimelineCopyWithImpl;
@override @useResult
$Res call({
 List<MedicalTimelineEntry> entries, List<AppointmentItem> appointments
});




}
/// @nodoc
class __$MedicalTimelineCopyWithImpl<$Res>
    implements _$MedicalTimelineCopyWith<$Res> {
  __$MedicalTimelineCopyWithImpl(this._self, this._then);

  final _MedicalTimeline _self;
  final $Res Function(_MedicalTimeline) _then;

/// Create a copy of MedicalTimeline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? appointments = null,}) {
  return _then(_MedicalTimeline(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<MedicalTimelineEntry>,appointments: null == appointments ? _self._appointments : appointments // ignore: cast_nullable_to_non_nullable
as List<AppointmentItem>,
  ));
}


}

// dart format on
