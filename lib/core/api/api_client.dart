import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin wrapper over `package:http` for the `/api/v1` REST surface.
///
/// [baseUrl] has no trailing slash and already includes `/api/v1`.
/// [apiKey] is sent as `X-API-Key`; `null` means unauthenticated (only
/// `/health` accepts that).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? apiKey;
  final http.Client _http;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (apiKey != null && apiKey!.isNotEmpty) 'X-API-Key': apiKey!,
  };

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
      () => _http.get(_uri(path, query), headers: _headers),
    );
    return _decodeObject(response);
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
      () => _http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      ),
    );
    return _decodeObject(response);
  }

  /// Raw text fetch for the `/jobs/{id}/log?offset=` polling fallback —
  /// callers need the `X-Log-Next-Offset` response header, not just JSON.
  Future<http.Response> getRaw(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    late http.Response response;
    try {
      response = await request();
    } catch (e) {
      throw ApiException.network(e.toString());
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }
    throw ApiException.fromResponseBody(response.statusCode, body);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void close() => _http.close();
}
