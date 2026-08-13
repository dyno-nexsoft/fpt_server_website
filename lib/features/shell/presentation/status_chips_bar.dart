import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/status_provider.dart';
import 'app_bar_toggle_chip.dart';

/// Running/queued counts, inline in the app bar's title — a
/// [NavigationRail]/[NavigationBar] has no room for them, and a dedicated
/// strip under the bar just added height back after shrinking it elsewhere.
/// Each chip jumps to the Builds list pre-filtered to its own state — the
/// count is otherwise just a number with nowhere to go look at it closer.
class StatusChipsBar extends ConsumerWidget {
  const StatusChipsBar({super.key, required this.compact});

  /// See [AppBarToggleChip.compact].
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusControllerProvider);
    return status.maybeWhen(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: compact ? 0 : 12,
          children: [
            Badge.count(
              count: data.running.length,
              isLabelVisible: data.running.isNotEmpty,
              child: AppBarToggleChip(
                compact: compact,
                icon: Icons.autorenew,
                label: 'Running',
                onPressed: () => context.go('/builds?state=running'),
              ),
            ),
            Badge.count(
              count: data.queued.length,
              isLabelVisible: data.queued.isNotEmpty,
              child: AppBarToggleChip(
                compact: compact,
                icon: Icons.schedule,
                label: 'Queued',
                onPressed: () => context.go('/builds?state=queued'),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
