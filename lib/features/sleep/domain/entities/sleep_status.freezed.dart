// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SleepStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SleepStatus()';
}


}

/// @nodoc
class $SleepStatusCopyWith<$Res>  {
$SleepStatusCopyWith(SleepStatus _, $Res Function(SleepStatus) __);
}


/// Adds pattern-matching-related methods to [SleepStatus].
extension SleepStatusPatterns on SleepStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Asleep value)?  asleep,TResult Function( Awake value)?  awake,TResult Function( ForgottenWake value)?  forgottenWake,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Asleep() when asleep != null:
return asleep(_that);case Awake() when awake != null:
return awake(_that);case ForgottenWake() when forgottenWake != null:
return forgottenWake(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Asleep value)  asleep,required TResult Function( Awake value)  awake,required TResult Function( ForgottenWake value)  forgottenWake,}){
final _that = this;
switch (_that) {
case Asleep():
return asleep(_that);case Awake():
return awake(_that);case ForgottenWake():
return forgottenWake(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Asleep value)?  asleep,TResult? Function( Awake value)?  awake,TResult? Function( ForgottenWake value)?  forgottenWake,}){
final _that = this;
switch (_that) {
case Asleep() when asleep != null:
return asleep(_that);case Awake() when awake != null:
return awake(_that);case ForgottenWake() when forgottenWake != null:
return forgottenWake(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SleepSession session)?  asleep,TResult Function( DateTime? since)?  awake,TResult Function( SleepSession session)?  forgottenWake,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Asleep() when asleep != null:
return asleep(_that.session);case Awake() when awake != null:
return awake(_that.since);case ForgottenWake() when forgottenWake != null:
return forgottenWake(_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SleepSession session)  asleep,required TResult Function( DateTime? since)  awake,required TResult Function( SleepSession session)  forgottenWake,}) {final _that = this;
switch (_that) {
case Asleep():
return asleep(_that.session);case Awake():
return awake(_that.since);case ForgottenWake():
return forgottenWake(_that.session);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SleepSession session)?  asleep,TResult? Function( DateTime? since)?  awake,TResult? Function( SleepSession session)?  forgottenWake,}) {final _that = this;
switch (_that) {
case Asleep() when asleep != null:
return asleep(_that.session);case Awake() when awake != null:
return awake(_that.since);case ForgottenWake() when forgottenWake != null:
return forgottenWake(_that.session);case _:
  return null;

}
}

}

/// @nodoc


class Asleep implements SleepStatus {
  const Asleep(this.session);
  

 final  SleepSession session;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsleepCopyWith<Asleep> get copyWith => _$AsleepCopyWithImpl<Asleep>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Asleep&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode {
    return Object.hash(runtimeType,session);
}

@override
String toString() {
    return 'SleepStatus.asleep(session: $session)';
}


}

/// @nodoc
abstract mixin class $AsleepCopyWith<$Res> implements $SleepStatusCopyWith<$Res> {
  factory $AsleepCopyWith(Asleep value, $Res Function(Asleep) _then) = _$AsleepCopyWithImpl;
@useResult
$Res call({
 SleepSession session
});


$SleepSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$AsleepCopyWithImpl<$Res>
    implements $AsleepCopyWith<$Res> {
  _$AsleepCopyWithImpl(this._self, this._then);

  final Asleep _self;
  final $Res Function(Asleep) _then;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(Asleep(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SleepSession,
  ));
}

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SleepSessionCopyWith<$Res> get session {
  
  return $SleepSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class Awake implements SleepStatus {
  const Awake({this.since});
  

 final  DateTime? since;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AwakeCopyWith<Awake> get copyWith => _$AwakeCopyWithImpl<Awake>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Awake&&(identical(other.since, since) || other.since == since));
}


@override
int get hashCode {
    return Object.hash(runtimeType,since);
}

@override
String toString() {
    return 'SleepStatus.awake(since: $since)';
}


}

