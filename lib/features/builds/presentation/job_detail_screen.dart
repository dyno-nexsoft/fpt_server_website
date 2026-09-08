import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/utils/responsive.dart';
import '../application/job_log_controller.dart';
import 'job_detail_body_desktop.dart';
import 'job_detail_body_mobile.dart';
import 'job_header.dart';

/// The core screen: does not poll, it drives an SSE connection (falling
/// back to log polling on any stream error) via [JobLogController].
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(jobLogControllerProvider(jobId));

    if (logState.jobMissing) {
      final resumedJob = logState.resumedJob;
      if (resumedJob != null) {
        // Replaces the URL rather than making the reader click "Open new
        // job" themselves — a resumed build has a definite, known
        // destination, so landing here is a transient redirect, not a
        // decision point.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) JobDetailRoute(resumedJob.id).go(context);
        });
        return const _RedirectingBanner();
      }
      return const _JobGoneBanner();
    }

    final job = logState.job;
    if (job == null) {
      if (logState.actionError != null) {
        return Center(child: Text(logState.actionError!));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final mobile = isMobileWidth(context);
    // Mobile folds JobHeader into the scrolling body instead (see
    // MobileJobBody) — pinning it here as well as the params panel would
    // permanently claim two chip rows' worth of a phone's limited height.
    if (mobile) {
      return MobileJobBody(job: job, mode: logState.mode, logState: logState);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobHeader(job: job, mode: logState.mode),
        const Divider(height: 1),
        Expanded(
          child: DesktopJobBody(job: job, logState: logState),
        ),
      ],
    );
  }
}

class _RedirectingBanner extends StatelessWidget {
  const _RedirectingBanner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          CircularProgressIndicator(),
          Text('This build was resumed after a restart — opening it…'),
        ],
      ),
    );
  }
}

/// Shown only when the server restarted mid-build *and* no job on record
/// points back here via `resumed_from` — either the re-run itself failed
/// (see `CommandExecutor._markInterrupted`'s "please start it again" case),
/// or this page was reopened long enough after the restart that the
/// resumed job has since been pruned from history too.
class _JobGoneBanner extends StatelessWidget {
  const _JobGoneBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.restart_alt),
              const Text(
                'The server restarted mid-build. This job is gone, and no '
                'resumed build points back to it — it may have failed to '
                'restart automatically, or the page was reopened too long '
                'after the fact. Check Builds or Discord for the latest '
                'run.',
                textAlign: TextAlign.center,
              ),
              OutlinedButton(
                onPressed: () => const BuildsRoute().go(context),
                child: const Text('View builds'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
