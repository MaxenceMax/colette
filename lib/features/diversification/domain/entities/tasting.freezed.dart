// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tasting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Tasting {

 String get id; String get foodId; DateTime get at; Liking? get liking; bool get hadReaction; String? get note;
/// Create a copy of Tasting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TastingCopyWith<Tasting> get copyWith => _$TastingCopyWithImpl<Tasting>(this as Tasting, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Tasting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tasting&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.foodId, _this.foodId) || other.foodId == _this.foodId)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.liking, _this.liking) || other.liking == _this.liking)&&(identical(other.hadReaction, _this.hadReaction) || other.hadReaction == _this.hadReaction)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as Tasting;
  return Object.hash(runtimeType,_this.id,_this.foodId,_this.at,_this.liking,_this.hadReaction,_this.note);
}

@override
String toString() {
  final _this = this as Tasting;
  return 'Tasting(id: ${_this.id}, foodId: ${_this.foodId}, at: ${_this.at}, liking: ${_this.liking}, hadReaction: ${_this.hadReaction}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $TastingCopyWith<$Res>  {
  factory $TastingCopyWith(Tasting value, $Res Function(Tasting) _then) = _$TastingCopyWithImpl;
@useResult
$Res call({
 String id, String foodId, DateTime at, Liking? liking, bool hadReaction, String? note
});




}
/// @nodoc
class _$TastingCopyWithImpl<$Res>
    implements $TastingCopyWith<$Res> {
  _$TastingCopyWithImpl(this._self, this._then);

  final Tasting _self;
  final $Res Function(Tasting) _then;

/// Create a copy of Tasting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? foodId = null,Object? at = null,Object? liking = freezed,Object? hadReaction = null,Object? note = freezed,}) {
  return _then(Tasting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,foodId: null == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,liking: freezed == liking ? _self.liking : liking // ignore: cast_nullable_to_non_nullable
as Liking?,hadReaction: null == hadReaction ? _self.hadReaction : hadReaction // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Tasting].
extension TastingPatterns on Tasting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tasting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tasting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tasting value)  $default,){
final _that = this;
switch (_that) {
case _Tasting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tasting value)?  $default,){
final _that = this;
switch (_that) {
case _Tasting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String foodId,  DateTime at,  Liking? liking,  bool hadReaction,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tasting() when $default != null:
return $default(_that.id,_that.foodId,_that.at,_that.liking,_that.hadReaction,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String foodId,  DateTime at,  Liking? liking,  bool hadReaction,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Tasting():
return $default(_that.id,_that.foodId,_that.at,_that.liking,_that.hadReaction,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String foodId,  DateTime at,  Liking? liking,  bool hadReaction,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Tasting() when $default != null:
return $default(_that.id,_that.foodId,_that.at,_that.liking,_that.hadReaction,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _Tasting implements Tasting {
  const _Tasting({required this.id, required this.foodId, required this.at, this.liking, this.hadReaction = false, this.note});
  

@override final  String id;
@override final  String foodId;
@override final  DateTime at;
@override final  Liking? liking;
@override@JsonKey() final  bool hadReaction;
@override final  String? note;

/// Create a copy of Tasting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TastingCopyWith<_Tasting> get copyWith => __$TastingCopyWithImpl<_Tasting>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tasting&&(identical(other.id, id) || other.id == id)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.at, at) || other.at == at)&&(identical(other.liking, liking) || other.liking == liking)&&(identical(other.hadReaction, hadReaction) || other.hadReaction == hadReaction)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,foodId,at,liking,hadReaction,note);
}

@override
String toString() {
    return 'Tasting(id: $id, foodId: $foodId, at: $at, liking: $liking, hadReaction: $hadReaction, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TastingCopyWith<$Res> implements $TastingCopyWith<$Res> {
  factory _$TastingCopyWith(_Tasting value, $Res Function(_Tasting) _then) = __$TastingCopyWithImpl;
@override @useResult
$Res call({
 String id, String foodId, DateTime at, Liking? liking, bool hadReaction, String? note
});




}
/// @nodoc
class __$TastingCopyWithImpl<$Res>
    implements _$TastingCopyWith<$Res> {
  __$TastingCopyWithImpl(this._self, this._then);

  final _Tasting _self;
  final $Res Function(_Tasting) _then;

/// Create a copy of Tasting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? foodId = null,Object? at = null,Object? liking = freezed,Object? hadReaction = null,Object? note = freezed,}) {
  return _then(_Tasting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,foodId: null == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,liking: freezed == liking ? _self.liking : liking // ignore: cast_nullable_to_non_nullable
as Liking?,hadReaction: null == hadReaction ? _self.hadReaction : hadReaction // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
