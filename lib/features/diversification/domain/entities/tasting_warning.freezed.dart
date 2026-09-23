// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tasting_warning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TastingWarning {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TastingWarning);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TastingWarning()';
}


}

/// @nodoc
class $TastingWarningCopyWith<$Res>  {
$TastingWarningCopyWith(TastingWarning _, $Res Function(TastingWarning) __);
}


/// Adds pattern-matching-related methods to [TastingWarning].
extension TastingWarningPatterns on TastingWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TastingWarningAvoidRule value)?  avoidRule,TResult Function( TastingWarningTooEarly value)?  tooEarly,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TastingWarningAvoidRule() when avoidRule != null:
return avoidRule(_that);case TastingWarningTooEarly() when tooEarly != null:
return tooEarly(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TastingWarningAvoidRule value)  avoidRule,required TResult Function( TastingWarningTooEarly value)  tooEarly,}){
final _that = this;
switch (_that) {
case TastingWarningAvoidRule():
return avoidRule(_that);case TastingWarningTooEarly():
return tooEarly(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TastingWarningAvoidRule value)?  avoidRule,TResult? Function( TastingWarningTooEarly value)?  tooEarly,}){
final _that = this;
switch (_that) {
case TastingWarningAvoidRule() when avoidRule != null:
return avoidRule(_that);case TastingWarningTooEarly() when tooEarly != null:
return tooEarly(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( FoodRule rule)?  avoidRule,TResult Function()?  tooEarly,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TastingWarningAvoidRule() when avoidRule != null:
return avoidRule(_that.rule);case TastingWarningTooEarly() when tooEarly != null:
return tooEarly();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( FoodRule rule)  avoidRule,required TResult Function()  tooEarly,}) {final _that = this;
switch (_that) {
case TastingWarningAvoidRule():
return avoidRule(_that.rule);case TastingWarningTooEarly():
return tooEarly();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( FoodRule rule)?  avoidRule,TResult? Function()?  tooEarly,}) {final _that = this;
switch (_that) {
case TastingWarningAvoidRule() when avoidRule != null:
return avoidRule(_that.rule);case TastingWarningTooEarly() when tooEarly != null:
return tooEarly();case _:
  return null;

}
}

}

/// @nodoc


class TastingWarningAvoidRule implements TastingWarning {
  const TastingWarningAvoidRule(this.rule);
  

 final  FoodRule rule;

/// Create a copy of TastingWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TastingWarningAvoidRuleCopyWith<TastingWarningAvoidRule> get copyWith => _$TastingWarningAvoidRuleCopyWithImpl<TastingWarningAvoidRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TastingWarningAvoidRule&&(identical(other.rule, rule) || other.rule == rule));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rule);
}

@override
String toString() {
    return 'TastingWarning.avoidRule(rule: $rule)';
}


}

/// @nodoc
abstract mixin class $TastingWarningAvoidRuleCopyWith<$Res> implements $TastingWarningCopyWith<$Res> {
  factory $TastingWarningAvoidRuleCopyWith(TastingWarningAvoidRule value, $Res Function(TastingWarningAvoidRule) _then) = _$TastingWarningAvoidRuleCopyWithImpl;
@useResult
$Res call({
 FoodRule rule
});


$FoodRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$TastingWarningAvoidRuleCopyWithImpl<$Res>
    implements $TastingWarningAvoidRuleCopyWith<$Res> {
  _$TastingWarningAvoidRuleCopyWithImpl(this._self, this._then);

  final TastingWarningAvoidRule _self;
  final $Res Function(TastingWarningAvoidRule) _then;

/// Create a copy of TastingWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rule = null,}) {
  return _then(TastingWarningAvoidRule(
null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as FoodRule,
  ));
}

/// Create a copy of TastingWarning
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodRuleCopyWith<$Res> get rule {
  
  return $FoodRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}

/// @nodoc


class TastingWarningTooEarly implements TastingWarning {
  const TastingWarningTooEarly();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TastingWarningTooEarly);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TastingWarning.tooEarly()';
}


}




// dart format on
