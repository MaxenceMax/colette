// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SleepSegment {

 DateTime get start; DateTime get end; SleepKind get kind;
/// Create a copy of SleepSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SleepSegmentCopyWith<SleepSegment> get copyWith => _$SleepSegmentCopyWithImpl<SleepSegment>(this as SleepSegment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SleepSegment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepSegment&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}


@override
int get hashCode {
  final _this = this as SleepSegment;
  return Object.hash(runtimeType,_this.start,_this.end,_this.kind);
}

@override
String toString() {
  final _this = this as SleepSegment;
  return 'SleepSegment(start: ${_this.start}, end: ${_this.end}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $SleepSegmentCopyWith<$Res>  {
  factory $SleepSegmentCopyWith(SleepSegment value, $Res Function(SleepSegment) _then) = _$SleepSegmentCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, SleepKind kind
});




}
/// @nodoc
class _$SleepSegmentCopyWithImpl<$Res>
    implements $SleepSegmentCopyWith<$Res> {
  _$SleepSegmentCopyWithImpl(this._self, this._then);

  final SleepSegment _self;
  final $Res Function(SleepSegment) _then;

/// Create a copy of SleepSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? kind = null,}) {
  return _then(SleepSegment(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SleepKind,
  ));
}

}


/// Adds pattern-matching-related methods to [SleepSegment].
extension SleepSegmentPatterns on SleepSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SleepSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SleepSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SleepSegment value)  $default,){
final _that = this;
switch (_that) {
case _SleepSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SleepSegment value)?  $default,){
final _that = this;
switch (_that) {
case _SleepSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  SleepKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SleepSegment() when $default != null:
return $default(_that.start,_that.end,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  SleepKind kind)  $default,) {final _that = this;
switch (_that) {
case _SleepSegment():
return $default(_that.start,_that.end,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  DateTime end,  SleepKind kind)?  $default,) {final _that = this;
switch (_that) {
case _SleepSegment() when $default != null:
return $default(_that.start,_that.end,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _SleepSegment implements SleepSegment {
  const _SleepSegment({required this.start, required this.end, required this.kind});
  

@override final  DateTime start;
@override final  DateTime end;
@override final  SleepKind kind;

/// Create a copy of SleepSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SleepSegmentCopyWith<_SleepSegment> get copyWith => __$SleepSegmentCopyWithImpl<_SleepSegment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SleepSegment&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode {
    return Object.hash(runtimeType,start,end,kind);
}

@override
String toString() {
    return 'SleepSegment(start: $start, end: $end, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$SleepSegmentCopyWith<$Res> implements $SleepSegmentCopyWith<$Res> {
  factory _$SleepSegmentCopyWith(_SleepSegment value, $Res Function(_SleepSegment) _then) = __$SleepSegmentCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, DateTime end, SleepKind kind
});




}
/// @nodoc
class __$SleepSegmentCopyWithImpl<$Res>
    implements _$SleepSegmentCopyWith<$Res> {
  __$SleepSegmentCopyWithImpl(this._self, this._then);

  final _SleepSegment _self;
  final $Res Function(_SleepSegment) _then;

/// Create a copy of SleepSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? kind = null,}) {
  return _then(_SleepSegment(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SleepKind,
  ));
}


}

/// @nodoc
mixin _$SleepDay {

 DateTime get day; List<SleepSegment> get segments; Duration get total; int get napCount; Duration get longest;
/// Create a copy of SleepDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SleepDayCopyWith<SleepDay> get copyWith => _$SleepDayCopyWithImpl<SleepDay>(this as SleepDay, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SleepDay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepDay&&(identical(other.day, _this.day) || other.day == _this.day)&&const DeepCollectionEquality().equals(other.segments, _this.segments)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.napCount, _this.napCount) || other.napCount == _this.napCount)&&(identical(other.longest, _this.longest) || other.longest == _this.longest));
}


@override
int get hashCode {
  final _this = this as SleepDay;
  return Object.hash(runtimeType,_this.day,const DeepCollectionEquality().hash(_this.segments),_this.total,_this.napCount,_this.longest);
}

@override
String toString() {
  final _this = this as SleepDay;
  return 'SleepDay(day: ${_this.day}, segments: ${_this.segments}, total: ${_this.total}, napCount: ${_this.napCount}, longest: ${_this.longest})';
}


}

/// @nodoc
abstract mixin class $SleepDayCopyWith<$Res>  {
  factory $SleepDayCopyWith(SleepDay value, $Res Function(SleepDay) _then) = _$SleepDayCopyWithImpl;
@useResult
$Res call({
 DateTime day, List<SleepSegment> segments, Duration total, int napCount, Duration longest
});




}
/// @nodoc
class _$SleepDayCopyWithImpl<$Res>
    implements $SleepDayCopyWith<$Res> {
  _$SleepDayCopyWithImpl(this._self, this._then);

  final SleepDay _self;
  final $Res Function(SleepDay) _then;

/// Create a copy of SleepDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? segments = null,Object? total = null,Object? napCount = null,Object? longest = null,}) {
  return _then(SleepDay(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<SleepSegment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Duration,napCount: null == napCount ? _self.napCount : napCount // ignore: cast_nullable_to_non_nullable
as int,longest: null == longest ? _self.longest : longest // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [SleepDay].
extension SleepDayPatterns on SleepDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SleepDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SleepDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SleepDay value)  $default,){
final _that = this;
switch (_that) {
case _SleepDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SleepDay value)?  $default,){
final _that = this;
switch (_that) {
case _SleepDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  List<SleepSegment> segments,  Duration total,  int napCount,  Duration longest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SleepDay() when $default != null:
return $default(_that.day,_that.segments,_that.total,_that.napCount,_that.longest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  List<SleepSegment> segments,  Duration total,  int napCount,  Duration longest)  $default,) {final _that = this;
switch (_that) {
case _SleepDay():
return $default(_that.day,_that.segments,_that.total,_that.napCount,_that.longest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  List<SleepSegment> segments,  Duration total,  int napCount,  Duration longest)?  $default,) {final _that = this;
switch (_that) {
case _SleepDay() when $default != null:
return $default(_that.day,_that.segments,_that.total,_that.napCount,_that.longest);case _:
  return null;

}
}

}

/// @nodoc


class _SleepDay implements SleepDay {
  const _SleepDay({required this.day, required  List<SleepSegment> segments, required this.total, required this.napCount, required this.longest}): _segments = segments;
  

@override final  DateTime day;
 final  List<SleepSegment> _segments;
@override List<SleepSegment> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

@override final  Duration total;
@override final  int napCount;
@override final  Duration longest;

/// Create a copy of SleepDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SleepDayCopyWith<_SleepDay> get copyWith => __$SleepDayCopyWithImpl<_SleepDay>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SleepDay&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other.segments, _segments)&&(identical(other.total, total) || other.total == total)&&(identical(other.napCount, napCount) || other.napCount == napCount)&&(identical(other.longest, longest) || other.longest == longest));
}


@override
int get hashCode {
    return Object.hash(runtimeType,day,const DeepCollectionEquality().hash(_segments),total,napCount,longest);
}

@override
String toString() {
    return 'SleepDay(day: $day, segments: $segments, total: $total, napCount: $napCount, longest: $longest)';
}


}

/// @nodoc
abstract mixin class _$SleepDayCopyWith<$Res> implements $SleepDayCopyWith<$Res> {
  factory _$SleepDayCopyWith(_SleepDay value, $Res Function(_SleepDay) _then) = __$SleepDayCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, List<SleepSegment> segments, Duration total, int napCount, Duration longest
});




}
/// @nodoc
class __$SleepDayCopyWithImpl<$Res>
    implements _$SleepDayCopyWith<$Res> {
  __$SleepDayCopyWithImpl(this._self, this._then);

  final _SleepDay _self;
  final $Res Function(_SleepDay) _then;

/// Create a copy of SleepDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? segments = null,Object? total = null,Object? napCount = null,Object? longest = null,}) {
  return _then(_SleepDay(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<SleepSegment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Duration,napCount: null == napCount ? _self.napCount : napCount // ignore: cast_nullable_to_non_nullable
as int,longest: null == longest ? _self.longest : longest // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
