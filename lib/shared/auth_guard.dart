import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../core/providers/session_provider.dart';
import '../core/router/app_router.dart';
import 'toast/app_toast.dart';

/// Runs a job-mutating call (cancel/promote/retry) only if a key is stored;
/// otherwise sends the user to `/login` instead of letting the request 401.
///
/// This dashboard lets anyone read a build's status, logs, and artifacts —
/// only triggering or mutating one needs a real key. Returns the updated
/// [Job] on success so the caller can run its own follow-up (refresh a
/// list, etc.); null if the guard redirected or the call failed.
Future<Job?> runAuthedJobAction(
  BuildContext context,
  WidgetRef ref, {
  required String? fallbackMessage,
  required Future<Job> Function() action,
}) async {
  if (!ref.read(sessionProvider).hasKey) {
    const LoginRoute().go(context);
    return null;
  }
  try {
    final result = await action();
    if (result.warnings.isNotEmpty) {
      // A warning (e.g. the retry couldn't edit the old Discord message and
      // posted a new one) means the action still succeeded but not exactly
      // as expected — surfacing it here is the only place that happens,
      // since the job list itself has no room for a per-row caveat.
      ref
          .read(appToastProvider.notifier)
          .show(result.warnings.join(' '), isError: true);
    } else {
      ref
          .read(appToastProvider.notifier)
          .show(result.message ?? fallbackMessage ?? 'Done');
    }
    return result;
  } on ApiException catch (e) {
    ref.read(appToastProvider.notifier).show(e.message, isError: true);
    return null;
  }
}
