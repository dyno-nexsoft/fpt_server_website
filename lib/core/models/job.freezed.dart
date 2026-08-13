// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Job {

 String get id;@JobStateConverter() JobState get state; String get command;/// Null for a handful of legacy/cron records with no recorded action —
/// see docs/rest-api.md. Every job created through an Action always has
/// one; this only stays nullable for those historical outliers.
 String? get actionName; Map<String, dynamic> get actionParams; Map<String, dynamic> get environments; String? get createdBy; int? get artifactKey; bool get promoted; bool get announce; DateTime get createdAt; DateTime? get startedAt; DateTime? get finishedAt; int? get exitCode; String? get lastLine; int get lastSeq;@JsonKey(readValue: _readDiscordChannelId) String? get discordChannelId;@JsonKey(readValue: _readDiscordMessageId) String? get discordMessageId; String? get logUrl; List<String> get warnings;/// Only populated on `/cancel` responses — the confirmation text.
 String? get message;/// Id of the job this one replaced after a server restart re-invoked its
/// recorded action — see docs/rest-api.md "Restart mid-build". Null for
/// every job created the normal way.
 String? get resumedFrom;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.command, command) || other.command == command)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&const DeepCollectionEquality().equals(other.actionParams, actionParams)&&const DeepCollectionEquality().equals(other.environments, environments)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.artifactKey, artifactKey) || other.artifactKey == artifactKey)&&(identical(other.promoted, promoted) || other.promoted == promoted)&&(identical(other.announce, announce) || other.announce == announce)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.lastLine, lastLine) || other.lastLine == lastLine)&&(identical(other.lastSeq, lastSeq) || other.lastSeq == lastSeq)&&(identical(other.discordChannelId, discordChannelId) || other.discordChannelId == discordChannelId)&&(identical(other.discordMessageId, discordMessageId) || other.discordMessageId == discordMessageId)&&(identical(other.logUrl, logUrl) || other.logUrl == logUrl)&&const DeepCollectionEquality().equals(other.warnings, warnings)&&(identical(other.message, message) || other.message == message)&&(identical(other.resumedFrom, resumedFrom) || other.resumedFrom == resumedFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,state,command,actionName,const DeepCollectionEquality().hash(actionParams),const DeepCollectionEquality().hash(environments),createdBy,artifactKey,promoted,announce,createdAt,startedAt,finishedAt,exitCode,lastLine,lastSeq,discordChannelId,discordMessageId,logUrl,const DeepCollectionEquality().hash(warnings),message,resumedFrom]);

