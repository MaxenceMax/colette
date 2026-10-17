// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pediatrician_advice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdviceItem {

 String get text; List<String> get details;
/// Create a copy of AdviceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdviceItemCopyWith<AdviceItem> get copyWith => _$AdviceItemCopyWithImpl<AdviceItem>(this as AdviceItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdviceItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdviceItem&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.details, _this.details));
}


@override
int get hashCode {
  final _this = this as AdviceItem;
  return Object.hash(runtimeType,_this.text,const DeepCollectionEquality().hash(_this.details));
}

@override
String toString() {
  final _this = this as AdviceItem;
  return 'AdviceItem(text: ${_this.text}, details: ${_this.details})';
}


}

/// @nodoc
abstract mixin class $AdviceItemCopyWith<$Res>  {
  factory $AdviceItemCopyWith(AdviceItem value, $Res Function(AdviceItem) _then) = _$AdviceItemCopyWithImpl;
@useResult
$Res call({
 String text, List<String> details
});




}
/// @nodoc
class _$AdviceItemCopyWithImpl<$Res>
    implements $AdviceItemCopyWith<$Res> {
  _$AdviceItemCopyWithImpl(this._self, this._then);

  final AdviceItem _self;
  final $Res Function(AdviceItem) _then;

/// Create a copy of AdviceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? details = null,}) {
  return _then(AdviceItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AdviceItem].
extension AdviceItemPatterns on AdviceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdviceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdviceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdviceItem value)  $default,){
final _that = this;
switch (_that) {
case _AdviceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdviceItem value)?  $default,){
final _that = this;
switch (_that) {
case _AdviceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<String> details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdviceItem() when $default != null:
return $default(_that.text,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<String> details)  $default,) {final _that = this;
switch (_that) {
case _AdviceItem():
return $default(_that.text,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<String> details)?  $default,) {final _that = this;
switch (_that) {
case _AdviceItem() when $default != null:
return $default(_that.text,_that.details);case _:
  return null;

}
}

}

/// @nodoc


class _AdviceItem implements AdviceItem {
  const _AdviceItem({required this.text,  List<String> details = const <String>[]}): _details = details;
  

@override final  String text;
 final  List<String> _details;
@override@JsonKey() List<String> get details {
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_details);
}


/// Create a copy of AdviceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdviceItemCopyWith<_AdviceItem> get copyWith => __$AdviceItemCopyWithImpl<_AdviceItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdviceItem&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.details, _details));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_details));
}

@override
String toString() {
    return 'AdviceItem(text: $text, details: $details)';
}


}

