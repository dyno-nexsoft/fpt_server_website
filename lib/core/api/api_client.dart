import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'api_exception.dart';
import 'fpt_api.dart';

/// Thin wrapper over the generated [FptApi] chopper service.
///
/// [FptApi] defines the endpoints (paths, methods, params) as typed,
/// compile-checked methods — see its doc comment. This class adds the one
/// thing that's the same for every endpoint: validating the response and
/// decoding its body, so that logic lives in one place instead of being
/// repeated (or drifting) across callers.
///
/// Deliberately no `converter:` on [ChopperClient] — see [FptApi]'s doc
/// comment for why a `JsonConverter` is actively wrong here.
///
/// [baseUrl] has no trailing slash and already includes `/api/v1`.
/// [apiKey] is sent as `X-API-Key`; `null` means unauthenticated (only
/// `/health` accepts that).
class ApiClient {
  ApiClient({required this.baseUrl, required this.apiKey})
    : _chopper = ChopperClient(
        baseUrl: Uri.parse(baseUrl),
        services: [FptApi.create()],
        interceptors: [
          if (apiKey != null && apiKey.isNotEmpty)
            HeadersInterceptor({'X-API-Key': apiKey}),
        ],
      );

  final String baseUrl;
  final String? apiKey;
  final ChopperClient _chopper;

  /// The typed REST methods. Prefer this over adding more decode helpers
  /// below for a new endpoint — decoding its result is the caller's job.
  late final FptApi endpoints = _chopper.getService<FptApi>();

  Future<Response<String>> _send(Future<Response<String>> request) async {
    late Response<String> response;
    try {
      response = await request;
    } catch (e) {
      throw ApiException.network(e.toString());
    }
    if (response.isSuccessful) return response;

    // `.body` is always null on a non-2xx response — chopper routes the raw
    // text through `.error` instead (no `errorConverter` is configured, so
    // it stays as the untouched response string here, same as `.body` would
    // hold on success).
    Map<String, dynamic> body;
    try {
      body =
          jsonDecode(response.error as String? ?? '') as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }
    throw ApiException.fromResponseBody(response.statusCode, body);
  }

  /// Runs [request], then decodes its body as a JSON object.
  Future<Map<String, dynamic>> decodeMap(
    Future<Response<String>> request,
  ) async {
    final response = await _send(request);
    return _decodeObject(response.body);
  }

  /// Runs [request], then decodes its body and pulls out the array at
  /// [listKey] — the shape every list endpoint here uses (`{jobs: [...]}`,
  /// `{actions: [...]}`, `{branches: [...]}`).
  Future<List<dynamic>> decodeList(
    Future<Response<String>> request, {
    required String listKey,
  }) async {
    final body = await decodeMap(request);
    return body[listKey] as List<dynamic>? ?? [];
  }

  /// Runs [request] and validates the response, without decoding — for the
  /// `/jobs/{id}/log` poll, which needs the raw text plus a response header.
  Future<Response<String>> rawText(Future<Response<String>> request) =>
      _send(request);

  /// [FptApi.invokeAction] takes an already-encoded JSON string, not a
  /// `Map` — see its doc comment for why nothing auto-encodes it.
  String encodeBody(Map<String, dynamic> body) => jsonEncode(body);

  Map<String, dynamic> _decodeObject(String? body) {
    if (body == null || body.isEmpty) return const {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void close() => _chopper.dispose();
}
