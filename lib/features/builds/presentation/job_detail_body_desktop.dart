import 'package:flutter/material.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../shared/widgets/log_viewer.dart';
import '../application/job_log_controller.dart';
import 'job_detail_panel.dart';

/// Desktop's log and panel side by side — both get their own bounded space
/// from the fixed panel width, so (unlike mobile) each can scroll
/// independently without one starving the other of screen height.
class DesktopJobBody extends StatelessWidget {
  const DesktopJobBody({super.key, required this.job, required this.logState});

  final Job job;
  final JobLogState logState;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: LogViewer(
            lines: logState.lines,
            pendingLine: logState.pendingLine,
            autoScrollToEnd: true,
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 320, child: JobDetailPanel(job: job)),
      ],
    );
  }
}
