// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artifact_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtifactFile {

 String get name; bool get isDirectory; int? get size; DateTime get modified;
/// Create a copy of ArtifactFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtifactFileCopyWith<ArtifactFile> get copyWith => _$ArtifactFileCopyWithImpl<ArtifactFile>(this as ArtifactFile, _$identity);

  /// Serializes this ArtifactFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtifactFile&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modified, modified) || other.modified == modified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,isDirectory,size,modified);

@override
String toString() {
  return 'ArtifactFile(name: $name, isDirectory: $isDirectory, size: $size, modified: $modified)';
}


}

/// @nodoc
abstract mixin class $ArtifactFileCopyWith<$Res>  {
  factory $ArtifactFileCopyWith(ArtifactFile value, $Res Function(ArtifactFile) _then) = _$ArtifactFileCopyWithImpl;
@useResult
$Res call({
 String name, bool isDirectory, int? size, DateTime modified
});




}
/// @nodoc
class _$ArtifactFileCopyWithImpl<$Res>
    implements $ArtifactFileCopyWith<$Res> {
  _$ArtifactFileCopyWithImpl(this._self, this._then);

  final ArtifactFile _self;
  final $Res Function(ArtifactFile) _then;

/// Create a copy of ArtifactFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? isDirectory = null,Object? size = freezed,Object? modified = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtifactFile].
extension ArtifactFilePatterns on ArtifactFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtifactFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtifactFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtifactFile value)  $default,){
final _that = this;
switch (_that) {
case _ArtifactFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtifactFile value)?  $default,){
final _that = this;
switch (_that) {
case _ArtifactFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool isDirectory,  int? size,  DateTime modified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtifactFile() when $default != null:
return $default(_that.name,_that.isDirectory,_that.size,_that.modified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool isDirectory,  int? size,  DateTime modified)  $default,) {final _that = this;
switch (_that) {
case _ArtifactFile():
return $default(_that.name,_that.isDirectory,_that.size,_that.modified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool isDirectory,  int? size,  DateTime modified)?  $default,) {final _that = this;
switch (_that) {
case _ArtifactFile() when $default != null:
return $default(_that.name,_that.isDirectory,_that.size,_that.modified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtifactFile implements ArtifactFile {
  const _ArtifactFile({required this.name, this.isDirectory = false, this.size, required this.modified});
  factory _ArtifactFile.fromJson(Map<String, dynamic> json) => _$ArtifactFileFromJson(json);

@override final  String name;
@override@JsonKey() final  bool isDirectory;
@override final  int? size;
@override final  DateTime modified;

/// Create a copy of ArtifactFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtifactFileCopyWith<_ArtifactFile> get copyWith => __$ArtifactFileCopyWithImpl<_ArtifactFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtifactFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtifactFile&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modified, modified) || other.modified == modified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,isDirectory,size,modified);

@override
String toString() {
  return 'ArtifactFile(name: $name, isDirectory: $isDirectory, size: $size, modified: $modified)';
}


}

/// @nodoc
abstract mixin class _$ArtifactFileCopyWith<$Res> implements $ArtifactFileCopyWith<$Res> {
  factory _$ArtifactFileCopyWith(_ArtifactFile value, $Res Function(_ArtifactFile) _then) = __$ArtifactFileCopyWithImpl;
@override @useResult
$Res call({
 String name, bool isDirectory, int? size, DateTime modified
});




}
/// @nodoc
class __$ArtifactFileCopyWithImpl<$Res>
    implements _$ArtifactFileCopyWith<$Res> {
  __$ArtifactFileCopyWithImpl(this._self, this._then);

  final _ArtifactFile _self;
  final $Res Function(_ArtifactFile) _then;

/// Create a copy of ArtifactFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? isDirectory = null,Object? size = freezed,Object? modified = null,}) {
  return _then(_ArtifactFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ArtifactListing {

 String get key; List<ArtifactFile> get files; Job? get job;
/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtifactListingCopyWith<ArtifactListing> get copyWith => _$ArtifactListingCopyWithImpl<ArtifactListing>(this as ArtifactListing, _$identity);

  /// Serializes this ArtifactListing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtifactListing&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.job, job) || other.job == job));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(files),job);

@override
String toString() {
  return 'ArtifactListing(key: $key, files: $files, job: $job)';
}


}

/// @nodoc
abstract mixin class $ArtifactListingCopyWith<$Res>  {
  factory $ArtifactListingCopyWith(ArtifactListing value, $Res Function(ArtifactListing) _then) = _$ArtifactListingCopyWithImpl;
@useResult
$Res call({
 String key, List<ArtifactFile> files, Job? job
});


$JobCopyWith<$Res>? get job;

}
/// @nodoc
class _$ArtifactListingCopyWithImpl<$Res>
    implements $ArtifactListingCopyWith<$Res> {
  _$ArtifactListingCopyWithImpl(this._self, this._then);

  final ArtifactListing _self;
  final $Res Function(ArtifactListing) _then;

/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? files = null,Object? job = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<ArtifactFile>,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as Job?,
  ));
}
/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobCopyWith<$Res>? get job {
    if (_self.job == null) {
    return null;
  }

  return $JobCopyWith<$Res>(_self.job!, (value) {
    return _then(_self.copyWith(job: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtifactListing].
extension ArtifactListingPatterns on ArtifactListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtifactListing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtifactListing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtifactListing value)  $default,){
final _that = this;
switch (_that) {
case _ArtifactListing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtifactListing value)?  $default,){
final _that = this;
switch (_that) {
case _ArtifactListing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  List<ArtifactFile> files,  Job? job)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtifactListing() when $default != null:
return $default(_that.key,_that.files,_that.job);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  List<ArtifactFile> files,  Job? job)  $default,) {final _that = this;
switch (_that) {
case _ArtifactListing():
return $default(_that.key,_that.files,_that.job);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  List<ArtifactFile> files,  Job? job)?  $default,) {final _that = this;
switch (_that) {
case _ArtifactListing() when $default != null:
return $default(_that.key,_that.files,_that.job);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtifactListing implements ArtifactListing {
  const _ArtifactListing({required this.key, final  List<ArtifactFile> files = const <ArtifactFile>[], this.job}): _files = files;
  factory _ArtifactListing.fromJson(Map<String, dynamic> json) => _$ArtifactListingFromJson(json);

@override final  String key;
 final  List<ArtifactFile> _files;
@override@JsonKey() List<ArtifactFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

@override final  Job? job;

/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtifactListingCopyWith<_ArtifactListing> get copyWith => __$ArtifactListingCopyWithImpl<_ArtifactListing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtifactListingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtifactListing&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.job, job) || other.job == job));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(_files),job);

@override
String toString() {
  return 'ArtifactListing(key: $key, files: $files, job: $job)';
}


}

/// @nodoc
abstract mixin class _$ArtifactListingCopyWith<$Res> implements $ArtifactListingCopyWith<$Res> {
  factory _$ArtifactListingCopyWith(_ArtifactListing value, $Res Function(_ArtifactListing) _then) = __$ArtifactListingCopyWithImpl;
@override @useResult
$Res call({
 String key, List<ArtifactFile> files, Job? job
});


@override $JobCopyWith<$Res>? get job;

}
/// @nodoc
class __$ArtifactListingCopyWithImpl<$Res>
    implements _$ArtifactListingCopyWith<$Res> {
  __$ArtifactListingCopyWithImpl(this._self, this._then);

  final _ArtifactListing _self;
  final $Res Function(_ArtifactListing) _then;

/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? files = null,Object? job = freezed,}) {
  return _then(_ArtifactListing(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<ArtifactFile>,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as Job?,
  ));
}

/// Create a copy of ArtifactListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobCopyWith<$Res>? get job {
    if (_self.job == null) {
    return null;
  }

  return $JobCopyWith<$Res>(_self.job!, (value) {
    return _then(_self.copyWith(job: value));
  });
}
}

// dart format on
