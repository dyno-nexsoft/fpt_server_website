import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

/// `discord_channel_id`/`discord_message_id` arrive nested under a
/// `discord` object on the wire rather than flat — read straight out of it
/// via these rather than a custom `fromJson` body (see [Job.fromJson]'s doc
/// comment for why that alternative doesn't work with freezed).
Object? _readDiscordChannelId(Map json, String key) =>
    (json['discord'] as Map<String, dynamic>?)?['channel_id'];

Object? _readDiscordMessageId(Map json, String key) =>
    (json['discord'] as Map<String, dynamic>?)?['message_id'];

/// A build/job as returned by every `kind: job` action, `GET /jobs`, and
/// `GET /jobs/{id}`. Wire format is snake_case; this is the camelCase model.
@freezed
abstract class Job with _$Job {
  const Job._();

  const factory Job({
    required String id,
    @JobStateConverter() required JobState state,
    required String command,

    /// Null for a handful of legacy/cron records with no recorded action —
    /// see docs/rest-api.md. Every job created through an Action always has
    /// one; this only stays nullable for those historical outliers.
    String? actionName,
    @Default(<String, dynamic>{}) Map<String, dynamic> actionParams,
    @Default(<String, dynamic>{}) Map<String, dynamic> environments,
    String? createdBy,
    int? artifactKey,
    @Default(false) bool promoted,
    @Default(false) bool announce,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? exitCode,
    String? lastLine,
    @Default(0) int lastSeq,
    @JsonKey(readValue: _readDiscordChannelId) String? discordChannelId,
    @JsonKey(readValue: _readDiscordMessageId) String? discordMessageId,
    String? logUrl,
    @Default(<String>[]) List<String> warnings,

    /// Only populated on `/cancel` responses — the confirmation text.
    String? message,

    /// Id of the job this one replaced after a server restart re-invoked its
    /// recorded action — see docs/rest-api.md "Restart mid-build". Null for
    /// every job created the normal way.
    String? resumedFrom,
  }) = _Job;

  // Freezed only recognises this exact one-line delegating form as "this
  // class wants JSON codegen" and hands off to json_serializable for it —
  // a custom body here (even one that just preprocesses `json` first) makes
  // freezed skip generating `_$JobFromJson`/`toJson` for this class
  // entirely, silently, with no error. The `discord`-nesting workaround
  // that used to live here moved to `readValue` callbacks on the two fields
  // instead, which json_serializable supports declaratively.
  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  bool get isTerminal => state.isTerminal;

  Duration? get runningDuration {
    final start = startedAt;
    if (start == null) return null;
    return (finishedAt ?? DateTime.now()).difference(start);
  }
}

enum JobState {
  queued,
  running,
  succeeded,
  failed,
  cancelled,
  interrupted,
  unknown;

  static JobState fromWire(String wire) => switch (wire) {
    'queued' => JobState.queued,
    'running' => JobState.running,
    'succeeded' => JobState.succeeded,
    'failed' => JobState.failed,
    'cancelled' => JobState.cancelled,
    'interrupted' => JobState.interrupted,
    _ => JobState.unknown,
  };

  bool get isTerminal => switch (this) {
    JobState.succeeded ||
    JobState.failed ||
    JobState.cancelled ||
    JobState.interrupted => true,
    _ => false,
  };
}

/// Routes through [JobState.fromWire] instead of json_serializable's
/// `unknownEnumValue`, so an unrecognised wire string keeps falling back to
/// [JobState.unknown] exactly the way the hand-written decoder always did.
class JobStateConverter implements JsonConverter<JobState, String> {
  const JobStateConverter();

  @override
  JobState fromJson(String json) => JobState.fromWire(json);

  @override
  String toJson(JobState object) => object.name;
}
