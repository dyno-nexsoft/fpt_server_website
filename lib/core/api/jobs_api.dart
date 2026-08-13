import '../models/job.dart';
import 'api_client.dart';

/// `POST /jobs/{id}/stream-token` response — short-lived, since
/// `EventSource` cannot send the `X-API-Key` header.
class StreamToken {
  const StreamToken({
    required this.token,
    required this.expiresInSeconds,
    required this.eventsUrl,
  });

  factory StreamToken.fromJson(Map<String, dynamic> json) => StreamToken(
    token: json['token'] as String,
    expiresInSeconds: json['expires_in_seconds'] as int,
    eventsUrl: json['events_url'] as String,
  );

  final String token;
  final int expiresInSeconds;
  final String eventsUrl;
}

Future<Job> fetchJob(ApiClient api, String id) async =>
    Job.fromJson(await api.decodeMap(api.endpoints.getJob(id)));

/// `fields=summary` drops `environments`/`discord`/`announce`/`last_seq`
/// server-side — none of which any list view here renders, but which can
/// dominate payload size across a hundred records (a full env var map,
/// repeated per job). [fetchJob] fetches one job in full instead.
Future<List<Job>> fetchJobs(
  ApiClient api, {
  String? state,
  String? resumedFrom,
  int limit = 20,
}) async {
  final list = await api.decodeList(
    api.endpoints.listJobs({
      'state': ?state,
      'resumed_from': ?resumedFrom,
      'limit': limit,
      'fields': 'summary',
    }),
    listKey: 'jobs',
  );
  return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
}

Future<Job> cancelJob(ApiClient api, String id) async =>
    Job.fromJson(await api.decodeMap(api.endpoints.cancelJob(id)));

Future<Job> promoteJob(ApiClient api, String id) async =>
    Job.fromJson(await api.decodeMap(api.endpoints.promoteJob(id)));

Future<Job> retryJob(ApiClient api, String id) async =>
    Job.fromJson(await api.decodeMap(api.endpoints.retryJob(id)));

Future<StreamToken> createStreamToken(ApiClient api, String id) async =>
    StreamToken.fromJson(
      await api.decodeMap(api.endpoints.createStreamToken(id)),
    );
