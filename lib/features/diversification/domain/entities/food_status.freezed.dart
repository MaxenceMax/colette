// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FoodStatus()';
}


}

/// @nodoc
class $FoodStatusCopyWith<$Res>  {
$FoodStatusCopyWith(FoodStatus _, $Res Function(FoodStatus) __);
}


/// Adds pattern-matching-related methods to [FoodStatus].
extension FoodStatusPatterns on FoodStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FoodStatusAvoid value)?  avoid,TResult Function( FoodStatusNotYetRecommended value)?  notYetRecommended,TResult Function( FoodStatusTasted value)?  tasted,TResult Function( FoodStatusNotTasted value)?  notTasted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FoodStatusAvoid() when avoid != null:
return avoid(_that);case FoodStatusNotYetRecommended() when notYetRecommended != null:
return notYetRecommended(_that);case FoodStatusTasted() when tasted != null:
return tasted(_that);case FoodStatusNotTasted() when notTasted != null:
return notTasted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FoodStatusAvoid value)  avoid,required TResult Function( FoodStatusNotYetRecommended value)  notYetRecommended,required TResult Function( FoodStatusTasted value)  tasted,required TResult Function( FoodStatusNotTasted value)  notTasted,}){
final _that = this;
switch (_that) {
case FoodStatusAvoid():
return avoid(_that);case FoodStatusNotYetRecommended():
return notYetRecommended(_that);case FoodStatusTasted():
return tasted(_that);case FoodStatusNotTasted():
return notTasted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FoodStatusAvoid value)?  avoid,TResult? Function( FoodStatusNotYetRecommended value)?  notYetRecommended,TResult? Function( FoodStatusTasted value)?  tasted,TResult? Function( FoodStatusNotTasted value)?  notTasted,}){
final _that = this;
switch (_that) {
case FoodStatusAvoid() when avoid != null:
return avoid(_that);case FoodStatusNotYetRecommended() when notYetRecommended != null:
return notYetRecommended(_that);case FoodStatusTasted() when tasted != null:
return tasted(_that);case FoodStatusNotTasted() when notTasted != null:
return notTasted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int untilMonths,  List<RuleSource> sources)?  avoid,TResult Function()?  notYetRecommended,TResult Function( int count,  bool needsPreparation)?  tasted,TResult Function( bool needsPreparation)?  notTasted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FoodStatusAvoid() when avoid != null:
return avoid(_that.untilMonths,_that.sources);case FoodStatusNotYetRecommended() when notYetRecommended != null:
return notYetRecommended();case FoodStatusTasted() when tasted != null:
return tasted(_that.count,_that.needsPreparation);case FoodStatusNotTasted() when notTasted != null:
return notTasted(_that.needsPreparation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int untilMonths,  List<RuleSource> sources)  avoid,required TResult Function()  notYetRecommended,required TResult Function( int count,  bool needsPreparation)  tasted,required TResult Function( bool needsPreparation)  notTasted,}) {final _that = this;
switch (_that) {
case FoodStatusAvoid():
return avoid(_that.untilMonths,_that.sources);case FoodStatusNotYetRecommended():
return notYetRecommended();case FoodStatusTasted():
return tasted(_that.count,_that.needsPreparation);case FoodStatusNotTasted():
return notTasted(_that.needsPreparation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int untilMonths,  List<RuleSource> sources)?  avoid,TResult? Function()?  notYetRecommended,TResult? Function( int count,  bool needsPreparation)?  tasted,TResult? Function( bool needsPreparation)?  notTasted,}) {final _that = this;
switch (_that) {
case FoodStatusAvoid() when avoid != null:
return avoid(_that.untilMonths,_that.sources);case FoodStatusNotYetRecommended() when notYetRecommended != null:
return notYetRecommended();case FoodStatusTasted() when tasted != null:
return tasted(_that.count,_that.needsPreparation);case FoodStatusNotTasted() when notTasted != null:
return notTasted(_that.needsPreparation);case _:
  return null;

}
}

}

/// @nodoc


class FoodStatusAvoid implements FoodStatus {
  const FoodStatusAvoid({required this.untilMonths, required  List<RuleSource> sources}): _sources = sources;
  

 final  int untilMonths;
 final  List<RuleSource> _sources;
 List<RuleSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodStatusAvoidCopyWith<FoodStatusAvoid> get copyWith => _$FoodStatusAvoidCopyWithImpl<FoodStatusAvoid>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodStatusAvoid&&(identical(other.untilMonths, untilMonths) || other.untilMonths == untilMonths)&&const DeepCollectionEquality().equals(other.sources, _sources));
}


