import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/jobs_api.dart';
import '../../../core/browser/browser_utils.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/storage/action_template_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/widgets/name_template_dialog.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        // Stretch, not start — the buttons below (Open raw log / Artifacts /
        // Promote / Cancel / Retry) used to fill the panel's width as a
        // ListView's default block-layout side effect; an explicit
        // crossAxisAlignment on a Column doesn't do that unless asked.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('Build', style: Theme.of(context).textTheme.titleMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              for (final entry in job.actionParams.entries)
                if (entry.value != null)
                  _ParamRow(name: entry.key, value: '${entry.value}'),
              for (final warning in job.warnings)
                _ParamRow(
                  name: 'Warning',
                  value: warning,
                  icon: Icons.warning_amber,
                ),
            ],
          ),
          const Divider(),
          if (job.logUrl != null)
            OutlinedButton.icon(
              onPressed: () => openInNewTab('${job.logUrl!}?raw=1'),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open raw log'),
            ),
          OutlinedButton.icon(
            onPressed: () => context.go('/builds/artifacts/${job.artifactKey}'),
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Artifacts'),
          ),
          // `actionName` is null for a job predating action-tracking (or one
          // evicted from the registry) — there is no schema to key a
          // template by, so there's nothing to offer saving here.
          if (job.actionName != null)
            OutlinedButton.icon(
              onPressed: () => _saveAsTemplate(context, ref, job.actionName!),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save as template'),
            ),
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
              style: AppTheme.destructiveButtonStyle(
                Theme.of(context).colorScheme,
              ),
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
            const Text(
              'Connect with an API key to manage this build — run '
              '/admin api-key-add in Discord to get one.',
            ),
        ],
      ),
    );
  }

  Future<void> _saveAsTemplate(
    BuildContext context,
    WidgetRef ref,
    String actionName,
  ) async {
    final store = ref.read(actionTemplateStoreProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => NameTemplateDialog(
        existingNames: store.list(actionName).map((t) => t.name).toSet(),
      ),
    );
    if (name == null || name.isEmpty) return;
    await store.save(
      actionName,
      ActionTemplate(name: name, params: job.actionParams),
    );
    ref.read(appToastProvider.notifier).show('Saved as "$name"');
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
  const _ParamRow({required this.name, required this.value, this.icon});

  final String name;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // ListTile centers `leading` against the title+subtitle block on its
    // own — the previous hand-built Row (icon + a Column of two Text
    // widgets) always sat the icon a few pixels too high instead.
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon ?? Icons.circle_outlined),
      title: Text(name),
      subtitle: Text(value),
    );
  }
}
