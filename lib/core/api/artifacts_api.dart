import 'package:fpt_server_shared/fpt_server_shared.dart';
import 'api_client.dart';

Future<ArtifactListing> fetchArtifacts(ApiClient api, String key) async =>
    ArtifactListing.fromJson(
      await api.decodeMap(api.endpoints.getArtifacts(key)),
    );
