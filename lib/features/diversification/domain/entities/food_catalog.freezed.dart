// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SourceRef {

 String get label; String get url;
/// Create a copy of SourceRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceRefCopyWith<SourceRef> get copyWith => _$SourceRefCopyWithImpl<SourceRef>(this as SourceRef, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SourceRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceRef&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.url, _this.url) || other.url == _this.url));
}


@override
int get hashCode {
  final _this = this as SourceRef;
  return Object.hash(runtimeType,_this.label,_this.url);
}

@override
String toString() {
  final _this = this as SourceRef;
  return 'SourceRef(label: ${_this.label}, url: ${_this.url})';
}


}

/// @nodoc
abstract mixin class $SourceRefCopyWith<$Res>  {
  factory $SourceRefCopyWith(SourceRef value, $Res Function(SourceRef) _then) = _$SourceRefCopyWithImpl;
@useResult
$Res call({
 String label, String url
});




}
/// @nodoc
class _$SourceRefCopyWithImpl<$Res>
    implements $SourceRefCopyWith<$Res> {
  _$SourceRefCopyWithImpl(this._self, this._then);

  final SourceRef _self;
  final $Res Function(SourceRef) _then;

/// Create a copy of SourceRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? url = null,}) {
  return _then(SourceRef(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceRef].
extension SourceRefPatterns on SourceRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceRef value)  $default,){
final _that = this;
switch (_that) {
case _SourceRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceRef value)?  $default,){
final _that = this;
switch (_that) {
case _SourceRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceRef() when $default != null:
return $default(_that.label,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String url)  $default,) {final _that = this;
switch (_that) {
case _SourceRef():
return $default(_that.label,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SourceRef() when $default != null:
return $default(_that.label,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _SourceRef implements SourceRef {
  const _SourceRef({required this.label, required this.url});
  

@override final  String label;
@override final  String url;

/// Create a copy of SourceRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceRefCopyWith<_SourceRef> get copyWith => __$SourceRefCopyWithImpl<_SourceRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceRef&&(identical(other.label, label) || other.label == label)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,url);
}

@override
String toString() {
    return 'SourceRef(label: $label, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SourceRefCopyWith<$Res> implements $SourceRefCopyWith<$Res> {
  factory _$SourceRefCopyWith(_SourceRef value, $Res Function(_SourceRef) _then) = __$SourceRefCopyWithImpl;
@override @useResult
$Res call({
 String label, String url
});




}
/// @nodoc
class __$SourceRefCopyWithImpl<$Res>
    implements _$SourceRefCopyWith<$Res> {
  __$SourceRefCopyWithImpl(this._self, this._then);

  final _SourceRef _self;
  final $Res Function(_SourceRef) _then;

/// Create a copy of SourceRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? url = null,}) {
  return _then(_SourceRef(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GuideItem {

 String get text; List<RuleSource> get sources;
/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideItemCopyWith<GuideItem> get copyWith => _$GuideItemCopyWithImpl<GuideItem>(this as GuideItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GuideItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideItem&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.sources, _this.sources));
}


@override
int get hashCode {
  final _this = this as GuideItem;
  return Object.hash(runtimeType,_this.text,const DeepCollectionEquality().hash(_this.sources));
}

@override
String toString() {
  final _this = this as GuideItem;
  return 'GuideItem(text: ${_this.text}, sources: ${_this.sources})';
}


}

/// @nodoc
abstract mixin class $GuideItemCopyWith<$Res>  {
  factory $GuideItemCopyWith(GuideItem value, $Res Function(GuideItem) _then) = _$GuideItemCopyWithImpl;
@useResult
$Res call({
 String text, List<RuleSource> sources
});




}
/// @nodoc
class _$GuideItemCopyWithImpl<$Res>
    implements $GuideItemCopyWith<$Res> {
  _$GuideItemCopyWithImpl(this._self, this._then);

  final GuideItem _self;
  final $Res Function(GuideItem) _then;

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? sources = null,}) {
  return _then(GuideItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<RuleSource>,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideItem].
extension GuideItemPatterns on GuideItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideItem value)  $default,){
final _that = this;
switch (_that) {
case _GuideItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideItem value)?  $default,){
final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<RuleSource> sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
return $default(_that.text,_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<RuleSource> sources)  $default,) {final _that = this;
switch (_that) {
case _GuideItem():
return $default(_that.text,_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<RuleSource> sources)?  $default,) {final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
return $default(_that.text,_that.sources);case _:
  return null;

}
}

}

/// @nodoc


class _GuideItem implements GuideItem {
  const _GuideItem({required this.text, required  List<RuleSource> sources}): _sources = sources;
  

@override final  String text;
 final  List<RuleSource> _sources;
@override List<RuleSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideItemCopyWith<_GuideItem> get copyWith => __$GuideItemCopyWithImpl<_GuideItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideItem&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.sources, _sources));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_sources));
}

