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

 int get adrigylPerDay; int get eyeCarePerDay; int get noseCarePerDay; int get umbilicalCarePerDay; int get bathEveryDays; int get feedsPerDay;/// Heure (0-23) à partir de laquelle un endormissement est une nuit.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareSettings&&(identical(other.adrigylPerDay, _this.adrigylPerDay) || other.adrigylPerDay == _this.adrigylPerDay)&&(identical(other.eyeCarePerDay, _this.eyeCarePerDay) || other.eyeCarePerDay == _this.eyeCarePerDay)&&(identical(other.noseCarePerDay, _this.noseCarePerDay) || other.noseCarePerDay == _this.noseCarePerDay)&&(identical(other.umbilicalCarePerDay, _this.umbilicalCarePerDay) || other.umbilicalCarePerDay == _this.umbilicalCarePerDay)&&(identical(other.bathEveryDays, _this.bathEveryDays) || other.bathEveryDays == _this.bathEveryDays)&&(identical(other.feedsPerDay, _this.feedsPerDay) || other.feedsPerDay == _this.feedsPerDay)&&(identical(other.nightStartHour, _this.nightStartHour) || other.nightStartHour == _this.nightStartHour)&&(identical(other.nightEndHour, _this.nightEndHour) || other.nightEndHour == _this.nightEndHour)&&(identical(other.dailyTargetMl, _this.dailyTargetMl) || other.dailyTargetMl == _this.dailyTargetMl));
}


@override
int get hashCode {
  final _this = this as CareSettings;
  return Object.hash(runtimeType,_this.adrigylPerDay,_this.eyeCarePerDay,_this.noseCarePerDay,_this.umbilicalCarePerDay,_this.bathEveryDays,_this.feedsPerDay,_this.nightStartHour,_this.nightEndHour,_this.dailyTargetMl);
}

@override
String toString() {
  final _this = this as CareSettings;
  return 'CareSettings(adrigylPerDay: ${_this.adrigylPerDay}, eyeCarePerDay: ${_this.eyeCarePerDay}, noseCarePerDay: ${_this.noseCarePerDay}, umbilicalCarePerDay: ${_this.umbilicalCarePerDay}, bathEveryDays: ${_this.bathEveryDays}, feedsPerDay: ${_this.feedsPerDay}, nightStartHour: ${_this.nightStartHour}, nightEndHour: ${_this.nightEndHour}, dailyTargetMl: ${_this.dailyTargetMl})';
}


}

