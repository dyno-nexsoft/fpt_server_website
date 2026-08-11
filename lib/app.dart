import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'shared/toast/app_toast.dart';
import 'theme/app_theme.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CiCdDashboardApp extends ConsumerWidget {
  const CiCdDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CI/CD Dashboard',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
      builder: (context, child) => _ToastListener(child: child),
    );
  }
}

/// Single top-level `ref.listen` that turns [appToastProvider] updates into
/// snack bars, so feature widgets never touch `ScaffoldMessenger` directly.
class _ToastListener extends ConsumerWidget {
  const _ToastListener({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appToastProvider, (previous, next) {
      if (next == null) return;
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(next.text)),
      );
      ref.read(appToastProvider.notifier).clear();
    });
    return child ?? const SizedBox.shrink();
  }
}
