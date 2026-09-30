// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'send_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SendReport {

 int get sent; int get cancelled; int get failed;
/// Create a copy of SendReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendReportCopyWith<SendReport> get copyWith => _$SendReportCopyWithImpl<SendReport>(this as SendReport, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SendReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendReport&&(identical(other.sent, _this.sent) || other.sent == _this.sent)&&(identical(other.cancelled, _this.cancelled) || other.cancelled == _this.cancelled)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as SendReport;
  return Object.hash(runtimeType,_this.sent,_this.cancelled,_this.failed);
}

@override
String toString() {
  final _this = this as SendReport;
  return 'SendReport(sent: ${_this.sent}, cancelled: ${_this.cancelled}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $SendReportCopyWith<$Res>  {
  factory $SendReportCopyWith(SendReport value, $Res Function(SendReport) _then) = _$SendReportCopyWithImpl;
@useResult
$Res call({
 int sent, int cancelled, int failed
});




}
/// @nodoc
class _$SendReportCopyWithImpl<$Res>
    implements $SendReportCopyWith<$Res> {
  _$SendReportCopyWithImpl(this._self, this._then);

  final SendReport _self;
  final $Res Function(SendReport) _then;

/// Create a copy of SendReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sent = null,Object? cancelled = null,Object? failed = null,}) {
  return _then(SendReport(
sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SendReport].
extension SendReportPatterns on SendReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SendReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SendReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SendReport value)  $default,){
final _that = this;
switch (_that) {
case _SendReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SendReport value)?  $default,){
final _that = this;
switch (_that) {
case _SendReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sent,  int cancelled,  int failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SendReport() when $default != null:
return $default(_that.sent,_that.cancelled,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sent,  int cancelled,  int failed)  $default,) {final _that = this;
switch (_that) {
case _SendReport():
return $default(_that.sent,_that.cancelled,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sent,  int cancelled,  int failed)?  $default,) {final _that = this;
switch (_that) {
case _SendReport() when $default != null:
return $default(_that.sent,_that.cancelled,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _SendReport extends SendReport {
  const _SendReport({required this.sent, required this.cancelled, required this.failed}): super._();
  

@override final  int sent;
@override final  int cancelled;
@override final  int failed;

/// Create a copy of SendReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendReportCopyWith<_SendReport> get copyWith => __$SendReportCopyWithImpl<_SendReport>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendReport&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sent,cancelled,failed);
}

@override
String toString() {
    return 'SendReport(sent: $sent, cancelled: $cancelled, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$SendReportCopyWith<$Res> implements $SendReportCopyWith<$Res> {
  factory _$SendReportCopyWith(_SendReport value, $Res Function(_SendReport) _then) = __$SendReportCopyWithImpl;
@override @useResult
$Res call({
 int sent, int cancelled, int failed
});




}
/// @nodoc
class __$SendReportCopyWithImpl<$Res>
    implements _$SendReportCopyWith<$Res> {
  __$SendReportCopyWithImpl(this._self, this._then);

  final _SendReport _self;
  final $Res Function(_SendReport) _then;

/// Create a copy of SendReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sent = null,Object? cancelled = null,Object? failed = null,}) {
  return _then(_SendReport(
sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
