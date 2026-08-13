import '../models/artifact_file.dart';
import 'api_client.dart';

Future<ArtifactListing> fetchArtifacts(ApiClient api, String key) async =>
    ArtifactListing.fromJson(
      await api.decodeMap(api.endpoints.getArtifacts(key)),
    );
