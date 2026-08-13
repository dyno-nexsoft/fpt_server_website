// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemStatus {

 String get dartVersion; String get hostname; int get uptimeSeconds; String get uptime; String get workingDirectory; List<Job> get running; List<Job> get queued;
/// Create a copy of SystemStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemStatusCopyWith<SystemStatus> get copyWith => _$SystemStatusCopyWithImpl<SystemStatus>(this as SystemStatus, _$identity);

  /// Serializes this SystemStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemStatus&&(identical(other.dartVersion, dartVersion) || other.dartVersion == dartVersion)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.uptimeSeconds, uptimeSeconds) || other.uptimeSeconds == uptimeSeconds)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.workingDirectory, workingDirectory) || other.workingDirectory == workingDirectory)&&const DeepCollectionEquality().equals(other.running, running)&&const DeepCollectionEquality().equals(other.queued, queued));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dartVersion,hostname,uptimeSeconds,uptime,workingDirectory,const DeepCollectionEquality().hash(running),const DeepCollectionEquality().hash(queued));

@override
String toString() {
  return 'SystemStatus(dartVersion: $dartVersion, hostname: $hostname, uptimeSeconds: $uptimeSeconds, uptime: $uptime, workingDirectory: $workingDirectory, running: $running, queued: $queued)';
}


}

/// @nodoc
abstract mixin class $SystemStatusCopyWith<$Res>  {
  factory $SystemStatusCopyWith(SystemStatus value, $Res Function(SystemStatus) _then) = _$SystemStatusCopyWithImpl;
@useResult
$Res call({
 String dartVersion, String hostname, int uptimeSeconds, String uptime, String workingDirectory, List<Job> running, List<Job> queued
});




}
/// @nodoc
class _$SystemStatusCopyWithImpl<$Res>
    implements $SystemStatusCopyWith<$Res> {
  _$SystemStatusCopyWithImpl(this._self, this._then);

  final SystemStatus _self;
  final $Res Function(SystemStatus) _then;

/// Create a copy of SystemStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dartVersion = null,Object? hostname = null,Object? uptimeSeconds = null,Object? uptime = null,Object? workingDirectory = null,Object? running = null,Object? queued = null,}) {
  return _then(_self.copyWith(
dartVersion: null == dartVersion ? _self.dartVersion : dartVersion // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,uptimeSeconds: null == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as int,uptime: null == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as String,workingDirectory: null == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as List<Job>,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as List<Job>,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemStatus].
extension SystemStatusPatterns on SystemStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemStatus value)  $default,){
final _that = this;
switch (_that) {
case _SystemStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemStatus value)?  $default,){
final _that = this;
switch (_that) {
case _SystemStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dartVersion,  String hostname,  int uptimeSeconds,  String uptime,  String workingDirectory,  List<Job> running,  List<Job> queued)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemStatus() when $default != null:
return $default(_that.dartVersion,_that.hostname,_that.uptimeSeconds,_that.uptime,_that.workingDirectory,_that.running,_that.queued);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dartVersion,  String hostname,  int uptimeSeconds,  String uptime,  String workingDirectory,  List<Job> running,  List<Job> queued)  $default,) {final _that = this;
switch (_that) {
case _SystemStatus():
return $default(_that.dartVersion,_that.hostname,_that.uptimeSeconds,_that.uptime,_that.workingDirectory,_that.running,_that.queued);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dartVersion,  String hostname,  int uptimeSeconds,  String uptime,  String workingDirectory,  List<Job> running,  List<Job> queued)?  $default,) {final _that = this;
switch (_that) {
case _SystemStatus() when $default != null:
return $default(_that.dartVersion,_that.hostname,_that.uptimeSeconds,_that.uptime,_that.workingDirectory,_that.running,_that.queued);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SystemStatus extends SystemStatus {
  const _SystemStatus({required this.dartVersion, required this.hostname, required this.uptimeSeconds, required this.uptime, required this.workingDirectory, final  List<Job> running = const <Job>[], final  List<Job> queued = const <Job>[]}): _running = running,_queued = queued,super._();
  factory _SystemStatus.fromJson(Map<String, dynamic> json) => _$SystemStatusFromJson(json);

@override final  String dartVersion;
@override final  String hostname;
@override final  int uptimeSeconds;
@override final  String uptime;
@override final  String workingDirectory;
 final  List<Job> _running;
@override@JsonKey() List<Job> get running {
  if (_running is EqualUnmodifiableListView) return _running;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_running);
}

 final  List<Job> _queued;
@override@JsonKey() List<Job> get queued {
  if (_queued is EqualUnmodifiableListView) return _queued;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queued);
}


/// Create a copy of SystemStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemStatusCopyWith<_SystemStatus> get copyWith => __$SystemStatusCopyWithImpl<_SystemStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemStatus&&(identical(other.dartVersion, dartVersion) || other.dartVersion == dartVersion)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.uptimeSeconds, uptimeSeconds) || other.uptimeSeconds == uptimeSeconds)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.workingDirectory, workingDirectory) || other.workingDirectory == workingDirectory)&&const DeepCollectionEquality().equals(other._running, _running)&&const DeepCollectionEquality().equals(other._queued, _queued));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dartVersion,hostname,uptimeSeconds,uptime,workingDirectory,const DeepCollectionEquality().hash(_running),const DeepCollectionEquality().hash(_queued));

@override
String toString() {
  return 'SystemStatus(dartVersion: $dartVersion, hostname: $hostname, uptimeSeconds: $uptimeSeconds, uptime: $uptime, workingDirectory: $workingDirectory, running: $running, queued: $queued)';
}


}

/// @nodoc
abstract mixin class _$SystemStatusCopyWith<$Res> implements $SystemStatusCopyWith<$Res> {
  factory _$SystemStatusCopyWith(_SystemStatus value, $Res Function(_SystemStatus) _then) = __$SystemStatusCopyWithImpl;
@override @useResult
$Res call({
 String dartVersion, String hostname, int uptimeSeconds, String uptime, String workingDirectory, List<Job> running, List<Job> queued
});




}
/// @nodoc
class __$SystemStatusCopyWithImpl<$Res>
    implements _$SystemStatusCopyWith<$Res> {
  __$SystemStatusCopyWithImpl(this._self, this._then);

  final _SystemStatus _self;
  final $Res Function(_SystemStatus) _then;

/// Create a copy of SystemStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dartVersion = null,Object? hostname = null,Object? uptimeSeconds = null,Object? uptime = null,Object? workingDirectory = null,Object? running = null,Object? queued = null,}) {
  return _then(_SystemStatus(
dartVersion: null == dartVersion ? _self.dartVersion : dartVersion // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,uptimeSeconds: null == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as int,uptime: null == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as String,workingDirectory: null == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String,running: null == running ? _self._running : running // ignore: cast_nullable_to_non_nullable
as List<Job>,queued: null == queued ? _self._queued : queued // ignore: cast_nullable_to_non_nullable
as List<Job>,
  ));
}


}

// dart format on
