// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentEntry {

 String get name; String get path; bool get isDirectory; int get size; DateTime get modifiedAt; DownloadStatus get downloadStatus;/// Progression du téléchargement iCloud (0 à 1), `null` hors téléchargement.
 double? get downloadProgress;
/// Create a copy of DocumentEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentEntryCopyWith<DocumentEntry> get copyWith => _$DocumentEntryCopyWithImpl<DocumentEntry>(this as DocumentEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DocumentEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentEntry&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.isDirectory, _this.isDirectory) || other.isDirectory == _this.isDirectory)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.modifiedAt, _this.modifiedAt) || other.modifiedAt == _this.modifiedAt)&&(identical(other.downloadStatus, _this.downloadStatus) || other.downloadStatus == _this.downloadStatus)&&(identical(other.downloadProgress, _this.downloadProgress) || other.downloadProgress == _this.downloadProgress));
}


@override
int get hashCode {
  final _this = this as DocumentEntry;
  return Object.hash(runtimeType,_this.name,_this.path,_this.isDirectory,_this.size,_this.modifiedAt,_this.downloadStatus,_this.downloadProgress);
}

@override
String toString() {
  final _this = this as DocumentEntry;
  return 'DocumentEntry(name: ${_this.name}, path: ${_this.path}, isDirectory: ${_this.isDirectory}, size: ${_this.size}, modifiedAt: ${_this.modifiedAt}, downloadStatus: ${_this.downloadStatus}, downloadProgress: ${_this.downloadProgress})';
}


}

/// @nodoc
abstract mixin class $DocumentEntryCopyWith<$Res>  {
  factory $DocumentEntryCopyWith(DocumentEntry value, $Res Function(DocumentEntry) _then) = _$DocumentEntryCopyWithImpl;
@useResult
$Res call({
 String name, String path, bool isDirectory, int size, DateTime modifiedAt, DownloadStatus downloadStatus, double? downloadProgress
});




}
/// @nodoc
class _$DocumentEntryCopyWithImpl<$Res>
    implements $DocumentEntryCopyWith<$Res> {
  _$DocumentEntryCopyWithImpl(this._self, this._then);

  final DocumentEntry _self;
  final $Res Function(DocumentEntry) _then;

/// Create a copy of DocumentEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? size = null,Object? modifiedAt = null,Object? downloadStatus = null,Object? downloadProgress = freezed,}) {
  return _then(DocumentEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,downloadStatus: null == downloadStatus ? _self.downloadStatus : downloadStatus // ignore: cast_nullable_to_non_nullable
as DownloadStatus,downloadProgress: freezed == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentEntry].
extension DocumentEntryPatterns on DocumentEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentEntry value)  $default,){
final _that = this;
switch (_that) {
case _DocumentEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  int size,  DateTime modifiedAt,  DownloadStatus downloadStatus,  double? downloadProgress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt,_that.downloadStatus,_that.downloadProgress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  int size,  DateTime modifiedAt,  DownloadStatus downloadStatus,  double? downloadProgress)  $default,) {final _that = this;
switch (_that) {
case _DocumentEntry():
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt,_that.downloadStatus,_that.downloadProgress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  bool isDirectory,  int size,  DateTime modifiedAt,  DownloadStatus downloadStatus,  double? downloadProgress)?  $default,) {final _that = this;
switch (_that) {
case _DocumentEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt,_that.downloadStatus,_that.downloadProgress);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentEntry implements DocumentEntry {
  const _DocumentEntry({required this.name, required this.path, required this.isDirectory, required this.size, required this.modifiedAt, required this.downloadStatus, this.downloadProgress});
  

@override final  String name;
@override final  String path;
@override final  bool isDirectory;
@override final  int size;
@override final  DateTime modifiedAt;
@override final  DownloadStatus downloadStatus;
/// Progression du téléchargement iCloud (0 à 1), `null` hors téléchargement.
@override final  double? downloadProgress;

/// Create a copy of DocumentEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentEntryCopyWith<_DocumentEntry> get copyWith => __$DocumentEntryCopyWithImpl<_DocumentEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.downloadStatus, downloadStatus) || other.downloadStatus == downloadStatus)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,path,isDirectory,size,modifiedAt,downloadStatus,downloadProgress);
}

@override
String toString() {
    return 'DocumentEntry(name: $name, path: $path, isDirectory: $isDirectory, size: $size, modifiedAt: $modifiedAt, downloadStatus: $downloadStatus, downloadProgress: $downloadProgress)';
}


}

/// @nodoc
abstract mixin class _$DocumentEntryCopyWith<$Res> implements $DocumentEntryCopyWith<$Res> {
  factory _$DocumentEntryCopyWith(_DocumentEntry value, $Res Function(_DocumentEntry) _then) = __$DocumentEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, bool isDirectory, int size, DateTime modifiedAt, DownloadStatus downloadStatus, double? downloadProgress
});




}
/// @nodoc
class __$DocumentEntryCopyWithImpl<$Res>
    implements _$DocumentEntryCopyWith<$Res> {
  __$DocumentEntryCopyWithImpl(this._self, this._then);

  final _DocumentEntry _self;
  final $Res Function(_DocumentEntry) _then;

/// Create a copy of DocumentEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? size = null,Object? modifiedAt = null,Object? downloadStatus = null,Object? downloadProgress = freezed,}) {
  return _then(_DocumentEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,downloadStatus: null == downloadStatus ? _self.downloadStatus : downloadStatus // ignore: cast_nullable_to_non_nullable
as DownloadStatus,downloadProgress: freezed == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
