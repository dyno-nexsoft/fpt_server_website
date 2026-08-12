import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';

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

/// `GET /jobs?limit=20` for the dashboard's "Recent builds" list.
final recentJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return fetchJobs(api, limit: 5);
});

/// `GET /jobs?state=&limit=` backing the filterable Builds list.
final jobsListProvider = FutureProvider.autoDispose
    .family<List<Job>, JobsQuery>((ref, query) async {
      final api = ref.watch(apiClientProvider);
      return fetchJobs(api, state: query.state, limit: query.limit);
    });
