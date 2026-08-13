import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key_info.freezed.dart';
part 'api_key_info.g.dart';

/// The server sends this as a raw Discord snowflake (a number in practice,
/// but never guaranteed) — normalised to a string, the only type a JSON id
/// should ever surface as here. A field-level converter rather than a
/// custom `fromJson` body: freezed only recognises the plain one-line
/// `=> _$ApiKeyInfoFromJson(json)` form as "generate JSON code for this
/// class" and silently skips it for anything else (see `Job.fromJson`'s doc
/// comment in job.dart for the same pitfall).
String? _discordUserIdFromJson(Object? value) => value?.toString();

/// One row from `admin.apiKeys.list`. `keyHash` is always truncated to 8 hex
/// chars server-side — never the full hash, never the secret.
@freezed
abstract class ApiKeyInfo with _$ApiKeyInfo {
  const ApiKeyInfo._();

  const factory ApiKeyInfo({
    required String id,
    required String name,
    required String keyHash,
    required List<String> scopes,
    @JsonKey(fromJson: _discordUserIdFromJson) String? discordUserId,
  }) = _ApiKeyInfo;

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyInfoFromJson(json);

  bool get isAdmin => scopes.contains('admin');

  /// Mirrors the server's `Principal.can` — `admin` implies every other
  /// permission, otherwise the key needs [permission] in its scopes exactly.
  /// Scopes do not stack hierarchically: an `invoke`-only key cannot call an
  /// `invokeDangerous` action even though the names suggest an ordering.
  bool can(String permission) => isAdmin || scopes.contains(permission);
}
