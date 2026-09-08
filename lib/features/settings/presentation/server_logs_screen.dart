import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/log_viewer.dart';
import '../application/settings_providers.dart';

/// `admin.logs.tail` — a full-page log viewer, styled like the build job
/// log pane, instead of a small scrollable box buried in Settings.
///
/// [source] is passed straight through to the action: `server` for the bot's
/// own `server.log`, `novnc` for the remote-desktop service. One screen for
/// both, because the only difference is which file the server opens.
class ServerLogsScreen extends ConsumerWidget {
  const ServerLogsScreen({required this.source, super.key});

  final String source;

  static const _titles = {
    'server': 'Server Logs',
    'novnc': 'Remote Desktop Logs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsTailProvider(source));
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
              Text(_titles[source] ?? 'Logs', style: textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(logsTailProvider(source)),
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
              return LogViewer(lines: lines, startAtBottom: true);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(error: error),
          ),
        ),
      ],
    );
  }
}
