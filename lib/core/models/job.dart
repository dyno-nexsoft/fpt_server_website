/// A build/job as returned by every `kind: job` action, `GET /jobs`, and
/// `GET /jobs/{id}`. Wire format is snake_case; this is the camelCase model.
class Job {
  const Job({
    required this.id,
    required this.state,
    required this.command,
    required this.actionName,
    required this.actionParams,
    required this.environments,
    required this.createdBy,
    required this.artifactKey,
    required this.promoted,
    required this.announce,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.exitCode,
    this.lastLine,
    required this.lastSeq,
    this.discordChannelId,
    this.discordMessageId,
    this.logUrl,
    this.warnings = const [],
    this.message,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final discord = json['discord'] as Map<String, dynamic>?;
    return Job(
      id: json['id'] as String,
      state: JobState.fromWire(json['state'] as String),
      command: json['command'] as String,
      actionName: json['action_name'] as String,
      actionParams: (json['action_params'] as Map<String, dynamic>? ?? {}),
      environments: (json['environments'] as Map<String, dynamic>? ?? {}),
      createdBy: json['created_by'] as String?,
      artifactKey: json['artifact_key'] as int?,
      promoted: json['promoted'] as bool? ?? false,
      announce: json['announce'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: (json['started_at'] as String?) != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: (json['finished_at'] as String?) != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      exitCode: json['exit_code'] as int?,
      lastLine: json['last_line'] as String?,
      lastSeq: json['last_seq'] as int? ?? 0,
      discordChannelId: discord?['channel_id'] as String?,
      discordMessageId: discord?['message_id'] as String?,
      logUrl: json['log_url'] as String?,
      warnings:
          (json['warnings'] as List<dynamic>?)?.cast<String>() ?? const [],
      message: json['message'] as String?,
    );
  }

  final String id;
  final JobState state;
  final String command;
  final String actionName;
  final Map<String, dynamic> actionParams;
  final Map<String, dynamic> environments;
  final String? createdBy;
  final int? artifactKey;
  final bool promoted;
  final bool announce;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? exitCode;
  final String? lastLine;
  final int lastSeq;
  final String? discordChannelId;
  final String? discordMessageId;
  final String? logUrl;
  final List<String> warnings;

  /// Only populated on `/cancel` responses — the confirmation text.
  final String? message;

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