@override
String toString() {
  return 'Job(id: $id, state: $state, command: $command, actionName: $actionName, actionParams: $actionParams, environments: $environments, createdBy: $createdBy, artifactKey: $artifactKey, promoted: $promoted, announce: $announce, createdAt: $createdAt, startedAt: $startedAt, finishedAt: $finishedAt, exitCode: $exitCode, lastLine: $lastLine, lastSeq: $lastSeq, discordChannelId: $discordChannelId, discordMessageId: $discordMessageId, logUrl: $logUrl, warnings: $warnings, message: $message, resumedFrom: $resumedFrom)';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
 String id,@JobStateConverter() JobState state, String command, String? actionName, Map<String, dynamic> actionParams, Map<String, dynamic> environments, String? createdBy, int? artifactKey, bool promoted, bool announce, DateTime createdAt, DateTime? startedAt, DateTime? finishedAt, int? exitCode, String? lastLine, int lastSeq,@JsonKey(readValue: _readDiscordChannelId) String? discordChannelId,@JsonKey(readValue: _readDiscordMessageId) String? discordMessageId, String? logUrl, List<String> warnings, String? message, String? resumedFrom
});




}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? state = null,Object? command = null,Object? actionName = freezed,Object? actionParams = null,Object? environments = null,Object? createdBy = freezed,Object? artifactKey = freezed,Object? promoted = null,Object? announce = null,Object? createdAt = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? exitCode = freezed,Object? lastLine = freezed,Object? lastSeq = null,Object? discordChannelId = freezed,Object? discordMessageId = freezed,Object? logUrl = freezed,Object? warnings = null,Object? message = freezed,Object? resumedFrom = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as JobState,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,actionName: freezed == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String?,actionParams: null == actionParams ? _self.actionParams : actionParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,environments: null == environments ? _self.environments : environments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,artifactKey: freezed == artifactKey ? _self.artifactKey : artifactKey // ignore: cast_nullable_to_non_nullable
as int?,promoted: null == promoted ? _self.promoted : promoted // ignore: cast_nullable_to_non_nullable
as bool,announce: null == announce ? _self.announce : announce // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,lastLine: freezed == lastLine ? _self.lastLine : lastLine // ignore: cast_nullable_to_non_nullable
as String?,lastSeq: null == lastSeq ? _self.lastSeq : lastSeq // ignore: cast_nullable_to_non_nullable
as int,discordChannelId: freezed == discordChannelId ? _self.discordChannelId : discordChannelId // ignore: cast_nullable_to_non_nullable
as String?,discordMessageId: freezed == discordMessageId ? _self.discordMessageId : discordMessageId // ignore: cast_nullable_to_non_nullable
as String?,logUrl: freezed == logUrl ? _self.logUrl : logUrl // ignore: cast_nullable_to_non_nullable
as String?,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,resumedFrom: freezed == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JobStateConverter()  JobState state,  String command,  String? actionName,  Map<String, dynamic> actionParams,  Map<String, dynamic> environments,  String? createdBy,  int? artifactKey,  bool promoted,  bool announce,  DateTime createdAt,  DateTime? startedAt,  DateTime? finishedAt,  int? exitCode,  String? lastLine,  int lastSeq, @JsonKey(readValue: _readDiscordChannelId)  String? discordChannelId, @JsonKey(readValue: _readDiscordMessageId)  String? discordMessageId,  String? logUrl,  List<String> warnings,  String? message,  String? resumedFrom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.state,_that.command,_that.actionName,_that.actionParams,_that.environments,_that.createdBy,_that.artifactKey,_that.promoted,_that.announce,_that.createdAt,_that.startedAt,_that.finishedAt,_that.exitCode,_that.lastLine,_that.lastSeq,_that.discordChannelId,_that.discordMessageId,_that.logUrl,_that.warnings,_that.message,_that.resumedFrom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JobStateConverter()  JobState state,  String command,  String? actionName,  Map<String, dynamic> actionParams,  Map<String, dynamic> environments,  String? createdBy,  int? artifactKey,  bool promoted,  bool announce,  DateTime createdAt,  DateTime? startedAt,  DateTime? finishedAt,  int? exitCode,  String? lastLine,  int lastSeq, @JsonKey(readValue: _readDiscordChannelId)  String? discordChannelId, @JsonKey(readValue: _readDiscordMessageId)  String? discordMessageId,  String? logUrl,  List<String> warnings,  String? message,  String? resumedFrom)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.id,_that.state,_that.command,_that.actionName,_that.actionParams,_that.environments,_that.createdBy,_that.artifactKey,_that.promoted,_that.announce,_that.createdAt,_that.startedAt,_that.finishedAt,_that.exitCode,_that.lastLine,_that.lastSeq,_that.discordChannelId,_that.discordMessageId,_that.logUrl,_that.warnings,_that.message,_that.resumedFrom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JobStateConverter()  JobState state,  String command,  String? actionName,  Map<String, dynamic> actionParams,  Map<String, dynamic> environments,  String? createdBy,  int? artifactKey,  bool promoted,  bool announce,  DateTime createdAt,  DateTime? startedAt,  DateTime? finishedAt,  int? exitCode,  String? lastLine,  int lastSeq, @JsonKey(readValue: _readDiscordChannelId)  String? discordChannelId, @JsonKey(readValue: _readDiscordMessageId)  String? discordMessageId,  String? logUrl,  List<String> warnings,  String? message,  String? resumedFrom)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.state,_that.command,_that.actionName,_that.actionParams,_that.environments,_that.createdBy,_that.artifactKey,_that.promoted,_that.announce,_that.createdAt,_that.startedAt,_that.finishedAt,_that.exitCode,_that.lastLine,_that.lastSeq,_that.discordChannelId,_that.discordMessageId,_that.logUrl,_that.warnings,_that.message,_that.resumedFrom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Job extends Job {
  const _Job({required this.id, @JobStateConverter() required this.state, required this.command, this.actionName, final  Map<String, dynamic> actionParams = const <String, dynamic>{}, final  Map<String, dynamic> environments = const <String, dynamic>{}, this.createdBy, this.artifactKey, this.promoted = false, this.announce = false, required this.createdAt, this.startedAt, this.finishedAt, this.exitCode, this.lastLine, this.lastSeq = 0, @JsonKey(readValue: _readDiscordChannelId) this.discordChannelId, @JsonKey(readValue: _readDiscordMessageId) this.discordMessageId, this.logUrl, final  List<String> warnings = const <String>[], this.message, this.resumedFrom}): _actionParams = actionParams,_environments = environments,_warnings = warnings,super._();
  factory _Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

@override final  String id;
@override@JobStateConverter() final  JobState state;
@override final  String command;
/// Null for a handful of legacy/cron records with no recorded action —
/// see docs/rest-api.md. Every job created through an Action always has
/// one; this only stays nullable for those historical outliers.
@override final  String? actionName;
 final  Map<String, dynamic> _actionParams;
@override@JsonKey() Map<String, dynamic> get actionParams {
  if (_actionParams is EqualUnmodifiableMapView) return _actionParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_actionParams);
}

 final  Map<String, dynamic> _environments;
@override@JsonKey() Map<String, dynamic> get environments {
  if (_environments is EqualUnmodifiableMapView) return _environments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_environments);
}

