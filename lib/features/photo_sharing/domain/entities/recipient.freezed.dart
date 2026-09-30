// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Recipient {

 String get name; String get phone;
/// Create a copy of Recipient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipientCopyWith<Recipient> get copyWith => _$RecipientCopyWithImpl<Recipient>(this as Recipient, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Recipient;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipient&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone));
}


@override
int get hashCode {
  final _this = this as Recipient;
  return Object.hash(runtimeType,_this.name,_this.phone);
}

@override
String toString() {
  final _this = this as Recipient;
  return 'Recipient(name: ${_this.name}, phone: ${_this.phone})';
}


}

/// @nodoc
abstract mixin class $RecipientCopyWith<$Res>  {
  factory $RecipientCopyWith(Recipient value, $Res Function(Recipient) _then) = _$RecipientCopyWithImpl;
@useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class _$RecipientCopyWithImpl<$Res>
    implements $RecipientCopyWith<$Res> {
  _$RecipientCopyWithImpl(this._self, this._then);

  final Recipient _self;
  final $Res Function(Recipient) _then;

/// Create a copy of Recipient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,}) {
  return _then(Recipient(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Recipient].
extension RecipientPatterns on Recipient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipient value)  $default,){
final _that = this;
switch (_that) {
case _Recipient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipient value)?  $default,){
final _that = this;
switch (_that) {
case _Recipient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipient() when $default != null:
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone)  $default,) {final _that = this;
switch (_that) {
case _Recipient():
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone)?  $default,) {final _that = this;
switch (_that) {
case _Recipient() when $default != null:
return $default(_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc


class _Recipient implements Recipient {
  const _Recipient({required this.name, required this.phone});
  

@override final  String name;
@override final  String phone;

/// Create a copy of Recipient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipientCopyWith<_Recipient> get copyWith => __$RecipientCopyWithImpl<_Recipient>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipient&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,phone);
}

@override
String toString() {
    return 'Recipient(name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$RecipientCopyWith<$Res> implements $RecipientCopyWith<$Res> {
  factory _$RecipientCopyWith(_Recipient value, $Res Function(_Recipient) _then) = __$RecipientCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class __$RecipientCopyWithImpl<$Res>
    implements _$RecipientCopyWith<$Res> {
  __$RecipientCopyWithImpl(this._self, this._then);

  final _Recipient _self;
  final $Res Function(_Recipient) _then;

/// Create a copy of Recipient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,}) {
  return _then(_Recipient(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
