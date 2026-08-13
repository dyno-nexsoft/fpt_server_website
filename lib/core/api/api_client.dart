import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'api_exception.dart';

/// Thin wrapper over `package:chopper` for the `/api/v1` REST surface.
///
/// Chopper here is used for its request/response pipeline (interceptors,
/// converters, typed `Response`) rather than its `@ChopperApi` code
/// generation — the paths this client calls are built from a runtime path
/// string (`/jobs/$id/cancel`, `/actions/${action.name}`), which an
/// annotation-based generated service has no natural way to express short of
/// one hand-written method per endpoint. [Response] bodies are always
/// requested as `String` and JSON-decoded here, exactly like the
/// `package:http`-based version this replaced — that keeps error handling
/// (a non-2xx response, a malformed body) in one place instead of split
/// between this class and a generated service.
///
/// [baseUrl] has no trailing slash and already includes `/api/v1`.
/// [apiKey] is sent as `X-API-Key`; `null` means unauthenticated (only
/// `/health` accepts that).
class ApiClient {
  ApiClient({required this.baseUrl, required this.apiKey})
    : _chopper = ChopperClient(
        baseUrl: Uri.parse(baseUrl),
        converter: const JsonConverter(),
        interceptors: [
          if (apiKey != null && apiKey.isNotEmpty)
            HeadersInterceptor({'X-API-Key': apiKey}),
        ],
      );

  final String baseUrl;
  final String? apiKey;
  final ChopperClient _chopper;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final full = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return full;
    return full.replace(
      queryParameters: {
        ...full.queryParameters,
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      },
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(
      Request('GET', _uri(path, query), Uri.parse(baseUrl)),
    );
    return _decodeObject(response.body);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? query,
    required String listKey,
  }) async {
    final body = await getJson(path, query: query);
    return body[listKey] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> postJson(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _send(
      Request(
        'POST',
        _uri(path),
        Uri.parse(baseUrl),
        body: jsonEncode(body ?? {}),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    return _decodeObject(response.body);
  }

  /// Raw text fetch for the `/jobs/{id}/log?offset=` polling fallback —
  /// callers need the `X-Log-Next-Offset` response header, not just JSON.
  Future<Response<String>> getRaw(String path, {Map<String, dynamic>? query}) =>
      _send(Request('GET', _uri(path, query), Uri.parse(baseUrl)));

  Future<Response<String>> _send(Request request) async {
    late Response<String> response;
    try {
      response = await _chopper.send<String, String>(request);
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

  Map<String, dynamic> _decodeObject(String? body) {
    if (body == null || body.isEmpty) return const {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void close() => _chopper.dispose();
}
