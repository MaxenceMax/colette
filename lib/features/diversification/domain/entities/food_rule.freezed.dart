// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodRule {

 RuleKind get kind;/// Âge (mois révolus) à partir duquel la règle ne s'applique plus ;
/// obligatoire pour `avoid` et `prepare`, absent pour `info`.
 int? get untilMonths; List<RuleSource> get sources; String get text;
/// Create a copy of FoodRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodRuleCopyWith<FoodRule> get copyWith => _$FoodRuleCopyWithImpl<FoodRule>(this as FoodRule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FoodRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodRule&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.untilMonths, _this.untilMonths) || other.untilMonths == _this.untilMonths)&&const DeepCollectionEquality().equals(other.sources, _this.sources)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as FoodRule;
  return Object.hash(runtimeType,_this.kind,_this.untilMonths,const DeepCollectionEquality().hash(_this.sources),_this.text);
}

@override
String toString() {
  final _this = this as FoodRule;
  return 'FoodRule(kind: ${_this.kind}, untilMonths: ${_this.untilMonths}, sources: ${_this.sources}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $FoodRuleCopyWith<$Res>  {
  factory $FoodRuleCopyWith(FoodRule value, $Res Function(FoodRule) _then) = _$FoodRuleCopyWithImpl;
@useResult
$Res call({
 RuleKind kind, int? untilMonths, List<RuleSource> sources, String text
});




}
/// @nodoc
class _$FoodRuleCopyWithImpl<$Res>
    implements $FoodRuleCopyWith<$Res> {
  _$FoodRuleCopyWithImpl(this._self, this._then);

  final FoodRule _self;
  final $Res Function(FoodRule) _then;

/// Create a copy of FoodRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? untilMonths = freezed,Object? sources = null,Object? text = null,}) {
  return _then(FoodRule(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleKind,untilMonths: freezed == untilMonths ? _self.untilMonths : untilMonths // ignore: cast_nullable_to_non_nullable
as int?,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<RuleSource>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodRule].
extension FoodRulePatterns on FoodRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodRule value)  $default,){
final _that = this;
switch (_that) {
case _FoodRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodRule value)?  $default,){
final _that = this;
switch (_that) {
case _FoodRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RuleKind kind,  int? untilMonths,  List<RuleSource> sources,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodRule() when $default != null:
return $default(_that.kind,_that.untilMonths,_that.sources,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RuleKind kind,  int? untilMonths,  List<RuleSource> sources,  String text)  $default,) {final _that = this;
switch (_that) {
case _FoodRule():
return $default(_that.kind,_that.untilMonths,_that.sources,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RuleKind kind,  int? untilMonths,  List<RuleSource> sources,  String text)?  $default,) {final _that = this;
switch (_that) {
case _FoodRule() when $default != null:
return $default(_that.kind,_that.untilMonths,_that.sources,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _FoodRule extends FoodRule {
  const _FoodRule({required this.kind, this.untilMonths, required  List<RuleSource> sources, required this.text}): _sources = sources,super._();
  

@override final  RuleKind kind;
/// Âge (mois révolus) à partir duquel la règle ne s'applique plus ;
/// obligatoire pour `avoid` et `prepare`, absent pour `info`.
@override final  int? untilMonths;
 final  List<RuleSource> _sources;
@override List<RuleSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override final  String text;

/// Create a copy of FoodRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodRuleCopyWith<_FoodRule> get copyWith => __$FoodRuleCopyWithImpl<_FoodRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodRule&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.untilMonths, untilMonths) || other.untilMonths == untilMonths)&&const DeepCollectionEquality().equals(other.sources, _sources)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,untilMonths,const DeepCollectionEquality().hash(_sources),text);
}

@override
String toString() {
    return 'FoodRule(kind: $kind, untilMonths: $untilMonths, sources: $sources, text: $text)';
}


}

/// @nodoc
abstract mixin class _$FoodRuleCopyWith<$Res> implements $FoodRuleCopyWith<$Res> {
  factory _$FoodRuleCopyWith(_FoodRule value, $Res Function(_FoodRule) _then) = __$FoodRuleCopyWithImpl;
@override @useResult
$Res call({
 RuleKind kind, int? untilMonths, List<RuleSource> sources, String text
});




}
/// @nodoc
class __$FoodRuleCopyWithImpl<$Res>
    implements _$FoodRuleCopyWith<$Res> {
  __$FoodRuleCopyWithImpl(this._self, this._then);

  final _FoodRule _self;
  final $Res Function(_FoodRule) _then;

/// Create a copy of FoodRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? untilMonths = freezed,Object? sources = null,Object? text = null,}) {
  return _then(_FoodRule(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleKind,untilMonths: freezed == untilMonths ? _self.untilMonths : untilMonths // ignore: cast_nullable_to_non_nullable
as int?,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<RuleSource>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
