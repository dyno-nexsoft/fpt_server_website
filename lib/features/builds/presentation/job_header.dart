import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../application/job_log_controller.dart';

/// The job id, action name, state, duration, and connection mode as a row of
/// chips — shared by desktop (pinned above the log/panel split) and mobile
/// (folded into the scrolling body instead, alongside the params panel, so
/// it isn't permanently pinned eating into the little screen height a phone
/// has to spare).
class JobHeader extends StatelessWidget {
  const JobHeader({super.key, required this.job, required this.mode});

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
        runSpacing: 8,
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
