// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareSettings {

 CareFrequency get adrigyl; CareFrequency get eyeCare; CareFrequency get noseCare; CareFrequency get umbilicalCare; CareFrequency get bath; int get feedsPerDay;/// Heure (0-23) à partir de laquelle un endormissement est une nuit.
 int get nightStartHour;/// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
 int get nightEndHour;/// Cible journalière forcée en ml ; `null` = calcul OMS.
 int? get dailyTargetMl;
/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareSettingsCopyWith<CareSettings> get copyWith => _$CareSettingsCopyWithImpl<CareSettings>(this as CareSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CareSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareSettings&&(identical(other.adrigyl, _this.adrigyl) || other.adrigyl == _this.adrigyl)&&(identical(other.eyeCare, _this.eyeCare) || other.eyeCare == _this.eyeCare)&&(identical(other.noseCare, _this.noseCare) || other.noseCare == _this.noseCare)&&(identical(other.umbilicalCare, _this.umbilicalCare) || other.umbilicalCare == _this.umbilicalCare)&&(identical(other.bath, _this.bath) || other.bath == _this.bath)&&(identical(other.feedsPerDay, _this.feedsPerDay) || other.feedsPerDay == _this.feedsPerDay)&&(identical(other.nightStartHour, _this.nightStartHour) || other.nightStartHour == _this.nightStartHour)&&(identical(other.nightEndHour, _this.nightEndHour) || other.nightEndHour == _this.nightEndHour)&&(identical(other.dailyTargetMl, _this.dailyTargetMl) || other.dailyTargetMl == _this.dailyTargetMl));
}


@override
int get hashCode {
  final _this = this as CareSettings;
  return Object.hash(runtimeType,_this.adrigyl,_this.eyeCare,_this.noseCare,_this.umbilicalCare,_this.bath,_this.feedsPerDay,_this.nightStartHour,_this.nightEndHour,_this.dailyTargetMl);
}

@override
String toString() {
  final _this = this as CareSettings;
  return 'CareSettings(adrigyl: ${_this.adrigyl}, eyeCare: ${_this.eyeCare}, noseCare: ${_this.noseCare}, umbilicalCare: ${_this.umbilicalCare}, bath: ${_this.bath}, feedsPerDay: ${_this.feedsPerDay}, nightStartHour: ${_this.nightStartHour}, nightEndHour: ${_this.nightEndHour}, dailyTargetMl: ${_this.dailyTargetMl})';
}


}