@override final  String? createdBy;
@override final  int? artifactKey;
@override@JsonKey() final  bool promoted;
@override@JsonKey() final  bool announce;
@override final  DateTime createdAt;
@override final  DateTime? startedAt;
@override final  DateTime? finishedAt;
@override final  int? exitCode;
@override final  String? lastLine;
@override@JsonKey() final  int lastSeq;
@override@JsonKey(readValue: _readDiscordChannelId) final  String? discordChannelId;
@override@JsonKey(readValue: _readDiscordMessageId) final  String? discordMessageId;
@override final  String? logUrl;
 final  List<String> _warnings;
@override@JsonKey() List<String> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}

/// Only populated on `/cancel` responses — the confirmation text.
@override final  String? message;
/// Id of the job this one replaced after a server restart re-invoked its
/// recorded action — see docs/rest-api.md "Restart mid-build". Null for
/// every job created the normal way.
@override final  String? resumedFrom;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.command, command) || other.command == command)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&const DeepCollectionEquality().equals(other._actionParams, _actionParams)&&const DeepCollectionEquality().equals(other._environments, _environments)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.artifactKey, artifactKey) || other.artifactKey == artifactKey)&&(identical(other.promoted, promoted) || other.promoted == promoted)&&(identical(other.announce, announce) || other.announce == announce)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.lastLine, lastLine) || other.lastLine == lastLine)&&(identical(other.lastSeq, lastSeq) || other.lastSeq == lastSeq)&&(identical(other.discordChannelId, discordChannelId) || other.discordChannelId == discordChannelId)&&(identical(other.discordMessageId, discordMessageId) || other.discordMessageId == discordMessageId)&&(identical(other.logUrl, logUrl) || other.logUrl == logUrl)&&const DeepCollectionEquality().equals(other._warnings, _warnings)&&(identical(other.message, message) || other.message == message)&&(identical(other.resumedFrom, resumedFrom) || other.resumedFrom == resumedFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,state,command,actionName,const DeepCollectionEquality().hash(_actionParams),const DeepCollectionEquality().hash(_environments),createdBy,artifactKey,promoted,announce,createdAt,startedAt,finishedAt,exitCode,lastLine,lastSeq,discordChannelId,discordMessageId,logUrl,const DeepCollectionEquality().hash(_warnings),message,resumedFrom]);

@override
String toString() {
  return 'Job(id: $id, state: $state, command: $command, actionName: $actionName, actionParams: $actionParams, environments: $environments, createdBy: $createdBy, artifactKey: $artifactKey, promoted: $promoted, announce: $announce, createdAt: $createdAt, startedAt: $startedAt, finishedAt: $finishedAt, exitCode: $exitCode, lastLine: $lastLine, lastSeq: $lastSeq, discordChannelId: $discordChannelId, discordMessageId: $discordMessageId, logUrl: $logUrl, warnings: $warnings, message: $message, resumedFrom: $resumedFrom)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
 String id,@JobStateConverter() JobState state, String command, String? actionName, Map<String, dynamic> actionParams, Map<String, dynamic> environments, String? createdBy, int? artifactKey, bool promoted, bool announce, DateTime createdAt, DateTime? startedAt, DateTime? finishedAt, int? exitCode, String? lastLine, int lastSeq,@JsonKey(readValue: _readDiscordChannelId) String? discordChannelId,@JsonKey(readValue: _readDiscordMessageId) String? discordMessageId, String? logUrl, List<String> warnings, String? message, String? resumedFrom
});




}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? state = null,Object? command = null,Object? actionName = freezed,Object? actionParams = null,Object? environments = null,Object? createdBy = freezed,Object? artifactKey = freezed,Object? promoted = null,Object? announce = null,Object? createdAt = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? exitCode = freezed,Object? lastLine = freezed,Object? lastSeq = null,Object? discordChannelId = freezed,Object? discordMessageId = freezed,Object? logUrl = freezed,Object? warnings = null,Object? message = freezed,Object? resumedFrom = freezed,}) {
  return _then(_Job(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as JobState,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,actionName: freezed == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String?,actionParams: null == actionParams ? _self._actionParams : actionParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,environments: null == environments ? _self._environments : environments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,artifactKey: freezed == artifactKey ? _self.artifactKey : artifactKey // ignore: cast_nullable_to_non_nullable
as int?,promoted: null == promoted ? _self.promoted : promoted // ignore: cast_nullable_to_non_nullable
as bool,announce: null == announce ? _self.announce : announce // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,lastLine: freezed == lastLine ? _self.lastLine : lastLine // ignore: cast_nullable_to_non_nullable
as String?,lastSeq: null == lastSeq ? _self.lastSeq : lastSeq // ignore: cast_nullable_to_non_nullable
as int,discordChannelId: freezed == discordChannelId ? _self.discordChannelId : discordChannelId // ignore: cast_nullable_to_non_nullable
as String?,discordMessageId: freezed == discordMessageId ? _self.discordMessageId : discordMessageId // ignore: cast_nullable_to_non_nullable
as String?,logUrl: freezed == logUrl ? _self.logUrl : logUrl // ignore: cast_nullable_to_non_nullable
as String?,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,resumedFrom: freezed == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
