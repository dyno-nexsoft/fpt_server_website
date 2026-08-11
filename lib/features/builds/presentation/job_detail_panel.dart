import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/jobs_api.dart';
import '../../../core/browser/browser_utils.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/auth_guard.dart';

/// Right-hand sidebar of the job detail screen: params, artifact/log links,
/// and the Promote / Cancel / Retry controls.
class JobDetailPanel extends ConsumerWidget {
  const JobDetailPanel({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        job.state == JobState.queued || job.state == JobState.running;
    final canPromote = job.state == JobState.queued && !job.promoted;
    final canRetry = job.isTerminal;
    final hasKey = ref.watch(sessionProvider).hasKey;
    final showsAnyAction = canPromote || canCancel || canRetry;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Build', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in job.actionParams.entries)
          _ParamRow(name: entry.key, value: '${entry.value}'),
        if (job.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final warning in job.warnings)
            _ParamRow(name: '⚠', value: warning),
        ],
        const Divider(height: 32),
        if (job.logUrl != null)
          OutlinedButton.icon(
            onPressed: () => openInNewTab('${job.logUrl!}?raw=1'),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Open raw log'),
          ),
        OutlinedButton.icon(
          onPressed: () => context.go('/artifacts/${job.artifactKey}'),
          icon: const Icon(Icons.folder_outlined),
          label: const Text('Artifacts'),
        ),
        const SizedBox(height: 16),
        if (canPromote)
          FilledButton.tonalIcon(
            onPressed: () => _act(
              context,
              ref,
              'Promoted',
              () => promoteJob(ref.read(apiClientProvider), job.id),
            ),
            icon: const Icon(Icons.upgrade),
            label: const Text('Promote'),
          ),
        if (canCancel) ...[
          FilledButton.icon(
            onPressed: () => _act(
              context,
              ref,
              null,
              () => cancelJob(ref.read(apiClientProvider), job.id),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
          const Text('This deletes artifacts on the build server.'),
        ],
        if (canRetry)
          FilledButton.icon(
            onPressed: () => _act(
              context,
              ref,
              'Retried',
              () => retryJob(ref.read(apiClientProvider), job.id),
            ),
            icon: const Icon(Icons.replay),
            label: const Text('Retry'),
          ),
        if (showsAnyAction && !hasKey)
          const Text('Connect with an API key to manage this build.'),
      ],
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    String? fallbackMessage,
    Future<Job> Function() action,
  ) async {
    final result = await runAuthedJobAction(
      context,
      ref,
      fallbackMessage: fallbackMessage,
      action: action,
    );
    if (result != null) {
      ref.read(statusControllerProvider.notifier).refreshNow();
    }
  }
}

class _ParamRow extends StatelessWidget {
  const _ParamRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$name: $value'),
    );
  }
}