@override
String toString() {
    return 'GuideItem(text: $text, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$GuideItemCopyWith<$Res> implements $GuideItemCopyWith<$Res> {
  factory _$GuideItemCopyWith(_GuideItem value, $Res Function(_GuideItem) _then) = __$GuideItemCopyWithImpl;
@override @useResult
$Res call({
 String text, List<RuleSource> sources
});




}
/// @nodoc
class __$GuideItemCopyWithImpl<$Res>
    implements _$GuideItemCopyWith<$Res> {
  __$GuideItemCopyWithImpl(this._self, this._then);

  final _GuideItem _self;
  final $Res Function(_GuideItem) _then;

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? sources = null,}) {
  return _then(_GuideItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<RuleSource>,
  ));
}


}

/// @nodoc
mixin _$PhaseGuide {

 String get mealsSummary; List<GuideItem> get items;
/// Create a copy of PhaseGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhaseGuideCopyWith<PhaseGuide> get copyWith => _$PhaseGuideCopyWithImpl<PhaseGuide>(this as PhaseGuide, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PhaseGuide;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhaseGuide&&(identical(other.mealsSummary, _this.mealsSummary) || other.mealsSummary == _this.mealsSummary)&&const DeepCollectionEquality().equals(other.items, _this.items));
}


@override
int get hashCode {
  final _this = this as PhaseGuide;
  return Object.hash(runtimeType,_this.mealsSummary,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as PhaseGuide;
  return 'PhaseGuide(mealsSummary: ${_this.mealsSummary}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $PhaseGuideCopyWith<$Res>  {
  factory $PhaseGuideCopyWith(PhaseGuide value, $Res Function(PhaseGuide) _then) = _$PhaseGuideCopyWithImpl;
@useResult
$Res call({
 String mealsSummary, List<GuideItem> items
});




}
/// @nodoc
class _$PhaseGuideCopyWithImpl<$Res>
    implements $PhaseGuideCopyWith<$Res> {
  _$PhaseGuideCopyWithImpl(this._self, this._then);

  final PhaseGuide _self;
  final $Res Function(PhaseGuide) _then;

/// Create a copy of PhaseGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mealsSummary = null,Object? items = null,}) {
  return _then(PhaseGuide(
mealsSummary: null == mealsSummary ? _self.mealsSummary : mealsSummary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [PhaseGuide].
extension PhaseGuidePatterns on PhaseGuide {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhaseGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhaseGuide() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhaseGuide value)  $default,){
final _that = this;
switch (_that) {
case _PhaseGuide():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhaseGuide value)?  $default,){
final _that = this;
switch (_that) {
case _PhaseGuide() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mealsSummary,  List<GuideItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhaseGuide() when $default != null:
return $default(_that.mealsSummary,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mealsSummary,  List<GuideItem> items)  $default,) {final _that = this;
switch (_that) {
case _PhaseGuide():
return $default(_that.mealsSummary,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mealsSummary,  List<GuideItem> items)?  $default,) {final _that = this;
switch (_that) {
case _PhaseGuide() when $default != null:
return $default(_that.mealsSummary,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _PhaseGuide implements PhaseGuide {
  const _PhaseGuide({required this.mealsSummary, required  List<GuideItem> items}): _items = items;
  

@override final  String mealsSummary;
 final  List<GuideItem> _items;
@override List<GuideItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PhaseGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhaseGuideCopyWith<_PhaseGuide> get copyWith => __$PhaseGuideCopyWithImpl<_PhaseGuide>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhaseGuide&&(identical(other.mealsSummary, mealsSummary) || other.mealsSummary == mealsSummary)&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mealsSummary,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'PhaseGuide(mealsSummary: $mealsSummary, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PhaseGuideCopyWith<$Res> implements $PhaseGuideCopyWith<$Res> {
  factory _$PhaseGuideCopyWith(_PhaseGuide value, $Res Function(_PhaseGuide) _then) = __$PhaseGuideCopyWithImpl;
@override @useResult
$Res call({
 String mealsSummary, List<GuideItem> items
});




}
/// @nodoc
class __$PhaseGuideCopyWithImpl<$Res>
    implements _$PhaseGuideCopyWith<$Res> {
  __$PhaseGuideCopyWithImpl(this._self, this._then);

  final _PhaseGuide _self;
  final $Res Function(_PhaseGuide) _then;

/// Create a copy of PhaseGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mealsSummary = null,Object? items = null,}) {
  return _then(_PhaseGuide(
mealsSummary: null == mealsSummary ? _self.mealsSummary : mealsSummary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}


}

/// @nodoc
mixin _$AgeGuide {

 Map<DiversificationPhase, PhaseGuide> get phases; List<GuideItem> get readinessSigns; List<GuideItem> get hungerSigns; List<GuideItem> get satietySigns; List<GuideItem> get safety;
/// Create a copy of AgeGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgeGuideCopyWith<AgeGuide> get copyWith => _$AgeGuideCopyWithImpl<AgeGuide>(this as AgeGuide, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AgeGuide;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgeGuide&&const DeepCollectionEquality().equals(other.phases, _this.phases)&&const DeepCollectionEquality().equals(other.readinessSigns, _this.readinessSigns)&&const DeepCollectionEquality().equals(other.hungerSigns, _this.hungerSigns)&&const DeepCollectionEquality().equals(other.satietySigns, _this.satietySigns)&&const DeepCollectionEquality().equals(other.safety, _this.safety));
}


@override
int get hashCode {
  final _this = this as AgeGuide;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.phases),const DeepCollectionEquality().hash(_this.readinessSigns),const DeepCollectionEquality().hash(_this.hungerSigns),const DeepCollectionEquality().hash(_this.satietySigns),const DeepCollectionEquality().hash(_this.safety));
}

@override
String toString() {
  final _this = this as AgeGuide;
  return 'AgeGuide(phases: ${_this.phases}, readinessSigns: ${_this.readinessSigns}, hungerSigns: ${_this.hungerSigns}, satietySigns: ${_this.satietySigns}, safety: ${_this.safety})';
}


}

/// @nodoc
abstract mixin class $AgeGuideCopyWith<$Res>  {
  factory $AgeGuideCopyWith(AgeGuide value, $Res Function(AgeGuide) _then) = _$AgeGuideCopyWithImpl;
@useResult
$Res call({
 Map<DiversificationPhase, PhaseGuide> phases, List<GuideItem> readinessSigns, List<GuideItem> hungerSigns, List<GuideItem> satietySigns, List<GuideItem> safety
});




}
/// @nodoc
class _$AgeGuideCopyWithImpl<$Res>
    implements $AgeGuideCopyWith<$Res> {
  _$AgeGuideCopyWithImpl(this._self, this._then);

  final AgeGuide _self;
  final $Res Function(AgeGuide) _then;

/// Create a copy of AgeGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phases = null,Object? readinessSigns = null,Object? hungerSigns = null,Object? satietySigns = null,Object? safety = null,}) {
  return _then(AgeGuide(
phases: null == phases ? _self.phases : phases // ignore: cast_nullable_to_non_nullable
as Map<DiversificationPhase, PhaseGuide>,readinessSigns: null == readinessSigns ? _self.readinessSigns : readinessSigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,hungerSigns: null == hungerSigns ? _self.hungerSigns : hungerSigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,satietySigns: null == satietySigns ? _self.satietySigns : satietySigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [AgeGuide].
extension AgeGuidePatterns on AgeGuide {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgeGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgeGuide() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgeGuide value)  $default,){
final _that = this;
switch (_that) {
case _AgeGuide():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgeGuide value)?  $default,){
final _that = this;
switch (_that) {
case _AgeGuide() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<DiversificationPhase, PhaseGuide> phases,  List<GuideItem> readinessSigns,  List<GuideItem> hungerSigns,  List<GuideItem> satietySigns,  List<GuideItem> safety)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgeGuide() when $default != null:
return $default(_that.phases,_that.readinessSigns,_that.hungerSigns,_that.satietySigns,_that.safety);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<DiversificationPhase, PhaseGuide> phases,  List<GuideItem> readinessSigns,  List<GuideItem> hungerSigns,  List<GuideItem> satietySigns,  List<GuideItem> safety)  $default,) {final _that = this;
switch (_that) {
case _AgeGuide():
return $default(_that.phases,_that.readinessSigns,_that.hungerSigns,_that.satietySigns,_that.safety);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<DiversificationPhase, PhaseGuide> phases,  List<GuideItem> readinessSigns,  List<GuideItem> hungerSigns,  List<GuideItem> satietySigns,  List<GuideItem> safety)?  $default,) {final _that = this;
switch (_that) {
case _AgeGuide() when $default != null:
return $default(_that.phases,_that.readinessSigns,_that.hungerSigns,_that.satietySigns,_that.safety);case _:
  return null;

}
}

}

/// @nodoc


class _AgeGuide implements AgeGuide {
  const _AgeGuide({required  Map<DiversificationPhase, PhaseGuide> phases, required  List<GuideItem> readinessSigns, required  List<GuideItem> hungerSigns, required  List<GuideItem> satietySigns, required  List<GuideItem> safety}): _phases = phases,_readinessSigns = readinessSigns,_hungerSigns = hungerSigns,_satietySigns = satietySigns,_safety = safety;
  

 final  Map<DiversificationPhase, PhaseGuide> _phases;
@override Map<DiversificationPhase, PhaseGuide> get phases {
  if (_phases is EqualUnmodifiableMapView) return _phases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_phases);
}

 final  List<GuideItem> _readinessSigns;
@override List<GuideItem> get readinessSigns {
  if (_readinessSigns is EqualUnmodifiableListView) return _readinessSigns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readinessSigns);
}

 final  List<GuideItem> _hungerSigns;
@override List<GuideItem> get hungerSigns {
  if (_hungerSigns is EqualUnmodifiableListView) return _hungerSigns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hungerSigns);
}

 final  List<GuideItem> _satietySigns;
@override List<GuideItem> get satietySigns {
  if (_satietySigns is EqualUnmodifiableListView) return _satietySigns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_satietySigns);
}

 final  List<GuideItem> _safety;
@override List<GuideItem> get safety {
  if (_safety is EqualUnmodifiableListView) return _safety;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_safety);
}


/// Create a copy of AgeGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgeGuideCopyWith<_AgeGuide> get copyWith => __$AgeGuideCopyWithImpl<_AgeGuide>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgeGuide&&const DeepCollectionEquality().equals(other.phases, _phases)&&const DeepCollectionEquality().equals(other.readinessSigns, _readinessSigns)&&const DeepCollectionEquality().equals(other.hungerSigns, _hungerSigns)&&const DeepCollectionEquality().equals(other.satietySigns, _satietySigns)&&const DeepCollectionEquality().equals(other.safety, _safety));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_phases),const DeepCollectionEquality().hash(_readinessSigns),const DeepCollectionEquality().hash(_hungerSigns),const DeepCollectionEquality().hash(_satietySigns),const DeepCollectionEquality().hash(_safety));
}

@override
String toString() {
    return 'AgeGuide(phases: $phases, readinessSigns: $readinessSigns, hungerSigns: $hungerSigns, satietySigns: $satietySigns, safety: $safety)';
}


}

