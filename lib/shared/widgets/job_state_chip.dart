import 'package:flutter/material.dart';

import '../../core/models/job.dart';

/// State glyph + label. Differentiated by icon and text only — no per-state
/// colors — so the default Material theme stays the single source of truth
/// for appearance.
class JobStateChip extends StatelessWidget {
  const JobStateChip({super.key, required this.state});

  final JobState state;

  IconData get _icon => switch (state) {
    JobState.queued => Icons.schedule,
    JobState.running => Icons.autorenew,
    JobState.succeeded => Icons.check_circle_outline,
    JobState.failed => Icons.error_outline,
    JobState.cancelled => Icons.block,
    JobState.interrupted => Icons.warning_amber,
    JobState.unknown => Icons.help_outline,
  };

  String get _label => switch (state) {
    JobState.queued => 'Queued',
    JobState.running => 'Running',
    JobState.succeeded => 'Succeeded',
    JobState.failed => 'Failed',
    JobState.cancelled => 'Cancelled',
    JobState.interrupted => 'Interrupted',
    JobState.unknown => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(_icon), label: Text(_label));
  }
}
