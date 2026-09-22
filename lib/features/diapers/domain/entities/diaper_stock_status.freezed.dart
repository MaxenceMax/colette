// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diaper_stock_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiaperStockStatus {

 int get remaining; bool get isLow;
/// Create a copy of DiaperStockStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaperStockStatusCopyWith<DiaperStockStatus> get copyWith => _$DiaperStockStatusCopyWithImpl<DiaperStockStatus>(this as DiaperStockStatus, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiaperStockStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaperStockStatus&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.isLow, _this.isLow) || other.isLow == _this.isLow));
}


@override
int get hashCode {
  final _this = this as DiaperStockStatus;
  return Object.hash(runtimeType,_this.remaining,_this.isLow);
}

@override
String toString() {
  final _this = this as DiaperStockStatus;
  return 'DiaperStockStatus(remaining: ${_this.remaining}, isLow: ${_this.isLow})';
}


}

/// @nodoc
abstract mixin class $DiaperStockStatusCopyWith<$Res>  {
  factory $DiaperStockStatusCopyWith(DiaperStockStatus value, $Res Function(DiaperStockStatus) _then) = _$DiaperStockStatusCopyWithImpl;
@useResult
$Res call({
 int remaining, bool isLow
});




}
/// @nodoc
class _$DiaperStockStatusCopyWithImpl<$Res>
    implements $DiaperStockStatusCopyWith<$Res> {
  _$DiaperStockStatusCopyWithImpl(this._self, this._then);

  final DiaperStockStatus _self;
  final $Res Function(DiaperStockStatus) _then;

/// Create a copy of DiaperStockStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? remaining = null,Object? isLow = null,}) {
  return _then(DiaperStockStatus(
remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,isLow: null == isLow ? _self.isLow : isLow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaperStockStatus].
extension DiaperStockStatusPatterns on DiaperStockStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaperStockStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaperStockStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaperStockStatus value)  $default,){
final _that = this;
switch (_that) {
case _DiaperStockStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaperStockStatus value)?  $default,){
final _that = this;
switch (_that) {
case _DiaperStockStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int remaining,  bool isLow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaperStockStatus() when $default != null:
return $default(_that.remaining,_that.isLow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int remaining,  bool isLow)  $default,) {final _that = this;
switch (_that) {
case _DiaperStockStatus():
return $default(_that.remaining,_that.isLow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int remaining,  bool isLow)?  $default,) {final _that = this;
switch (_that) {
case _DiaperStockStatus() when $default != null:
return $default(_that.remaining,_that.isLow);case _:
  return null;

}
}

}

/// @nodoc


class _DiaperStockStatus implements DiaperStockStatus {
  const _DiaperStockStatus({required this.remaining, required this.isLow});
  

@override final  int remaining;
@override final  bool isLow;

/// Create a copy of DiaperStockStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaperStockStatusCopyWith<_DiaperStockStatus> get copyWith => __$DiaperStockStatusCopyWithImpl<_DiaperStockStatus>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaperStockStatus&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.isLow, isLow) || other.isLow == isLow));
}


@override
int get hashCode {
    return Object.hash(runtimeType,remaining,isLow);
}

@override
String toString() {
    return 'DiaperStockStatus(remaining: $remaining, isLow: $isLow)';
}


}

/// @nodoc
abstract mixin class _$DiaperStockStatusCopyWith<$Res> implements $DiaperStockStatusCopyWith<$Res> {
  factory _$DiaperStockStatusCopyWith(_DiaperStockStatus value, $Res Function(_DiaperStockStatus) _then) = __$DiaperStockStatusCopyWithImpl;
@override @useResult
$Res call({
 int remaining, bool isLow
});




}
/// @nodoc
class __$DiaperStockStatusCopyWithImpl<$Res>
    implements _$DiaperStockStatusCopyWith<$Res> {
  __$DiaperStockStatusCopyWithImpl(this._self, this._then);

  final _DiaperStockStatus _self;
  final $Res Function(_DiaperStockStatus) _then;

/// Create a copy of DiaperStockStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? remaining = null,Object? isLow = null,}) {
  return _then(_DiaperStockStatus(
remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,isLow: null == isLow ? _self.isLow : isLow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