/// @nodoc
abstract mixin class _$AgeGuideCopyWith<$Res> implements $AgeGuideCopyWith<$Res> {
  factory _$AgeGuideCopyWith(_AgeGuide value, $Res Function(_AgeGuide) _then) = __$AgeGuideCopyWithImpl;
@override @useResult
$Res call({
 Map<DiversificationPhase, PhaseGuide> phases, List<GuideItem> readinessSigns, List<GuideItem> hungerSigns, List<GuideItem> satietySigns, List<GuideItem> safety
});




}
/// @nodoc
class __$AgeGuideCopyWithImpl<$Res>
    implements _$AgeGuideCopyWith<$Res> {
  __$AgeGuideCopyWithImpl(this._self, this._then);

  final _AgeGuide _self;
  final $Res Function(_AgeGuide) _then;

/// Create a copy of AgeGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phases = null,Object? readinessSigns = null,Object? hungerSigns = null,Object? satietySigns = null,Object? safety = null,}) {
  return _then(_AgeGuide(
phases: null == phases ? _self._phases : phases // ignore: cast_nullable_to_non_nullable
as Map<DiversificationPhase, PhaseGuide>,readinessSigns: null == readinessSigns ? _self._readinessSigns : readinessSigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,hungerSigns: null == hungerSigns ? _self._hungerSigns : hungerSigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,satietySigns: null == satietySigns ? _self._satietySigns : satietySigns // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,safety: null == safety ? _self._safety : safety // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}


}

/// @nodoc
mixin _$FoodCatalog {

 int get version; DateTime get reviewedAt; Map<RuleSource, SourceRef> get sources; AgeGuide get guide; List<Food> get foods;
/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodCatalogCopyWith<FoodCatalog> get copyWith => _$FoodCatalogCopyWithImpl<FoodCatalog>(this as FoodCatalog, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FoodCatalog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodCatalog&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt)&&const DeepCollectionEquality().equals(other.sources, _this.sources)&&(identical(other.guide, _this.guide) || other.guide == _this.guide)&&const DeepCollectionEquality().equals(other.foods, _this.foods));
}


@override
int get hashCode {
  final _this = this as FoodCatalog;
  return Object.hash(runtimeType,_this.version,_this.reviewedAt,const DeepCollectionEquality().hash(_this.sources),_this.guide,const DeepCollectionEquality().hash(_this.foods));
}

@override
String toString() {
  final _this = this as FoodCatalog;
  return 'FoodCatalog(version: ${_this.version}, reviewedAt: ${_this.reviewedAt}, sources: ${_this.sources}, guide: ${_this.guide}, foods: ${_this.foods})';
}


}

