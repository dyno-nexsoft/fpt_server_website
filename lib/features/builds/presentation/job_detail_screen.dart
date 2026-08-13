import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../../../shared/widgets/log_viewer.dart';
import '../application/job_log_controller.dart';
import 'job_detail_panel.dart';

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
          if (context.mounted) context.go('/builds/${resumedJob.id}');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JobHeader(job: job, mode: logState.mode),
        const Divider(height: 1),
        Expanded(
          child: Flex(
            direction: mobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LogViewer(
                    lines: logState.lines,
                    pendingLine: logState.pendingLine,
                    autoScrollToEnd: true,
                  ),
                ),
              ),
              mobile
                  ? const Divider(height: 1)
                  : const VerticalDivider(width: 1),
              // JobDetailPanel is a ListView — it needs a bounded main-axis
              // extent either way: a fixed width alongside the log on
              // desktop, or a share of the remaining height below it on
              // mobile, where a fixed height would either waste space or
              // clip a long panel.
              mobile
                  ? Expanded(child: JobDetailPanel(job: job))
                  : SizedBox(width: 320, child: JobDetailPanel(job: job)),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job, required this.mode});

  final Job job;
  final LogConnectionMode mode;

  String get _modeLabel => switch (mode) {
    LogConnectionMode.connecting => 'connecting…',
    LogConnectionMode.live => 'live',
    LogConnectionMode.polling => 'polling',
    LogConnectionMode.static => 'finished',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = job.runningDuration;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text(job.id, style: textTheme.titleMedium),
          Chip(label: Text(job.actionName ?? job.command)),
          JobStateChip(state: job.state),
          if (duration != null) Chip(label: Text(formatDuration(duration))),
          Chip(label: Text(_modeLabel)),
          if (job.resumedFrom != null)
            Chip(label: Text('resumed from ${job.resumedFrom}')),
        ],
      ),
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
                onPressed: () => context.go('/builds'),
                child: const Text('View builds'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
