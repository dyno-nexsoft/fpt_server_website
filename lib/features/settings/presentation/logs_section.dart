import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../application/settings_providers.dart';

/// `admin.logs.tail` — read-only, admin-only debugging view of `server.log`.
class LogsSection extends ConsumerWidget {
  const LogsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsTailProvider);
    return logs.when(
      data: (lines) {
        if (lines == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  children: [
                    Text(
                      'Logs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(logsTailProvider),
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectableText(
                      lines.join('\n'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.merge(AppTheme.monospaceTextStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
    );
  }
}
