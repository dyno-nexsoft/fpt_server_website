/// A `{ "error": { "code", "message", "details" } }` response, or a
/// synthesized `network` code when the request never reached the server.
///
/// `message` is Vietnamese (mirrors what a Discord user sees) — UI must
/// branch on [code], never on [message] text.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.problems,
  });

  factory ApiException.network(String detail) =>
      ApiException(code: 'network', message: detail);

  factory ApiException.fromResponseBody(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    final error = body['error'] as Map<String, dynamic>?;
    final details = error?['details'] as Map<String, dynamic>?;
    final problems = (details?['problems'] as List<dynamic>?)?.cast<String>();
    return ApiException(
      code: (error?['code'] as String?) ?? 'unknown',
      message: (error?['message'] as String?) ?? 'Unknown error',
      statusCode: statusCode,
      problems: problems,
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final List<String>? problems;

  bool get isNetworkError => code == 'network';
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isServerNotConfigured => statusCode == 503;
  bool get isValidation => statusCode == 400;

  @override
  String toString() => 'ApiException($code, $message)';
}
