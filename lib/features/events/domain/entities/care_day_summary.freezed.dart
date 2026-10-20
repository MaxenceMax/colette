// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_day_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareDaySummary {

 int get bottleMl; int get bottleCount; int get diapers; int get pee;
/// Create a copy of CareDaySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareDaySummaryCopyWith<CareDaySummary> get copyWith => _$CareDaySummaryCopyWithImpl<CareDaySummary>(this as CareDaySummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CareDaySummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareDaySummary&&(identical(other.bottleMl, _this.bottleMl) || other.bottleMl == _this.bottleMl)&&(identical(other.bottleCount, _this.bottleCount) || other.bottleCount == _this.bottleCount)&&(identical(other.diapers, _this.diapers) || other.diapers == _this.diapers)&&(identical(other.pee, _this.pee) || other.pee == _this.pee));
}


@override
int get hashCode {
  final _this = this as CareDaySummary;
  return Object.hash(runtimeType,_this.bottleMl,_this.bottleCount,_this.diapers,_this.pee);
}

@override
String toString() {
  final _this = this as CareDaySummary;
  return 'CareDaySummary(bottleMl: ${_this.bottleMl}, bottleCount: ${_this.bottleCount}, diapers: ${_this.diapers}, pee: ${_this.pee})';
}


}

/// @nodoc
abstract mixin class $CareDaySummaryCopyWith<$Res>  {
  factory $CareDaySummaryCopyWith(CareDaySummary value, $Res Function(CareDaySummary) _then) = _$CareDaySummaryCopyWithImpl;
@useResult
$Res call({
 int bottleMl, int bottleCount, int diapers, int pee
});




}
/// @nodoc
class _$CareDaySummaryCopyWithImpl<$Res>
    implements $CareDaySummaryCopyWith<$Res> {
  _$CareDaySummaryCopyWithImpl(this._self, this._then);

  final CareDaySummary _self;
  final $Res Function(CareDaySummary) _then;

/// Create a copy of CareDaySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bottleMl = null,Object? bottleCount = null,Object? diapers = null,Object? pee = null,}) {
  return _then(CareDaySummary(
bottleMl: null == bottleMl ? _self.bottleMl : bottleMl // ignore: cast_nullable_to_non_nullable
as int,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,diapers: null == diapers ? _self.diapers : diapers // ignore: cast_nullable_to_non_nullable
as int,pee: null == pee ? _self.pee : pee // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CareDaySummary].
extension CareDaySummaryPatterns on CareDaySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareDaySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareDaySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareDaySummary value)  $default,){
final _that = this;
switch (_that) {
case _CareDaySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareDaySummary value)?  $default,){
final _that = this;
switch (_that) {
case _CareDaySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bottleMl,  int bottleCount,  int diapers,  int pee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareDaySummary() when $default != null:
return $default(_that.bottleMl,_that.bottleCount,_that.diapers,_that.pee);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bottleMl,  int bottleCount,  int diapers,  int pee)  $default,) {final _that = this;
switch (_that) {
case _CareDaySummary():
return $default(_that.bottleMl,_that.bottleCount,_that.diapers,_that.pee);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bottleMl,  int bottleCount,  int diapers,  int pee)?  $default,) {final _that = this;
switch (_that) {
case _CareDaySummary() when $default != null:
return $default(_that.bottleMl,_that.bottleCount,_that.diapers,_that.pee);case _:
  return null;

}
}

}

/// @nodoc


class _CareDaySummary extends CareDaySummary {
  const _CareDaySummary({this.bottleMl = 0, this.bottleCount = 0, this.diapers = 0, this.pee = 0}): super._();
  

@override@JsonKey() final  int bottleMl;
@override@JsonKey() final  int bottleCount;
@override@JsonKey() final  int diapers;
@override@JsonKey() final  int pee;

/// Create a copy of CareDaySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareDaySummaryCopyWith<_CareDaySummary> get copyWith => __$CareDaySummaryCopyWithImpl<_CareDaySummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareDaySummary&&(identical(other.bottleMl, bottleMl) || other.bottleMl == bottleMl)&&(identical(other.bottleCount, bottleCount) || other.bottleCount == bottleCount)&&(identical(other.diapers, diapers) || other.diapers == diapers)&&(identical(other.pee, pee) || other.pee == pee));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bottleMl,bottleCount,diapers,pee);
}

@override
String toString() {
    return 'CareDaySummary(bottleMl: $bottleMl, bottleCount: $bottleCount, diapers: $diapers, pee: $pee)';
}


}

/// @nodoc
abstract mixin class _$CareDaySummaryCopyWith<$Res> implements $CareDaySummaryCopyWith<$Res> {
  factory _$CareDaySummaryCopyWith(_CareDaySummary value, $Res Function(_CareDaySummary) _then) = __$CareDaySummaryCopyWithImpl;
@override @useResult
$Res call({
 int bottleMl, int bottleCount, int diapers, int pee
});




}
/// @nodoc
class __$CareDaySummaryCopyWithImpl<$Res>
    implements _$CareDaySummaryCopyWith<$Res> {
  __$CareDaySummaryCopyWithImpl(this._self, this._then);

  final _CareDaySummary _self;
  final $Res Function(_CareDaySummary) _then;

/// Create a copy of CareDaySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bottleMl = null,Object? bottleCount = null,Object? diapers = null,Object? pee = null,}) {
  return _then(_CareDaySummary(
bottleMl: null == bottleMl ? _self.bottleMl : bottleMl // ignore: cast_nullable_to_non_nullable
as int,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,diapers: null == diapers ? _self.diapers : diapers // ignore: cast_nullable_to_non_nullable
as int,pee: null == pee ? _self.pee : pee // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
