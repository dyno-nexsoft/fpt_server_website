import 'package:flutter/material.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';

import 'bar_chart.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Two bar charts (by state + by day) replacing the old "Recent builds" card.
///
/// [allJobs] is the full history (up to 100 records) used for aggregation.
class BuildStatsCard extends StatelessWidget {
  const BuildStatsCard({super.key, required this.allJobs});

  final List<Job> allJobs;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [],
    );
  }
}

// We expose a Column directly so DashboardScreen can inline these two cards
// without an extra nesting level — callers use [buildStateChart] and
// [buildDailyChart] as siblings in their own Column.

/// Bar chart of terminal build counts grouped by [JobState].
class BuildsByStateCard extends StatelessWidget {
  const BuildsByStateCard({super.key, required this.jobs});

  final List<Job> jobs;

  /// Only terminal states make sense as chart bars; active states are already
  /// visible in the "Running / queued" card above.
  static const _tracked = [
    JobState.succeeded,
    JobState.failed,
    JobState.cancelled,
    JobState.interrupted,
  ];

  List<BarChartData> _buildData(ThemeData theme) {
    final counts = {for (final s in _tracked) s: 0};
    for (final job in jobs) {
      if (counts.containsKey(job.state)) {
        counts[job.state] = counts[job.state]! + 1;
      }
    }
    final cs = theme.colorScheme;
    // Short labels so they fit under narrow bars without clipping.
    return [
      BarChartData(
        label: 'OK',
        value: counts[JobState.succeeded]!,
        color: Colors.green,
      ),
      BarChartData(
        label: 'Failed',
        value: counts[JobState.failed]!,
        color: cs.error,
      ),
      BarChartData(
        label: 'Cancel',
        value: counts[JobState.cancelled]!,
        color: cs.secondary,
      ),
      BarChartData(
        label: 'Interr.',
        value: counts[JobState.interrupted]!,
        color: Colors.orange,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final data = _buildData(theme);
    final total = jobs.where((j) => j.state.isTerminal).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.bar_chart),
                Text('Builds by state', style: textTheme.titleSmall),
                const Spacer(),
                Text('$total total', style: textTheme.bodySmall),
              ],
            ),
            _Legend(data: data),
            BarChart(data: data),
          ],
        ),
      ),
    );
  }
}

/// Bar chart of build counts grouped by calendar day for the last 7 days.
class BuildsByDayCard extends StatelessWidget {
  const BuildsByDayCard({super.key, required this.jobs});

  final List<Job> jobs;

  static const _days = 7;

  List<BarChartData> _buildData(ThemeData theme) {
    final now = DateTime.now();
    // Normalise to midnight so grouping is date-only.
    final today = DateTime(now.year, now.month, now.day);

    final counts = List.filled(_days, 0);
    for (final job in jobs) {
      final day = DateTime(
        job.createdAt.year,
        job.createdAt.month,
        job.createdAt.day,
      );
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < _days) {
        counts[_days - 1 - diff]++;
      }
    }

    return List.generate(_days, (i) {
      final date = today.subtract(Duration(days: _days - 1 - i));
      final label = _shortDay(date, i == _days - 1);
      return BarChartData(
        label: label,
        value: counts[i],
        color: theme.colorScheme.primary,
      );
    });
  }

  String _shortDay(DateTime date, bool isToday) {
    if (isToday) return 'Today';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final data = _buildData(theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.calendar_month_outlined),
                Text('Builds per day (7 days)', style: textTheme.titleSmall),
              ],
            ),
            BarChart(data: data),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend row
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.data});

  final List<BarChartData> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final d in data.where((d) => d.value > 0))
          _LegendItem(
            label: '${d.label} (${d.value})',
            color: d.color ?? theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}
