// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_diversity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyDiversity {

 Set<FoodGroup> get coveredGroups; int get tastingCount;
/// Create a copy of DailyDiversity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyDiversityCopyWith<DailyDiversity> get copyWith => _$DailyDiversityCopyWithImpl<DailyDiversity>(this as DailyDiversity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DailyDiversity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyDiversity&&const DeepCollectionEquality().equals(other.coveredGroups, _this.coveredGroups)&&(identical(other.tastingCount, _this.tastingCount) || other.tastingCount == _this.tastingCount));
}


@override
int get hashCode {
  final _this = this as DailyDiversity;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.coveredGroups),_this.tastingCount);
}

@override
String toString() {
  final _this = this as DailyDiversity;
  return 'DailyDiversity(coveredGroups: ${_this.coveredGroups}, tastingCount: ${_this.tastingCount})';
}


}

/// @nodoc
abstract mixin class $DailyDiversityCopyWith<$Res>  {
  factory $DailyDiversityCopyWith(DailyDiversity value, $Res Function(DailyDiversity) _then) = _$DailyDiversityCopyWithImpl;
@useResult
$Res call({
 Set<FoodGroup> coveredGroups, int tastingCount
});




}
/// @nodoc
class _$DailyDiversityCopyWithImpl<$Res>
    implements $DailyDiversityCopyWith<$Res> {
  _$DailyDiversityCopyWithImpl(this._self, this._then);

  final DailyDiversity _self;
  final $Res Function(DailyDiversity) _then;

/// Create a copy of DailyDiversity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coveredGroups = null,Object? tastingCount = null,}) {
  return _then(DailyDiversity(
coveredGroups: null == coveredGroups ? _self.coveredGroups : coveredGroups // ignore: cast_nullable_to_non_nullable
as Set<FoodGroup>,tastingCount: null == tastingCount ? _self.tastingCount : tastingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyDiversity].
extension DailyDiversityPatterns on DailyDiversity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyDiversity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyDiversity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyDiversity value)  $default,){
final _that = this;
switch (_that) {
case _DailyDiversity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyDiversity value)?  $default,){
final _that = this;
switch (_that) {
case _DailyDiversity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<FoodGroup> coveredGroups,  int tastingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyDiversity() when $default != null:
return $default(_that.coveredGroups,_that.tastingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<FoodGroup> coveredGroups,  int tastingCount)  $default,) {final _that = this;
switch (_that) {
case _DailyDiversity():
return $default(_that.coveredGroups,_that.tastingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<FoodGroup> coveredGroups,  int tastingCount)?  $default,) {final _that = this;
switch (_that) {
case _DailyDiversity() when $default != null:
return $default(_that.coveredGroups,_that.tastingCount);case _:
  return null;

}
}

}

/// @nodoc


class _DailyDiversity implements DailyDiversity {
  const _DailyDiversity({required  Set<FoodGroup> coveredGroups, required this.tastingCount}): _coveredGroups = coveredGroups;
  

 final  Set<FoodGroup> _coveredGroups;
@override Set<FoodGroup> get coveredGroups {
  if (_coveredGroups is EqualUnmodifiableSetView) return _coveredGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_coveredGroups);
}

@override final  int tastingCount;

/// Create a copy of DailyDiversity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyDiversityCopyWith<_DailyDiversity> get copyWith => __$DailyDiversityCopyWithImpl<_DailyDiversity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyDiversity&&const DeepCollectionEquality().equals(other.coveredGroups, _coveredGroups)&&(identical(other.tastingCount, tastingCount) || other.tastingCount == tastingCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_coveredGroups),tastingCount);
}

@override
String toString() {
    return 'DailyDiversity(coveredGroups: $coveredGroups, tastingCount: $tastingCount)';
}


}

/// @nodoc
abstract mixin class _$DailyDiversityCopyWith<$Res> implements $DailyDiversityCopyWith<$Res> {
  factory _$DailyDiversityCopyWith(_DailyDiversity value, $Res Function(_DailyDiversity) _then) = __$DailyDiversityCopyWithImpl;
@override @useResult
$Res call({
 Set<FoodGroup> coveredGroups, int tastingCount
});




}
/// @nodoc
class __$DailyDiversityCopyWithImpl<$Res>
    implements _$DailyDiversityCopyWith<$Res> {
  __$DailyDiversityCopyWithImpl(this._self, this._then);

  final _DailyDiversity _self;
  final $Res Function(_DailyDiversity) _then;

/// Create a copy of DailyDiversity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coveredGroups = null,Object? tastingCount = null,}) {
  return _then(_DailyDiversity(
coveredGroups: null == coveredGroups ? _self._coveredGroups : coveredGroups // ignore: cast_nullable_to_non_nullable
as Set<FoodGroup>,tastingCount: null == tastingCount ? _self.tastingCount : tastingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
