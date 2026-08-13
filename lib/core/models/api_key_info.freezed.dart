// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_key_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiKeyInfo {

 String get id; String get name; String get keyHash; List<String> get scopes;@JsonKey(fromJson: _discordUserIdFromJson) String? get discordUserId;
/// Create a copy of ApiKeyInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiKeyInfoCopyWith<ApiKeyInfo> get copyWith => _$ApiKeyInfoCopyWithImpl<ApiKeyInfo>(this as ApiKeyInfo, _$identity);

  /// Serializes this ApiKeyInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiKeyInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.keyHash, keyHash) || other.keyHash == keyHash)&&const DeepCollectionEquality().equals(other.scopes, scopes)&&(identical(other.discordUserId, discordUserId) || other.discordUserId == discordUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,keyHash,const DeepCollectionEquality().hash(scopes),discordUserId);

@override
String toString() {
  return 'ApiKeyInfo(id: $id, name: $name, keyHash: $keyHash, scopes: $scopes, discordUserId: $discordUserId)';
}


}

/// @nodoc
abstract mixin class $ApiKeyInfoCopyWith<$Res>  {
  factory $ApiKeyInfoCopyWith(ApiKeyInfo value, $Res Function(ApiKeyInfo) _then) = _$ApiKeyInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String keyHash, List<String> scopes,@JsonKey(fromJson: _discordUserIdFromJson) String? discordUserId
});




}
/// @nodoc
class _$ApiKeyInfoCopyWithImpl<$Res>
    implements $ApiKeyInfoCopyWith<$Res> {
  _$ApiKeyInfoCopyWithImpl(this._self, this._then);

  final ApiKeyInfo _self;
  final $Res Function(ApiKeyInfo) _then;

/// Create a copy of ApiKeyInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? keyHash = null,Object? scopes = null,Object? discordUserId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyHash: null == keyHash ? _self.keyHash : keyHash // ignore: cast_nullable_to_non_nullable
as String,scopes: null == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,discordUserId: freezed == discordUserId ? _self.discordUserId : discordUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiKeyInfo].
extension ApiKeyInfoPatterns on ApiKeyInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiKeyInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiKeyInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiKeyInfo value)  $default,){
final _that = this;
switch (_that) {
case _ApiKeyInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiKeyInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ApiKeyInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String keyHash,  List<String> scopes, @JsonKey(fromJson: _discordUserIdFromJson)  String? discordUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiKeyInfo() when $default != null:
return $default(_that.id,_that.name,_that.keyHash,_that.scopes,_that.discordUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String keyHash,  List<String> scopes, @JsonKey(fromJson: _discordUserIdFromJson)  String? discordUserId)  $default,) {final _that = this;
switch (_that) {
case _ApiKeyInfo():
return $default(_that.id,_that.name,_that.keyHash,_that.scopes,_that.discordUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String keyHash,  List<String> scopes, @JsonKey(fromJson: _discordUserIdFromJson)  String? discordUserId)?  $default,) {final _that = this;
switch (_that) {
case _ApiKeyInfo() when $default != null:
return $default(_that.id,_that.name,_that.keyHash,_that.scopes,_that.discordUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiKeyInfo extends ApiKeyInfo {
  const _ApiKeyInfo({required this.id, required this.name, required this.keyHash, required final  List<String> scopes, @JsonKey(fromJson: _discordUserIdFromJson) this.discordUserId}): _scopes = scopes,super._();
  factory _ApiKeyInfo.fromJson(Map<String, dynamic> json) => _$ApiKeyInfoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String keyHash;
 final  List<String> _scopes;
@override List<String> get scopes {
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scopes);
}

@override@JsonKey(fromJson: _discordUserIdFromJson) final  String? discordUserId;

/// Create a copy of ApiKeyInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiKeyInfoCopyWith<_ApiKeyInfo> get copyWith => __$ApiKeyInfoCopyWithImpl<_ApiKeyInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiKeyInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiKeyInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.keyHash, keyHash) || other.keyHash == keyHash)&&const DeepCollectionEquality().equals(other._scopes, _scopes)&&(identical(other.discordUserId, discordUserId) || other.discordUserId == discordUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,keyHash,const DeepCollectionEquality().hash(_scopes),discordUserId);

@override
String toString() {
  return 'ApiKeyInfo(id: $id, name: $name, keyHash: $keyHash, scopes: $scopes, discordUserId: $discordUserId)';
}


}

/// @nodoc
abstract mixin class _$ApiKeyInfoCopyWith<$Res> implements $ApiKeyInfoCopyWith<$Res> {
  factory _$ApiKeyInfoCopyWith(_ApiKeyInfo value, $Res Function(_ApiKeyInfo) _then) = __$ApiKeyInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String keyHash, List<String> scopes,@JsonKey(fromJson: _discordUserIdFromJson) String? discordUserId
});




}
/// @nodoc
class __$ApiKeyInfoCopyWithImpl<$Res>
    implements _$ApiKeyInfoCopyWith<$Res> {
  __$ApiKeyInfoCopyWithImpl(this._self, this._then);

  final _ApiKeyInfo _self;
  final $Res Function(_ApiKeyInfo) _then;

/// Create a copy of ApiKeyInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? keyHash = null,Object? scopes = null,Object? discordUserId = freezed,}) {
  return _then(_ApiKeyInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyHash: null == keyHash ? _self.keyHash : keyHash // ignore: cast_nullable_to_non_nullable
as String,scopes: null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,discordUserId: freezed == discordUserId ? _self.discordUserId : discordUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
