// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diaper_stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiaperStock {

 int get count; DateTime get countedAt; int get alertThreshold; int get lastPackSize;
/// Create a copy of DiaperStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaperStockCopyWith<DiaperStock> get copyWith => _$DiaperStockCopyWithImpl<DiaperStock>(this as DiaperStock, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiaperStock;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaperStock&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.countedAt, _this.countedAt) || other.countedAt == _this.countedAt)&&(identical(other.alertThreshold, _this.alertThreshold) || other.alertThreshold == _this.alertThreshold)&&(identical(other.lastPackSize, _this.lastPackSize) || other.lastPackSize == _this.lastPackSize));
}


@override
int get hashCode {
  final _this = this as DiaperStock;
  return Object.hash(runtimeType,_this.count,_this.countedAt,_this.alertThreshold,_this.lastPackSize);
}

@override
String toString() {
  final _this = this as DiaperStock;
  return 'DiaperStock(count: ${_this.count}, countedAt: ${_this.countedAt}, alertThreshold: ${_this.alertThreshold}, lastPackSize: ${_this.lastPackSize})';
}


}

/// @nodoc
abstract mixin class $DiaperStockCopyWith<$Res>  {
  factory $DiaperStockCopyWith(DiaperStock value, $Res Function(DiaperStock) _then) = _$DiaperStockCopyWithImpl;
@useResult
$Res call({
 int count, DateTime countedAt, int alertThreshold, int lastPackSize
});




}
/// @nodoc
class _$DiaperStockCopyWithImpl<$Res>
    implements $DiaperStockCopyWith<$Res> {
  _$DiaperStockCopyWithImpl(this._self, this._then);

  final DiaperStock _self;
  final $Res Function(DiaperStock) _then;

/// Create a copy of DiaperStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? countedAt = null,Object? alertThreshold = null,Object? lastPackSize = null,}) {
  return _then(DiaperStock(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,countedAt: null == countedAt ? _self.countedAt : countedAt // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,lastPackSize: null == lastPackSize ? _self.lastPackSize : lastPackSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaperStock].
extension DiaperStockPatterns on DiaperStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaperStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaperStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaperStock value)  $default,){
final _that = this;
switch (_that) {
case _DiaperStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaperStock value)?  $default,){
final _that = this;
switch (_that) {
case _DiaperStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  DateTime countedAt,  int alertThreshold,  int lastPackSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaperStock() when $default != null:
return $default(_that.count,_that.countedAt,_that.alertThreshold,_that.lastPackSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  DateTime countedAt,  int alertThreshold,  int lastPackSize)  $default,) {final _that = this;
switch (_that) {
case _DiaperStock():
return $default(_that.count,_that.countedAt,_that.alertThreshold,_that.lastPackSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  DateTime countedAt,  int alertThreshold,  int lastPackSize)?  $default,) {final _that = this;
switch (_that) {
case _DiaperStock() when $default != null:
return $default(_that.count,_that.countedAt,_that.alertThreshold,_that.lastPackSize);case _:
  return null;

}
}

}

/// @nodoc


class _DiaperStock extends DiaperStock {
  const _DiaperStock({required this.count, required this.countedAt, this.alertThreshold = 10, this.lastPackSize = 44}): super._();
  

@override final  int count;
@override final  DateTime countedAt;
@override@JsonKey() final  int alertThreshold;
@override@JsonKey() final  int lastPackSize;

/// Create a copy of DiaperStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaperStockCopyWith<_DiaperStock> get copyWith => __$DiaperStockCopyWithImpl<_DiaperStock>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaperStock&&(identical(other.count, count) || other.count == count)&&(identical(other.countedAt, countedAt) || other.countedAt == countedAt)&&(identical(other.alertThreshold, alertThreshold) || other.alertThreshold == alertThreshold)&&(identical(other.lastPackSize, lastPackSize) || other.lastPackSize == lastPackSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,count,countedAt,alertThreshold,lastPackSize);
}

@override
String toString() {
    return 'DiaperStock(count: $count, countedAt: $countedAt, alertThreshold: $alertThreshold, lastPackSize: $lastPackSize)';
}


}

/// @nodoc
abstract mixin class _$DiaperStockCopyWith<$Res> implements $DiaperStockCopyWith<$Res> {
  factory _$DiaperStockCopyWith(_DiaperStock value, $Res Function(_DiaperStock) _then) = __$DiaperStockCopyWithImpl;
@override @useResult
$Res call({
 int count, DateTime countedAt, int alertThreshold, int lastPackSize
});




}
/// @nodoc
class __$DiaperStockCopyWithImpl<$Res>
    implements _$DiaperStockCopyWith<$Res> {
  __$DiaperStockCopyWithImpl(this._self, this._then);

  final _DiaperStock _self;
  final $Res Function(_DiaperStock) _then;

/// Create a copy of DiaperStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? countedAt = null,Object? alertThreshold = null,Object? lastPackSize = null,}) {
  return _then(_DiaperStock(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,countedAt: null == countedAt ? _self.countedAt : countedAt // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,lastPackSize: null == lastPackSize ? _self.lastPackSize : lastPackSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
