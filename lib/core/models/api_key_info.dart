/// One row from `admin.apiKeys.list`. `keyHash` is always truncated to 8 hex
/// chars server-side — never the full hash, never the secret.
class ApiKeyInfo {
  const ApiKeyInfo({
    required this.id,
    required this.name,
    required this.keyHash,
    required this.scopes,
    this.discordUserId,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) => ApiKeyInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    keyHash: json['key_hash'] as String,
    scopes: (json['scopes'] as List<dynamic>).cast<String>(),
    discordUserId: json['discord_user_id']?.toString(),
  );

  final String id;
  final String name;
  final String keyHash;
  final List<String> scopes;
  final String? discordUserId;

  bool get isAdmin => scopes.contains('admin');
}
