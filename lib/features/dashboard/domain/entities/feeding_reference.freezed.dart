// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feeding_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedingReference {

 int get dayOfLife; FeedingAgeBand get ageBand; int get mlPerKg; int? get weightGrams; int? get weightTargetMl;
/// Create a copy of FeedingReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedingReferenceCopyWith<FeedingReference> get copyWith => _$FeedingReferenceCopyWithImpl<FeedingReference>(this as FeedingReference, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedingReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedingReference&&(identical(other.dayOfLife, _this.dayOfLife) || other.dayOfLife == _this.dayOfLife)&&(identical(other.ageBand, _this.ageBand) || other.ageBand == _this.ageBand)&&(identical(other.mlPerKg, _this.mlPerKg) || other.mlPerKg == _this.mlPerKg)&&(identical(other.weightGrams, _this.weightGrams) || other.weightGrams == _this.weightGrams)&&(identical(other.weightTargetMl, _this.weightTargetMl) || other.weightTargetMl == _this.weightTargetMl));
}


@override
int get hashCode {
  final _this = this as FeedingReference;
  return Object.hash(runtimeType,_this.dayOfLife,_this.ageBand,_this.mlPerKg,_this.weightGrams,_this.weightTargetMl);
}

@override
String toString() {
  final _this = this as FeedingReference;
  return 'FeedingReference(dayOfLife: ${_this.dayOfLife}, ageBand: ${_this.ageBand}, mlPerKg: ${_this.mlPerKg}, weightGrams: ${_this.weightGrams}, weightTargetMl: ${_this.weightTargetMl})';
}


}

/// @nodoc
abstract mixin class $FeedingReferenceCopyWith<$Res>  {
  factory $FeedingReferenceCopyWith(FeedingReference value, $Res Function(FeedingReference) _then) = _$FeedingReferenceCopyWithImpl;
@useResult
$Res call({
 int dayOfLife, FeedingAgeBand ageBand, int mlPerKg, int? weightGrams, int? weightTargetMl
});




}
/// @nodoc
class _$FeedingReferenceCopyWithImpl<$Res>
    implements $FeedingReferenceCopyWith<$Res> {
  _$FeedingReferenceCopyWithImpl(this._self, this._then);

  final FeedingReference _self;
  final $Res Function(FeedingReference) _then;

/// Create a copy of FeedingReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayOfLife = null,Object? ageBand = null,Object? mlPerKg = null,Object? weightGrams = freezed,Object? weightTargetMl = freezed,}) {
  return _then(FeedingReference(
dayOfLife: null == dayOfLife ? _self.dayOfLife : dayOfLife // ignore: cast_nullable_to_non_nullable
as int,ageBand: null == ageBand ? _self.ageBand : ageBand // ignore: cast_nullable_to_non_nullable
as FeedingAgeBand,mlPerKg: null == mlPerKg ? _self.mlPerKg : mlPerKg // ignore: cast_nullable_to_non_nullable
as int,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,weightTargetMl: freezed == weightTargetMl ? _self.weightTargetMl : weightTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedingReference].
extension FeedingReferencePatterns on FeedingReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedingReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedingReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedingReference value)  $default,){
final _that = this;
switch (_that) {
case _FeedingReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedingReference value)?  $default,){
final _that = this;
switch (_that) {
case _FeedingReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayOfLife,  FeedingAgeBand ageBand,  int mlPerKg,  int? weightGrams,  int? weightTargetMl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedingReference() when $default != null:
return $default(_that.dayOfLife,_that.ageBand,_that.mlPerKg,_that.weightGrams,_that.weightTargetMl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayOfLife,  FeedingAgeBand ageBand,  int mlPerKg,  int? weightGrams,  int? weightTargetMl)  $default,) {final _that = this;
switch (_that) {
case _FeedingReference():
return $default(_that.dayOfLife,_that.ageBand,_that.mlPerKg,_that.weightGrams,_that.weightTargetMl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayOfLife,  FeedingAgeBand ageBand,  int mlPerKg,  int? weightGrams,  int? weightTargetMl)?  $default,) {final _that = this;
switch (_that) {
case _FeedingReference() when $default != null:
return $default(_that.dayOfLife,_that.ageBand,_that.mlPerKg,_that.weightGrams,_that.weightTargetMl);case _:
  return null;

}
}

}

/// @nodoc


class _FeedingReference implements FeedingReference {
  const _FeedingReference({required this.dayOfLife, required this.ageBand, required this.mlPerKg, this.weightGrams, this.weightTargetMl});
  

@override final  int dayOfLife;
@override final  FeedingAgeBand ageBand;
@override final  int mlPerKg;
@override final  int? weightGrams;
@override final  int? weightTargetMl;

/// Create a copy of FeedingReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedingReferenceCopyWith<_FeedingReference> get copyWith => __$FeedingReferenceCopyWithImpl<_FeedingReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedingReference&&(identical(other.dayOfLife, dayOfLife) || other.dayOfLife == dayOfLife)&&(identical(other.ageBand, ageBand) || other.ageBand == ageBand)&&(identical(other.mlPerKg, mlPerKg) || other.mlPerKg == mlPerKg)&&(identical(other.weightGrams, weightGrams) || other.weightGrams == weightGrams)&&(identical(other.weightTargetMl, weightTargetMl) || other.weightTargetMl == weightTargetMl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,dayOfLife,ageBand,mlPerKg,weightGrams,weightTargetMl);
}

@override
String toString() {
    return 'FeedingReference(dayOfLife: $dayOfLife, ageBand: $ageBand, mlPerKg: $mlPerKg, weightGrams: $weightGrams, weightTargetMl: $weightTargetMl)';
}


}

/// @nodoc
abstract mixin class _$FeedingReferenceCopyWith<$Res> implements $FeedingReferenceCopyWith<$Res> {
  factory _$FeedingReferenceCopyWith(_FeedingReference value, $Res Function(_FeedingReference) _then) = __$FeedingReferenceCopyWithImpl;
@override @useResult
$Res call({
 int dayOfLife, FeedingAgeBand ageBand, int mlPerKg, int? weightGrams, int? weightTargetMl
});




}
/// @nodoc
class __$FeedingReferenceCopyWithImpl<$Res>
    implements _$FeedingReferenceCopyWith<$Res> {
  __$FeedingReferenceCopyWithImpl(this._self, this._then);

  final _FeedingReference _self;
  final $Res Function(_FeedingReference) _then;

/// Create a copy of FeedingReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayOfLife = null,Object? ageBand = null,Object? mlPerKg = null,Object? weightGrams = freezed,Object? weightTargetMl = freezed,}) {
  return _then(_FeedingReference(
dayOfLife: null == dayOfLife ? _self.dayOfLife : dayOfLife // ignore: cast_nullable_to_non_nullable
as int,ageBand: null == ageBand ? _self.ageBand : ageBand // ignore: cast_nullable_to_non_nullable
as FeedingAgeBand,mlPerKg: null == mlPerKg ? _self.mlPerKg : mlPerKg // ignore: cast_nullable_to_non_nullable
as int,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,weightTargetMl: freezed == weightTargetMl ? _self.weightTargetMl : weightTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