/// @nodoc
abstract mixin class $CareSettingsCopyWith<$Res>  {
  factory $CareSettingsCopyWith(CareSettings value, $Res Function(CareSettings) _then) = _$CareSettingsCopyWithImpl;
@useResult
$Res call({
 CareFrequency adrigyl, CareFrequency eyeCare, CareFrequency noseCare, CareFrequency umbilicalCare, CareFrequency bath, int feedsPerDay, int nightStartHour, int nightEndHour, int? dailyTargetMl
});


$CareFrequencyCopyWith<$Res> get adrigyl;$CareFrequencyCopyWith<$Res> get eyeCare;$CareFrequencyCopyWith<$Res> get noseCare;$CareFrequencyCopyWith<$Res> get umbilicalCare;$CareFrequencyCopyWith<$Res> get bath;

}
/// @nodoc
class _$CareSettingsCopyWithImpl<$Res>
    implements $CareSettingsCopyWith<$Res> {
  _$CareSettingsCopyWithImpl(this._self, this._then);

  final CareSettings _self;
  final $Res Function(CareSettings) _then;

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? adrigyl = null,Object? eyeCare = null,Object? noseCare = null,Object? umbilicalCare = null,Object? bath = null,Object? feedsPerDay = null,Object? nightStartHour = null,Object? nightEndHour = null,Object? dailyTargetMl = freezed,}) {
  return _then(CareSettings(
adrigyl: null == adrigyl ? _self.adrigyl : adrigyl // ignore: cast_nullable_to_non_nullable
as CareFrequency,eyeCare: null == eyeCare ? _self.eyeCare : eyeCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,noseCare: null == noseCare ? _self.noseCare : noseCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,umbilicalCare: null == umbilicalCare ? _self.umbilicalCare : umbilicalCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,bath: null == bath ? _self.bath : bath // ignore: cast_nullable_to_non_nullable
as CareFrequency,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nightStartHour: null == nightStartHour ? _self.nightStartHour : nightStartHour // ignore: cast_nullable_to_non_nullable
as int,nightEndHour: null == nightEndHour ? _self.nightEndHour : nightEndHour // ignore: cast_nullable_to_non_nullable
as int,dailyTargetMl: freezed == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get adrigyl {
  
  return $CareFrequencyCopyWith<$Res>(_self.adrigyl, (value) {
    return _then(_self.copyWith(adrigyl: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get eyeCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.eyeCare, (value) {
    return _then(_self.copyWith(eyeCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get noseCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.noseCare, (value) {
    return _then(_self.copyWith(noseCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get umbilicalCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.umbilicalCare, (value) {
    return _then(_self.copyWith(umbilicalCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get bath {
  
  return $CareFrequencyCopyWith<$Res>(_self.bath, (value) {
    return _then(_self.copyWith(bath: value));
  });
}
}


/// Adds pattern-matching-related methods to [CareSettings].
extension CareSettingsPatterns on CareSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareSettings value)  $default,){
final _that = this;
switch (_that) {
case _CareSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareSettings value)?  $default,){
final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CareFrequency adrigyl,  CareFrequency eyeCare,  CareFrequency noseCare,  CareFrequency umbilicalCare,  CareFrequency bath,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
return $default(_that.adrigyl,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bath,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CareFrequency adrigyl,  CareFrequency eyeCare,  CareFrequency noseCare,  CareFrequency umbilicalCare,  CareFrequency bath,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)  $default,) {final _that = this;
switch (_that) {
case _CareSettings():
return $default(_that.adrigyl,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bath,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CareFrequency adrigyl,  CareFrequency eyeCare,  CareFrequency noseCare,  CareFrequency umbilicalCare,  CareFrequency bath,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)?  $default,) {final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
return $default(_that.adrigyl,_that.eyeCare,_that.noseCare,_that.umbilicalCare,_that.bath,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
  return null;

}
}

}

/// @nodoc


class _CareSettings extends CareSettings {
  const _CareSettings({this.adrigyl = const CareFrequency(), this.eyeCare = const CareFrequency(), this.noseCare = const CareFrequency(), this.umbilicalCare = const CareFrequency(timesPerDay: 3), this.bath = const CareFrequency(everyDays: 2), this.feedsPerDay = 8, this.nightStartHour = 20, this.nightEndHour = 7, this.dailyTargetMl}): super._();
  

@override@JsonKey() final  CareFrequency adrigyl;
@override@JsonKey() final  CareFrequency eyeCare;
@override@JsonKey() final  CareFrequency noseCare;
@override@JsonKey() final  CareFrequency umbilicalCare;
@override@JsonKey() final  CareFrequency bath;
@override@JsonKey() final  int feedsPerDay;
/// Heure (0-23) à partir de laquelle un endormissement est une nuit.
@override@JsonKey() final  int nightStartHour;
/// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
@override@JsonKey() final  int nightEndHour;
/// Cible journalière forcée en ml ; `null` = calcul OMS.
@override final  int? dailyTargetMl;

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareSettingsCopyWith<_CareSettings> get copyWith => __$CareSettingsCopyWithImpl<_CareSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareSettings&&(identical(other.adrigyl, adrigyl) || other.adrigyl == adrigyl)&&(identical(other.eyeCare, eyeCare) || other.eyeCare == eyeCare)&&(identical(other.noseCare, noseCare) || other.noseCare == noseCare)&&(identical(other.umbilicalCare, umbilicalCare) || other.umbilicalCare == umbilicalCare)&&(identical(other.bath, bath) || other.bath == bath)&&(identical(other.feedsPerDay, feedsPerDay) || other.feedsPerDay == feedsPerDay)&&(identical(other.nightStartHour, nightStartHour) || other.nightStartHour == nightStartHour)&&(identical(other.nightEndHour, nightEndHour) || other.nightEndHour == nightEndHour)&&(identical(other.dailyTargetMl, dailyTargetMl) || other.dailyTargetMl == dailyTargetMl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,adrigyl,eyeCare,noseCare,umbilicalCare,bath,feedsPerDay,nightStartHour,nightEndHour,dailyTargetMl);
}

@override
String toString() {
    return 'CareSettings(adrigyl: $adrigyl, eyeCare: $eyeCare, noseCare: $noseCare, umbilicalCare: $umbilicalCare, bath: $bath, feedsPerDay: $feedsPerDay, nightStartHour: $nightStartHour, nightEndHour: $nightEndHour, dailyTargetMl: $dailyTargetMl)';
}


}

/// @nodoc
abstract mixin class _$CareSettingsCopyWith<$Res> implements $CareSettingsCopyWith<$Res> {
  factory _$CareSettingsCopyWith(_CareSettings value, $Res Function(_CareSettings) _then) = __$CareSettingsCopyWithImpl;
@override @useResult
$Res call({
 CareFrequency adrigyl, CareFrequency eyeCare, CareFrequency noseCare, CareFrequency umbilicalCare, CareFrequency bath, int feedsPerDay, int nightStartHour, int nightEndHour, int? dailyTargetMl
});


@override $CareFrequencyCopyWith<$Res> get adrigyl;@override $CareFrequencyCopyWith<$Res> get eyeCare;@override $CareFrequencyCopyWith<$Res> get noseCare;@override $CareFrequencyCopyWith<$Res> get umbilicalCare;@override $CareFrequencyCopyWith<$Res> get bath;

}
/// @nodoc
class __$CareSettingsCopyWithImpl<$Res>
    implements _$CareSettingsCopyWith<$Res> {
  __$CareSettingsCopyWithImpl(this._self, this._then);

  final _CareSettings _self;
  final $Res Function(_CareSettings) _then;

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? adrigyl = null,Object? eyeCare = null,Object? noseCare = null,Object? umbilicalCare = null,Object? bath = null,Object? feedsPerDay = null,Object? nightStartHour = null,Object? nightEndHour = null,Object? dailyTargetMl = freezed,}) {
  return _then(_CareSettings(
adrigyl: null == adrigyl ? _self.adrigyl : adrigyl // ignore: cast_nullable_to_non_nullable
as CareFrequency,eyeCare: null == eyeCare ? _self.eyeCare : eyeCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,noseCare: null == noseCare ? _self.noseCare : noseCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,umbilicalCare: null == umbilicalCare ? _self.umbilicalCare : umbilicalCare // ignore: cast_nullable_to_non_nullable
as CareFrequency,bath: null == bath ? _self.bath : bath // ignore: cast_nullable_to_non_nullable
as CareFrequency,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nightStartHour: null == nightStartHour ? _self.nightStartHour : nightStartHour // ignore: cast_nullable_to_non_nullable
as int,nightEndHour: null == nightEndHour ? _self.nightEndHour : nightEndHour // ignore: cast_nullable_to_non_nullable
as int,dailyTargetMl: freezed == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get adrigyl {
  
  return $CareFrequencyCopyWith<$Res>(_self.adrigyl, (value) {
    return _then(_self.copyWith(adrigyl: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get eyeCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.eyeCare, (value) {
    return _then(_self.copyWith(eyeCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get noseCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.noseCare, (value) {
    return _then(_self.copyWith(noseCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get umbilicalCare {
  
  return $CareFrequencyCopyWith<$Res>(_self.umbilicalCare, (value) {
    return _then(_self.copyWith(umbilicalCare: value));
  });
}/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CareFrequencyCopyWith<$Res> get bath {
  
  return $CareFrequencyCopyWith<$Res>(_self.bath, (value) {
    return _then(_self.copyWith(bath: value));
  });
}
}

// dart format on
