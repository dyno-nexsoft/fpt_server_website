import 'dart:async';

import 'package:flutter/material.dart';

/// Rotates through a canned list of "what's probably happening right now"
/// messages while a long-running mutation is in flight.
///
/// The server's own progress reporting (`Action.onProgress`) only reaches
/// Discord today — a REST caller (this website) gets one blocking response
/// at the end, with nothing in between. For a fast action that's invisible;
/// for `gitlab.review`/`gitlab.translateArb`, which can run for minutes
/// while Gemini works, a bare disabled button reads as a hung request. This
/// is deliberately fake progress, not real status, purely to keep the wait
/// legible.
class SubmittingIndicator extends StatefulWidget {
  const SubmittingIndicator({super.key, required this.messages});

  final List<String> messages;

  @override
  State<SubmittingIndicator> createState() => _SubmittingIndicatorState();
}

class _SubmittingIndicatorState extends State<SubmittingIndicator> {
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The last message is left showing rather than looping back to the
    // first — cycling through "reading files... asking AI... reading
    // files..." again reads as stuck in a way holding on a later step
    // doesn't.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_index >= widget.messages.length - 1) return;
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            const LinearProgressIndicator(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.messages[_index],
                key: ValueKey(_index),
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
