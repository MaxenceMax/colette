// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bottle_timer_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BottleTimerSession {

 BottleTimerRun get run; CareEvent get draft;/// Minuteur lancé depuis l'édition d'un soin existant.
 bool get editing;
/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottleTimerSessionCopyWith<BottleTimerSession> get copyWith => _$BottleTimerSessionCopyWithImpl<BottleTimerSession>(this as BottleTimerSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BottleTimerSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottleTimerSession&&(identical(other.run, _this.run) || other.run == _this.run)&&(identical(other.draft, _this.draft) || other.draft == _this.draft)&&(identical(other.editing, _this.editing) || other.editing == _this.editing));
}


@override
int get hashCode {
  final _this = this as BottleTimerSession;
  return Object.hash(runtimeType,_this.run,_this.draft,_this.editing);
}

@override
String toString() {
  final _this = this as BottleTimerSession;
  return 'BottleTimerSession(run: ${_this.run}, draft: ${_this.draft}, editing: ${_this.editing})';
}


}

/// @nodoc
abstract mixin class $BottleTimerSessionCopyWith<$Res>  {
  factory $BottleTimerSessionCopyWith(BottleTimerSession value, $Res Function(BottleTimerSession) _then) = _$BottleTimerSessionCopyWithImpl;
@useResult
$Res call({
 BottleTimerRun run, CareEvent draft, bool editing
});


$BottleTimerRunCopyWith<$Res> get run;$CareEventCopyWith<$Res> get draft;

}
/// @nodoc
class _$BottleTimerSessionCopyWithImpl<$Res>
    implements $BottleTimerSessionCopyWith<$Res> {
  _$BottleTimerSessionCopyWithImpl(this._self, this._then);

  final BottleTimerSession _self;
  final $Res Function(BottleTimerSession) _then;

/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? run = null,Object? draft = null,Object? editing = null,}) {
  return _then(BottleTimerSession(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as BottleTimerRun,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as CareEvent,editing: null == editing ? _self.editing : editing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleTimerRunCopyWith<$Res> get run {
  
  return $BottleTimerRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareEventCopyWith<$Res> get draft {
  
  return $CareEventCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [BottleTimerSession].
extension BottleTimerSessionPatterns on BottleTimerSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BottleTimerSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BottleTimerSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BottleTimerSession value)  $default,){
final _that = this;
switch (_that) {
case _BottleTimerSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BottleTimerSession value)?  $default,){
final _that = this;
switch (_that) {
case _BottleTimerSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BottleTimerRun run,  CareEvent draft,  bool editing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BottleTimerSession() when $default != null:
return $default(_that.run,_that.draft,_that.editing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BottleTimerRun run,  CareEvent draft,  bool editing)  $default,) {final _that = this;
switch (_that) {
case _BottleTimerSession():
return $default(_that.run,_that.draft,_that.editing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BottleTimerRun run,  CareEvent draft,  bool editing)?  $default,) {final _that = this;
switch (_that) {
case _BottleTimerSession() when $default != null:
return $default(_that.run,_that.draft,_that.editing);case _:
  return null;

}
}

}

/// @nodoc


class _BottleTimerSession extends BottleTimerSession {
  const _BottleTimerSession({required this.run, required this.draft, required this.editing}): super._();
  

@override final  BottleTimerRun run;
@override final  CareEvent draft;
/// Minuteur lancé depuis l'édition d'un soin existant.
@override final  bool editing;

/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottleTimerSessionCopyWith<_BottleTimerSession> get copyWith => __$BottleTimerSessionCopyWithImpl<_BottleTimerSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottleTimerSession&&(identical(other.run, run) || other.run == run)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.editing, editing) || other.editing == editing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,run,draft,editing);
}

@override
String toString() {
    return 'BottleTimerSession(run: $run, draft: $draft, editing: $editing)';
}


}

/// @nodoc
abstract mixin class _$BottleTimerSessionCopyWith<$Res> implements $BottleTimerSessionCopyWith<$Res> {
  factory _$BottleTimerSessionCopyWith(_BottleTimerSession value, $Res Function(_BottleTimerSession) _then) = __$BottleTimerSessionCopyWithImpl;
@override @useResult
$Res call({
 BottleTimerRun run, CareEvent draft, bool editing
});


@override $BottleTimerRunCopyWith<$Res> get run;@override $CareEventCopyWith<$Res> get draft;

}
/// @nodoc
class __$BottleTimerSessionCopyWithImpl<$Res>
    implements _$BottleTimerSessionCopyWith<$Res> {
  __$BottleTimerSessionCopyWithImpl(this._self, this._then);

  final _BottleTimerSession _self;
  final $Res Function(_BottleTimerSession) _then;

/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? run = null,Object? draft = null,Object? editing = null,}) {
  return _then(_BottleTimerSession(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as BottleTimerRun,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as CareEvent,editing: null == editing ? _self.editing : editing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleTimerRunCopyWith<$Res> get run {
  
  return $BottleTimerRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}/// Create a copy of BottleTimerSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareEventCopyWith<$Res> get draft {
  
  return $CareEventCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

// dart format on
