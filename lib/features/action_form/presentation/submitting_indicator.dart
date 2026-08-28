import 'dart:async';

import 'package:flutter/material.dart';

/// Shows what a long-running mutation is doing while it is in flight.
///
/// Prefers [liveStatus] — the server's own `Action.onProgress` lines,
/// streamed over `GET /invocations/{id}/events` for any action whose schema
/// sets `supportsProgress`. Until the first of those arrives (and for any
/// action that reports none at all), it falls back to rotating [messages],
/// which are deliberately fake: for `gitlab.review`/`gitlab.translateArb`,
/// which can run for minutes while Gemini works, a bare disabled button
/// reads as a hung request.
class SubmittingIndicator extends StatefulWidget {
  const SubmittingIndicator({
    super.key,
    required this.messages,
    this.liveStatus,
  });

  final List<String> messages;

  /// Real server-reported status lines, when this action streams them.
  final Stream<String>? liveStatus;

  @override
  State<SubmittingIndicator> createState() => _SubmittingIndicatorState();
}

class _SubmittingIndicatorState extends State<SubmittingIndicator> {
  var _index = 0;
  Timer? _timer;
  StreamSubscription<String>? _statusSub;

  /// Non-null once the server has reported anything — from then on the
  /// canned rotation is irrelevant and stops being shown.
  String? _live;

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
    _statusSub = widget.liveStatus?.listen((status) {
      if (!mounted) return;
      // Once the server is reporting for itself, the canned rotation is dead
      // weight — it can never be shown again, so leaving it ticking is a
      // rebuild every 5s that changes nothing on screen.
      _timer?.cancel();
      _timer = null;
      setState(() => _live = status);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_statusSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lives inside the submit button itself (its `FilledButton.icon`-style
    // label) rather than a separate card above it — a disabled button that
    // still visibly changes reads as "working", not "stuck", without a
    // second widget competing for attention right next to it.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _live ?? widget.messages[_index],
              key: ValueKey(_live ?? '$_index'),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