@override
int get hashCode {
    return Object.hash(runtimeType,untilMonths,const DeepCollectionEquality().hash(_sources));
}

@override
String toString() {
    return 'FoodStatus.avoid(untilMonths: $untilMonths, sources: $sources)';
}


}

/// @nodoc
abstract mixin class $FoodStatusAvoidCopyWith<$Res> implements $FoodStatusCopyWith<$Res> {
  factory $FoodStatusAvoidCopyWith(FoodStatusAvoid value, $Res Function(FoodStatusAvoid) _then) = _$FoodStatusAvoidCopyWithImpl;
@useResult
$Res call({
 int untilMonths, List<RuleSource> sources
});




}
/// @nodoc
class _$FoodStatusAvoidCopyWithImpl<$Res>
    implements $FoodStatusAvoidCopyWith<$Res> {
  _$FoodStatusAvoidCopyWithImpl(this._self, this._then);

  final FoodStatusAvoid _self;
  final $Res Function(FoodStatusAvoid) _then;

/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? untilMonths = null,Object? sources = null,}) {
  return _then(FoodStatusAvoid(
untilMonths: null == untilMonths ? _self.untilMonths : untilMonths // ignore: cast_nullable_to_non_nullable
as int,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<RuleSource>,
  ));
}


}

/// @nodoc


class FoodStatusNotYetRecommended implements FoodStatus {
  const FoodStatusNotYetRecommended();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodStatusNotYetRecommended);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FoodStatus.notYetRecommended()';
}


}




/// @nodoc


class FoodStatusTasted implements FoodStatus {
  const FoodStatusTasted({required this.count, required this.needsPreparation});
  

 final  int count;
 final  bool needsPreparation;

/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodStatusTastedCopyWith<FoodStatusTasted> get copyWith => _$FoodStatusTastedCopyWithImpl<FoodStatusTasted>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodStatusTasted&&(identical(other.count, count) || other.count == count)&&(identical(other.needsPreparation, needsPreparation) || other.needsPreparation == needsPreparation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,count,needsPreparation);
}

@override
String toString() {
    return 'FoodStatus.tasted(count: $count, needsPreparation: $needsPreparation)';
}


}

/// @nodoc
abstract mixin class $FoodStatusTastedCopyWith<$Res> implements $FoodStatusCopyWith<$Res> {
  factory $FoodStatusTastedCopyWith(FoodStatusTasted value, $Res Function(FoodStatusTasted) _then) = _$FoodStatusTastedCopyWithImpl;
@useResult
$Res call({
 int count, bool needsPreparation
});




}
/// @nodoc
class _$FoodStatusTastedCopyWithImpl<$Res>
    implements $FoodStatusTastedCopyWith<$Res> {
  _$FoodStatusTastedCopyWithImpl(this._self, this._then);

  final FoodStatusTasted _self;
  final $Res Function(FoodStatusTasted) _then;

/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? count = null,Object? needsPreparation = null,}) {
  return _then(FoodStatusTasted(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,needsPreparation: null == needsPreparation ? _self.needsPreparation : needsPreparation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class FoodStatusNotTasted implements FoodStatus {
  const FoodStatusNotTasted({required this.needsPreparation});
  

 final  bool needsPreparation;

/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodStatusNotTastedCopyWith<FoodStatusNotTasted> get copyWith => _$FoodStatusNotTastedCopyWithImpl<FoodStatusNotTasted>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodStatusNotTasted&&(identical(other.needsPreparation, needsPreparation) || other.needsPreparation == needsPreparation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,needsPreparation);
}

@override
String toString() {
    return 'FoodStatus.notTasted(needsPreparation: $needsPreparation)';
}


}

/// @nodoc
abstract mixin class $FoodStatusNotTastedCopyWith<$Res> implements $FoodStatusCopyWith<$Res> {
  factory $FoodStatusNotTastedCopyWith(FoodStatusNotTasted value, $Res Function(FoodStatusNotTasted) _then) = _$FoodStatusNotTastedCopyWithImpl;
@useResult
$Res call({
 bool needsPreparation
});




}
/// @nodoc
class _$FoodStatusNotTastedCopyWithImpl<$Res>
    implements $FoodStatusNotTastedCopyWith<$Res> {
  _$FoodStatusNotTastedCopyWithImpl(this._self, this._then);

  final FoodStatusNotTasted _self;
  final $Res Function(FoodStatusNotTasted) _then;

/// Create a copy of FoodStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? needsPreparation = null,}) {
  return _then(FoodStatusNotTasted(
needsPreparation: null == needsPreparation ? _self.needsPreparation : needsPreparation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