/// @nodoc
abstract mixin class $FoodCatalogCopyWith<$Res>  {
  factory $FoodCatalogCopyWith(FoodCatalog value, $Res Function(FoodCatalog) _then) = _$FoodCatalogCopyWithImpl;
@useResult
$Res call({
 int version, DateTime reviewedAt, Map<RuleSource, SourceRef> sources, AgeGuide guide, List<Food> foods
});


$AgeGuideCopyWith<$Res> get guide;

}
/// @nodoc
class _$FoodCatalogCopyWithImpl<$Res>
    implements $FoodCatalogCopyWith<$Res> {
  _$FoodCatalogCopyWithImpl(this._self, this._then);

  final FoodCatalog _self;
  final $Res Function(FoodCatalog) _then;

/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? reviewedAt = null,Object? sources = null,Object? guide = null,Object? foods = null,}) {
  return _then(FoodCatalog(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,reviewedAt: null == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as Map<RuleSource, SourceRef>,guide: null == guide ? _self.guide : guide // ignore: cast_nullable_to_non_nullable
as AgeGuide,foods: null == foods ? _self.foods : foods // ignore: cast_nullable_to_non_nullable
as List<Food>,
  ));
}
/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgeGuideCopyWith<$Res> get guide {
  
  return $AgeGuideCopyWith<$Res>(_self.guide, (value) {
    return _then(_self.copyWith(guide: value));
  });
}
}


