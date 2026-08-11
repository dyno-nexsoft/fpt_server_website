import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../../../core/theme/app_theme.dart';
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
      return _ResumedJobBanner(resumedJob: logState.resumedJob);
    }

    final job = logState.job;
    if (job == null) {
      if (logState.actionError != null) {
        return Center(child: Text(logState.actionError!));
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JobHeader(job: job, mode: logState.mode),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _LogPane(text: logState.logText)),
              const VerticalDivider(width: 1),
              SizedBox(width: 320, child: JobDetailPanel(job: job)),
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
          Text('·  ${job.actionName}'),
          JobStateChip(state: job.state),
          if (duration != null) Text(formatDuration(duration)),
          Chip(label: Text(_modeLabel)),
          if (job.resumedFrom != null)
            Chip(label: Text('resumed from ${job.resumedFrom}')),
        ],
      ),
    );
  }
}

class _LogPane extends StatefulWidget {
  const _LogPane({required this.text});

  final String text;

  @override
  State<_LogPane> createState() => _LogPaneState();
}

class _LogPaneState extends State<_LogPane> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _LogPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text.length != widget.text.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SelectableText(
            widget.text.isEmpty ? '(no output yet)' : widget.text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.merge(AppTheme.monospaceTextStyle),
          ),
        ),
      ),
    );
  }
}

class _ResumedJobBanner extends StatelessWidget {
  const _ResumedJobBanner({required this.resumedJob});

  final Job? resumedJob;

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
                'This build was resumed as a new job after a restart.',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  if (resumedJob != null)
                    FilledButton(
                      onPressed: () => context.go('/jobs/${resumedJob!.id}'),
                      child: const Text('Open new job'),
                    ),
                  OutlinedButton(
                    onPressed: () => context.go('/builds'),
                    child: const Text('View builds'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
