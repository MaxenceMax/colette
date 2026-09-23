// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CalendarAction {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CalendarAction()';
}


}

/// @nodoc
class $CalendarActionCopyWith<$Res>  {
$CalendarActionCopyWith(CalendarAction _, $Res Function(CalendarAction) __);
}


/// Adds pattern-matching-related methods to [CalendarAction].
extension CalendarActionPatterns on CalendarAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateCalendarEvent value)?  create,TResult Function( UpdateCalendarEvent value)?  update,TResult Function( DeleteCalendarEvent value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateCalendarEvent() when create != null:
return create(_that);case UpdateCalendarEvent() when update != null:
return update(_that);case DeleteCalendarEvent() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateCalendarEvent value)  create,required TResult Function( UpdateCalendarEvent value)  update,required TResult Function( DeleteCalendarEvent value)  delete,}){
final _that = this;
switch (_that) {
case CreateCalendarEvent():
return create(_that);case UpdateCalendarEvent():
return update(_that);case DeleteCalendarEvent():
return delete(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateCalendarEvent value)?  create,TResult? Function( UpdateCalendarEvent value)?  update,TResult? Function( DeleteCalendarEvent value)?  delete,}){
final _that = this;
switch (_that) {
case CreateCalendarEvent() when create != null:
return create(_that);case UpdateCalendarEvent() when update != null:
return update(_that);case DeleteCalendarEvent() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CalendarEventDraft draft)?  create,TResult Function( String eventId,  CalendarEventDraft draft)?  update,TResult Function( String eventId)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateCalendarEvent() when create != null:
return create(_that.draft);case UpdateCalendarEvent() when update != null:
return update(_that.eventId,_that.draft);case DeleteCalendarEvent() when delete != null:
return delete(_that.eventId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CalendarEventDraft draft)  create,required TResult Function( String eventId,  CalendarEventDraft draft)  update,required TResult Function( String eventId)  delete,}) {final _that = this;
switch (_that) {
case CreateCalendarEvent():
return create(_that.draft);case UpdateCalendarEvent():
return update(_that.eventId,_that.draft);case DeleteCalendarEvent():
return delete(_that.eventId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CalendarEventDraft draft)?  create,TResult? Function( String eventId,  CalendarEventDraft draft)?  update,TResult? Function( String eventId)?  delete,}) {final _that = this;
switch (_that) {
case CreateCalendarEvent() when create != null:
return create(_that.draft);case UpdateCalendarEvent() when update != null:
return update(_that.eventId,_that.draft);case DeleteCalendarEvent() when delete != null:
return delete(_that.eventId);case _:
  return null;

}
}

}

/// @nodoc


class CreateCalendarEvent implements CalendarAction {
  const CreateCalendarEvent(this.draft);
  

 final  CalendarEventDraft draft;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCalendarEventCopyWith<CreateCalendarEvent> get copyWith => _$CreateCalendarEventCopyWithImpl<CreateCalendarEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateCalendarEvent&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode {
    return Object.hash(runtimeType,draft);
}

@override
String toString() {
    return 'CalendarAction.create(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $CreateCalendarEventCopyWith<$Res> implements $CalendarActionCopyWith<$Res> {
  factory $CreateCalendarEventCopyWith(CreateCalendarEvent value, $Res Function(CreateCalendarEvent) _then) = _$CreateCalendarEventCopyWithImpl;
@useResult
$Res call({
 CalendarEventDraft draft
});


$CalendarEventDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$CreateCalendarEventCopyWithImpl<$Res>
    implements $CreateCalendarEventCopyWith<$Res> {
  _$CreateCalendarEventCopyWithImpl(this._self, this._then);

  final CreateCalendarEvent _self;
  final $Res Function(CreateCalendarEvent) _then;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(CreateCalendarEvent(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as CalendarEventDraft,
  ));
}

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventDraftCopyWith<$Res> get draft {
  
  return $CalendarEventDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class UpdateCalendarEvent implements CalendarAction {
  const UpdateCalendarEvent(this.eventId, this.draft);
  

 final  String eventId;
 final  CalendarEventDraft draft;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCalendarEventCopyWith<UpdateCalendarEvent> get copyWith => _$UpdateCalendarEventCopyWithImpl<UpdateCalendarEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCalendarEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode {
    return Object.hash(runtimeType,eventId,draft);
}

@override
String toString() {
    return 'CalendarAction.update(eventId: $eventId, draft: $draft)';
}


}

/// @nodoc
abstract mixin class $UpdateCalendarEventCopyWith<$Res> implements $CalendarActionCopyWith<$Res> {
  factory $UpdateCalendarEventCopyWith(UpdateCalendarEvent value, $Res Function(UpdateCalendarEvent) _then) = _$UpdateCalendarEventCopyWithImpl;
@useResult
$Res call({
 String eventId, CalendarEventDraft draft
});


$CalendarEventDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$UpdateCalendarEventCopyWithImpl<$Res>
    implements $UpdateCalendarEventCopyWith<$Res> {
  _$UpdateCalendarEventCopyWithImpl(this._self, this._then);

  final UpdateCalendarEvent _self;
  final $Res Function(UpdateCalendarEvent) _then;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? draft = null,}) {
  return _then(UpdateCalendarEvent(
null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as CalendarEventDraft,
  ));
}

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventDraftCopyWith<$Res> get draft {
  
  return $CalendarEventDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class DeleteCalendarEvent implements CalendarAction {
  const DeleteCalendarEvent(this.eventId);
  

 final  String eventId;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteCalendarEventCopyWith<DeleteCalendarEvent> get copyWith => _$DeleteCalendarEventCopyWithImpl<DeleteCalendarEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteCalendarEvent&&(identical(other.eventId, eventId) || other.eventId == eventId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,eventId);
}

@override
String toString() {
    return 'CalendarAction.delete(eventId: $eventId)';
}


}

/// @nodoc
abstract mixin class $DeleteCalendarEventCopyWith<$Res> implements $CalendarActionCopyWith<$Res> {
  factory $DeleteCalendarEventCopyWith(DeleteCalendarEvent value, $Res Function(DeleteCalendarEvent) _then) = _$DeleteCalendarEventCopyWithImpl;
@useResult
$Res call({
 String eventId
});




}
/// @nodoc
class _$DeleteCalendarEventCopyWithImpl<$Res>
    implements $DeleteCalendarEventCopyWith<$Res> {
  _$DeleteCalendarEventCopyWithImpl(this._self, this._then);

  final DeleteCalendarEvent _self;
  final $Res Function(DeleteCalendarEvent) _then;

/// Create a copy of CalendarAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? eventId = null,}) {
  return _then(DeleteCalendarEvent(
null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