/// Adds pattern-matching-related methods to [FoodCatalog].
extension FoodCatalogPatterns on FoodCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodCatalog value)  $default,){
final _that = this;
switch (_that) {
case _FoodCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _FoodCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  DateTime reviewedAt,  Map<RuleSource, SourceRef> sources,  AgeGuide guide,  List<Food> foods)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodCatalog() when $default != null:
return $default(_that.version,_that.reviewedAt,_that.sources,_that.guide,_that.foods);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  DateTime reviewedAt,  Map<RuleSource, SourceRef> sources,  AgeGuide guide,  List<Food> foods)  $default,) {final _that = this;
switch (_that) {
case _FoodCatalog():
return $default(_that.version,_that.reviewedAt,_that.sources,_that.guide,_that.foods);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  DateTime reviewedAt,  Map<RuleSource, SourceRef> sources,  AgeGuide guide,  List<Food> foods)?  $default,) {final _that = this;
switch (_that) {
case _FoodCatalog() when $default != null:
return $default(_that.version,_that.reviewedAt,_that.sources,_that.guide,_that.foods);case _:
  return null;

}
}

}

/// @nodoc


class _FoodCatalog implements FoodCatalog {
  const _FoodCatalog({required this.version, required this.reviewedAt, required  Map<RuleSource, SourceRef> sources, required this.guide, required  List<Food> foods}): _sources = sources,_foods = foods;
  

@override final  int version;
@override final  DateTime reviewedAt;
 final  Map<RuleSource, SourceRef> _sources;
@override Map<RuleSource, SourceRef> get sources {
  if (_sources is EqualUnmodifiableMapView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sources);
}

@override final  AgeGuide guide;
 final  List<Food> _foods;
@override List<Food> get foods {
  if (_foods is EqualUnmodifiableListView) return _foods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foods);
}


