// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'fpt_api.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$FptApi extends FptApi {
  _$FptApi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = FptApi;

  @override
  Future<Response<String>> health() {
    final Uri $url = Uri.parse('/health');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> status() {
    final Uri $url = Uri.parse('/status');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> listActions() {
    final Uri $url = Uri.parse('/actions');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> invokeAction(String name, String jsonBody) {
    final Uri $url = Uri.parse('/actions/${name}');
    final Map<String, String> $headers = {'Content-Type': 'application/json'};
    final $body = jsonBody;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> listJobs(Map<String, dynamic> query) {
    final Uri $url = Uri.parse('/jobs');
    final Map<String, dynamic> $params = query;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> getJob(String id) {
    final Uri $url = Uri.parse('/jobs/${id}');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> cancelJob(String id) {
    final Uri $url = Uri.parse('/jobs/${id}/cancel');
    final Request $request = Request('POST', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> promoteJob(String id) {
    final Uri $url = Uri.parse('/jobs/${id}/promote');
    final Request $request = Request('POST', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> retryJob(String id) {
    final Uri $url = Uri.parse('/jobs/${id}/retry');
    final Request $request = Request('POST', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> createStreamToken(String id) {
    final Uri $url = Uri.parse('/jobs/${id}/stream-token');
    final Request $request = Request('POST', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> getJobLog(String id, int offset) {
    final Uri $url = Uri.parse('/jobs/${id}/log');
    final Map<String, dynamic> $params = <String, dynamic>{'offset': offset};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> getArtifacts(String key) {
    final Uri $url = Uri.parse('/artifacts/${key}');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> autocompleteBranches(String repo, String query) {
    final Uri $url = Uri.parse('/autocomplete/branches');
    final Map<String, dynamic> $params = <String, dynamic>{
      'repo': repo,
      'query': query,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<String, String>($request);
  }
}
