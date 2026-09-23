// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retry_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RetryItem {

 Food get food; Liking get lastLiking; int get tastingCount;
/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetryItemCopyWith<RetryItem> get copyWith => _$RetryItemCopyWithImpl<RetryItem>(this as RetryItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RetryItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetryItem&&(identical(other.food, _this.food) || other.food == _this.food)&&(identical(other.lastLiking, _this.lastLiking) || other.lastLiking == _this.lastLiking)&&(identical(other.tastingCount, _this.tastingCount) || other.tastingCount == _this.tastingCount));
}


@override
int get hashCode {
  final _this = this as RetryItem;
  return Object.hash(runtimeType,_this.food,_this.lastLiking,_this.tastingCount);
}

@override
String toString() {
  final _this = this as RetryItem;
  return 'RetryItem(food: ${_this.food}, lastLiking: ${_this.lastLiking}, tastingCount: ${_this.tastingCount})';
}


}

/// @nodoc
abstract mixin class $RetryItemCopyWith<$Res>  {
  factory $RetryItemCopyWith(RetryItem value, $Res Function(RetryItem) _then) = _$RetryItemCopyWithImpl;
@useResult
$Res call({
 Food food, Liking lastLiking, int tastingCount
});


$FoodCopyWith<$Res> get food;

}
/// @nodoc
class _$RetryItemCopyWithImpl<$Res>
    implements $RetryItemCopyWith<$Res> {
  _$RetryItemCopyWithImpl(this._self, this._then);

  final RetryItem _self;
  final $Res Function(RetryItem) _then;

/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? food = null,Object? lastLiking = null,Object? tastingCount = null,}) {
  return _then(RetryItem(
food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as Food,lastLiking: null == lastLiking ? _self.lastLiking : lastLiking // ignore: cast_nullable_to_non_nullable
as Liking,tastingCount: null == tastingCount ? _self.tastingCount : tastingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodCopyWith<$Res> get food {
  
  return $FoodCopyWith<$Res>(_self.food, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}


/// Adds pattern-matching-related methods to [RetryItem].
extension RetryItemPatterns on RetryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetryItem value)  $default,){
final _that = this;
switch (_that) {
case _RetryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetryItem value)?  $default,){
final _that = this;
switch (_that) {
case _RetryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Food food,  Liking lastLiking,  int tastingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetryItem() when $default != null:
return $default(_that.food,_that.lastLiking,_that.tastingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Food food,  Liking lastLiking,  int tastingCount)  $default,) {final _that = this;
switch (_that) {
case _RetryItem():
return $default(_that.food,_that.lastLiking,_that.tastingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Food food,  Liking lastLiking,  int tastingCount)?  $default,) {final _that = this;
switch (_that) {
case _RetryItem() when $default != null:
return $default(_that.food,_that.lastLiking,_that.tastingCount);case _:
  return null;

}
}

}

/// @nodoc


class _RetryItem implements RetryItem {
  const _RetryItem({required this.food, required this.lastLiking, required this.tastingCount});
  

@override final  Food food;
@override final  Liking lastLiking;
@override final  int tastingCount;

/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetryItemCopyWith<_RetryItem> get copyWith => __$RetryItemCopyWithImpl<_RetryItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetryItem&&(identical(other.food, food) || other.food == food)&&(identical(other.lastLiking, lastLiking) || other.lastLiking == lastLiking)&&(identical(other.tastingCount, tastingCount) || other.tastingCount == tastingCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,food,lastLiking,tastingCount);
}

@override
String toString() {
    return 'RetryItem(food: $food, lastLiking: $lastLiking, tastingCount: $tastingCount)';
}


}

/// @nodoc
abstract mixin class _$RetryItemCopyWith<$Res> implements $RetryItemCopyWith<$Res> {
  factory _$RetryItemCopyWith(_RetryItem value, $Res Function(_RetryItem) _then) = __$RetryItemCopyWithImpl;
@override @useResult
$Res call({
 Food food, Liking lastLiking, int tastingCount
});


@override $FoodCopyWith<$Res> get food;

}
/// @nodoc
class __$RetryItemCopyWithImpl<$Res>
    implements _$RetryItemCopyWith<$Res> {
  __$RetryItemCopyWithImpl(this._self, this._then);

  final _RetryItem _self;
  final $Res Function(_RetryItem) _then;

/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? food = null,Object? lastLiking = null,Object? tastingCount = null,}) {
  return _then(_RetryItem(
food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as Food,lastLiking: null == lastLiking ? _self.lastLiking : lastLiking // ignore: cast_nullable_to_non_nullable
as Liking,tastingCount: null == tastingCount ? _self.tastingCount : tastingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RetryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodCopyWith<$Res> get food {
  
  return $FoodCopyWith<$Res>(_self.food, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}

// dart format on
