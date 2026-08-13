// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActionSchema {

 String get name; String get description;@ActionKindConverter() ActionKind get kind; String get permission; List<ActionParam> get params;
/// Create a copy of ActionSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionSchemaCopyWith<ActionSchema> get copyWith => _$ActionSchemaCopyWithImpl<ActionSchema>(this as ActionSchema, _$identity);

  /// Serializes this ActionSchema to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionSchema&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,kind,permission,const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'ActionSchema(name: $name, description: $description, kind: $kind, permission: $permission, params: $params)';
}


}

/// @nodoc
abstract mixin class $ActionSchemaCopyWith<$Res>  {
  factory $ActionSchemaCopyWith(ActionSchema value, $Res Function(ActionSchema) _then) = _$ActionSchemaCopyWithImpl;
@useResult
$Res call({
 String name, String description,@ActionKindConverter() ActionKind kind, String permission, List<ActionParam> params
});




}
/// @nodoc
class _$ActionSchemaCopyWithImpl<$Res>
    implements $ActionSchemaCopyWith<$Res> {
  _$ActionSchemaCopyWithImpl(this._self, this._then);

  final ActionSchema _self;
  final $Res Function(ActionSchema) _then;

/// Create a copy of ActionSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? kind = null,Object? permission = null,Object? params = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActionKind,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as List<ActionParam>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionSchema].
extension ActionSchemaPatterns on ActionSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionSchema value)  $default,){
final _that = this;
switch (_that) {
case _ActionSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionSchema value)?  $default,){
final _that = this;
switch (_that) {
case _ActionSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description, @ActionKindConverter()  ActionKind kind,  String permission,  List<ActionParam> params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionSchema() when $default != null:
return $default(_that.name,_that.description,_that.kind,_that.permission,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description, @ActionKindConverter()  ActionKind kind,  String permission,  List<ActionParam> params)  $default,) {final _that = this;
switch (_that) {
case _ActionSchema():
return $default(_that.name,_that.description,_that.kind,_that.permission,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description, @ActionKindConverter()  ActionKind kind,  String permission,  List<ActionParam> params)?  $default,) {final _that = this;
switch (_that) {
case _ActionSchema() when $default != null:
return $default(_that.name,_that.description,_that.kind,_that.permission,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionSchema extends ActionSchema {
  const _ActionSchema({required this.name, this.description = '', @ActionKindConverter() required this.kind, required this.permission, final  List<ActionParam> params = const <ActionParam>[]}): _params = params,super._();
  factory _ActionSchema.fromJson(Map<String, dynamic> json) => _$ActionSchemaFromJson(json);

@override final  String name;
@override@JsonKey() final  String description;
@override@ActionKindConverter() final  ActionKind kind;
@override final  String permission;
 final  List<ActionParam> _params;
@override@JsonKey() List<ActionParam> get params {
  if (_params is EqualUnmodifiableListView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_params);
}


/// Create a copy of ActionSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionSchemaCopyWith<_ActionSchema> get copyWith => __$ActionSchemaCopyWithImpl<_ActionSchema>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionSchemaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionSchema&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,kind,permission,const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'ActionSchema(name: $name, description: $description, kind: $kind, permission: $permission, params: $params)';
}


}

/// @nodoc
abstract mixin class _$ActionSchemaCopyWith<$Res> implements $ActionSchemaCopyWith<$Res> {
  factory _$ActionSchemaCopyWith(_ActionSchema value, $Res Function(_ActionSchema) _then) = __$ActionSchemaCopyWithImpl;
@override @useResult
$Res call({
 String name, String description,@ActionKindConverter() ActionKind kind, String permission, List<ActionParam> params
});




}
/// @nodoc
class __$ActionSchemaCopyWithImpl<$Res>
    implements _$ActionSchemaCopyWith<$Res> {
  __$ActionSchemaCopyWithImpl(this._self, this._then);

  final _ActionSchema _self;
  final $Res Function(_ActionSchema) _then;

/// Create a copy of ActionSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? kind = null,Object? permission = null,Object? params = null,}) {
  return _then(_ActionSchema(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActionKind,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as List<ActionParam>,
  ));
}


}


/// @nodoc
mixin _$ActionParam {

 String get name; String get description;@ActionParamTypeConverter() ActionParamType get type; bool get required; List<String> get choices;@JsonKey(name: 'default') dynamic get defaultValue;/// Whether this string param is a git branch name — see
/// `ParamSpec.isBranchRef` on the server. `name` doubles as the repo key
/// for `GET /autocomplete/branches?repo={name}`.
 bool get isBranchRef;
/// Create a copy of ActionParam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionParamCopyWith<ActionParam> get copyWith => _$ActionParamCopyWithImpl<ActionParam>(this as ActionParam, _$identity);

  /// Serializes this ActionParam to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionParam&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other.choices, choices)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue)&&(identical(other.isBranchRef, isBranchRef) || other.isBranchRef == isBranchRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,type,required,const DeepCollectionEquality().hash(choices),const DeepCollectionEquality().hash(defaultValue),isBranchRef);

@override
String toString() {
  return 'ActionParam(name: $name, description: $description, type: $type, required: $required, choices: $choices, defaultValue: $defaultValue, isBranchRef: $isBranchRef)';
}


}

/// @nodoc
abstract mixin class $ActionParamCopyWith<$Res>  {
  factory $ActionParamCopyWith(ActionParam value, $Res Function(ActionParam) _then) = _$ActionParamCopyWithImpl;
@useResult
$Res call({
 String name, String description,@ActionParamTypeConverter() ActionParamType type, bool required, List<String> choices,@JsonKey(name: 'default') dynamic defaultValue, bool isBranchRef
});




}
/// @nodoc
class _$ActionParamCopyWithImpl<$Res>
    implements $ActionParamCopyWith<$Res> {
  _$ActionParamCopyWithImpl(this._self, this._then);

  final ActionParam _self;
  final $Res Function(ActionParam) _then;

/// Create a copy of ActionParam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? type = null,Object? required = null,Object? choices = null,Object? defaultValue = freezed,Object? isBranchRef = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ActionParamType,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as dynamic,isBranchRef: null == isBranchRef ? _self.isBranchRef : isBranchRef // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionParam].
extension ActionParamPatterns on ActionParam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionParam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionParam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionParam value)  $default,){
final _that = this;
switch (_that) {
case _ActionParam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionParam value)?  $default,){
final _that = this;
switch (_that) {
case _ActionParam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description, @ActionParamTypeConverter()  ActionParamType type,  bool required,  List<String> choices, @JsonKey(name: 'default')  dynamic defaultValue,  bool isBranchRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionParam() when $default != null:
return $default(_that.name,_that.description,_that.type,_that.required,_that.choices,_that.defaultValue,_that.isBranchRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description, @ActionParamTypeConverter()  ActionParamType type,  bool required,  List<String> choices, @JsonKey(name: 'default')  dynamic defaultValue,  bool isBranchRef)  $default,) {final _that = this;
switch (_that) {
case _ActionParam():
return $default(_that.name,_that.description,_that.type,_that.required,_that.choices,_that.defaultValue,_that.isBranchRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description, @ActionParamTypeConverter()  ActionParamType type,  bool required,  List<String> choices, @JsonKey(name: 'default')  dynamic defaultValue,  bool isBranchRef)?  $default,) {final _that = this;
switch (_that) {
case _ActionParam() when $default != null:
return $default(_that.name,_that.description,_that.type,_that.required,_that.choices,_that.defaultValue,_that.isBranchRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionParam implements ActionParam {
  const _ActionParam({required this.name, this.description = '', @ActionParamTypeConverter() required this.type, this.required = false, final  List<String> choices = const <String>[], @JsonKey(name: 'default') this.defaultValue, this.isBranchRef = false}): _choices = choices;
  factory _ActionParam.fromJson(Map<String, dynamic> json) => _$ActionParamFromJson(json);

@override final  String name;
@override@JsonKey() final  String description;
@override@ActionParamTypeConverter() final  ActionParamType type;
@override@JsonKey() final  bool required;
 final  List<String> _choices;
@override@JsonKey() List<String> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}

@override@JsonKey(name: 'default') final  dynamic defaultValue;
/// Whether this string param is a git branch name — see
/// `ParamSpec.isBranchRef` on the server. `name` doubles as the repo key
/// for `GET /autocomplete/branches?repo={name}`.
@override@JsonKey() final  bool isBranchRef;

/// Create a copy of ActionParam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionParamCopyWith<_ActionParam> get copyWith => __$ActionParamCopyWithImpl<_ActionParam>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionParamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionParam&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other._choices, _choices)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue)&&(identical(other.isBranchRef, isBranchRef) || other.isBranchRef == isBranchRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,type,required,const DeepCollectionEquality().hash(_choices),const DeepCollectionEquality().hash(defaultValue),isBranchRef);

@override
String toString() {
  return 'ActionParam(name: $name, description: $description, type: $type, required: $required, choices: $choices, defaultValue: $defaultValue, isBranchRef: $isBranchRef)';
}


}

/// @nodoc
abstract mixin class _$ActionParamCopyWith<$Res> implements $ActionParamCopyWith<$Res> {
  factory _$ActionParamCopyWith(_ActionParam value, $Res Function(_ActionParam) _then) = __$ActionParamCopyWithImpl;
@override @useResult
$Res call({
 String name, String description,@ActionParamTypeConverter() ActionParamType type, bool required, List<String> choices,@JsonKey(name: 'default') dynamic defaultValue, bool isBranchRef
});




}
/// @nodoc
class __$ActionParamCopyWithImpl<$Res>
    implements _$ActionParamCopyWith<$Res> {
  __$ActionParamCopyWithImpl(this._self, this._then);

  final _ActionParam _self;
  final $Res Function(_ActionParam) _then;

/// Create a copy of ActionParam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? type = null,Object? required = null,Object? choices = null,Object? defaultValue = freezed,Object? isBranchRef = null,}) {
  return _then(_ActionParam(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ActionParamType,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as dynamic,isBranchRef: null == isBranchRef ? _self.isBranchRef : isBranchRef // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
