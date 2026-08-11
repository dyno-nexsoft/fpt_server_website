import '../models/artifact_file.dart';
import 'api_client.dart';

Future<ArtifactListing> fetchArtifacts(ApiClient api, String key) async =>
    ArtifactListing.fromJson(await api.getJson('/artifacts/$key'));