/// @nodoc
abstract mixin class $AwakeCopyWith<$Res> implements $SleepStatusCopyWith<$Res> {
  factory $AwakeCopyWith(Awake value, $Res Function(Awake) _then) = _$AwakeCopyWithImpl;
@useResult
$Res call({
 DateTime? since
});




}
/// @nodoc
class _$AwakeCopyWithImpl<$Res>
    implements $AwakeCopyWith<$Res> {
  _$AwakeCopyWithImpl(this._self, this._then);

  final Awake _self;
  final $Res Function(Awake) _then;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? since = freezed,}) {
  return _then(Awake(
since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class ForgottenWake implements SleepStatus {
  const ForgottenWake(this.session);
  

 final  SleepSession session;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgottenWakeCopyWith<ForgottenWake> get copyWith => _$ForgottenWakeCopyWithImpl<ForgottenWake>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgottenWake&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode {
    return Object.hash(runtimeType,session);
}

@override
String toString() {
    return 'SleepStatus.forgottenWake(session: $session)';
}


}

/// @nodoc
abstract mixin class $ForgottenWakeCopyWith<$Res> implements $SleepStatusCopyWith<$Res> {
  factory $ForgottenWakeCopyWith(ForgottenWake value, $Res Function(ForgottenWake) _then) = _$ForgottenWakeCopyWithImpl;
@useResult
$Res call({
 SleepSession session
});


$SleepSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$ForgottenWakeCopyWithImpl<$Res>
    implements $ForgottenWakeCopyWith<$Res> {
  _$ForgottenWakeCopyWithImpl(this._self, this._then);

  final ForgottenWake _self;
  final $Res Function(ForgottenWake) _then;

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(ForgottenWake(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SleepSession,
  ));
}

/// Create a copy of SleepStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SleepSessionCopyWith<$Res> get session {
  
  return $SleepSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc
mixin _$SleepSummary {

 SleepStatus get status; Duration get last24h;
/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SleepSummaryCopyWith<SleepSummary> get copyWith => _$SleepSummaryCopyWithImpl<SleepSummary>(this as SleepSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SleepSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepSummary&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.last24h, _this.last24h) || other.last24h == _this.last24h));
}


@override
int get hashCode {
  final _this = this as SleepSummary;
  return Object.hash(runtimeType,_this.status,_this.last24h);
}

@override
String toString() {
  final _this = this as SleepSummary;
  return 'SleepSummary(status: ${_this.status}, last24h: ${_this.last24h})';
}


}

/// @nodoc
abstract mixin class $SleepSummaryCopyWith<$Res>  {
  factory $SleepSummaryCopyWith(SleepSummary value, $Res Function(SleepSummary) _then) = _$SleepSummaryCopyWithImpl;
@useResult
$Res call({
 SleepStatus status, Duration last24h
});


$SleepStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$SleepSummaryCopyWithImpl<$Res>
    implements $SleepSummaryCopyWith<$Res> {
  _$SleepSummaryCopyWithImpl(this._self, this._then);

  final SleepSummary _self;
  final $Res Function(SleepSummary) _then;

/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? last24h = null,}) {
  return _then(SleepSummary(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SleepStatus,last24h: null == last24h ? _self.last24h : last24h // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}
/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SleepStatusCopyWith<$Res> get status {
  
  return $SleepStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}


/// Adds pattern-matching-related methods to [SleepSummary].
extension SleepSummaryPatterns on SleepSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SleepSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SleepSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SleepSummary value)  $default,){
final _that = this;
switch (_that) {
case _SleepSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SleepSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SleepSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SleepStatus status,  Duration last24h)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SleepSummary() when $default != null:
return $default(_that.status,_that.last24h);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SleepStatus status,  Duration last24h)  $default,) {final _that = this;
switch (_that) {
case _SleepSummary():
return $default(_that.status,_that.last24h);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SleepStatus status,  Duration last24h)?  $default,) {final _that = this;
switch (_that) {
case _SleepSummary() when $default != null:
return $default(_that.status,_that.last24h);case _:
  return null;

}
}

}

/// @nodoc


class _SleepSummary implements SleepSummary {
  const _SleepSummary({required this.status, required this.last24h});
  

@override final  SleepStatus status;
@override final  Duration last24h;

/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SleepSummaryCopyWith<_SleepSummary> get copyWith => __$SleepSummaryCopyWithImpl<_SleepSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SleepSummary&&(identical(other.status, status) || other.status == status)&&(identical(other.last24h, last24h) || other.last24h == last24h));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,last24h);
}

@override
String toString() {
    return 'SleepSummary(status: $status, last24h: $last24h)';
}


}

/// @nodoc
abstract mixin class _$SleepSummaryCopyWith<$Res> implements $SleepSummaryCopyWith<$Res> {
  factory _$SleepSummaryCopyWith(_SleepSummary value, $Res Function(_SleepSummary) _then) = __$SleepSummaryCopyWithImpl;
@override @useResult
$Res call({
 SleepStatus status, Duration last24h
});


@override $SleepStatusCopyWith<$Res> get status;

}
/// @nodoc
class __$SleepSummaryCopyWithImpl<$Res>
    implements _$SleepSummaryCopyWith<$Res> {
  __$SleepSummaryCopyWithImpl(this._self, this._then);

  final _SleepSummary _self;
  final $Res Function(_SleepSummary) _then;

/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? last24h = null,}) {
  return _then(_SleepSummary(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SleepStatus,last24h: null == last24h ? _self.last24h : last24h // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

/// Create a copy of SleepSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SleepStatusCopyWith<$Res> get status {
  
  return $SleepStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

// dart format on
