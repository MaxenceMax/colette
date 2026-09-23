// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodFilter {

 String get query; CatalogMode get mode; Allergen? get allergen;
/// Create a copy of FoodFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodFilterCopyWith<FoodFilter> get copyWith => _$FoodFilterCopyWithImpl<FoodFilter>(this as FoodFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FoodFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodFilter&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.allergen, _this.allergen) || other.allergen == _this.allergen));
}


@override
int get hashCode {
  final _this = this as FoodFilter;
  return Object.hash(runtimeType,_this.query,_this.mode,_this.allergen);
}

@override
String toString() {
  final _this = this as FoodFilter;
  return 'FoodFilter(query: ${_this.query}, mode: ${_this.mode}, allergen: ${_this.allergen})';
}


}

/// @nodoc
abstract mixin class $FoodFilterCopyWith<$Res>  {
  factory $FoodFilterCopyWith(FoodFilter value, $Res Function(FoodFilter) _then) = _$FoodFilterCopyWithImpl;
@useResult
$Res call({
 String query, CatalogMode mode, Allergen? allergen
});




}
/// @nodoc
class _$FoodFilterCopyWithImpl<$Res>
    implements $FoodFilterCopyWith<$Res> {
  _$FoodFilterCopyWithImpl(this._self, this._then);

  final FoodFilter _self;
  final $Res Function(FoodFilter) _then;

/// Create a copy of FoodFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? mode = null,Object? allergen = freezed,}) {
  return _then(FoodFilter(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CatalogMode,allergen: freezed == allergen ? _self.allergen : allergen // ignore: cast_nullable_to_non_nullable
as Allergen?,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodFilter].
extension FoodFilterPatterns on FoodFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodFilter value)  $default,){
final _that = this;
switch (_that) {
case _FoodFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodFilter value)?  $default,){
final _that = this;
switch (_that) {
case _FoodFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  CatalogMode mode,  Allergen? allergen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodFilter() when $default != null:
return $default(_that.query,_that.mode,_that.allergen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  CatalogMode mode,  Allergen? allergen)  $default,) {final _that = this;
switch (_that) {
case _FoodFilter():
return $default(_that.query,_that.mode,_that.allergen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  CatalogMode mode,  Allergen? allergen)?  $default,) {final _that = this;
switch (_that) {
case _FoodFilter() when $default != null:
return $default(_that.query,_that.mode,_that.allergen);case _:
  return null;

}
}

}

/// @nodoc


class _FoodFilter implements FoodFilter {
  const _FoodFilter({this.query = '', this.mode = CatalogMode.all, this.allergen});
  

@override@JsonKey() final  String query;
@override@JsonKey() final  CatalogMode mode;
@override final  Allergen? allergen;

/// Create a copy of FoodFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodFilterCopyWith<_FoodFilter> get copyWith => __$FoodFilterCopyWithImpl<_FoodFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.allergen, allergen) || other.allergen == allergen));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,mode,allergen);
}

@override
String toString() {
    return 'FoodFilter(query: $query, mode: $mode, allergen: $allergen)';
}


}

/// @nodoc
abstract mixin class _$FoodFilterCopyWith<$Res> implements $FoodFilterCopyWith<$Res> {
  factory _$FoodFilterCopyWith(_FoodFilter value, $Res Function(_FoodFilter) _then) = __$FoodFilterCopyWithImpl;
@override @useResult
$Res call({
 String query, CatalogMode mode, Allergen? allergen
});




}
/// @nodoc
class __$FoodFilterCopyWithImpl<$Res>
    implements _$FoodFilterCopyWith<$Res> {
  __$FoodFilterCopyWithImpl(this._self, this._then);

  final _FoodFilter _self;
  final $Res Function(_FoodFilter) _then;

/// Create a copy of FoodFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? mode = null,Object? allergen = freezed,}) {
  return _then(_FoodFilter(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CatalogMode,allergen: freezed == allergen ? _self.allergen : allergen // ignore: cast_nullable_to_non_nullable
as Allergen?,
  ));
}


}

// dart format on
