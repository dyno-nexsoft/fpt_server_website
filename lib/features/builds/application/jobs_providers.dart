import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/jobs_api.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/status_provider.dart';

class JobsQuery {
  const JobsQuery({this.state, this.limit = 50});

  final String? state;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is JobsQuery && other.state == state && other.limit == limit;

  @override
  int get hashCode => Object.hash(state, limit);
}

/// `GET /jobs?limit=5` for the dashboard's "Recent builds" list.
///
/// Watches [statusControllerProvider] purely to re-run on every job-registry
/// change it pushes over `/status/events` — a build queued/started/finished
/// from Discord (or any other client) refetches this list too, not just the
/// sidebar counts.
final recentJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  ref.watch(statusControllerProvider);
  final api = ref.watch(apiClientProvider);
  return fetchJobs(api, limit: 5);
});

/// `GET /jobs?limit=100` — full job history for the dashboard charts.
///
/// Uses the same live-refetch pattern as [recentJobsProvider] so the charts
/// update automatically when a new build completes without a manual refresh.
final dashboardJobsProvider = FutureProvider.autoDispose<List<Job>>((
  ref,
) async {
  ref.watch(statusControllerProvider);
  final api = ref.watch(apiClientProvider);
  return fetchJobs(api, limit: 100);
});

/// `GET /jobs?state=&limit=` backing the filterable Builds list.
///
/// Same live-refetch-on-status-change rationale as [recentJobsProvider].
final jobsListProvider = FutureProvider.autoDispose
    .family<List<Job>, JobsQuery>((ref, query) async {
      ref.watch(statusControllerProvider);
      final api = ref.watch(apiClientProvider);
      return fetchJobs(api, state: query.state, limit: query.limit);
    });
