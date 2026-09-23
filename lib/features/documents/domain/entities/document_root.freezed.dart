// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_root.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentRoot {

 String get name;
/// Create a copy of DocumentRoot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentRootCopyWith<DocumentRoot> get copyWith => _$DocumentRootCopyWithImpl<DocumentRoot>(this as DocumentRoot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DocumentRoot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentRoot&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as DocumentRoot;
  return Object.hash(runtimeType,_this.name);
}

@override
String toString() {
  final _this = this as DocumentRoot;
  return 'DocumentRoot(name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $DocumentRootCopyWith<$Res>  {
  factory $DocumentRootCopyWith(DocumentRoot value, $Res Function(DocumentRoot) _then) = _$DocumentRootCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$DocumentRootCopyWithImpl<$Res>
    implements $DocumentRootCopyWith<$Res> {
  _$DocumentRootCopyWithImpl(this._self, this._then);

  final DocumentRoot _self;
  final $Res Function(DocumentRoot) _then;

/// Create a copy of DocumentRoot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(DocumentRoot(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentRoot].
extension DocumentRootPatterns on DocumentRoot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentRoot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentRoot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentRoot value)  $default,){
final _that = this;
switch (_that) {
case _DocumentRoot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentRoot value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentRoot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentRoot() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _DocumentRoot():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _DocumentRoot() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentRoot implements DocumentRoot {
  const _DocumentRoot({required this.name});
  

@override final  String name;

/// Create a copy of DocumentRoot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentRootCopyWith<_DocumentRoot> get copyWith => __$DocumentRootCopyWithImpl<_DocumentRoot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentRoot&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name);
}

@override
String toString() {
    return 'DocumentRoot(name: $name)';
}


}

/// @nodoc
abstract mixin class _$DocumentRootCopyWith<$Res> implements $DocumentRootCopyWith<$Res> {
  factory _$DocumentRootCopyWith(_DocumentRoot value, $Res Function(_DocumentRoot) _then) = __$DocumentRootCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$DocumentRootCopyWithImpl<$Res>
    implements _$DocumentRootCopyWith<$Res> {
  __$DocumentRootCopyWithImpl(this._self, this._then);

  final _DocumentRoot _self;
  final $Res Function(_DocumentRoot) _then;

/// Create a copy of DocumentRoot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_DocumentRoot(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
