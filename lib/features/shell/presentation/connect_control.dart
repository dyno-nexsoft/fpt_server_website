import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/router/app_router.dart';
import 'app_bar_toggle_chip.dart';

/// The app bar's Sign-out/Connect control — self-contained (reads
/// [sessionProvider] itself) rather than a value [AppShell] computes and
/// passes down, since nothing else in the shell needs to know which state
/// it's in.
class ConnectControl extends ConsumerWidget {
  const ConnectControl({super.key, required this.compact});

  /// See [AppBarToggleChip.compact].
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasKey = ref.watch(sessionProvider).hasKey;
    if (!hasKey) {
      return AppBarToggleChip(
        compact: compact,
        icon: Icons.login,
        label: 'Sign in',
        onPressed: () => const LoginRoute().go(context),
      );
    }
    return AppBarToggleChip(
      compact: compact,
      icon: Icons.logout,
      label: 'Sign out',
      onPressed: () async {
        await ref.read(connectionControllerProvider.notifier).logout();
        if (context.mounted) const LoginRoute().go(context);
      },
    );
  }
}
