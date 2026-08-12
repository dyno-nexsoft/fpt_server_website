import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/log_viewer.dart';
import '../application/settings_providers.dart';

/// `admin.logs.tail` — a full-page log viewer, styled like the build job
/// log pane, instead of a small scrollable box buried in Settings.
class ServerLogsScreen extends ConsumerWidget {
  const ServerLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsTailProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.article_outlined),
              Text('Server Logs', style: textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(logsTailProvider),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: logs.when(
            data: (lines) {
              if (lines == null) {
                return const Center(
                  child: Text('Connect with an admin key to view server logs.'),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: LogViewer(text: lines.join('\n'), reverse: true),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(error: error),
          ),
        ),
      ],
    );
  }
}
