import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../application/jobs_providers.dart';
import 'builds_list_mobile.dart';
import 'builds_table_desktop.dart';

const _filters = <(String label, String? value, IconData icon)>[
  ('All', null, Icons.apps),
  ('Running', 'running', Icons.autorenew),
  ('Queued', 'queued', Icons.schedule),
  ('Succeeded', 'succeeded', Icons.check_circle_outline),
  ('Failed', 'failed', Icons.error_outline),
  ('Cancelled', 'cancelled', Icons.block),
];

/// `GET /jobs?state=&limit=` — a live wire-screen of what the API returns;
/// row actions are derived from each job's own field values so the button
/// availability never drifts from the server's own 409 rules.
class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

/// Distinguishes "no `?state=` seen yet" from "saw `?state=` and it was
/// absent" — both are represented by `null` otherwise, which would make the
/// very first build indistinguishable from a later navigation that
/// explicitly clears the filter.
const _unsetRouteState = Object();

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  String? _stateFilter;
  String _search = '';

  /// The last `?state=` value this screen synced [_stateFilter] from — not
  /// the same as [BuildsScreen]'s own widget/State lifetime, since go_router
  /// reuses this State across query-only navigations to the same `/builds`
  /// path. Comparing against the *previous* route value (rather than syncing
  /// on every build) is what lets a chip elsewhere re-filter this screen on
  /// a fresh navigation without also stomping a filter chip tapped locally,
  /// which changes `_stateFilter` without ever touching the URL.
  Object? _lastRouteState = _unsetRouteState;

  @override
  Widget build(BuildContext context) {
    final routeState = GoRouterState.of(context).uri.queryParameters['state'];
    if (routeState != _lastRouteState) {
      _lastRouteState = routeState;
      _stateFilter = _filters.any((f) => f.$2 == routeState)
          ? routeState
          : null;
    }
    final textTheme = Theme.of(context).textTheme;
    final jobs = ref.watch(
      jobsListProvider(JobsQuery(state: _stateFilter, limit: 100)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.list_alt_outlined),
              Text('Builds', style: textTheme.headlineSmall),
              const Spacer(),
              SearchAnchor(
                viewHintText: 'Search action or job id',
                // Keeps the table below filtering live as the reader types,
                // the same way the old inline field did — suggestions alone
                // would only help someone who wants to jump straight to one
                // match, not someone scanning a narrowed table.
                viewOnChanged: (value) => setState(() => _search = value),
                builder: (context, controller) => IconButton(
                  tooltip: 'Search action or job id',
                  icon: const Icon(Icons.search),
                  onPressed: controller.openView,
                ),
                suggestionsBuilder: (context, controller) {
                  if (controller.text.trim().isEmpty) return const [];
                  final matches = jobs.maybeWhen(
                    data: (list) => _filterJobs(list, controller.text),
                    orElse: () => const <Job>[],
                  );
                  return [
                    for (final job in matches.take(10))
                      ListTile(
                        leading: JobStateChip(state: job.state),
                        title: Text(job.actionName ?? job.command),
                        subtitle: Text(job.id),
                        onTap: () {
                          controller.closeView(job.actionName ?? job.id);
                          setState(() => _search = '');
                          JobDetailRoute(job.id).go(context);
                        },
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value, icon) in _filters)
                ChoiceChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  selected: _stateFilter == value,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _stateFilter = value),
                ),
            ],
          ),
        ),
        Expanded(
          child: jobs.when(
            data: (list) => isTabletWidth(context)
                ? BuildsListMobile(jobs: _applySearch(list))
                : BuildsTableDesktop(jobs: _applySearch(list)),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(error: error),
          ),
        ),
      ],
    );
  }

  List<Job> _applySearch(List<Job> jobs) => _filterJobs(jobs, _search);
}

/// Shared by the table's own live filter (driven by [_search], set from
/// `SearchAnchor.viewOnChanged`) and the search view's suggestions list
/// (driven directly off the view's own `SearchController.text`) — the
/// latter reads that controller straight rather than `_search` to avoid a
/// one-keystroke lag between the two callbacks firing in the same frame.
List<Job> _filterJobs(List<Job> jobs, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return jobs;
  return jobs
      .where(
        (job) =>
            (job.actionName ?? job.command).toLowerCase().contains(query) ||
            job.id.toLowerCase().contains(query),
      )
      .toList();
}
