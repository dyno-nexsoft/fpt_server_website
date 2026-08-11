/// `GET /health` — the only unauthenticated endpoint. Discovers the current
/// tunnel base URL, which changes on every server restart.
class Health {
  const Health({
    required this.ok,
    required this.version,
    required this.uptimeSeconds,
    required this.hostname,
    required this.publicUrl,
  });

  factory Health.fromJson(Map<String, dynamic> json) => Health(
    ok: json['ok'] as bool,
    version: json['version'] as String,
    uptimeSeconds: json['uptimeSeconds'] as int,
    hostname: json['hostname'] as String,
    publicUrl: json['publicUrl'] as String?,
  );

  final bool ok;
  final String version;
  final int uptimeSeconds;
  final String hostname;
  final String? publicUrl;
}
