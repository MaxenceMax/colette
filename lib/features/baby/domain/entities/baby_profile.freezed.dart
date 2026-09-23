// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BabyProfile {

 String get name; DateTime get birthDate; DateTime? get cordFallenAt;/// `null` tant que non renseigné : pas de courbes OMS.
 BabySex? get sex; CareSettings get careSettings;
/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyProfileCopyWith<BabyProfile> get copyWith => _$BabyProfileCopyWithImpl<BabyProfile>(this as BabyProfile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BabyProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyProfile&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.birthDate, _this.birthDate) || other.birthDate == _this.birthDate)&&(identical(other.cordFallenAt, _this.cordFallenAt) || other.cordFallenAt == _this.cordFallenAt)&&(identical(other.sex, _this.sex) || other.sex == _this.sex)&&(identical(other.careSettings, _this.careSettings) || other.careSettings == _this.careSettings));
}


@override
int get hashCode {
  final _this = this as BabyProfile;
  return Object.hash(runtimeType,_this.name,_this.birthDate,_this.cordFallenAt,_this.sex,_this.careSettings);
}

@override
String toString() {
  final _this = this as BabyProfile;
  return 'BabyProfile(name: ${_this.name}, birthDate: ${_this.birthDate}, cordFallenAt: ${_this.cordFallenAt}, sex: ${_this.sex}, careSettings: ${_this.careSettings})';
}


}

/// @nodoc
abstract mixin class $BabyProfileCopyWith<$Res>  {
  factory $BabyProfileCopyWith(BabyProfile value, $Res Function(BabyProfile) _then) = _$BabyProfileCopyWithImpl;
@useResult
$Res call({
 String name, DateTime birthDate, DateTime? cordFallenAt, BabySex? sex, CareSettings careSettings
});


$CareSettingsCopyWith<$Res> get careSettings;

}
/// @nodoc
class _$BabyProfileCopyWithImpl<$Res>
    implements $BabyProfileCopyWith<$Res> {
  _$BabyProfileCopyWithImpl(this._self, this._then);

  final BabyProfile _self;
  final $Res Function(BabyProfile) _then;

/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? birthDate = null,Object? cordFallenAt = freezed,Object? sex = freezed,Object? careSettings = null,}) {
  return _then(BabyProfile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,cordFallenAt: freezed == cordFallenAt ? _self.cordFallenAt : cordFallenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as BabySex?,careSettings: null == careSettings ? _self.careSettings : careSettings // ignore: cast_nullable_to_non_nullable
as CareSettings,
  ));
}
/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareSettingsCopyWith<$Res> get careSettings {
  
  return $CareSettingsCopyWith<$Res>(_self.careSettings, (value) {
    return _then(_self.copyWith(careSettings: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyProfile].
extension BabyProfilePatterns on BabyProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyProfile value)  $default,){
final _that = this;
switch (_that) {
case _BabyProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BabyProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  DateTime birthDate,  DateTime? cordFallenAt,  BabySex? sex,  CareSettings careSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyProfile() when $default != null:
return $default(_that.name,_that.birthDate,_that.cordFallenAt,_that.sex,_that.careSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  DateTime birthDate,  DateTime? cordFallenAt,  BabySex? sex,  CareSettings careSettings)  $default,) {final _that = this;
switch (_that) {
case _BabyProfile():
return $default(_that.name,_that.birthDate,_that.cordFallenAt,_that.sex,_that.careSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  DateTime birthDate,  DateTime? cordFallenAt,  BabySex? sex,  CareSettings careSettings)?  $default,) {final _that = this;
switch (_that) {
case _BabyProfile() when $default != null:
return $default(_that.name,_that.birthDate,_that.cordFallenAt,_that.sex,_that.careSettings);case _:
  return null;

}
}

}

/// @nodoc


class _BabyProfile implements BabyProfile {
  const _BabyProfile({required this.name, required this.birthDate, this.cordFallenAt, this.sex, this.careSettings = const CareSettings()});
  

@override final  String name;
@override final  DateTime birthDate;
@override final  DateTime? cordFallenAt;
/// `null` tant que non renseigné : pas de courbes OMS.
@override final  BabySex? sex;
@override@JsonKey() final  CareSettings careSettings;

/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyProfileCopyWith<_BabyProfile> get copyWith => __$BabyProfileCopyWithImpl<_BabyProfile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyProfile&&(identical(other.name, name) || other.name == name)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.cordFallenAt, cordFallenAt) || other.cordFallenAt == cordFallenAt)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.careSettings, careSettings) || other.careSettings == careSettings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,birthDate,cordFallenAt,sex,careSettings);
}

@override
String toString() {
    return 'BabyProfile(name: $name, birthDate: $birthDate, cordFallenAt: $cordFallenAt, sex: $sex, careSettings: $careSettings)';
}


}

/// @nodoc
abstract mixin class _$BabyProfileCopyWith<$Res> implements $BabyProfileCopyWith<$Res> {
  factory _$BabyProfileCopyWith(_BabyProfile value, $Res Function(_BabyProfile) _then) = __$BabyProfileCopyWithImpl;
@override @useResult
$Res call({
 String name, DateTime birthDate, DateTime? cordFallenAt, BabySex? sex, CareSettings careSettings
});


@override $CareSettingsCopyWith<$Res> get careSettings;

}
/// @nodoc
class __$BabyProfileCopyWithImpl<$Res>
    implements _$BabyProfileCopyWith<$Res> {
  __$BabyProfileCopyWithImpl(this._self, this._then);

  final _BabyProfile _self;
  final $Res Function(_BabyProfile) _then;

/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? birthDate = null,Object? cordFallenAt = freezed,Object? sex = freezed,Object? careSettings = null,}) {
  return _then(_BabyProfile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,cordFallenAt: freezed == cordFallenAt ? _self.cordFallenAt : cordFallenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as BabySex?,careSettings: null == careSettings ? _self.careSettings : careSettings // ignore: cast_nullable_to_non_nullable
as CareSettings,
  ));
}

/// Create a copy of BabyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareSettingsCopyWith<$Res> get careSettings {
  
  return $CareSettingsCopyWith<$Res>(_self.careSettings, (value) {
    return _then(_self.copyWith(careSettings: value));
  });
}
}

// dart format on
