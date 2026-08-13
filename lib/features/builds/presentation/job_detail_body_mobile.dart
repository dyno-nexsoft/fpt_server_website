import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../../shared/widgets/log_viewer.dart';
import '../application/job_log_controller.dart';
import 'job_detail_panel.dart';
import 'job_header.dart';

/// Mobile's whole job page: header, params panel, and log, all scrolling as
/// one continuous gesture via [NestedScrollView] instead of two independent
/// scrollables (a fixed-height log window inside an outer page scroll)
/// fighting each other for the same drag.
///
/// The header and panel are the [NestedScrollView] *header* — they scroll
/// away first, the same way an app bar collapses, instead of staying
/// pinned and permanently claiming a phone's limited height. The log is the
/// *body*: once the header is scrolled out of view, the same drag keeps
/// scrolling the log, which shares the header's scroll position via
/// [LogViewer.verticalController] rather than owning its own.
class MobileJobBody extends StatelessWidget {
  const MobileJobBody({
    super.key,
    required this.job,
    required this.mode,
    required this.logState,
  });

  final Job job;
  final LogConnectionMode mode;
  final JobLogState logState;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: JobHeader(job: job, mode: mode),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverToBoxAdapter(child: JobDetailPanel(job: job, scrollable: false)),
        const SliverToBoxAdapter(child: Divider(height: 1)),
      ],
      body: Builder(
        builder: (context) => LogViewer(
          lines: logState.lines,
          pendingLine: logState.pendingLine,
          autoScrollToEnd: true,
          verticalController: PrimaryScrollController.of(context),
        ),
      ),
    );
  }
}
