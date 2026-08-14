import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/artifacts_api.dart';
import '../../../core/api/jobs_api.dart';
import '../../../core/models/artifact_file.dart';
import '../../../core/providers/core_providers.dart';

/// Keyed by job id, not artifactKey: the URL is job-scoped
/// (`/builds/:id/artifacts`), so this resolves the job first to find which
/// `build/<artifactKey>/` directory it actually points at. The resolved job
/// is then attached to the listing directly, rather than trusting whichever
/// job `GET /artifacts/{key}` itself would have picked for a shared
/// artifactKey (several retries of the same command all produce the same
/// key) — the one in the URL is the one the caller actually asked to see.
final artifactListingProvider = FutureProvider.autoDispose
    .family<ArtifactListing, String>((ref, jobId) async {
      final api = ref.watch(apiClientProvider);
      final job = await fetchJob(api, jobId);
      final listing = await fetchArtifacts(api, job.artifactKey.toString());
      return listing.copyWith(job: job);
    });