/// @nodoc
abstract mixin class _$AdviceItemCopyWith<$Res> implements $AdviceItemCopyWith<$Res> {
  factory _$AdviceItemCopyWith(_AdviceItem value, $Res Function(_AdviceItem) _then) = __$AdviceItemCopyWithImpl;
@override @useResult
$Res call({
 String text, List<String> details
});




}
/// @nodoc
class __$AdviceItemCopyWithImpl<$Res>
    implements _$AdviceItemCopyWith<$Res> {
  __$AdviceItemCopyWithImpl(this._self, this._then);

  final _AdviceItem _self;
  final $Res Function(_AdviceItem) _then;

/// Create a copy of AdviceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? details = null,}) {
  return _then(_AdviceItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$AdviceStep {

 int get fromMonths; List<AdviceItem> get items;
/// Create a copy of AdviceStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdviceStepCopyWith<AdviceStep> get copyWith => _$AdviceStepCopyWithImpl<AdviceStep>(this as AdviceStep, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdviceStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdviceStep&&(identical(other.fromMonths, _this.fromMonths) || other.fromMonths == _this.fromMonths)&&const DeepCollectionEquality().equals(other.items, _this.items));
}


@override
int get hashCode {
  final _this = this as AdviceStep;
  return Object.hash(runtimeType,_this.fromMonths,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as AdviceStep;
  return 'AdviceStep(fromMonths: ${_this.fromMonths}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $AdviceStepCopyWith<$Res>  {
  factory $AdviceStepCopyWith(AdviceStep value, $Res Function(AdviceStep) _then) = _$AdviceStepCopyWithImpl;
@useResult
$Res call({
 int fromMonths, List<AdviceItem> items
});




}
/// @nodoc
class _$AdviceStepCopyWithImpl<$Res>
    implements $AdviceStepCopyWith<$Res> {
  _$AdviceStepCopyWithImpl(this._self, this._then);

  final AdviceStep _self;
  final $Res Function(AdviceStep) _then;

/// Create a copy of AdviceStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromMonths = null,Object? items = null,}) {
  return _then(AdviceStep(
fromMonths: null == fromMonths ? _self.fromMonths : fromMonths // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdviceItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [AdviceStep].
extension AdviceStepPatterns on AdviceStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdviceStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdviceStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdviceStep value)  $default,){
final _that = this;
switch (_that) {
case _AdviceStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdviceStep value)?  $default,){
final _that = this;
switch (_that) {
case _AdviceStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fromMonths,  List<AdviceItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdviceStep() when $default != null:
return $default(_that.fromMonths,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fromMonths,  List<AdviceItem> items)  $default,) {final _that = this;
switch (_that) {
case _AdviceStep():
return $default(_that.fromMonths,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fromMonths,  List<AdviceItem> items)?  $default,) {final _that = this;
switch (_that) {
case _AdviceStep() when $default != null:
return $default(_that.fromMonths,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _AdviceStep implements AdviceStep {
  const _AdviceStep({required this.fromMonths, required  List<AdviceItem> items}): _items = items;
  

@override final  int fromMonths;
 final  List<AdviceItem> _items;
@override List<AdviceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of AdviceStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdviceStepCopyWith<_AdviceStep> get copyWith => __$AdviceStepCopyWithImpl<_AdviceStep>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdviceStep&&(identical(other.fromMonths, fromMonths) || other.fromMonths == fromMonths)&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fromMonths,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'AdviceStep(fromMonths: $fromMonths, items: $items)';
}


}

/// @nodoc
abstract mixin class _$AdviceStepCopyWith<$Res> implements $AdviceStepCopyWith<$Res> {
  factory _$AdviceStepCopyWith(_AdviceStep value, $Res Function(_AdviceStep) _then) = __$AdviceStepCopyWithImpl;
@override @useResult
$Res call({
 int fromMonths, List<AdviceItem> items
});




}
/// @nodoc
class __$AdviceStepCopyWithImpl<$Res>
    implements _$AdviceStepCopyWith<$Res> {
  __$AdviceStepCopyWithImpl(this._self, this._then);

  final _AdviceStep _self;
  final $Res Function(_AdviceStep) _then;

/// Create a copy of AdviceStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromMonths = null,Object? items = null,}) {
  return _then(_AdviceStep(
fromMonths: null == fromMonths ? _self.fromMonths : fromMonths // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdviceItem>,
  ));
}


}

/// @nodoc
mixin _$PediatricianAdvice {

 String get title; String get author;/// Portée des consignes (ex. sauf lait HPLV).
 String get scope;/// Étapes triées par âge strictement croissant.
 List<AdviceStep> get steps;/// Aliments à éviter, en une phrase.
 String get avoid;
/// Create a copy of PediatricianAdvice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PediatricianAdviceCopyWith<PediatricianAdvice> get copyWith => _$PediatricianAdviceCopyWithImpl<PediatricianAdvice>(this as PediatricianAdvice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PediatricianAdvice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PediatricianAdvice&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.avoid, _this.avoid) || other.avoid == _this.avoid));
}


@override
int get hashCode {
  final _this = this as PediatricianAdvice;
  return Object.hash(runtimeType,_this.title,_this.author,_this.scope,const DeepCollectionEquality().hash(_this.steps),_this.avoid);
}

@override
String toString() {
  final _this = this as PediatricianAdvice;
  return 'PediatricianAdvice(title: ${_this.title}, author: ${_this.author}, scope: ${_this.scope}, steps: ${_this.steps}, avoid: ${_this.avoid})';
}


}

/// @nodoc
abstract mixin class $PediatricianAdviceCopyWith<$Res>  {
  factory $PediatricianAdviceCopyWith(PediatricianAdvice value, $Res Function(PediatricianAdvice) _then) = _$PediatricianAdviceCopyWithImpl;
@useResult
$Res call({
 String title, String author, String scope, List<AdviceStep> steps, String avoid
});




}
/// @nodoc
class _$PediatricianAdviceCopyWithImpl<$Res>
    implements $PediatricianAdviceCopyWith<$Res> {
  _$PediatricianAdviceCopyWithImpl(this._self, this._then);

  final PediatricianAdvice _self;
  final $Res Function(PediatricianAdvice) _then;

/// Create a copy of PediatricianAdvice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? author = null,Object? scope = null,Object? steps = null,Object? avoid = null,}) {
  return _then(PediatricianAdvice(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<AdviceStep>,avoid: null == avoid ? _self.avoid : avoid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PediatricianAdvice].
extension PediatricianAdvicePatterns on PediatricianAdvice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PediatricianAdvice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PediatricianAdvice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PediatricianAdvice value)  $default,){
final _that = this;
switch (_that) {
case _PediatricianAdvice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PediatricianAdvice value)?  $default,){
final _that = this;
switch (_that) {
case _PediatricianAdvice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String author,  String scope,  List<AdviceStep> steps,  String avoid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PediatricianAdvice() when $default != null:
return $default(_that.title,_that.author,_that.scope,_that.steps,_that.avoid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String author,  String scope,  List<AdviceStep> steps,  String avoid)  $default,) {final _that = this;
switch (_that) {
case _PediatricianAdvice():
return $default(_that.title,_that.author,_that.scope,_that.steps,_that.avoid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String author,  String scope,  List<AdviceStep> steps,  String avoid)?  $default,) {final _that = this;
switch (_that) {
case _PediatricianAdvice() when $default != null:
return $default(_that.title,_that.author,_that.scope,_that.steps,_that.avoid);case _:
  return null;

}
}

}

/// @nodoc


class _PediatricianAdvice extends PediatricianAdvice {
  const _PediatricianAdvice({required this.title, required this.author, required this.scope, required  List<AdviceStep> steps, required this.avoid}): _steps = steps,super._();
  

@override final  String title;
@override final  String author;
/// Portée des consignes (ex. sauf lait HPLV).
@override final  String scope;
/// Étapes triées par âge strictement croissant.
 final  List<AdviceStep> _steps;
/// Étapes triées par âge strictement croissant.
@override List<AdviceStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

/// Aliments à éviter, en une phrase.
@override final  String avoid;

/// Create a copy of PediatricianAdvice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PediatricianAdviceCopyWith<_PediatricianAdvice> get copyWith => __$PediatricianAdviceCopyWithImpl<_PediatricianAdvice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PediatricianAdvice&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.avoid, avoid) || other.avoid == avoid));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,author,scope,const DeepCollectionEquality().hash(_steps),avoid);
}

@override
String toString() {
    return 'PediatricianAdvice(title: $title, author: $author, scope: $scope, steps: $steps, avoid: $avoid)';
}


}

/// @nodoc
abstract mixin class _$PediatricianAdviceCopyWith<$Res> implements $PediatricianAdviceCopyWith<$Res> {
  factory _$PediatricianAdviceCopyWith(_PediatricianAdvice value, $Res Function(_PediatricianAdvice) _then) = __$PediatricianAdviceCopyWithImpl;
@override @useResult
$Res call({
 String title, String author, String scope, List<AdviceStep> steps, String avoid
});




}
/// @nodoc
class __$PediatricianAdviceCopyWithImpl<$Res>
    implements _$PediatricianAdviceCopyWith<$Res> {
  __$PediatricianAdviceCopyWithImpl(this._self, this._then);

  final _PediatricianAdvice _self;
  final $Res Function(_PediatricianAdvice) _then;

/// Create a copy of PediatricianAdvice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? author = null,Object? scope = null,Object? steps = null,Object? avoid = null,}) {
  return _then(_PediatricianAdvice(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<AdviceStep>,avoid: null == avoid ? _self.avoid : avoid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