/// @nodoc
abstract mixin class $CareSettingsCopyWith<$Res>  {
  factory $CareSettingsCopyWith(CareSettings value, $Res Function(CareSettings) _then) = _$CareSettingsCopyWithImpl;
@useResult
$Res call({
 int adrigylPerDay, int eyeCarePerDay, int noseCarePerDay, int umbilicalCarePerDay, int bathEveryDays, int feedsPerDay, int nightStartHour, int nightEndHour, int? dailyTargetMl
});




}
/// @nodoc
class _$CareSettingsCopyWithImpl<$Res>
    implements $CareSettingsCopyWith<$Res> {
  _$CareSettingsCopyWithImpl(this._self, this._then);

  final CareSettings _self;
  final $Res Function(CareSettings) _then;

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? adrigylPerDay = null,Object? eyeCarePerDay = null,Object? noseCarePerDay = null,Object? umbilicalCarePerDay = null,Object? bathEveryDays = null,Object? feedsPerDay = null,Object? nightStartHour = null,Object? nightEndHour = null,Object? dailyTargetMl = freezed,}) {
  return _then(CareSettings(
adrigylPerDay: null == adrigylPerDay ? _self.adrigylPerDay : adrigylPerDay // ignore: cast_nullable_to_non_nullable
as int,eyeCarePerDay: null == eyeCarePerDay ? _self.eyeCarePerDay : eyeCarePerDay // ignore: cast_nullable_to_non_nullable
as int,noseCarePerDay: null == noseCarePerDay ? _self.noseCarePerDay : noseCarePerDay // ignore: cast_nullable_to_non_nullable
as int,umbilicalCarePerDay: null == umbilicalCarePerDay ? _self.umbilicalCarePerDay : umbilicalCarePerDay // ignore: cast_nullable_to_non_nullable
as int,bathEveryDays: null == bathEveryDays ? _self.bathEveryDays : bathEveryDays // ignore: cast_nullable_to_non_nullable
as int,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nightStartHour: null == nightStartHour ? _self.nightStartHour : nightStartHour // ignore: cast_nullable_to_non_nullable
as int,nightEndHour: null == nightEndHour ? _self.nightEndHour : nightEndHour // ignore: cast_nullable_to_non_nullable
as int,dailyTargetMl: freezed == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int adrigylPerDay,  int eyeCarePerDay,  int noseCarePerDay,  int umbilicalCarePerDay,  int bathEveryDays,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
return $default(_that.adrigylPerDay,_that.eyeCarePerDay,_that.noseCarePerDay,_that.umbilicalCarePerDay,_that.bathEveryDays,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int adrigylPerDay,  int eyeCarePerDay,  int noseCarePerDay,  int umbilicalCarePerDay,  int bathEveryDays,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)  $default,) {final _that = this;
switch (_that) {
case _CareSettings():
return $default(_that.adrigylPerDay,_that.eyeCarePerDay,_that.noseCarePerDay,_that.umbilicalCarePerDay,_that.bathEveryDays,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int adrigylPerDay,  int eyeCarePerDay,  int noseCarePerDay,  int umbilicalCarePerDay,  int bathEveryDays,  int feedsPerDay,  int nightStartHour,  int nightEndHour,  int? dailyTargetMl)?  $default,) {final _that = this;
switch (_that) {
case _CareSettings() when $default != null:
return $default(_that.adrigylPerDay,_that.eyeCarePerDay,_that.noseCarePerDay,_that.umbilicalCarePerDay,_that.bathEveryDays,_that.feedsPerDay,_that.nightStartHour,_that.nightEndHour,_that.dailyTargetMl);case _:
  return null;

}
}

}

/// @nodoc


class _CareSettings extends CareSettings {
  const _CareSettings({this.adrigylPerDay = 1, this.eyeCarePerDay = 1, this.noseCarePerDay = 1, this.umbilicalCarePerDay = 3, this.bathEveryDays = 2, this.feedsPerDay = 8, this.nightStartHour = 20, this.nightEndHour = 7, this.dailyTargetMl}): super._();
  

@override@JsonKey() final  int adrigylPerDay;
@override@JsonKey() final  int eyeCarePerDay;
@override@JsonKey() final  int noseCarePerDay;
@override@JsonKey() final  int umbilicalCarePerDay;
@override@JsonKey() final  int bathEveryDays;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareSettings&&(identical(other.adrigylPerDay, adrigylPerDay) || other.adrigylPerDay == adrigylPerDay)&&(identical(other.eyeCarePerDay, eyeCarePerDay) || other.eyeCarePerDay == eyeCarePerDay)&&(identical(other.noseCarePerDay, noseCarePerDay) || other.noseCarePerDay == noseCarePerDay)&&(identical(other.umbilicalCarePerDay, umbilicalCarePerDay) || other.umbilicalCarePerDay == umbilicalCarePerDay)&&(identical(other.bathEveryDays, bathEveryDays) || other.bathEveryDays == bathEveryDays)&&(identical(other.feedsPerDay, feedsPerDay) || other.feedsPerDay == feedsPerDay)&&(identical(other.nightStartHour, nightStartHour) || other.nightStartHour == nightStartHour)&&(identical(other.nightEndHour, nightEndHour) || other.nightEndHour == nightEndHour)&&(identical(other.dailyTargetMl, dailyTargetMl) || other.dailyTargetMl == dailyTargetMl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,adrigylPerDay,eyeCarePerDay,noseCarePerDay,umbilicalCarePerDay,bathEveryDays,feedsPerDay,nightStartHour,nightEndHour,dailyTargetMl);
}

@override
String toString() {
    return 'CareSettings(adrigylPerDay: $adrigylPerDay, eyeCarePerDay: $eyeCarePerDay, noseCarePerDay: $noseCarePerDay, umbilicalCarePerDay: $umbilicalCarePerDay, bathEveryDays: $bathEveryDays, feedsPerDay: $feedsPerDay, nightStartHour: $nightStartHour, nightEndHour: $nightEndHour, dailyTargetMl: $dailyTargetMl)';
}


}

/// @nodoc
abstract mixin class _$CareSettingsCopyWith<$Res> implements $CareSettingsCopyWith<$Res> {
  factory _$CareSettingsCopyWith(_CareSettings value, $Res Function(_CareSettings) _then) = __$CareSettingsCopyWithImpl;
@override @useResult
$Res call({
 int adrigylPerDay, int eyeCarePerDay, int noseCarePerDay, int umbilicalCarePerDay, int bathEveryDays, int feedsPerDay, int nightStartHour, int nightEndHour, int? dailyTargetMl
});




}
/// @nodoc
class __$CareSettingsCopyWithImpl<$Res>
    implements _$CareSettingsCopyWith<$Res> {
  __$CareSettingsCopyWithImpl(this._self, this._then);

  final _CareSettings _self;
  final $Res Function(_CareSettings) _then;

/// Create a copy of CareSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? adrigylPerDay = null,Object? eyeCarePerDay = null,Object? noseCarePerDay = null,Object? umbilicalCarePerDay = null,Object? bathEveryDays = null,Object? feedsPerDay = null,Object? nightStartHour = null,Object? nightEndHour = null,Object? dailyTargetMl = freezed,}) {
  return _then(_CareSettings(
adrigylPerDay: null == adrigylPerDay ? _self.adrigylPerDay : adrigylPerDay // ignore: cast_nullable_to_non_nullable
as int,eyeCarePerDay: null == eyeCarePerDay ? _self.eyeCarePerDay : eyeCarePerDay // ignore: cast_nullable_to_non_nullable
as int,noseCarePerDay: null == noseCarePerDay ? _self.noseCarePerDay : noseCarePerDay // ignore: cast_nullable_to_non_nullable
as int,umbilicalCarePerDay: null == umbilicalCarePerDay ? _self.umbilicalCarePerDay : umbilicalCarePerDay // ignore: cast_nullable_to_non_nullable
as int,bathEveryDays: null == bathEveryDays ? _self.bathEveryDays : bathEveryDays // ignore: cast_nullable_to_non_nullable
as int,feedsPerDay: null == feedsPerDay ? _self.feedsPerDay : feedsPerDay // ignore: cast_nullable_to_non_nullable
as int,nightStartHour: null == nightStartHour ? _self.nightStartHour : nightStartHour // ignore: cast_nullable_to_non_nullable
as int,nightEndHour: null == nightEndHour ? _self.nightEndHour : nightEndHour // ignore: cast_nullable_to_non_nullable
as int,dailyTargetMl: freezed == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
