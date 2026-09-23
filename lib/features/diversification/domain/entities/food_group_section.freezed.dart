// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_group_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodGroupSection {

 FoodGroup get group; List<Food> get foods;
/// Create a copy of FoodGroupSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodGroupSectionCopyWith<FoodGroupSection> get copyWith => _$FoodGroupSectionCopyWithImpl<FoodGroupSection>(this as FoodGroupSection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FoodGroupSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodGroupSection&&(identical(other.group, _this.group) || other.group == _this.group)&&const DeepCollectionEquality().equals(other.foods, _this.foods));
}


@override
int get hashCode {
  final _this = this as FoodGroupSection;
  return Object.hash(runtimeType,_this.group,const DeepCollectionEquality().hash(_this.foods));
}

@override
String toString() {
  final _this = this as FoodGroupSection;
  return 'FoodGroupSection(group: ${_this.group}, foods: ${_this.foods})';
}


}

/// @nodoc
abstract mixin class $FoodGroupSectionCopyWith<$Res>  {
  factory $FoodGroupSectionCopyWith(FoodGroupSection value, $Res Function(FoodGroupSection) _then) = _$FoodGroupSectionCopyWithImpl;
@useResult
$Res call({
 FoodGroup group, List<Food> foods
});




}
/// @nodoc
class _$FoodGroupSectionCopyWithImpl<$Res>
    implements $FoodGroupSectionCopyWith<$Res> {
  _$FoodGroupSectionCopyWithImpl(this._self, this._then);

  final FoodGroupSection _self;
  final $Res Function(FoodGroupSection) _then;

/// Create a copy of FoodGroupSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? foods = null,}) {
  return _then(FoodGroupSection(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as FoodGroup,foods: null == foods ? _self.foods : foods // ignore: cast_nullable_to_non_nullable
as List<Food>,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodGroupSection].
extension FoodGroupSectionPatterns on FoodGroupSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodGroupSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodGroupSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodGroupSection value)  $default,){
final _that = this;
switch (_that) {
case _FoodGroupSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodGroupSection value)?  $default,){
final _that = this;
switch (_that) {
case _FoodGroupSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FoodGroup group,  List<Food> foods)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodGroupSection() when $default != null:
return $default(_that.group,_that.foods);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FoodGroup group,  List<Food> foods)  $default,) {final _that = this;
switch (_that) {
case _FoodGroupSection():
return $default(_that.group,_that.foods);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FoodGroup group,  List<Food> foods)?  $default,) {final _that = this;
switch (_that) {
case _FoodGroupSection() when $default != null:
return $default(_that.group,_that.foods);case _:
  return null;

}
}

}

/// @nodoc


class _FoodGroupSection implements FoodGroupSection {
  const _FoodGroupSection({required this.group, required  List<Food> foods}): _foods = foods;
  

@override final  FoodGroup group;
 final  List<Food> _foods;
@override List<Food> get foods {
  if (_foods is EqualUnmodifiableListView) return _foods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foods);
}


/// Create a copy of FoodGroupSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodGroupSectionCopyWith<_FoodGroupSection> get copyWith => __$FoodGroupSectionCopyWithImpl<_FoodGroupSection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodGroupSection&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other.foods, _foods));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group,const DeepCollectionEquality().hash(_foods));
}

@override
String toString() {
    return 'FoodGroupSection(group: $group, foods: $foods)';
}


}

/// @nodoc
abstract mixin class _$FoodGroupSectionCopyWith<$Res> implements $FoodGroupSectionCopyWith<$Res> {
  factory _$FoodGroupSectionCopyWith(_FoodGroupSection value, $Res Function(_FoodGroupSection) _then) = __$FoodGroupSectionCopyWithImpl;
@override @useResult
$Res call({
 FoodGroup group, List<Food> foods
});




}
/// @nodoc
class __$FoodGroupSectionCopyWithImpl<$Res>
    implements _$FoodGroupSectionCopyWith<$Res> {
  __$FoodGroupSectionCopyWithImpl(this._self, this._then);

  final _FoodGroupSection _self;
  final $Res Function(_FoodGroupSection) _then;

/// Create a copy of FoodGroupSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? foods = null,}) {
  return _then(_FoodGroupSection(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as FoodGroup,foods: null == foods ? _self._foods : foods // ignore: cast_nullable_to_non_nullable
as List<Food>,
  ));
}


}

// dart format on
