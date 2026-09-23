// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Food {

 String get id; String get name; FoodGroup get group; Set<Allergen> get allergens; List<FoodRule> get rules; bool get isCustom;/// Référencé par une dégustation mais introuvable (catalogue et aliments perso).
 bool get isUnknown;
/// Create a copy of Food
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodCopyWith<Food> get copyWith => _$FoodCopyWithImpl<Food>(this as Food, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Food;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Food&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.group, _this.group) || other.group == _this.group)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens)&&const DeepCollectionEquality().equals(other.rules, _this.rules)&&(identical(other.isCustom, _this.isCustom) || other.isCustom == _this.isCustom)&&(identical(other.isUnknown, _this.isUnknown) || other.isUnknown == _this.isUnknown));
}


@override
int get hashCode {
  final _this = this as Food;
  return Object.hash(runtimeType,_this.id,_this.name,_this.group,const DeepCollectionEquality().hash(_this.allergens),const DeepCollectionEquality().hash(_this.rules),_this.isCustom,_this.isUnknown);
}

@override
String toString() {
  final _this = this as Food;
  return 'Food(id: ${_this.id}, name: ${_this.name}, group: ${_this.group}, allergens: ${_this.allergens}, rules: ${_this.rules}, isCustom: ${_this.isCustom}, isUnknown: ${_this.isUnknown})';
}


}

/// @nodoc
abstract mixin class $FoodCopyWith<$Res>  {
  factory $FoodCopyWith(Food value, $Res Function(Food) _then) = _$FoodCopyWithImpl;
@useResult
$Res call({
 String id, String name, FoodGroup group, Set<Allergen> allergens, List<FoodRule> rules, bool isCustom, bool isUnknown
});




}
/// @nodoc
class _$FoodCopyWithImpl<$Res>
    implements $FoodCopyWith<$Res> {
  _$FoodCopyWithImpl(this._self, this._then);

  final Food _self;
  final $Res Function(Food) _then;

/// Create a copy of Food
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? group = null,Object? allergens = null,Object? rules = null,Object? isCustom = null,Object? isUnknown = null,}) {
  return _then(Food(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as FoodGroup,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<FoodRule>,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isUnknown: null == isUnknown ? _self.isUnknown : isUnknown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Food].
extension FoodPatterns on Food {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Food value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Food() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Food value)  $default,){
final _that = this;
switch (_that) {
case _Food():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Food value)?  $default,){
final _that = this;
switch (_that) {
case _Food() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  FoodGroup group,  Set<Allergen> allergens,  List<FoodRule> rules,  bool isCustom,  bool isUnknown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Food() when $default != null:
return $default(_that.id,_that.name,_that.group,_that.allergens,_that.rules,_that.isCustom,_that.isUnknown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  FoodGroup group,  Set<Allergen> allergens,  List<FoodRule> rules,  bool isCustom,  bool isUnknown)  $default,) {final _that = this;
switch (_that) {
case _Food():
return $default(_that.id,_that.name,_that.group,_that.allergens,_that.rules,_that.isCustom,_that.isUnknown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  FoodGroup group,  Set<Allergen> allergens,  List<FoodRule> rules,  bool isCustom,  bool isUnknown)?  $default,) {final _that = this;
switch (_that) {
case _Food() when $default != null:
return $default(_that.id,_that.name,_that.group,_that.allergens,_that.rules,_that.isCustom,_that.isUnknown);case _:
  return null;

}
}

}

/// @nodoc


class _Food extends Food {
  const _Food({required this.id, required this.name, required this.group,  Set<Allergen> allergens = const <Allergen>{},  List<FoodRule> rules = const <FoodRule>[], this.isCustom = false, this.isUnknown = false}): _allergens = allergens,_rules = rules,super._();
  

@override final  String id;
@override final  String name;
@override final  FoodGroup group;
 final  Set<Allergen> _allergens;
@override@JsonKey() Set<Allergen> get allergens {
  if (_allergens is EqualUnmodifiableSetView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_allergens);
}

 final  List<FoodRule> _rules;
@override@JsonKey() List<FoodRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

@override@JsonKey() final  bool isCustom;
/// Référencé par une dégustation mais introuvable (catalogue et aliments perso).
@override@JsonKey() final  bool isUnknown;

/// Create a copy of Food
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodCopyWith<_Food> get copyWith => __$FoodCopyWithImpl<_Food>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Food&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other.allergens, _allergens)&&const DeepCollectionEquality().equals(other.rules, _rules)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isUnknown, isUnknown) || other.isUnknown == isUnknown));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,group,const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_rules),isCustom,isUnknown);
}

@override
String toString() {
    return 'Food(id: $id, name: $name, group: $group, allergens: $allergens, rules: $rules, isCustom: $isCustom, isUnknown: $isUnknown)';
}


}

/// @nodoc
abstract mixin class _$FoodCopyWith<$Res> implements $FoodCopyWith<$Res> {
  factory _$FoodCopyWith(_Food value, $Res Function(_Food) _then) = __$FoodCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, FoodGroup group, Set<Allergen> allergens, List<FoodRule> rules, bool isCustom, bool isUnknown
});




}
/// @nodoc
class __$FoodCopyWithImpl<$Res>
    implements _$FoodCopyWith<$Res> {
  __$FoodCopyWithImpl(this._self, this._then);

  final _Food _self;
  final $Res Function(_Food) _then;

/// Create a copy of Food
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? group = null,Object? allergens = null,Object? rules = null,Object? isCustom = null,Object? isUnknown = null,}) {
  return _then(_Food(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as FoodGroup,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<FoodRule>,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isUnknown: null == isUnknown ? _self.isUnknown : isUnknown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
