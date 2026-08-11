/// `GET /health` — the only unauthenticated endpoint.
class Health {
  const Health({
    required this.ok,
    required this.version,
    required this.uptimeSeconds,
    required this.hostname,
  });

  factory Health.fromJson(Map<String, dynamic> json) => Health(
    ok: json['ok'] as bool,
    version: json['version'] as String,
    uptimeSeconds: json['uptimeSeconds'] as int,
    hostname: json['hostname'] as String,
  );

  final bool ok;
  final String version;
  final int uptimeSeconds;
  final String hostname;
}
