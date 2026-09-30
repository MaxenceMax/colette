// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'broadcast_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BroadcastList {

 String get id; String get name; List<Recipient> get recipients;
/// Create a copy of BroadcastList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BroadcastListCopyWith<BroadcastList> get copyWith => _$BroadcastListCopyWithImpl<BroadcastList>(this as BroadcastList, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BroadcastList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BroadcastList&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.recipients, _this.recipients));
}


@override
int get hashCode {
  final _this = this as BroadcastList;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.recipients));
}

@override
String toString() {
  final _this = this as BroadcastList;
  return 'BroadcastList(id: ${_this.id}, name: ${_this.name}, recipients: ${_this.recipients})';
}


}

/// @nodoc
abstract mixin class $BroadcastListCopyWith<$Res>  {
  factory $BroadcastListCopyWith(BroadcastList value, $Res Function(BroadcastList) _then) = _$BroadcastListCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<Recipient> recipients
});




}
/// @nodoc
class _$BroadcastListCopyWithImpl<$Res>
    implements $BroadcastListCopyWith<$Res> {
  _$BroadcastListCopyWithImpl(this._self, this._then);

  final BroadcastList _self;
  final $Res Function(BroadcastList) _then;

/// Create a copy of BroadcastList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? recipients = null,}) {
  return _then(BroadcastList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as List<Recipient>,
  ));
}

}


/// Adds pattern-matching-related methods to [BroadcastList].
extension BroadcastListPatterns on BroadcastList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BroadcastList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BroadcastList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BroadcastList value)  $default,){
final _that = this;
switch (_that) {
case _BroadcastList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BroadcastList value)?  $default,){
final _that = this;
switch (_that) {
case _BroadcastList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<Recipient> recipients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BroadcastList() when $default != null:
return $default(_that.id,_that.name,_that.recipients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<Recipient> recipients)  $default,) {final _that = this;
switch (_that) {
case _BroadcastList():
return $default(_that.id,_that.name,_that.recipients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<Recipient> recipients)?  $default,) {final _that = this;
switch (_that) {
case _BroadcastList() when $default != null:
return $default(_that.id,_that.name,_that.recipients);case _:
  return null;

}
}

}

/// @nodoc


class _BroadcastList extends BroadcastList {
  const _BroadcastList({required this.id, required this.name, required  List<Recipient> recipients}): _recipients = recipients,super._();
  

@override final  String id;
@override final  String name;
 final  List<Recipient> _recipients;
@override List<Recipient> get recipients {
  if (_recipients is EqualUnmodifiableListView) return _recipients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipients);
}


/// Create a copy of BroadcastList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BroadcastListCopyWith<_BroadcastList> get copyWith => __$BroadcastListCopyWithImpl<_BroadcastList>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BroadcastList&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.recipients, _recipients));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_recipients));
}

@override
String toString() {
    return 'BroadcastList(id: $id, name: $name, recipients: $recipients)';
}


}

/// @nodoc
abstract mixin class _$BroadcastListCopyWith<$Res> implements $BroadcastListCopyWith<$Res> {
  factory _$BroadcastListCopyWith(_BroadcastList value, $Res Function(_BroadcastList) _then) = __$BroadcastListCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<Recipient> recipients
});




}
/// @nodoc
class __$BroadcastListCopyWithImpl<$Res>
    implements _$BroadcastListCopyWith<$Res> {
  __$BroadcastListCopyWithImpl(this._self, this._then);

  final _BroadcastList _self;
  final $Res Function(_BroadcastList) _then;

/// Create a copy of BroadcastList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? recipients = null,}) {
  return _then(_BroadcastList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,recipients: null == recipients ? _self._recipients : recipients // ignore: cast_nullable_to_non_nullable
as List<Recipient>,
  ));
}


}

// dart format on
