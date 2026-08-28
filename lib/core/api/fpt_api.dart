import 'package:chopper/chopper.dart';

part 'fpt_api.chopper.dart';

/// One typed method per `/api/v1` endpoint — see `docs/rest-api.md`.
///
/// Every method returns the raw `Response<String>`; [ApiClient] decodes the
/// body and maps errors to [ApiException] in one place, since the response
/// shape differs per endpoint (a bare object, `{jobs: [...]}`, a raw log
/// slice with a custom header). `/actions/{name}` covers every action by
/// name (`admin.apiKeys.add`, `ci.build`, …) via [Path] rather than one
/// method per action — the action catalogue is fetched at runtime from
/// `GET /actions`, so the set of names isn't known at compile time.
///
/// [FptApi] has no [Converter] attached (see [ApiClient]) — a `JsonConverter`
/// unconditionally `json.decode()`s a JSON response body regardless of the
/// declared `BodyType`, which silently produces a `Map` where every method
/// here expects `String`, breaking only once a response actually succeeds
/// with real JSON. [invokeAction]'s body is JSON-encoded by its caller for
/// the same reason — nothing here auto-encodes it either.
@ChopperApi()
abstract class FptApi extends ChopperService {
  static FptApi create([ChopperClient? client]) => _$FptApi(client);

  @GET(path: '/health')
  Future<Response<String>> health();

  @GET(path: '/status')
  Future<Response<String>> status();

  @GET(path: '/actions')
  Future<Response<String>> listActions();

  /// [invocationId] names a progress feed the caller already opened with
  /// `GET /invocations/{id}/events`, so a long-running `mutation` can report
  /// real steps while this request is still in flight. A header rather than a
  /// body field on purpose — the server persists request params verbatim for
  /// its Retry button, and a one-shot stream id must not be replayed later.
  @POST(path: '/actions/{name}', headers: {'Content-Type': 'application/json'})
  Future<Response<String>> invokeAction(
    @Path('name') String name,
    @Body() String jsonBody, {
    @Header('X-Invocation-Id') String? invocationId,
  });

  @GET(path: '/jobs')
  Future<Response<String>> listJobs(@QueryMap() Map<String, dynamic> query);

  @GET(path: '/jobs/{id}')
  Future<Response<String>> getJob(@Path('id') String id);

  @POST(path: '/jobs/{id}/cancel')
  Future<Response<String>> cancelJob(@Path('id') String id);

  @POST(path: '/jobs/{id}/promote')
  Future<Response<String>> promoteJob(@Path('id') String id);

  @POST(path: '/jobs/{id}/retry')
  Future<Response<String>> retryJob(@Path('id') String id);

  @DELETE(path: '/jobs/{id}')
  Future<Response<String>> deleteJob(@Path('id') String id);

  @POST(path: '/jobs/{id}/stream-token')
  Future<Response<String>> createStreamToken(@Path('id') String id);

  /// Raw text, not JSON — see [ApiClient.rawText]'s callers.
  @GET(path: '/jobs/{id}/log')
  Future<Response<String>> getJobLog(
    @Path('id') String id,
    @Query('offset') int offset,
  );

  @GET(path: '/artifacts/{key}')
  Future<Response<String>> getArtifacts(@Path('key') String key);

  @GET(path: '/autocomplete/branches')
  Future<Response<String>> autocompleteBranches(
    @Query('repo') String repo,
    @Query('query') String query,
  );
}
