// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_choice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CalendarChoice {

 String get id; String get title;
/// Create a copy of CalendarChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarChoiceCopyWith<CalendarChoice> get copyWith => _$CalendarChoiceCopyWithImpl<CalendarChoice>(this as CalendarChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CalendarChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarChoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title));
}


@override
int get hashCode {
  final _this = this as CalendarChoice;
  return Object.hash(runtimeType,_this.id,_this.title);
}

@override
String toString() {
  final _this = this as CalendarChoice;
  return 'CalendarChoice(id: ${_this.id}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $CalendarChoiceCopyWith<$Res>  {
  factory $CalendarChoiceCopyWith(CalendarChoice value, $Res Function(CalendarChoice) _then) = _$CalendarChoiceCopyWithImpl;
@useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class _$CalendarChoiceCopyWithImpl<$Res>
    implements $CalendarChoiceCopyWith<$Res> {
  _$CalendarChoiceCopyWithImpl(this._self, this._then);

  final CalendarChoice _self;
  final $Res Function(CalendarChoice) _then;

/// Create a copy of CalendarChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(CalendarChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarChoice].
extension CalendarChoicePatterns on CalendarChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarChoice value)  $default,){
final _that = this;
switch (_that) {
case _CalendarChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarChoice value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarChoice() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title)  $default,) {final _that = this;
switch (_that) {
case _CalendarChoice():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title)?  $default,) {final _that = this;
switch (_that) {
case _CalendarChoice() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarChoice implements CalendarChoice {
  const _CalendarChoice({required this.id, required this.title});
  

@override final  String id;
@override final  String title;

/// Create a copy of CalendarChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarChoiceCopyWith<_CalendarChoice> get copyWith => __$CalendarChoiceCopyWithImpl<_CalendarChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title);
}

@override
String toString() {
    return 'CalendarChoice(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CalendarChoiceCopyWith<$Res> implements $CalendarChoiceCopyWith<$Res> {
  factory _$CalendarChoiceCopyWith(_CalendarChoice value, $Res Function(_CalendarChoice) _then) = __$CalendarChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class __$CalendarChoiceCopyWithImpl<$Res>
    implements _$CalendarChoiceCopyWith<$Res> {
  __$CalendarChoiceCopyWithImpl(this._self, this._then);

  final _CalendarChoice _self;
  final $Res Function(_CalendarChoice) _then;

/// Create a copy of CalendarChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_CalendarChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
