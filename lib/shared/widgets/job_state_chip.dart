import 'package:flutter/material.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';

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

/// Just the glyph, no label — for a `ListTile.leading` slot, which reserves
/// a fixed-width box sized for an icon and clips a full [JobStateChip]'s
/// text mid-word rather than wrapping or ellipsizing it.
class JobStateIcon extends StatelessWidget {
  const JobStateIcon({super.key, required this.state});

  final JobState state;

  @override
  Widget build(BuildContext context) => Icon(switch (state) {
    JobState.queued => Icons.schedule,
    JobState.running => Icons.autorenew,
    JobState.succeeded => Icons.check_circle_outline,
    JobState.failed => Icons.error_outline,
    JobState.cancelled => Icons.block,
    JobState.interrupted => Icons.warning_amber,
    JobState.unknown => Icons.help_outline,
  });
}
