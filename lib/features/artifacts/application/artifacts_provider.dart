import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/artifacts_api.dart';
import '../../../core/models/artifact_file.dart';
import '../../../core/providers/core_providers.dart';

final artifactListingProvider = FutureProvider.autoDispose
    .family<ArtifactListing, String>((ref, key) async {
      final api = ref.watch(apiClientProvider);
      return fetchArtifacts(api, key);
    });
