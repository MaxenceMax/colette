// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'growth_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrowthTrend {

 GrowthMetric get metric; int get latestValue; DateTime get latestAt; int? get previousValue; DateTime? get previousAt;
/// Create a copy of GrowthTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrowthTrendCopyWith<GrowthTrend> get copyWith => _$GrowthTrendCopyWithImpl<GrowthTrend>(this as GrowthTrend, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GrowthTrend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrowthTrend&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.latestValue, _this.latestValue) || other.latestValue == _this.latestValue)&&(identical(other.latestAt, _this.latestAt) || other.latestAt == _this.latestAt)&&(identical(other.previousValue, _this.previousValue) || other.previousValue == _this.previousValue)&&(identical(other.previousAt, _this.previousAt) || other.previousAt == _this.previousAt));
}


@override
int get hashCode {
  final _this = this as GrowthTrend;
  return Object.hash(runtimeType,_this.metric,_this.latestValue,_this.latestAt,_this.previousValue,_this.previousAt);
}

@override
String toString() {
  final _this = this as GrowthTrend;
  return 'GrowthTrend(metric: ${_this.metric}, latestValue: ${_this.latestValue}, latestAt: ${_this.latestAt}, previousValue: ${_this.previousValue}, previousAt: ${_this.previousAt})';
}


}

/// @nodoc
abstract mixin class $GrowthTrendCopyWith<$Res>  {
  factory $GrowthTrendCopyWith(GrowthTrend value, $Res Function(GrowthTrend) _then) = _$GrowthTrendCopyWithImpl;
@useResult
$Res call({
 GrowthMetric metric, int latestValue, DateTime latestAt, int? previousValue, DateTime? previousAt
});




}
/// @nodoc
class _$GrowthTrendCopyWithImpl<$Res>
    implements $GrowthTrendCopyWith<$Res> {
  _$GrowthTrendCopyWithImpl(this._self, this._then);

  final GrowthTrend _self;
  final $Res Function(GrowthTrend) _then;

/// Create a copy of GrowthTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metric = null,Object? latestValue = null,Object? latestAt = null,Object? previousValue = freezed,Object? previousAt = freezed,}) {
  return _then(GrowthTrend(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as GrowthMetric,latestValue: null == latestValue ? _self.latestValue : latestValue // ignore: cast_nullable_to_non_nullable
as int,latestAt: null == latestAt ? _self.latestAt : latestAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousValue: freezed == previousValue ? _self.previousValue : previousValue // ignore: cast_nullable_to_non_nullable
as int?,previousAt: freezed == previousAt ? _self.previousAt : previousAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GrowthTrend].
extension GrowthTrendPatterns on GrowthTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrowthTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrowthTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrowthTrend value)  $default,){
final _that = this;
switch (_that) {
case _GrowthTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrowthTrend value)?  $default,){
final _that = this;
switch (_that) {
case _GrowthTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrowthMetric metric,  int latestValue,  DateTime latestAt,  int? previousValue,  DateTime? previousAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrowthTrend() when $default != null:
return $default(_that.metric,_that.latestValue,_that.latestAt,_that.previousValue,_that.previousAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrowthMetric metric,  int latestValue,  DateTime latestAt,  int? previousValue,  DateTime? previousAt)  $default,) {final _that = this;
switch (_that) {
case _GrowthTrend():
return $default(_that.metric,_that.latestValue,_that.latestAt,_that.previousValue,_that.previousAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrowthMetric metric,  int latestValue,  DateTime latestAt,  int? previousValue,  DateTime? previousAt)?  $default,) {final _that = this;
switch (_that) {
case _GrowthTrend() when $default != null:
return $default(_that.metric,_that.latestValue,_that.latestAt,_that.previousValue,_that.previousAt);case _:
  return null;

}
}

}

/// @nodoc


class _GrowthTrend extends GrowthTrend {
  const _GrowthTrend({required this.metric, required this.latestValue, required this.latestAt, this.previousValue, this.previousAt}): super._();
  

@override final  GrowthMetric metric;
@override final  int latestValue;
@override final  DateTime latestAt;
@override final  int? previousValue;
@override final  DateTime? previousAt;

/// Create a copy of GrowthTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrowthTrendCopyWith<_GrowthTrend> get copyWith => __$GrowthTrendCopyWithImpl<_GrowthTrend>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrowthTrend&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.latestValue, latestValue) || other.latestValue == latestValue)&&(identical(other.latestAt, latestAt) || other.latestAt == latestAt)&&(identical(other.previousValue, previousValue) || other.previousValue == previousValue)&&(identical(other.previousAt, previousAt) || other.previousAt == previousAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,metric,latestValue,latestAt,previousValue,previousAt);
}

@override
String toString() {
    return 'GrowthTrend(metric: $metric, latestValue: $latestValue, latestAt: $latestAt, previousValue: $previousValue, previousAt: $previousAt)';
}


}

/// @nodoc
abstract mixin class _$GrowthTrendCopyWith<$Res> implements $GrowthTrendCopyWith<$Res> {
  factory _$GrowthTrendCopyWith(_GrowthTrend value, $Res Function(_GrowthTrend) _then) = __$GrowthTrendCopyWithImpl;
@override @useResult
$Res call({
 GrowthMetric metric, int latestValue, DateTime latestAt, int? previousValue, DateTime? previousAt
});




}
/// @nodoc
class __$GrowthTrendCopyWithImpl<$Res>
    implements _$GrowthTrendCopyWith<$Res> {
  __$GrowthTrendCopyWithImpl(this._self, this._then);

  final _GrowthTrend _self;
  final $Res Function(_GrowthTrend) _then;

/// Create a copy of GrowthTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metric = null,Object? latestValue = null,Object? latestAt = null,Object? previousValue = freezed,Object? previousAt = freezed,}) {
  return _then(_GrowthTrend(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as GrowthMetric,latestValue: null == latestValue ? _self.latestValue : latestValue // ignore: cast_nullable_to_non_nullable
as int,latestAt: null == latestAt ? _self.latestAt : latestAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousValue: freezed == previousValue ? _self.previousValue : previousValue // ignore: cast_nullable_to_non_nullable
as int?,previousAt: freezed == previousAt ? _self.previousAt : previousAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