/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodCatalogCopyWith<_FoodCatalog> get copyWith => __$FoodCatalogCopyWithImpl<_FoodCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodCatalog&&(identical(other.version, version) || other.version == version)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other.sources, _sources)&&(identical(other.guide, guide) || other.guide == guide)&&const DeepCollectionEquality().equals(other.foods, _foods));
}


@override
int get hashCode {
    return Object.hash(runtimeType,version,reviewedAt,const DeepCollectionEquality().hash(_sources),guide,const DeepCollectionEquality().hash(_foods));
}

@override
String toString() {
    return 'FoodCatalog(version: $version, reviewedAt: $reviewedAt, sources: $sources, guide: $guide, foods: $foods)';
}


}

/// @nodoc
abstract mixin class _$FoodCatalogCopyWith<$Res> implements $FoodCatalogCopyWith<$Res> {
  factory _$FoodCatalogCopyWith(_FoodCatalog value, $Res Function(_FoodCatalog) _then) = __$FoodCatalogCopyWithImpl;
@override @useResult
$Res call({
 int version, DateTime reviewedAt, Map<RuleSource, SourceRef> sources, AgeGuide guide, List<Food> foods
});


@override $AgeGuideCopyWith<$Res> get guide;

}
/// @nodoc
class __$FoodCatalogCopyWithImpl<$Res>
    implements _$FoodCatalogCopyWith<$Res> {
  __$FoodCatalogCopyWithImpl(this._self, this._then);

  final _FoodCatalog _self;
  final $Res Function(_FoodCatalog) _then;

/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? reviewedAt = null,Object? sources = null,Object? guide = null,Object? foods = null,}) {
  return _then(_FoodCatalog(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,reviewedAt: null == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as Map<RuleSource, SourceRef>,guide: null == guide ? _self.guide : guide // ignore: cast_nullable_to_non_nullable
as AgeGuide,foods: null == foods ? _self._foods : foods // ignore: cast_nullable_to_non_nullable
as List<Food>,
  ));
}

/// Create a copy of FoodCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgeGuideCopyWith<$Res> get guide {
  
  return $AgeGuideCopyWith<$Res>(_self.guide, (value) {
    return _then(_self.copyWith(guide: value));
  });
}
}

// dart format on
